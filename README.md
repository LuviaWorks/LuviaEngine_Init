# LuviaEngine_Init

**LuviaEngine_Init** 是 LuviaEngine 游戏引擎的高性能构建基座。它定义了引擎的核心模块化架构，并集成了全自动的跨平台着色器编译流水线。

---

## 核心特性

* [cite_start]**自动化 Shader 编译**：基于 `sokol-shdc` 的全自动扫描机制，支持将 `.glsl` 编译为 Zig 后端代码。
* [cite_start]**模块化架构**：预置了 `Core`、`Render`、`AI`、`UI` 等解耦模块定义。
* [cite_start]**现代 Zig 构建系统**：完全适配 Zig 0.15.2+ 的包管理机制（`build.zig.zon`）。 

## 项目定位

本项目为 **LuviaEngine** 的开源脚手架版本，旨在为 Zig 开发者提供工业级的工程起点。

## 快速开始

1. 确保已安装 Zig 编译器。
2. 克隆仓库：`git clone https://github.com/LuviaWorks/LuviaEngine_Init`
3. 执行构建并运行示例：
   ```bash
   zig build run
   
