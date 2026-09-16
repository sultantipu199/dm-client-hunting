import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/leads_provider.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

/// Top HUD display with executive acquisition metrics and quick filter actions.
class QuickStatsBar extends ConsumerWidget {
  const QuickStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(leadsStatsProvider);
    final filter = ref.watch(filterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard(
            label: 'NEW LEADS',
            value: '${stats['new'] ?? 0}',
            icon: Icons.flash_on_rounded,
            accentColor: AppTheme.electricCyan,
            isSelected: filter.activeTab == 'new',
            onTap: () {
              ref.read(filterProvider.notifier).state =
                  filter.copyWith(activeTab: 'new');
            },
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            label: 'CONTACTED',
            value: '${stats['contacted'] ?? 0}',
            icon: Icons.send_rounded,
            accentColor: AppTheme.mintEmerald,
            isSelected: filter.activeTab == 'contacted',
            onTap: () {
              ref.read(filterProvider.notifier).state =
                  filter.copyWith(activeTab: 'contacted');
            },
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            label: 'REMOTE VERIFIED',
            value: '${stats['remoteVerified'] ?? 0}',
            icon: Icons.public_rounded,
            accentColor: AppTheme.royalIndigo,
            isSelected: filter.onlyRemoteVerified,
            onTap: () {
              ref.read(filterProvider.notifier).state = filter.copyWith(
                onlyRemoteVerified: !filter.onlyRemoteVerified,
              );
            },
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            label: 'BLACKLIST GUARD',
            value: '${stats['blacklisted'] ?? 0}',
            icon: Icons.shield_rounded,
            accentColor: AppTheme.sunsetCoral,
            isSelected: filter.activeTab == 'blacklisted',
            onTap: () {
              ref.read(filterProvider.notifier).state =
                  filter.copyWith(activeTab: 'blacklisted');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 14,
      borderColor: isSelected ? accentColor : AppTheme.borderNeonSubtle,
      borderWidth: isSelected ? 1.5 : 1.0,
      backgroundColor: isSelected
          ? accentColor.withOpacity(0.12)
          : AppTheme.cardSurface,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: accentColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.cleanAlabaster,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? accentColor : AppTheme.mutedSlate,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
