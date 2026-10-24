const std = @import("std");
const builtin = @import("builtin");
const assert = @import("../quirks.zig").inlineAssert;
const Allocator = std.mem.Allocator;
const internal_os = @import("../os/main.zig");
const global = @import("../global.zig");

const log = std.log.scoped(.config);

/// Default path for the XDG home configuration file. Returned value
/// must be freed by the caller.
pub fn defaultXdgPath(alloc: Allocator) ![]const u8 {
    var environ_map = try global.environMap();
    defer environ_map.deinit();
    return try internal_os.xdg.config(
        global.io(),
        alloc,
        &environ_map,
        .{ .subdir = "kinterm/config.kinterm" },
    );
}

/// Default path for the XDG home configuration file without an extension.
/// Returned value must be freed by the caller.
pub fn legacyDefaultXdgPath(alloc: Allocator) ![]const u8 {
    var environ_map = try global.environMap();
    defer environ_map.deinit();
    return try internal_os.xdg.config(
        global.io(),
        alloc,
        &environ_map,
        .{ .subdir = "kinterm/config" },
    );
}

/// Preferred default path for the XDG home configuration file.
/// Returned value must be freed by the caller.
pub fn preferredXdgPath(alloc: Allocator) ![]const u8 {
    // If the XDG path exists, use that.
    const xdg_path = try defaultXdgPath(alloc);
    if (open(global.io(), xdg_path)) |f| {
        f.close(global.io());
        return xdg_path;
    } else |_| {}

    // Try the legacy path
    errdefer alloc.free(xdg_path);
    const legacy_xdg_path = try legacyDefaultXdgPath(alloc);
    if (open(global.io(), legacy_xdg_path)) |f| {
        f.close(global.io());
        alloc.free(xdg_path);
        return legacy_xdg_path;
    } else |_| {}

    // Legacy path and XDG path both don't exist. Return the
    // new one.
    alloc.free(legacy_xdg_path);
    return xdg_path;
}

/// Default path for the macOS Application Support configuration file.
/// Returned value must be freed by the caller.
pub fn defaultAppSupportPath(alloc: Allocator) ![]const u8 {
    return try internal_os.macos.appSupportDir(alloc, "config.kinterm");
}

/// Default path for the macOS Application Support configuration file
/// without an extension. Returned value must be freed by the caller.
pub fn legacyDefaultAppSupportPath(alloc: Allocator) ![]const u8 {
    return try internal_os.macos.appSupportDir(alloc, "config");
}

/// Preferred default path for the macOS Application Support configuration file.
/// Returned value must be freed by the caller.
pub fn preferredAppSupportPath(alloc: Allocator) ![]const u8 {
    // If the app support path exists, use that.
    const app_support_path = try defaultAppSupportPath(alloc);
    if (open(global.io(), app_support_path)) |f| {
        f.close(global.io());
        return app_support_path;
    } else |_| {}

    // Try the legacy path
    errdefer alloc.free(app_support_path);
    const legacy_app_support_path = try legacyDefaultAppSupportPath(alloc);
    if (open(global.io(), legacy_app_support_path)) |f| {
        f.close(global.io());
        alloc.free(app_support_path);
        return legacy_app_support_path;
    } else |_| {}

    // Legacy path and app support path both don't exist. Return the
    // new one.
    alloc.free(legacy_app_support_path);
    return app_support_path;
}

/// Ghostty's configuration files, in the order Ghostty loads them. KinTerm
/// loads these when it has no configuration file of its own, so an existing
/// Ghostty setup keeps working. Returned values must be freed by the caller.
pub fn ghosttyPaths(alloc: Allocator) ![]const []const u8 {
    var environ_map = try global.environMap();
    defer environ_map.deinit();

    var paths: std.ArrayList([]const u8) = try .initCapacity(alloc, 4);
    errdefer {
        for (paths.items) |path| alloc.free(path);
        paths.deinit(alloc);
    }

    for ([_][]const u8{ "ghostty/config", "ghostty/config.ghostty" }) |subdir| {
        paths.appendAssumeCapacity(try internal_os.xdg.config(
            global.io(),
            alloc,
            &environ_map,
            .{ .subdir = subdir },
        ));
    }

    if (comptime builtin.target.os.tag == .macos) {
        for ([_][]const u8{ "config", "config.ghostty" }) |sub_path| {
            paths.appendAssumeCapacity(
                try internal_os.macos.ghosttyAppSupportDir(alloc, sub_path),
            );
        }
    }

    return try paths.toOwnedSlice(alloc);
}

/// Frees the result of `ghosttyPaths`.
pub fn freeGhosttyPaths(alloc: Allocator, paths: []const []const u8) void {
    for (paths) |path| alloc.free(path);
    alloc.free(paths);
}

/// The Ghostty configuration file KinTerm falls back to, if any exists.
/// Returned value must be freed by the caller.
pub fn existingGhosttyPath(alloc: Allocator) !?[]const u8 {
    const paths = try ghosttyPaths(alloc);
    defer freeGhosttyPaths(alloc, paths);

    // The last one loaded wins, so prefer it for editing.
    var i = paths.len;
    while (i > 0) {
        i -= 1;
        if (open(global.io(), paths[i])) |f| {
            f.close(global.io());
            return try alloc.dupe(u8, paths[i]);
        } else |_| {}
    }

    return null;
}

/// Returns the path to the preferred default configuration file.
/// This is the file where users should place their configuration.
///
/// This doesn't create or populate the file with any default
/// contents; downstream callers must handle this.
///
/// The returned value must be freed by the caller.
pub fn preferredDefaultFilePath(alloc: Allocator) ![]const u8 {
    const path = try preferredKinTermFilePath(alloc);
    if (open(global.io(), path)) |f| {
        f.close(global.io());
        return path;
    } else |_| {}

    // No KinTerm config yet: KinTerm is running on a Ghostty config, so
    // that's the one to edit.
    const ghostty_path = try existingGhosttyPath(alloc) orelse return path;
    alloc.free(path);
    return ghostty_path;
}

fn preferredKinTermFilePath(alloc: Allocator) ![]const u8 {
    switch (builtin.target.os.tag) {
        .macos => {
            // macOS prefers the Application Support directory
            // if it exists.
            const app_support_path = try preferredAppSupportPath(alloc);
            const app_support_file = open(global.io(), app_support_path) catch {
                // Try the XDG path if it exists
                const xdg_path = try preferredXdgPath(alloc);
                const xdg_file = open(global.io(), xdg_path) catch {
                    // If neither file exists, use app support
                    alloc.free(xdg_path);
                    return app_support_path;
                };
                xdg_file.close(global.io());
                alloc.free(app_support_path);
                return xdg_path;
            };
            app_support_file.close(global.io());
            return app_support_path;
        },

        // All other platforms use XDG only
        else => return try preferredXdgPath(alloc),
    }
}

const OpenFileError = error{
    FileNotFound,
    FileIsEmpty,
    FileOpenFailed,
    NotAFile,
};

/// Opens the file at the given path and returns the file handle
/// if it exists and is non-empty. This also constrains the possible
/// errors to a smaller set that we can explicitly handle.
pub fn open(io: std.Io, path: []const u8) OpenFileError!std.Io.File {
    assert(std.fs.path.isAbsolute(path));

    var file = std.Io.Dir.openFileAbsolute(
        io,
        path,
        .{},
    ) catch |err| switch (err) {
        error.FileNotFound => return OpenFileError.FileNotFound,
        else => {
            log.warn("unexpected file open error path={s} err={}", .{
                path,
                err,
            });
            return OpenFileError.FileOpenFailed;
        },
    };
    errdefer file.close(io);

    const stat = file.stat(io) catch |err| {
        log.warn("error getting file stat path={s} err={}", .{
            path,
            err,
        });
        return OpenFileError.FileOpenFailed;
    };
    switch (stat.kind) {
        .file => {},
        else => return OpenFileError.NotAFile,
    }

    if (stat.size == 0) return OpenFileError.FileIsEmpty;

    return file;
}
