# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps those roles to the strings actually used in this project's tracker.

## 五个规范分拣角色 → 本项目取值（Jira 项目 Key 以 `AGENTS.md` 为准）

| Label in mattpocock/skills | 本项目取值 | 含义 |
| --- | --- | --- |
| `needs-triage` | Jira 状态 `To Do` + label `needs-triage` | PM 尚未评估 |
| `needs-info` | Jira 状态 `To Do` + label `needs-info` | 等报告人补充信息 |
| `ready-for-agent` | Jira 状态 `To Do` + label `ready-for-agent` | 规格完整，可交给 `implementer` |
| `ready-for-human` | Jira 状态 `To Do` + label `ready-for-human` | 需人工实现 |
| `wontfix` | Jira 状态 `Done` + label `wontfix` | 不做 |

## 改动分级标签

| 级别 | 标签 | 必经流程 |
| --- | --- | --- |
| L0 | `level-L0` | `implementer` → PR Review |
| L1 | `level-L1` | `pm` → `ba`（Jira 确认）→ `implementer` ↔ `qa` → `@reviewer` |
| L2 | `level-L2` | 全链路（含 `architect` 的 `plan.md` + `adr-draft.md` + `librarian` 沉淀） |

## 状态映射（五个门）

| 门 | Jira 状态 | 本地产物 |
| --- | --- | --- |
| 需求确认完成 | `To Do` → `In Progress` | `spec.md`（`status: approved`） |
| 方案确认完成 | `In Progress`（`architect` 同时建 Subtask + `Blocks` 边） | `plan.md`、`adr-draft.md` |
| 实现自测完成 | 各 Subtask `To Do` → `In Progress` → `Done`（附 commit SHA 评论）；父 Story 仍 `In Progress` | 各仓 PR（带同一 `JIRA-KEY`） |
| 验收通过 | 父 Story `In Progress` → `In Review` | `qa-report.md` + `release-checklist.md`（`status: final`） |
| 评审通过 / 上线 | 父 Story `In Review` → `Done` | `review.md` |

- 父 Story 与 Subtask 是**两套独立状态链**，不要混用：Subtask 只到 `Done`，父 Story 才到 `In Review` / `Done`。
- `level-L*` 与 `ready-for-agent` 打在父 Story 上；Subtask 建单时也带 `ready-for-agent`，方便按标签筛 Frontier。

Bug 单用 issue type `Bug`，通过 `atlassian_jira_create_issue_link` 关联原 Story。

改「本项目取值」列即可适配别的 Jira 项目，其余文件无需改动；换项目时更推荐重跑 `/project-setup` 让它整份重建。
