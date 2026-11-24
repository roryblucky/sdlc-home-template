# Domain Docs

How the engineering skills should consume this project's domain documentation.

> **提示**：首次接入新项目时，请运行 `/project-setup` 由 `architect` 根据 `repos/*` 子仓拓扑与 `repos/team-wiki/` 更新本文件。

## 权威来源（按优先级）

1. `AGENTS.md`：当前项目子仓拓扑、调用链、接口契约、共享公共库与构建/测试约定。
2. `.scratch/<JIRA-KEY>/spec.md`：本单业务口径（跨人共享走 Jira 父 Story）。
3. `repos/team-wiki/`：
   - `GLOSSARY.md`：长期术语的权威来源（含 `_Avoid_` 禁用同义词列）
   - `index.md`：全库页面自动索引目录树
   - `domains/`：按业务域聚合的核心规则与不变量契约
   - `standards/`：跨仓公共技术规范（API、错误码、数据命名、安全等）
   - `designs/`：跨服务架构设计（RFC / System Design）
   - `adr/`：跨仓架构决策记录（Architecture Decision Records）
   - `runbooks/`：发布/回滚/排障手册
   - `postmortems/`：线上故障复盘与防复发项
   - `onboarding/`：团队服务导览与环境指引
   - **检索方式**：先读 `repos/team-wiki/index.md` 导航，或在 `home/` 根目录用 `python3 scripts/wiki-search "<关键词>"` 检索（零依赖 Python 内置 SQLite FTS5 BM25，无需安装第三方包或模型），再读命中页。
   - 知识库与 `spec.md` 冲突时：文档表述长期规则的以 wiki 为准，单次需求口径以已确认的 `spec.md` 为准，两者冲突必须在产物里显式报出并交回 `ba` 澄清。
   - 改知识库走 `@librarian` 的新分支 + Draft PR，**任何角色都不要直写 `main`**。

## 用术语表说话

输出里提到领域概念（Story 标题、方案、假设、测试名）时，一律使用 `repos/team-wiki/GLOSSARY.md` 中的标准词汇，不要自造同义词。

若需要的概念不在术语表里：记进 `.scratch/<JIRA-KEY>/spec.md` 第 3 节「待沉淀术语/规则」，最终由 `@librarian` 用 `domain-modeling` + `/wiki-ingest` 提进 `repos/team-wiki/`。

## 与 ADR 冲突要说出来

输出与既有 ADR 矛盾时显式指出，不要静默覆盖（ADR 在 `repos/team-wiki/adr/`）：

> _Contradicts ADR-NNNN (<标题>), 但值得重开，因为…_
