import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/pet_provider.dart';
import 'create_booking_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetch();
      context.read<PetProvider>().fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    return Scaffold(
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.fetch(status: _status),
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  Row(
                    children: [
                      const Text('Filter:'),
                      const SizedBox(width: 8),
                      DropdownButton<String?>(
                        value: _status,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                          DropdownMenuItem(value: 'completed', child: Text('Completed')),
                          DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                        ],
                        onChanged: (v) => setState(() {
                          _status = v;
                          provider.fetch(status: _status);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...provider.bookings.map((b) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.event_note),
                          title: Text(b.serviceType),
                          subtitle: Text('${b.bookingDate} ${b.bookingTime} • ${b.pet.name}'),
                          trailing: Text(b.status),
                          onLongPress: b.status == 'upcoming'
                              ? () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Cancel booking?'),
                                      content: const Text('This action cannot be undone.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, cancel')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    final err = await context.read<BookingProvider>().cancel(b.id);
                                    if (err != null && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                    }
                                  }
                                }
                              : null,
                        ),
                      )),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateBookingScreen()),
          );
          if (created == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking created')));
          }
        },
        label: const Text('New Booking'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
