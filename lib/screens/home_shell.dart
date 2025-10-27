import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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

  final _pages = const [
    DashboardScreen(),
    PetsScreen(),
    BookingsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final titles = ['Dashboard', 'Pets', 'Bookings', 'Profile'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          if (_index == 3)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              tooltip: 'Logout',
            ),
        ],
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
