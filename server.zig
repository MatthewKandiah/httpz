const std = @import("std");
const c = @cImport({
    @cInclude("sys/socket.h");
});

const lib = @import("./lib.zig");

pub const localhost_address = "127.0.0.1";
pub const server_port = 6969;

const ServerArgs = struct {
    ipv4_address: ?[:0]const u8,
    port: ?u16,

    const Self = @This();

    fn init() Self {
        return .{
            .ipv4_address = null,
            .port = null,
        };
    }

    fn isValid(self: Self) bool {
        return self.ipv4_address != null and self.port != null;
    }
};

pub fn main() !void {
    lib.platformInit();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    _ = args.next(); // skip program name
    var server_args = ServerArgs.init();
    while (args.next()) |arg| {
        const flag = arg;
        const value = args.next();
        if (std.mem.eql(u8, flag, "--ipv4")) {
            if (value) |ipv4_value| {
                server_args.ipv4_address = try allocator.dupeZ(u8, ipv4_value);
            } else {
                lib.platform.reportError("missing ipv4 value", .{});
            }
        } else if (std.mem.eql(u8, flag, "--port")) {
            if (value) |portValue| {
                server_args.port = try std.fmt.parseInt(u16, portValue, 10);
            } else {
                lib.platform.reportError("missing port value", .{});
            }
        }
    }
    if (!server_args.isValid()) {
        // TODO-Matt: nicer usage error
        lib.platform.reportError("invalid arguments", .{});
    }
    args.deinit();

    const socket = lib.createSocket();
    const sockaddr = lib.buildIpv4Addrinfo(localhost_address, server_port);
    lib.bind(socket, sockaddr);
    lib.listen(socket);

    var count: usize = 0;
    while (true) : (count += 1) {
        const connection_info = lib.acceptConnection(socket);
        var buf: [1024]u8 = .{0} ** 1024;
        var read_bytes: usize = 0;
        while (read_bytes == 0) {
            read_bytes = lib.read(connection_info.connfd, buf[0..100]);
        }

        var data_buf: [16]u8 = .{0} ** 16;
        const data_byte_count = std.fmt.formatIntBuf(&data_buf, count, 10, .lower, .{});
        _ = lib.write(connection_info.connfd, data_buf[0..data_byte_count]);

        lib.close(connection_info.connfd);
    }
}
