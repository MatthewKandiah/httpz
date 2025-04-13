const std = @import("std");
const c = @cImport({
    @cInclude("sys/socket.h");
});

const lib = @import("./lib.zig");

pub const localhost_address = "127.0.0.1";
pub const server_port = 6969;

pub fn main() void {
    lib.platformInit();

    const socket = lib.createSocket();
    const sockaddr = lib.buildIpv4Addrinfo(localhost_address, server_port);
    lib.bind(socket, sockaddr);
    lib.listen(socket);
    const connection_info = lib.acceptConnection(socket);
    var buf: [1024]u8 = .{0} ** 1024;
    var read_bytes: usize = 0;
    while (read_bytes == 0) {
        read_bytes = lib.read(connection_info.connfd, buf[0..100]);
    }

    const data = "Hello client, from server";
    _ = lib.write(connection_info.connfd, data);

    lib.close(connection_info.connfd);
    lib.close(socket);
}
