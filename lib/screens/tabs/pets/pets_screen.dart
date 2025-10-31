import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/pet_provider.dart';
import '../../../models/pet.dart';
import 'pet_form_screen.dart';
import 'pet_detail_screen.dart';
import 'scan_tag_screen.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<PetProvider>().fetch(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PetProvider>();
    final cs = Theme.of(context).colorScheme;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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

    if (provider.pets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.pets, size: 60, color: cs.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'No pets yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first pet to start managing their health records and appointments',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  final created = await Navigator.of(context).push<Pet>(
                    MaterialPageRoute(builder: (_) => const PetFormScreen()),
                  );
                  if (created != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pet added successfully')),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Your First Pet'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: provider.fetch,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: provider.pets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final p = provider.pets[i];
            final speciesLower = p.species.toLowerCase();
            final isDogOrCat = speciesLower == 'dog' || speciesLower == 'cat';
            final speciesIcon = speciesLower == 'dog'
                ? FontAwesomeIcons.dog
                : speciesLower == 'cat'
                ? FontAwesomeIcons.cat
                : Icons.cruelty_free;
            final speciesDisplay =
                p.species.substring(0, 1).toUpperCase() +
                p.species.substring(1).toLowerCase();

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PetDetailScreen(petId: p.id),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      // Pet image or species icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color:
                              (p.petImageUrl != null &&
                                  p.petImageUrl!.isNotEmpty)
                              ? null
                              : const Color(0xFFC1E8F7).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: p.isDeceased
                              ? Border.all(
                                  color: Colors.grey.shade400,
                                  width: 2,
                                )
                              : null,
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child:
                            (p.petImageUrl != null && p.petImageUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: p.petImageUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) => isDogOrCat
                                    ? FaIcon(
                                        speciesIcon,
                                        color: const Color(0xFF1E3A8A),
                                        size: 28,
                                      )
                                    : Icon(
                                        speciesIcon,
                                        color: const Color(0xFF1E3A8A),
                                        size: 28,
                                      ),
                              )
                            : (isDogOrCat
                                  ? FaIcon(
                                      speciesIcon,
                                      color: const Color(0xFF1E3A8A),
                                      size: 28,
                                    )
                                  : Icon(
                                      speciesIcon,
                                      color: const Color(0xFF1E3A8A),
                                      size: 28,
                                    )),
                      ),
                      const SizedBox(width: 14),
                      // Pet info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  speciesDisplay,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context).hintColor,
                                      ),
                                ),
                                if (p.breed != null && p.breed!.isNotEmpty) ...[
                                  Text(
                                    ' • ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context).hintColor,
                                        ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      p.breed!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context).hintColor,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (p.age != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${p.age} ${p.age == 1 ? 'year' : 'years'} old',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).hintColor.withValues(alpha: 0.8),
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Tag indicator & actions
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (p.tag != null)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.qr_code_2,
                                color: Colors.green,
                                size: 20,
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              tooltip: 'Assign QR tag',
                              onPressed: () async {
                                final tag = await Navigator.of(context)
                                    .push<String>(
                                      MaterialPageRoute(
                                        builder: (_) => ScanTagScreen(),
                                      ),
                                    );
                                if (tag != null && mounted) {
                                  final err = await context
                                      .read<PetProvider>()
                                      .assignTag(p.id, tag);
                                  if (err != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(err)),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Tag assigned successfully',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).hintColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(
            context,
          ).push<Pet>(MaterialPageRoute(builder: (_) => const PetFormScreen()));
          if (created != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pet added successfully')),
            );
          }
        },
        label: const Text('Add Pet'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
