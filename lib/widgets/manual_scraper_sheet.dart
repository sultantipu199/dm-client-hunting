import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/leads_provider.dart';
import '../services/lead_scraper_service.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

/// Modal bottom sheet allowing users to trigger manual lead scraping on demand
class ManualScraperSheet extends ConsumerStatefulWidget {
  const ManualScraperSheet({super.key});

  @override
  ConsumerState<ManualScraperSheet> createState() => _ManualScraperSheetState();
}

class _ManualScraperSheetState extends ConsumerState<ManualScraperSheet> {
  String _selectedCountry = 'All MENA Hubs';
  String _selectedSector = 'All High-Ticket Sectors';
  int _batchSize = 10;
  String _mode = 'Deep Corridor Crawler';

  bool _isScraping = false;
  double _progress = 0.0;
  String _currentStep = '';
  final List<String> _telemetryLogs = [];
  ScrapeReport? _completedReport;

  final List<String> _countries = [
    'All MENA Hubs',
    'Saudi Arabia (KSA)',
    'United Arab Emirates (UAE)',
    'Qatar',
    'Kuwait',
    'Bahrain',
    'Oman',
    'Egypt',
  ];

  final List<String> _sectors = [
    'All High-Ticket Sectors',
    'Luxury Real Estate Agencies',
    'Private Healthcare & Aesthetic Clinics',
    'Newly Formed Corporate Firms',
    'High-Growth E-Commerce Brands',
    'Management & Strategy Consulting',
    'B2B Tech & SaaS Solutions',
  ];

  Future<void> _startScraping() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isScraping = true;
      _progress = 0.05;
      _currentStep = 'Initializing scraper...';
      _telemetryLogs.clear();
      _completedReport = null;
    });

    try {
      final report = await LeadScraperService.runManualScrape(
        targetCountry: _selectedCountry,
        targetSector: _selectedSector,
        targetCount: _batchSize,
        mode: _mode,
        onProgress: (stepMessage, progress) {
          if (mounted) {
            setState(() {
              _currentStep = stepMessage;
              _progress = progress;
              _telemetryLogs.insert(0, stepMessage);
            });
          }
        },
      );

      // Persist to provider & Hive
      if (report.newLeads.isNotEmpty) {
        await ref.read(leadsProvider.notifier).addLeadsBatch(report.newLeads);
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _isScraping = false;
          _completedReport = report;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScraping = false;
          _currentStep = 'Scrape encountered an error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.obsidianNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.mutedSlate.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.electricCyan, AppTheme.royalIndigo],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.electricCyan.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    size: 20,
                    color: AppTheme.obsidianNavy,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Autonomous MENA Scraper',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.cleanAlabaster,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'On-Demand High-Ticket Lead Mining & Validation',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.electricCyan,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.subduedSilver, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_completedReport == null) ...[
              // Mode Selector Pill
              Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      label: 'Deep Crawler',
                      icon: Icons.radar_rounded,
                      isSelected: _mode == 'Deep Corridor Crawler',
                      onTap: _isScraping
                          ? null
                          : () => setState(() => _mode = 'Deep Corridor Crawler'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModeTab(
                      label: 'Cloud Feed Sync',
                      icon: Icons.cloud_sync_rounded,
                      isSelected: _mode == 'Live Cloud Feed Sync',
                      onTap: _isScraping
                          ? null
                          : () => setState(() => _mode = 'Live Cloud Feed Sync'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Country Dropdown
              const Text(
                'Target Commercial Hub / Market:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.subduedSilver),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurfaceRaw,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderNeonSubtle),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCountry,
                    isExpanded: true,
                    dropdownColor: AppTheme.cardSurfaceRaw,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.electricCyan),
                    items: _countries.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(
                          c,
                          style: const TextStyle(fontSize: 12, color: AppTheme.cleanAlabaster),
                        ),
                      );
                    }).toList(),
                    onChanged: _isScraping
                        ? null
                        : (val) {
                            if (val != null) setState(() => _selectedCountry = val);
                          },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Sector Dropdown
              const Text(
                'Target Industry / Sector:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.subduedSilver),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurfaceRaw,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderNeonSubtle),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSector,
                    isExpanded: true,
                    dropdownColor: AppTheme.cardSurfaceRaw,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.electricCyan),
                    items: _sectors.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(
                          s,
                          style: const TextStyle(fontSize: 12, color: AppTheme.cleanAlabaster),
                        ),
                      );
                    }).toList(),
                    onChanged: _isScraping
                        ? null
                        : (val) {
                            if (val != null) setState(() => _selectedSector = val);
                          },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Batch Size Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Leads Batch Size:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.subduedSilver),
                  ),
                  Row(
                    children: [5, 10, 20].map((count) {
                      final isSelected = _batchSize == count;
                      return GestureDetector(
                        onTap: _isScraping ? null : () => setState(() => _batchSize = count),
                        child: Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.electricCyan.withOpacity(0.2)
                                : AppTheme.cardSurfaceRaw,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppTheme.electricCyan : AppTheme.borderNeonSubtle,
                            ),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? AppTheme.electricCyan : AppTheme.subduedSilver,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Active Scraping Progress Terminal
            if (_isScraping) ...[
              GlassContainer(
                padding: const EdgeInsets.all(14),
                borderRadius: 12,
                borderColor: AppTheme.electricCyan.withOpacity(0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.electricCyan),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentStep,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.electricCyan,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.subduedSilver),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: AppTheme.obsidianNavy,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.electricCyan),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 70,
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.obsidianNavy,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ListView.builder(
                        itemCount: _telemetryLogs.length,
                        itemBuilder: (context, idx) {
                          return Text(
                            '› ${_telemetryLogs[idx]}',
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: idx == 0 ? AppTheme.cleanAlabaster : AppTheme.mutedSlate,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Completed State
            if (_completedReport != null) ...[
              GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 14,
                borderColor: AppTheme.mintEmerald.withOpacity(0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.mintEmerald.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: AppTheme.mintEmerald, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scrape Completed Successfully!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.cleanAlabaster,
                                ),
                              ),
                              Text(
                                'Leads validated and committed to Hive database.',
                                style: TextStyle(fontSize: 11, color: AppTheme.subduedSilver),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildStatCard(
                          label: 'NEW DISCOVERED',
                          val: '+${_completedReport!.newLeads.length}',
                          accentColor: AppTheme.mintEmerald,
                        ),
                        const SizedBox(width: 8),
                        _buildStatCard(
                          label: 'SKIPPED / DUPES',
                          val: '${_completedReport!.duplicatesSkipped}',
                          accentColor: AppTheme.subduedSilver,
                        ),
                        const SizedBox(width: 8),
                        _buildStatCard(
                          label: 'SPEED',
                          val: '${_completedReport!.duration.inMilliseconds}ms',
                          accentColor: AppTheme.electricCyan,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Trigger Buttons
            if (_completedReport != null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _completedReport = null;
                          _isScraping = false;
                        });
                      },
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: const Text('Scrape Again', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.subduedSilver,
                        side: const BorderSide(color: AppTheme.borderNeonSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Switch active tab to 'new' and close
                        ref.read(filterProvider.notifier).state =
                            ref.read(filterProvider).copyWith(activeTab: 'new');
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      label: const Text('View in Radar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCyan,
                        foregroundColor: AppTheme.obsidianNavy,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isScraping ? null : _startScraping,
                  icon: _isScraping
                      ? const SizedBox.shrink()
                      : const Icon(Icons.flash_on_rounded, size: 18),
                  label: Text(
                    _isScraping ? 'SCRAPING IN PROGRESS...' : 'RUN MANUAL SCRAPER NOW',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                    foregroundColor: AppTheme.obsidianNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.electricCyan.withOpacity(0.15) : AppTheme.cardSurfaceRaw,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.electricCyan : AppTheme.borderNeonSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.electricCyan : AppTheme.subduedSilver,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppTheme.cleanAlabaster : AppTheme.subduedSilver,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String val,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.obsidianNavy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppTheme.subduedSilver,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
