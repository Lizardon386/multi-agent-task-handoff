# <任务目录名>（<别名>）· 方案设计

<!-- 没有别名就写 # <任务目录名> · 方案设计。不适用节可删。 -->

> <一句话：设计目标 / 范围>
> 最近更新：YYYY-MM-DD

## 文档

| 文档 | 阅读对象 | 内容 |
|---|---|---|
| [README.md](README.md) | 使用者 | 这是什么、怎么跑、限制 |
| [DESIGN.md](DESIGN.md) | 评审 / 开发 | 本文件 |
| [CONTEXT.md](CONTEXT.md) | 接手 agent | 当前状态、下一步、坑、验证 |

## 1. 目标与约束

## 2. 运行模式与拓扑

```mermaid
flowchart LR
  A[入口] --> B[核心]
  B --> C[存储]
```

## 3. 核心流程

<!-- 有时序交互用 sequenceDiagram；没有就用 flowchart。 -->

```mermaid
sequenceDiagram
  participant A as 调用方
  participant B as 系统
  A->>B: 请求
  B-->>A: 结果
```

## 4. 架构与关键接缝

### 4.1 包 / 目录结构

```text
<只列到包/工具目录一级，不列 src 内部文件；每节点一句说明>
```

### 4.2 关系图

```mermaid
flowchart LR
  P1[包 A] --> P2[包 B]
```

### 4.3 关键接口 / 接缝

## 5. 数据、协议与接口

## 6. 开发与构建

## 7. 关键设计决策

| 决策 | 理由 | 代价 |
|---|---|---|
|  |  |  |

## 8. 已定语义与边界

## 9. 工程约束
