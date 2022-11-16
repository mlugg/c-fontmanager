const std = @import("std");
const freetype = @import("mach-freetype/build.zig");
const fontmanager = @import("zig-fontmanager/build.zig");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const lib = b.addStaticLibrary("c-fontmanager", "src/main.zig");
    lib.setBuildMode(mode);
    lib.setTarget(target);
    lib.addPackage(fontmanager.pkg(freetype));
    freetype.link(b, lib, .{ .harfbuzz = .{} });
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
}
