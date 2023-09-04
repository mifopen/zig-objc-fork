const std = @import("std");
const c = @import("c.zig");
const objc = @import("main.zig");
const MsgSend = @import("msg_send.zig").MsgSend;

pub const class = @This();

value: c.Class,

pub usingnamespace MsgSend(class);

/// Returns a property with a given name of a given class.
pub fn getProperty(self: class, name: [:0]const u8) ?objc.Property {
    return objc.Property{
        .value = c.class_getProperty(self.value, name.ptr) orelse return null,
    };
}

/// Describes the properties declared by a class. This must be freed.
pub fn copyPropertyList(self: class) []objc.Property {
    var count: c_uint = undefined;
    const list = @as([*c]objc.Property, @ptrCast(c.class_copyPropertyList(self.value, &count)));
    if (count == 0) return list[0..0];
    return list[0..count];
}
