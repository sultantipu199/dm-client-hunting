#!/usr/bin/env python3
"""
Utility script to validate and synchronize assets/data/leads_feed.json.
Runs asynchronous DNS & HTTP validation and attaches verified fallbacks.
"""

import json
import os
import sys

# Ensure UTF-8 console output on Windows
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

from url_validator import batch_verify_leads

def sync_leads_feed(feed_path: str = "assets/data/leads_feed.json"):
    if not os.path.exists(feed_path):
        print(f"Error: {feed_path} not found.")
        return

    with open(feed_path, "r", encoding="utf-8") as f:
        leads = json.load(f)

    print(f"🔍 Validating {len(leads)} leads from {feed_path}...")
    hardened = batch_verify_leads(leads, max_workers=10)

    with open(feed_path, "w", encoding="utf-8") as f:
        json.dump(hardened, f, indent=2, ensure_ascii=False)

    live_count = sum(1 for l in hardened if l.get("has_live_website"))
    fallback_count = len(hardened) - live_count

    print(f"\n📊 Summary: {live_count} live corporate sites, {fallback_count} routed to verified Google Maps fallbacks.")
    for l in hardened:
        flag = "✅ LIVE" if l.get("has_live_website") else "📍 MAPS"
        print(f"  [{flag}] {l.get('company_name')}: URL={l.get('website_url')} -> Action={l.get('primary_action_url')}")

if __name__ == "__main__":
    sync_leads_feed()
