import 'package:flutter/material.dart';
import 'tabs/dashboard_screen.dart';
import 'tabs/pets/pets_screen.dart';
import 'tabs/bookings/bookings_screen.dart';
import 'tabs/profile/profile_screen.dart';

class HomeShell extends StatefulWidget {
  static const routeName = '/home';
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _switchTab(int index) {
    setState(() => _index = index);
  }

  List<Widget> get _pages => [
    DashboardScreen(onSwitchTab: _switchTab),
    const PetsScreen(),
    const BookingsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final titles = ['Dashboard', 'Pets', 'Bookings', 'Profile'];
    return Scaffold(
      appBar: _index == 0 ? null : AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(titles[_index]),
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Pets'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
