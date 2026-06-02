# AI Development Base — 使用指南

> OpenSpec + Superpowers + Claude Code 融合的 AI 原生研发工作流基座

---

## 这是什么

AI Development Base 是一套**面向产研团队的标准化 AI 开发基础设施**。它将 OpenSpec（规格标准 + 变更管理）、Superpowers（流程骨架）和 Claude Code（执行引擎）融合为一个完整的研发工作流，覆盖从需求定义到代码交付的全生命周期。

**核心理念**：每个功能变更都是一个 OpenSpec Change，经历 Discover → Plan → Execute → Verify → Release 五个阶段，每个阶段有自动化 Gate 把关，严禁跳过。

---

## 架构总览

```
第一层 — OpenSpec Core（大脑）
  规格标准：PRD · API · Design · Test · Release
  变更管理：propose → review → implement → verify → archive

第二层 — Superpowers 流程骨架（脊椎）
  Discover → Plan → Execute → Verify → Release

第三层 — 可插拔能力模块
  Skill / MCP / Hook / Gate

第四层 — Agent 执行层
  并行调度 · Git Worktree 隔离 · 会话独立
```

---

## 快速开始

### 前置条件

本基座依赖以下组件，部分需要提前安装：

| 组件 | 用途 | 适用级别 | 安装方式 |
|------|------|---------|---------|
| **Claude Code** | AI 执行引擎 | 全部 | `npm install -g @anthropic-ai/claude-code` |
| **OpenSpec CLI** | 规格管理 | L1+ | `npm install -g @fission-ai/openspec` |
| **Superpowers Plugin** | 流程技能（brainstorming/writing-plans/TDD 等） | L1+ | 在 Claude Code 中: `/plugin install superpowers@claude-plugins-official` |
| **Figma Plugin** | 设计稿读取 | L2+ | `/plugin install figma@claude-plugins-official` |
| **TypeScript LSP MCP** | TS 类型检查与诊断 | L1+ | `npm install -g ts-language-mcp && claude mcp add --scope user typescript-lsp -- npx -y ts-language-mcp` |
| **Serena MCP** | 代码库语义分析 | L1+ | `uv tool install -p 3.13 serena-agent@latest --prerelease=allow && serena setup claude-code` |
| **Playwright MCP** | E2E 测试与浏览器自动化 | L2+ | `claude mcp add --scope user playwright -- npx @playwright/mcp@latest` |
| **Pencil MCP** | 原型设计（备选） | L2+（可选） | VS Code 中安装 Pencil 扩展即可 |
| **gitleaks** | 密钥泄露扫描 | L3 | `brew install gitleaks` |
| **semgrep** | 安全静态分析 | L3 | `pip install semgrep` |
| **oasdiff** | API 契约变更检测 | L2+ | `go install github.com/tufin/oasdiff/cmd/oasdiff@latest` |

> **提示**：不确定自己需要装什么？直接运行 `/onboard`，选完角色和级别后会给出针对性的安装清单。

### 接入步骤

**方式一：全新项目**

将此仓库克隆或复制到你的项目目录，然后在 Claude Code 中输入：

```
/onboard
```

交互流程：选择语言 → 选择角色 → 确认项目状态 → 选择启用级别（L0-L3），基座自动完成配置。

**方式二：已有项目接入**

将以下目录复制到你的项目根目录：

```bash
cp -r .claude/ .githooks/ .gitleaks.toml specs/ /path/to/your/project/
```

然后在项目目录的 Claude Code 中输入 `/onboard`。

---

## 角色入口

| 角色 | 主要工作 | 入口命令 | 涉及阶段 |
|------|---------|---------|---------|
| **产品经理 / 设计师** | 定义需求、产出 PRD spec | `/discover [想法]` | Phase 1 |
| **开发工程师** | 执行实现、TDD 开发 | `/execute` | Phase 2-5 |
| **全栈独立** | 全流程一肩挑 | `/onboard` → `/discover` | Phase 1-5 |
| **维护 / 值班** | 紧急修复、诊断 | `/hotfix` 或 `/diagnose` | L0-L1 |

---

## 启用级别（L0-L3）

| 级别 | 适合谁 | 能力范围 |
|------|--------|---------|
| **L0 Hotfix** | 任何人 | `/hotfix` + `/diagnose`，零配置，无 Gate |
| **L1 Light** | 独立开发者 | 核心 skill（TDD、code-review、verification），pre-commit hooks，TS LSP + Serena |
| **L2 Standard**（推荐） | 产研团队 | 全 skill 链 + 4 MCP + CI gates + 并行 Agent |
| **L3 Full** | 企业级 | L2 全部 + 质量指标 M1-M5 + Feedback Loop 经验沉淀 |

随时可通过 `/onboard` 重新选择级别。

---

## 五阶段生命周期

```
Phase 0 ──▶ Phase 1 ──▶ Phase 2 ──▶ Phase 3 ──▶ Phase 4 ──▶ Phase 5
 (初始化)    (Discover)   (Plan)     (Execute)   (Verify)   (Release)
    │            │           │           │           │           │
    ▼            ▼           ▼           ▼           ▼           ▼
 openspec    /discover   writing-    /execute   verification  /close-phase
 init        产出 PRD    plans       TDD 循环    + 7步验证    openspec
 部署配置    spec        产出 plan   逐任务实现   gate 检查    archive
 激活 hooks              + 并行 spec                        更新 CLAUDE.md
```

### Phase 0：项目初始化

运行 `/onboard`，自动执行 `openspec init` + 部署 `.claude/` 配置 + 激活 `.githooks/`。

### Phase 1：Discover

输入 `/discover [想法]`，brainstorming 激活，产出 PRD spec → `specs/prd/<change-id>.md`。

**Gate：** PRD 完整性 + 可测试性，缺一不进下一阶段。

### Phase 2：Plan

自动或手动进入。`writing-plans` 读取 PRD spec，拆解为任务 DAG，并行产出 API 契约、设计 spec、测试策略。

**Gate：** 任务粒度 + 依赖无循环 + Spec 对齐。

### Phase 3：Execute

输入 `/execute`。TDD 铁律逐任务循环：写测试→红灯→最小实现→绿灯→重构→`openspec diff` 检查偏离→提交。

L2+：就绪任务自动并行执行（独立 Agent + 独立 worktree）。

**Gate：** TDD Gate + File Scope Gate + Spec Drift Gate。

### Phase 4：Verify

自动进入。七步验证：Contract → Security → Smoke Test → Visual Regression → 全量诊断 → Code Review → `openspec validate`。

**Gate：** 5 个 Gate 全部通过。

### Phase 5：Release

输入 `/close-phase`。前置条件全过 → Migration Journal 萃取 → `openspec archive` → 更新 CLAUDE.md → 清理。

**产出：** `archive/<change-id>/` 完整可追溯变更历史。

---

## 斜杠命令速查

| 命令 | 说明 | 适用级别 |
|------|------|---------|
| `/discover [想法]` | Phase 1 入口，产出 PRD spec | L2+ |
| `/execute` | Phase 3 入口，TDD 实现循环 | L1+ |
| `/hotfix [问题]` | 紧急修复（≤3 文件、无新 API/DB 变更） | L0+ |
| `/diagnose` | 只读健康审计（9 类检查） | L0+ |
| `/close-phase` | Phase 5 归档，知识萃取 + openspec archive | L1+ |
| `/onboard` | 交互式初始化，角色+级别路由 | 全部 |

---

## Skill 快捷指令参考

除基座自带的 6 个斜杠命令外，还可通过以下快捷指令直接调用 Superpowers 和 OpenSpec 的 Skill。

### Superpowers Skills

来自 `superpowers` 插件，使用格式：`/superpowers:<skill名>`

| 快捷指令 | 说明 | 对应阶段 |
|---------|------|---------|
| `/superpowers:brainstorming` | 结构化需求探索 — 创建功能/组件/行为修改前必用 | Phase 1 |
| `/superpowers:writing-plans` | PRD → 可执行任务 DAG，多步骤实现前使用 | Phase 2 |
| `/superpowers:executing-plans` | 在独立会话中按拓扑顺序执行实现计划 | Phase 3 |
| `/superpowers:test-driven-development` | TDD 铁律 — 实现任何功能或修复 bug 前使用 | Phase 3 |
| `/superpowers:subagent-driven-development` | 多 Agent 并行执行独立任务 | Phase 3 |
| `/superpowers:dispatching-parallel-agents` | 2+ 独立任务的并行调度 | Phase 3 |
| `/superpowers:using-git-worktrees` | 创建隔离的 Git Worktree 工作空间 | Phase 3 |
| `/superpowers:systematic-debugging` | 系统化调试 — 遇到任何 bug 或测试失败时使用 | Phase 3-4 |
| `/superpowers:verification-before-completion` | 证据优先 — 声称工作完成前必须验证 | Phase 4 |
| `/superpowers:requesting-code-review` | 完成主要功能后，合并前发起代码审查 | Phase 4 |
| `/superpowers:receiving-code-review` | 收到 Code Review 反馈后，严谨评估再实施 | Phase 4 |
| `/superpowers:finishing-a-development-branch` | 合并策略决策（merge/squash/rebase）+ 集成 | Phase 5 |
| `/superpowers:writing-skills` | 创建、编辑或验证自定义 Skill | Phase 0 |
| `/superpowers:using-superpowers` | 会话启动引导 — 建立 Skill 发现与使用规则 | — |

### OpenSpec Skills

项目级 Skill，定义在 `.claude/skills/openspec.md`，使用格式：`/openspec:<操作>`

| 快捷指令 | 说明 | 对应阶段 |
|---------|------|---------|
| `/openspec:init` | 初始化 `specs/` 目录结构与标准模板 | Phase 0 |
| `/openspec:validate` | 验证 Spec 文件的格式完整性与 Schema 合规性 | Phase 1-4 |
| `/openspec:diff` | 检测实现代码与 Spec 之间的偏离（LOW/MEDIUM/HIGH） | Phase 3 |
| `/openspec:archive` | 归档已完成的变更到 `archive/<change-id>/` | Phase 5 |

> **提示**：这些 Skill 也可由 Claude 在合适场景下自动激活，无需手动调用。手动调用适合需要强制执行特定流程时。

---

## Hook 系统

| 层 | 内容 | 工具 | 成熟度 |
|----|------|------|--------|
| **L1 代码卫生** | format · lint · type-check · secret scan · test · security · contract | Prettier/ESLint/tsc/gitleaks/semgrep/oasdiff | 成熟 |
| **L2 AI 安全** | TDD gate · spec drift · file scope · permission boundary | openspec diff / Claude Code 原生 | 快速成熟中 |
| **L3 智能演化** | 质量指标 · Feedback Loop · 频率驱动规则升级 | 自定义 | 前沿 |

---

## 文件清单

### 核心基座文件

| 文件/目录 | 类型 | 说明 |
|----------|------|------|
| `.claude/WORKFLOW.md` | 流程手册 | 完整的五阶段流程说明、Gate 清单、Skill/MCP 映射 |
| `.claude/settings.json` | 配置文件 | 权限声明、L0-L3 级别定义、阶段→Skill→Gate 映射 |
| `.claude/skills/openspec.md` | Skill 定义 | OpenSpec 操作的 Skill 封装（init/validate/diff/archive） |
| `.claude/commands/` | 命令定义 | 6 个斜杠命令（discover/execute/hotfix/diagnose/close-phase/onboard） |
| `.claude/reference/` | 参考文档 | 按需读取：spec-drift-guide + 6 种 test-strategies |
| `.githooks/` | Git Hook | pre-commit / commit-msg / pre-push + 共享脚本库 |
| `.githooks/lib/gates.sh` | Gate 引擎 | 17 个质量 Gate 函数 + run_phase_gates 调度器 |
| `.githooks/lib/l2-checks.sh` | AI 安全层 | spec drift / file scope / permission / destructive op 检测 |
| `.gitleaks.toml` | 安全配置 | 密钥扫描规则与白名单 |
| `specs/` | 规格模板 | PRD / API / Plan / Design / Test / Release 的 OpenSpec 模板 |

### 非基座文件（说明性）

| 文件/目录 | 类型 | 说明 |
|----------|------|------|
| `README.md` | 说明文档 | 语言切换入口（中/英） |
| `README.zh.md` | 说明文档 | 中文使用指南（本文件） |
| `README.en.md` | 说明文档 | 英文使用指南 |
| `docs/superpowers/specs/` | 设计文档 | 本基座的设计规格文档（归档参考） |
| `docs/superpowers/plans/` | 实施计划 | 本基座的实施计划文档（归档参考） |
| `archive/` | 历史归档 | 已完成变更的完整记录，由 `/close-phase` 自动写入 |
| `.gitignore` | Git 配置 | 忽略规则 |

---

## 常见问题

**Q: 我已有项目，接入会影响现有代码吗？**
接入只添加 `.claude/`、`.githooks/`、`specs/` 等目录，不修改你的任何源代码。

**Q: 可以只用部分功能吗？**
可以。选择 L1 只启用核心 hooks + 少量 skill；L0 连 Gate 都不启用。随时 `/onboard` 调整。

**Q: 多人团队怎么协作？**
每人本地部署基座文件。OpenSpec change 与 Git branch 同生命周期，spec 族随代码一起提交，团队共享。

**Q: 我的 skill 没装全怎么办？**
运行 `/diagnose` 查看缺失项和安装命令。不影响已安装 skill 的正常使用。

---

## 版本

v1.0.0 — 2026-05-08
