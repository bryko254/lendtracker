import 'package:flutter/material.dart';

import '../data/lend_repository.dart';
import '../models/borrower.dart';
import '../models/loan_with_totals.dart';
import '../utils/formatters.dart';
import 'borrower_form_screen.dart';
import 'loan_detail_screen.dart';
import 'loan_form_screen.dart';

class BorrowerDetailScreen extends StatefulWidget {
  const BorrowerDetailScreen({
    super.key,
    required this.repository,
    required this.borrowerId,
  });

  final LendRepository repository;
  final int borrowerId;

  @override
  State<BorrowerDetailScreen> createState() => _BorrowerDetailScreenState();
}

class _BorrowerDetailScreenState extends State<BorrowerDetailScreen> {
  late Future<_BorrowerDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_BorrowerDetailData> _loadData() async {
    final borrower = await widget.repository.getBorrower(widget.borrowerId);
    final loans =
        await widget.repository.listLoans(borrowerId: widget.borrowerId);
    return _BorrowerDetailData(borrower: borrower, loans: loans);
  }

  void _refresh() {
    setState(() {
      _future = _loadData();
    });
  }

  Future<void> _editBorrower(Borrower borrower) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BorrowerFormScreen(
          repository: widget.repository,
          borrower: borrower,
        ),
      ),
    );
    _refresh();
  }

  Future<void> _deleteBorrower(Borrower borrower) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete borrower?'),
          content: const Text(
            'This will delete the borrower and all their loans and repayments.',
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
      await widget.repository.deleteBorrower(borrower.id!);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _addLoan(Borrower borrower) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoanFormScreen(
          repository: widget.repository,
          borrower: borrower,
        ),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrower'),
      ),
      body: FutureBuilder<_BorrowerDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data;
          final borrower = data?.borrower;
          if (data == null || borrower == null) {
            return const Center(child: Text('Borrower not found.'));
          }

          final totalOutstanding = data.loans.fold<int>(
            0,
            (sum, loan) => sum + loan.remainingMinor,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: Text(borrower.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (borrower.phone != null && borrower.phone!.isNotEmpty)
                        Text(borrower.phone!),
                      if (borrower.notes != null && borrower.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(borrower.notes!),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editBorrower(borrower);
                      } else if (value == 'delete') {
                        _deleteBorrower(borrower);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Total outstanding: ${formatMoney(totalOutstanding)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Loans',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: () => _addLoan(borrower),
                    icon: const Icon(Icons.add),
                    label: const Text('Add loan'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (data.loans.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No loans for this borrower yet.'),
                )
              else
                ...data.loans.map((loan) {
                  return Card(
                    child: ListTile(
                      title: Text(
                        'Remaining ${formatMoney(loan.remainingMinor)}',
                      ),
                      subtitle: Text(
                        'Lent ${formatMoney(loan.loan.principalMinor)}',
                      ),
                      trailing: Text(loan.loan.status.toUpperCase()),
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
          );
        },
      ),
    );
  }
}

class _BorrowerDetailData {
  _BorrowerDetailData({required this.borrower, required this.loans});

  final Borrower? borrower;
  final List<LoanWithTotals> loans;
}
