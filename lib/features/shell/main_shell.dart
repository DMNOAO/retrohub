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

  static const titles = ['Inicio', 'Biblioteca', 'Bitácora', 'Perfil'];

  void _openConsole(String console) {
    setState(() {
      _libraryConsoleFilter = console;
      _selectedIndex = 1;
      _refreshToken++;
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
    return Scaffold(
      appBar: AppBar(title: Text(titles[_selectedIndex])),
      body: _currentPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            _refreshToken++;
            if (index != 1) _libraryConsoleFilter = null;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.videogame_asset_outlined), selectedIcon: Icon(Icons.videogame_asset), label: 'Biblioteca'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Bitácora'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
