# 团队 AI-SDLC Agent Factory 架构与实施规范

> 版本：**v4.2（定稿 — Root Folder 架构 + 通用引擎与项目配置解耦，已按 OpenCode v1.19.3 实测校准）**
> 定位：面向实施工程师与 Coding Agent 的唯一技术基线。
> 核心范式：**`home/` Root Folder 总控台（内嵌 `repos/*` 子仓）+ 零项目耦合的 7 角色通用引擎 + `/project-setup` 引导式配置生成 + `mattpocock/skills` & 私有 Skills + Jira MCP 共享状态 + `team-wiki` 长期记忆**。

---

## 1. 系统边界与硬性约束

- **团队结构**：专职 **PM**、**QA**、**Dev**；**无专职 BA**（Dev 接单后用 `ba` + `grill-with-docs` 产出规格，交 **Business User** 确认）；**无专职 SRE**（由 Dev 提 PR 前通过 `release-checklist` 补位）。
- **多仓业务现实（`home/` Root Folder 定位）**：单个业务需求通常同时改动 **UI 仓 + 多个微服务 API 仓 + 共享公共库仓**。所有人统一在根目录 **`home/`** 启动 OpenCode，所有独立业务 Git 仓挂载于 **`home/repos/<repo>/`** 下（由 `home/.gitignore` 忽略 Git 追踪，由 `home/.ignore` 开放 `glob`/`grep` 检索），无需配置跨出工作区的 `external_directory`。
- **通用底座（Engine）与项目声明（Profile）严格解耦**：
  - **100% 通用层（换 Python / Java / Node / Go 项目零修改）**：`.opencode/agents/*.md`（7 个角色定义）、`.agents/skills/**`（9 个 vendored skills + 6 个私有 skills）、`skills-lock.json`、`scripts/home-doctor`。**严禁在任何 Agent 或 Skill 文件中硬编码具体项目仓名、构建工具（如 `mvn`/`pytest`）或 Jira 项目 Key**。
  - **项目特定层（仅 3 处，由 `/project-setup` 扫描并反问用户后自动生成）**：`AGENTS.md`（子仓拓扑、共享库依赖、构建/发布顺序、测试命令）、`opencode.json`（模型、Jira MCP 项目过滤、本项目测试命令放行白名单）、`docs/agents/*.md`（领域术语与 Jira 状态/标签映射）。
- **运行形态（人工在环，不做 CI 自动跑 AI）**：
  - 每个岗位的同事在本地 OpenCode 与同岗位 Agent 协作：AI 负责查重、追问、设计、编码、跑测、评审；人类负责 **Review（审结果）与 Control（拍板、确认 Jira 写入、点 PR 合并）**。
  - **防上下文腐烂铁律**：同阶段讨论可共享会话；**跨大阶段必须 `/new` 开启新会话**，只读取上一阶段落盘的定稿文件或 Jira 内容接力，禁止一个聊天窗从需求一路聊到写完代码。
- **技术底座约束**：
  - Harness：**OpenCode v1.19.x**（严格使用 V1 语法，见 §5.1）。**禁止**开发 OpenCode V1 Plugin（OpenCode v2 已废弃 v1 plugin）。
  - 模型：**模型无关，不使用 Claude 系列模型**；所有 agent 配置**禁止**硬编码 `model`、`temperature`、`top_p`，统一继承 `opencode.json`。
  - 平台：**GitHub Enterprise (GHE)**（或公网沙盒 `github.com`）+ **Jira MCP**。
  - 技能基线：**`mattpocock/skills`（9 个核心技能，由 `skills-lock.json` 唯一锁定）+ 6 个通用私有 Skills**。

---

## 2. 工作区拓扑与三类资产归属

`home/` 是唯一的工作区根目录（Root Folder），所有业务代码仓与 `team-wiki` 作为独立 Git 仓挂载在 `home/repos/` 下：

```text
home/                               # 【资产一：通用 SDLC 底座 & 总控根仓库】独立 Git 仓
├── VERSION                         # 底座版本（如 0.1.0）
├── .gitignore                      # 必须忽略 .scratch/、repos/ 与 .qmd/（子仓代码、本地缓存与 qmd 索引库永不混入 home Git）
├── .ignore                         # 必须包含 !.scratch/ 和 !repos/（让 OpenCode glob/grep 穿透检索子仓源码与 .scratch）
├── skills-lock.json                # 唯一技能锁文件（npx skills 原生生成，含 commit SHA 与 computedHash）
├── scripts/
│   └── home-doctor                 # 真校验脚本：验 skills-lock.json hash、验 Agent 零项目耦合与权限、验 repos/* 与 home/.qmd 就绪
├── .opencode/
│   └── agents/                     # 7 个 100% 通用角色定义（严禁出现具体仓名/语言/Jira Key，见 §5.3）
│       ├── pm.md
│       ├── ba.md
│       ├── architect.md
│       ├── implementer.md
│       ├── qa.md
│       ├── reviewer.md
│       └── librarian.md
├── .agents/
│   └── skills/                     # 27 个 vendored skills + 6 个通用私有 skills（含 project-setup）
├── AGENTS.md                       # 【项目配置：由 /project-setup 生成】当前项目 repos/* 拓扑、依赖顺序、测试命令
├── opencode.json                   # 【项目配置：由 /project-setup 生成】模型、Jira MCP、本项目测试命令 bash allow
├── docs/
│   └── agents/                     # 【项目配置：由 /project-setup 生成】
│       ├── domain.md               # 领域文档消费规范（指向 repos/team-wiki/ 或 AGENTS.md）
│       ├── issue-tracker.md        # Jira MCP + .scratch/<JIRA-KEY>/ 同步契约（含 **agent:<role> | home@<ver>** 署名规范）
│       └── triage-labels.md        # Jira 标签/状态映射表
├── .qmd/                           # 【本地 qmd 索引库，gitignored】必须在 home/ 根目录 qmd init，索引 repos/team-wiki 知识页（排除 index.md / log.md / README.md）
├── .scratch/                       # 【本地工作缓存，gitignored】按 Jira Key 建目录
│   └── <JIRA-KEY>/                 # 如 PROJ-1234/ 或 SCRUM-1/
│       ├── spec.md                 # 门 1 产物（通过 Jira MCP 同步到父 Jira Story 给 Business User & QA 共享）
│       ├── plan.md                 # 门 2 跨仓方案（含影响的服务清单、Seam 决策与 Subtask 拆分列表）
│       ├── adr-draft.md            # 门 2 ADR 草稿（若为 L2，上线后由 librarian 提进 repos/team-wiki）
│       ├── qa-report.md            # 门 4 测试报告
│       ├── review.md               # 门 5 跨仓评审报告
│       └── wiki-pr-description.md  # 门 6 沉淀 PR 描述草稿（无远端 GHE 时的本地 PR 归档）
└── repos/                          # 【挂载区：gitignored by home】每个子目录均为独立 Git 仓
    ├── team-wiki/                  # 【资产二：LLM Wiki 长期常识】（Phase 1 启用）独立 Git 仓
    │   ├── index.md                # 自动生成导航目录，禁止手改（由 qmd ignore 排除，避免稀释 BM25 IDF）
    │   ├── log.md                  # 变更审计流水（由 qmd ignore 排除，避免高频词把 BM25 IDF 压成 0%）
    │   ├── GLOSSARY.md             # 跨系统统一业务术语表
    │   ├── adr/                    # 跨服务架构决策（NNNN-<slug>.md）
    │   ├── domains/                # 领域概念与不变量知识页
    │   ├── runbooks/               # 发布/排障/联调手册
    │   └── scripts/wiki-check      # 校验脚本：frontmatter / 断链 / 孤儿页 / 重建 index.md
    ├── <shared-lib-repo>/          # 【资产三：业务与测试子仓们】如公共 Jar / Python SDK / 共享包
    ├── <system-api-repo>/          # 底层 System API 仓
    ├── <processing-api-repo>/      # 中层 Processing API 仓
    ├── <experience-api-repo>/      # 顶层 Experience API 仓
    ├── <ui-repo>/                  # 前端 UI 仓
    └── <e2e-repo>/                 # （可选）跨服务验收/E2E 测试仓；或位于各业务仓验收测试目录
```

### 三类资产的共享流转机制与 Story / Spec / Ticket 映射

| 资产类型 | 权威存储位置 | 本地路径 | 跨人共享方式 |
|---|---|---|---|
| **通用底座与跨仓地图** | `home/`（Git） | `home/`（Root Folder） | 全员拉取同一 tag/version，新项目跑 `/project-setup` 生成拓扑，用 `scripts/home-doctor` 校验 |
| **单次需求过程工件**（`spec.md`、`plan.md`） | **Jira（唯一跨人中转站）** | `home/.scratch/<JIRA-KEY>/`（gitignored） | Dev 通过 **Jira MCP** 推送 `spec.md` 与业务摘要到**父 Jira `Story`** → Business User 在 Jira 确认 → QA/其他 Dev 通过 Jira MCP 一键拉取到自己本地 `.scratch/<JIRA-KEY>/` |
| **长期公共常识**（术语、跨服务 ADR、runbook） | **`team-wiki`（Git）** | `home/repos/team-wiki/` | `librarian` 提 Draft PR 人工合并；**在 `home/` 根目录初始化 `home/.qmd/`**（BM25，通过 `ignore: ["index.md", "log.md", "README.md"]` 过滤导航与流水噪音）供所有角色在 `home/` 下毫秒级检索 |

> **Jira `Story` vs `Spec` vs `Ticket (Subtask)` 核心映射（对齐 `mattpocock/skills` 的 `/to-spec` → `/to-tickets` → `/implement`）**：
> 1. **父 Jira `Story` = 业务需求 & 完整 `Spec` 的载体**：
>    - 起步由 `pm`（`/jira-story-draft`）创建为业务视角的用户故事（Initial Story）；
>    - 经 `ba`（`/grill-with-docs` + `/to-spec`）与 Business User 拍板后，**完整业务规格与 `AC-1..N`（`spec.md`）直接回写并定稿在父 Jira `Story` 描述中**；随后 `architect` 用 `/to-spec` 增补跨仓 Implementation & Testing Seams（`plan.md`）。因此在 Jira 上，**父 `Story` 就是这单的权威 `Spec` 容器**。
> 2. **子 Jira `Subtask` = `/to-tickets` 拆出的开发执行单元（`Ticket`）**：
>    - `architect` 运行 `/to-tickets` 将 `plan.md` 拆成挂在父 Story 下的多个 Jira `Subtask`（带 `ready-for-agent` 标签与 `Blocks` 阻塞边）；
>    - **切片原则**：常规功能默认按 **垂直 Tracer-bullet（端到端薄切片）** 拆 Subtask；当且仅当涉及跨微服务共享公共库（`shared-lib`）契约变更时，按 `/to-tickets` 规范允许的 **Expand–Contract / 自底向上依赖链** 拆 Subtask；
>    - `implementer` 运行 `/implement` + `/tdd` 时，**按 Subtask（Ticket）逐个从 Frontier 领取、流转状态（`To Do` → `In Progress` → `Done`）并提交代码**；全部 Subtask 完成后，再由 `qa` 对照父 `Story` 上的 `spec.md` 做整单验收并将父 Story 流转为 `In Review`。
> 3. **Jira 角色署名铁律（解决共用个人 Token 无法区分哪个 Agent 发言的问题）**：
>    - 由于本地 OpenCode 各角色共用开发者的 `JIRA_API_TOKEN`，**所有角色在写入 Jira 评论（`atlassian_jira_add_comment` / `edit_comment`）或追加 Jira 描述备注时，第一行必须带上统一角色签名头**：
>      `**agent:<role> | home@<version>** <动作摘要>`（例如 `**agent:pm | home@0.1.0** 初始建单`、`**agent:ba | home@0.1.0** 阶段 A：待 Business User 确认请求`、`**agent:architect | home@0.1.0** 跨仓方案与 Subtask 拆解清单`、`**agent:implementer | home@0.1.0** Subtask 完成`、`**agent:qa | home@0.1.0** 验收测试报告`）；若在沙盒中模拟真人回复，则显式标 `**human:business-user**`。

---

## 3. SDLC 工作流、角色协作与跨角色呼叫设计

### 3.1 七大角色协作矩阵（1 岗位 = 1 角色，不拆写手/顾问）

| 阶段 | 真人角色 | Agent | `mode` | 唤起与会话策略 | 职责与产出（含 Jira 状态流转、Subtask 拆解与 `**agent:<role>**` 署名） | 人类 Review & Control |
|---|---|---|---|---|---|---|
| **0. 分拣排期** | **PM** | `pm` | `primary` | `Tab`（新会话） | Jira 查重、查 `team-wiki`、可呼叫 `architect`/`ba`/`qa` 评估跨服务影响面 → 起草父 Story & 建议级别（L0/L1/L2） | PM 拍板优先级，确认后通过 Jira MCP 建父 Story（初始状态 `To Do`） |
| **1. 需求澄清（Story → Spec）** | **Dev**（代行 BA）→ **Business User** | `ba` | `all` | `Tab`（新会话） | 跑 `/grill-with-docs` + `/to-spec` → 写 `.scratch/<KEY>/spec.md` → 阶段 A 发 `**agent:ba**` 待确认评论 → 阶段 B 确认后标 `status: approved` 回写父 Story（使父 Story 成为权威 Spec 载体）并**流转为 `In Progress`** | Dev 回答问题；**Business User 在 Jira 确认后**，Dev 批准 `ba` 回写定稿并流转父 Story 状态 |
| **2. 跨仓方案与拆分子任务（Spec → Tickets）** | **Dev**（Tech Lead） | `architect` | `all` | **`/new` 新会话**后 `Tab` | 读定稿 `spec.md` + 多子仓代码 + `team-wiki/adr/` → 用 `/to-spec` 写跨服务 `plan.md`（及 L2 `adr-draft.md`）→ **运行 `/to-tickets` 将 `plan.md` 拆成带阻塞依赖顺序的 Jira `Subtask`（挂在父 Story 下并用 `Blocks` 链接串起 Frontier，在父 Story 留 `**agent:architect**` 拆分汇总评论）** | Tech Lead 审跨服务方案与 Subtask 拆分粒度/依赖边，确认后批量建 Jira Subtasks |
| **3. 按 Subtask 逐个编码自测** | **Dev** | `implementer` | `primary` | **`/new` 新会话**后 `Tab` | **按 Subtask 依赖拓扑（Frontier）逐个运行 `/implement` + `/tdd`**：将当前 Subtask 流转为 `In Progress` → 改对应仓代码与单测 → 单测通过后留 `**agent:implementer**` 评论并将该 Subtask 流转为 `Done`；全部 Subtask 完成后跑 `/release-checklist` 与 `/pr` | 卡点介入；每完成一个 Subtask 确认流转状态；审发布清单（**物理禁止改验收测试**） |
| **4. 验收测试** | **QA** | `qa` | `all` | **`/new` 或 `@qa`** | 通过 Jira MCP 拉取父 Story 上的已确认 `spec.md` → **只看 `spec.md` 与接口契约**写验收测试 → 自动执行并产出 `qa-report.md` → 验收通过后留 `**agent:qa**` 报告评论并**将父 Story 流转为 `In Review`**（有缺陷则提 Jira `Bug` 并 link 原 Story） | QA 审用例覆盖率、确认提 Bug 或将父 Story 流转为 `In Review` |
| **5. 独立评审** | **Dev**（Reviewer） | `reviewer` | `subagent` | **`@reviewer`（Fresh context）** | 独立审查各受影响业务仓的 `git diff` 对照 `spec.md`/ADR/安全边界，检查测试是否被弱化 → 输出 `review.md` | Reviewer 聚焦高风险项，点 PR Approve 并由主会话留 `**agent:reviewer**` 摘要后将父 Story 流转为 `Done` |
| **6. 知识沉淀** | **Dev / PM / QA** | `librarian` | `subagent` | **`@librarian`（Fresh context）** | 把本次新增的长期术语、跨服务 ADR、排障经验整理成 `repos/team-wiki/` 的新分支与 Draft PR（或无远端时写 `.scratch/<KEY>/wiki-pr-description.md`），并在 `home/` 更新 `qmd` 索引 | 同事 1 分钟审阅合并 wiki PR |

### 3.2 多角色互相呼叫规则（受控 DAG + 防套娃）

保留「角色互相呼叫解决跨岗问题」的核心能力，同时通过 **权限 DAG（有向无环图）+ 会诊规约** 彻底杜绝 OpenCode v1 无限递归套娃与越权改文件：

```text
pm ──────────┬──▶ architect ──┬──▶ qa ──▶ ba（叶子，不调任何人）
implementer ─┘                └──▶ ba
                              ▲
             (严格无环，无双向回边；所有被呼叫的 subagent 禁止继续往下调用)
```

- **合法呼叫矩阵（`permission.task`）**：
  - `pm` → 可呼叫 `architect`（评跨服务改造成本）、`ba`（查术语/口径冲突）、`qa`（评测试影响面）。
  - `implementer` → 可呼叫 `architect`（遇实现阻碍核对方案）、`ba`（核对极端边界业务规则）、`qa`（核对验收口径）。
  - `architect` → 可呼叫 `ba`（反查需求缺口）、`qa`（评审方案可测性）。
  - `qa` → 可呼叫 `ba`（核对模糊 AC）；排查代码缺陷时直接只读兄弟业务仓源码，无需回呼 `implementer`。
  - `ba` / `reviewer` / `librarian` → 叶子角色，不调用任何子代理。
- **被呼叫时的两条会诊规约（写入 `ba` / `architect` / `qa` 的 prompt）**：
  1. **只读会诊**：当以 subagent 身份被其他角色呼叫时，**只做分析、引用依据、列出缺口和问题，严禁修改任何文件、严禁调用 Jira 写操作**。
  2. **最多一跳，遇需求缺口即阻塞**：禁止在被呼叫期间再次调用其他角色；若确认根因是 `spec.md` 缺失或冲突，调用方在自身产物写入 `status: blocked` + `missing` + `questions` 并立刻停下，由真人切回 `ba` 修订并找 Business User 确认。
- **演进路径（Phase 0 之后可选）**：Phase 0 先用原生 OpenCode 的 `Tab` + `task` 呼叫跑通全部资产与流程；若团队跑顺后仍强烈需要「多个 Bot 在同一群聊界面公开对话」的体验，可在 **Phase 2+** 直接在外部叠加开源群聊协调层（如 `CCCC`、`CircleChat` 或 `agent-talk`），**100% 复用现有 `home/` 地图、7 个角色配置、Skills、Jira MCP 与 `team-wiki`，零返工**。

### 3.3 改动分级（Quick Path，防流程过重）

| 级别 | 判定条件 | 必经流程 | 允许跳过 |
|---|---|---|---|
| **L0（微小改动）** | 单仓单文件 bugfix、文案、小版本升级，**无业务规则变更** | `implementer` → 常规 GHE PR Review | 跳过 `ba`、`architect`、`qa` 验收、`librarian` |
| **L1（常规功能）** | 单仓或少量跨仓新功能、改业务规则 | `pm` → `ba`（Jira 确认）→ `implementer` ↔ `qa` → `@reviewer` | 无架构权衡时跳过 ADR 与 `librarian` |
| **L2（架构/多微服务/核心规则）** | 多微服务联动、数据模型/接口契约大改、推翻旧 ADR | **全链路**（含 `architect` 跨仓 `plan.md` + `adr-draft.md` + `librarian` 沉淀进 `team-wiki`） | 无 |

---

## 4. Skills 基线（`mattpocock/skills` 27 个主集合 + 6 个通用私有 Skills）

### 4.1 复用 `mattpocock/skills` 主集合全部 27 个 Skills（排除 12 个 General 杂项，由单一 `skills-lock.json` 锁定）

```bash
npx skills add mattpocock/skills -a opencode --copy -y \
  -s ask-matt -s code-review -s codebase-design -s diagnosing-bugs \
  -s domain-modeling -s grill-me -s grill-with-docs -s grilling \
  -s handoff -s implement -s implement-spec -s improve-codebase-architecture \
  -s pr -s prototype -s research -s retro -s setup-matt-pocock-skills \
  -s tdd -s teach -s to-questionnaire -s to-spec -s to-tickets \
  -s triage -s wait-what -s wayfinder -s wizard -s writing-for-agents
```

- **为什么装齐 27 个主集合（排除 12 个 General）**：
  - `mattpocock/skills` 上游共 39 个技能，其中 **Mattpocock Skills 主集合 27 个**、General 杂项 12 个（TS 练习脚手架、写文章等，不安装）。
  - OpenCode 的 `permission.skill` 按角色白名单过滤（被 `deny` 的技能不会注入该角色的 System Prompt，**零额外 Token 开销**），因此将 27 个主集合全部 vendor 进 `home/.agents/skills/` 并按岗位精准放行，既保持工具箱完整，又不膨胀单个角色的上下文。
- **唯一锁文件 `skills-lock.json`**：`npx skills` 原生生成的 `skills-lock.json`（v2）已完整包含 27 个技能的 `source`、`commit`、`skillPath` 与 `computedHash`，**禁止再维护第二份冗余的 `vendor.lock.json`**。
- **确定性加载与校验**：
  - 由 `scripts/home-doctor` 读取 `skills-lock.json`，实时校验 27 个 vendored skills + 6 个私有 skills 的 `SKILL.md` 是否全部存在且非空，并核对 7 个角色的设置。
  - 启动 OpenCode 时建议带环境变量 `OPENCODE_DISABLE_EXTERNAL_SKILLS=1 opencode`，确保只加载 `home/.agents/skills/` 内锁定的 33 个技能。

| 类别 | Skill 名（共 27 个） | 放行给哪些角色（含二级调用依赖） | 用途与二级调用链说明 |
|---|---|---|---|
| **需求澄清、问卷与业务规格** | `grill-with-docs`、`grilling`、`grill-me`、`to-questionnaire`、`to-spec` | `ba`（`grilling`、`to-spec`、`to-questionnaire` 同步放行给 `pm`；`grilling`、`to-spec` 同步放行给 `architect`） | `grill-with-docs` 内部调 `grilling` + `domain-modeling`；`to-questionnaire` 生成外部问卷；`to-spec` 合成业务规格与架构/测试接缝（Seam） |
| **分拣、探路与拆单** | `triage`、`wayfinder`、`to-tickets` | `pm`、`architect`（`triage` 仅 `pm`） | `triage` 与 `wayfinder` 内部均调用 `grilling` + `domain-modeling`（`wayfinder` 还调用 `research` 并在迷雾散去后汇入 `to-spec` → `to-tickets`） |
| **领域与架构设计** | `domain-modeling`、`codebase-design`、`improve-codebase-architecture`、`prototype`、`research` | `architect`（`domain-modeling` 同步给 `pm`/`ba`/`librarian`；`codebase-design` 同步给 `implementer`/`qa`/`reviewer`；`research` 同步给 `pm`/`ba`） | `improve-codebase-architecture` 内部调用 `codebase-design` + `grilling` + `domain-modeling`；`tdd` 依赖 `codebase-design` 的 Seam 词汇 |
| **按单编码、测试与排障** | `implement`、`implement-spec`、`tdd`、`diagnosing-bugs`、`wizard`、`pr` | `implementer`（`tdd`/`diagnosing-bugs` 同步给 `qa`） | `implement` 与 `implement-spec` 按 Frontier 逐个 Subtask 执行，内部调用 `tdd`（依赖 `codebase-design`）并在结尾调用 `code-review` 自检 |
| **代码评审** | `code-review` | `reviewer`、`implementer` | `reviewer` 独立双轴评审（Standards + Spec）；`implementer` 在 `/implement` 收尾时内部调用自检 |
| **文档与沉淀** | `writing-for-agents` | `architect`、`librarian` | 编写面向 Agent 的高密度文档（`AGENTS.md` / Wiki / 规则） |
| **通用会话辅助** | `ask-matt`、`handoff`、`wait-what`、`retro`、`teach` | `pm`、`ba`、`architect`、`implementer`、`qa`（`retro` 同步放行给 `librarian`） | 技能路由咨询、跨会话交接文档、重新对齐意图、会话复盘、概念讲解 |
| **仅落盘备查（不放行）** | `setup-matt-pocock-skills` | 无（由多仓增强版私有 `/project-setup` 替代） | 保留在 27 个主集合锁文件中确保完整性，不放行给角色以免与 `/project-setup` 冲突 |

### 4.2 新建 6 个通用私有 Skills（`home/.agents/skills/<name>/SKILL.md`）

> **硬性规范**：所有私有 Skill **必须 100% 语言无关、项目无关**，严禁硬编码具体仓名（如 `demo-*`）、构建工具（如 `mvn`）或特定 Jira 项目 Key（如 `SCRUM`）；所有项目特定参数一律指示 Agent 从 `AGENTS.md` 的结构化章节读取。

1. **`project-setup`**（供 `architect` 或内置 `build` 角色，新项目接入 / 拓扑变更时运行）：
   - **自动探测**：扫描 `repos/*` 下的所有独立 Git 子仓，自动识别语言与构建栈、现有单测与验收测试目录。
   - **反问确认（5 个必问项，附带自动探测出的默认建议供用户一键确认或修改）**：
     1. **子仓角色与调用/依赖拓扑**：哪些是 `shared-lib`（公共库/Jar/SDK）、哪些是 `service`（及自底向上调用顺序）、哪些是 `ui`、哪些是 `e2e`？
     2. **自底向上构建与发布顺序**：公共库如何安装/发布供下游引用？各仓免 `cd` 的构建命令与反向回滚顺序是什么？
     3. **单测 vs 验收测试边界**：各仓的单测命令、验收测试目录路径与验收执行命令是什么？（确认 `implementer` 物理禁改的验收路径）
     4. **Issue Tracker 映射**：Jira Project Key 是什么？5 个规范分拣角色映射哪些状态/标签？
     5. **模型与测试命令放行**：主模型与轻量模型 ID 是什么？是否将上述只读测试命令以通配形式写入 `opencode.json` 的 `permission.bash` 自动放行？
   - **生成与自检**：根据用户确认结果生成/更新 `AGENTS.md`、`opencode.json`（含 `"skills": { "paths": [".agents/skills"] }`）、`docs/agents/{domain,issue-tracker,triage-labels}.md`，最后执行 `scripts/home-doctor` 验证闭环。
2. **`jira-sync`**（供 `pm`/`ba`/`architect`/`implementer`/`qa`）：
   - 从 `AGENTS.md` 读取当前项目的 `JIRA_PROJECT_KEY`，从 `VERSION` 读取底座版本号 `<version>`。
   - **角色署名铁律**：由于所有角色共用同一个 Jira Token，**每一次**调用 `atlassian_jira_add_comment`、`atlassian_jira_edit_comment` 或在 Jira 描述尾部追加更新时，首行**必须**写明当前执行角色签名头：`**agent:<role> | home@<version>** <动作摘要>`（沙盒内若模拟业务方确认则标 `**human:business-user**`）。
   - **格式防呆（实测校准）**：
     1. 发往 Jira 描述或评论中的 `` `AC-1` ``..`` `AC-N` ``、路径参数 `` `{id}` ``、以及含下划线的标识符（如 `` `ORDER_NOT_DISCOUNTABLE` ``）**必须用反引号包裹为行内代码**，防止 Jira Markdown→ADF 将 `AC-1` 误解析为 Issue 链接或将 `_NOT_` 吃掉变成斜体 `*NOT*`。
     2. 角色署名头统一使用不带方括号的 `**agent:<role> | home@<version>**`（**禁止写成 `[agent:... | ...]`**，否则 `mcp-atlassian` 的 Markdown→ADF 转换器会把 `[text|url]` 当作 Jira Wiki 链接吃掉竖线）。
   - `pull <JIRA-KEY>`：通过 Jira MCP 读取父 Story 描述（权威 `Spec` 载体）与最新确认评论，落地到 `.scratch/<JIRA-KEY>/spec.md`（若本地有未推送修改则报冲突，不静默覆盖）。
   - `push-spec <JIRA-KEY>`（**分两阶段，带状态流转与角色署名**）：
     - **阶段 A（`status: draft` 请求确认）**：校验 frontmatter 与 `AC-1..N` 齐全后，将「业务确认摘要 + AC 清单」展示给真人确认，调用 `atlassian_jira_add_comment` 发送首行为 `**agent:ba | home@<version>** 阶段 A：待 Business User 确认请求` 的确认评论。
     - **阶段 B（`status: approved` 正式定稿 + 流转 `In Progress`）**：收到 Business User 在 Jira 的确认回复后，本地更新 `status: approved` 与 `confirmed_by`，经真人确认后调用 `atlassian_jira_update_issue`（将父 Story 更新为完整 `Spec` 载体）与 `atlassian_jira_add_comment`（首行 `**agent:ba | home@<version>** 阶段 B：Spec 已定稿并流转 In Progress`），并调用 `atlassian_jira_transition_issue` 将父 Story 流转为 `In Progress`。
3. **`jira-story-draft`**（供 `pm`）：从 `AGENTS.md` 读取子仓拓扑与 `JIRA_PROJECT_KEY` + 查 `repos/team-wiki`（若存在）+ 调 Jira MCP 查重 → 输出含受影响子仓清单、L0/L1/L2 建议、Story 拆分草稿（写入 `.scratch/<KEY>/story-draft.md`）；经 PM 确认后建父 Story（初始状态 `To Do`，描述末尾或首条评论署名 `**agent:pm | home@<version>**`）。
4. **`qa-test-run`**（供 `qa`）：只读 `.scratch/<JIRA-KEY>/spec.md` 与 `AGENTS.md` 中的公开接口契约生成验收测试（标注 `AC-N`，写入 `AGENTS.md` 规定的验收测试目录）→ 按 `AGENTS.md` 的测试命令执行 → 输出 `.scratch/<JIRA-KEY>/qa-report.md`（区分测试脚本/环境问题 vs 产品缺陷）→ 若全部通过，经 QA 确认后在父 Story 发表 `**agent:qa | home@<version>** 验收测试通过报告` 评论并调用 `atlassian_jira_transition_issue` 将父 Story 流转为 `In Review`；若有产品缺陷则经确认后提 Jira `Bug`（署名 `**agent:qa | home@<version>**`）并关联原 Story。
5. **`release-checklist`**（供 `architect`/`implementer`/`reviewer`，补位无 SRE）：读取 `AGENTS.md` 的拓扑与发布顺序，扫描所有受影响 `repos/*` 的 `git diff`，检查：① `shared-lib` 公共库版本号、API/二进制兼容性及所有下游依赖声明文件版本对齐；② 自底向上的发布顺序、滚动窗口兼容性与反向回滚顺序；③ DB migration / 新增环境变量 / 端口与配置；④ 健康检查与冒烟命令，输出 `.scratch/<JIRA-KEY>/release-checklist.md`（QA 验收通过后须更新为 `status: final`）。
6. **`wiki-ingest`**（供 `librarian`）：把已上线需求的长期术语、`adr-draft.md` 或排障手册写入 `repos/team-wiki/` 的**新分支** → 跑 `repos/team-wiki/scripts/wiki-check --fix-index` → 在 `home/` 根目录跑 `qmd update` 刷新索引 → 用 `gh pr create --draft` 提 Draft PR（若本地沙盒无远端 GitHub remote，则将 PR 描述落盘到 `.scratch/<JIRA-KEY>/wiki-pr-description.md` 供审阅合入）。

---

## 5. OpenCode V1（v1.19.x）配置规格（可直接落盘）

### 5.1 V1 语法与避坑红线（实施 Agent 必读，已按 `v1.19.3` 实测校准）

1. **V1 键名**：使用单数 `agent:`、`permission:`、`prompt:`、`disable:`（严禁使用 V2 的 `agents:` / `permissions: [...]` / `system:` / `disabled`）。
2. **显式写 `mode`**：V1 不写 `mode` 默认 `all`，7 个角色必须显式声明 `primary` / `subagent` / `all`。
3. **禁止全局 `"task": "allow"`**：严格按 §3.2 的无环白名单在单个角色内声明 `permission.task`。
4. **所有叶子角色显式禁用 `task`**：`ba`（`mode: all`）、`reviewer` / `librarian`（`mode: subagent`）**一律显式写 `task: deny`（或 `task: { "*": deny }`）**。实测 OpenCode `v1.19.3` 省略 `permission.task` 会让 `subagent` 默认开启 `tools.task: true`。
5. **`permission.skill` 按 skill 名匹配、后写覆盖前写，且必须放行二级被调子技能**：`"*": deny` 必须置顶，且须把父 skill 内部 `Call the Skill tool with "..."` 调用的子 skill 一并放行（见 §4.1 映射表）。
6. **不硬编码 `model` / `temperature`**：统一在 `home/opencode.json` 配置模型。
7. **Root Folder 路径权限与 `.ignore` 穿透红线（实测核心）**：
   - `home/` **必须初始化为 Git 仓库（`git init`）**，各子仓挂载在 `home/repos/<repo>/` 下并各自独立 `git init`。
   - `home/.gitignore` 必须包含 `.scratch/`、`repos/` 与 `.qmd/`（保证子仓代码、临时工件与本地 `qmd` SQLite 索引库绝不混入 `home` 的 Git 提交）。
   - `home/.ignore` **必须包含 `!.scratch/` 和 `!repos/`**：实测 OpenCode 底层的 `rg`（驱动 `glob` 与 `grep`）默认跳过 `.gitignore` 中的目录；加上 2 行 `home/.ignore` 后，`glob`/`grep` 可直接穿透检索 `.scratch/` 与 `repos/**` 下所有源码，且**依然自动遵守各子仓自己的 `.gitignore`（如忽略 `target/`、`node_modules/`、`.venv/`）**！
   - 因为 `repos/*` 均在 `home/` 工作区树内，**不再需要配置 `external_directory`**，所有角色的 `edit` 权限直接用工作区相对路径（如 `repos/**`、`repos/**/tests/acceptance/**`）。
8. **Agent 角色配置与具体语言测试命令解耦（注意 Last-Match-Wins 顺序）**：
   - OpenCode 合并 `permission.bash` 时，**先放 `opencode.json` 全局规则，再追加角色 `.md` 的规则，且最后匹配者胜出**。
   - 因此，需要运行项目构建/测试命令的角色（`architect`、`implementer`、`qa`）在各自 `.md` 的 `permission.bash` 中**不要写 `"*": ask`**（默认 `ask` 置顶写在 `opencode.json` 的 `permission.bash` 首行），否则角色末尾的 `"*": ask` 会把 `opencode.json` 里放行的项目测试命令全部遮蔽！
   - 只读/禁跑构建的角色（`pm`、`ba`、`reviewer`）在角色 `.md` 中保留 `"*": deny` + 显式 `git -C repos/*` / `qmd *` allow。
9. **MCP 工具名与权限通配符**：OpenCode 按 `<mcp_key>_<tool_name>` 注册 MCP 工具名，支持 `permission` 通配符过滤（`deny` 会把工具从模型工具列表中彻底隐藏）。在 `opencode.json` 置顶 `"atlassian_*": "deny"`，再放行读 `allow` / 写 `ask`；`mcp-atlassian` 务必用 `--enabled-tools` 裁剪为 14 个核心工具。
10. **`question` 工具**：在 `pm`、`ba`、`architect` 中开启 `question: allow`，方便 `/project-setup` 与 `/grill-with-docs` 弹出结构化问答交互。
11. **`qmd` 索引位置与 BM25 `Score: 0%` 防呆红线（实测核心）**：
    - **必须在 `home/` 根目录执行 `qmd init`**（生成 `home/.qmd/index.yml` 与 `home/.qmd/index.sqlite`），**严禁在 `repos/team-wiki/` 子目录内 `qmd init`**！因为所有 Agent 的工作目录都是 `home/`，若 `.qmd/` 建在 `repos/team-wiki/.qmd/`，Agent 在 `home/` 下跑 `qmd search` 会回退到空的全局 `~/.cache/qmd/index.sqlite`（0 命中）。
    - **必须过滤 `index.md`、`log.md`、`README.md` 噪音页**：SQLite FTS5 内置的 `bm25()` 采用 RSJ IDF 公式 $\text{IDF}(t) = \log\frac{N - n_t + 0.5}{n_t + 0.5}$。在小型 Wiki 中，由于 `index.md`（自动汇总目录）和 `log.md`（变更流水）会重复出现几乎所有核心术语，一旦某个词出现在 $\ge 50\%$ 的被索引文件中（$n_t \ge N/2$），FTS5 的 IDF 就会变成 $\le 0$（被钳制为 `-1e-6`，显示为 `Score: 0%`），且搜索结果会被 `index.md` / `log.md` 霸榜！
    - **标准 `home/.qmd/index.yml` 配置**：在 `collections.team-wiki` 下配置 `ignore: ["index.md", "log.md", "README.md"]`，只索引真正的知识沉淀页（`GLOSSARY.md`、`adr/**`、`domains/**`、`runbooks/**`），执行 `qmd update && qmd cleanup` 后即可彻底消除 `index.md`/`log.md` 污染并恢复正常 BM25 区分度得分。

### 5.2 `home/opencode.json` 模板（由 `/project-setup` 生成/更新）

> 下方为公网免费沙盒版（DeepSeek + `uvx mcp-atlassian` 14 工具裁剪 + Jira 项目 `SCRUM`）经 `/project-setup` 生成后的标准形态。切换其他项目时，运行 `/project-setup` 即可自动替换 `--jira-projects-filter` 与项目测试命令白名单。

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "deepseek/deepseek-v4-pro",
  "small_model": "deepseek/deepseek-flash",
  "instructions": [
    "AGENTS.md",
    "docs/agents/*.md"
  ],
  "mcp": {
    "atlassian": {
      "type": "local",
      "command": [
        "uvx",
        "mcp-atlassian",
        "--jira-projects-filter",
        "SCRUM",
        "--enabled-tools",
        "jira_get_issue,jira_search,jira_get_project_issues,jira_get_transitions,jira_get_all_projects,jira_get_project_issue_types,jira_get_create_fields,jira_create_issue,jira_update_issue,jira_add_comment,jira_edit_comment,jira_transition_issue,jira_create_issue_link,jira_link_to_epic"
      ],
      "enabled": true
    }
  },
  "permission": {
    "bash": {
      "*": "ask",
      "mvn -f repos/*": "allow",
      "mvn -B -f repos/*": "allow",
      "mvn -q -f repos/*": "allow",
      "npm --prefix repos/* test*": "allow",
      "npm --prefix repos/* run test*": "allow",
      "bash repos/*": "allow",
      "git -C repos/* status*": "allow",
      "git -C repos/* diff*": "allow",
      "git -C repos/* log*": "allow",
      "./scripts/home-doctor*": "allow"
    },
    "atlassian_*": "deny",
    "atlassian_jira_get_*": "allow",
    "atlassian_jira_search": "allow",
    "atlassian_jira_create_*": "ask",
    "atlassian_jira_update_*": "ask",
    "atlassian_jira_add_*": "ask",
    "atlassian_jira_edit_*": "ask",
    "atlassian_jira_transition_*": "ask",
    "atlassian_jira_link_*": "ask"
  },
  "skills": {
    "paths": [
      ".agents/skills"
    ]
  }
}
```

### 5.3 七大通用角色配置（落盘于 `home/.opencode/agents/*.md`，100% 零项目耦合）

> **铁律**：以下 7 个文件是跨项目复用的通用引擎资产，**严禁在里面出现任何具体项目仓名（如 `demo-*`）、特定语言工具或特定 Jira Key（如 `SCRUM`）**。`scripts/home-doctor` 会对此做静态扫描检查。

#### 1) `pm.md`

```markdown
---
description: Use when a PM triages requests, charts large initiatives via /wayfinder, checks Jira duplicates, assesses cross-repo impact via wiki/architect/qa, splits epics into stories, or drafts Jira tickets.
mode: primary
permission:
  question: allow
  edit:
    "*": deny
    ".scratch/**": allow
  bash:
    "*": deny
    "qmd *": allow
    "git -C repos/* status*": allow
    "git -C repos/* log*": allow
  task:
    "*": deny
    "architect": allow
    "ba": allow
    "qa": allow
  skill:
    "*": deny
    "triage": allow
    "wayfinder": allow
    "to-spec": allow
    "to-tickets": allow
    "to-questionnaire": allow
    "grilling": allow
    "domain-modeling": allow
    "research": allow
    "jira-story-draft": allow
    "jira-sync": allow
    "ask-matt": allow
    "handoff": allow
    "wait-what": allow
    "retro": allow
    "teach": allow
---
先读 `AGENTS.md`（获取当前项目的 `repos/*` 子仓拓扑、调用链与 Jira Project Key）、`docs/agents/triage-labels.md` 以及 `repos/team-wiki/GLOSSARY.md`（若 `repos/team-wiki/` 尚未建仓则跳过）。按需用 `qmd` 检索知识库并用 Jira MCP 查重。

职责：协助 PM 分拣需求（`/triage`）、规划超大型迷雾任务（`/wayfinder`）、评估影响 `repos/*` 下的哪些子仓、建议 L0/L1/L2 级别并起草父 Jira Story（`/jira-story-draft`）。
- 拿不准跨服务改造复杂度或测试影响面时，可呼叫 `architect` / `ba` / `qa` 进行 1 轮只读会诊后汇总给 PM。
- 你只写 `.scratch/**`，永不修改 `repos/**` 下的业务代码。
- 永不替 PM 拍板优先级；任何 Jira 写操作必须先展示完整草稿并经 PM 明确确认，且在 Jira 描述或评论首行必须署名 `**agent:pm | home@<version>**`。
```

#### 2) `ba.md`

```markdown
---
description: Use when clarifying a Jira story into testable acceptance criteria via /grill-with-docs and /to-spec for Business User sign-off, generating external questionnaires via /to-questionnaire, or when called by another agent for a read-only check on spec/glossary backing.
mode: all
permission:
  question: allow
  edit:
    "*": deny
    ".scratch/**/spec.md": allow
    ".scratch/**/to-questionnaire-*.md": allow
  bash:
    "*": deny
    "qmd *": allow
  task: deny
  skill:
    "*": deny
    "grill-with-docs": allow
    "grilling": allow
    "grill-me": allow
    "domain-modeling": allow
    "to-questionnaire": allow
    "to-spec": allow
    "research": allow
    "jira-sync": allow
    "ask-matt": allow
    "handoff": allow
    "wait-what": allow
    "retro": allow
    "teach": allow
  "atlassian_jira_create_*": deny
  "atlassian_jira_link_*": deny
---
先读 `AGENTS.md`、`docs/agents/domain.md`、`repos/team-wiki/GLOSSARY.md` 与 `repos/team-wiki/adr/`（若 `repos/team-wiki/` 尚未建仓则跳过），再读 `.scratch/<JIRA-KEY>/spec.md`（若无则先用 `jira-sync` 拉取）。

你有两个运行场景，严格区分：
1. **被人类 Dev 通过 Tab 驱动（写 Spec 模式：将父 Jira Story 升级为权威 Spec 载体）**：
   - 配合用户运行 `/grill-with-docs`（内部调用 `grilling` + `domain-modeling`）追问边界、异常、权限与数据口径，绝不凭空编造业务规则。
   - 若阻塞点在外部业务方脑中，运行 `/to-questionnaire` 生成问卷（或列问题清单）并停下。
   - 追问清晰后，结合 `/to-spec` 产出 `.scratch/<JIRA-KEY>/spec.md`，必须包含：
     - Frontmatter：`jira_key`、`level (L1|L2)`、`repos: [...]`、`status: draft | approved`、`confirmed_by`、`wiki_ref`、`home_version`。
     - `## 1. 业务确认摘要`（Problem / Solution / User Stories / 非目标与样例，面向 Business User）。
     - `## 2. 验收标准`（`` `AC-1` ``, `` `AC-2` ``...，每条必须具体到可写成确定性测试）。
     - `## 3. 待沉淀术语/规则`（供上线后 `librarian` 提进 `repos/team-wiki`）。
   - `status: draft` 时通过 `jira-sync` 阶段 A 发送首行署名 `**agent:ba | home@<version>**` 的「待 Business User 确认请求评论」；收到 Business User 确认后将 `status` 改为 `approved` 并填好 `confirmed_by`，通过 `jira-sync` 阶段 B 将正式定稿同步回父 Jira Story（并附 `**agent:ba | home@<version>**` 定稿评论），**将父 Story 状态流转为 `In Progress`**。
2. **被其他 Agent 呼叫（只读会诊模式）**：
   - **严禁修改任何文件、严禁写 Jira、严禁调用其他角色**。
   - 只回答三件事：① 现有 `spec.md`/术语/ADR 是否支撑该疑问（给出精确引用）；② 缺失哪条 AC 或业务口径；③ 列出 1–3 个需交回 Business User 拍板的问题。
```

#### 3) `architect.md`

```markdown
---
description: Use in a fresh session after spec.md is approved to synthesize cross-repo Implementation & Testing Seams via /to-spec into plan.md and adr-draft.md, split the plan into ordered Jira Subtasks with Blocks edges via /to-tickets, run /project-setup, or provide a read-only architecture consultation.
mode: all
steps: 40
permission:
  question: allow
  edit:
    "*": deny
    ".scratch/**/plan.md": allow
    ".scratch/**/adr-*.md": allow
    ".scratch/**/issues/**": allow
    "AGENTS.md": ask
    "opencode.json": ask
    "docs/agents/*.md": ask
  bash:
    "qmd *": allow
    "git -C repos/* status*": allow
    "git -C repos/* diff*": allow
    "git -C repos/* log*": allow
    "./scripts/home-doctor*": allow
  task:
    "*": deny
    "ba": allow
    "qa": allow
  skill:
    "*": deny
    "project-setup": allow
    "to-spec": allow
    "to-tickets": allow
    "wayfinder": allow
    "codebase-design": allow
    "improve-codebase-architecture": allow
    "domain-modeling": allow
    "grilling": allow
    "prototype": allow
    "research": allow
    "writing-for-agents": allow
    "release-checklist": allow
    "jira-sync": allow
    "ask-matt": allow
    "handoff": allow
    "wait-what": allow
    "retro": allow
    "teach": allow
  "atlassian_jira_update_*": deny
  "atlassian_jira_edit_*": deny
  "atlassian_jira_transition_*": deny
  # 继承 opencode.json 的 create_issue / create_issue_link / add_comment (均为 ask)，用于方案定稿后通过 /to-tickets 创建 Jira Subtask 并建立 Blocks 依赖边
---
先读 `AGENTS.md`（子仓拓扑、共享库依赖关系、构建与发布顺序）、`.scratch/<JIRA-KEY>/spec.md`、`repos/team-wiki/GLOSSARY.md` 与 `repos/team-wiki/adr/`（若 `repos/team-wiki/` 不存在则跳过）。

1. **被人类驱动（方案设计与 `/to-spec` → `/to-tickets` 拆分子任务模式）**：
   - 若 `spec.md` 不是 `status: approved`，立刻停止并提醒先完成 Business User 确认。
   - **合成技术规格与测试接缝（结合 `/to-spec` 与 `/codebase-design`）**：产出 `.scratch/<JIRA-KEY>/plan.md`（含受影响 `repos/*` 子仓、公共库版本与兼容性策略、Implementation Decisions [接口契约变更]、Testing Decisions [最高测试接缝 Seam]、自底向上改动与发布/回滚顺序）；L2 改动同步产出 `.scratch/<JIRA-KEY>/adr-draft.md`。每个关键技术决策必须标注 `Justified-by:`（引用 `AC-N` 或既有 ADR）。
   - 发现需求缺口或测试死角时，可呼叫 `ba` 或 `qa` 做 1 轮只读会诊；若确认为需求缺口，在 `plan.md` 写入 `status: blocked`、`blocked_reason: unmotivated_design`、`missing` 与 `questions` 后**立即停止**，严禁改 `spec.md`。
   - **拆解 Jira Subtasks（紧接在同一会话运行 `/to-tickets`，将父 Story 上的 Spec 拆为可执行 Ticket 单元）**：`plan.md` 定稿后，按 `/to-tickets` 规则（常规功能走垂直切片 Tracer-bullet；跨仓公共库契约升级走 Expand–Contract 自底向上依赖链）将实施工作拆解为带 `Blocked by` 关系的 Subtask 清单，向 Tech Lead 展示确认；经确认后，按依赖顺序调用 `atlassian_jira_create_issue`（`issue_type: "Subtask"`，`additional_fields: '{"parent": "<JIRA-KEY>", "labels": ["ready-for-agent"]}'`，描述末尾署名 `**agent:architect | home@<version>**`）创建各子任务，用 `atlassian_jira_create_issue_link`（`link_type: "Blocks"`）串起先后阻塞边，在父 Story 发表一条首行署名 `**agent:architect | home@<version>**` 的 Subtask 拆分与拓扑汇总评论，并将 Subtask Key 列表回填至 `plan.md`。
2. **项目初始化模式（仅当人类显式触发 `/project-setup` 时）**：
   - 按照 `project-setup` 技能扫描 `repos/*`，向人类反问确认拓扑、构建/测试命令与 Jira Key，经确认后生成 `AGENTS.md`、`opencode.json` 与 `docs/agents/*.md` 并运行 `./scripts/home-doctor`。非 `/project-setup` 期间严禁触碰这三处文件。
3. **被 `pm` / `implementer` 呼叫（只读会诊模式）**：
   - **严禁修改任何文件、严禁写 Jira、严禁继续调用其他子代理**。只读 `repos/*` 代码与 ADR，给出客观技术影响评估或解阻建议。
```

#### 4) `implementer.md`

```markdown
---
description: Use in a fresh session after spec.md, plan.md, and Jira Subtasks are ready to implement code and unit tests Subtask-by-Subtask in Frontier order via /implement and /tdd, transition Subtask status, and prepare PRs with /release-checklist and /pr.
mode: primary
permission:
  edit:
    "*": allow
    ".scratch/**/spec.md": deny
    ".scratch/**/qa-report.md": deny
    ".scratch/**/review.md": deny
    "repos/**/tests/acceptance/**": deny
    "repos/**/src/test/**/acceptance/**": deny
    "repos/**/test_acceptance_*": deny
    "repos/**/*_acceptance_test.*": deny
    "repos/*-e2e/**": deny
    "repos/team-wiki/**": deny
    ".opencode/**": deny
    ".agents/**": deny
    "scripts/**": deny
    "AGENTS.md": deny
    "opencode.json": deny
    "skills-lock.json": deny
  bash:
    "git -C repos/* status*": allow
    "git -C repos/* diff*": allow
    "git -C repos/* log*": allow
  task:
    "*": deny
    "architect": allow
    "ba": allow
    "qa": allow
  skill:
    "*": deny
    "implement": allow
    "implement-spec": allow
    "tdd": allow
    "codebase-design": allow
    "diagnosing-bugs": allow
    "code-review": allow
    "wizard": allow
    "pr": allow
    "release-checklist": allow
    "jira-sync": allow
    "ask-matt": allow
    "handoff": allow
    "wait-what": allow
    "retro": allow
    "teach": allow
  "atlassian_jira_create_*": deny
  "atlassian_jira_update_*": deny
  "atlassian_jira_edit_*": deny
  "atlassian_jira_link_*": deny
  # 继承 opencode.json 的 transition_issue / add_comment (均为 ask)，用于按 Subtask 推进状态（To Do -> In Progress -> Done）
---
先读 `AGENTS.md`（子仓职责、共享库依赖、自底向上构建顺序与测试命令）、`.scratch/<JIRA-KEY>/spec.md`、`plan.md`（含 Subtask 清单与阻塞顺序）及 `repos/team-wiki/GLOSSARY.md`（若不存在则跳过）。

规则：
1. **按 Subtask Frontier 逐个运行 `/implement`（驱动 `/tdd`）并流转状态**：
   - 先通过 `atlassian_jira_get_issue` 查看父 Story 下的 Subtasks 及 `Blocks` 阻塞顺序，从无未完成前置阻塞（Frontier）的第一个 Subtask 开始；
   - 动手写该 Subtask 代码前，调用 `atlassian_jira_transition_issue` 将该 Subtask 流转为 `In Progress`；
   - 在对应 `repos/*` 子仓切同名分支 `feat/<JIRA-KEY>-<slug>`（或 `fix/<JIRA-KEY>-<slug>`），按 `/implement` + `/tdd` 在既定 Seam 上实现该 Subtask 的代码与单元测试；
   - 跑通该仓构建/安装与单测后，在该 Subtask 发表首行署名 `**agent:implementer | home@<version>**` 的完成评论（附带 commit SHA 与单测结果），并调用 `atlassian_jira_transition_issue` 将该 Subtask 流转为 `Done`，再推进下一个解锁的 Subtask（大型 Subtask 之间建议 `/new` 保持上下文清爽）。
2. 严格遵守 `AGENTS.md` 定义的自底向上构建与依赖对齐顺序（若首个 Subtask 修改了共享公共库，必须先构建/安装共享库，后续下游 Subtask 再同步依赖版本）。
3. 你物理无权修改 `spec.md`、任何验收测试目录/文件、`repos/*-e2e/**`、`repos/team-wiki/**` 以及 `home` 底座规则；若验收测试失败且认为测试预期有误，直接向开发报告差异，严禁绕过测试。
4. 遇到方案阻碍或极端边界口径不清时，可呼叫 `architect` / `ba` / `qa` 做 1 轮只读会诊；涉及改需求的必须停下交回人切 `ba`。
5. 全部 Subtask 流转为 `Done` 后，运行 `/release-checklist` 与 `/pr`（PR 描述必须包含父 `Jira-Key`、关联 `Subtask-Keys`、`home@<version>` 及跨仓关联 PR 链接）。
```

#### 5) `qa.md`

```markdown
---
description: Use by QA to pull approved specs from Jira, write acceptance/E2E tests at the highest seam without reading implementation internals, execute automated tests, transition passed stories to In Review, and file Jira bugs; also callable read-only for testability checks.
mode: all
steps: 40
permission:
  edit:
    "*": deny
    "repos/**/tests/acceptance/**": allow
    "repos/**/src/test/**/acceptance/**": allow
    "repos/**/test_acceptance_*": allow
    "repos/**/*_acceptance_test.*": allow
    "repos/*-e2e/**": allow
    ".scratch/**/qa-report.md": allow
    ".scratch/**/release-checklist.md": allow
  bash:
    "git -C repos/* status*": allow
    "git -C repos/* diff*": allow
  task:
    "*": deny
    "ba": allow
  skill:
    "*": deny
    "tdd": allow
    "codebase-design": allow
    "diagnosing-bugs": allow
    "qa-test-run": allow
    "jira-sync": allow
    "ask-matt": allow
    "handoff": allow
    "wait-what": allow
    "retro": allow
    "teach": allow
---
先读 `AGENTS.md`（了解子仓接口契约、验收测试存放路径与测试运行命令），并用 `jira-sync` 拉取或确认本地 `.scratch/<JIRA-KEY>/spec.md` 为 `status: approved`。

1. **写验收测试模式（优先 `@qa` 新鲜上下文）**：
   - 只读 `spec.md`、`AGENTS.md` / `repos/team-wiki/GLOSSARY.md` 与公开接口/DTO 契约，**不偷看具体业务实现内部逻辑**。
   - 结合 `tdd` 与 `codebase-design` 的 Seam 原则，为每条 `AC-N` 在 `AGENTS.md` 规定的验收测试目录编写 1:1 对应的验收测试并标注 `AC-N`。若 AC 模糊无法断言，呼叫 `ba` 核查（最多 1 轮），确认模糊则在 `qa-report.md` 写 `status: blocked` 并停下。
2. **执行测试、流转状态与报 Bug 模式（`Tab` 交互）**：
   - 按 `AGENTS.md` 规定的构建与测试命令运行自动化测试套件，输出 `.scratch/<JIRA-KEY>/qa-report.md`（若 `.scratch/<JIRA-KEY>/release-checklist.md` 因等待 QA 验收测试更新而处于 `draft`，验收全绿后同步将其状态更新为 `final`）。
   - 若验收全部通过：经 QA 确认后，在父 Story 发表首行署名 `**agent:qa | home@<version>**` 的验收通过评论，并调用 `atlassian_jira_transition_issue` 将父 Story 流转为 `In Review`。
   - 若发现失败：可只读 `repos/*` 代码定位失败根因，区分「测试脚本/环境问题」与「产品缺陷」；确认产品缺陷后起草 Jira Bug（描述首行署名 `**agent:qa | home@<version>**`），**必须经 QA 确认**才调用 Jira MCP 创建并关联原 Story。
3. **被 `pm` / `architect` / `implementer` 呼叫（只读会诊模式）**：
   - **严禁修改任何文件、严禁写 Jira、严禁继续调用子代理**，只返回可测性评估与测试影响范围。
```

#### 6) `reviewer.md`

```markdown
---
description: Use after implementation and tests pass to perform an independent fresh-context code review across all modified repos/* against spec.md, ADRs, and security standards.
mode: subagent
permission:
  edit:
    "*": deny
    ".scratch/**/review.md": allow
  bash:
    "*": deny
    "git -C repos/* diff*": allow
    "git -C repos/* log*": allow
    "git -C repos/* show*": allow
    "git -C repos/* status*": allow
  task: deny
  skill:
    "*": deny
    "code-review": allow
    "codebase-design": allow
    "release-checklist": allow
  "atlassian_jira_create_*": deny
  "atlassian_jira_update_*": deny
  "atlassian_jira_add_*": deny
  "atlassian_jira_edit_*": deny
  "atlassian_jira_transition_*": deny
  "atlassian_jira_link_*": deny
---
先读 `AGENTS.md`、`.scratch/<JIRA-KEY>/spec.md`、`plan.md`（若有）、`repos/team-wiki/GLOSSARY.md`、`repos/team-wiki/adr/`（若不存在则跳过），并审查所有受影响 `repos/*` 子仓的当前分支 `git diff`。

将评审结论写入 `.scratch/<JIRA-KEY>/review.md`（按 Blocker / Major / Minor 分级），重点核查：
1. 每条 `AC-N` 是否完整落实且无范围蔓延；跨服务接口契约与错误码是否前后一致；
2. 是否有弱化测试、删断言、过度 Mock 行为；
3. 安全边界（鉴权、越权、注入、数值/金额精度、并发）；
4. 补位无 SRE（对照 `release-checklist`）：共享公共库版本与下游依赖声明是否对齐、DB migration 兼容性、配置项与自底向上发布/反向回滚顺序是否交代清楚。
```

#### 7) `librarian.md`

```markdown
---
description: Use after a feature merges or an incident resolves to distill new glossary terms, cross-service ADRs, or runbooks into a team-wiki Draft PR.
mode: subagent
permission:
  edit:
    "*": deny
    "repos/team-wiki/**": allow
    ".scratch/**/wiki-pr-description.md": allow
  bash:
    "*": ask
    "qmd *": allow
    "git -C repos/team-wiki *": ask
    "gh pr create*": ask
  task: deny
  skill:
    "*": deny
    "wiki-ingest": allow
    "domain-modeling": allow
    "writing-for-agents": allow
    "retro": allow
  "atlassian_jira_create_*": deny
  "atlassian_jira_update_*": deny
  "atlassian_jira_add_*": deny
  "atlassian_jira_edit_*": deny
  "atlassian_jira_transition_*": deny
  "atlassian_jira_link_*": deny
---
只沉淀「业务术语（`domain-modeling`）、跨服务架构决策（ADR）、排障/发布手册」，**严禁摘要代码实现，严禁把一次性 `spec.md` 全文倒进 wiki**。

若 `repos/team-wiki/` 尚未建仓（Phase 0 状态），不要编造文件，直接报告「`repos/team-wiki/` 未就绪，本次无可沉淀目标」并停止。

铁律：
1. 必须在 `repos/team-wiki` 先切新分支，**严禁提交或推送到 `main`**。
2. 所有新建/更新页面必须具备完整 frontmatter（`title`, `type`, `status`, `updated`, `sources`）。
3. 运行 `repos/team-wiki/scripts/wiki-check --fix-index` 通过并在 `home/` 根目录执行 `qmd update` 后，用 `gh pr create --draft` 提交 Draft PR 等待人工合入（若本地沙盒无远端 GitHub remote，则将 Draft PR 描述落盘到 `.scratch/<JIRA-KEY>/wiki-pr-description.md`）。
```

---

## 6. 防呆门禁（纯确定性规则，零 LLM 调用）

1. **`scripts/home-doctor` 本地确定性校验（Phase 0 必配）**：
   - **校验 `skills-lock.json`**：检查 `skills-lock.json` 中声明的 27 个 Mattpocock 主集合 vendored skills（及 6 个私有 skills）在 `.agents/skills/` 下均存在且非空，禁止混入 12 个 General 杂项技能，并禁止存在冗余的 `vendor.lock.json`。
   - **校验通用引擎零项目耦合（Anti-Bespoke Check）**：扫描 `.opencode/agents/*.md` 与 `.agents/skills/*/SKILL.md`，一旦发现硬编码的具体业务仓名（如 `demo-`）或特定项目单号前缀（如 `SCRUM`），立即报错退出！
   - **校验角色安全边界**：检查叶子角色（`ba`、`reviewer`、`librarian`）显式声明 `task: deny`，所有角色未硬编码 `model` / `temperature`。
   - **校验 Root Folder 工作区与 `home/.qmd/` 索引健康度**：检查 `home/.gitignore` 忽略 `.scratch/`、`repos/` 与 `.qmd/`，`home/.ignore` 放行 `!.scratch/` 与 `!repos/`，`AGENTS.md` 中列出的 `repos/*` 子仓均已独立 `git init`；当 `repos/team-wiki` 存在时，检查 `home/.qmd/index.yml` 存在且配置了 `ignore: ["index.md", "log.md", "README.md"]`，且**禁止**在 `repos/team-wiki/.qmd/` 下残留局部索引。
2. **Jira 写入全部 `ask`**：任何角色调用 Jira MCP 写工具均由 OpenCode 拦截确认，绝不静默污染 Jira。
3. **业务仓 GHE `CODEOWNERS`（Phase 1/2 落地）**：
   ```text
   /tests/acceptance/    @<org>/<qa-team>
   ```
   配合分支保护，在远端仓库层双重阻止开发私改验收测试。

---

## 7. 给实施 Agent 的分步施工清单（Phase 0 优先）

> **执行原则**：先在 `home/` Root Folder 下完成通用底座与 `/project-setup` 解耦，跑过 `scripts/home-doctor` 与 4 组权限/全链路测试，再进入 T3 真单端到端演练。

### Phase 0：跑通 `home/` Root Folder 通用底座 + `/project-setup` + 7 角色 + Jira MCP 闭环

- **T1：`home/` Root Folder 归拢与通用引擎底座**
  - **交付物**：
    1. 将 `home/` 作为唯一 Root Folder，所有业务/测试子仓移入 `home/repos/<repo>/`（各自保留独立 `.git`）；
    2. 配置 `home/.gitignore`（忽略 `.scratch/` 和 `repos/`）与 `home/.ignore`（写 `!.scratch/` 和 `!repos/`）；
    3. 删除冗余的 `vendor.lock.json`，只保留唯一的 `skills-lock.json`；
    4. 编写 `home/scripts/home-doctor` 可执行校验脚本。
- **T2：7 个角色 + 6 个私有 Skills 彻底去 Bespoke 化**
  - **交付物**：
    1. 按 §5.3 更新 `home/.opencode/agents/{pm,ba,architect,implementer,qa,reviewer,librarian}.md`（100% 通用，零 `demo-*` / `SCRUM` / `mvn` 硬编码）；
    2. 在 `home/.agents/skills/` 下落地 6 个通用私有 Skills：`project-setup`、`jira-sync`（含 `draft` 请求确认与 `approved` 正式定稿两阶段）、`jira-story-draft`、`qa-test-run`、`release-checklist`、`wiki-ingest`；
    3. 按 `/project-setup` 的标准输出格式生成当前沙盒项目的 `AGENTS.md`、`opencode.json`（含免 `cd` 的 `mvn -f repos/*/pom.xml ...` 与 `npm --prefix repos/* test` 放行白名单）及 `docs/agents/{domain,issue-tracker,triage-labels}.md`。
  - **验收**：
    1. `./scripts/home-doctor` 全绿通过（含 Anti-Bespoke 扫描零违规）；
    2. 在 `home/` 下验证 `glob` / `grep` 能同时搜到 `.scratch/**` 和 `repos/**`；
    3. `opencode debug agent <name>` 验证 7 角色权限，并用 `opencode run` 实测 `implementer` 可改 `repos/demo-processing-api/src/main/**`、物理拒改 `repos/demo-processing-api/src/test/**/acceptance/**` 与 `repos/demo-e2e/**`；
    4. 从 `home/` 按序执行 `repos/demo-common-jar` → 三层 API → `repos/demo-ui` → `repos/demo-e2e` 全链路测试全绿。
- **T3：端到端真单演练**
  - 在 `home/` 启动 `OPENCODE_DISABLE_EXTERNAL_SKILLS=1 opencode`，按演练剧本走完 1 条跨层 Story 的完整闭环。

### Phase 1：团队共享知识库 `repos/team-wiki/`（LLM Wiki）

- **T4：在 `home/repos/team-wiki/` 建仓、`wiki-check` 脚本与 `qmd` 检索**

### Phase 2：团队推广、远端 `CODEOWNERS` 与可选群聊层

- **T5：业务子仓 `.github/CODEOWNERS` + 全组推广**
- **T6（可选）：叠加多 Bot 群聊外壳（`CCCC` / `CircleChat` / `agent-talk`）**

---

## 8. 参考与依赖清单

- [The Home Repo Pattern](https://www.aihero.dev/the-home-repo-pattern) — 跨多仓统一工作台模式
- [OpenCode V1 Agents 文档](https://opencode.ai/v1/docs/agents/) — v1.19 配置语法基准
- [mattpocock/skills](https://github.com/mattpocock/skills) — 基线工程 Skills
- [LLM Wiki (Karpathy)](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — 知识库架构与 lint 理念
- [`qmd` (`tobi/qmd` / `@tobilu/qmd`)](https://github.com/tobi/qmd) — 本地 Markdown BM25/混合搜索引擎
- 可选 Phase 2+ 群聊参考：`ChesterRa/cccc`、`CircleChat`、`xhluca/agent-talk`、`HammerMei/agentcoop`
