import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/pet_provider.dart';
import '../../../models/booking.dart';
import 'create_booking_screen.dart';
import 'booking_details_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String? _status;
  int? _petId;
  String? _selectedDate; // YYYY-MM-DD

  // Colors
  static const _primary = Color(0xFFC1E8F7);
  static const _accent = Color(0xFF1E3A8A);

  String _formatDate(String raw) {
    try {
      // Handle either 'YYYY-MM-DD' or ISO strings
      final d = DateTime.parse(raw);
      return DateFormat('EEE, MMM d').format(d);
    } catch (_) {
      return raw; // Fallback to raw if parsing fails
    }
  }

  String _formatTime(String raw) {
    try {
      // If it's ISO string, parse and format
      if (raw.contains('T')) {
        // Do NOT shift timezone for appointment wall-time
        final dt = DateTime.parse(raw);
        final wall = DateTime(2000, 1, 1, dt.hour, dt.minute);
        return DateFormat('h:mm a').format(wall);
      }
      // Expect HH:mm
      final parts = raw.split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final wall = DateTime(2000, 1, 1, h, m);
        return DateFormat('h:mm a').format(wall);
      }
      return raw;
    } catch (_) {
      return raw;
    }
  }

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B); // amber-500
      case 'confirmed':
        return const Color(0xFF10B981); // emerald-500
      case 'completed':
        return const Color(0xFF64748B); // slate-500
      case 'cancelled':
        return const Color(0xFFEF4444); // red-500
      default:
        return _accent;
    }
  }

  Widget _statusChip(String status) {
    final bg = _statusBg(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: bg.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _bookingCard(Booking b) {
    final dateText = _formatDate(b.bookingDate);
    final timeText = _formatTime(b.bookingTime);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon circle - vertically centered
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
            child: const Icon(Icons.event, color: _accent),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  b.serviceType,
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: _accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$dateText • $timeText',
                        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.pets, size: 16, color: _accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b.pet.name,
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status chip - positioned on the right, vertically centered
          _statusChip(b.status),
        ],
      ),
    );
  }

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
              onRefresh: () => provider.fetch(status: _status, petId: _petId, date: _selectedDate),
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // Pet dropdown filter (above status chips)
                  Consumer<PetProvider>(
                    builder: (context, petProv, _) {
                      final pets = petProv.pets;
                      return DropdownButtonFormField<int?>(
                        value: _petId,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All Pets'),
                          ),
                          ...pets.map((p) => DropdownMenuItem<int?>(
                                value: p.id,
                                child: Text(p.name),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() => _petId = val);
                          provider.fetch(status: _status, petId: _petId, date: _selectedDate);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  // Date filter (picker)
                  Builder(builder: (context) {
                    final display = _selectedDate == null
                        ? 'All Dates'
                        : DateFormat('EEE, MMM d').format(DateTime.parse(_selectedDate!));
                    return InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final initial = _selectedDate != null
                            ? DateTime.parse(_selectedDate!)
                            : now;
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 2),
                        );
                        if (picked != null) {
                          final ymd = DateFormat('yyyy-MM-dd').format(picked);
                          setState(() => _selectedDate = ymd);
                          provider.fetch(status: _status, petId: _petId, date: _selectedDate);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_selectedDate != null)
                                IconButton(
                                  tooltip: 'Clear date',
                                  onPressed: () {
                                    setState(() => _selectedDate = null);
                                    provider.fetch(status: _status, petId: _petId, date: _selectedDate);
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        child: Text(display, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  // Modern filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _status == null,
                          onTap: () {
                            setState(() {
                              _status = null;
                              provider.fetch(status: _status, petId: _petId, date: _selectedDate);
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Pending',
                          selected: _status == 'pending',
                          color: const Color(0xFFF59E0B),
                          onTap: () {
                            setState(() {
                              _status = 'pending';
                              provider.fetch(status: _status, petId: _petId, date: _selectedDate);
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Confirmed',
                          selected: _status == 'confirmed',
                          color: const Color(0xFF10B981),
                          onTap: () {
                            setState(() {
                              _status = 'confirmed';
                              provider.fetch(status: _status, petId: _petId, date: _selectedDate);
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Completed',
                          selected: _status == 'completed',
                          color: const Color(0xFF64748B),
                          onTap: () {
                            setState(() {
                              _status = 'completed';
                              provider.fetch(status: _status, petId: _petId, date: _selectedDate);
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Cancelled',
                          selected: _status == 'cancelled',
                          color: const Color(0xFFEF4444),
                          onTap: () {
                            setState(() {
                              _status = 'cancelled';
                              provider.fetch(status: _status, petId: _petId, date: _selectedDate);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...provider.bookings.map((b) => GestureDetector(
                        onTap: () async {
                          final refreshNeeded = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingDetailsScreen(booking: b),
                            ),
                          );
                          if (refreshNeeded == true && mounted) {
                            provider.fetch(status: _status, petId: _petId, date: _selectedDate);
                          }
                        },
                        onLongPress: b.status == 'pending'
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
                        child: _bookingCard(b),
                      )),
                  // Empty state
                  if (provider.bookings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC1E8F7).withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.event_busy_outlined,
                              size: 50,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            () {
                              final pets = context.read<PetProvider>().pets;
                              final hasPet = _petId != null && pets.any((p) => p.id == _petId);
                              final name = hasPet
                                  ? pets.firstWhere((p) => p.id == _petId).name
                                  : null;
                              if (_status == null && !hasPet) return 'No bookings yet';
                              if (_status != null && !hasPet) return 'No ${_status} bookings';
                              if (_status == null && hasPet) return 'No bookings for $name';
                              return 'No ${_status} bookings for $name';
                            }(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _status == null
                                ? 'Create your first booking to get started'
                                : 'Try selecting a different filter',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_status == null && _petId == null)
                            ElevatedButton.icon(
                              onPressed: () async {
                                final created = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(builder: (_) => const CreateBookingScreen()),
                                );
                                if (created == true && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Booking created')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Create Booking'),
                            ),
                        ],
                      ),
                    ),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? const Color(0xFF1E3A8A);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? bgColor : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: bgColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
