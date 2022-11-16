#ifndef C_FONTMANAGER
#define C_FONTMANAGER

#include <stdint.h>

#ifdef __CPLUSPLUS
extern "C" {
#endif

/* Opaque datatypes */
struct font_manager;
struct glyph_iterator;

/* The information required to render a single glyph. 'render' contains the
 * information needed to create the actual vertices, while 'layout' contains
 * information about the position and dimensions of the glyph. */
struct glyph_render_info {
	struct {
		uint32_t texture_id;
		float top;
		float left;
		float bottom;
		float right;
	} render;

	struct {
		int32_t advance;
		int32_t x_offset;
		int32_t y_offset;
		uint32_t width;
		uint32_t height;
	} layout;
};

/* Initialize a font manager. 'create_tex', 'destroy_tex', and 'update_tex' are
 * pointers to callbacks which will be run when font page textures are to be
 * updated. 'texture_ctx' will be passed as the first argument to these
 * functions. Each font page is referenced by an index.
 *
 * Each font page will be 'page_size' pixels in each dimension, and pages will
 * be cleaned up once 'max_pages' exist. Suggested values for these parameters
 * are 512 and 64 respectively. */
struct font_manager *fontman_init(
	void *texture_ctx,
	bool (*create_tex)(void *ctx, uint32_t idx, uint32_t w, uint32_t h, const uint8_t *data),
	void (*destroy_tex)(void *ctx, uint32_t idx),
	bool (*update_tex)(void *ctx, uint32_t idx, uint32_t x, uint32_t y, uint32_t w, uint32_t h),
	uint32_t page_size,
	uint32_t max_pages
);

/* Deinitialize a font manager created by fontman_init. This MUST be run once
 * the font manager is no longer needed. */
void fontman_deinit(struct font_manager *fm);

/* Register a new font into a manager. The font is read as the 'face_idx'th face
 * in the file referred to by 'path', and can later be referred to by 'name'.
 * Returns true on success. */
bool fontman_register_font(struct font_manager *fm, const char *name, const char *path, int32_t face_idx);

/* Check whether a font name exists within a given font manager. Returns true if
 * the font exists, false otherwise. */
bool fontman_has_font(struct font_manager *fm, const char *name);

/* Begin iterating through the glyphs in a Unicode string. 'face_name' must
 * refer to a valid font, and 'str' must be a valid UTF-8 string. 'dpi' may be
 * passed as 0 if unknown. */
struct glyph_iterator *fontman_glyph_iterator(struct font_manager *fm, const char *face_name, uint32_t size, uint16_t dpi, const char *str);

/* Deinitialize a glyph iterator created by fontman_glyph_iterator. This MUST be
 * run once the glyph iterator is no longer needed. */
void fontman_gliter_deinit(struct glyph_iterator *gi);

/* Get the total number of glyphs (both already-iterated and remaining) in a
 * glyph iterator. */
uint32_t fontman_gliter_num_glyphs(struct glyph_iterator *gi);

/* Get the next glyph from an iterator. */
bool fontman_gliter_next(struct glyph_iterator *gi, struct glyph_render_info *out);

#ifdef __CPLUSPLUS
}
#endif

#endif
