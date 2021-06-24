const std = @import("std");
const zCord = @import("zCord");
const configjson = @import("../config.json");

pub fn main() !void {
    // This is a shared global and should never be reclaimed
    try zCord.root_ca.preload(std.heap.page_allocator);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var auth_buf: [0x100]u8 = undefined;
    const config = try getConfig(allocator)
    const auth = try std.fmt.bufPrint(&auth_buf, "Bot {s}", .{std.os.getenv("DISCORD_AUTH") orelse return error.AuthNotFound});

    const Client = try zCord.Client.create(.{
        .allocator = &gpa.allocator,
        .auth_token = auth,
        .intents = .{.guild_messages = true},
    });
    defer client.destroy();
}

pub fn getConfig(allocator: *std.mem.Allocator) !Config {
    const f = try std.fs.cwd().openFile("config.json", .{});
    defer f.close();

    const json_data = try f.reader().readAllAlloc(&allocator, 1<<20);
    defer allocator.free(json_data);

    const stream = std.json.TokenStream.init(json_data);
    const data = try std.json.parse(Config, &stream, .{.allocator = allocator});
    defer json.parseFree(data);

    return data;
}

const Config = struct {
    token: []const u8,
    prefix: []const u8,
};
