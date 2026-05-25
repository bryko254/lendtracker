import 'package:flutter/material.dart';

import '../data/lend_repository.dart';
import '../models/borrower.dart';
import '../utils/formatters.dart';
import 'borrower_detail_screen.dart';
import 'borrower_form_screen.dart';

class BorrowersScreen extends StatefulWidget {
  const BorrowersScreen({super.key, required this.repository});

  final LendRepository repository;

  @override
  State<BorrowersScreen> createState() => _BorrowersScreenState();
}

class _BorrowersScreenState extends State<BorrowersScreen> {
  late Future<_BorrowerListData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_BorrowerListData> _loadData() async {
    final borrowers = await widget.repository.listBorrowers();
    final outstanding = await widget.repository.getOutstandingByBorrower();
    return _BorrowerListData(
      borrowers: borrowers,
      outstandingByBorrower: outstanding,
    );
  }

  void _refresh() {
    setState(() {
      _future = _loadData();
    });
  }

  Future<void> _openBorrowerForm({Borrower? borrower}) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrowers'),
      ),
      body: FutureBuilder<_BorrowerListData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data;
          if (data == null || data.borrowers.isEmpty) {
            return const Center(child: Text('No borrowers yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: data.borrowers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final borrower = data.borrowers[index];
                final outstanding =
                    data.outstandingByBorrower[borrower.id] ?? 0;
                return Card(
                  child: ListTile(
                    title: Text(borrower.name),
                    subtitle: borrower.phone == null || borrower.phone!.isEmpty
                        ? const Text('No phone')
                        : Text(borrower.phone!),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Outstanding',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        Text(
                          formatMoney(outstanding),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BorrowerDetailScreen(
                            repository: widget.repository,
                            borrowerId: borrower.id!,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openBorrowerForm(),
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }
}

class _BorrowerListData {
  _BorrowerListData({
    required this.borrowers,
    required this.outstandingByBorrower,
  });

  final List<Borrower> borrowers;
  final Map<int, int> outstandingByBorrower;
}
