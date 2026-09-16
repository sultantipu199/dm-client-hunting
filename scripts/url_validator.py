#!/usr/bin/env python3
"""
Pre-Flight URL & DNS Validator and Fallback URL Generator
Validates company websites via DNS resolution (dnspython / socket) and lightweight HTTP probe (HEAD / GET fallback).
Generates verified fallbacks (Google Maps search link, WhatsApp API) for dead or non-existent domains.
"""

import re
import socket
import urllib.parse
from concurrent.futures import ThreadPoolExecutor
from typing import Dict, Any, Optional, Tuple

import requests

try:
    import dns.resolver
    HAS_DNSPYTHON = True
except ImportError:
    HAS_DNSPYTHON = False

DEFAULT_USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/128.0.0.0 Safari/537.36"
)
PROBE_TIMEOUT = 3.0


def extract_host(url: str) -> str:
    """Extracts the clean domain host from a URL."""
    if not url:
        return ""
    clean = url.strip()
    if not clean.startswith("http://") and not clean.startswith("https://"):
        clean = f"https://{clean}"
    try:
        parsed = urllib.parse.urlparse(clean)
        host = parsed.hostname or ""
        return host.lower()
    except Exception:
        return ""


def resolve_dns(host: str, timeout: float = 2.0) -> bool:
    """
    Step A: DNS Resolve.
    Uses dnspython if available with socket.getaddrinfo fallback.
    Returns True if domain resolves to at least one valid IP, False on NXDOMAIN or gaierror.
    """
    if not host or "." not in host:
        return False

    # Attempt dnspython resolution
    if HAS_DNSPYTHON:
        try:
            resolver = dns.resolver.Resolver()
            resolver.lifetime = timeout
            resolver.timeout = timeout
            answers = resolver.resolve(host, "A")
            if len(answers) > 0:
                return True
        except (dns.resolver.NXDOMAIN, dns.resolver.NoAnswer, dns.resolver.NoNameservers):
            return False
        except Exception:
            # Fall back to socket check on any unexpected resolver exception
            pass

    # Socket getaddrinfo fallback
    try:
        results = socket.getaddrinfo(host, 80, proto=socket.IPPROTO_TCP)
        return len(results) > 0
    except (socket.gaierror, socket.herror, TimeoutError, OSError):
        return False


def probe_http(url: str, timeout: float = PROBE_TIMEOUT) -> Tuple[bool, Optional[str]]:
    """
    Step B: HTTP Probe.
    Performs lightweight HEAD request (with GET fallback on 405) with 3.0s timeout and realistic User-Agent.
    Returns (True, verified_url) if response code is 2xx or 3xx; (False, None) on 404, 5xx, or network errors.
    """
    if not url:
        return False, None

    target_url = url.strip()
    if not target_url.startswith("http://") and not target_url.startswith("https://"):
        target_url = f"https://{target_url}"

    headers = {
        "User-Agent": DEFAULT_USER_AGENT,
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.5",
    }

    session = requests.Session()
    try:
        # Initial lightweight HEAD probe
        response = session.head(
            target_url,
            headers=headers,
            timeout=timeout,
            allow_redirects=True,
            verify=True,
        )

        # Some servers return 405 Method Not Allowed or 403 to HEAD requests, try GET fallback
        if response.status_code in (403, 405):
            response = session.get(
                target_url,
                headers=headers,
                timeout=timeout,
                allow_redirects=True,
                stream=True,  # Stream avoids downloading entire body
                verify=True,
            )

        if 200 <= response.status_code < 400:
            return True, response.url
        return False, None
    except requests.exceptions.RequestException:
        # SSL errors, timeouts, connection resets, 404, etc.
        return False, None
    finally:
        session.close()


def validate_url(url: Optional[str]) -> Tuple[bool, Optional[str]]:
    """
    Combines DNS resolution and HTTP probe into a single pre-flight verification.
    Returns (is_live, verified_url_or_none).
    """
    if not url or not url.strip():
        return False, None

    host = extract_host(url)
    if not host:
        return False, None

    # Step A: DNS Resolve
    if not resolve_dns(host):
        return False, None

    # Step B: HTTP Probe
    is_live, final_url = probe_http(url)
    if is_live:
        return True, final_url

    return False, None


def generate_fallback_maps_url(company_name: str, corridor: str = "", country: str = "") -> str:
    """
    Constructs an authoritative Google Maps Place search link for the lead.
    Format: https://www.google.com/maps/search/?api=1&query=URI_ENCODED(company_name + " " + location)
    """
    location_parts = [p for p in [company_name, corridor, country] if p and p.strip()]
    query_str = " ".join(location_parts)
    encoded_query = urllib.parse.quote(query_str)
    return f"https://www.google.com/maps/search/?api=1&query={encoded_query}"


def generate_whatsapp_url(phone: str, prefilled_text: str = "") -> str:
    """Constructs a direct WhatsApp click-to-chat link."""
    clean_digits = re.sub(r"[^\d]", "", phone or "")
    if prefilled_text:
        return f"https://wa.me/{clean_digits}?text={urllib.parse.quote(prefilled_text)}"
    return f"https://wa.me/{clean_digits}"


def verify_and_harden_lead(lead: Dict[str, Any]) -> Dict[str, Any]:
    """
    Processes a lead record:
    - Runs DNS + HTTP pre-flight validation.
    - If verified: sets has_live_website = True, website_url = verified_url, primary_action_url = verified_url.
    - If failed: sets has_live_website = False, website_url = None, primary_action_url = Google Maps search fallback.
    """
    original_url = lead.get("website_url")
    company_name = lead.get("company_name", "Enterprise Client")
    corridor = lead.get("corridor", "")
    country = lead.get("country", "")

    maps_fallback = generate_fallback_maps_url(company_name, corridor, country)

    is_live = False
    verified_url = None

    if original_url:
        is_live, verified_url = validate_url(original_url)

    updated_lead = dict(lead)
    if is_live and verified_url:
        updated_lead["has_live_website"] = True
        updated_lead["website_url"] = verified_url
        updated_lead["primary_action_url"] = verified_url
    else:
        updated_lead["has_live_website"] = False
        updated_lead["website_url"] = None
        updated_lead["primary_action_url"] = maps_fallback

    return updated_lead


def batch_verify_leads(leads: list, max_workers: int = 10) -> list:
    """Asynchronously verifies a list of leads using a ThreadPoolExecutor."""
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        results = list(executor.map(verify_and_harden_lead, leads))
    return results
