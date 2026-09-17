import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lead.dart';
import '../providers/leads_provider.dart';
import '../services/lead_scraper_service.dart';
import '../theme/app_theme.dart';

/// Interactive Obsidian modal bottom sheet for manually creating and listing a new lead
class AddLeadSheet extends ConsumerStatefulWidget {
  const AddLeadSheet({super.key});

  @override
  ConsumerState<AddLeadSheet> createState() => _AddLeadSheetState();
}

class _AddLeadSheetState extends ConsumerState<AddLeadSheet> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+9665');
  final _emailCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactRoleCtrl = TextEditingController(text: 'Managing Director');
  final _gapDetailsCtrl = TextEditingController();
  final _customCorridorCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _selectedCountry = 'Saudi Arabia (KSA)';
  String _selectedCorridor = 'Al Narjis Commercial Corridor';
  String _selectedSector = 'Luxury Real Estate Agencies';
  String _selectedMarketingGap = '🔥 Missing Meta/GTM Pixel';
  String _selectedRemoteTier = 'MENA Cross-Border Retainer';
  bool _agreesToRemoteWork = true;
  bool _isSaving = false;

  final List<String> _countries = [
    'Saudi Arabia (KSA)',
    'United Arab Emirates (UAE)',
    'Qatar',
    'Kuwait',
    'Bahrain',
    'Oman',
    'Egypt',
    'Other Commercial Market',
  ];

  final List<String> _sectors = [
    'Luxury Real Estate Agencies',
    'Private Healthcare & Aesthetic Clinics',
    'Newly Formed Corporate Firms',
    'High-Growth E-Commerce Brands',
    'Management & Strategy Consulting',
    'B2B Tech & SaaS Solutions',
    'Trading & Logistics Corporation',
    'Other Commercial Sector',
  ];

  final List<String> _marketingGaps = [
    '🔥 Missing Meta/GTM Pixel',
    '⚡ Low Google Visibility / No Search Ads',
    '🛠️ Outdated Website / No Mobile Funnel',
    '📱 Inactive Social Media Presence',
    '🎯 Zero Retargeting / High Ad CAC',
    '💬 No Automated WhatsApp Lead Funnel',
    'Custom Marketing Bottleneck',
  ];

  final List<String> _remoteTiers = [
    'MENA Cross-Border Retainer',
    'GCC Remote Sprints',
    'Enterprise Performance Retainer',
    'Advisory Growth Retainer',
  ];

  @override
  void initState() {
    super.initState();
    _updatePhonePrefixAndCorridors(_selectedCountry);
  }

  void _updatePhonePrefixAndCorridors(String country) {
    final prefix = LeadScraperService.phonePrefixes[country];
    if (prefix != null && !_phoneCtrl.text.startsWith(prefix)) {
      _phoneCtrl.text = prefix;
    }

    final availableCorridors = LeadScraperService.corridors[country] ?? [];
    if (availableCorridors.isNotEmpty) {
      _selectedCorridor = availableCorridors.first;
    } else {
      _selectedCorridor = 'Custom District / Zone';
    }
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _websiteCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactRoleCtrl.dispose();
    _gapDetailsCtrl.dispose();
    _customCorridorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitLead() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    final companyName = _companyNameCtrl.text.trim();
    String rawWebsite = _websiteCtrl.text.trim();
    String? websiteUrl;
    bool hasLiveWebsite = false;

    if (rawWebsite.isNotEmpty) {
      if (!rawWebsite.startsWith('http://') && !rawWebsite.startsWith('https://')) {
        rawWebsite = 'https://$rawWebsite';
      }
      websiteUrl = rawWebsite;
      hasLiveWebsite = true;
    }

    final corridor = (_selectedCorridor == 'Custom District / Zone' && _customCorridorCtrl.text.trim().isNotEmpty)
        ? _customCorridorCtrl.text.trim()
        : _selectedCorridor;

    final query = Uri.encodeComponent('$companyName $corridor $_selectedCountry'.trim());
    final fallbackMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$query';

    final leadId = 'manual_lead_${DateTime.now().millisecondsSinceEpoch}';

    final newLead = Lead(
      id: leadId,
      companyName: companyName,
      websiteUrl: websiteUrl,
      hasLiveWebsite: hasLiveWebsite,
      primaryActionUrl: hasLiveWebsite ? websiteUrl : fallbackMapsUrl,
      country: _selectedCountry,
      corridor: corridor,
      sector: _selectedSector,
      marketingGap: _selectedMarketingGap,
      marketingGapDetails: _gapDetailsCtrl.text.trim().isNotEmpty
          ? _gapDetailsCtrl.text.trim()
          : 'High mobile bounce and missing automated conversion tags in target district.',
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : 'info@${companyName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}.com',
      contactName: _contactNameCtrl.text.trim().isNotEmpty ? _contactNameCtrl.text.trim() : 'Decision Maker',
      contactRole: _contactRoleCtrl.text.trim().isNotEmpty ? _contactRoleCtrl.text.trim() : 'Managing Director',
      agreesToRemoteWork: _agreesToRemoteWork,
      remoteTier: _selectedRemoteTier,
      status: 'new',
      createdAt: DateTime.now(),
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : 'Manually listed prospect ready for acquisition sprint.',
    );

    // Save lead to Hive and Riverpod state
    await ref.read(leadsProvider.notifier).addLead(newLead);

    // Switch active tab to 'new' so it appears right at the top
    ref.read(filterProvider.notifier).state =
        ref.read(filterProvider).copyWith(activeTab: 'new');

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.mintEmerald, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lead "$companyName" successfully added to Radar!',
                  style: const TextStyle(fontSize: 13, color: AppTheme.cleanAlabaster, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.cardSurfaceRaw,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppTheme.mintEmerald),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableCorridors = LeadScraperService.corridors[_selectedCountry] ?? [];
    final corridorOptions = [...availableCorridors, 'Custom District / Zone'];

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
      child: Form(
        key: _formKey,
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
                      Icons.add_business_rounded,
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
                          'Manual Lead Entry',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.cleanAlabaster,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Add & Profile a New Corporate Prospect',
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
              const SizedBox(height: 18),

              // Section 1: Company Identity
              _buildSectionHeader('1. Company Identity', Icons.domain_rounded),
              const SizedBox(height: 8),

              // Company Name Field
              _buildTextField(
                controller: _companyNameCtrl,
                label: 'Company Name *',
                hint: 'e.g. Al Malqa Luxury Estates',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Company name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Website URL Field
              _buildTextField(
                controller: _websiteCtrl,
                label: 'Corporate Website (Optional)',
                hint: 'e.g. almalqa.sa or leave blank for Maps search',
              ),
              const SizedBox(height: 14),

              // Section 2: Market Hub & Sector
              _buildSectionHeader('2. Market Hub & Sector', Icons.place_rounded),
              const SizedBox(height: 8),

              // Country Dropdown
              _buildDropdown(
                label: 'Commercial Market / Country',
                value: _selectedCountry,
                items: _countries,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCountry = val;
                      _updatePhonePrefixAndCorridors(val);
                    });
                  }
                },
              ),
              const SizedBox(height: 10),

              // Corridor Dropdown
              _buildDropdown(
                label: 'Business Corridor / Zone',
                value: corridorOptions.contains(_selectedCorridor) ? _selectedCorridor : corridorOptions.first,
                items: corridorOptions,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCorridor = val);
                  }
                },
              ),
              if (_selectedCorridor == 'Custom District / Zone') ...[
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _customCorridorCtrl,
                  label: 'Custom Corridor / District Name',
                  hint: 'e.g. King Fahd Road Tech Corridor',
                ),
              ],
              const SizedBox(height: 10),

              // Sector Dropdown
              _buildDropdown(
                label: 'Industry Sector',
                value: _selectedSector,
                items: _sectors,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSector = val);
                },
              ),
              const SizedBox(height: 14),

              // Section 3: Identified Marketing Gap
              _buildSectionHeader('3. Acquisition Bottleneck', Icons.track_changes_rounded),
              const SizedBox(height: 8),

              _buildDropdown(
                label: 'Primary Marketing Gap',
                value: _selectedMarketingGap,
                items: _marketingGaps,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMarketingGap = val);
                },
              ),
              const SizedBox(height: 10),

              _buildTextField(
                controller: _gapDetailsCtrl,
                label: 'Gap Details / Pain Points',
                hint: 'e.g. Broken mobile funnel; no retargeting on luxury searches',
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              // Section 4: Contact & Channels
              _buildSectionHeader('4. Decision Maker & Channels', Icons.contacts_rounded),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _contactNameCtrl,
                      label: 'Contact Name',
                      hint: 'e.g. Tariq Al-Mansoor',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _contactRoleCtrl,
                      label: 'Executive Role',
                      hint: 'e.g. Managing Partner',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Phone Number Field
              _buildTextField(
                controller: _phoneCtrl,
                label: 'Phone Number (International WhatsApp) *',
                hint: '+966501234567',
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                  if (clean.length < 9) {
                    return 'Enter valid international phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Email Field
              _buildTextField(
                controller: _emailCtrl,
                label: 'Corporate Email',
                hint: 'e.g. director@company.sa',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // Section 5: Remote Collaboration & Notes
              _buildSectionHeader('5. Collaboration Model', Icons.handshake_rounded),
              const SizedBox(height: 8),

              // Remote Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurfaceRaw,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderNeonSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remote Work Ready',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.cleanAlabaster),
                        ),
                        Text(
                          'Agrees to cross-border growth sprint model',
                          style: TextStyle(fontSize: 10, color: AppTheme.subduedSilver),
                        ),
                      ],
                    ),
                    Switch(
                      value: _agreesToRemoteWork,
                      activeColor: AppTheme.electricCyan,
                      onChanged: (val) => setState(() => _agreesToRemoteWork = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              _buildDropdown(
                label: 'Target Retainer Tier',
                value: _selectedRemoteTier,
                items: _remoteTiers,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRemoteTier = val);
                },
              ),
              const SizedBox(height: 10),

              _buildTextField(
                controller: _notesCtrl,
                label: 'Internal Notes / Acquisition Strategy',
                hint: 'Additional notes or tailored hook angle...',
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submitLead,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.obsidianNavy),
                          ),
                        )
                      : const Icon(Icons.add_task_rounded, size: 18),
                  label: Text(
                    _isSaving ? 'SAVING TO RADAR...' : 'SAVE & LIST TO RADAR',
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
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.electricCyan),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.cleanAlabaster,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.subduedSilver),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 12, color: AppTheme.cleanAlabaster),
          cursorColor: AppTheme.electricCyan,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 11, color: AppTheme.mutedSlate),
            filled: true,
            fillColor: AppTheme.cardSurfaceRaw,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderNeonSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderNeonSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.electricCyan),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.sunsetCoral),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.subduedSilver),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardSurfaceRaw,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderNeonSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              dropdownColor: AppTheme.cardSurfaceRaw,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.electricCyan, size: 18),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 12, color: AppTheme.cleanAlabaster),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
