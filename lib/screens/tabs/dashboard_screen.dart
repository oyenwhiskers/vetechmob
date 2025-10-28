import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import 'bookings/create_booking_screen.dart';
import 'pets/pet_form_screen.dart';
import 'pets/pet_detail_screen.dart';
import 'ai_diagnose_screen.dart';
import '../../models/dashboard.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int)? onSwitchTab;
  
  const DashboardScreen({super.key, this.onSwitchTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _fmtDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return DateFormat('EEE, MMM d').format(d);
    } catch (_) {
      return raw;
    }
  }

  String _fmtTime(String raw) {
    try {
      // If ISO-like, avoid timezone shifts; format by hour/min only
      if (raw.contains('T')) {
        final dt = DateTime.parse(raw);
        final wall = DateTime(2000, 1, 1, dt.hour, dt.minute);
        return DateFormat('h:mm a').format(wall);
      }
      // Expect HH:mm or HH:mm:ss
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
    final userName = context.read<AuthProvider>().user?.name;
    if (provider.isLoading) {
      // Simple pleasant loading state matching the new layout
      return const _DashboardSkeleton();
    }
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(provider.error!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: provider.fetch,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final DashboardData? data = provider.data;
    if (data == null) return const Center(child: Text('No data'));

    return RefreshIndicator(
      onRefresh: provider.fetch,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          _HeaderSection(userName: userName),

          // Stats grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              shrinkWrap: true,
              children: [
                _StatCard(title: 'Pets', value: data.statistics.totalPets.toString(), icon: Icons.pets, color: Colors.teal, onTap: () {
                  widget.onSwitchTab?.call(1); // Switch to Pets tab
                }),
                _StatCard(title: 'Bookings', value: data.statistics.totalBookings.toString(), icon: Icons.event_note, color: Colors.indigo, onTap: () {
                  widget.onSwitchTab?.call(2); // Switch to Bookings tab
                }),
                _StatCard(title: 'Upcoming', value: data.statistics.upcomingBookings.toString(), icon: Icons.upcoming, color: Colors.orange, onTap: () {
                  widget.onSwitchTab?.call(2); // Switch to Bookings tab
                }),
                _StatCard(title: 'Treatments', value: data.statistics.totalTreatments.toString(), icon: Icons.medical_information, color: Colors.pink, onTap: () {}),
              ],
            ),
          ),

          // Next booking
          if (data.nextBooking != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _NextBookingCard(
                title: data.nextBooking!.serviceType,
                subtitle: '${_fmtDate(data.nextBooking!.bookingDate)} • ${_fmtTime(data.nextBooking!.bookingTime)} • ${data.nextBooking!.pet.name}',
              ),
            ),

          // Quick actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _QuickActionsRow(),
          ),

          // Recent bookings - vertical list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _SectionHeader(
              title: 'Recent bookings',
              action: data.recentBookings.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded),
                      onPressed: () {
                        // Switch to Bookings tab (index 2)
                        widget.onSwitchTab?.call(2);
                      },
                      tooltip: 'View all',
                    )
                  : null,
            ),
          ),
          if (data.recentBookings.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _EmptyStateCard(
                message: 'No recent bookings yet',
                icon: Icons.event_available_outlined,
                action: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateBookingScreen()));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Create booking'),
                ),
              ),
            )
          else
            ...data.recentBookings.take(3).map((b) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: _BookingCard(
                    title: b.serviceType,
                    subtitle: '${_fmtDate(b.bookingDate)} • ${_fmtTime(b.bookingTime)}',
                    petName: b.pet.name,
                    status: b.status,
                    onTap: () {},
                  ),
                )),

          // Pets - vertical list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _SectionHeader(
              title: 'Your pets',
              action: data.pets.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded),
                      onPressed: () {
                        // Switch to Pets tab (index 1)
                        widget.onSwitchTab?.call(1);
                      },
                      tooltip: 'Manage',
                    )
                  : null,
            ),
          ),
          if (data.pets.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _EmptyStateCard(
                message: 'No pets yet',
                icon: Icons.pets_outlined,
                action: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PetFormScreen()));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add pet'),
                ),
              ),
            )
          else
            ...data.pets.take(3).map((p) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: _PetCardVertical(
                    name: p.name,
                    species: p.species,
                    breed: p.breed,
                    hasTag: p.tag != null,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PetDetailScreen(petId: p.id)));
                    },
                  ),
                )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8))),
                    const SizedBox(height: 2),
                    Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String? userName;
  const _HeaderSection({this.userName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const textColor = Color(0xFF1E3A8A); // Dark navy for better contrast
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(cs.primary, cs.primaryContainer, .05)!,
            cs.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: textColor.withOpacity(.08),
                shape: BoxShape.circle,
                border: Border.all(color: textColor.withOpacity(.15), width: 1.5),
              ),
              child: Icon(Icons.dashboard_rounded, color: textColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard', style: theme.textTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                  if (userName != null) ...[
                    const SizedBox(height: 2),
                    Text('Welcome back, $userName', style: theme.textTheme.bodyMedium?.copyWith(color: textColor.withOpacity(.85))),
                  ],
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: textColor.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.notifications_none_rounded, color: textColor),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 16))),
        if (action != null) action!,
      ],
    );
  }
}

class _NextBookingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _NextBookingCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: const Color(0xFFC1E8F7), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.schedule, color: Color(0xFF1E3A8A)),
        ),
        title: Text(title, style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: cs.onSecondaryContainer.withOpacity(.9))),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String petName;
  final String status;
  final VoidCallback onTap;
  const _BookingCard({required this.title, required this.subtitle, required this.petName, required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Enhanced status colors with better contrast
    Color statusBg;
    Color statusText;
    switch (status.toLowerCase()) {
      case 'pending':
        statusBg = const Color(0xFFF59E0B); // amber-500
        statusText = Colors.white;
        break;
      case 'confirmed':
        statusBg = const Color(0xFF10B981); // emerald-500
        statusText = Colors.white;
        break;
      case 'completed':
        statusBg = const Color(0xFF64748B); // slate-500
        statusText = Colors.white;
        break;
      case 'cancelled':
        statusBg = const Color(0xFFEF4444); // red-500
        statusText = Colors.white;
        break;
      default:
        statusBg = const Color(0xFF1E3A8A);
        statusText = Colors.white;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFC1E8F7), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.event_note_rounded, color: Color(0xFF1E3A8A), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 3),
                    // Pet name row
                    Row(
                      children: [
                        const Icon(Icons.pets, size: 14, color: Color(0xFF1E3A8A)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            petName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Date time row (now below name)
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Color(0xFF1E3A8A)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
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
              // Status badge positioned on right
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: statusBg.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetCardVertical extends StatelessWidget {
  final String name;
  final String species;
  final String? breed;
  final bool hasTag;
  final VoidCallback onTap;
  const _PetCardVertical({required this.name, required this.species, this.breed, required this.hasTag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final speciesLower = species.toLowerCase();
    final bool isDogOrCat = speciesLower == 'dog' || speciesLower == 'cat';
    final speciesIcon = speciesLower == 'dog'
        ? FontAwesomeIcons.dog // Dog icon
        : speciesLower == 'cat'
            ? FontAwesomeIcons.cat // Cat icon
            : Icons.cruelty_free; // Other animals
    
    // Capitalize species name
    final speciesDisplay = species.substring(0, 1).toUpperCase() + species.substring(1).toLowerCase();
    
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: cs.tertiary.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: isDogOrCat
                    ? FaIcon(speciesIcon, color: cs.tertiary, size: 22)
                    : Icon(speciesIcon, color: cs.tertiary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(breed != null && breed!.isNotEmpty ? '$speciesDisplay • $breed' : speciesDisplay, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (hasTag)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_2, color: Colors.green, size: 18),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: Theme.of(context).hintColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget action;
  const _EmptyStateCard({required this.message, required this.icon, required this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).hintColor),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
            const SizedBox(height: 12),
            action,
          ],
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  Widget _box({double h = 16, double r = 12}) => Container(
        height: h,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.06),
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          height: 110,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.primary.withOpacity(.85),
            ]),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Row(children: [Expanded(child: _box(h: 92)), const SizedBox(width: 12), Expanded(child: _box(h: 92))]),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: _box(h: 92)), const SizedBox(width: 12), Expanded(child: _box(h: 92))]),
              const SizedBox(height: 16),
              _box(h: 64, r: 16),
              const SizedBox(height: 16),
              _box(h: 20, r: 6),
              const SizedBox(height: 12),
              SizedBox(height: 120, child: Row(children: [Expanded(child: _box(h: 120, r: 16)), const SizedBox(width: 12), Expanded(child: _box(h: 120, r: 16))])),
              const SizedBox(height: 16),
              _box(h: 20, r: 6),
              const SizedBox(height: 12),
              SizedBox(height: 120, child: Row(children: [Expanded(child: _box(h: 120, r: 16)), const SizedBox(width: 12), Expanded(child: _box(h: 120, r: 16))])),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
  const accentColor = Color(0xFF1E3A8A); // Dark navy
    
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            color: accentColor,
            icon: Icons.psychology_outlined,
            label: 'AI Diagnose',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AIDiagnoseScreen())),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionCard({required this.color, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(.2), width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
