---
title: 团队统一业务术语表
type: glossary
status: active
updated: 2026-11-23
sources: [AGENTS.md]
---

# 团队统一业务术语表（GLOSSARY）

> 跨系统、跨微服务共享的业务名词、金额/状态口径与核心领域概念定义。
> - **何时维护**：无需等项目结束——在 `ba` 运行 `/grill-with-docs`（内部调用 `grilling` + `domain-modeling`）追问需求时，即可边对齐边识别新术语，并在上线后由 `@librarian`（`/wiki-ingest`）合入本表。
> - **必填三要素（Matt Pocock 规范）**：每个词条必须包含 **标准名称（中/英）**、**精确业务定义与不变量**、以及 **`_Avoid_`（禁用同义词/易混词黑名单）**，防止不同子仓、前端或邮件对同一概念发明三种名字。
> - 相关架构决策参见 [ADR-0001](adr/0001-wiki-conventions.md) 及发布手册 [发布与回滚手册](runbooks/release-order.md)。

| 标准术语（Canonical Term） | 英文标识（Identifier） | 业务定义与不变量（Definition & Invariants） | 禁用别名（`_Avoid_` — 严禁在代码/接口/文档中混用） |
|---|---|---|---|
| 示例：已省金额 | `savedAmount` | 订单原价减去折后应付金额的差值（两位小数，`HALF_UP`，恒满足 `originalAmount - payableAmount == savedAmount`） | `_Avoid_`: `discountMoney`, `deduction`, `rebateAmount`, `reducedPrice` |
