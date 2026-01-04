// # 引擎总入口（Facade），负责导出所有子模块
pub const core = @import("core");
pub const ai = @import("ai");
pub const render = @import("render");
pub const platform = @import("platform");

const std = @import("std");
const RndGen = std.Random.DefaultPrng;
const math = core.math;

const sokol = render.sokol;
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;

export fn init() void {}

export fn update() void {}

export fn draw() void {}

export fn cleanup() void {}

export fn event(ev: [*c]const sapp.Event) void {
    _ = ev;
}

// 【启动 引擎】
pub fn run() void {
    // 启动 Sokol 循环
    sapp.run(.{
        .init_cb = init,
        .frame_cb = update,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .window_title = "Luvia Engine - 2DGS",
        .width = 1600,
        .height = 1000,
        .fullscreen = false,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = slog.func },
        .win32 = .{
            .console_utf8 = true,
        },
    });
}
