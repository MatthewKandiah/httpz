const std = @import("std");
const c = @cImport({
    @cInclude("sys/socket.h");
});

const lib = @import("./lib.zig");
const server = @import("./server.zig");

const ClientArgs = struct {
    host: ?[:0]const u8,
    port: ?u16,

    const Self = @This();

    fn init() Self {
        return .{
            .host = null,
            .port = null,
        };
    }

    fn isValid(self: Self) bool {
        return self.host != null and self.port != null;
    }
};

pub fn main() !void {
    lib.platformInit();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    _ = args.next(); // skip program name
    var clientArgs = ClientArgs.init();
    while (args.next()) |arg| {
        const flag = arg;
        const value = args.next();
        if (std.mem.eql(u8, flag, "--host")) {
            if (value) |hostValue| {
                clientArgs.host = try allocator.dupeZ(u8, hostValue);
            } else {
                lib.platform.reportError("missing host value", .{});
            }
        } else if (std.mem.eql(u8, flag, "--port")) {
            if (value) |portValue| {
                clientArgs.port = try std.fmt.parseInt(u16, portValue, 10);
            } else {
                lib.platform.reportError("missing port value", .{});
            }
        }
    }
    if (!clientArgs.isValid()) {
        // TODO-Matt: nicer usage error
        lib.platform.reportError("invalid arguments", .{});
    }
    args.deinit();

    const socket = lib.createSocket();
    lib.connect(socket, clientArgs.host.?, clientArgs.port.?);
    const data = "Hello server";
    _ = lib.write(socket, data);

    var buf: [1024]u8 = .{0} ** 1024;
    var read_bytes: usize = 0;
    while (read_bytes == 0) {
        read_bytes = lib.read(socket, buf[0..100]);
    }

    lib.close(socket);
}
