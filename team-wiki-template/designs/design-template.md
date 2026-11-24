---
title: 跨服务架构设计文档模板（RFC / System Design）
type: design
status: active
updated: 2026-11-24
sources: [GLOSSARY.md]
---

# 跨服务架构设计文档模板（`designs/`）

> 本目录存放跨模块、跨服务的 **Design Docs / RFC（Request for Comments）**。
> - **与 ADR 的区别**：`designs/` 记录完整系统拓扑、数据流、状态机与多方案权衡；当设计定稿后，将核心的单点技术拍板提炼为简短的 [ADR](../adr/0001-wiki-conventions.md)。
> - 所有业务名词必须与 [GLOSSARY.md](../GLOSSARY.md) 保持一致。

## 1. 背景与问题定义（Context & Problem）

- 当前系统痛点、业务目标与明确的非目标（Non-Goals）。

## 2. 系统拓扑与数据流（Architecture & Data Flow）

- 涉及的 `repos/*` 子仓、调用方向、核心状态机与存储变更（参考 [核心业务领域契约模板](../domains/domain-template.md)）。

## 3. 备选方案权衡（Design It Twice / Alternatives Considered）

- 方案 A vs 方案 B 的接口深度（Deep vs Shallow Module）、性能与维护成本对比。

## 4. 灰度、测试接缝与回滚计划（Rollout & Seams）

- 外部测试接缝（Testing Seams）定义，以及遵循 [发布与回滚手册](../runbooks/release-order.md) 的上线步骤。
