---
name: project-setup
description: Scan repos/* to detect languages, build tools, and test layout, then interview the user about topology, build/release order, test boundaries, issue-tracker mapping and model IDs, and generate AGENTS.md, opencode.json and docs/agents/*.md. Use when onboarding a new project or when repos are added, removed or re-languaged.
---

# project-setup

把「通用引擎」接到一个具体项目上。只会写四处项目特定文件：`AGENTS.md`、`CODING_STANDARDS.md`、`opencode.json`、`docs/agents/*.md`。**其余任何文件都不改**（尤其不动 `.opencode/agents/**`、`.agents/skills/**`、`scripts/**`）。

先读 `VERSION`、现有 `AGENTS.md`、`CODING_STANDARDS.md` 与 `opencode.json`（若有），保留用户已有内容中未被本次确认覆盖的部分。

## 1. 自动探测（不问人先看清）

1. 列出 `repos/*`：只认含 `.git` 的目录才算子仓；非 Git 目录只报告、不写入文件。
2. 逐个判断语言与构建栈：**看该仓根目录的构建清单文件与锁文件属于哪个生态**（构建描述、依赖清单、锁文件），不要凭目录名猜。也记录：
   - 是否多模块（单仓多产物）；
   - **确定性反馈三件套（Typecheck / Linter / Test）**：该仓现有的类型检查、Linter/Checkstyle/ESLint/Ruff 配置与测试目录（单测 / 验收 / e2e 分别在哪）；若某仓没有任何 Linter 或 Pre-commit/CI 检查，显式标注为 `missing-linter-guardrail`；
   - 是否声明了共享库与其版本号位置（供第 2 问自动填默认值）。
3. 探测共享库与下游依赖：某仓被其他仓的依赖清单声明 → 该仓是 `shared-lib` 候选。
4. 汇总成一张表给用户看：`仓 | 探测到的栈 | 产物类型 | Linter/Typecheck | 测试目录 | Git 状态`。

**探测只用于给默认值**：技能文件与角色定义里不得固化任何具体语言、工具或仓名，全部由本步探测结果 + 用户确认后写进项目文件。

## 2. 反问确认（5 个必问项，每项先给探测默认值）

**逐项提问，一次一项**；用 `question` 工具（可多选/单选）或结构化文本提问均可。用户说"按默认"就接受默认值，不要再复述一遍。

1. **子仓角色与调用/依赖拓扑**
   - 每个仓归类为 `shared-lib` / `service` / `ui` / `e2e`；
   - `service` 之间自底向上的调用顺序（谁是底层、谁调用谁）；
   - 哪些仓依赖哪个 `shared-lib`、依赖版本写在哪里。
2. **自底向上构建、Linter 与发布顺序**
   - 共享库如何产出并让下游可见（安装到本地仓库 / 发布到制品库 / 其他方式）；
   - 各仓的**构建、Typecheck/Linter 与测试命令**在 Root Folder 下免 `cd` 的形式（用各栈自己的 `-f` / `--prefix` / `-C` 语义，保证从 `home/` 直接可跑）；
   - 反向回滚顺序。
3. **单测 vs 验收测试边界 & 跨仓编码红线（`CODING_STANDARDS.md`）**
   - 各仓单测目录与命令；
   - 各仓验收测试目录与命令（E2E 仓单列）；
   - 明确列出 `implementer` 物理禁改的路径集合（通用模式：`repos/**/tests/acceptance/**`、`repos/**/src/test/**/acceptance/**`、`repos/**/test_acceptance_*`、`repos/**/*_acceptance_test.*`、`repos/*-e2e/**`）；
   - 是否有机器 Linter 查不出的跨仓判断类编码红线（如金额/精度必须走共享库、禁止裸 `any` 等）需写入 `CODING_STANDARDS.md` 供 `@reviewer` 强制审查。
4. **Issue Tracker 映射**
   - Jira 项目 Key（仅写进项目文件，不写进角色/Skill）；
   - 5 个规范分拣角色各映射到什么状态/标签；
   - L0/L1/L2 的标签约定。
5. **模型与按角色模型分配 + 只读检查命令放行**
   - 默认主模型（`model`）、轻量模型（`small_model`），以及**是否需要为 7 个角色分别指定不同模型**（统一写进 `opencode.json` 的 `"agent": { "<role>": { "model": "..." } }`，保持 `.opencode/agents/*.md` 零模型硬编码）；
   - 是否把第 2、3 问里的**只读构建、Typecheck/Linter 与测试命令**写入 `opencode.json` 的 `permission.bash` 自动放行（推荐：是）。

## 3. 生成四处文件

### `AGENTS.md`（保持高密度导航指针风格，防膨胀滑入 150K 变笨区）

> **上下文分工原则**：`AGENTS.md` 会被注入所有角色的上下文，因此**只放导航地图、构建/Linter/测试命令与角色边界**；把具体的代码风格、坏味道判据与历史反例放进 `CODING_STANDARDS.md`（仅在 `@reviewer` 评审和 `/retro` 复盘时按需读取）。

1. **子仓拓扑**表：仓 / 角色 / 技术栈 / 职责 / Linter & 单测 / 验收测试；
2. **调用链与依赖**：ascii 图 + 接口契约表 + 共享错误码约定（没有就写"无"）；
3. **构建、Linter 与发布顺序**：自底向上，命令全部是 Root Folder 下免 `cd` 的形式；写明回滚顺序与"共享库升级必须下游依赖同步"的规则；
4. **单测 vs 验收测试边界**：路径 + 谁写 + `implementer` 禁改清单；
5. **角色与规则**：7 个角色在哪、过程工件写 `.scratch/<JIRA-KEY>/`、评审规范指向 `CODING_STANDARDS.md`、Jira Key、`repos/team-wiki/` 就绪状态、每个 Subtask 独立 `/new` 开新会话保持 <150K 聪明区铁律；
6. **`## Agent skills` 标准指针块**（兼容 `mattpocock/skills` 所有技能对 `/setup-matt-pocock-skills` 产物的查找，固定指向 `docs/agents/issue-tracker.md`、`docs/agents/triage-labels.md`、`docs/agents/domain.md`）。

### `CODING_STANDARDS.md`（供 `@reviewer` 双轴评审与 `/retro` 收紧束身衣使用）

保留现有 `CODING_STANDARDS.md` 的四节结构（1. Deep Modules & Narrow Interfaces；2. Three "Lying Tests" Forbidden；3. Shared Contract & Domain Language Discipline [Steering Words + `GLOSSARY.md` `_Avoid_` 黑名单 + 共享库精度/校验红线]；4. Human Review Leverage: "Never Write the Same PR Comment Twice" via `/retro`），将用户确认的本项目跨仓编码判断标准写入第 3 节。注意：**不要**将 `CODING_STANDARDS.md` 加入 `opencode.json` 的全局 `instructions` 数组。

### `opencode.json`

保留 `$schema` / `instructions` / `mcp` 结构与 `permission` 里的 MCP 基线；更新：
- 全局默认 `model`、`small_model`，以及按角色分配的 `"agent": { "pm": { "model": "..." }, "ba": { "model": "..." }, "architect": { "model": "..." }, "implementer": { "model": "..." }, "qa": { "model": "..." }, "reviewer": { "model": "..." }, "librarian": { "model": "..." } }`（所有模型配置集中在此，严禁写进 `.opencode/agents/*.md`）；
- `mcp.<tracker>.command` 里的项目过滤参数（如 Jira 的 projects filter）；
- `permission.bash`：置顶 `"*": "ask"`，随后 `allow` 用户确认的只读构建/测试命令与 `git -C repos/* status|diff|log`、`./scripts/home-doctor*`；
  放行模式用「命令 + 作用域前缀 + `*`」的形式（该栈自己的 `-f repos/*` / `--prefix repos/*` 语义），**不要写逐条字面命令**。实测（OpenCode 1.19.3）：
  - 重定向 `2>&1` / `> file` 不影响匹配；
  - **管道 `|` 会被拆成多段，每一段都必须命中 allow**，否则整条命令退化成 `ask`。所以要在 `AGENTS.md` 里提醒：构建/测试命令不要接 `| tail` 之类的管道。
- **必须保留** `"skills": { "paths": [".agents/skills"] }`：项目技能目录只有被登记成项目路径，`OPENCODE_DISABLE_EXTERNAL_SKILLS=1` 时才会保留（否则连本地 33 个技能一起被关掉）；
- **不要**写 `external_directory`（`repos/*` 已在本工作区树内）。

生成后用 `opencode debug config` 复核键值真的生效。

### `docs/agents/{domain,issue-tracker,triage-labels}.md`

- `domain.md`：领域文档消费规范。指向 `repos/team-wiki/`（未建仓时说明以 `AGENTS.md` 为准），并列出本项目的核心术语与"金额/精度类规则必须走共享校验"这类跨层约定。
- `issue-tracker.md`：`.scratch/<JIRA-KEY>/` 各文件名与属主、spec frontmatter 必填项、本环境实际启用的 MCP 工具名清单、读写权限基线。
- `triage-labels.md`：5 个规范分拣角色 → 本项目取值；L0/L1/L2 标签；五道门的状态映射。

## 4. 自检、可选真机验证脚手架与收尾

1. 运行 `./scripts/home-doctor`，必须全绿；失败就按它的报错修，**不要改 `home-doctor` 来让它变绿**。
2. **可选真机验证能力（对普通成员透明）**：若 `repos/*` 包含可运行的用户交互面（UI / API / CLI / 工作流服务）且 `.agents/skills/verify-*/` 尚未建立，主动询问搭建者一句：「是否需要顺便按代码库自动生成一套本地真机验证配方（`verify-<app>`），供后续研发提 PR 与 QA 验收时静默自动运行？」。若同意，直接内部执行 `create-verification-skill` 完成生成并跑通自证；若跳过，后续随时可补建。
3. 把本次生成/改动摘要（改了哪几个文件、拓扑是什么、测试命令是什么、是否生成了 `verify-<app>`）报告给用户。
4. 提醒用户：角色、Skills、`home-doctor` 属于通用引擎，换项目只重跑本技能；拓扑再变就再跑一次。
