#!/usr/bin/env python3
"""Check release metadata and the actual app bundle before publishing packages."""

import argparse
import json
import plistlib
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
REPOSITORY = "quiteQa/Shirox"


def verify_source():
    release = json.loads((ROOT / "Configurations/Release.json").read_text())
    assert re.fullmatch(r"\d+\.\d+\.\d+", release["version"]), "Invalid app version"
    assert re.fullmatch(r"[1-9]\d*", release["build"]), "Invalid build number"
    assert re.fullmatch(r"v[0-9A-Za-z._-]+", release["tag"]), "Invalid release tag"
    project = (ROOT / "Shirox.xcodeproj/project.pbxproj").read_text()
    for setting, expected in [("MARKETING_VERSION", release["version"]),
                              ("CURRENT_PROJECT_VERSION", release["build"])]:
        values = re.findall(r"\b" + setting + r" = ([^;]+);", project)
        assert values and set(values) == {expected}, f"Inconsistent {setting}: {values}"
    config = (ROOT / "Configurations/Shirox.xcconfig").read_text()
    assert f"GITHUB_REPO = {REPOSITORY}" in config, "Wrong update repository"
    source = json.loads((ROOT / "apps.json").read_text())
    assert source["sourceURL"] == f"https://raw.githubusercontent.com/{REPOSITORY}/main/apps.json"
    version = source["apps"][0]["versions"][0]
    assert version["version"] == release["version"]
    assert version["buildVersion"] == release["build"]
    assert version["downloadURL"] == (
        f"https://github.com/{REPOSITORY}/releases/download/{release['tag']}/Shirox.ipa"
    ), "Wrong side-loading download URL"
    return release


def verify_app(app, release):
    mac = (app / "Contents/Info.plist").is_file()
    info_path = app / ("Contents/Info.plist" if mac else "Info.plist")
    resources = app / "Contents/Resources" if mac else app
    info = plistlib.loads(info_path.read_bytes())
    assert info["CFBundleShortVersionString"] == release["version"], "Wrong packaged version"
    assert info["CFBundleVersion"] == release["build"], "Wrong packaged build number"
    assert info["GithubRepo"] == REPOSITORY, "Wrong packaged update repository"
    executable = app / "Contents/MacOS" / info["CFBundleExecutable"] if mac else app / info["CFBundleExecutable"]
    assert executable.is_file() and executable.stat().st_size > 0, "Missing app executable"
    for filename in ["Bangumi.json", "Bangumi.js"]:
        expected = ROOT / "Shirox/Resources" / filename
        actual = resources / filename
        assert actual.read_bytes() == expected.read_bytes(), f"Wrong bundled {filename}"
    manifest = json.loads((resources / "Bangumi.json").read_text())
    assert manifest["type"] == "metadata", "Bangumi must be a metadata source"
    print(f"Verified {app}: {release['version']} ({release['build']}), both Bangumi resources match")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", nargs="?", type=Path)
    args = parser.parse_args()
    release = verify_source()
    if args.app:
        verify_app(args.app, release)
    else:
        print(f"Release source metadata verified: {release['tag']}")


if __name__ == "__main__":
    main()
