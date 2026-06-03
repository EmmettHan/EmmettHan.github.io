# Obsidian → Jekyll 一键发布脚本设计

## 目标

极简化从 Obsidian vault 发布文章到 Jekyll 博客的流程。当前需要手动复制、改名、加 front matter、转换语法、git push，目标是一条命令搞定。

## 命令

```bash
# 单篇发布（只生成文件到 _posts/）
./publish.sh /path/to/vault/article.md

# 批量发布目录下所有 .md
./publish.sh /path/to/vault/folder/

# 自动 git commit + push
./publish.sh /path/to/vault/article.md --push
```

## 核心流程

```
输入: Obsidian note                    输出: Jekyll post
┌──────────────────┐                  ┌──────────────────┐
│ ---              │                  │ ---              │
│ created: 2024... │ ──提取日期──→    │ layout: post     │
│ modified: 2025.. │                  │ title: xxx       │
│ ---              │                  │ date: 2024-11-12 │
│                  │                  │ ---              │
│ [[wiki link]]    │ ──转为纯文本──→  │ wiki link        │
│ > [!note] xxx    │ ──转换──→        │ > **Note** xxx   │
│ ![[image.png]]   │ ──忽略(MVP)──→   │ (跳过)           │
└──────────────────┘                  └──────────────────┘
```

## 语法转换规则

| Obsidian 语法 | 转换结果 | 说明 |
|---|---|---|
| `[[wikilink]]` | `wikilink` | 保留文字，去掉 `[[]]` |
| `[[note\|别名]]` | `别名` | 用别名部分 |
| `> [!note] Title` | `> **Title**` | callout 转 blockquote + 加粗标题 |
| `> [!note]` (无标题) | `> **Note**` | 默认标题 |
| `> [!warning] Title` | `> **⚠ Title**` | 可选加 emoji 前缀 |
| `![[image.png]]` | 跳过（MVP） | 后续版本处理图片上传 |
| `![[note.md]]` | 跳过 | embed 不支持 |

## Front Matter 生成

```yaml
---
layout: post
title: "推断的标题"
date: 2024-11-12 15:50
---
```

- `date`：从 Obsidian YAML 的 `created` 字段读取
- `title`：优先取正文第一个 `# 标题`；无则从文件名推断
- `layout: post` 固定

## 文件命名

- 输出文件名：`{YYYY-MM-DD}-{原始文件名}.md`
- 示例：`/vault/域名解析.md`（created: 2024-11-12）→ `_posts/2024-11-12-域名解析.md`
- 同名冲突：加 `-2`、`-3` 后缀

## Git 操作

- 默认不触发 git 操作，只生成文件
- `--push` 时：`git add _posts/xxx.md && git commit -m "post: {title}" && git push`

## MVP 范围

- [x] 读取 Obsidian YAML front matter 中的 `created` 日期
- [x] 转换 wikilink 为纯文本
- [x] 转换 callout 语法为 blockquote
- [x] 忽略图片嵌入
- [x] 忽略笔记嵌入
- [x] 自动生成 Jekyll front matter
- [x] 生成 `YYYY-MM-DD-slug.md` 到 `_posts/`
- [x] 可选 `--push` 自动提交

## 后续版本（不在 MVP 范围）

- 图片上传到图床（需先选定图床方案）
- 批量发布时的交互式选择
- 从 Obsidian 内直接调用（Templater 插件集成）
