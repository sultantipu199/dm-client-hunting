import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/leads_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

/// Comprehensive Executive Control Center & Settings Sheet
/// Provides full lead lifecycle management (Clear, Reset, Restore, Export) and Engine Config.
class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  late final TextEditingController _keyCtrl;
  bool _obscureKey = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: StorageService.getApiKey() ?? '');
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  void _showConfirmClearDialog() {
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
            Icon(Icons.warning_amber_rounded, color: AppTheme.sunsetCoral, size: 24),
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
          'This will wipe all active leads from local storage.\n\nYou can restore the 78+ default verified MENA commercial inventory at any time with one tap.',
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
              setState(() => _isProcessing = true);
              await ref.read(leadsProvider.notifier).clearAllLeads();
              if (mounted) {
                setState(() => _isProcessing = false);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.cardSurfaceRaw,
                    content: const Text(
                      'All leads cleared successfully. You can restore defaults anytime.',
                      style: TextStyle(color: AppTheme.cleanAlabaster),
                    ),
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
            label: const Text('Clear All'),
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

  void _showConfirmResetContactedDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardSurfaceRaw,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderNeonSubtle),
        ),
        title: const Row(
          children: [
            Icon(Icons.restore_page_rounded, color: AppTheme.mintEmerald, size: 22),
            SizedBox(width: 10),
            Text(
              'Reset Contacted Status?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.cleanAlabaster),
            ),
          ],
        ),
        content: const Text(
          'All contacted leads will be moved back to "New Leads" so you can re-run your outreach campaigns.',
          style: TextStyle(fontSize: 13, color: AppTheme.subduedSilver, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.subduedSilver)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() => _isProcessing = true);
              await ref.read(leadsProvider.notifier).resetContactedStatus();
              if (mounted) {
                setState(() => _isProcessing = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contacted status reset for all leads!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mintEmerald,
              foregroundColor: AppTheme.obsidianNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reset Status', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreDefaultLeads() async {
    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);
    await ref.read(leadsProvider.notifier).resetToDefaultLeads();
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restored 78+ authentic verified MENA commercial leads!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearBlacklist() async {
    HapticFeedback.mediumImpact();
    await ref.read(leadsProvider.notifier).clearBlacklist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blacklist contacts cleared!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveApiKey() async {
    HapticFeedback.lightImpact();
    final key = _keyCtrl.text.trim();
    await StorageService.setApiKey(key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(key.isNotEmpty
              ? 'Gemini API key saved to local vault!'
              : 'Cleared API key. Local heuristic fallback active.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _exportLeadsSummary() {
    final leads = ref.read(leadsProvider);
    final stats = ref.read(leadsStatsProvider);
    final text = 'DM Client Hunter MENA Telemetry Report\n'
        'Generated: ${DateTime.now().toIso8601String()}\n'
        'Total Stored Leads: ${stats['total']}\n'
        'New Leads: ${stats['new']}\n'
        'Contacted Leads: ${stats['contacted']}\n'
        'Remote Verified: ${stats['remoteVerified']}\n'
        'Blacklisted Numbers: ${stats['blacklisted']}\n\n'
        'Top 5 Leads:\n'
        '${leads.take(5).map((l) => "• ${l.companyName} (${l.corridor}) - ${l.phone}").join("\n")}';

    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Telemetry summary copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(leadsStatsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.electricCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.settings_suggest_rounded, color: AppTheme.electricCyan, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Control Center & Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.cleanAlabaster,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Lead Database Management & Engine Config',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.mutedSlate,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.subduedSilver),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Telemetry Quick Stats
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.obsidianNavy.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderNeonSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('TOTAL LEADS', '${stats['total'] ?? 0}', AppTheme.electricCyan),
                    _buildDivider(),
                    _buildStatItem('ACTIVE NEW', '${stats['new'] ?? 0}', AppTheme.mintEmerald),
                    _buildDivider(),
                    _buildStatItem('CONTACTED', '${stats['contacted'] ?? 0}', AppTheme.royalIndigo),
                    _buildDivider(),
                    _buildStatItem('BLOCKED', '${stats['blacklisted'] ?? 0}', AppTheme.sunsetCoral),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 1: Lead Database Operations
              const Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.electricCyan),
                  SizedBox(width: 6),
                  Text(
                    'LEAD DATABASE OPERATIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.electricCyan,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Clear All Leads Button (Prominent & Safe)
              InkWell(
                onTap: _isProcessing ? null : _showConfirmClearDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.sunsetCoral.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.sunsetCoral.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.sunsetCoral.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_sweep_rounded, color: AppTheme.sunsetCoral, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clear All Leads',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.cleanAlabaster,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Wipe local leads database clean (Can be restored anytime)',
                              style: TextStyle(fontSize: 11, color: AppTheme.subduedSilver),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.subduedSilver),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Restore Default Verified Leads Button
              InkWell(
                onTap: _isProcessing ? null : _restoreDefaultLeads,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.mintEmerald.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.mintEmerald.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.mintEmerald.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restore_rounded, color: AppTheme.mintEmerald, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Restore Default Verified Inventory',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.cleanAlabaster,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Reload 78+ authentic commercial leads across MENA',
                              style: TextStyle(fontSize: 11, color: AppTheme.subduedSilver),
                            ),
                          ],
                        ),
                      ),
                      if (_isProcessing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.mintEmerald),
                        )
                      else
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.subduedSilver),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Secondary actions row: Reset Contacted & Clear Blacklist
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _showConfirmResetContactedDialog,
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('Reset Contacted', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.cleanAlabaster,
                        side: const BorderSide(color: AppTheme.borderNeonSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _clearBlacklist,
                      icon: const Icon(Icons.shield_outlined, size: 14),
                      label: const Text('Clear Blacklist', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.subduedSilver,
                        side: const BorderSide(color: AppTheme.borderNeonSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Section 2: AI Strategic Analyst Config
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.royalIndigo),
                  SizedBox(width: 6),
                  Text(
                    'AI STRATEGIC ANALYST & OUTBOUND ENGINE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.royalIndigo,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.obsidianNavy.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderNeonSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Google Gemini 1.5 Flash API Key (Optional):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.cleanAlabaster),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Leave empty to use built-in intelligent heuristic analysis, or insert your key for cloud GenAI.',
                      style: TextStyle(fontSize: 11, color: AppTheme.mutedSlate),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _keyCtrl,
                      obscureText: _obscureKey,
                      style: const TextStyle(fontSize: 12, color: AppTheme.cleanAlabaster),
                      cursorColor: AppTheme.electricCyan,
                      decoration: InputDecoration(
                        hintText: 'AIzaSy...',
                        hintStyle: const TextStyle(fontSize: 11, color: AppTheme.mutedSlate),
                        filled: true,
                        fillColor: AppTheme.obsidianNavy,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.borderNeonSubtle),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _obscureKey ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 16,
                                color: AppTheme.subduedSilver,
                              ),
                              onPressed: () => setState(() => _obscureKey = !_obscureKey),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.electricCyan),
                              onPressed: _saveApiKey,
                              tooltip: 'Save Key',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Section 3: Telemetry Export & App Info
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportLeadsSummary,
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Export Telemetry', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.electricCyan,
                        side: BorderSide(color: AppTheme.electricCyan.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // App Version & Signature info
              Center(
                child: Text(
                  'DM Client Hunter MENA v1.0.8 • Dual v1+v2 Keystore Signed\n100% Genuine Google Places Commercial Inventory',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.mutedSlate.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppTheme.subduedSilver,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppTheme.borderNeonSubtle,
    );
  }
}
