# ⚡ DM Client Hunter MENA - Executive Obsidian CRM & Outbound Acquisition Engine

> **Executive Glassmorphism Mobile & Web CRM for High-Ticket Digital Marketing Agency Client Acquisition across Riyadh and the Greater Middle East (GCC/MENA).**

---

## 🏛️ Executive Architecture & Tech Stack

- **Framework**: Flutter 3.24+ (Stable) running on Dart 3.5+
- **Design Paradigm**: **Obsidian Glassmorphism** (120 FPS high-contrast executive dark mode)
  - Ultra-deep Obsidian Navy (`#06090E`)
  - Translucent Frosted Glass (`#0E1420` with 0.87 opacity, 1px subtle neon borders `#1E293B`)
  - Primary Tech Accent: **Electric Cyan** (`#00F2FE`)
  - WhatsApp Active Accent: **Mint Emerald** (`#10B981`)
  - Email Dispatch Accent: **Deep Royal Indigo** (`#6366F1`)
  - Typography: Clean Alabaster (`#F8FAFC`) display headings, Subdued Silver (`#94A3B8`) body
- **State Architecture**: Flutter Riverpod 2.5+ (`NotifierProvider`, `filteredLeadsProvider`, `filterProvider`)
- **Local Storage**: Hive CE (Community Edition) with strongly-typed `LeadAdapter` and dedicated boxes:
  - `leads_box`: Primary client records, notes, and AI analysis data
  - `blacklist_contacts`: Wrong-number protection registry
  - `settings_box`: API configuration and persistent preferences
- **AI Intelligence**: **Google Gemini 1.5 Flash** REST API (Zero heavy SDK dependencies) with automatic client reply paste analysis and markdown backtick stripping
- **Outbound Dispatcher**: Dual 1-Tap WhatsApp & Native Mail (`mailto:`) with localized, gap-specific outreach copy in Arabic and English
- **Cross-Border Scope**: Riyadh growth corridors (KAFD, Al Narjis, King Salman Rd, Al Malqa, New Murabba) + Pan-MENA commercial hubs (Dubai DIFC, Abu Dhabi ADGM, Lusail Doha, Kuwait Sharq, Bahrain Seef, Cairo Smart Village) with **MENA Remote-Work Validation**.

---

## 🎯 Target Matrix & Marketing Gaps

### Primary Corridors
- **Riyadh (KSA)**:
  - *North Growth Hotspots*: Al Narjis Commercial Corridor, Al Yasmin, Al Khuzama, New Murabba
  - *Corporate Hubs*: KAFD Phase 1 & 2, King Salman Road Business Strip, Roshn Front, Al Malqa, Digital City
  - *Commercial Hubs*: Granada Business Park, Al Yarmouk, Al Sulay Logistics HQ
- **UAE**: DIFC Financial Centre, Business Bay, Dubai Silicon Oasis, ADGM Al Maryah Island
- **Qatar**: Lusail Marina Financial District, West Bay Towers
- **Kuwait**: Sharq Financial District, Al Hamra Corporate Strip
- **Bahrain & Oman**: Seef Business District, Bahrain Bay, Al Mouj Muscat
- **Egypt**: New Cairo 5th Settlement, Smart Village Tech Corridor, Sheikh Zayed

### Detected Marketing Gaps
- `🔥 Missing Meta/GTM Pixel` - Lack of conversion tracking, Facebook CAPI, and Google Tag Manager
- `⚡ Low Google Visibility / No Search Ads` - Zero commercial search capture on high-intent buyer terms
- `🛠️ Outdated Website / No Mobile Funnel` - Slow responsive performance and broken mobile consultation checkout
- `📱 Inactive Social Media Presence` - Dormant corporate channels missing high-net-worth client engagement
- `🎯 Zero Retargeting / High Ad CAC` - Paid traffic abandonment without conversion remarketing funnels
- `💬 No Automated WhatsApp Lead Funnel` - Manual delayed replies leading to dropped inbound leads

---

## 🚀 Dual 1-Tap Outbound Dispatcher

Every lead card is equipped with two ergonomic action buttons:
1. **[🟢 WhatsApp Pitch]**:
   - Launches WhatsApp via `wa.me` with localized, conversion-focused audit copy.
   - Highlights the client's detected marketing gap and offers a 10-minute remote growth sprint.
2. **[🟣 Email Proposal]**:
   - Pre-fills native email client via `mailto:` with executive subject line and value-first proposal body.

### State-Shift Haptic Trigger
Tapping either button instantly:
- Triggers `HapticFeedback.mediumImpact()`
- Updates lead status to `contacted` with `contacted_at` timestamp in Hive
- Triggers an animated slide-out from the active 'New Leads' view

---

## 🤖 AI Strategic Growth Analyst & Wrong-Contact Guard

### Auto-Triggered Reply Analysis
When an incoming prospect message is pasted into the card:
- Automatically debounces and sends to **Gemini 1.5 Flash** REST API (or local resilient heuristic engine)
- Strips markdown code blocks/backticks and parses structured JSON:
  ```json
  {
    "sentiment": "Interested | High-Intent | Budget Objection | Competitor Bound | Wrong Contact",
    "is_wrong_contact": false,
    "audit_summary": "1-sentence executive summary of position and bottlenecks",
    "strategic_reply": "Concise, value-first response proposing a free 10-minute growth roadmap",
    "deal_tier": "$$$ Enterprise | $$ Mid-Market | $ Starter Retainer",
    "next_step": "Recommended calendar invite or discovery call"
  }
  ```

### Wrong-Number Protection
If `is_wrong_contact == true`:
- Auto-appends sanitized number to Hive box `blacklist_contacts`.
- Generates polite Arabic apology: *"اعتذر منك بشدة على الإزعاج، سيتم حذف وتعديل الرقم فوراً من سجلاتنا. أتمنى لك يوماً سعيداً."*
- Displays 1-tap **Send Apology & Archive** button to remove the card immediately.

---

## 🔄 Daily Automated Scraper Pipeline

- `.github/workflows/daily_scraper.yml`:
  - Runs daily at `03:00 UTC` (`06:00 AM Riyadh/GCC Time`) + manual `workflow_dispatch`.
  - Python crawler (`scripts/scraper.py`) validates MENA mobile formats (`+9665...`, `+9715...`, `+974...`, `+965...`, `+201...`) and corporate domains.
  - Validates remote collaboration readiness and checks against blacklist before updating `assets/data/leads_feed.json`.

---

## 📦 Android Build Hardening & GitHub Actions CI

- `.github/workflows/build_apk.yml`:
  - Builds release APK on `ubuntu-latest` with Java 17 and Flutter 3.24.x.
  - Automatically runs `flutter analyze` and `flutter test`.
  - Packages and uploads `app-release.apk` artifact.
- `android/app/build.gradle`:
  - Android Gradle Plugin 8.x with explicit namespace `com.antigravity.dm_client_hunting`.
  - Debug signing for reproducible release builds.
- `AndroidManifest.xml`:
  - Includes `<queries>` for `com.whatsapp`, `com.whatsapp.w4b`, and `mailto:`.
