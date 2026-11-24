---
title: ADR-0001 团队知识库（LLM Wiki）维护规范
type: adr
status: accepted
updated: 2026-11-22
sources: [GLOSSARY.md]
---

# ADR-0001：团队知识库（LLM Wiki）维护规范

- **背景**：跨多微服务协作时，核心业务术语（见 [GLOSSARY.md](../GLOSSARY.md)）、跨仓契约决策与发布顺序（见 [发布与回滚手册](../runbooks/release-order.md)）需沉淀在独立 Git 仓库 `team-wiki` 中供全员与 Agent 同步检索。
- **决策**：
  1. 知识库采用 **8 大标准分类**：`GLOSSARY.md`（统一术语表）、`domains/`（业务域契约）、`standards/`（跨仓技术规范）、`designs/`（系统架构设计 RFC）、`adr/`（架构决策记录）、`runbooks/`（发布与排障手册）、`postmortems/`（无指责故障复盘）、`onboarding/`（团队全景与新人导览）。
  2. 所有页面必须包含完整 YAML frontmatter（`title`, `type`, `status`, `updated`, `sources`），且不可出现孤儿页或断链（由 `./scripts/wiki-check` 强制校验）。
  3. `librarian` 角色永不直接推送 `main`，一律切新分支、运行 `./scripts/wiki-check --fix-index` 后提 GitHub Draft PR，经团队同事 Review 后合入。
  4. 本地检索采用**零第三方依赖、零本地模型**的 `python3 scripts/wiki-search`（基于 Python 标准库 `sqlite3` FTS5 BM25，在 `home/` 根目录自动生成 `home/.qmd/index.yml` 与 `home/.qmd/index.sqlite`，并自动忽略 `index.md`、`log.md`、`README.md`）。
