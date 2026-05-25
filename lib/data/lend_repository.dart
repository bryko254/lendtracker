import 'package:sqflite/sqflite.dart';

import '../models/borrower.dart';
import '../models/dashboard_summary.dart';
import '../models/loan.dart';
import '../models/loan_with_totals.dart';
import '../models/repayment.dart';
import '../utils/date_utils.dart';
import 'lend_database.dart';

class LendRepository {
  LendRepository({LendDatabase? database})
      : _database = database ?? LendDatabase.instance;

  final LendDatabase _database;

  Future<BorrowerUpsertResult> upsertBorrower(Borrower borrower) async {
    final duplicate = await _findDuplicateBorrower(borrower);
    if (duplicate != null) {
      return BorrowerUpsertResult(borrower: duplicate, created: false);
    }
    final db = await _database.database;
    final id = await db.insert('borrowers', borrower.toMap());
    final created = borrower.copyWith(id: id);
    return BorrowerUpsertResult(borrower: created, created: true);
  }

  Future<List<Borrower>> listBorrowers() async {
    final db = await _database.database;
    final rows = await db.query(
      'borrowers',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Borrower.fromMap).toList();
  }

  Future<Borrower?> getBorrower(int id) async {
    final db = await _database.database;
    final rows = await db.query('borrowers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) {
      return null;
    }
    return Borrower.fromMap(rows.first);
  }

  Future<void> updateBorrower(Borrower borrower) async {
    final duplicate = await _findDuplicateBorrower(borrower, excludeId: borrower.id);
    if (duplicate != null) {
      throw StateError('Borrower already exists.');
    }
    final db = await _database.database;
    await db.update(
      'borrowers',
      borrower.toMap(),
      where: 'id = ?',
      whereArgs: [borrower.id],
    );
  }

  Future<void> deleteBorrower(int id) async {
    final db = await _database.database;
    await db.delete('borrowers', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertLoan(Loan loan) async {
    final db = await _database.database;
    return db.insert('loans', loan.toMap());
  }

  Future<void> updateLoan(Loan loan) async {
    final db = await _database.database;
    await db.update('loans', loan.toMap(), where: 'id = ?', whereArgs: [loan.id]);
  }

  Future<void> deleteLoan(int id) async {
    final db = await _database.database;
    await db.delete('loans', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> recalcLoanStatus(int loanId) async {
    await _syncLoanStatus(loanId);
  }

  Future<List<LoanWithTotals>> listLoans({
    String? statusFilter,
    int? borrowerId,
  }) async {
    final db = await _database.database;
    final where = <String>[];
    final args = <Object?>[];

    if (borrowerId != null) {
      where.add('loans.borrower_id = ?');
      args.add(borrowerId);
    }

    final whereClause = where.isEmpty ? null : where.join(' AND ');

    final rows = await db.rawQuery(
      '''
      SELECT loans.*, COALESCE(SUM(repayments.amount_minor), 0) AS repaid_minor
      FROM loans
      LEFT JOIN repayments ON repayments.loan_id = loans.id
      ${whereClause == null ? '' : 'WHERE $whereClause'}
      GROUP BY loans.id
      ORDER BY loans.lent_date DESC
      ''',
      args,
    );

    final items = rows.map((row) {
      final loan = Loan.fromMap(row);
      final repaidMinor = (row['repaid_minor'] as int?) ?? 0;
      return LoanWithTotals(loan: loan, repaidMinor: repaidMinor);
    }).toList();

    if (statusFilter == null || statusFilter == 'all') {
      return items;
    }

    if (statusFilter == 'overdue') {
      return items.where((item) => isOverdue(item)).toList();
    }

    return items.where((item) => item.loan.status == statusFilter).toList();
  }

  Future<LoanWithTotals?> getLoanWithTotals(int loanId) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
      SELECT loans.*, COALESCE(SUM(repayments.amount_minor), 0) AS repaid_minor
      FROM loans
      LEFT JOIN repayments ON repayments.loan_id = loans.id
      WHERE loans.id = ?
      GROUP BY loans.id
      ''',
      [loanId],
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.first;
    final loan = Loan.fromMap(row);
    final repaidMinor = (row['repaid_minor'] as int?) ?? 0;
    return LoanWithTotals(loan: loan, repaidMinor: repaidMinor);
  }

  Future<List<Repayment>> listRepayments(int loanId) async {
    final db = await _database.database;
    final rows = await db.query(
      'repayments',
      where: 'loan_id = ?',
      whereArgs: [loanId],
      orderBy: 'date DESC',
    );
    return rows.map(Repayment.fromMap).toList();
  }

  Future<List<Repayment>> listAllRepayments() async {
    final db = await _database.database;
    final rows = await db.query('repayments', orderBy: 'date DESC');
    return rows.map(Repayment.fromMap).toList();
  }

  Future<int> insertRepayment(Repayment repayment) async {
    final db = await _database.database;
    final id = await db.insert('repayments', repayment.toMap());
    await _syncLoanStatus(repayment.loanId, db: db);
    return id;
  }

  Future<void> updateRepayment(Repayment repayment) async {
    final db = await _database.database;
    await db.update(
      'repayments',
      repayment.toMap(),
      where: 'id = ?',
      whereArgs: [repayment.id],
    );
    await _syncLoanStatus(repayment.loanId, db: db);
  }

  Future<void> deleteRepayment(int id, int loanId) async {
    final db = await _database.database;
    await db.delete('repayments', where: 'id = ?', whereArgs: [id]);
    await _syncLoanStatus(loanId, db: db);
  }

  Future<Borrower?> _findDuplicateBorrower(
    Borrower borrower, {
    int? excludeId,
  }) async {
    final borrowers = await listBorrowers();
    final normalizedName = _normalizeName(borrower.name);
    final normalizedPhone =
        borrower.phone == null ? '' : _normalizePhone(borrower.phone!);

    for (final existing in borrowers) {
      if (excludeId != null && existing.id == excludeId) {
        continue;
      }
      final existingPhone = existing.phone == null
          ? ''
          : _normalizePhone(existing.phone!);
      if (normalizedPhone.isNotEmpty &&
          existingPhone.isNotEmpty &&
          normalizedPhone == existingPhone) {
        return existing;
      }

      if (normalizedName == _normalizeName(existing.name)) {
        return existing;
      }
    }
    return null;
  }

  String _normalizeName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\\D'), '');
  }

  Future<DashboardSummary> getDashboardSummary() async {
    final loans = await listLoans();

    var totalLent = 0;
    var totalRepaid = 0;
    var totalOutstanding = 0;
    var overdueCount = 0;
    var overdueOutstanding = 0;

    for (final item in loans) {
      totalLent += item.loan.principalMinor;
      totalRepaid += item.repaidMinor;

      final remaining = item.remainingMinor;
      if (item.loan.status == 'open') {
        totalOutstanding += remaining;
      }

      if (isOverdue(item)) {
        overdueCount += 1;
        overdueOutstanding += remaining;
      }
    }

    return DashboardSummary(
      totalLentMinor: totalLent,
      totalRepaidMinor: totalRepaid,
      totalOutstandingMinor: totalOutstanding,
      overdueCount: overdueCount,
      overdueOutstandingMinor: overdueOutstanding,
    );
  }

  Future<Map<int, int>> getOutstandingByBorrower() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT
        loans.borrower_id AS borrower_id,
        SUM(loans.principal_minor) AS principal_sum,
        SUM(COALESCE(repaid.repaid_minor, 0)) AS repaid_sum
      FROM loans
      LEFT JOIN (
        SELECT loan_id, SUM(amount_minor) AS repaid_minor
        FROM repayments
        GROUP BY loan_id
      ) AS repaid ON repaid.loan_id = loans.id
      WHERE loans.status = 'open'
      GROUP BY loans.borrower_id
    ''');

    final map = <int, int>{};
    for (final row in rows) {
      final borrowerId = row['borrower_id'] as int;
      final principalSum = (row['principal_sum'] as int?) ?? 0;
      final repaidSum = (row['repaid_sum'] as int?) ?? 0;
      map[borrowerId] = principalSum - repaidSum;
    }
    return map;
  }

  Future<void> _syncLoanStatus(int loanId, {Database? db}) async {
    final database = db ?? await _database.database;
    final rows = await database.rawQuery(
      '''
      SELECT loans.principal_minor AS principal_minor,
             COALESCE(SUM(repayments.amount_minor), 0) AS repaid_minor
      FROM loans
      LEFT JOIN repayments ON repayments.loan_id = loans.id
      WHERE loans.id = ?
      GROUP BY loans.id
      ''',
      [loanId],
    );
    if (rows.isEmpty) {
      return;
    }
    final principal = (rows.first['principal_minor'] as int?) ?? 0;
    final repaid = (rows.first['repaid_minor'] as int?) ?? 0;
    final remaining = principal - repaid;
    final status = remaining <= 0 ? 'settled' : 'open';

    await database.update(
      'loans',
      {'status': status},
      where: 'id = ?',
      whereArgs: [loanId],
    );
  }
}

class BorrowerUpsertResult {
  BorrowerUpsertResult({required this.borrower, required this.created});

  final Borrower borrower;
  final bool created;
}
