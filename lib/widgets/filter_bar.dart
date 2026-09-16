import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/zones.dart';
import '../providers/leads_provider.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

/// Search and Corridor & Gap Filter Pills for targeted client hunting
class FilterBar extends ConsumerStatefulWidget {
  const FilterBar({super.key});

  @override
  ConsumerState<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<FilterBar> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(
      text: ref.read(filterProvider).searchQuery,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            borderRadius: 12,
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppTheme.subduedSilver, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: AppTheme.cleanAlabaster, fontSize: 13),
                    cursorColor: AppTheme.electricCyan,
                    decoration: const InputDecoration(
                      hintText: 'Search companies, corridors, or gaps...',
                      hintStyle: TextStyle(color: AppTheme.mutedSlate, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (val) {
                      ref.read(filterProvider.notifier).state =
                          filter.copyWith(searchQuery: val);
                    },
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      ref.read(filterProvider.notifier).state =
                          filter.copyWith(searchQuery: '');
                    },
                    child: const Icon(Icons.close_rounded, color: AppTheme.subduedSilver, size: 18),
                  ),
              ],
            ),
          ),
        ),

        // Horizontal filter tags (Corridors & Gaps)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              // All Reset Pill
              _buildFilterPill(
                label: 'All Corridors',
                isSelected: filter.selectedCorridor == null,
                onTap: () {
                  ref.read(filterProvider.notifier).state =
                      filter.copyWith(clearCorridor: true);
                },
              ),
              const SizedBox(width: 8),

              // Country / Major Corridor Hubs
              ...MenaMarketZones.allCorridors.take(8).map((corridor) {
                final isSelected = filter.selectedCorridor == corridor;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterPill(
                    label: corridor,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(filterProvider.notifier).state = filter.copyWith(
                        selectedCorridor: isSelected ? null : corridor,
                        clearCorridor: isSelected,
                      );
                    },
                  ),
                );
              }),

              // Marketing Gaps
              ...MenaMarketZones.marketingGaps.map((gap) {
                final isSelected = filter.selectedMarketingGap == gap;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterPill(
                    label: gap,
                    isSelected: isSelected,
                    accentColor: AppTheme.amberGold,
                    onTap: () {
                      ref.read(filterProvider.notifier).state = filter.copyWith(
                        selectedMarketingGap: isSelected ? null : gap,
                        clearGap: isSelected,
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color accentColor = AppTheme.electricCyan,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.18)
              : AppTheme.cardSurfaceRaw.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : AppTheme.borderNeonSubtle,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.2),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.cleanAlabaster : AppTheme.subduedSilver,
          ),
        ),
      ),
    );
  }
}
