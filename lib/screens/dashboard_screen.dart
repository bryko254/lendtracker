import 'package:flutter/material.dart';

import '../data/export_service.dart';
import '../data/lend_repository.dart';
import '../models/borrower.dart';
import '../models/dashboard_summary.dart';
import '../models/loan_with_totals.dart';
import '../utils/date_utils.dart';
import '../utils/formatters.dart';
import 'borrower_detail_screen.dart';
import 'loan_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.repository});

  final LendRepository repository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _future;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_DashboardData> _loadData() async {
    final summary = await widget.repository.getDashboardSummary();
    final loans = await widget.repository.listLoans(statusFilter: 'open');
    final borrowers = await widget.repository.listBorrowers();
    final outstanding = await widget.repository.getOutstandingByBorrower();
    final topBorrower = _findTopBorrower(borrowers, outstanding);
    return _DashboardData(
      summary: summary,
      loans: loans,
      borrowers: {for (final b in borrowers) b.id!: b},
      topBorrower: topBorrower,
    );
  }

  _TopBorrower? _findTopBorrower(
    List<Borrower> borrowers,
    Map<int, int> outstanding,
  ) {
    Borrower? top;
    var topAmount = 0;
    for (final borrower in borrowers) {
      final amount = outstanding[borrower.id] ?? 0;
      if (amount > topAmount) {
        top = borrower;
        topAmount = amount;
      }
    }
    if (top == null || topAmount == 0) {
      return null;
    }
    return _TopBorrower(borrower: top, outstandingMinor: topAmount);
  }

  void _refresh() {
    setState(() {
      _future = _loadData();
    });
  }

  Future<void> _exportCsv() async {
    if (_exporting) {
      return;
    }
    setState(() => _exporting = true);
    try {
      final service = ExportService(repository: widget.repository);
      final files = await service.exportCsvFiles();
      if (!mounted) {
        return;
      }
      final message = files.isEmpty
          ? 'No files exported.'
          : 'Exported ${files.length} files to ${files.first.parent.path}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LendTracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportCsv,
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: FutureBuilder<_DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No data yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryGrid(summary: data.summary),
                const SizedBox(height: 20),
                _TopBorrowerCard(
                  topBorrower: data.topBorrower,
                  onTap: data.topBorrower == null
                      ? null
                      : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BorrowerDetailScreen(
                                repository: widget.repository,
                                borrowerId: data.topBorrower!.borrower.id!,
                              ),
                            ),
                          );
                          _refresh();
                        },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Open loans',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Text('(${data.loans.length})'),
                  ],
                ),
                const SizedBox(height: 8),
                if (data.loans.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No open loans yet.'),
                  )
                else
                  ...data.loans.take(5).map((loan) {
                    final borrower = data.borrowers[loan.loan.borrowerId];
                    final isOverdueLoan = isOverdue(loan);
                    return Card(
                      child: ListTile(
                        title: Text(borrower?.name ?? 'Unknown borrower'),
                        subtitle: Text(
                          isOverdueLoan
                              ? 'Overdue • Due ${formatDate(loan.loan.dueDate!)}'
                              : loan.loan.dueDate == null
                                  ? 'No due date'
                                  : 'Due ${formatDate(loan.loan.dueDate!)}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatMoney(loan.remainingMinor),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isOverdueLoan
                                    ? Colors.redAccent
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              loan.loan.status.toUpperCase(),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoanDetailScreen(
                                repository: widget.repository,
                                loanId: loan.loan.id!,
                                borrower: borrower,
                              ),
                            ),
                          );
                          _refresh();
                        },
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardData {
  _DashboardData({
    required this.summary,
    required this.loans,
    required this.borrowers,
    required this.topBorrower,
  });

  final DashboardSummary summary;
  final List<LoanWithTotals> loans;
  final Map<int, Borrower> borrowers;
  final _TopBorrower? topBorrower;
}

class _TopBorrower {
  _TopBorrower({required this.borrower, required this.outstandingMinor});

  final Borrower borrower;
  final int outstandingMinor;
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      children: [
        _SummaryCard(
          title: 'Outstanding',
          value: formatMoney(summary.totalOutstandingMinor),
          icon: Icons.account_balance_wallet_outlined,
        ),
        _SummaryCard(
          title: 'Total lent',
          value: formatMoney(summary.totalLentMinor),
          icon: Icons.payments_outlined,
        ),
        _SummaryCard(
          title: 'Total repaid',
          value: formatMoney(summary.totalRepaidMinor),
          icon: Icons.check_circle_outline,
        ),
        _SummaryCard(
          title: 'Overdue',
          value:
              '${summary.overdueCount} • ${formatMoney(summary.overdueOutstandingMinor)}',
          icon: Icons.warning_amber_outlined,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.8,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.black54),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBorrowerCard extends StatelessWidget {
  const _TopBorrowerCard({
    required this.topBorrower,
    this.onTap,
  });

  final _TopBorrower? topBorrower;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (topBorrower == null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: const Text(
          'Top borrower',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(topBorrower!.borrower.name),
        trailing: Text(
          formatMoney(topBorrower!.outstandingMinor),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onTap: onTap,
      ),
    );
  }
}
