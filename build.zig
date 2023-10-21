const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const static_lib = b.addStaticLibrary(.{
        .name = "rlottie",
        .target = target,
        .optimize = optimize,
    });
    static_lib.defineCMacro("LOT_BUILD", null);
    static_lib.defineCMacro("LOTTIE_IMAGE_MODULE_SUPPORT", "0");
    static_lib.defineCMacro("LOTTIE_THREAD_SUPPORT", null);
    static_lib.defineCMacro("LOTTIE_CACHE_SUPPORT", null);
    static_lib.addIncludePath(.{ .path = "inc" });
    static_lib.linkSystemLibrary("pthread");
    static_lib.linkLibCpp();
    root.addTo(static_lib, cxx_options, "src", b.allocator);
    b.installArtifact(static_lib);
}

const StrSlice = []const []const u8;

/// Helper struct that implements the same logic as previous build system:
/// recursively include folders and compile source files that are in there.
/// The only purpose is to painlessly copy cmake/meson build logic.
const BuildDir = struct {
    rel_path: []const u8,
    srcs: StrSlice = &.{},
    subdirs: []const BuildDir = &.{},
    include: bool = true,

    fn addTo(self: *const BuildDir, step: *std.Build.Step.Compile, flags: StrSlice, root_path: []const u8, allocator: std.mem.Allocator) void {
        if (self.include) step.addIncludePath(.{ .path = root_path });
        for (self.srcs) |src| {
            const src_path = std.mem.concat(allocator, u8, &.{ root_path, std.fs.path.sep_str, src }) catch @panic("OOM");
            step.addCSourceFile(.{
                .file = .{ .path = src_path },
                .flags = flags,
            });
        }
        for (self.subdirs) |*dir| {
            const curr_path = std.mem.concat(allocator, u8, &.{ root_path, std.fs.path.sep_str, dir.rel_path }) catch @panic("OOM");
            dir.addTo(step, flags, curr_path, allocator);
        }
    }
};

const cxx_options: StrSlice = &.{
    "-std=c++14",
    "-fno-sanitize=undefined",
    "-fno-exceptions",
    "-fno-unwind-tables",
    "-fno-asynchronous-unwind-tables",
    "-fno-rtti",
    "-Wall",
    "-Werror",
    "-Wextra",
    "-Wnon-virtual-dtor",
    "-Woverloaded-virtual",
    "-Wno-unused-parameter",
    "-fvisibility=hidden",
};

const root = BuildDir{
    .rel_path = "src",
    .subdirs = &.{
        lottie_dir,
        vector_dir,
        binding_dir,
    },
    .include = false,
};

const lottie_dir = BuildDir{
    .rel_path = "lottie",
    .srcs = &.{
        "lottieitem.cpp",
        "lottieloader.cpp",
        "lottiemodel.cpp",
        "lottieproxymodel.cpp",
        "lottieparser.cpp",
        "lottieanimation.cpp",
        "lottiekeypath.cpp",
    },
};

const vector_dir = BuildDir{
    .rel_path = "vector",
    .srcs = &.{
        "vrect.cpp",
        "vdasher.cpp",
        "vbrush.cpp",
        "vbitmap.cpp",
        "vpainter.cpp",
        "vcompositionfunctions.cpp",
        "vdrawhelper.cpp",
        "vdrawhelper_sse2.cpp",
        "vdrawhelper_neon.cpp",
        "vrle.cpp",
        "vpath.cpp",
        "vpathmesure.cpp",
        "vmatrix.cpp",
        "velapsedtimer.cpp",
        "vdebug.cpp",
        "vinterpolator.cpp",
        "vbezier.cpp",
        "vraster.cpp",
        "vdrawable.cpp",
        "vimageloader.cpp",
    },
    .subdirs = &.{
        freetype_dir,
        pixman_dir,
        stb_dir,
    },
};

const freetype_dir = BuildDir{
    .rel_path = "freetype",
    .srcs = &.{
        "v_ft_math.cpp",
        "v_ft_raster.cpp",
        "v_ft_stroker.cpp",
    },
};

const pixman_dir = BuildDir{
    .rel_path = "pixman",
    .srcs = &.{
        "vregion.cpp",
    },
};

const stb_dir = BuildDir{
    .rel_path = "stb",
    .srcs = &.{"stb_image.cpp"},
};

const binding_dir = BuildDir{
    .rel_path = "binding/c",
    .srcs = &.{
        "lottieanimation_capi.cpp",
    },
};
