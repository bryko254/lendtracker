import 'package:flutter/material.dart';

import '../data/lend_repository.dart';
import 'borrowers_screen.dart';
import 'dashboard_screen.dart';
import 'loans_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.repository});

  final LendRepository repository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(repository: widget.repository),
      BorrowersScreen(repository: widget.repository),
      LoansScreen(repository: widget.repository),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Borrowers',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Loans',
          ),
        ],
      ),
    );
  }
}
