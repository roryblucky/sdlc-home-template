---
title: 跨服务 API、错误码与数据契约规范
type: standard
status: active
updated: 2026-11-24
sources: [GLOSSARY.md]
---

# 跨服务 API、错误码与数据契约规范（`standards/`）

> 本目录存放团队跨仓库共享的**技术与工程标准**（区别于 `home/CODING_STANDARDS.md` 的单仓代码品味，此处沉淀跨微服务必须对齐的协议、命名、安全与兼容性规范）。
> - 字段命名必须严格使用 [GLOSSARY.md](../GLOSSARY.md) 中的标准英文标识（Identifier），严禁出现 `_Avoid_` 列中的禁用别名。
> - 跨服务契约升级的发布顺序见 [发布与回滚手册](../runbooks/release-order.md)。

## 1. 接口兼容性基线（Expand–Contract）

- **新增字段**：必须为可选（Optional）或提供向后兼容默认值；
- **废弃字段**：先新增替代字段并双写（Expand），待所有下游消费方升级完毕后再移除旧字段（Contract）。

## 2. 统一错误码规范

- 错误码枚举必须在公共契约层显式定义，禁止向客户端直接透传未捕获的底层异常堆栈。
- 业务规则校验失败须映射为确定性的业务错误码（参见 [核心业务领域契约模板](../domains/domain-template.md)）。

## 3. 日志、幂等与安全合规

- 写接口与消息消费端必须具备幂等键（Idempotency Key）；
- 日志中严禁打印明文密钥、Token 或敏感个人隐私数据（PII）。
