#!/usr/bin/env python3
"""Auto-generate mkdocs.yml nav + index pages from docs directory structure."""
import os, re, yaml
from datetime import datetime, timedelta

DOCS_DIR = os.path.expanduser("~/research/docs")
MKDOCS_FILE = os.path.expanduser("~/research/mkdocs.yml")

SECTION_NAMES = {
    "gaming": "Gaming",
    "marketing": "Marketing",
    "creative": "Creative",
    "finance": "Finance",
    "_reports": "Reports",
}

SECTION_DESC = {
    "gaming": "게임 산업 동향, 시장 분석, 경쟁사, 기술",
    "marketing": "마케팅 전략, 사례, 데이터 분석",
    "creative": "디자인, 콘텐츠 기획, 제작 도구",
    "finance": "주식, 크립토, 투자 분석",
    "_reports": "분야 횡단 종합 리포트",
}

def get_research_files(section_dir=None):
    """Get all research .md files with metadata, sorted by date desc."""
    search_dir = section_dir or DOCS_DIR
    files = []
    for root, dirs, fnames in os.walk(search_dir):
        dirs[:] = [d for d in dirs if d not in ("assets", "_templates")]
        for f in fnames:
            if not f.endswith(".md") or f == "index.md" or f == "questions.md":
                continue
            fpath = os.path.join(root, f)
            rel = os.path.relpath(fpath, DOCS_DIR)

            # Extract title from first # heading
            title = f.replace(".md", "").replace("_", " ")
            date_str = ""
            try:
                with open(fpath, "r") as fp:
                    content = fp.read()
                    # Get title
                    tm = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
                    if tm:
                        title = tm.group(1).strip()
                    # Get date from frontmatter
                    dm = re.search(r"^date:\s*(\d{4}-\d{2}-\d{2})", content, re.MULTILINE)
                    if dm:
                        date_str = dm.group(1)
            except:
                pass

            files.append({
                "path": rel,
                "title": title,
                "date": date_str,
                "filename": f,
            })

    files.sort(key=lambda x: x["date"], reverse=True)
    return files


def is_new(date_str, hours=24):
    """Check if a date string is within the last N hours."""
    if not date_str:
        return False
    try:
        d = datetime.strptime(date_str, "%Y-%m-%d")
        return datetime.now() - d < timedelta(hours=hours)
    except:
        return False


def generate_home_page(all_files):
    """Generate home index.md showing recent/NEW research."""
    new_files = [f for f in all_files if is_new(f["date"], 48)]
    recent_files = all_files[:10]

    lines = ["# Research Hub\n"]

    if new_files:
        lines.append("## :new: 최신 리서치\n")
        for f in new_files:
            lines.append(f"- [{f['title']}]({f['path']}) `{f['date']}`")
        lines.append("")

    lines.append("## 최근 리서치\n")
    if recent_files:
        lines.append("| 날짜 | 제목 |")
        lines.append("|------|------|")
        for f in recent_files:
            lines.append(f"| {f['date']} | [{f['title']}]({f['path']}) |")
    else:
        lines.append("*아직 리서치가 없습니다.*")
    lines.append("")

    with open(os.path.join(DOCS_DIR, "index.md"), "w") as fp:
        fp.write("\n".join(lines))


def generate_section_page(dirname, label, section_files):
    """Generate section index.md showing recent research for that category."""
    index_path = os.path.join(DOCS_DIR, dirname, "index.md")
    new_files = [f for f in section_files if is_new(f["date"], 48)]

    lines = [f"# {label}\n", f"> {SECTION_DESC.get(dirname, '')}\n"]

    if new_files:
        lines.append("## :new: 신규\n")
        for f in new_files:
            rel = os.path.relpath(os.path.join(DOCS_DIR, f["path"]), os.path.join(DOCS_DIR, dirname))
            lines.append(f"- [{f['title']}]({rel}) `{f['date']}`")
        lines.append("")

    lines.append("*좌측 사이드바에서 전체 리서치 목록을 확인할 수 있습니다.*\n")

    with open(index_path, "w") as fp:
        fp.write("\n".join(lines))


def scan_section(section_dir, prefix):
    """Scan a section directory and return nav entries."""
    entries = []
    if os.path.exists(os.path.join(section_dir, "index.md")):
        entries.append(f"{prefix}/index.md")

    for root, dirs, files in os.walk(section_dir):
        dirs.sort()
        for f in sorted(files, reverse=True):  # newest first
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

    if os.path.exists(os.path.join(DOCS_DIR, "questions.md")):
        nav.append({"Questions": "questions.md"})

    return nav


def update_mkdocs():
    with open(MKDOCS_FILE, "r") as f:
        config = yaml.safe_load(f)

    config["nav"] = build_nav()

    with open(MKDOCS_FILE, "w") as f:
        yaml.dump(config, f, default_flow_style=False, allow_unicode=True, sort_keys=False)


def generate_new_data(all_files):
    """Generate JS data file with list of NEW research titles."""
    import json
    new_files = [f for f in all_files if is_new(f["date"], 48)]
    new_titles = [f["title"] for f in new_files]
    # Also include section names that contain new items
    new_sections = set()
    for f in new_files:
        parts = f["path"].split("/")
        if parts:
            for sname, slabel in SECTION_NAMES.items():
                if f["path"].startswith(sname + "/"):
                    new_sections.add(slabel)
    data = {"titles": new_titles, "sections": list(new_sections)}
    js_path = os.path.join(DOCS_DIR, "assets", "js", "research-data.js")
    os.makedirs(os.path.dirname(js_path), exist_ok=True)
    with open(js_path, "w") as fp:
        fp.write("window.__RESEARCH_NEW = " + json.dumps(data, ensure_ascii=False) + ";\n")


if __name__ == "__main__":
    all_files = get_research_files()

    # Generate home page
    generate_home_page(all_files)

    # Generate each section page
    for dirname in SECTION_NAMES:
        section_dir = os.path.join(DOCS_DIR, dirname)
        if os.path.isdir(section_dir):
            section_files = get_research_files(section_dir)
            generate_section_page(dirname, SECTION_NAMES[dirname], section_files)

    # Generate NEW data for JS
    generate_new_data(all_files)

    # Update nav
    update_mkdocs()
    print("Nav + index pages updated.")
