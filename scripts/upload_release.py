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

def create_and_upload_release():
    token = get_git_token()
    if not token:
        print("Error: Could not retrieve GitHub token from git credential manager.")
        sys.exit(1)

    repo = "sultantipu199/dm-client-hunting"
    tag = "v1.0.1"
    apk_path = os.path.abspath("build/app/outputs/flutter-apk/app-release.apk")

    if not os.path.exists(apk_path):
        print(f"Error: APK not found at {apk_path}")
        sys.exit(1)

    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json",
    }

    # 1. Check if release already exists
    rel_url = f"https://api.github.com/repos/{repo}/releases/tags/{tag}"
    resp = requests.get(rel_url, headers=headers)
    
    release_data = None
    if resp.status_code == 200:
        print(f"Existing release found for {tag}.")
        release_data = resp.json()
    else:
        # Create release
        create_url = f"https://api.github.com/repos/{repo}/releases"
        payload = {
            "tag_name": tag,
            "target_commitish": "main",
            "name": "DM Client Hunter MENA v1.0.1 (Production Release)",
            "body": (
                "### DM Client Hunter MENA v1.0.1\n\n"
                "- **URL & DNS Pre-Flight Validator**: Eliminates broken corporate domains (NXDOMAIN / gaierror) and 404/5xx pages.\n"
                "- **Verified Google Maps Fallback Generator**: Guaranteed navigation fallback for unverified sites.\n"
                "- **Flutter Lead Card UI Hardening**: Dynamic live site vs. Maps pin action and graceful SnackBar handling.\n\n"
                "**Direct Download**: Download `app-release.apk` below."
            ),
            "draft": False,
            "prerelease": False,
        }
        create_resp = requests.post(create_url, headers=headers, json=payload)
        if create_resp.status_code not in (200, 201):
            print(f"Failed to create release: {create_resp.status_code} {create_resp.text}")
            sys.exit(1)
        release_data = create_resp.json()
        print(f"Created release: {release_data.get('html_url')}")

    upload_url_template = release_data.get("upload_url", "")
    # upload_url format: https://uploads.github.com/repos/.../assets{?name,label}
    upload_url = upload_url_template.split("{")[0]

    # Delete existing asset with same name if present
    asset_name = "app-release.apk"
    for asset in release_data.get("assets", []):
        if asset.get("name") in (asset_name, "DM_Client_Hunter_v1.0.1.apk"):
            del_url = asset.get("url")
            print(f"Deleting existing asset {asset.get('name')}...")
            requests.delete(del_url, headers=headers)

    # Upload APK asset
    print(f"Uploading {apk_path} ({os.path.getsize(apk_path)} bytes) to GitHub Release...")
    upload_headers = {
        "Authorization": f"token {token}",
        "Content-Type": "application/vnd.android.package-archive",
    }
    
    with open(apk_path, "rb") as f:
        up_resp = requests.post(
            f"{upload_url}?name={asset_name}&label=DM_Client_Hunter_Release_v1.0.1.apk",
            headers=upload_headers,
            data=f,
        )

    if up_resp.status_code in (200, 201):
        asset_info = up_resp.json()
        download_url = asset_info.get("browser_download_url")
        print("\nSUCCESS! Upload completed.")
        print(f"GitHub Release Page: {release_data.get('html_url')}")
        print(f"Direct APK Download URL: {download_url}")
    else:
        print(f"Upload failed: {up_resp.status_code} {up_resp.text}")
        sys.exit(1)

if __name__ == "__main__":
    create_and_upload_release()
