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
  1. 所有页面必须包含完整 YAML frontmatter（`title`, `type`, `status`, `updated`, `sources`），且不可出现孤儿页或断链（由 `./scripts/wiki-check` 强制校验）。
  2. `librarian` 角色永不直接推送 `main`，一律切新分支、运行 `./scripts/wiki-check --fix-index` 后提 GitHub Draft PR，经团队同事 Review 后合入。
  3. 本地检索统一在 `home/` 根目录初始化 `home/.qmd/`（并在 `.qmd/index.yml` 中设置 `ignore: ["index.md", "log.md", "README.md"]`）。
