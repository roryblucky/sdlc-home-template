---
title: 核心业务领域契约模板（Domain Contract Template）
type: domain
status: active
updated: 2026-11-24
sources: [GLOSSARY.md]
---

# 核心业务领域契约模板（`domains/`）

> 本目录存放按业务域（如计价、订单、库存、权限、账务）聚合的**长期业务规则与不变量（Invariants）**。
> - 术语标准请统一遵循 [GLOSSARY.md](../GLOSSARY.md)；
> - 关联的接口与错误码约定请参考 [跨服务 API 与错误码规范](../standards/api-and-error-codes.md)。

## 1. 领域边界与权威数据源（Source of Truth）

- **所属子仓**：`repos/<service-name>`
- **核心实体**：引用 [GLOSSARY.md](../GLOSSARY.md) 中的标准标识

## 2. 业务不变量（Domain Invariants — 任何改动不可违背）

1. **金额/精度不变量**：例如 `originalAmount - payableAmount == savedAmount` 恒成立。
2. **状态机合法流转**：列出合法状态迁移边与禁止回退的终态。

## 3. 边界与异常规则

- 明确零值、负数、并发幂等、超时降级时的确定性业务表现。
