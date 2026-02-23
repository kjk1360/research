#!/usr/bin/env python3
"""Auto-generate mkdocs.yml nav from docs directory structure."""
import os, re, yaml

DOCS_DIR = os.path.expanduser("~/research/docs")
MKDOCS_FILE = os.path.expanduser("~/research/mkdocs.yml")

SECTION_NAMES = {
    "gaming": "Gaming",
    "marketing": "Marketing",
    "creative": "Creative",
    "finance": "Finance",
    "_reports": "Reports",
}

def scan_section(section_dir, prefix):
    """Scan a section directory and return nav entries."""
    entries = []
    if os.path.exists(os.path.join(section_dir, "index.md")):
        entries.append(f"{prefix}/index.md")

    for root, dirs, files in os.walk(section_dir):
        dirs.sort()
        for f in sorted(files):
            if f.endswith(".md") and f != "index.md":
                rel = os.path.relpath(os.path.join(root, f), DOCS_DIR)
                entries.append(rel)
    return entries

def build_nav():
    nav = [{"Home": "index.md"}]

    for dirname, label in SECTION_NAMES.items():
        section_dir = os.path.join(DOCS_DIR, dirname)
        if not os.path.isdir(section_dir):
            continue
        entries = scan_section(section_dir, dirname)
        if entries:
            nav.append({label: entries})

    # Questions page
    if os.path.exists(os.path.join(DOCS_DIR, "questions.md")):
        nav.append({"Questions": "questions.md"})

    return nav

def update_mkdocs():
    with open(MKDOCS_FILE, "r") as f:
        config = yaml.safe_load(f)

    config["nav"] = build_nav()

    with open(MKDOCS_FILE, "w") as f:
        yaml.dump(config, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

if __name__ == "__main__":
    update_mkdocs()
    print("Nav updated.")
