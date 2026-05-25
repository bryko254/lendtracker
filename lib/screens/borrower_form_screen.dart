import 'package:flutter/material.dart';

import 'package:flutter_contacts/flutter_contacts.dart';

import '../data/lend_repository.dart';
import '../models/borrower.dart';

class BorrowerFormScreen extends StatefulWidget {
  const BorrowerFormScreen({super.key, required this.repository, this.borrower});

  final LendRepository repository;
  final Borrower? borrower;

  @override
  State<BorrowerFormScreen> createState() => _BorrowerFormScreenState();
}

class _BorrowerFormScreenState extends State<BorrowerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;
  bool _saving = false;
  bool _loadingContact = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.borrower?.name ?? '');
    _phoneController =
        TextEditingController(text: widget.borrower?.phone ?? '');
    _notesController =
        TextEditingController(text: widget.borrower?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();

    if (widget.borrower == null) {
      final borrower = Borrower(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: now,
      );
      final result = await widget.repository.upsertBorrower(borrower);
      if (mounted && !result.created) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Borrower already exists.')),
        );
      }
      if (mounted) {
        Navigator.pop(context, result.borrower);
      }
      return;
    } else {
      final borrower = widget.borrower!.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      try {
        await widget.repository.updateBorrower(borrower);
        if (mounted) {
          Navigator.pop(context, borrower);
        }
      } on StateError {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Borrower already exists.')),
          );
        }
      }
      return;
    }
  }

  Future<void> _pickFromContacts() async {
    if (_loadingContact) {
      return;
    }
    setState(() => _loadingContact = true);
    try {
      final allowed = await FlutterContacts.requestPermission(readonly: true);
      if (!allowed) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Contacts permission needed'),
              content: const Text(
                'Please enable Contacts permission in your device settings and '
                'restart the app if the permission was just granted.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts permission denied.')),
          );
        }
        return;
      }
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) {
        return;
      }
      final phone = contact.phones.isNotEmpty
          ? contact.phones.first.number
          : null;
      setState(() {
        _nameController.text = contact.displayName;
        _phoneController.text = phone ?? '';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingContact = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.borrower == null ? 'Add borrower' : 'Edit borrower'),
        actions: [
          if (widget.borrower == null)
            IconButton(
              icon: const Icon(Icons.contact_page_outlined),
              onPressed: _loadingContact ? null : _pickFromContacts,
              tooltip: 'Select from contacts',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (widget.borrower == null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _loadingContact ? null : _pickFromContacts,
                    icon: const Icon(Icons.contact_page_outlined),
                    label: Text(
                      _loadingContact
                          ? 'Loading contacts...'
                          : 'Select from contacts',
                    ),
                  ),
                ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                ),
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
                  child: Text(_saving ? 'Saving...' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
