// # 程序入口，负责初始化 Luvia 并开启游戏循环

const std = @import("std");
const engine = @import("engine");

// 【程序入口】
pub fn main() !void {
    std.debug.print("Start Game ... ", .{});
    engine.run();
}
