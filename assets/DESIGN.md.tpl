# <项目名>（<别名>）· 方案设计

<!-- 本文件是 handoff/DESIGN.md；指项目根文件用 ../。不适用节可删。 -->

> <一句话：设计目标 / 范围>
> 文档表见 [CONTEXT.md](CONTEXT.md)。
> 最近更新：YYYY-MM-DD

## 1. 目标与约束

## 2. 运行模式与拓扑

```mermaid
flowchart LR
  A[入口] --> B[核心]
  B --> C[存储]
```

## 3. 核心流程

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
