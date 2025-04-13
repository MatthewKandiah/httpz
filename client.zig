const std = @import("std");
const c = @cImport({
    @cInclude("sys/socket.h");
});

const lib = @import("./lib.zig");

pub fn main() void {
    const platform = lib.Platform.init();

    const socket = lib.createSocket(platform);
    lib.connect(platform, socket);
    const data = "Hello server";
    const written_bytes = lib.write(platform, socket, data);
    lib.print(platform.std_out, "client written_bytes: {}\n", .{written_bytes});

    var buf: [1024]u8 = .{0} ** 1024;
    var read_bytes: usize = 0;
    while (read_bytes == 0) {
        read_bytes = lib.read(platform, socket, buf[0..100]);
        lib.print(platform.std_out, "read_bytes: {}\n", .{read_bytes});
        lib.print(platform.std_out, "read data: {s}\n", .{buf[0..read_bytes]});
    }
    // close
}
