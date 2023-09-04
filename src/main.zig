const std = @import("std");

pub const c = @import("c.zig");
pub usingnamespace @import("autorelease.zig");
const class = @import("class.zig");
pub usingnamespace @import("object.zig");
pub usingnamespace @import("property.zig");
pub usingnamespace @import("sel.zig");

/// This just calls the C allocator free. Some things need to be freed
/// and this is how they can be freed for objc.
pub inline fn free(ptr: anytype) void {
    std.heap.c_allocator.free(ptr);
}

test {
    std.testing.refAllDecls(@This());
}

pub fn Class(name: [:0]const u8) ?class {
    return .{
        .value = c.objc_getClass(name.ptr) orelse return null,
    };
}

test "getClass" {
    const testing = std.testing;
    const NSObject = Class("NSObject");
    try testing.expect(NSObject != null);
    try testing.expect(Class("NoWay") == null);
}

test "msgSend" {
    const testing = std.testing;
    const NSObject = Class("NSObject").?;

    // Should work with primitives
    const id = NSObject.message(c.id, "alloc", .{});
    try testing.expect(id != null);
    {
        const obj: @This().Object = .{ .value = id };
        obj.message(void, "dealloc", .{});
    }

    // Should work with our wrappers
    const obj = NSObject.message(@This().Object, "alloc", .{});
    try testing.expect(obj.value != null);
    obj.message(void, "dealloc", .{});
}

test "getProperty" {
    const testing = std.testing;
    const NSObject = Class("NSObject").?;

    try testing.expect(NSObject.getProperty("className") != null);
    try testing.expect(NSObject.getProperty("nope") == null);
}

test "copyProperyList" {
    const testing = std.testing;
    const NSObject = Class("NSObject").?;

    const list = NSObject.copyPropertyList();
    defer free(list);
    try testing.expect(list.len > 20);
}
