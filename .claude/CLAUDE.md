# Aiit 基座

## 概述
Aiit — AI 开发基座，提供 OpenSpec 变更管理、阶段守卫、自动化归档等工程化能力。

- **语言**：Node.js / TypeScript
- **分发**：npm CLI（`npm install -g aiit-base`）
- **交互语言**：中文（所有交互使用中文）

## 可用命令
| 命令 | 用途 |
|------|------|
| `/discover` | 将想法转化为结构化 OpenSpec PRD 规格 |
| `/execute` | 按拓扑顺序执行计划任务（TDD 铁律） |
| `/hotfix` | 紧急修复（最小范围，L0 模式） |
| `/diagnose` | 系统健康审计（OpenSpec、Gates、Skills、MCP） |
| `/close-phase` | 压缩阶段知识到迁移日志，归档并清理 |
| `/onboard` | 交互式渐进配置 |

## 活跃变更

暂无活跃变更。运行 `/discover "你的想法"` 来创建新的变更。

## 约束
- **严禁跳过 Gate**：所有阶段 gate 必须通过
- **TDD 要求**：是（实现代码必须有对应测试文件）
- **并行 Agent**：是
- **文件范围强制**：是（变更文件必须在计划范围内）
- **规格漂移检测**：是
- **质量指标收集**：是
- **反馈闭环**：是
- **自动归档**：是

## 可用 MCP 服务器
| MCP | 用途 |
|-----|------|
| Playwright | 浏览器自动化 / E2E 测试 |
| Figma | 设计稿读取与图片导出 |
| Serena | 语义代码分析与编辑 |
| TypeScript LSP | TypeScript/JavaScript 语言智能 |
| Pencil | .pen 设计文件编辑 |

## 可用 Skills
| Skill | 触发场景 |
|-------|----------|
| brainstorming | 任何创造性工作之前（功能、组件、行为修改） |
| writing-plans | 有规格或需求，需多步骤实现前 |
| executing-plans | 在独立会话中执行实现计划 |
| TDD | 实现任何功能或 bug 修复前 |
| subagent-driven-development | 执行有独立任务的实现计划 |
| dispatching-parallel-agents | 2+ 独立任务可并行处理 |
| code-review | 完成主要功能，合并前验证 |
| verification-before-completion | 声称工作完成、修复、通过前 |
| finishing-a-development-branch | 实现完成，所有测试通过后 |
| systematic-debugging | 遇到任何 bug、测试失败、异常行为 |
| receiving-code-review | 收到 code review 反馈后 |
| using-git-worktrees | 需要隔离工作空间时 |