---
title: 团队服务全景与新人导览（Onboarding & System Map）
type: onboarding
status: active
updated: 2026-11-24
sources: [GLOSSARY.md]
---

# 团队服务全景与新人导览（`onboarding/`）

> 本目录存放面向团队新成员与 Agent 的**全局架构导览、环境配置速查、测试环境入口与外部依赖说明**。
> - **Onboarding Test（最佳实践）**：每位新成员加入团队的前两周内，若发现文档与实际环境不符，请通过 `@librarian`（`/wiki-ingest`）提一个修正 PR。

## 1. 核心阅读路线

1. **业务语言对齐**：先读 [GLOSSARY.md](../GLOSSARY.md) 与 [核心业务领域契约模板](../domains/domain-template.md)
2. **技术规范与设计**：阅读 [跨服务 API、错误码与数据契约规范](../standards/api-and-error-codes.md)、[跨服务架构设计文档模板](../designs/design-template.md) 及 [ADR-0001](../adr/0001-wiki-conventions.md)
3. **发布与应急**：阅读 [发布与回滚手册](../runbooks/release-order.md) 与 [线上故障无指责复盘模板](../postmortems/postmortem-template.md)

## 2. 团队微服务与仓库拓扑速查

| 仓库名（`repos/*`） | 角色定位 | 上游依赖 | 下游消费方 | 本地联调注意点 |
|---|---|---|---|---|
| 示例：`repos/common-lib` | 公共契约与金额工具库 | 无 | 所有业务服务 | 修改后需先发布版本再升级下游 |
