import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_analysis.dart';
import '../models/lead.dart';
import '../providers/leads_provider.dart';
import '../services/dispatch_service.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

/// Modern Obsidian Lead Card with Dual 1-Tap Outbound Dispatcher
/// and Gemini 1.5 Flash Strategic Analyst & Wrong-Contact Guard.
class ModernLeadCard extends ConsumerStatefulWidget {
  final Lead lead;
  final VoidCallback? onDismissed;

  const ModernLeadCard({
    super.key,
    required this.lead,
    this.onDismissed,
  });

  @override
  ConsumerState<ModernLeadCard> createState() => _ModernLeadCardState();
}

class _ModernLeadCardState extends ConsumerState<ModernLeadCard> {
  final TextEditingController _replyController = TextEditingController();
  Timer? _debounceTimer;
  bool _isAnalyzing = false;
  bool _isSlidingOut = false;
  AiAnalysisResult? _aiResult;

  @override
  void initState() {
    super.initState();
    if (widget.lead.aiAnalysisJson != null) {
      _aiResult = AiAnalysisResult.fromJsonString(widget.lead.aiAnalysisJson!);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _replyController.dispose();
    super.dispose();
  }

  /// Automatically triggers Gemini 1.5 Flash analysis when client reply is pasted
  void _onReplyTextChanged(String text) {
    _debounceTimer?.cancel();
    if (text.trim().isEmpty) {
      setState(() {
        _aiResult = null;
      });
      return;
    }

    // Debounce to allow quick paste / continuous text without manual submit button
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _performAiAnalysis(text.trim());
    });
  }

  Future<void> _performAiAnalysis(String rawReply) async {
    setState(() {
      _isAnalyzing = true;
    });

    const gemini = GeminiService();
    final result = await gemini.analyzeClientReply(
      lead: widget.lead,
      incomingReply: rawReply,
    );

    if (!mounted) return;

    setState(() {
      _aiResult = result;
      _isAnalyzing = false;
    });

    // Save result to Hive through notifier
    await ref.read(leadsProvider.notifier).saveAiResult(widget.lead.id, result);

    // Wrong-Contact Protection: Auto-append to blacklist Hive box if wrong contact detected
    if (result.isWrongContact) {
      await ref.read(leadsProvider.notifier).blacklistLead(
            widget.lead.id,
            widget.lead.phone,
          );
      HapticFeedback.heavyImpact();
    }
  }

  /// Trigger 1-Tap WhatsApp Outreach with medium impact haptic and instant synchronous state-demotion
  Future<void> _triggerWhatsAppOutreach() async {
    HapticFeedback.mediumImpact();

    // 1. Synchronously trigger state-demotion in Riverpod & Hive, starting slide-out animation
    _handleStateShift();

    // 2. Launch WhatsApp with RFC-compliant encoding (strictly zero '+' signs)
    await DispatchService.launchWhatsAppOutreach(lead: widget.lead, preferArabic: true);
  }

  /// Trigger 1-Tap Direct Email Pitch with medium impact haptic and instant synchronous state-demotion
  Future<void> _triggerEmailPitch() async {
    HapticFeedback.mediumImpact();

    // 1. Synchronously trigger state-demotion in Riverpod & Hive, starting slide-out animation
    _handleStateShift();

    // 2. Launch native email with RFC-compliant encoding (strictly zero '+' signs)
    await DispatchService.launchEmailPitch(lead: widget.lead);
  }

  void _handleStateShift() {
    // Mark contacted in Riverpod + Hive immediately
    ref.read(leadsProvider.notifier).markContacted(widget.lead.id);

    // Only slide out if currently in 'new' state (demoting New -> Contacted)
    if (widget.lead.status == 'new') {
      setState(() {
        _isSlidingOut = true;
      });

      // Provide smooth slide-out animation delay
      Future.delayed(const Duration(milliseconds: 320), () {
        if (mounted) {
          widget.onDismissed?.call();
        }
      });
    }
  }

  /// Handles 1-tap Send Apology & Archive for Wrong Contacts
  Future<void> _sendApologyAndArchive() async {
    HapticFeedback.mediumImpact();
    await DispatchService.launchApologyWhatsApp(
      phone: widget.lead.phone,
      apologyText: GeminiService.politeApologyMessage,
    );

    setState(() {
      _isSlidingOut = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onDismissed?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isSlidingOut) {
      return Container()
          .animate()
          .slideX(begin: 0, end: 1.0, duration: 300.ms, curve: Curves.easeIn);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        borderRadius: 18,
        borderColor: _aiResult?.isWrongContact == true
            ? AppTheme.sunsetCoral.withOpacity(0.6)
            : AppTheme.borderNeonSubtle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Company Name & URL Preview Icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.lead.companyName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.cleanAlabaster,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Hardened Corporate Link / Google Maps Directory Action
                          Tooltip(
                            message: widget.lead.hasLiveWebsite
                                ? 'Visit Corporate Website'
                                : 'Search Location on Google Maps',
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                DispatchService.launchCompanyAction(
                                  context: context,
                                  lead: widget.lead,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: widget.lead.hasLiveWebsite
                                      ? AppTheme.electricCyan.withOpacity(0.12)
                                      : AppTheme.amberGold.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: widget.lead.hasLiveWebsite
                                        ? AppTheme.electricCyan.withOpacity(0.25)
                                        : AppTheme.amberGold.withOpacity(0.25),
                                    width: 0.8,
                                  ),
                                ),
                                child: Icon(
                                  widget.lead.hasLiveWebsite
                                      ? Icons.open_in_new_rounded
                                      : Icons.location_on_outlined,
                                  size: 14,
                                  color: widget.lead.hasLiveWebsite
                                      ? AppTheme.electricCyan
                                      : AppTheme.amberGold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.lead.contactRole.isNotEmpty ? widget.lead.contactRole : "Corporate Decision Maker"} • ${widget.lead.sector}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.subduedSilver,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status pill
                _buildStatusPill(widget.lead.status),
              ],
            ),

            const SizedBox(height: 12),

            // Badges Row: Location Pill + Marketing Gap Badge + Remote Agreement
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Location Pill
                _buildMicroCapsule(
                  text: widget.lead.corridor,
                  icon: Icons.location_on_rounded,
                  color: AppTheme.royalIndigo,
                ),
                // Marketing Gap Badge
                _buildMicroCapsule(
                  text: widget.lead.marketingGap,
                  color: AppTheme.amberGold,
                  isBold: true,
                ),
                // Remote Work Agreement Badge
                if (widget.lead.agreesToRemoteWork)
                  _buildMicroCapsule(
                    text: '🌐 MENA Remote-Verified',
                    color: AppTheme.electricCyan,
                  ),
              ],
            ),

            if (widget.lead.marketingGapDetails.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.obsidianNavy.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.borderNeonSubtle.withOpacity(0.6),
                  ),
                ),
                child: Text(
                  'Audit: ${widget.lead.marketingGapDetails}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.subduedSilver,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Dual 1-Tap Outbound Dispatch Buttons
            Row(
              children: [
                // 1. WhatsApp Outreach Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _triggerWhatsAppOutreach,
                    icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                    label: const Text(
                      'WhatsApp Pitch',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mintEmerald,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 2. Direct Email Pitch Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _triggerEmailPitch,
                    icon: const Icon(Icons.alternate_email_rounded, size: 16),
                    label: const Text(
                      'Email Proposal',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.royalIndigo,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(color: AppTheme.borderNeonSubtle, height: 1),
            const SizedBox(height: 12),

            // AI Strategic Growth Analyst & Client Reply Auto-Input
            _buildAiSection(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildAiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: AppTheme.electricCyan),
                SizedBox(width: 6),
                Text(
                  'AI STRATEGIC GROWTH ANALYST',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.electricCyan,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            if (_isAnalyzing)
              const SizedBox(
                height: 12,
                width: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.electricCyan),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Auto-Trigger Reply Paste Field (No manual submit button)
        Container(
          decoration: BoxDecoration(
            color: AppTheme.obsidianNavy.withOpacity(0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderNeonSubtle),
          ),
          child: TextField(
            controller: _replyController,
            maxLines: 2,
            minLines: 1,
            style: const TextStyle(fontSize: 12, color: AppTheme.cleanAlabaster),
            cursorColor: AppTheme.electricCyan,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              hintText: 'Paste client reply here (Auto-analyzed instantly)...',
              hintStyle: const TextStyle(fontSize: 12, color: AppTheme.mutedSlate),
              border: InputBorder.none,
              suffixIcon: _replyController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: AppTheme.mutedSlate),
                      onPressed: () {
                        _replyController.clear();
                        _onReplyTextChanged('');
                      },
                    )
                  : null,
            ),
            onChanged: _onReplyTextChanged,
          ),
        ),

        // AI Results & Wrong Contact Guard
        if (_aiResult != null) ...[
          const SizedBox(height: 10),
          _buildAiResultCard(_aiResult!),
        ],
      ],
    );
  }

  Widget _buildAiResultCard(AiAnalysisResult res) {
    if (res.isWrongContact) {
      // Wrong-Number Guard UI
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.sunsetCoral.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.sunsetCoral.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.sunsetCoral),
                SizedBox(width: 8),
                Text(
                  'WRONG CONTACT DETECTED • BLACKLIST GUARD ACTIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.sunsetCoral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Polite Exit Message: "${GeminiService.politeApologyMessage}"',
              style: TextStyle(fontSize: 12, color: AppTheme.cleanAlabaster),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendApologyAndArchive,
                icon: const Icon(Icons.archive_rounded, size: 16),
                label: const Text(
                  'Send Apology & Archive Lead',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sunsetCoral,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // High-Converting Strategic Response Card
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardSurfaceRaw,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.electricCyan.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPill(
                res.sentiment,
                res.sentiment == 'High-Intent'
                    ? AppTheme.mintEmerald
                    : (res.sentiment == 'Budget Objection'
                        ? AppTheme.amberGold
                        : AppTheme.royalIndigo),
              ),
              _buildPill(res.dealTier, AppTheme.electricCyan),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            res.auditSummary,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.subduedSilver,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.obsidianNavy,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              res.strategicReply,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.cleanAlabaster,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: res.strategicReply));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Strategic reply copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copy Reply', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.cleanAlabaster,
                    side: const BorderSide(color: AppTheme.borderNeonSubtle),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final cleanPhone = DispatchService.sanitizePhoneNumber(widget.lead.phone);
                    final encoded = Uri.encodeComponent(res.strategicReply);
                    await DispatchService.launchWebsitePreview(
                      'https://wa.me/$cleanPhone?text=$encoded',
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 14),
                  label: const Text('Send via WA', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                    foregroundColor: AppTheme.obsidianNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color color = AppTheme.electricCyan;
    String label = 'NEW';
    if (status == 'contacted') {
      color = AppTheme.mintEmerald;
      label = 'CONTACTED';
    } else if (status == 'blacklisted') {
      color = AppTheme.sunsetCoral;
      label = 'BLACKLISTED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMicroCapsule({
    required String text,
    IconData? icon,
    required Color color,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppTheme.cleanAlabaster,
            ),
          ),
        ],
      ),
    );
  }
}
