const std = @import("std");
//const Loop = std.event.Loop;

const zog = @import("zog");
usingnamespace zog.cmdlinetool;

const eventlib = @import("eventlib.zig");
const Events = eventlib.Events;

var arena = std.heap.ArenaAllocator.init(std.heap.direct_allocator);
const allocator = &arena.allocator;

//const DefaultPort = 1013;
const DefaultPort = 1234;

//var globalLoop : Loop = undefined;
var globalEvents : Events() = undefined;

pub fn main() anyerror!u8 {
    const listenAddress = std.net.Address.initIp4(0, DefaultPort);

    // TODO: use IPPROTO_TCP when zig standard lib defines it
    var listenSock = std.os.socket(std.os.AF_INET, std.os.SOCK_STREAM, 0) catch |err| {
        log("Error: socket function failed with {}", err);
        return 1;
    };

    // print listen address
    // log("listen address is {}", listenAddress); NOTE: std.net.Address.format is wrong
    // TODO: fix it and add a test

    std.os.bind(listenSock, &listenAddress.os_addr) catch |err| {
        log("Error: bind failed with {}", err);
        return 1;
    };
    std.os.listen(listenSock, 128) catch |err| {
        log("Error; listen failed with {}", err);
        return 1;
    };

    log("listening!");

    //try globalLoop.initSingleThreaded(allocator);
    //defer globalLoop.deinit(); // TODO: may not be necessary
    //var acceptHandle = async Loop.call(acceptLoop, listenSock);
    //log("running event loop...");
    //globalLoop.run();

    try globalEvents.init();
    try globalEvents.add(listenSock, eventlib.EventFlag.in, handleListenSock);
    try globalEvents.run();
    return 0;
}

fn handleListenSock(events: *Events(), fd: eventlib.Handle) anyerror!void {
    var from : std.net.Address = undefined;
    var fromSize : u32 = @sizeOf(@typeOf(from));
    var newSocket = try std.os.accept4(fd, &from.os_addr, &fromSize, 0);
    //log("got new connection {}", from);
    log("got new connection!");
    try events.add(newSocket, eventlib.EventFlag.in, handleDataSock);
}

fn handleDataSock(events: *Events(), fd: eventlib.Handle) anyerror!void {
    var buffer : [200]u8 = undefined;
    //var result = async std.os.read(fd, buffer[0..]);
    var result = std.os.read(fd, buffer[0..]);
    log("read result is {}", result);
    _ = std.os.system.shutdown(fd, 0xFFFF);
    std.os.close(fd);
}

fn acceptLoop(listenSock: i32) anyerror!void {
    log("--- accept loop!");
    while (true) {
        log("calling accept...");

        var newSocket = async std.os.accept4_async(listenSock, &from.os_addr, 0);
        //log("got new connection {}", from);
        log("got new connection!");
        _ = async Loop.call(handleClient, newSocket);
    }
}

fn handleClient(sock: i32) void {
    log("--- handleClient {}", sock);
    var buffer : [200]u8 = undefined;
    //var result = async std.os.read(sock, buffer[0..]);
    var result = std.os.read(sock, buffer[0..]);
    log("read result is {}", result);
    _ = std.os.system.shutdown(sock, 0xFFFF);
    std.os.close(sock);
}