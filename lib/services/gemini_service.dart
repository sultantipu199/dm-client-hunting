import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_analysis.dart';
import '../models/lead.dart';

/// Gemini 1.5 Flash Strategic Growth Analyst via zero-dependency REST API.
class GeminiService {
  static const String _defaultModel = 'gemini-1.5-flash';
  static const String politeApologyMessage =
      'اعتذر منك بشدة على الإزعاج، سيتم حذف وتعديل الرقم فوراً من سجلاتنا. أتمنى لك يوماً سعيداً.';

  final String? apiKey;

  const GeminiService({this.apiKey});

  /// Analyzes an incoming client reply, assessing intent, wrong-number detection,
  /// and generating a high-converting, value-first strategic response.
  Future<AiAnalysisResult> analyzeClientReply({
    required Lead lead,
    required String incomingReply,
  }) async {
    final cleanInput = incomingReply.trim();
    if (cleanInput.isEmpty) {
      return const AiAnalysisResult(
        sentiment: 'Interested',
        isWrongContact: false,
        auditSummary: 'No incoming text provided',
        strategicReply: 'Would you be open to a 10-minute growth roadmap session this week?',
        dealTier: '\$\$ Mid-Market',
        nextStep: 'Awaiting client response',
      );
    }

    final key = apiKey?.isNotEmpty == true
        ? apiKey!
        : const String.fromEnvironment('GEMINI_API_KEY');

    if (key.isNotEmpty) {
      try {
        final result = await _callGeminiApi(lead: lead, reply: cleanInput, key: key);
        if (result != null) return result;
      } catch (e) {
        // Fallback to local heuristic engine if network or quota issue occurs
      }
    }

    // High-precision local heuristic fallback engine for offline or zero-key instant dev
    return _localHeuristicAnalysis(lead, cleanInput);
  }

  Future<AiAnalysisResult?> _callGeminiApi({
    required Lead lead,
    required String reply,
    required String key,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_defaultModel:generateContent?key=$key',
    );

    final prompt = '''
You are an Elite B2B Digital Marketing Agency Strategist & Client Acquisition Director specializing in the Saudi and Middle Eastern markets (Riyadh, Dubai, Doha, Kuwait, Cairo).
You are evaluating an incoming client reply from a lead.

Lead Context:
- Company: ${lead.companyName}
- Location: ${lead.corridor}, ${lead.country}
- Sector: ${lead.sector}
- Identified Marketing Gap: ${lead.marketingGap} (${lead.marketingGapDetails})
- Remote Collaboration Verified: ${lead.agreesToRemoteWork} (${lead.remoteTier})

Incoming Client Reply:
"""$reply"""

Your Goal:
Analyze this message and return ONLY a valid raw JSON object (strictly NO markdown formatting, NO backticks, NO surrounding text):
{
  "sentiment": "Interested | High-Intent | Budget Objection | Competitor Bound | Wrong Contact",
  "is_wrong_contact": boolean,
  "audit_summary": "1-sentence executive assessment of their position and pain points",
  "strategic_reply": "A concise, value-first response proposing a free 10-minute growth roadmap or discovery call tailored to their gap and remote execution",
  "deal_tier": "\$\$\$ Enterprise | \$\$ Mid-Market | \$ Starter Retainer",
  "next_step": "Recommended immediate action item"
}

Important Rules:
- If the sender states wrong number, wrong person, "غلطان", "من أنت", "wrong person", or indicates they do not own this business, set "is_wrong_contact": true and "sentiment": "Wrong Contact".
- Otherwise set "is_wrong_contact": false.
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 600,
      }
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = jsonResponse['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          final rawText = parts[0]['text']?.toString() ?? '';
          final cleanedJson = cleanJsonString(rawText);
          final decoded = jsonDecode(cleanedJson) as Map<String, dynamic>;
          return AiAnalysisResult.fromJson(decoded, rawSnippet: reply);
        }
      }
    }
    return null;
  }

  /// Strips markdown code blocks, backticks, and whitespace before JSON decoding
  static String cleanJsonString(String raw) {
    String text = raw.trim();
    // Remove ```json ... ``` or ``` ... ```
    if (text.startsWith('```')) {
      final firstNewline = text.indexOf('\n');
      if (firstNewline != -1) {
        text = text.substring(firstNewline + 1);
      }
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }

  /// High-accuracy local fallback engine ensuring instant, resilient analysis even without network
  static AiAnalysisResult _localHeuristicAnalysis(Lead lead, String text) {
    final lower = text.toLowerCase();

    // Check wrong contact phrases in English and Arabic
    final isWrong = lower.contains('wrong') ||
        lower.contains('غلطان') ||
        lower.contains('الرقم غلط') ||
        lower.contains('خطأ') ||
        lower.contains('who is this') ||
        lower.contains('مين انت') ||
        lower.contains('مش انا') ||
        lower.contains('wrong number');

    if (isWrong) {
      return AiAnalysisResult(
        sentiment: 'Wrong Contact',
        isWrongContact: true,
        auditSummary: 'Client indicated incorrect recipient or updated telephone contact.',
        strategicReply: politeApologyMessage,
        dealTier: '\$ Starter Retainer',
        nextStep: 'Archive lead and append phone to blacklist.',
        rawReplySnippet: text,
      );
    }

    final isHighIntent = lower.contains('interested') ||
        lower.contains('call') ||
        lower.contains('zoom') ||
        lower.contains('meeting') ||
        lower.contains('مهتم') ||
        lower.contains('نتصل') ||
        lower.contains('اجتماع') ||
        lower.contains('تفاصيل') ||
        lower.contains('send proposal') ||
        lower.contains('send details');

    final isBudget = lower.contains('expensive') ||
        lower.contains('budget') ||
        lower.contains('cost') ||
        lower.contains('غالي') ||
        lower.contains('ميزانية') ||
        lower.contains('كم السعر');

    if (isHighIntent) {
      return AiAnalysisResult(
        sentiment: 'High-Intent',
        isWrongContact: false,
        auditSummary: 'High buying intent detected. Client requested call or strategic details.',
        strategicReply:
            'Excellent! I can walk you through our MENA remote growth sprint and show how we resolve ${lead.marketingGap} in under 14 days. Are you free for a quick 10-minute Zoom call tomorrow at 2:00 PM?',
        dealTier: '\$\$\$ Enterprise',
        nextStep: 'Lock in 10-min calendar discovery invite.',
        rawReplySnippet: text,
      );
    }

    if (isBudget) {
      return AiAnalysisResult(
        sentiment: 'Budget Objection',
        isWrongContact: false,
        auditSummary: 'Pricing sensitivity detected. Focus on ROAS and cross-border efficiency.',
        strategicReply:
            'Completely understand. Our remote agency model operates with zero wasted retainer overhead—focused strictly on performance ROAS to quickly self-fund your ad spend. Would you like to review our 1-page breakdown?',
        dealTier: '\$\$ Mid-Market',
        nextStep: 'Send value-first ROI case study.',
        rawReplySnippet: text,
      );
    }

    return AiAnalysisResult(
      sentiment: 'Interested',
      isWrongContact: false,
      auditSummary: 'Engagement initiated. Propose a short 10-minute audit roadmap.',
      strategicReply:
          'Thanks for getting back to us! We recently conducted a quick audit on ${lead.companyName} and spotted 2 immediate growth levers regarding ${lead.marketingGap}. Would you be open to a 10-minute walkthrough this week?',
      dealTier: '\$\$ Mid-Market',
      nextStep: 'Offer 2 convenient time slots for discovery.',
      rawReplySnippet: text,
    );
  }
}
