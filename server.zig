const std = @import("std");
const c = @cImport({
    @cInclude("sys/socket.h");
});

const lib = @import("./lib.zig");

pub fn main() void {
    const platform = lib.Platform.init();

    const socket = lib.createSocket(platform);
    lib.bind(platform, socket);
    lib.listen(platform, socket);
    const connection_info = lib.acceptConnection(platform, socket);
    var buf: [1024]u8 = .{0} ** 1024;
    var read_bytes: usize = 0;
    while (read_bytes == 0) {
        read_bytes = lib.read(platform, connection_info.connfd, buf[0..100]);
        lib.print(platform.std_out, "read_bytes: {}\n", .{read_bytes});
        lib.print(platform.std_out, "read data: {s}\n", .{buf[0..read_bytes]});
    }

    // write
    // EOF read
    // close
}
