#!/usr/bin/env python3
"""
publish.sh — Obsidian → Jekyll 一键发布脚本

用法:
  ./publish.sh /path/to/vault/note.md                          # 发布单篇
  ./publish.sh /path/to/vault/note.md --emoji 🔧 --tag Crash   # 带 emoji 标签
  ./publish.sh /path/to/vault/folder/                          # 批量发布
  ./publish.sh /path/to/vault/note.md --push                   # 发布并 git push
"""

import os
import re
import sys
import subprocess
from pathlib import Path

BLOG_ROOT = Path(__file__).parent.resolve()
POSTS_DIR = BLOG_ROOT / "_posts"


def parse_obsidian_yaml(content: str) -> tuple[dict, str]:
    """解析 Obsidian YAML front matter，返回 (metadata, body)。"""
    if not content.startswith("---"):
        return {}, content

    end = content.find("---", 3)
    if end == -1:
        return {}, content

    yaml_block = content[3:end].strip()
    body = content[end + 3:].strip()

    meta = {}
    for line in yaml_block.split("\n"):
        if ":" in line:
            key, _, value = line.partition(":")
            meta[key.strip()] = value.strip()

    return meta, body


def extract_title(body: str, filename: str) -> str:
    """从正文第一个 # 标题提取标题，无则从文件名推断。"""
    match = re.search(r"^#\s+(.+)$", body, re.MULTILINE)
    if match:
        return match.group(1).strip()

    name = Path(filename).stem
    return name


def format_title(title: str, emoji: str = "", tag: str = "") -> str:
    """格式化标题为 emoji【tag】title 格式。"""
    if emoji and tag:
        return f"{emoji}【{tag}】{title}"
    return title


def slugify(title: str) -> str:
    """生成文件名 slug。中文保留，特殊字符替换为 -。"""
    slug = re.sub(r"[^\w一-鿿-]", "-", title)
    slug = re.sub(r"-+", "-", slug).strip("-")
    return slug


def convert_obsidian_syntax(body: str) -> str:
    """将 Obsidian 特有语法转换为标准 Markdown。"""

    # 先处理嵌入（![[...]]），再处理 wikilink（[[...]]），避免顺序问题
    # ![[image.png]] → 跳过（MVP 不处理图片）
    body = re.sub(r"!\[\[[^\]]+\]\]", "", body)

    # ![[note.md]] → 跳过
    body = re.sub(r"!\[\[[^\]]+\.md\]\]", "", body)

    # [[wikilink]] → wikilink
    # [[note|别名]] → 别名
    body = re.sub(
        r"\[\[([^\]|]+)\|([^\]]+)\]\]",
        r"\2",
        body,
    )
    body = re.sub(
        r"\[\[([^\]]+)\]\]",
        r"\1",
        body,
    )

    # > [!type] Title  →  > **Type** Title
    # > [!type]         →  > **Type**
    def convert_callout(m):
        callout_type = m.group(1).capitalize()
        rest = m.group(2).strip()
        if rest:
            return f"> **{callout_type}** {rest}"
        return f"> **{callout_type}**"

    body = re.sub(
        r"^>\s*\[!([a-z]+)\]\s*(.*)$",
        convert_callout,
        body,
        flags=re.MULTILINE,
    )

    # 清理 Obsidian 标签（#标签 格式，行首或行内）
    body = re.sub(r"(?m)^#\S+(\s+#\S+)*\s*$", "", body)
    body = re.sub(r"(?<!\w)#[\w一-鿿]+", "", body)

    # 清理多余空行（超过 2 个连续空行 → 2 个）
    body = re.sub(r"\n{3,}", "\n\n", body)

    return body


def generate_jekyll_post(meta: dict, body: str, title: str, date_str: str) -> str:
    """生成 Jekyll 格式的文章内容。"""
    front_matter = f"""---
layout: post
title: {title}
date: {date_str}
---"""

    return f"{front_matter}\n{body}\n"


def get_output_path(date_str: str, slug: str) -> Path:
    """生成输出文件路径，处理同名冲突。"""
    date_prefix = date_str.split(" ")[0]
    filename = f"{date_prefix}-{slug}.md"
    output = POSTS_DIR / filename

    counter = 2
    while output.exists():
        filename = f"{date_prefix}-{slug}-{counter}.md"
        output = POSTS_DIR / filename
        counter += 1

    return output


def publish_note(source: Path, emoji: str = "", tag: str = "") -> Path | None:
    """发布单篇笔记到 _posts/。"""
    if not source.exists():
        print(f"  ✗ 文件不存在: {source}")
        return None

    content = source.read_text(encoding="utf-8")
    meta, body = parse_obsidian_yaml(content)

    if not body:
        print(f"  ✗ 文件内容为空: {source.name}")
        return None

    # 提取日期
    date_str = meta.get("created", "")
    if not date_str:
        mtime = source.stat().st_mtime
        from datetime import datetime
        date_str = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M")
        print(f"  ⚠ 无 created 字段，使用文件修改时间: {date_str}")

    # 提取标题并格式化
    raw_title = extract_title(body, source.name)
    title = format_title(raw_title, emoji, tag)
    slug = slugify(raw_title)

    # 转换语法
    body = convert_obsidian_syntax(body)

    # 生成 Jekyll 文章
    post_content = generate_jekyll_post(meta, body, title, date_str)

    # 写入
    output_path = get_output_path(date_str, slug)
    POSTS_DIR.mkdir(parents=True, exist_ok=True)
    output_path.write_text(post_content, encoding="utf-8")

    print(f"  ✓ {source.name} → {output_path.name}")
    return output_path


def git_push(files: list[Path], title: str):
    """git add + commit + push。"""
    for f in files:
        subprocess.run(["git", "add", str(f)], cwd=BLOG_ROOT, check=True)

    msg = f"post: {title}" if len(files) == 1 else f"post: 批量发布 {len(files)} 篇"
    subprocess.run(["git", "commit", "-m", msg], cwd=BLOG_ROOT, check=True)
    subprocess.run(["git", "push"], cwd=BLOG_ROOT, check=True)
    print(f"\n✓ 已推送到远程仓库")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    push = "--push" in sys.argv
    args = [a for a in sys.argv[1:] if a != "--push"]

    # 解析 --emoji 和 --tag
    emoji = ""
    tag = ""
    positional = []
    i = 0
    while i < len(args):
        if args[i] == "--emoji" and i + 1 < len(args):
            emoji = args[i + 1]
            i += 2
        elif args[i] == "--tag" and i + 1 < len(args):
            tag = args[i + 1]
            i += 2
        else:
            positional.append(args[i])
            i += 1

    if not positional:
        print(__doc__)
        sys.exit(1)

    source = Path(positional[0]).resolve()

    if source.is_dir():
        files = sorted(source.glob("*.md"))
        if not files:
            print(f"目录中没有 .md 文件: {source}")
            sys.exit(1)

        print(f"批量发布 {len(files)} 篇文章...\n")
        published = []
        for f in files:
            result = publish_note(f, emoji, tag)
            if result:
                published.append(result)

        if push and published:
            git_push(published, "")

        print(f"\n完成: {len(published)}/{len(files)} 篇已发布")

    elif source.is_file():
        result = publish_note(source, emoji, tag)
        if result and push:
            git_push([result], result.stem)

    else:
        print(f"路径不存在: {source}")
        sys.exit(1)


if __name__ == "__main__":
    main()
