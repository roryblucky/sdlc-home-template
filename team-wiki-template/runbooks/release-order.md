---
title: 跨仓发布与反向回滚手册
type: runbook
status: active
updated: 2026-11-22
sources: [AGENTS.md]
---

# 跨仓发布与反向回滚手册

- 遵循 [ADR-0001](../adr/0001-wiki-conventions.md) 与 [GLOSSARY.md](../GLOSSARY.md) 规范。
- **发布顺序**：自底向上（先 `shared-lib` 公共库 → 底层 `system-api` → 中层 `processing-api` → 顶层 `experience-api` → 前端 `ui`）。
- **回滚顺序**：自顶向下反向回滚，严禁在下游仍依赖新版公共库契约时先行回滚底层服务。
