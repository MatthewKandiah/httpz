const std = @import("std");
const c = @cImport({
    @cInclude("sys/socket.h");
});

const lib = @import("./lib.zig");

const localhost_address = "127.0.0.1";
const server_port = 6969;

pub fn main() void {
    const platform = lib.Platform.init();

    const socket = lib.createSocket(platform);
    const sockaddr = lib.buildIpv4Addrinfo(platform, localhost_address, server_port);
    lib.bind(platform, socket, sockaddr);
    lib.listen(platform, socket);
    const connection_info = lib.acceptConnection(platform, socket);
    var buf: [1024]u8 = .{0} ** 1024;
    var read_bytes: usize = 0;
    while (read_bytes == 0) {
        read_bytes = lib.read(platform, connection_info.connfd, buf[0..100]);
        lib.print(platform.std_out, "read_bytes: {}\n", .{read_bytes});
        lib.print(platform.std_out, "read data: {s}\n", .{buf[0..read_bytes]});
    }

    const data = "Hello client, from server";
    const written_bytes = lib.write(platform, connection_info.connfd, data);
    lib.print(platform.std_out, "server written_bytes: {}\n", .{written_bytes});

    // EOF read
    // close
}
