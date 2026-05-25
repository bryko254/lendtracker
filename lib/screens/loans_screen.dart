import 'package:flutter/material.dart';

import '../data/lend_repository.dart';
import '../models/borrower.dart';
import '../models/borrower.dart';
import '../models/loan_with_totals.dart';
import '../utils/date_utils.dart';
import '../utils/formatters.dart';
import 'loan_detail_screen.dart';
import 'loan_form_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key, required this.repository});

  final LendRepository repository;

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  String _filter = 'all';
  late Future<_LoanListData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_LoanListData> _loadData() async {
    final loans = await widget.repository.listLoans(statusFilter: _filter);
    final borrowers = await widget.repository.listBorrowers();
    return _LoanListData(
      loans: loans,
      borrowers: {for (final b in borrowers) b.id!: b},
    );
  }

  void _refresh() {
    setState(() {
      _future = _loadData();
    });
  }

  Future<void> _addLoan() async {
    final borrowers = await widget.repository.listBorrowers();
    if (!mounted) {
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoanFormScreen(
          repository: widget.repository,
          borrowers: borrowers,
        ),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == 'all',
                  onTap: () => setState(() {
                    _filter = 'all';
                    _future = _loadData();
                  }),
                ),
                _FilterChip(
                  label: 'Open',
                  selected: _filter == 'open',
                  onTap: () => setState(() {
                    _filter = 'open';
                    _future = _loadData();
                  }),
                ),
                _FilterChip(
                  label: 'Overdue',
                  selected: _filter == 'overdue',
                  onTap: () => setState(() {
                    _filter = 'overdue';
                    _future = _loadData();
                  }),
                ),
                _FilterChip(
                  label: 'Settled',
                  selected: _filter == 'settled',
                  onTap: () => setState(() {
                    _filter = 'settled';
                    _future = _loadData();
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<_LoanListData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final data = snapshot.data;
                if (data == null || data.loans.isEmpty) {
                  return const Center(child: Text('No loans found.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.loans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final loan = data.loans[index];
                      final borrower = data.borrowers[loan.loan.borrowerId];
                      final overdue = isOverdue(loan);
                      return Card(
                        child: ListTile(
                          title: Text(borrower?.name ?? 'Unknown borrower'),
                          subtitle: Text(
                            loan.loan.dueDate == null
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
                                  color: overdue
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
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLoan,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LoanListData {
  _LoanListData({required this.loans, required this.borrowers});

  final List<LoanWithTotals> loans;
  final Map<int, Borrower> borrowers;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
