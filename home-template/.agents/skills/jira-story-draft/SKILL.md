---
name: jira-story-draft
description: Turn a rough request into a Jira Story draft after a duplicate check and a scan of which repos/* sub-repos are affected. Use when a PM says draft a story, split this epic, or assess which repos a request touches.
---

# jira-story-draft

把一个想法变成可评审的 Story 草稿。**草稿先给 PM 看，PM 明确说"建单"才调写工具。**

项目参数一律从 `AGENTS.md` 读：Jira 项目 Key、`repos/*` 子仓清单与角色分类、`repos/team-wiki/` 是否就绪。工具名以 `atlassian_jira_*` 为准。

## 1. 先查重

1. `atlassian_jira_get_all_projects` 确认 `AGENTS.md` 里的项目 Key 可见（连不上就停下报错，不要凭记忆编 Key）。
2. `atlassian_jira_search` 用 JQL 查重，至少两轮：
   - 关键词：`project = <KEY> AND text ~ "<核心名词>" AND statusCategory != Done`
   - 近义/旧称：把用户口语词换成 `AGENTS.md` 与术语表里的正式术语再搜一次。
3. 命中相似卡片就列出来（Key + summary + 状态），建议「并入现有单」或「新建并 link」，交 PM 判断。

## 2. 影响面

对照 `AGENTS.md` 第 1、2 节的子仓角色与调用链判断要动哪几层：

| 变更落点 | 受影响仓 |
|---|---|
| 底层事实/数据访问 | `shared-lib` 之下的最底层 `service` |
| 业务规则/编排 | 对应的中层 `service` |
| 面向端聚合/适配 | 顶层 `service` |
| 页面渲染/交互 | `ui` |
| 公共类型/错误码/共享校验 | `shared-lib` + 所有下游的依赖声明版本对齐 |
| 跨层验收 | `e2e` 仓（QA 所有，不列入开发改动） |

不确定就写"待 architect 评估"，不要硬猜仓名。

## 3. 判级

- **L0**：单仓单文件、无业务规则变更（文案、依赖小版本）。
- **L1**：单仓或少量跨仓新功能、改业务规则。
- **L2**：多服务联动、数据模型/接口契约大改、改共享库公共类型/错误码语义、推翻旧 ADR。

判不准就按**高一级**建议，并写明不确定点。

## 4. 输出草稿（写进 `.scratch/<KEY>/story-draft.md`）

```markdown
## Summary
<一句话，含业务对象与动作>

## Description
背景 / 目标 / 非目标

## 验收标准（草稿，待 ba 细化为 AC-N）
- ...

## 影响仓
- <repo>（原因）

## 建议级别
L1（理由）

## 拆分建议
1. ...（每片可独立交付、独立验收）
```

## 5. 建单（必须人工确认）

1. `atlassian_jira_get_project_issue_types` 取可选类型，`atlassian_jira_get_create_fields` 取必填字段。
2. 用第 4 节的草稿组装 `fields`，把 summary / description / labels（`level-Ln` + 分拣标签，见 `docs/agents/triage-labels.md`）逐项展示给 PM。
3. PM 明确确认后才 `atlassian_jira_create_issue`；需要挂 Epic 用 `atlassian_jira_link_to_epic`。
   - **父 Story 是这单的权威 Spec 容器**：创建时描述里已有背景与草稿 AC，`ba` 阶段 B 会把完整 `spec.md` 回写进同一个 Story 描述。
   - **角色署名铁律**：描述末尾必须带一行 `**agent:pm | home@<version>** 初始建单`（版本取自 `VERSION`），否则同一个人 Token 下的多个 Agent 发言无法区分。
4. 返回新建 Key，并提示下一步：Dev 用 `ba` + `/grill-with-docs` 写 `spec.md`。
5. 建单失败（字段校验、权限）时原样回报错误，不要反复重试不同字段组合。
