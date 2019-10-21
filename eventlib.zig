// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// TODO: move this to zog library
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
const builtin = @import("builtin");
const std = @import("std");

const EventsImpl = enum {
    epoll,
};
const eventsImpl = switch (builtin.Os.linux) {
    .linux => EventsImpl.epoll,
    else => @compileError("Events not implemented on this OS"),
};

pub const Handle = i32;

pub const EventHandler = fn(events: *Events(), handle: Handle) anyerror!void;

fn EventsData() type {
    switch (eventsImpl) {
        .epoll => return struct {
            handle: i32,
            pub fn init() @This() {
                return @This() {
                    .handle = -1,
                };
            }
        },
    }
}

pub const EventFlag = switch (eventsImpl) {
    .epoll => enum(u32) {
        in = std.os.EPOLLIN,
        out = std.os.EPOLLOUT,
    },
};


pub fn Events() type {
    return struct {
        data: EventsData(),
        pub fn init(self: *@This()) !void {
            switch (eventsImpl) {
                .epoll => {
                    self.data.handle = try std.os.epoll_create1(0);
                    errdefer std.os.close(self.data.handle);
                },
            }
        }
        pub fn add(self: *@This(), handle: Handle, events: EventFlag, handler: EventHandler) !void {
            switch (eventsImpl) {
                .epoll => {
                    //self.os_data.final_eventfd = try os.eventfd(0, os.EFD_CLOEXEC | os.EFD_NONBLOCK);
                    //errdefer os.close(self.os_data.final_eventfd);
                    var event = std.os.epoll_event {
                        .events = @enumToInt(events),
                        .data = std.os.epoll_data { .ptr = @ptrToInt(handler) },
                    };
                    try std.os.epoll_ctl(
                        self.data.handle,
                        std.os.EPOLL_CTL_ADD,
                        handle,
                        &event,
                    );
                },
            }
        }
        pub fn run(self: *@This()) anyerror!void {
            switch (eventsImpl) {
                .epoll => {
                    // TODO: allow the number of events to be customizeable
                    var events: [32]std.os.linux.epoll_event = undefined;
                    while (true) {
                        std.debug.warn("[DEBUG] epoll_wait...\n");
                        const count = std.os.epoll_wait(self.data.handle, events[0..], -1);
                        if (count < 0) {
                            std.debug.warn("epoll_wait failed, errno={}", std.os.errno);
                            return error.EpollFailed;
                        }
                        for (events[0..count]) |ev| {
                            const handler = @intToPtr(EventHandler, ev.data.ptr);
                            try handler(self, ev.data.fd);
                        }
                    }
                },
            }
        }
    };
}