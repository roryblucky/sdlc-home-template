# Issue tracker: Jira MCP + `.scratch/`

Issue 与规格的权威存储是 **Jira（以 `AGENTS.md` 为准）**；本地只是工作缓存。

## Story / Spec / Ticket 三层映射

| Jira 对象 | 含义 | 谁写 | 本地产物 |
|---|---|---|---|
| 父 `Story` | **业务需求 + 权威 `spec.md` 的载体**：完整业务摘要与 `AC-1..N` 回写在描述里 | `pm` 建单 → `ba` 定稿回写 | `.scratch/<KEY>/spec.md` |
| 父 `Story` 评论 | 阶段 A 请求确认、阶段 B 定稿、验收报告、结单摘要 | `ba`、`qa`、主会话 | 同上 |
| 子 `Subtask` | **`/to-tickets` 拆出的 `Ticket` 开发执行单元**，用 `Blocks` 串先后阻塞边 | `architect` 建 → `implementer` 领取 | `.scratch/<KEY>/plan.md` |

对齐 `mattpocock/skills` 的链路：`/to-spec`（父 Story 成为 Spec）→ `/to-tickets`（Spec 拆成 Subtask/Ticket）→ `/implement`（逐个 Ticket 实现）→ `qa` 对照父 Story 上的 `spec.md` 整单验收。

## 角色署名（共用 Token 下区分 Agent 的唯一手段）

所有角色共用同一个人 Jira Token，**光看评论作者分不出是哪个 Agent 说的**。因此：

- 每次 `atlassian_jira_add_comment` / `atlassian_jira_edit_comment` 或在描述尾部追加内容，**首行必须是**：
  `**agent:<role> | home@<version>** <动作摘要>`
- 沙盒里模拟真人回复：`**human:business-user**`（不写版本号）。
- `retro` 式补签旧评论时只补首行，不改原文；<version> 取 `home/VERSION`。
- 角色与署名对应：`pm` 建单 / `ba` 阶段 A、B / `architect` Subtask 拆分汇总 / `implementer` Subtask 完成 / `qa` 验收报告 / `reviewer` 结单摘要。

> 快速自检：一条评论没有首行署名，就当它没写——别人无法判断这是谁做出的结论。
>
> **平台实测（必读）**：`**agent:<role> | home@<version>**` 带方括号的写法会被 mcp-atlassian 的 Markdown→ADF 当 Jira wiki 链接（`[text|url]`）处理，竖线被吃掉、变成破损链接；`\|`、`&#124;`、行内代码包裏三种转义均无效。实际写入用不带方括号的 `**agent:<role> | home@<version>**`（已逐字验证无损）。另外 `edit_comment` 是有损的 Markdown→ADF→Markdown 往返：空行会变多、`**粗**` 可能变 `__粗__`，补署名可以接受，但不要指望正文逐字不变。

## 本地工作缓存

- 一单一个目录：`home/.scratch/<JIRA-KEY>/`，**gitignored，永不提交**（`home/.ignore` 已放行检索，所以 `glob`/`grep` 能找到它）。
- 固定文件名（各角色只写自己那一个）：

| 文件 | 谁写 | 内容 |
|---|---|---|
| `spec.md` | `ba` | 业务确认摘要 + `AC-1..N`（门 1 产物） |
| `plan.md` | `architect` | 跨仓方案、接口契约、改动与发布顺序（门 2） |
| `adr-draft.md` | `architect` | L2 才需要，上线后由 `librarian` 提进 `repos/team-wiki` |
| `qa-report.md` | `qa` | 用例与结果、缺陷分类（门 4） |
| `review.md` | `reviewer` | Blocker / Major / Minor 分级评审（门 5） |
| `release-checklist.md` | `implementer` | 发布/回滚检查单（SRE 补位），QA 验收全绿后置 `status: final` |
| `story-draft.md` | `pm` | 建单前的 Story 草稿 |
| `to-questionnaire-*.md` | `ba` | 阻塞点在外部业务方时生成的问卷 |
| `wiki-pr-description.md` | `librarian` | 无远端时的 Draft PR 描述（Phase 1） |

`spec.md` frontmatter 必填：`jira_key`、`level (L1|L2)`、`repos: [...]`、`status: draft|approved`、`confirmed_by`、`wiki_ref`、`home_version`。

## 通过 Jira MCP 读写（本环境实际启用的 14 个工具）

MCP 由 `opencode.json` 的 `mcp.atlassian` 启动，命令行为 `uvx mcp-atlassian --jira-projects-filter <JIRA_PROJECT_KEY> --enabled-tools <下列 14 个>`。

| 用途 | 工具 |
|---|---|
| 读单条 / 搜索 / 列项目需求 | `atlassian_jira_get_issue`、`atlassian_jira_search`、`atlassian_jira_get_project_issues` |
| 元数据（建单前必查） | `atlassian_jira_get_all_projects`、`atlassian_jira_get_project_issue_types`、`atlassian_jira_get_create_fields`、`atlassian_jira_get_transitions` |
| 建单 / 改字段 / 评论 / 流转 / 关联 | `atlassian_jira_create_issue`、`atlassian_jira_update_issue`、`atlassian_jira_add_comment`、`atlassian_jira_edit_comment`、`atlassian_jira_transition_issue`、`atlassian_jira_create_issue_link`、`atlassian_jira_link_to_epic` |

**权限基线**：读 `allow`，写 `ask`。任何写操作（建单、改字段、发评论、流转、建 Bug、关联）必须先把完整内容展示给真人，明确同意后才执行。例外（已按 §5.3 有意放开，仍走 `ask` 人工确认）：`architect` 需要建 Subtask 与 `Blocks` 链接，`implementer` 需要推进 Subtask 状态并附 commit SHA 评论；两者的其余写工具仍为 `deny`。`reviewer` / `librarian` / `ba` 维持写工具 `deny`。

## 格式防呆

发往 Jira 的描述与评论里，`` `AC-1` ``..`` `AC-N` `` 与路径参数 `` `{id}` `` 必须用反引号包裹成行内代码。裸写会被 Jira 的 Markdown→ADF 当成 Issue Key 渲染成链接，原文失真（实测）。

## spec 推送的两个阶段

`jira-sync push-spec` 分两阶段，**不要混**：

- **阶段 A（`status: draft`）**：`AC-1..N` 齐全即可，经人确认后发「待 Business User 确认请求评论」。此时不许改字段、不许流转。
- **阶段 B（`status: approved` + `confirmed_by` 已填）**：收到 Business User 确认后，经人确认再同步正式定稿，并把**父 Story 流转为 `In Progress`**。

## 父 Story 与 Subtask 的两套状态链

| 对象 | 状态链 | 谁推进 |
|---|---|---|
| 父 Story | `To Do` → `In Progress`（spec 定稿）→ `In Review`（验收全绿）→ `Done`（评审通过/上线） | `ba` → `qa` → 真人 |
| Subtask | `To Do` → `In Progress`（开工）→ `Done`（该仓代码+单测完成，附 commit SHA 评论） | `implementer` |

- 拆单：`architect` 在产品定稿后用 `/to-tickets` 建 Subtask（`issue_type: Subtask`，`additional_fields: '{"parent": "<JIRA-KEY>", "labels": ["ready-for-agent"]}'`），用 `Blocks` 串先后阻塞边，Key 回填 `plan.md`。
- 领单：`implementer` 按 Blocks 拓扑（Frontier）逐个领，未完成前置阻塞的 Subtask 不领。
- 每次流转前先 `atlassian_jira_get_transitions` 读可用 transition 名，按名匹配；失败就报当前状态与可用列表，不要猜 id。

## 技能里说「fetch 相关 ticket」

走 `jira-sync pull <JIRA-KEY>`：用 `atlassian_jira_get_issue` 读描述与最新确认评论，落到 `.scratch/<JIRA-KEY>/spec.md`。**本地有未推送修改时先报冲突，不静默覆盖。**

## 分拣状态

用 Jira 状态 + 标签表达五态，映射见 `triage-labels.md`。
