---
name: jira-sync
description: Pull a Jira story into home/.scratch/<JIRA-KEY>/spec.md, or push a spec to Jira in two stages (draft asks for Business User confirmation, approved posts the final version). Use when the user says pull <KEY>, push the spec, sync with Jira, or when a role needs the confirmed story text.
---

# jira-sync

把 Jira 卡片与本地 `.scratch/<JIRA-KEY>/spec.md` 对齐。Jira 是跨人共享的唯一中转站；本地文件只是缓存（`.scratch/` 已 gitignored）。

**所有项目特定参数从 `AGENTS.md` 读取，不要在本文件里写死**：Jira 项目 Key、子仓清单、`repos/team-wiki/` 是否就绪。

## Story / Spec / Ticket 三层映射（先对齐概念再动手）

| Jira 对象 | 含义 | 谁写 | 本地产物 |
|---|---|---|---|
| 父 `Story` | **业务需求 + 权威 `spec.md` 的载体**（完整 `AC-1..N` 回写在描述里） | `pm` 建单，`ba` 定稿回写 | `.scratch/<KEY>/spec.md`、`story-draft.md` |
| 父 `Story` 评论 | 阶段 A 请求确认 / 阶段 B 定稿 / 验收报告 / 结单摘要 | `ba`、`qa`、主会话 | 同上 |
| 子 `Subtask` | **`/to-tickets` 拆出的 `Ticket` 开发执行单元**（带 `Blocks` 阻塞边） | `architect` 建，`implementer` 领取 | `.scratch/<KEY>/plan.md` §Subtasks |

- 父 Story 走 `To Do → In Progress → In Review → Done`；每个 Subtask 只走 `To Do → In Progress → Done`。
- 拆单、领单、验收不得跳层：`implementer` 不动父 Story 的验收门，`qa` 不直接关 Subtask（已 `Done` 的才不再动）。

## 角色署名铁律（所有写操作都要）

所有角色共用同一个人 Jira Token，**光看作者分不出是哪个 Agent 说的**。因此：

- `atlassian_jira_add_comment`、`atlassian_jira_edit_comment` 以及在描述尾部追加内容时，**首行必须**是：
  `**agent:<role> | home@<version>** <动作摘要>`
  例：`**agent:ba | home@0.1.0** 阶段 A：待 Business User 确认请求`、`**agent:architect | home@0.1.0** 跨仓方案与 Subtask 拆解清单`、`**agent:implementer | home@0.1.0** Subtask 完成`、`**agent:qa | home@0.1.0** 验收测试通过报告`。
- 沙盒里模拟真人回复时，改用 `**human:business-user**`（不写版本号）。
- 改写旧评论（`edit_comment`）时，只补首行署名，**不改原文其余内容**；旧评论归属哪个角色以内容为准（谁写的那段就署谁）。
- `<version>` 取 `home/VERSION`（没有就读 `AGENTS.md` 的底座版本），不要凭记忆填。
- 署名与后面的摘要同一行；不要把署名放到正文末尾。
- **平台实测（必读）**：方括号 + 竖线的写法 `[agent:<role> | home@<version>]` 会被 mcp-atlassian 的 Markdown→ADF 当成 Jira wiki 链接（`[text|url]`）吃掉竖线、改写成破损链接 `[agent:ba ]( home@0.1.0)`；`\|`、`&#124;`、行内代码包裹三种转义**均无效**，全角竖线还会被剥掉方括号。
  所以实际写进 Jira 的署名用**不带方括号**的形式（已逐字验证无损）：
  `**agent:<role> | home@<version>** <动作摘要>`（例：`**agent:ba | home@0.1.0** 阶段 A：待 Business User 确认请求`）
- 改写旧评论（`edit_comment`）是 **Markdown→ADF→Markdown 有损往返**：空行会被补插、`**粗体**` 可能变 `__粗体__`。只补首行时可以接受，但**不要**指望改写后正文逐字不变；涉及代码块/表格的评论尽量不要重写。

工具名以 `atlassian_jira_*` 为准（本环境只启用核心 14 个，清单见 `docs/agents/issue-tracker.md`）。凭据来自环境变量，**任何情况下不要把 URL、用户名、Token 写进文件、命令回显或提交记录**。

## 格式防呆（发往 Jira 前逐条过）

- 描述与评论里的 `AC-1`..`AC-N` 必须写成行内代码 `` `AC-1` ``：裸写会被 Jira 的 Markdown→ADF 当成 Issue Key 渲染成链接，原文失真。
- 路径参数 `{id}` 同样用反引号包裹，否则被当成模板占位符吃掉。
- 结论：先把正文拼成字符串，检查这两类 token 都有反引号，再调用写工具。

## pull &lt;JIRA-KEY&gt;

1. `atlassian_jira_get_issue` 取卡片：summary、description、labels、状态，以及**最新一条由 Business User 确认的评论**。
2. 若本地 `.scratch/<JIRA-KEY>/spec.md` 不存在 → 用下面的骨架新建，`status: draft`。
3. 若已存在，比对内容：
   - 一致 → 什么都不做，报告 "already in sync"。
   - 本地有未推送修改，或 Jira 侧有新确认评论 → **报冲突并列出差异**，标出建议保留哪一份，**等用户拍板**。禁止静默覆盖任何一侧。
4. `AC-N` 从 Jira 描述/确认评论提取；Jira 上没有可断言的验收标准时，不要编，直接告诉用户。

## push-spec &lt;JIRA-KEY&gt; — 两阶段，禁止死锁

先做**本地校验**（A、B 两阶段共用），任一项不过就停：

- frontmatter 必填齐全：`jira_key`、`level (L1|L2)`、`repos: [...]`、`status`、`confirmed_by`、`wiki_ref`、`home_version`。
- `## 2. 验收标准` 至少有 `AC-1`，且每条是可写成确定性测试的断言。
- `repos` 里的仓名必须都出现在 `AGENTS.md` 第 1 节的子仓清单里。

### 阶段 A：`status: draft` → 请求确认

1. 抽出「业务确认摘要」（`## 1.` 全文）+ `AC-1..N` 清单。
2. **把要发的内容原文展示给用户，等明确确认**；没确认就停在这里，不要调用任何写工具。
3. 确认后 `atlassian_jira_add_comment` 发一条「待 Business User 确认请求评论」：摘要 + AC 清单 + 请回复"确认"或指出差异。整段 spec 过长时只发摘要与 AC，注明全文在本地 `.scratch/<JIRA-KEY>/spec.md`。
   - 首行必须是 `**agent:ba | home@<version>** 阶段 A：待 Business User 确认请求`。
4. **阶段 A 到此结束**。`status` 保持 `draft`；不要改卡片字段、不要流转状态、不要把 draft 当定稿同步。

### 阶段 B：`status: approved` → 正式定稿

前置条件（缺一不可，否则回到阶段 A）：

- 用户明确转述了 Business User 在 Jira 的确认结论；
- 本地 `status` 已改为 `approved`，且 `confirmed_by` 填了确认人。

然后：

1. 展示「本次将同步的定稿内容」给用户，等确认。
2. `atlassian_jira_add_comment` 发正式定稿评论（AC 定稿 + `confirmed_by` + 级别），首行 `**agent:ba | home@<version>** 阶段 B：Spec 已定稿并流转 In Progress`。
3. 需要改卡片描述本身时用 `atlassian_jira_update_issue`，同样先展示再执行；把完整 `spec.md`（业务摘要 + 全部 `AC-1..N` + 待沉淀术语）回写进父 Story 描述，让父 Story 成为权威 Spec 载体，描述末尾带同一署名行。
4. `atlassian_jira_transition_issue` 将父 Story 流转为 `In Progress`（这是阶段 B 的收尾动作，必须做；先 `atlassian_jira_get_transitions` 取该卡片可用的 transition id，不要猜 id）。
5. 除上一步外不要自行流转状态；其他任何流转都必须用户明确点名目标状态。

**死锁自检**：如果你卡在"要先 approved 才能 push，但 approved 又要先 push 才能拿到确认"——说明走错了，回到阶段 A 发请求确认评论即可。

## spec.md 骨架

```markdown
---
jira_key: <KEY>
level: L1
repos: [<repo-a>, <repo-b>]
status: draft
confirmed_by:
wiki_ref: none
home_version: <VERSION>
---

## 1. 业务确认摘要
（通俗语言：范围、规则、非目标、样例）

## 2. 验收标准
- AC-1: ...
- AC-2: ...

## 3. 待沉淀术语/规则
- ...
```

`wiki_ref`：`repos/team-wiki/` 未就绪时写 `none`；就绪后写页面路径或 `none`。

## 父 Story / Subtask 状态流转规约（全链路唯一口径）

| 时点 | 动作 | 责任角色 |
|---|---|---|
| 建父 Story | 父 Story 落 `To Do`，打 `level-L*` + `ready-for-agent` | pm |
| spec 定稿 | 父 Story → `In Progress` | ba（经 `push-spec` 阶段 B） |
| 方案定稿 | 按 Frontier 建 Subtask（`issue_type: Subtask`，`parent` 指向父 Story），用 `Blocks` 串先后边，Key 回填 `plan.md` | architect |
| 每个 Subtask 开工 | 该 Subtask → `In Progress` | implementer |
| 每个 Subtask 完成 | 该 Subtask → `Done`，并附 commit SHA 评论 | implementer |
| 验收全绿 | 父 Story → `In Review`；`release-checklist.md` → `status: final` | qa |
| 评审通过 | 父 Story → `Done` | 真人（主会话） |

- **两套状态链不要混用**：Subtask 只走 `To Do → In Progress → Done`；父 Story 走 `To Do → In Progress → In Review → Done`。
- 每次流转前先 `atlassian_jira_get_transitions` 读可用 transition 名，按名字匹配，拿不到就停下问用户，**绝不按 id 猜**。
- 流转失败（名称不存在 / 工作流不允许跳转）→ 如实报告当前状态与可用 transition 列表，不要改用其他字段绕过。
