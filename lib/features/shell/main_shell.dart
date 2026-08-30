import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../journal/journal_dashboard_page.dart';
import '../library/library_page.dart';
import '../profile/profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  int _refreshToken = 0;
  String? _libraryConsoleFilter;
  final List<int> _navigationHistory = <int>[];

  static const titles = ['Inicio', 'Biblioteca', 'Bitácora', 'Perfil'];
  static const titleIcons = [
    Icons.home_rounded,
    Icons.videogame_asset_rounded,
    Icons.auto_stories_rounded,
    Icons.person_rounded,
  ];

  void _openConsole(String console) {
    setState(() {
      if (_selectedIndex != 1) _navigationHistory.add(_selectedIndex);
      _libraryConsoleFilter = console;
      _selectedIndex = 1;
      _refreshToken++;
    });
  }

  void _selectSection(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      if (index == 0) {
        _navigationHistory.clear();
      } else {
        _navigationHistory.add(_selectedIndex);
      }
      _selectedIndex = index;
      _refreshToken++;
      if (index != 1) _libraryConsoleFilter = null;
    });
  }

  void _goBackInShell() {
    if (_selectedIndex == 0) return;
    setState(() {
      _selectedIndex = _navigationHistory.isNotEmpty
          ? _navigationHistory.removeLast()
          : 0;
      _refreshToken++;
      if (_selectedIndex != 1) _libraryConsoleFilter = null;
    });
  }

  Widget _currentPage() {
    switch (_selectedIndex) {
      case 0:
        return HomePage(
          key: ValueKey('home-$_refreshToken'),
          onConsoleSelected: _openConsole,
        );
      case 1:
        return LibraryPage(
          key: ValueKey('library-$_refreshToken-${_libraryConsoleFilter ?? 'all'}'),
          initialConsoleFilter: _libraryConsoleFilter,
        );
      case 2:
        return JournalDashboardPage(key: ValueKey('journal-$_refreshToken'));
      default:
        return ProfilePage(key: ValueKey('profile-$_refreshToken'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBackInShell();
      },
      child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              titleIcons[_selectedIndex],
              color: Theme.of(context).colorScheme.outline,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              titles[_selectedIndex],
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: .4,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
      body: _currentPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectSection,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.videogame_asset_outlined), selectedIcon: Icon(Icons.videogame_asset), label: 'Biblioteca'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Bitácora'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    ),
    );
  }
}
