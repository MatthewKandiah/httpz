const std = @import("std");
const c = @cImport({
    @cInclude("sys/socket.h");
});

const lib = @import("./lib.zig");
const server = @import("./server.zig");

pub fn main() void {
    lib.platformInit();

    const socket = lib.createSocket();
    lib.connect(socket, server.localhost_address, server.server_port);
    const data = "Hello server";
    const written_bytes = lib.write(socket, data);
    lib.print(lib.platform.std_out, "client written_bytes: {}\n", .{written_bytes});

    var buf: [1024]u8 = .{0} ** 1024;
    var read_bytes: usize = 0;
    while (read_bytes == 0) {
        read_bytes = lib.read(socket, buf[0..100]);
        lib.print(lib.platform.std_out, "read_bytes: {}\n", .{read_bytes});
        lib.print(lib.platform.std_out, "read data: {s}\n", .{buf[0..read_bytes]});
    }

    lib.close(socket);
}
