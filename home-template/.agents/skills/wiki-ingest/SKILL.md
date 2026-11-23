---
name: wiki-ingest
description: Distill long-lived glossary terms, cross-service ADRs, or runbooks into a team-wiki Draft PR. Use when the librarian is asked to record knowledge after a feature merges or an incident resolves.
---

# wiki-ingest

只沉淀**长期公共常识**：业务术语、跨服务架构决策（ADR）、排障/发布手册。

**就绪检查**：知识库仓位于 `repos/team-wiki/`（见 `AGENTS.md`）。目录不存在时报告「`repos/team-wiki/` 未就绪，本次无可沉淀目标」并停止 —— 不要凭空创建 wiki 内容，也不要写进 `home/`。

## 严禁

- 摘要代码实现（"某方法先查表再算金额"这类）。wiki 记判断与约定，不记实现。
- 把一次性 `spec.md` / `plan.md` 全文倒进 wiki。
- 直接提交或推送到 `main`。

## 步骤

1. 定目标页：术语表、`adr/NNNN-<slug>.md`（决策）、`runbooks/<topic>.md`（手册）三选一；先列目录与检索是否已有同主题页，有就更新而不是新建。
2. 切新分支：`git -C repos/team-wiki switch -c wiki/<JIRA-KEY>-<slug>`（从最新 `main` 起）。
3. 写内容，**每个新建/更新页必须有完整 frontmatter**：

```markdown
---
title: <一句话标题>
type: glossary | adr | runbook
status: draft
updated: <YYYY-MM-DD>
sources:
  - <JIRA-KEY>
  - home@<VERSION>
---
```

4. 内容取自 `.scratch/<JIRA-KEY>/adr-draft.md` 或本次真实结论；每条决策写 `Justified-by:`，推翻旧决策写 `Supersedes:`。
5. 跑校验：`repos/team-wiki/scripts/wiki-check --fix-index`，必须通过（frontmatter 完整、无断链、无孤儿页、index 重建）。脚本报错就修内容，不要改脚本绕过。
6. 刷新检索索引：在 **`home/` 根目录**跑 `qmd update`（索引库在 `home/.qmd/`，不在子仓）。**严禁在 `repos/team-wiki/` 里 `qmd init`**：`index.md` / `log.md` / `README.md` 已由 `collections.team-wiki.ignore` 排除，不要把它们加回索引。
7. 提 Draft PR：`gh pr create --draft --title "wiki: <标题> (<JIRA-KEY>)" --body "..."`。PR 描述写清：沉淀了什么、来源单号、合并后是否要通知谁。
   - 本沙盒无远端 GitHub remote，`gh pr create` 会返回 `no git remotes found`：把完整 PR 标题 + body 落盘到 `.scratch/<JIRA-KEY>/wiki-pr-description.md`，供人工审阅合入，**不要 push、不要建远端**。
8. 报告分支名、commit SHA、PR 链接或落盘路径，等人工合并。合并前不要推 `main`、不要 `gh pr merge`。
