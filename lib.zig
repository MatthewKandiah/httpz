const std = @import("std");
const File = std.fs.File;
const c = @cImport({
    @cInclude("sys/socket.h");
    @cInclude("netinet/in.h");
    @cInclude("arpa/inet.h");
});

pub const Platform = struct {
    std_out: File,
    std_err: File,

    const Self = @This();

    pub fn init() Self {
        return .{
            .std_out = std.io.getStdOut(),
            .std_err = std.io.getStdErr(),
        };
    }
};

pub fn happyExit() noreturn {
    std.process.exit(0);
}

pub fn errorExit() noreturn {
    std.process.exit(1);
}

// TODO-Matt: maybe move to method on Platform, think we'll want a write function for sockets
pub fn printLine(file: File, bytes: []const u8) void {
    print(file, "{s}\n", .{bytes});
}

// TODO-Matt: maybe move to method on Platform, think we'll want a write function for sockets
pub fn print(file: File, comptime fmt: []const u8, args: anytype) void {
    std.fmt.format(file.writer(), fmt, args) catch {};
}

pub fn createSocket(p: Platform) usize {
    const fd = std.os.linux.socket(c.AF_INET, c.SOCK_STREAM, 0);
    if (fd == -1) {
        printLine(p.std_err, "ERROR - failed to open socket");
        errorExit();
    } else {
        printLine(p.std_out, "SUCCESS - opened socket");
    }
    return fd;
}

pub fn buildIpv4Addrinfo(p: Platform, address: [:0]const u8, port: u16) std.os.linux.sockaddr.in {
    var result = std.os.linux.sockaddr.in{
        .family = c.AF_INET,
        .addr = undefined,
        .port = c.htons(port),
    };
    const addr_convert_res = c.inet_pton(c.AF_INET, address, &result.addr);
    if (addr_convert_res != 1) {
        print(p.std_err, "ERROR - failed to convert address {s}\n", .{address});
    }
    return result;
}

pub fn bind(p: Platform, socket: usize, sockaddr: std.os.linux.sockaddr.in) void {
    const bind_res = std.os.linux.bind(@intCast(socket), @ptrCast(&sockaddr), @sizeOf(@TypeOf(sockaddr)));
    if (bind_res == -1) {
        printLine(p.std_err, "ERROR - failed to bind socket");
    } else {
        printLine(p.std_out, "SUCCESS - bound socket");
    }
}

pub fn listen(p: Platform, socket: usize) void {
    const listen_res = std.os.linux.listen(@intCast(socket), 0);
    if (listen_res == -1) {
        printLine(p.std_err, "ERROR - failed to listen to socket");
        errorExit();
    } else {
        printLine(p.std_out, "SUCCESS - listening to socket");
    }
}

pub const ConnectionInfo = struct {
    connfd: usize,
    cliaddr: std.os.linux.sockaddr.in,
};

pub fn connect(p: Platform, socket: usize) void {
    const sockaddr = buildIpv4Addrinfo(p, "127.0.0.1", 6969);
    const connect_res = std.os.linux.connect(@intCast(socket), @ptrCast(&sockaddr), @sizeOf(@TypeOf(sockaddr)));
    if (connect_res == -1) {
        printLine(p.std_err, "ERROR - failed to connect");
        errorExit();
    } else {
        printLine(p.std_out, "SUCCESS - connected");
    }
}

pub fn acceptConnection(p: Platform, socket: usize) ConnectionInfo {
    var cliaddrlen: usize = @sizeOf(std.os.linux.sockaddr.in);
    var res: ConnectionInfo = undefined;
    const connfd = std.os.linux.accept(@intCast(socket), @ptrCast(&res.cliaddr), @alignCast(@ptrCast(&cliaddrlen)));
    if (connfd == -1) {
        printLine(p.std_err, "ERROR - failed to accept connection");
        errorExit();
    } else {
        printLine(p.std_out, "SUCCESS - accepted connection");
    }
    res.connfd = connfd;
    return res;
}

pub fn read(p: Platform, socket: usize, buf: []u8) usize {
    const read_res = std.os.linux.read(@intCast(socket), buf.ptr, buf.len);
    if (read_res == -1) {
        p.printLine(p.std_err, "ERROR - failed to read");
    }
    return read_res;
}

pub fn write(p: Platform, socket: usize, data: []const u8) usize {
    const write_res = std.os.linux.write(@intCast(socket), data.ptr, data.len);
    if (write_res == -1) {
        p.printLine(p.std_err, "ERROR - failed to write");
    }
    return write_res;
}
