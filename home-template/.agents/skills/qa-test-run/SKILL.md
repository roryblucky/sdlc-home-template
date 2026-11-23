---
name: qa-test-run
description: Write acceptance tests from an approved spec.md into the paths AGENTS.md defines, run the project test commands, and produce .scratch/<JIRA-KEY>/qa-report.md with failures classified as test/environment vs product bug. Use when QA says write acceptance tests, run the suite, or produce a test report.
---

# qa-test-run

QA 只依据 `spec.md` 与公开接口契约写验收测试，**不读业务实现内部**。

项目参数一律从 `AGENTS.md` 读：验收测试目录、单测/验收/端到端测试命令、构建顺序。工具名以 `atlassian_jira_*` 为准。

## 1. 前置

1. `.scratch/<JIRA-KEY>/spec.md` 存在且 `status: approved`。不是就先用 `jira-sync` 拉，或停下要求 `ba` 补 `status`。
2. 读 `AGENTS.md` 的接口契约与测试命令；**不读业务实现源码**（需要定位失败根因时才只读，且不改）。

## 2. 用例落点

按 `AGENTS.md` 第 4 节「单测 vs 验收测试边界」写的目录放，不要自创目录。通用判据：

| 层 | 落点 |
|---|---|
| 各 `service` / `shared-lib` | 该项目验收测试目录（通常在各仓 `**/acceptance/**`） |
| `ui` | 该仓 `tests/acceptance/**` |
| 跨层 | `e2e` 仓的验收目录 |

命令用 `AGENTS.md` 第 3 节给的**免 `cd` 形式**（从 Root Folder 直接跑）。

## 3. 写测试

- 一条 `AC-N` 对一组断言，测试名或注释里必须出现 `AC-N`；没对应 `AC` 的用例不要写。
- 断言用契约里的字面值（路径、字段名、错误码、金额/数值字符串），**不要**从实现里抄期望值（同义反复测试）。
- 只用该项目测试框架与仓库已有的测试依赖，**不要为新测试引入新框架/新依赖**。
- `AC` 模糊到无法断言 → 呼叫 `ba` 核对（最多 1 轮）；仍模糊就在 `qa-report.md` 写 `status: blocked` 并停止，不要猜。

## 4. 跑测

按 `AGENTS.md` 的构建顺序，先保证共享库已构建/安装，再跑受影响层 + 端到端。只跑受影响的层即可，不必每次全量。

## 5. 产出 `.scratch/<JIRA-KEY>/qa-report.md`

```markdown
---
jira_key: <KEY>
status: passed | failed | blocked
ran_at: <date>
home_version: <VERSION>
---

## 用例与结果
| AC | 用例 | 位置 | 结果 |
|---|---|---|---|
| AC-1 | ... | <repo>/... | PASS |

## 失败分类
| 用例 | 分类（测试脚本/环境 vs 产品缺陷） | 依据 |
|---|---|---|

## 缺陷（待 QA 确认后建单）
| 编号 | 标题 | 复现步骤 | 期望/实际 | 关联 Story |
|---|---|---|---|---|
```

分类要有依据（日志、HTTP 状态、字段值），不要写"疑似"。

## 6. 验收全绿后的收口（必须做）

全部 `AC` 通过后，按顺序做两件事，再做下一步：

1. 若 `.scratch/<JIRA-KEY>/release-checklist.md` 仍为 `status: draft`，将其改为 `status: final`（你已拿到全链路全绿证据，且有 `edit` 权限），并在文件里注明同步了哪些验收测试、各层测试数字。
2. `atlassian_jira_transition_issue` 将父 Story 流转为 `In Review`：先 `atlassian_jira_get_transitions` 读可用 transition 名，按名匹配；流转失败就如实报告当前状态与可用列表。
   - 流转前后都要在父 Story 发一条首行 `**agent:qa | home@<version>** 验收测试通过报告` 的评论（各层测试数字 + `release-checklist` 已置 `final` + Subtask 全 `Done`）。

有失败时**不要**做上面任何一步：先回到第 5 节分类，产品缺陷走第 7 节。

## 7. 报 Bug（必须人工确认）

1. 先用 `atlassian_jira_get_project_issue_types` 检查该项目是否开启了 `Bug` 类型；若有则用 `issue_type: "Bug"`，若该项目未配置 `Bug` 类型则自動回退为 `issue_type: "Task"` + `labels: ["bug"]` + 标题前缀 `[Bug]`。草稿展示给 QA，明确确认后才调用 `atlassian_jira_create_issue`，**描述首行署名 `**agent:qa | home@<version>**`**。
2. 用 `atlassian_jira_create_issue_link` 关联原 Story；链接类型按 `atlassian_jira_get_issue` 返回里可用的选。
3. 建单后把 Key 回填 `qa-report.md`。失败原因属于环境/脚本的，不建 Bug，写进「失败分类」即可。
