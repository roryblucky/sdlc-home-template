---
name: wiki-ingest
description: Distill long-lived glossary terms, cross-service ADRs, or runbooks into a team-wiki Draft PR. Use when the librarian is asked to record knowledge after a feature merges or an incident resolves.
---

# wiki-ingest

只沉淀**长期公共常识**：
- `GLOSSARY.md`：全局业务与技术术语表（含 `_Avoid_` 禁用别名）
- `domains/<domain>.md`：核心业务域规则与不变量契约
- `standards/<topic>.md`：跨仓技术规范（API 约定、错误码体系、数据库/事件命名、安全合规等）
- `designs/<topic>.md`：跨服务架构设计文档（RFC / System Design / 数据流与状态机设计）
- `adr/NNNN-<slug>.md`：架构决策记录（Architecture Decision Records）
- `runbooks/<topic>.md`：发布顺序、变更操作手册、线上排障 Playbook
- `postmortems/YYYY-MM-DD-<slug>.md`：线上故障无指责复盘（5 Whys 与防复发 Action Items）
- `onboarding/<topic>.md`：团队环境搭建、服务拓扑导览、外部系统/测试账号速查

**就绪检查**：知识库仓位于 `repos/team-wiki/`（见 `AGENTS.md`）。目录不存在时报告「`repos/team-wiki/` 未就绪，本次无可沉淀目标」并停止 —— 不要凭空创建 wiki 内容，也不要写进 `home/`。

## 严禁

- 摘要代码实现（"某方法先查表再算金额"这类）。wiki 记判断与约定，不记实现。
- 把一次性 `spec.md` / `plan.md` 全文倒进 wiki。
- 直接提交或推送到 `main`。

## 步骤

1. 定目标页：根据知识类型归入上述目录（`GLOSSARY.md`、`domains/`、`standards/`、`designs/`、`adr/`、`runbooks/`、`postmortems/`、`onboarding/`）；先读 `repos/team-wiki/index.md` 或运行 `python3 scripts/wiki-search "<关键词>"` 查重，已有同主题页就更新而不是新建。
2. 切新分支：`git -C repos/team-wiki switch -c wiki/<JIRA-KEY>-<slug>`（从最新 `main` 起）。
3. 写内容，**每个新建/更新页必须有完整 frontmatter**：

```markdown
---
title: <一句话标题>
type: glossary | domain | standard | design | adr | runbook | postmortem | onboarding
status: draft | approved
updated: <YYYY-MM-DD>
sources:
  - <JIRA-KEY>
  - home@<VERSION>
---
```

4. 内容取自 `.scratch/<JIRA-KEY>/adr-draft.md` 或本次真实结论；每条决策写 `Justified-by:`，推翻旧决策写 `Supersedes:`。并确保在 `GLOSSARY.md` 或相关页面建立双向/入口链接（避免 `wiki-check` 报 `orphan page`）。
5. 跑校验：`python3 repos/team-wiki/scripts/wiki-check --fix-index`，必须通过（frontmatter 完整、无断链、无孤儿页、`index.md` 重建）。脚本报错就修内容，不要改脚本绕过。
6. 刷新检索索引：在 **`home/` 根目录**跑 `python3 scripts/wiki-search update`（零依赖 SQLite FTS5 BM25 索引库位于 `home/.qmd/`，不在子仓）。`index.md` / `log.md` / `README.md` 已自动由 `collections.team-wiki.ignore` 排除。
7. 提 Draft PR：`gh pr create --draft --title "wiki: <标题> (<JIRA-KEY>)" --body "..."`。PR 描述写清：沉淀了什么、来源单号、合并后是否要通知谁。
   - 若无远端 GitHub remote，`gh pr create` 会返回 `no git remotes found`：把完整 PR 标题 + body 落盘到 `.scratch/<JIRA-KEY>/wiki-pr-description.md`，供人工审阅合入，**不要 push、不要建远端**。
8. 报告分支名、commit SHA、PR 链接或落盘路径，等人工合并。合并前不要推 `main`、不要 `gh pr merge`。
