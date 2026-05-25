import 'package:flutter/material.dart';

import '../data/lend_repository.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../utils/formatters.dart';
import 'borrower_form_screen.dart';

class LoanFormScreen extends StatefulWidget {
  const LoanFormScreen({
    super.key,
    required this.repository,
    this.borrower,
    this.loan,
    this.borrowers,
  });

  final LendRepository repository;
  final Borrower? borrower;
  final Loan? loan;
  final List<Borrower>? borrowers;

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  DateTime _lentDate = DateTime.now();
  DateTime? _dueDate;
  int? _borrowerId;
  bool _saving = false;
  late Future<void> _borrowersFuture;
  List<Borrower> _borrowers = [];

  @override
  void initState() {
    super.initState();
    final loan = widget.loan;
    _amountController = TextEditingController(
      text: loan == null ? '' : (loan.principalMinor / 100).toStringAsFixed(2),
    );
    _notesController = TextEditingController(text: loan?.notes ?? '');
    _lentDate = loan?.lentDate ?? DateTime.now();
    _dueDate = loan?.dueDate;
    _borrowerId = widget.borrower?.id ?? loan?.borrowerId;
    _borrowersFuture = _loadBorrowers();
  }

  Future<void> _loadBorrowers() async {
    final initial = widget.borrowers ?? <Borrower>[];
    if (initial.isNotEmpty) {
      _borrowers = initial;
    } else {
      _borrowers = await widget.repository.listBorrowers();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDueDate}) async {
    final initial = isDueDate ? (_dueDate ?? _lentDate) : _lentDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isDueDate) {
        _dueDate = picked;
      } else {
        _lentDate = picked;
      }
    });
  }

  Future<void> _save(List<Borrower> borrowers) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_borrowerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a borrower.')),
      );
      return;
    }
    setState(() => _saving = true);

    final principalMinor = parseAmountToMinor(_amountController.text);
    final now = DateTime.now();
    if (widget.loan == null) {
      final loan = Loan(
        borrowerId: _borrowerId!,
        principalMinor: principalMinor,
        lentDate: _lentDate,
        dueDate: _dueDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        status: 'open',
        createdAt: now,
      );
      await widget.repository.insertLoan(loan);
    } else {
      final updated = widget.loan!.copyWith(
        borrowerId: _borrowerId!,
        principalMinor: principalMinor,
        lentDate: _lentDate,
        dueDate: _dueDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      await widget.repository.updateLoan(updated);
      await widget.repository.recalcLoanStatus(updated.id!);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _addBorrowerFromLoan() async {
    final created = await Navigator.push<Borrower>(
      context,
      MaterialPageRoute(
        builder: (_) => BorrowerFormScreen(repository: widget.repository),
      ),
    );
    if (created == null) {
      return;
    }
    await _loadBorrowers();
    if (mounted) {
      setState(() {
        _borrowerId = created.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.loan == null ? 'Add loan' : 'Edit loan'),
      ),
      body: FutureBuilder<void>(
        future: _borrowersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final borrowers = _borrowers;
          if (borrowers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add a borrower first.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _addBorrowerFromLoan,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add borrower'),
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _borrowerId,
                          decoration: const InputDecoration(
                            labelText: 'Borrower',
                            border: OutlineInputBorder(),
                          ),
                          items: borrowers
                              .map(
                                (borrower) => DropdownMenuItem<int>(
                                  value: borrower.id,
                                  child: Text(borrower.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _borrowerId = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _addBorrowerFromLoan,
                        icon: const Icon(Icons.person_add_alt_1),
                        tooltip: 'Add borrower',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (KSh)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Amount is required';
                      }
                      final amount = parseAmountToMinor(value);
                      if (amount <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Date lent',
                          value: formatDate(_lentDate),
                          onTap: () => _pickDate(isDueDate: false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: 'Due date',
                          value:
                              _dueDate == null ? 'Optional' : formatDate(_dueDate!),
                          onTap: () => _pickDate(isDueDate: true),
                          onClear: _dueDate == null
                              ? null
                              : () => setState(() => _dueDate = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : () => _save(borrowers),
                      child: Text(_saving ? 'Saving...' : 'Save loan'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: onClear == null
              ? const Icon(Icons.calendar_today)
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                ),
        ),
        child: Text(value),
      ),
    );
  }
}
