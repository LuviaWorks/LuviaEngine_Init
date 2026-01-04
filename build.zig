// LuviaEngine_Init - Built by Wang Shuai (LuviaWorks)
// Part of the LuviaEngine project.

const std = @import("std");
const Build = std.Build;

// re-export the shader compiler module for use by upstream projects
pub const shdc = @import("shdc");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ============================================================
    // 0. 获取 Zig 模块依赖 (sokol, zmath)
    // ============================================================
    const dep_sokol = b.dependency("sokol", .{ .target = target, .optimize = optimize });
    const dep_zmath = b.dependency("zmath", .{ .target = target, .optimize = optimize });

    // ============================================================
    // 1. 定义 [Core] 模块
    // ============================================================
    const mod_core = b.createModule(.{
        .root_source_file = b.path("luvia/core/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    // Core 依赖
    mod_core.addImport("zmath", dep_zmath.module("root"));

    // ============================================================
    // 2. 定义 [Render] 模块 (Main)
    // ============================================================
    const mod_render = b.createModule(.{
        .root_source_file = b.path("luvia/render/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod_render.addImport("sokol", dep_sokol.module("sokol"));
    mod_render.addImport("core", mod_core);

    // ============================================================
    // 3. 定义 [AI] 模块
    // ============================================================
    const mod_ai = b.createModule(.{
        .root_source_file = b.path("luvia/ai/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    // AI 依赖 Core
    mod_ai.addImport("core", mod_core);

    // ============================================================
    // 4. 定义 [UI] 模块 (Main)
    // ============================================================
    const mod_ui = b.createModule(.{
        .root_source_file = b.path("luvia/ui/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod_ui.addImport("core", mod_core);
    mod_ui.addImport("render", mod_render);
    mod_ui.addImport("ai", mod_ai);

    // ============================================================
    // 5. 定义 [Engine] 模块 (Main)
    // ============================================================
    const mod_engine = b.createModule(.{
        .root_source_file = b.path("luvia/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod_engine.addImport("core", mod_core);
    mod_engine.addImport("render", mod_render);
    mod_engine.addImport("ai", mod_ai);
    mod_engine.addImport("game", mod_ui);

    // ============================================================
    // 6. 定义 [Project] 模块 (Main)
    // ============================================================
    const app_project = b.createModule(.{
        .root_source_file = b.path("project/main.zig"), // 目前使用pet游戏项目作为启动项
        .target = target,
        .optimize = optimize,
    });
    app_project.addImport("engine", mod_engine);

    // ============================================================
    // 7. 自动扫描并编译 shaders
    // ============================================================
    const shader_step = try buildShadersAuto(b); // <--- 自动编译shader文件
    b.step("shader", "create shader files").dependOn(shader_step);

    // ============================================================
    // 8. 定义 [Exe] 可执行文件
    // ============================================================
    const exe = b.addExecutable(.{
        .name = "LuviaEngine",
        .root_module = app_project,
    });
    // 让 exe 的编译步骤依赖于 shader 的编译步骤
    // 这样每次 zig build run 时，zig 会先检查 shader 是否需要重编译
    exe.step.dependOn(shader_step);

    // ============================================================
    // 9. 链接环节 (调用辅助函数)
    // ============================================================

    // ============================================================
    // 10. 安装与运行
    // ============================================================
    b.installArtifact(exe);
    // 支持运行命令
    const run_cmd = b.addRunArtifact(exe); //创建一个“运行命令”
    run_cmd.step.dependOn(b.getInstallStep()); //在运行这个程序之前，必须先完成安装步骤
    if (b.args) |args| run_cmd.addArgs(args); //传递命令行参数
    const run_step = b.step("run", "Run the app"); //增加构建步骤，就是能使用 zig build run 的原因
    run_step.dependOn(&run_cmd.step); //绑定逻辑执行run_cmd
}

// ------------------------------------------------------------
// 自动扫描函数，用于自动编译所有找到的着色器文件
// ------------------------------------------------------------
fn buildShadersAuto(b: *std.Build) !*std.Build.Step {
    const shader_step = b.step("shader_auto", "Compile all found shaders");

    // 1. 定义 Shader 目录 (相对于 build.zig)
    const shaders_rel_path = "luvia/render/shaders";
    const absolute_shader_path = b.path(shaders_rel_path).getPath(b);

    // 2. 打开目录
    // 注意：这里是在构建配置阶段运行，使用 host 的文件系统
    // 1. 尝试打开目录 (使用构建系统的路径抽象)
    var dir = std.fs.cwd().openDir(absolute_shader_path, .{ .iterate = true }) catch |err| {
        std.debug.print("Error opening shader directory '{s}': {}\n", .{ shaders_rel_path, err });
        return shader_step; // 如果目录不存在，直接返回空步骤，或者你可以选择 error out
    };
    defer dir.close();

    // 3. 遍历目录
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        // 只处理文件
        if (entry.kind != .file) continue;

        // 只处理 .glsl 后缀的文件
        if (std.mem.endsWith(u8, entry.name, ".glsl")) {
            const filename = entry.name; // 例如 "triangle.glsl"

            // 构造输入输出路径
            // 注意：b.fmt 分配的内存在构建过程中有效
            const input_path = b.fmt("{s}/{s}", .{ shaders_rel_path, filename });
            // 输出文件名习惯： triangle.glsl -> triangle.glsl.zig
            const output_path = b.fmt("{s}/{s}.zig", .{ shaders_rel_path, filename });

            // 调用 shdc 编译
            const cmd_step = try shdc.createSourceFile(b, .{
                .shdc_dep = b.dependency("shdc", .{}),
                .input = b.path(input_path).src_path.sub_path,
                .output = b.path(output_path).src_path.sub_path,
                .slang = .{
                    .glsl430 = true,
                    .glsl310es = true,
                    .metal_macos = true,
                    .hlsl5 = true,
                    .wgsl = true,
                    .spirv_vk = true,
                },
                .reflection = true,
            });

            // 打印日志，让你知道扫到了哪些文件（可选，看起来很爽）
            std.debug.print("[AutoShader] Found: {s}, Compiled: {s}.zig\n", .{ filename, filename });

            // 将该文件的编译任务挂载到总任务上
            shader_step.dependOn(cmd_step);
        }
    }

    return shader_step;
}
