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

    // read
    // close
}
