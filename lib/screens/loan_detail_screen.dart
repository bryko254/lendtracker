import 'package:flutter/material.dart';

import '../data/lend_repository.dart';
import '../models/borrower.dart';
import '../models/loan_with_totals.dart';
import '../models/repayment.dart';
import '../utils/date_utils.dart';
import '../utils/formatters.dart';
import 'loan_form_screen.dart';
import 'repayment_form_screen.dart';

class LoanDetailScreen extends StatefulWidget {
  const LoanDetailScreen({
    super.key,
    required this.repository,
    required this.loanId,
    this.borrower,
  });

  final LendRepository repository;
  final int loanId;
  final Borrower? borrower;

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  late Future<_LoanDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_LoanDetailData> _loadData() async {
    final loan = await widget.repository.getLoanWithTotals(widget.loanId);
    Borrower? borrower = widget.borrower;
    if (loan != null && borrower == null) {
      borrower = await widget.repository.getBorrower(loan.loan.borrowerId);
    }
    final repayments = await widget.repository.listRepayments(widget.loanId);
    return _LoanDetailData(
      loan: loan,
      borrower: borrower,
      repayments: repayments,
    );
  }

  void _refresh() {
    setState(() {
      _future = _loadData();
    });
  }

  Future<void> _editLoan(LoanWithTotals loan, Borrower? borrower) async {
    final borrowers = await widget.repository.listBorrowers();
    if (!mounted) {
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoanFormScreen(
          repository: widget.repository,
          loan: loan.loan,
          borrower: borrower,
          borrowers: borrowers,
        ),
      ),
    );
    _refresh();
  }

  Future<void> _deleteLoan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete loan?'),
          content: const Text(
            'This will delete the loan and all repayments linked to it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await widget.repository.deleteLoan(widget.loanId);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _addRepayment(LoanWithTotals loan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RepaymentFormScreen(
          repository: widget.repository,
          loan: loan,
        ),
      ),
    );
    _refresh();
  }

  Future<void> _editRepayment(Repayment repayment, LoanWithTotals loan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RepaymentFormScreen(
          repository: widget.repository,
          loan: loan,
          repayment: repayment,
        ),
      ),
    );
    _refresh();
  }

  Future<void> _deleteRepayment(Repayment repayment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete repayment?'),
          content: const Text('This will remove the repayment record.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await widget.repository.deleteRepayment(
        repayment.id!,
        repayment.loanId,
      );
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteLoan,
          ),
        ],
      ),
      body: FutureBuilder<_LoanDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data;
          if (data == null || data.loan == null) {
            return const Center(child: Text('Loan not found.'));
          }

          final loan = data.loan!;
          final borrower = data.borrower;
          final overdue = isOverdue(loan);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: Text(borrower?.name ?? 'Unknown borrower'),
                  subtitle: Text(
                    'Status: ${loan.loan.status.toUpperCase()}'
                    '${overdue ? ' • OVERDUE' : ''}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editLoan(loan, borrower),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        label: 'Principal',
                        value: formatMoney(loan.loan.principalMinor),
                      ),
                      _InfoRow(
                        label: 'Repaid',
                        value: formatMoney(loan.repaidMinor),
                      ),
                      _InfoRow(
                        label: 'Remaining',
                        value: formatMoney(loan.remainingMinor),
                      ),
                      _InfoRow(
                        label: 'Date lent',
                        value: formatDate(loan.loan.lentDate),
                      ),
                      _InfoRow(
                        label: 'Due date',
                        value: loan.loan.dueDate == null
                            ? 'No due date'
                            : formatDate(loan.loan.dueDate!),
                      ),
                      if (loan.loan.notes != null &&
                          loan.loan.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Notes: ${loan.loan.notes}'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Repayments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: loan.remainingMinor <= 0
                        ? null
                        : () => _addRepayment(loan),
                    icon: const Icon(Icons.add),
                    label: const Text('Add repayment'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (data.repayments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No repayments yet.'),
                )
              else
                ...data.repayments.map((repayment) {
                  return Card(
                    child: ListTile(
                      title: Text(formatMoney(repayment.amountMinor)),
                      subtitle: Text(formatDate(repayment.date)),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editRepayment(repayment, loan);
                          } else if (value == 'delete') {
                            _deleteRepayment(repayment);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _LoanDetailData {
  _LoanDetailData({
    required this.loan,
    required this.borrower,
    required this.repayments,
  });

  final LoanWithTotals? loan;
  final Borrower? borrower;
  final List<Repayment> repayments;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
