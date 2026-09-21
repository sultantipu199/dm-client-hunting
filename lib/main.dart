import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/leads_provider.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/add_lead_sheet.dart';
import 'widgets/filter_bar.dart';
import 'widgets/manual_scraper_sheet.dart';
import 'widgets/modern_lead_card.dart';
import 'widgets/quick_stats_bar.dart';
import 'widgets/settings_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system navigation and status bar style for obsidian aesthetic
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.obsidianNavy,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive CE and load local storage
  await StorageService.init();

  runApp(
    const ProviderScope(
      child: DmClientHuntingApp(),
    ),
  );
}

class DmClientHuntingApp extends StatelessWidget {
  const DmClientHuntingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DM Client Hunter MENA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ExecutiveDashboardScreen(),
    );
  }
}

class ExecutiveDashboardScreen extends ConsumerStatefulWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  ConsumerState<ExecutiveDashboardScreen> createState() =>
      _ExecutiveDashboardScreenState();
}

class _ExecutiveDashboardScreenState
    extends ConsumerState<ExecutiveDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabControllerTick);
  }

  void _onTabControllerTick() {
    if (!_tabController.indexIsChanging) {
      final tabs = ['new', 'contacted', 'all', 'blacklisted'];
      if (_tabController.index < tabs.length) {
        final targetTab = tabs[_tabController.index];
        final currentTab = ref.read(filterProvider).activeTab;
        if (currentTab != targetTab) {
          ref.read(filterProvider.notifier).state =
              ref.read(filterProvider).copyWith(activeTab: targetTab);
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showScraperModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ManualScraperSheet(),
    );
  }

  void _showAddLeadModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AddLeadSheet(),
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SettingsSheet(),
    );
  }

  void _showClearRadarConfirmation() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardSurfaceRaw,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.sunsetCoral.withOpacity(0.5)),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: AppTheme.sunsetCoral, size: 24),
            SizedBox(width: 10),
            Text(
              'Clear All Leads?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.cleanAlabaster,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to clear all leads from your radar?\n\nYou can restore the 78+ default verified MENA commercial inventory anytime from Settings.',
          style: TextStyle(fontSize: 13, color: AppTheme.subduedSilver, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.subduedSilver)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(leadsProvider.notifier).clearAllLeads();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.cardSurfaceRaw,
                    content: const Text('All leads cleared from Radar.'),
                    action: SnackBarAction(
                      label: 'Restore',
                      textColor: AppTheme.electricCyan,
                      onPressed: () async {
                        await ref.read(leadsProvider.notifier).resetToDefaultLeads();
                      },
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
            label: const Text('Clear Radar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sunsetCoral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Synchronize TabController smoothly when activeTab changes from QuickStatsBar or filters
    ref.listen<String>(filterProvider.select((f) => f.activeTab), (previous, next) {
      final tabs = ['new', 'contacted', 'all', 'blacklisted'];
      final targetIndex = tabs.indexOf(next);
      if (targetIndex != -1 && _tabController.index != targetIndex) {
        _tabController.animateTo(targetIndex);
      }
    });

    final filteredLeads = ref.watch(filteredLeadsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.electricCyan, AppTheme.royalIndigo],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.radar_rounded,
                size: 18,
                color: AppTheme.obsidianNavy,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DM CLIENT HUNTER',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.cleanAlabaster,
                      letterSpacing: 0.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'MENA Acquisition Radar',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.electricCyan,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // 1. Scraper Trigger Pill Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            child: Tooltip(
              message: 'Launch Manual Lead Scraper',
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showScraperModal();
                },
                icon: const Icon(
                  Icons.travel_explore_rounded,
                  size: 14,
                  color: AppTheme.obsidianNavy,
                ),
                label: const Text(
                  'SCRAPER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: AppTheme.obsidianNavy,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCyan,
                  foregroundColor: AppTheme.obsidianNavy,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          // 2. Add Lead Button
          IconButton(
            tooltip: 'Add Lead Manually',
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.electricCyan, size: 20),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showAddLeadModal();
            },
          ),
          // 3. Clear Leads Button (Requested feature)
          IconButton(
            tooltip: 'Clear All Leads',
            icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.sunsetCoral, size: 21),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(),
            onPressed: _showClearRadarConfirmation,
          ),
          // 4. Executive Settings & Control Hub Button (Requested feature)
          IconButton(
            tooltip: 'Settings & Control Hub',
            icon: const Icon(Icons.tune_rounded, color: AppTheme.cleanAlabaster, size: 20),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showSettingsModal();
            },
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardSurfaceRaw.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderNeonSubtle),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                HapticFeedback.selectionClick();
                final tabs = ['new', 'contacted', 'all', 'blacklisted'];
                if (index < tabs.length) {
                  ref.read(filterProvider.notifier).state =
                      ref.read(filterProvider).copyWith(activeTab: tabs[index]);
                }
              },
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppTheme.electricCyan.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.electricCyan.withOpacity(0.4)),
              ),
              labelColor: AppTheme.cleanAlabaster,
              unselectedLabelColor: AppTheme.mutedSlate,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'New Leads'),
                Tab(text: 'Contacted'),
                Tab(text: 'All Radar'),
                Tab(text: 'Blacklisted'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Top telemetry HUD
            const QuickStatsBar(),
            // Search and Corridor filter pills
            const FilterBar(),
            const SizedBox(height: 4),

            // Leads List / Empty State
            Expanded(
              child: filteredLeads.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: AppTheme.electricCyan,
                      backgroundColor: AppTheme.cardSurfaceRaw,
                      onRefresh: () async {
                        HapticFeedback.mediumImpact();
                        await StorageService.syncLeadsFromFeed();
                        ref.read(leadsProvider.notifier).refresh();
                      },
                      child: ListView.builder(
                        itemCount: filteredLeads.length,
                        padding: const EdgeInsets.only(bottom: 24, top: 4),
                        itemBuilder: (context, index) {
                          final lead = filteredLeads[index];
                          return ModernLeadCard(
                            key: ValueKey(lead.id),
                            lead: lead,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Manually List a New Lead',
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showAddLeadModal();
        },
        backgroundColor: AppTheme.electricCyan,
        foregroundColor: AppTheme.obsidianNavy,
        elevation: 4,
        icon: const Icon(Icons.add_business_rounded, size: 18),
        label: const Text(
          'ADD LEAD',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: AppTheme.obsidianNavy,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final allLeads = ref.watch(leadsProvider);
    final isCompletelyEmpty = allLeads.isEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardSurfaceRaw,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompletelyEmpty
                      ? AppTheme.sunsetCoral.withOpacity(0.5)
                      : AppTheme.borderNeonSubtle,
                ),
                boxShadow: isCompletelyEmpty
                    ? [
                        BoxShadow(
                          color: AppTheme.sunsetCoral.withOpacity(0.15),
                          blurRadius: 20,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                isCompletelyEmpty ? Icons.delete_sweep_rounded : Icons.radar_rounded,
                size: 44,
                color: isCompletelyEmpty ? AppTheme.sunsetCoral : AppTheme.mutedSlate,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isCompletelyEmpty ? 'Lead Radar is Empty' : 'No Leads Matching Criteria',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.cleanAlabaster,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCompletelyEmpty
                  ? 'All leads have been cleared. Restore the 78+ verified authentic MENA commercial inventory with 1 tap, or discover new leads with the scraper.'
                  : 'Try clearing corridor or marketing gap filters, or pull down to reload from storage.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.subduedSilver,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                if (isCompletelyEmpty)
                  ElevatedButton.icon(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      await ref.read(leadsProvider.notifier).resetToDefaultLeads();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Restored 78+ authentic verified MENA leads!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    label: const Text(
                      'Restore Verified Leads (78+)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mintEmerald,
                      foregroundColor: AppTheme.obsidianNavy,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(filterProvider.notifier).state = const LeadsFilterState();
                    },
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Reset All Filters', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.subduedSilver,
                      side: const BorderSide(color: AppTheme.borderNeonSubtle),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showAddLeadModal();
                  },
                  icon: const Icon(Icons.add_business_rounded, size: 16),
                  label: const Text(
                    'Add Lead Manually',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                    foregroundColor: AppTheme.obsidianNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showScraperModal();
                  },
                  icon: const Icon(Icons.travel_explore_rounded, size: 16),
                  label: const Text('Launch Scraper', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.electricCyan,
                    side: BorderSide(color: AppTheme.electricCyan.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
