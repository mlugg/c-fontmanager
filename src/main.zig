const std = @import("std");
const FontManager = @import("fontmanager").FontManager(DummyTextureContext);

const DummyTextureContext = struct {
    ctx: ?*anyopaque,
    createTex: *fn (ctx: ?*anyopaque, idx: u32, w: u32, h: u32, data: [*]const u8) callconv(.C) bool,
    destroyTex: *fn (ctx: ?*anyopaque, idx: u32) callconv(.C) void,
    updateTex: *fn (ctx: ?*anyopaque, idx: u32, x: u32, y: u32, w: u32, h: u32) callconv(.C) bool,

    pub const RenderTexture = u32;
    pub fn getRenderTexture(_: DummyTextureContext, idx: u32) u32 {
        return idx;
    }

    pub fn createTexture(self: DummyTextureContext, idx: u32, w: u32, h: u32, data: []const u8) !void {
        std.debug.assert(data.len == w * h * 4);
        if (!self.createTex(self.ctx, idx, w, h, data.ptr)) {
            return error.TextureCreationFailed;
        }
    }

    pub fn destroyTexture(self: DummyTextureContext, idx: u32) void {
        self.destroyTex(self.ctx, idx);
    }

    pub fn updateTexture(self: DummyTextureContext, idx: u32, x: u32, y: u32, w: u32, h: u32, data: []const u8) !void {
        _ = data; // always the same as the initial buffer
        if (!self.updateTex(self.ctx, idx, x, y, w, h)) {
            return error.TextureUpdateFailed;
        }
    }
};

export fn fontman_init(
    texture_ctx: ?*anyopaque,
    create_tex: *fn (ctx: ?*anyopaque, idx: u32, w: u32, h: u32, data: [*]const u8) callconv(.C) bool,
    destroy_tex: *fn (ctx: ?*anyopaque, idx: u32) callconv(.C) void,
    update_tex: *fn (ctx: ?*anyopaque, idx: u32, x: u32, y: u32, w: u32, h: u32) callconv(.C) bool,
    page_size: u32,
    max_pages: u32,
) ?*FontManager {
    const fm = std.heap.c_allocator.create(FontManager) catch return null;

    fm.* = FontManager.init(std.heap.c_allocator, DummyTextureContext{
        .ctx = texture_ctx,
        .createTex = create_tex,
        .destroyTex = destroy_tex,
        .updateTex = update_tex,
    }, .{
        .page_size = page_size,
        .max_pages = max_pages,
    }) catch {
        std.heap.c_allocator.destroy(fm);
        return null;
    };

    return fm;
}

export fn fontman_deinit(fm: *FontManager) void {
    fm.deinit();
    std.heap.c_allocator.destroy(fm);
}

export fn fontman_register_font(fm: *FontManager, name: [*:0]const u8, path: [*:0]const u8, face_idx: i32) bool {
    fm.registerFont(std.mem.span(name), std.mem.span(path), face_idx) catch return false;
    return true;
}

export fn fontman_has_font(fm: *FontManager, name: [*:0]const u8) bool {
    return fm.hasFont(std.mem.span(name));
}

export fn fontman_glyph_iterator(fm: *FontManager, face_name: [*:0]const u8, size: u32, dpi: u16, str: [*:0]const u8) ?*FontManager.GlyphIterator {
    const iter = std.heap.c_allocator.create(FontManager.GlyphIterator) catch return null;

    iter.* = fm.glyphIterator(std.mem.span(face_name), size, dpi, std.mem.span(str)) catch {
        std.heap.c_allocator.destroy(iter);
        return null;
    };

    return iter;
}

export fn fontman_gliter_deinit(gi: *FontManager.GlyphIterator) void {
    gi.deinit();
    std.heap.c_allocator.destroy(gi);
}

export fn fontman_gliter_num_glyphs(gi: *FontManager.GlyphIterator) u32 {
    return @intCast(u32, gi.numGlyphs());
}

const CGlyphRenderInfo = extern struct {
    render: extern struct {
        texture_id: u32,
        top: f32,
        left: f32,
        bottom: f32,
        right: f32,
    },
    layout: extern struct {
        advance: i32,
        x_offset: i32,
        y_offset: i32,
        width: u32,
        height: u32,
    },
};

export fn fontman_gliter_next(gi: *FontManager.GlyphIterator, out: *CGlyphRenderInfo) bool {
    const info = (gi.next() catch return false) orelse return false;
    out.* = .{
        .render = .{
            .texture_id = info.render.texture,
            .top = info.render.top,
            .left = info.render.left,
            .bottom = info.render.bottom,
            .right = info.render.right,
        },
        .layout = .{
            .advance = info.layout.advance,
            .x_offset = info.layout.x_offset,
            .y_offset = info.layout.y_offset,
            .width = info.layout.width,
            .height = info.layout.height,
        },
    };
    return true;
}
