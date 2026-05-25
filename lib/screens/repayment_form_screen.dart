import 'package:flutter/material.dart';

import '../data/lend_repository.dart';
import '../models/loan_with_totals.dart';
import '../models/repayment.dart';
import '../utils/formatters.dart';

class RepaymentFormScreen extends StatefulWidget {
  const RepaymentFormScreen({
    super.key,
    required this.repository,
    required this.loan,
    this.repayment,
  });

  final LendRepository repository;
  final LoanWithTotals loan;
  final Repayment? repayment;

  @override
  State<RepaymentFormScreen> createState() => _RepaymentFormScreenState();
}

class _RepaymentFormScreenState extends State<RepaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  DateTime _date = DateTime.now();
  String? _method;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final repayment = widget.repayment;
    _amountController = TextEditingController(
      text:
          repayment == null ? '' : (repayment.amountMinor / 100).toStringAsFixed(2),
    );
    _notesController = TextEditingController(text: repayment?.notes ?? '');
    _date = repayment?.date ?? DateTime.now();
    _method = repayment?.method;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);

    final amountMinor = parseAmountToMinor(_amountController.text);
    final now = DateTime.now();

    if (widget.repayment == null) {
      final repayment = Repayment(
        loanId: widget.loan.loan.id!,
        amountMinor: amountMinor,
        date: _date,
        method: _method,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: now,
      );
      await widget.repository.insertRepayment(repayment);
    } else {
      final updated = widget.repayment!.copyWith(
        amountMinor: amountMinor,
        date: _date,
        method: _method,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      await widget.repository.updateRepayment(updated);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxAllowed =
        widget.loan.remainingMinor + (widget.repayment?.amountMinor ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.repayment == null ? 'Add repayment' : 'Edit repayment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Remaining: ${formatMoney(widget.loan.remainingMinor)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
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
                  if (amount > maxAllowed) {
                    return 'Amount exceeds remaining balance.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _DateField(
                label: 'Date',
                value: formatDate(_date),
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _method,
                decoration: const InputDecoration(
                  labelText: 'Payment method',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'M-Pesa', child: Text('M-Pesa')),
                  DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _method = value),
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
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save repayment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(value),
      ),
    );
  }
}
