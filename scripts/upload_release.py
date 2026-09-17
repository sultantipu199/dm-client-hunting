#!/usr/bin/env python3
"""
Uploads compiled release APK to GitHub Releases for tag v1.0.1.
Uses cached git credentials with 'repo' scope.
"""

import os
import sys
import subprocess
import requests

def get_git_token():
    proc = subprocess.Popen(
        ["git", "credential", "fill"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    out, _ = proc.communicate("protocol=https\nhost=github.com\n\n")
    for line in out.splitlines():
        if line.startswith("password="):
            return line.split("=", 1)[1].strip()
    return None

def upload_to_tag(tag, apk_path, token, repo, title, body_text):
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json",
    }
    rel_url = f"https://api.github.com/repos/{repo}/releases/tags/{tag}"
    resp = requests.get(rel_url, headers=headers)
    
    if resp.status_code == 200:
        print(f"Existing release found for {tag}.")
        release_data = resp.json()
    else:
        create_url = f"https://api.github.com/repos/{repo}/releases"
        payload = {
            "tag_name": tag,
            "target_commitish": "main",
            "name": title,
            "body": body_text,
            "draft": False,
            "prerelease": False,
        }
        create_resp = requests.post(create_url, headers=headers, json=payload)
        if create_resp.status_code not in (200, 201):
            print(f"Failed to create release {tag}: {create_resp.status_code} {create_resp.text}")
            return None
        release_data = create_resp.json()
        print(f"Created release {tag}: {release_data.get('html_url')}")

    upload_url = release_data.get("upload_url", "").split("{")[0]
    asset_name = "app-release.apk"
    for asset in release_data.get("assets", []):
        if asset.get("name") in (asset_name, f"DM_Client_Hunter_{tag}.apk", "DM_Client_Hunter_Release_v1.0.1.apk", "DM_Client_Hunter_Release_v1.0.2.apk", "DM_Client_Hunter_Release_v1.0.3.apk", "DM_Client_Hunter_Release_v1.0.4.apk"):
            del_url = asset.get("url")
            print(f"Deleting existing asset {asset.get('name')} from {tag}...")
            requests.delete(del_url, headers=headers)

    print(f"Uploading {apk_path} ({os.path.getsize(apk_path)} bytes) to GitHub Release {tag}...")
    upload_headers = {
        "Authorization": f"token {token}",
        "Content-Type": "application/vnd.android.package-archive",
    }
    with open(apk_path, "rb") as f:
        up_resp = requests.post(
            f"{upload_url}?name={asset_name}&label=DM_Client_Hunter_Release_{tag}.apk",
            headers=upload_headers,
            data=f,
        )

    if up_resp.status_code in (200, 201):
        asset_info = up_resp.json()
        download_url = asset_info.get("browser_download_url")
        print(f"\nSUCCESS for {tag}!")
        print(f"GitHub Release Page: {release_data.get('html_url')}")
        print(f"Direct APK Download URL: {download_url}")
        return download_url
    else:
        print(f"Upload to {tag} failed: {up_resp.status_code} {up_resp.text}")
        return None

def main():
    token = get_git_token()
    if not token:
        print("Error: Could not retrieve GitHub token from git credential manager.")
        sys.exit(1)

    repo = "sultantipu199/dm-client-hunting"
    cache_apk = r"C:\Android\build_cache\dm_build\app\outputs\flutter-apk\app-release.apk"
    local_apk = os.path.abspath("build/app/outputs/flutter-apk/app-release.apk")

    if os.path.exists(cache_apk):
        apk_path = cache_apk
        try:
            os.makedirs(os.path.dirname(local_apk), exist_ok=True)
            import shutil
            shutil.copy2(cache_apk, local_apk)
        except Exception:
            pass
    elif os.path.exists(local_apk):
        apk_path = local_apk
    else:
        print(f"Error: APK not found at {cache_apk} or {local_apk}")
        sys.exit(1)

    body = (
        "### DM Client Hunter MENA v1.0.4\n\n"
        "- **Manual Lead Entry & Listing Engine**: Added prominent `[ + ADD LEAD ]` Floating Action Button and AppBar action to manually create, profile, and list custom corporate prospects.\n"
        "- **Comprehensive Enterprise Profiling**: Full support for company name, website with live detection, country/corridor selection, industry sector, marketing bottleneck, phone format validation, email, contact role, remote readiness toggle, and acquisition notes.\n"
        "- **Instant Radar Injection**: Manually created leads persist immediately to local encrypted Hive storage and display at the top of the 'New Leads' feed with haptic feedback.\n"
        "- **In-App Manual Scraper Engine**: Dedicated on-demand scraper button (`[ ⚡ SCRAPER ]`) to mine MENA corporate corridors anytime.\n"
        "- **RFC 6068 Dual-Channel Compliance**: Zero `+` signs across native email and WhatsApp dispatches.\n\n"
        "**Direct Download**: Download `app-release.apk` below."
    )

    tags = ["v1.0.4", "v1.0.3", "v1.0.2"]
    for tag in tags:
        upload_to_tag(
            tag=tag,
            apk_path=apk_path,
            token=token,
            repo=repo,
            title=f"DM Client Hunter MENA {tag} (Production Release)",
            body_text=body,
        )

if __name__ == "__main__":
    main()
