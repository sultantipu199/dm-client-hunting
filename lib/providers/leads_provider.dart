import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_analysis.dart';
import '../models/lead.dart';
import '../services/storage_service.dart';

/// Filter state for leads exploration
class LeadsFilterState {
  final String? selectedCountry;
  final String? selectedCorridor;
  final String? selectedSector;
  final String? selectedMarketingGap;
  final bool onlyRemoteVerified;
  final String searchQuery;
  final String activeTab; // 'new' | 'contacted' | 'all' | 'blacklisted'

  const LeadsFilterState({
    this.selectedCountry,
    this.selectedCorridor,
    this.selectedSector,
    this.selectedMarketingGap,
    this.onlyRemoteVerified = false,
    this.searchQuery = '',
    this.activeTab = 'new',
  });

  LeadsFilterState copyWith({
    String? selectedCountry,
    String? selectedCorridor,
    String? selectedSector,
    String? selectedMarketingGap,
    bool? onlyRemoteVerified,
    String? searchQuery,
    String? activeTab,
    bool clearCountry = false,
    bool clearCorridor = false,
    bool clearSector = false,
    bool clearGap = false,
  }) {
    return LeadsFilterState(
      selectedCountry: clearCountry ? null : (selectedCountry ?? this.selectedCountry),
      selectedCorridor: clearCorridor ? null : (selectedCorridor ?? this.selectedCorridor),
      selectedSector: clearSector ? null : (selectedSector ?? this.selectedSector),
      selectedMarketingGap: clearGap ? null : (selectedMarketingGap ?? this.selectedMarketingGap),
      onlyRemoteVerified: onlyRemoteVerified ?? this.onlyRemoteVerified,
      searchQuery: searchQuery ?? this.searchQuery,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

/// Filter Provider
final filterProvider = StateProvider<LeadsFilterState>((ref) {
  return const LeadsFilterState();
});

/// Riverpod 2.5+ Notifier for Leads
class LeadsNotifier extends Notifier<List<Lead>> {
  @override
  List<Lead> build() {
    return _loadAllFromHive();
  }

  List<Lead> _loadAllFromHive() {
    try {
      final box = StorageService.leadsBox;
      final leads = box.values.toList();
      // Sort newest first
      leads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return leads;
    } catch (_) {
      return [];
    }
  }

  /// Refreshes state directly from Hive
  void refresh() {
    state = _loadAllFromHive();
  }

  /// Marks a lead as contacted and persists to Hive immediately.
  /// Instantly triggers card slide-out in the 'new' active tab.
  Future<void> markContacted(String leadId) async {
    await StorageService.markLeadContacted(leadId);
    state = state.map((lead) {
      if (lead.id == leadId) {
        return lead.copyWith(
          status: 'contacted',
          contactedAt: DateTime.now(),
        );
      }
      return lead;
    }).toList();
  }

  /// Appends phone number to blacklist Hive box and flags lead
  Future<void> blacklistLead(String leadId, String phone) async {
    await StorageService.blacklistContact(leadId: leadId, phone: phone);
    state = state.map((lead) {
      if (lead.id == leadId) {
        return lead.copyWith(
          status: 'blacklisted',
          notes: 'Blacklisted: Wrong Contact',
        );
      }
      return lead;
    }).toList();
  }

  /// Stores AI Analysis result
  Future<void> saveAiResult(String leadId, AiAnalysisResult result) async {
    await StorageService.saveAiAnalysis(leadId, result.toJsonString());
    state = state.map((lead) {
      if (lead.id == leadId) {
        return lead.copyWith(aiAnalysisJson: result.toJsonString());
      }
      return lead;
    }).toList();
  }

  /// Adds new lead (e.g. from sync/scraper)
  Future<void> addLead(Lead lead) async {
    if (StorageService.isPhoneBlacklisted(lead.phone)) return;
    await StorageService.leadsBox.put(lead.id, lead);
    state = [lead, ...state];
  }
}

final leadsProvider = NotifierProvider<LeadsNotifier, List<Lead>>(() {
  return LeadsNotifier();
});

/// Filtered leads provider reacting to tabs, search, and corridors
final filteredLeadsProvider = Provider<List<Lead>>((ref) {
  final allLeads = ref.watch(leadsProvider);
  final filter = ref.watch(filterProvider);

  return allLeads.where((lead) {
    // Tab Filter
    if (filter.activeTab == 'new') {
      if (lead.status != 'new') return false;
    } else if (filter.activeTab == 'contacted') {
      if (lead.status != 'contacted') return false;
    } else if (filter.activeTab == 'blacklisted') {
      if (lead.status != 'blacklisted') return false;
    }

    // Remote verification filter
    if (filter.onlyRemoteVerified && !lead.agreesToRemoteWork) {
      return false;
    }

    // Country filter
    if (filter.selectedCountry != null && filter.selectedCountry!.isNotEmpty) {
      if (lead.country != filter.selectedCountry) return false;
    }

    // Corridor filter
    if (filter.selectedCorridor != null && filter.selectedCorridor!.isNotEmpty) {
      if (lead.corridor != filter.selectedCorridor) return false;
    }

    // Sector filter
    if (filter.selectedSector != null && filter.selectedSector!.isNotEmpty) {
      if (lead.sector != filter.selectedSector) return false;
    }

    // Marketing Gap filter
    if (filter.selectedMarketingGap != null && filter.selectedMarketingGap!.isNotEmpty) {
      if (lead.marketingGap != filter.selectedMarketingGap) return false;
    }

    // Search query
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      final matchName = lead.companyName.toLowerCase().contains(q);
      final matchSector = lead.sector.toLowerCase().contains(q);
      final matchCorridor = lead.corridor.toLowerCase().contains(q);
      final matchGap = lead.marketingGap.toLowerCase().contains(q);
      final matchPhone = lead.phone.contains(q);
      if (!matchName && !matchSector && !matchCorridor && !matchGap && !matchPhone) {
        return false;
      }
    }

    return true;
  }).toList();
});

/// Aggregate stats provider
final leadsStatsProvider = Provider<Map<String, int>>((ref) {
  final allLeads = ref.watch(leadsProvider);
  int newCount = 0;
  int contactedCount = 0;
  int blacklistedCount = 0;
  int remoteVerifiedCount = 0;

  for (final l in allLeads) {
    if (l.status == 'new') newCount++;
    if (l.status == 'contacted') contactedCount++;
    if (l.status == 'blacklisted') blacklistedCount++;
    if (l.agreesToRemoteWork) remoteVerifiedCount++;
  }

  return {
    'total': allLeads.length,
    'new': newCount,
    'contacted': contactedCount,
    'blacklisted': blacklistedCount,
    'remoteVerified': remoteVerifiedCount,
  };
});
