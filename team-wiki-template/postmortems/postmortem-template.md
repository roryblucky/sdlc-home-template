---
title: 线上故障无指责复盘模板（Blameless Postmortem）
type: postmortem
status: active
updated: 2026-11-24
sources: [GLOSSARY.md]
---

# 线上故障无指责复盘模板（`postmortems/`）

> 本目录存放线上故障或重大质量事故的**无指责复盘报告（Blameless Postmortem）**。
> - **复盘闭环管线（Postmortem → Runbook / Standards）**：每次事故复盘的 Action Items 必须转化为可执行的应急手册（更新至 [发布与回滚手册](../runbooks/release-order.md)）或技术规范（更新至 [跨服务 API、错误码与数据契约规范](../standards/api-and-error-codes.md)），并同步通过 `/retro` 收紧 `home/CODING_STANDARDS.md`。

## 1. 故障摘要与影响面（Summary & Impact）

- **发生时间 / 持续时长**：
- **影响业务域与指标**：（使用 [GLOSSARY.md](../GLOSSARY.md) 中的标准术语）

## 2. 根因分析（Root Cause — 5 Whys）

- 为什么第一道刹车（Linter/自动化测试）与第二道刹车（`@reviewer`）未能拦截？

## 3. 防复发改进项（Action Items）

- [ ] **新增/更新测试或 Linter 规则**：
- [ ] **新增/更新 `runbooks/` 或 `standards/`**：
- [ ] **通过 `/retro` 更新 `CODING_STANDARDS.md`**：
