# AI-SDLC Team Workspace (`home`) — Quick Start Guide

这是一套面向多仓库（Multi-Repo）团队的 **AI 协同研发工作台**（支持 **macOS / Linux / Windows**，基于 [OpenCode](https://opencode.ai) + Jira + 本地知识库）。
它内置了 **7 个岗位 AI 角色**（`pm`、`ba`、`architect`、`implementer`、`qa`、`reviewer`、`librarian`）和 **35 个研发技能**，帮助团队从「Jira 需求 → 业务规格 → 架构拆单 → 编码自测 → QA 验收 → 代码评审 → 知识沉淀」全流程人机协作。

---

## 1. 环境准备（每人装一次）

### 1.1 安装基础命令行工具
请确认已安装以下工具（**Windows 用户请务必安装 [Git for Windows](https://gitforwindows.org/) 和 Python 3**，OpenCode 和体检脚本依赖 Git 自带的 Bash 环境）：

```bash
# 1. OpenCode (v1.19+)
opencode --version

# 2. uv (用于自动启动 Jira MCP 服务)
uvx --version

# 3. GitHub CLI (用于命令行提 PR) & Python 3 (自带 sqlite3 FTS5 本地搜索引擎，零第三方依赖)
gh --version
python3 --version   # Windows 下为 python --version
```

### 1.2 配置个人 Jira 环境变量

#### 🍎 macOS / Linux（写入 `~/.zshrc` 或 `~/.bashrc` 后执行 `source ~/.zshrc`）
```bash
export JIRA_URL="https://<your-domain>.atlassian.net"
export JIRA_USERNAME="<your-email@company.com>"
export JIRA_API_TOKEN="<your-jira-api-token>"
export OPENCODE_DISABLE_EXTERNAL_SKILLS="1"
```

#### 🪟 Windows — PowerShell（永久写入当前用户环境变量，重开终端生效）
```powershell
[Environment]::SetEnvironmentVariable("JIRA_URL", "https://<your-domain>.atlassian.net", "User")
[Environment]::SetEnvironmentVariable("JIRA_USERNAME", "<your-email@company.com>", "User")
[Environment]::SetEnvironmentVariable("JIRA_API_TOKEN", "<your-jira-api-token>", "User")
[Environment]::SetEnvironmentVariable("OPENCODE_DISABLE_EXTERNAL_SKILLS", "1", "User")

# 让当前 PowerShell 窗口立即生效：
$env:JIRA_URL = "https://<your-domain>.atlassian.net"
$env:JIRA_USERNAME = "<your-email@company.com>"
$env:JIRA_API_TOKEN = "<your-jira-api-token>"
$env:OPENCODE_DISABLE_EXTERNAL_SKILLS = "1"
```
> *注：如果你在 Windows 上使用 **Git Bash**，写法与 macOS/Linux 完全一致（写入 `~/.bashrc` 即可）。仓库内已内置 `.gitattributes` 强制 `eol=lf`，Windows 用户无需担心 `CRLF` 换行符破坏脚本。*

---

## 2. 安装与初始化（二选一）

### 场景 A：你是团队里的【普通成员】（PM / Dev / QA）
> 团队负责人已经建好了 GitHub 上的 `team-sdlc-home` 和 `team-wiki` 仓库，你只需 **3 步** 在本地跑起来：

#### Step 1：克隆团队工作台主仓（`home`）
- **macOS / Linux / Windows (Git Bash)**：
  ```bash
  git clone git@<github-host>:<org>/team-sdlc-home.git ~/work/team-sdlc-home
  cd ~/work/team-sdlc-home
  ```
- **Windows (PowerShell)**：
  ```powershell
  git clone git@<github-host>:<org>/team-sdlc-home.git "$HOME\work\team-sdlc-home"
  cd "$HOME\work\team-sdlc-home"
  ```

#### Step 2：把 `team-wiki` 和你要干活的业务仓克隆到 `repos/` 目录下
> `repos/` 目录已被主仓 `.gitignore` 忽略，里面的每个子目录都是独立的 Git 仓库，互不干扰。

```bash
# 必装：团队共享知识库（涵盖 8 大分类：GLOSSARY 术语表、domains 领域契约、standards 跨仓规范、designs 架构设计 RFC、adr 决策记录、runbooks 运维手册、postmortems 故障复盘、onboarding 新人导览）
git clone git@<github-host>:<org>/team-wiki.git repos/team-wiki

# 按需克隆你日常开发的业务仓库（克隆几个都行）
git clone git@<github-host>:<org>/<your-repo-1>.git repos/<your-repo-1>
git clone git@<github-host>:<org>/<your-repo-2>.git repos/<your-repo-2>
```

#### Step 3：初始化本地知识库索引并自检（零外部依赖）
在 `team-sdlc-home` **根目录**下执行（内置的 `scripts/wiki-search` 使用 Python 标准库 `sqlite3` FTS5 构建毫秒级 BM25 索引，**无需安装 `@tobilu/qmd`、本地 LLM 或任何第三方包**；且 `home-doctor` 也会自动检查并初始化索引）：

- **macOS / Linux / Windows (Git Bash)**：
  ```bash
  python3 scripts/wiki-search update

  # 运行体检脚本，看到 ALL CHECKS PASSED 即可开始工作
  ./scripts/home-doctor
  ```
- **Windows (PowerShell)**：
  ```powershell
  .\scripts\wiki-search.ps1 update

  # 运行 Windows 包装体检脚本（自动调用 Git for Windows 的 bash 执行校验）
  .\scripts\home-doctor.ps1
  ```

---

### 场景 B：你是团队【负责人 / 搭建者】（首次为新项目搭建工作台）
> 如果你是第一次把这个工具引入新项目，用自带的 `home-template/` 和 `team-wiki-template/` 初始化并推送到 GitHub：

- **macOS / Linux / Windows (Git Bash)**：
  ```bash
  # 1. 复制工作台模板与知识库模板
  cp -R ./home-template ~/work/team-sdlc-home
  cp -R ./team-wiki-template ~/work/team-sdlc-home/repos/team-wiki

  # 2. 初始化独立的 team-wiki 仓库并推上 GitHub
  cd ~/work/team-sdlc-home/repos/team-wiki
  git init && ./scripts/wiki-check --fix-index
  git add -A && git commit -m "chore: init team-wiki"
  git remote add origin git@<github-host>:<org>/team-wiki.git
  git push -u origin main

  # 3. 把项目的所有业务仓库 clone 到 repos/ 下
  cd ~/work/team-sdlc-home/repos
  git clone git@<github-host>:<org>/<shared-lib-repo>.git
  git clone git@<github-host>:<org>/<service-repo>.git
  git clone git@<github-host>:<org>/<ui-repo>.git

  # 4. 回到主目录构建零依赖知识库索引并启动 OpenCode
  cd ~/work/team-sdlc-home
  git init
  python3 scripts/wiki-search update
  opencode
  ```
- **Windows (PowerShell)**：
  ```powershell
  # 1. 复制工作台模板与知识库模板
  Copy-Item -Recurse .\home-template "$HOME\work\team-sdlc-home"
  Copy-Item -Recurse .\team-wiki-template "$HOME\work\team-sdlc-home\repos\team-wiki"

  # 2. 初始化独立的 team-wiki 仓库并推上 GitHub
  cd "$HOME\work\team-sdlc-home\repos\team-wiki"
  git init
  .\scripts\wiki-check.ps1 --fix-index
  git add -A; git commit -m "chore: init team-wiki"
  git remote add origin git@<github-host>:<org>/team-wiki.git
  git push -u origin main

  # 3. 把项目的所有业务仓库 clone 到 repos/ 下
  cd "$HOME\work\team-sdlc-home\repos"
  git clone git@<github-host>:<org>/<shared-lib-repo>.git
  git clone git@<github-host>:<org>/<service-repo>.git
  git clone git@<github-host>:<org>/<ui-repo>.git

  # 4. 回到主目录构建零依赖知识库索引并启动 OpenCode
  cd "$HOME\work\team-sdlc-home"
  git init
  .\scripts\wiki-search.ps1 update
  opencode
  ```

启动 `opencode` 后，按 **`Tab`** 切到 **`architect`** 角色，输入 **`/project-setup`**。它会自动扫描 `repos/*` 并向你提问 5 个问题（仓库调用关系、构建命令、测试目录、Jira Project Key、模型配置），生成 `AGENTS.md` 和 `opencode.json`。最后提交并推到 GitHub 的 `<org>/team-sdlc-home.git`，其他同事就能直接按【场景 A】拉取使用了。

---

## 3. 日常怎么用？（4 个基本操作 + 7 步研发流）

### 每次启动工作台
**永远在 `team-sdlc-home` 根目录下启动**（不要 `cd` 进 `repos/` 子目录启动）：

- **macOS / Linux / Git Bash**：`cd ~/work/team-sdlc-home && opencode`
- **Windows PowerShell**：`cd "$HOME\work\team-sdlc-home"; opencode`

### 4 个核心快捷键与习惯
1. **`Tab` 键**：在顶部切换当前对话的岗位角色（`pm` / `ba` / `architect` / `implementer` / `qa`）。
2. **`@角色名`**：在对话中呼叫只读子角色（如 `@reviewer` 做代码评审、`@librarian` 沉淀 Wiki）。
3. **`/new` 命令**：**每做完一个大阶段（比如写完 Spec 要去写架构方案，或写完方案要去写代码），必须输入 `/new` 开启新会话**，防止上下文过长导致 AI 变笨。
4. **`[Allow / Deny]` 审批框**：所有写 Jira（建单、改单、评论、流转状态）和 `git push` / `gh pr create` 都会弹窗停住等你确认。**你点 Allow 才会真正执行**。

---

### 一张需求单从头到尾的标准口令速查表

假设你要处理一张 Jira 需求（以 `PROJ-101` 为例）：

| 步骤 | 你切到什么角色 | 你在对话框输入什么口令 | 你需要 Review & 确认什么 |
|---|---|---|---|
| **① 提需求建单** | 按 `Tab` 切 **`pm`** | `/jira-story-draft 帮我查重并起草需求：<一句话描述需求>` | 看它生成的 `.scratch/` 草稿和影响仓库对不对 → 满意后批准它在 Jira 创建父 Story（如 `PROJ-101`） |
| **② 澄清需求写 Spec（边聊边对齐术语）** | 输入 `/new`<br>按 `Tab` 切 **`ba`** | `拉取 PROJ-101，运行 /grill-with-docs 追问我业务边界与同义词黑名单(_Avoid_)，然后用 /to-spec 生成 spec.md` | 1. 回答 AI 的追问，审阅 `.scratch/PROJ-101/spec.md` 的验收标准 `AC-1..N` 与待沉淀术语（含 `_Avoid_` 禁用别名）；<br>2. 让它发 Jira 待确认评论给业务方；<br>3. 业务方在 Jira 确认后，让它执行阶段 B 把正式 Spec 回写到 `PROJ-101` 并流转为 `In Progress` |
| **③ 出深模块方案与拆子任务** | 输入 `/new`<br>按 `Tab` 切 **`architect`** | `读取 .scratch/PROJ-101/spec.md，用 /to-spec 和 /codebase-design 设计窄接口深模块(Deep Module)方案写入 plan.md，并用 /to-tickets 列出拟拆分的 Jira Subtasks 给我审核` | 看 `plan.md` 的接口设计（外部测试接缝 Seam）和 Subtask 拆分粒度合不合理（小改动无需拆 Subtask；跨仓大改动确保每个 Subtask 可在单次 <150K 会话内完成）→ 满意后说 `批准创建 Jira Subtasks` |
| **④ 按单编码（1 个 Subtask = 1 次 `/new` 新会话）与开 PR** | 输入 `/new`<br>按 `Tab` 切 **`implementer`** | `查看 PROJ-101 下的 Subtasks，领取当前第一个解锁的 Subtask，按 /implement 和 /tdd 实现代码和单测并让我看 diff` | 1. **防变笨区铁律**：每做完 **1 个** Subtask 检查 diff、跑过 Linter/单测并批准流转为 `Done` 后，**立刻输入 `/new` 开启新会话**再领下一个 Subtask；<br>2. 全部完成后输入：`运行 /release-checklist 和 /pr 生成发布检查单并创建 GitHub PR` |
| **⑤ QA 写验收测试与跑测** | 输入 `/new`<br>按 `Tab` 切 **`qa`** | `用 jira-sync 拉取 PROJ-101 的 spec.md，在外部 Seam 上为 AC-1..N 编写验收测试，先列出用例覆盖表给我审核，确认后再跑测试` | 看测试用例覆盖全不全 → 让它跑自动化验收测试 → 全绿后批准把 `PROJ-101` 流转为 `In Review`（若测出 Bug，批准它提 Jira Bug 单，再切回 `implementer` 用 `/diagnosing-bugs` 修复） |
| **⑥ AI 双轴评审（`Spec` + `CODING_STANDARDS.md`）+ 人工合 PR** | 输入 `/new`<br>直接呼叫 **`@reviewer`** | `@reviewer 对照 .scratch/PROJ-101/spec.md 和 CODING_STANDARDS.md 对所有修改子仓执行 /code-review，输出 review.md` | 看 `.scratch/PROJ-101/review.md` 和 GitHub PR（结合 `/pr` 生成的双向门/单向门风险评估）→ 有问题切回 `implementer` 返工 → 没问题在 GitHub 点 **Merge PR**，并把 `PROJ-101` 流转为 `Done` |
| **⑦ 双轨沉淀：写 Wiki（`/wiki-ingest`）+ 收紧束身衣（`/retro`）** | 输入 `/new`<br>直接呼叫 **`@librarian`** | `@librarian 运行 /wiki-ingest 把 PROJ-101 新增的术语(含 _Avoid_)、规范或 ADR 提 PR 到 repos/team-wiki；再运行 /retro 复盘本次评审问题并收紧到 CODING_STANDARDS.md 或 AGENTS.md 导航指针` | 1. 在 GitHub 合入 `team-wiki` PR（同事跑 `python3 scripts/wiki-search update --pull` 同步）；<br>2. 批准 `/retro` 将本次踩坑沉淀进 `CODING_STANDARDS.md` 或 Linter 检查，让 Agent 下次不再犯同类错误 |

---

### 日常架构治理与学习口令（无需建需求单也能随时用）

- **老代码深化重构（把「浅模块」合并成「深模块 Deep Module」或集中状态机）**：
  切到 **`architect`**，输入：
  ```text
  对 repos/<目标仓库> 运行 /improve-codebase-architecture，找出暴露内部细节的浅模块或分散状态，给出深模块（Deep Module）重构报告
  ```
- **排查存量「说谎测试（Lying Tests）」**：
  切到 **`qa`** 或 **`architect`**，直接输入 Matt Pocock 的审计口令：
  ```text
  探索 repos/<目标仓库> 的测试套件，找出那些同义反复的（Tautological）、过于结构敏感的（Structure-Sensitive），或 Mock 与真实运行时不符（Cannot-Fail）的测试
  ```
- **从团队历史 GitHub PR 评论中批量提炼 `CODING_STANDARDS.md`**：
  呼叫 **`@librarian`** 或 **`architect`**，输入：
  ```text
  查看你能访问到的团队近期 GitHub PR 评论，运行 /retro 为 CODING_STANDARDS.md 和自动化 Linter 创建更新建议（保证同一条人工 Review 意见永远不用写第二遍）
  ```
- **看不懂架构报告或复杂代码时让 AI 交互式教你**：
  在任意角色下输入：
  ```text
  /teach 给我讲讲这份报告里的深模块接缝（Seam）和局部性（Locality）是怎么回事
  ```

---

## 4. 常见问题（FAQ）

- **Q：怎么给每个角色（`architect`、`implementer`、`librarian` 等）单独配置不同的 LLM 模型？**
  **统一在根目录的 `opencode.json` 里的 `"agent"` 字段下按角色名配置**（不要去改 `.opencode/agents/*.md`，这样换模型时只需改一个 JSON 文件）：
  ```json
  {
    "model": "deepseek/deepseek-v4-pro",
    "small_model": "deepseek/deepseek-flash",
    "agent": {
      "pm":          { "model": "deepseek/deepseek-v4-pro" },
      "ba":          { "model": "deepseek/deepseek-v4-pro" },
      "architect":   { "model": "deepseek/deepseek-reasoner" },
      "implementer": { "model": "deepseek/deepseek-v4-pro" },
      "qa":          { "model": "deepseek/deepseek-v4-pro" },
      "reviewer":    { "model": "deepseek/deepseek-reasoner" },
      "librarian":   { "model": "deepseek/deepseek-flash" }
    }
  }
  ```
  配置后可在终端运行 `opencode debug agent <角色名>` 验证该角色生效的模型。

- **Q：`AGENTS.md` 和 `CODING_STANDARDS.md` 有什么区别？为什么分开？**
  - `AGENTS.md` 是**全局导航地图**（每个角色每轮对话都会加载，因此必须保持极简，只放仓库拓扑、构建/Linter/测试命令和路径指针，防止把上下文挤进 >150K 的「变笨区」）。
  - `CODING_STANDARDS.md` 是**评审标准与历史反例库**（编码时不塞给 `implementer`，专门在 `@reviewer` 执行 `/code-review` 时读取，并通过每次 `/retro` 把人类在 PR 里提过的意见沉淀进去——**「同一条人工 PR 评论绝不写第二遍」**）。

- **Q：别的同事更新了 `team-wiki`，我怎么同步到本地？**
  在 `team-sdlc-home` 根目录下运行：
  ```bash
  python3 scripts/wiki-search update --pull
  ```
  （Windows PowerShell 下运行 `.\scripts\wiki-search.ps1 update --pull`）。它会自动对 `repos/team-wiki` 执行 `git pull` 并使用 Python 内置的 SQLite FTS5 刷新本地 BM25 索引（零外部依赖）。

- **Q：我已经用旧版 setup 了一个项目，`home-doctor` 卡在 `.qmd/index.yml or index.sqlite is missing` 怎么无缝迁移？**
  无需重装项目！只需把新版模板里的 `scripts/wiki-search`（及 `scripts/wiki-search.ps1`、`scripts/wiki-search.cmd`、`scripts/home-doctor`）拷进你现有项目的 `scripts/` 目录，然后直接运行 `./scripts/home-doctor`（或 `python3 scripts/wiki-search update`），它就会自动生成兼容的 `.qmd/index.yml` 和 `.qmd/index.sqlite`，立即满血通过 `home-doctor`。

- **Q：工作台如何保证代码“不只是单测绿，而是真实拉起也能跑通”？（对用户透明的真机验证）**
  普通成员**不需要记住任何额外命令**。团队负责人在初始化阶段运行 `/project-setup` 时，可按提示由 `architect` 自动盘问代码库生成项目专属的真机验证配方（`.agents/skills/verify-<app>/`）。生成后，整套闭环对日常研发与 QA **完全透明**：
  - `implementer` 在提 PR 前会自动发现并运行匹配路径的真机验证，把动作、可见结果与持久化副作用证据落盘到 `.scratch/<JIRA-KEY>/evidence/` 并写入 PR；
  - `qa` 验收时会自动执行真机验证；若遇合法改版导致的验证地图过时，会自动触发维护流程修正（但若发现产品缺陷，严禁修改验证地图迎合 Bug，而是正常提缺陷单）；
  - `@reviewer` 会自动核查本次改动是否具备实跑证据。

- **Q：Windows 用户跑脚本报错或找不到命令怎么办？**
  - 在 **Git Bash** 下：直接跑 `./scripts/home-doctor`、`python3 scripts/wiki-search update` 和 `./repos/team-wiki/scripts/wiki-check`。
  - 在 **PowerShell / CMD** 下：运行配套的 Windows 包装脚本 `.\scripts\home-doctor.ps1`、`.\scripts\wiki-search.ps1` 和 `.\repos\team-wiki\scripts\wiki-check.ps1`。

- **Q：为什么我在改代码时，AI 报错说没有权限改 `tests/acceptance/`？**
  这是故意设计的物理隔离：`implementer` 角色被严格禁止修改任何验收测试和 E2E 测试（防止 AI 为了让测试通过而篡改测试断言）。验收测试只能切到 `qa` 角色修改。
