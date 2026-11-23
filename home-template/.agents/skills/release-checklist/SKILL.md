---
name: release-checklist
description: Scan the git diff across the affected repos/* and produce a release checklist covering shared-library version and binary compatibility, downstream dependency alignment, and the bottom-up release/rollback order. Use before raising a PR or when standing in for SRE.
---

# release-checklist

补位无 SRE：提 PR 前扫一遍本次改动涉及的所有子仓 `git diff`，产出可直接贴进 PR 的检查单。

拓扑、共享库坐标、构建与发布顺序一律从 `AGENTS.md` 读，**不要凭记忆假设**（本项目可能根本没有共享库或数据库，那就写 `不适用`）。先跑 `git -C repos/<repo> status` / `git -C repos/<repo> diff` 拿实际改动。

检查结论只有三种：`OK` / `需处理` / `不适用`，每条都要写依据（文件、行、命令输出）。

## 1. 共享库版本号与二进制兼容（最容易炸的一环）

适用于任何被下游依赖的 `shared-lib` 仓（库、SDK、共享包）：

- 看公共 API 变了什么：
  - 只新增类型/方法/枚举值 → 可保持版本号，但在 PR 说明里写"只加不改"。
  - 改/删既有签名、数据类字段、枚举常量名、共享校验规则（金额精度、舍入、错误码语义）→ **不兼容**：必须升版本号，并在 PR 写明迁移方式。
  - 改了共享错误码的语义或 HTTP/传输层映射 → 所有下游的映射与前端展示都要同步，属跨层契约变更，必须逐条列出。
- 校验"只加不改"是否真成立：`git -C repos/<lib> diff --stat` 里出现删除行就要逐条确认是不是签名/语义变更。
- 确认共享库**本次产物**已构建并安装/发布到下游能解析到的地方（否则下游测的是旧版本，假绿）。

## 2. 下游各层依赖声明版本对齐

- 列出所有声明了共享库版本的依赖清单文件，确认版本**完全相同**且等于共享库自身声明的版本。
- 只改了一两个 → 判 `需处理`：版本漂移会让某层跑到旧类型，编译能过、运行时字段缺失。
- 空版本、范围版本（如 `1.x`）、可被覆盖的开发期版本（含 `-SNAPSHOT` / `-dev` 一类后缀）一律不接受。

## 3. 发布顺序与回滚顺序（自底向上发布，反向回滚）

发布顺序 = `AGENTS.md` 第 3 节的顺序（共享库 → 各 `service` 按调用方向由下往上 → `ui` → `e2e` 验收放行）。
回滚顺序 = **严格反向**；共享库最后回滚，且仅当所有下游都已回退到不依赖新版本的代码之后。

- 每条都要回答：**新旧版本能否同时在线**（滚动发布窗口内）。不能 → 必须停机窗口或加兼容层，写进检查单。
- 新增/变更的环境变量、端口、外部依赖地址：列名字 + 默认值 + 谁负责配置；端到端脚本里的端口/就绪探测若变了要同步。
- DB migration：本项目若无持久化层，写 `不适用`；一旦引入持久化，必须回来补迁移与回滚脚本。

## 4. 可观测与冒烟

- 各服务是否保留健康检查端点；改了路由或端口要更新端到端脚本的就绪探测。
- 冒烟命令：用 `AGENTS.md` 第 3 节的端到端测试命令，失败即阻断发布。
- 关键日志/埋点若新增，列出字段与用途；无则写 `不适用`。

## 5. 输出

- `implementer`：把检查单写入 `.scratch/<JIRA-KEY>/release-checklist.md`，并把勾选块贴进每个受影响仓的 PR 描述（含 `Jira-Key`、`home@<version>`）。
- `reviewer`：你只能写 `.scratch/<JIRA-KEY>/review.md`，把本节结论作为 review 的"SRE 补位"一节写入，不要另建文件。
- 任一条 `需处理` 未闭环 → 明确写"不得合并"，并列出闭环所需动作与责任人。
