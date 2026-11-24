---
name: maintain-verification-skill
description: Event-driven audit and upkeep pass for an existing project-local verification skill (.agents/skills/verify-*/): checks source code against the feature map, executes a live verification pass, and strictly classifies findings as doc drift, harness gap, or product regression. Use when live verification fails due to suspected feature drift or after major user-surface refactors.
---

# maintain-verification-skill

随着业务演进，项目专属的真机验证技能（`.agents/skills/verify-<app>/`）和功能地图（`features/*.md`）会逐渐过时。本技能用于在**发生验收漂移或重大界面/接口改版时**按需巡检并修复验证技能，使其始终诚实可靠。

## 结果三选一（Outcomes）

每次执行结束必须明确报告以下三种结论之一：
- **`clean`**：所有 Feature 的源码核对与真机实跑均一致，无需改动。
- **`changed`**：已修复经实跑验证的文档漂移或 Harness 缺口（仅限 `.agents/skills/verify-<app>/**` 目录内）。
- **`blocked`**：因环境前置条件、权限或产品缺陷阻断，如实列出阻断原因与已覆盖范围。

## 严格编辑边界（Edit Scope）

- **只允许修改目标验证技能自身目录**（`.agents/skills/verify-<app>/SKILL.md`、`features/*.md` 及其自带的 `scripts/`）。
- **严禁在维护过程中修改任何业务产品代码**（`repos/*` 下的生产代码）。
- **绝不向 Bug 妥协**：如果地图描述的预期行为在现网代码里失效了，必须先判定是「合法需求改版导致的文档漂移」还是「产品回归缺陷（Regression）」——**若属于产品缺陷，严禁修改 Feature Map 去迎合错误行为，必须直接报出产品缺陷**。

## 执行步骤

### 0. 定位目标
扫描 `.agents/skills/verify-*/SKILL.md`。若有多个候选，结合当前改动涉及的子仓自动匹配（无法自动确定时再询问用户）；若不存在任何 `verify-*` 技能，停止并提示先通过 `create-verification-skill` 生成。

### 1. 索引清洁度检查（Index Hygiene）
核对 `features/README.md` 与同目录 `features/*.md` 文件列表，修补漏登、多余、重复或死链条目。

### 2. 源码核对（Source Audit）
逐个对照 `features/*.md` 与对应 `repos/*` 的最新源码（路由、命令、状态机、错误码）：
- 标出每条 Feature 疑似漂移的具体源码文件与行号；
- 扫描近期变更中新增但尚未进入 Feature Map 的重要用户交互面（必须给出具体源码路径，不可凭空臆测）。

### 3. 真机实跑（Live Pass）
即使源码看起来一致，也必须按该 `verify-<app>` 技能自身的 **Launch** 模式执行实跑验证，并全程死守三条不变量：
1. **Doctor 先行与故障复位**：首次驱动前必跑 Doctor；任一驱动失败后必重跑 Doctor；若进程健康但状态卡死，按技能规则重置状态或重启实例，严禁带病继续驱动。
2. **证据永不丢失**：每次清理后核验已采集的证据文件仍在指定路径。
3. **零残留进程**：无论成功还是中途失败，结束前必须执行完整 **Cleanup**，不遗留孤儿进程、容器或占用端口。

### 4. 严格三分类处置（Triage）
- **文档漂移（Doc/Map Drift）**：产品行为经核实已合法变更，但地图或步骤过时 → 更新 `features/*.md` 或 `SKILL.md`。
- **工具缺口（Harness Gap）**：产品行为正常，但验证脚本/定位符无法驱动 → 修复 Helper 脚本或 `Drive` 配方，**且必须重新真机跑通该条 Feature 验证修复有效**。
- **产品缺陷（Product Regression）**：产品实际行为坏了 → **严禁改动验证地图来凑绿**！保留失败证据路径，在报告（或 `.scratch/<JIRA-KEY>/qa-report.md`）中作为产品缺陷报出，交由 QA 按正常缺陷流程提单。

### 5. 回报
简洁汇报本次 `outcome`（`clean` / `changed` / `blocked`）、覆盖的 Feature 列表、不可达前置条件（若有）、已确认的漂移修复清单或产品缺陷清单。运行过程临时笔记放在 `.scratch/` 下，不要提交进代码仓。
