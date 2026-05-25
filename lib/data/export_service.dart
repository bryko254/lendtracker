import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/borrower.dart';
import '../models/loan.dart';
import '../models/repayment.dart';
import 'lend_repository.dart';

class ExportService {
  ExportService({required this.repository});

  final LendRepository repository;

  Future<List<File>> exportCsvFiles() async {
    final borrowers = await repository.listBorrowers();
    final loans = await repository.listLoans();
    final repayments = await repository.listAllRepayments();

    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(directory.path, 'LendTrackerExports'));
    await exportDir.create(recursive: true);

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    final borrowerFile = File(
      p.join(exportDir.path, 'borrowers_$timestamp.csv'),
    );
    final loanFile = File(
      p.join(exportDir.path, 'loans_$timestamp.csv'),
    );
    final repaymentFile = File(
      p.join(exportDir.path, 'repayments_$timestamp.csv'),
    );

    await borrowerFile.writeAsString(_borrowersToCsv(borrowers));
    await loanFile.writeAsString(_loansToCsv(loans.map((e) => e.loan).toList()));
    await repaymentFile.writeAsString(_repaymentsToCsv(repayments));

    return [borrowerFile, loanFile, repaymentFile];
  }

  String _borrowersToCsv(List<Borrower> borrowers) {
    final buffer = StringBuffer();
    buffer.writeln('id,name,phone,notes,created_at');
    for (final borrower in borrowers) {
      buffer.writeln(
        '${borrower.id},${_escape(borrower.name)},${_escape(borrower.phone)},${_escape(borrower.notes)},${borrower.createdAt.toIso8601String()}',
      );
    }
    return buffer.toString();
  }

  String _loansToCsv(List<Loan> loans) {
    final buffer = StringBuffer();
    buffer.writeln(
      'id,borrower_id,principal_minor,lent_date,due_date,notes,status,created_at',
    );
    for (final loan in loans) {
      buffer.writeln(
        '${loan.id},${loan.borrowerId},${loan.principalMinor},${loan.lentDate.toIso8601String()},${loan.dueDate?.toIso8601String() ?? ''},${_escape(loan.notes)},${loan.status},${loan.createdAt.toIso8601String()}',
      );
    }
    return buffer.toString();
  }

  String _repaymentsToCsv(List<Repayment> repayments) {
    final buffer = StringBuffer();
    buffer.writeln(
      'id,loan_id,amount_minor,date,method,notes,created_at',
    );
    for (final repayment in repayments) {
      buffer.writeln(
        '${repayment.id},${repayment.loanId},${repayment.amountMinor},${repayment.date.toIso8601String()},${_escape(repayment.method)},${_escape(repayment.notes)},${repayment.createdAt.toIso8601String()}',
      );
    }
    return buffer.toString();
  }

  String _escape(String? value) {
    if (value == null) {
      return '';
    }
    final needsQuotes = value.contains(',') || value.contains('\n');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }
}
