---
name: create-verification-skill
description: Interview repos/* to generate a project-local live verification skill (.agents/skills/verify-<app>/SKILL.md) and feature map (features/*.md) with Launch, Doctor, Drive, Evidence, Cleanup, and Helpers, then prove it end-to-end once before handoff. Use during /project-setup or when adding live runtime verification for a runnable app/service surface.
---

# create-verification-skill

生成一个**项目专属的真机运行验证技能**（落点：`.agents/skills/verify-<app>/`），让后续的 `implementer`、`qa` 与 `reviewer` 无需再靠猜或只靠静态单测，而是能按确定性配方**拉起真实运行环境 → 健康自检 → 像真实用户一样驱动 → 采集可见结果与持久化副作用证据 → 清理进程但保留证据**。

> **设计原则（Non-Bespoke & 零噪音）**：本技能本身不绑定任何特定语言、框架或中间件；所有启动命令、端口、迁移步骤、驱动方式均通过**现场盘问 `repos/*` 代码库**得出。生成的技能写给“第一次见这个项目的冷启动 Agent”阅读，必须无占位符、可直接执行。

## 1. 盘问代码库（Interview the repo, not the user）

先读取 `AGENTS.md` 与目标 `repos/*` 子仓（构建清单、入口文件、路由/命令定义、环境配置样例、迁移/初始化脚本、既有测试工具），只把代码库里确实无法观测的信息（如外部测试账号、内网受限边界）拿来向人确认：

1. **识别用户交互面（User Surface）**：Web UI、HTTP/RPC API、CLI/TUI，还是异步工作流/状态编排服务？
2. **确定隔离运行分级（适配企业内网现实）**：
   - **优先（Tier 1 — 本地隔离实例）**：单条命令即可从干净数据目录/独立端口拉起应用及其本地依赖（含数据迁移与幂等 Seed，外部云/第三方服务走本地模拟器或受控 Stub，严禁直连共享生产或多人共用的脏环境）。
   - **备选（Tier 2 — 单服务边界隔离）**：当上游依赖过多无法全量本地拉起时，拉起本服务真实进程，仅在既定外部边界启用受控测试替身，并在 `Gotchas` 中如实声明边界假设。
   - **兜底（Tier 3 — 受控只读/安全靶场）**：若企业环境完全禁止本地启动，则明确目标测试环境地址、幂等清理规则与严禁触碰的写操作边界。
3. **识别非确定性控制杠杆（Build the Lever）**：若应用包含非确定性外部依赖（如外部模型推理、第三方回调、随机调度），优先发现或建议在测试启动模式下暴露**确定性驱动开关/录制回放模式**，验证真实编排、持久层写入与回滚，而不被外部波动卡死门禁。

## 2. 生成项目级验证技能（`.agents/skills/verify-<app>/SKILL.md`）

文件必须包含完整 frontmatter（`name: verify-<app>` 与清晰触发 `description`）以及强制 6 节：

1. **Launch（拉起与真就绪）**：
   - 给出从工作台根目录（`home/`）免 `cd` 可执行的启动命令，以及**真就绪信号**（不只是端口监听成功，必须确认数据迁移/Seed 完成、依赖存储可读写）。
2. **Doctor（只读健康自检）**：
   - 一条快速只读命令，检查进程归属、构建版本、端口占用、数据迁移版本、存储连通性与必要环境变量。**任何驱动前先跑 Doctor；任何驱动异常后先跑 Doctor**。
3. **Drive（真实路径驱动）**：
   - 给出真实可复用的交互指令，优先使用稳定定位符（语义标签、显式测试标识、真实路由/CLI 命令），严禁依赖脆弱坐标、绕过校验的内部 Setter 或测试专供后门接口。
4. **Evidence（动作 + 结果 + 副作用留证）**：
   - 证据统一落盘至 `.scratch/<JIRA-KEY>/evidence/verify-<app>/`（初始化自证阶段落盘至 `.scratch/_verify/verify-<app>/`）。
   - 必须同时记录三类证据：① **触发动作**；② **可见输出**（响应体/截图/终端输出）；③ **真实副作用**（持久化存储目标记录变化、缓存状态/过期策略、服务日志无未捕获异常或 5xx）。
   - **Able to Fail（红灯可证）**：若使用 dry-run 或测试模式，必须核验它实际跳过了什么，绝不轻信名称。
5. **Cleanup（精准清理，永不毁证）**：
   - 只终止本次运行亲手拉起的进程/容器（记录 PID 或实例 ID，严禁按进程名粗暴 `killall`）。
   - 清理临时进程与临时数据，**严禁删除 `.scratch/**/evidence/**` 下的证据文件**。
6. **Helpers（上下文友好型辅助脚本）**：
   - 将冗长的启动、健康检查、副作用采样封装为可执行 Helper 脚本（放在 `.agents/skills/verify-<app>/scripts/`），在 `SKILL.md` 正文写明精确调用方式。
   - **省 Token 铁律**：Helper 输出紧凑的结构化结果（如 10 行以内摘要或 JSON），完整长日志重定向到证据目录，避免把主代理上下文撑出 `<150K` 聪明区。

## 3. 播撒功能地图（Feature Map）

创建 `.agents/skills/verify-<app>/features/README.md` 索引，以及 3–5 个最高频用户核心流程文件（`features/<feature-slug>.md`）。每个功能文件从**真实用户视角**包含 4 个 H2 章节：

- `## Sub-features`：涵盖的子路径与关键状态边界
- `## How to get to it (user POV)`：用户如何进入该功能及前置条件
- `## Driving it with <harness>`：驱动步骤与证明其生效的可观测终态（含副作用核对）
- `## Gotchas`：已知环境坑、缺失 Seed 前置条件与隔离注意事项（**前置条件缺失必须如实报错并记录于此，严禁削弱验证步骤来凑绿**）

## 4. 交付前必须现场跑通自证（Prove It Before Handing Over）

**从未实际执行过的验证技能只是草稿，不是交付物。** 生成后必须按技能自身文档从头到尾真跑一遍：

1. 执行 **Launch** → **Doctor**；
2. 驱动地图中的至少 **1 条核心 Feature**；
3. 采集 **Evidence** 到 `.scratch/_verify/verify-<app>/`；
4. 执行 **Cleanup**；
5. **复核证据存活**：确认 Cleanup 之后，证据文件仍完整保留在指定路径，且没有遗留孤儿进程或占用端口。
6. 若自证过程暴露脚本或文档缺陷，现场修复并跑完 Cleanup 后重测，直到一次完整闭环通过。

## 5. 收尾回报

向用户报告：生成的技能路径、覆盖的隔离分级与假设（明确列出未覆盖的外部边界）、实跑自证的证据路径。提醒后续若业务改版导致校验漂移，`qa` 会在验收期间自动触发 `maintain-verification-skill` 协同修复。
