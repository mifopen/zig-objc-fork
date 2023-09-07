const std = @import("std");
const c = @import("c.zig");
const objc = @import("main.zig");
const MsgSend = @import("msg_send.zig").MsgSend;

pub const Class = struct {
    value: c.Class,
    pub usingnamespace MsgSend(Class);

    // Returns a property with a given name of a given class.
    pub fn getProperty(self: Class, name: [:0]const u8) ?objc.Property {
        return objc.Property{
            .value = c.class_getProperty(self.value, name.ptr) orelse return null,
        };
    }

    /// Describes the properties declared by a class. This must be freed.
    pub fn copyPropertyList(self: Class) []objc.Property {
        var count: c_uint = undefined;
        const list = @as([*c]objc.Property, @ptrCast(c.class_copyPropertyList(self.value, &count)));
        if (count == 0) return list[0..0];
        return list[0..count];
    }

    /// Describes the protocols adopted by a class. This must be freed.
    pub fn copyProtocolList(self: Class) []objc.Protocol {
        var count: c_uint = undefined;
        const list = @as([*c]objc.Protocol, @ptrCast(c.class_copyProtocolList(self.value, &count)));
        if (count == 0) return list[0..0];
        return list[0..count];
    }

    pub fn isMetaClass(self: Class) bool {
        return if (c.class_isMetaClass(self.value) == 1) true else false;
    }

    pub fn getInstanceSize(self: Class) usize {
        return c.class_getInstanceSize(self.value);
    }

    pub fn respondsToSelector(self: Class, sel: objc.Sel) bool {
        return if (c.class_respondsToSelector(self.value, sel.value) == 1) true else false;
    }

    pub fn conformsToProtocol(self: Class, protocol: objc.Protocol) bool {
        return if (c.class_conformsToProtocol(self.value, &protocol.value) == 1) true else false;
    }
};

pub fn getClass(name: [:0]const u8) ?Class {
    return .{
        .value = c.objc_getClass(name.ptr) orelse return null,
    };
}

pub fn getMetaClass(name: [:0]const u8) ?Class {
    return .{
        .value = c.objc_getMetaClass(name) orelse return null,
    };
}

test "getClass" {
    const testing = std.testing;
    const NSObject = getClass("NSObject");
    try testing.expect(NSObject != null);
    try testing.expect(getClass("NoWay") == null);
}

test "msgSend" {
    const testing = std.testing;
    const NSObject = getClass("NSObject").?;

    // Should work with primitives
    const id = NSObject.message(c.id, "alloc", .{});
    try testing.expect(id != null);
    {
        const obj: objc.Object = .{ .value = id };
        obj.message(void, "dealloc", .{});
    }

    // Should work with our wrappers
    const obj = NSObject.message(objc.Object, "alloc", .{});
    try testing.expect(obj.value != null);
    obj.message(void, "dealloc", .{});
}

test "getProperty" {
    const testing = std.testing;
    const NSObject = getClass("NSObject").?;

    try testing.expect(NSObject.getProperty("className") != null);
    try testing.expect(NSObject.getProperty("nope") == null);
}

test "copyProperyList" {
    const testing = std.testing;
    const NSObject = getClass("NSObject").?;

    const list = NSObject.copyPropertyList();
    defer objc.free(list);
    try testing.expect(list.len > 20);
}
