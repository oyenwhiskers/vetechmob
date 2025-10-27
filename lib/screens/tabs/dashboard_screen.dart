import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text('Error: ${provider.error}'));
    }
    final DashboardData? data = provider.data;
    if (data == null) return const Center(child: Text('No data'));

    return RefreshIndicator(
      onRefresh: provider.fetch,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(title: 'Pets', value: data.statistics.totalPets.toString(), icon: Icons.pets),
              _StatCard(title: 'Bookings', value: data.statistics.totalBookings.toString(), icon: Icons.event_note),
              _StatCard(title: 'Upcoming', value: data.statistics.upcomingBookings.toString(), icon: Icons.upcoming),
              _StatCard(title: 'Treatments', value: data.statistics.totalTreatments.toString(), icon: Icons.medical_information),
            ],
          ),
          const SizedBox(height: 16),
          if (data.nextBooking != null)
            Card(
              child: ListTile(
                title: Text('Next: ${data.nextBooking!.serviceType}'),
                subtitle: Text('${data.nextBooking!.bookingDate} ${data.nextBooking!.bookingTime} • ${data.nextBooking!.pet.name}'),
                leading: const Icon(Icons.schedule),
              ),
            ),
          const SizedBox(height: 16),
          const Text('Recent bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...data.recentBookings.map((b) => Card(
                child: ListTile(
                  title: Text(b.serviceType),
                  subtitle: Text('${b.bookingDate} ${b.bookingTime} • ${b.pet.name}'),
                  trailing: Text(b.status),
                ),
              )),
          const SizedBox(height: 16),
          const Text('Your pets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...data.pets.map((p) => Card(
                child: ListTile(
                  title: Text(p.name),
                  subtitle: Text(p.species),
                  trailing: p.tag != null ? const Icon(Icons.qr_code_2) : null,
                ),
              )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
