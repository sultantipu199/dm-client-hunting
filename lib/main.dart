import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/leads_provider.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/add_lead_sheet.dart';
import 'widgets/blacklist_dialog.dart';
import 'widgets/filter_bar.dart';
import 'widgets/glass_container.dart';
import 'widgets/manual_scraper_sheet.dart';
import 'widgets/modern_lead_card.dart';
import 'widgets/quick_stats_bar.dart';

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
    final keyCtrl = TextEditingController(text: StorageService.getApiKey() ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded, color: AppTheme.electricCyan, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Executive Engine Config',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.cleanAlabaster,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.subduedSilver),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Google Gemini 1.5 Flash API Key (Optional):',
                  style: TextStyle(fontSize: 12, color: AppTheme.subduedSilver),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: keyCtrl,
                  obscureText: true,
                  style: const TextStyle(fontSize: 13, color: AppTheme.cleanAlabaster),
                  cursorColor: AppTheme.electricCyan,
                  decoration: InputDecoration(
                    hintText: 'Enter AI Studio Gemini key or leave blank for local heuristic',
                    hintStyle: const TextStyle(fontSize: 11, color: AppTheme.mutedSlate),
                    filled: true,
                    fillColor: AppTheme.obsidianNavy,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderNeonSubtle),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await StorageService.setApiKey(keyCtrl.text.trim());
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Configuration saved to Hive successfully!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.electricCyan,
                      foregroundColor: AppTheme.obsidianNavy,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Save Settings',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DM CLIENT HUNTER',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.cleanAlabaster,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'MENA Outbound Acquisition Matrix',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.electricCyan,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Manual Scraper Trigger Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            child: Tooltip(
              message: 'Launch Manual Lead Scraper',
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showScraperModal();
                },
                icon: const Icon(
                  Icons.travel_explore_rounded,
                  size: 15,
                  color: AppTheme.obsidianNavy,
                ),
                label: const Text(
                  'SCRAPER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: AppTheme.obsidianNavy,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCyan,
                  foregroundColor: AppTheme.obsidianNavy,
                  elevation: 3,
                  shadowColor: AppTheme.electricCyan.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Manual Lead Entry',
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.electricCyan),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showAddLeadModal();
            },
          ),
          IconButton(
            tooltip: 'Blacklist Guard',
            icon: const Icon(Icons.shield_outlined, color: AppTheme.subduedSilver),
            onPressed: () {
              HapticFeedback.lightImpact();
              showDialog(
                context: context,
                builder: (_) => const BlacklistGuardDialog(),
              );
            },
          ),
          IconButton(
            tooltip: 'Engine Config',
            icon: const Icon(Icons.tune_rounded, color: AppTheme.subduedSilver),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showSettingsModal();
            },
          ),
          const SizedBox(width: 8),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardSurfaceRaw,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderNeonSubtle),
              ),
              child: const Icon(
                Icons.radar_rounded,
                size: 42,
                color: AppTheme.mutedSlate,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Leads Matching Criteria',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.cleanAlabaster,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try clearing corridor or marketing gap filters, or pull down to reload from Hive storage.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.subduedSilver,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
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
                  label: const Text('Add Lead Manually', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                    foregroundColor: AppTheme.obsidianNavy,
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
