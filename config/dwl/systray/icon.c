#include "icon.h"

#include <fcft/fcft.h>
#include <gtk/gtk.h>
#include <pixman.h>

#include <ctype.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define PREMUL_ALPHA(chan, alpha) (chan * alpha + 127) / 255

/*
 * Converts pixels from uint8_t[4] to uint32_t and
 * straight alpha to premultiplied alpha.
 */
static uint32_t *
to_pixman(const uint8_t *src, int n_pixels, size_t *pix_size)
{
	uint32_t *dest = NULL;

	*pix_size = n_pixels * sizeof(uint32_t);
	dest = malloc(*pix_size);
	if (!dest)
		return NULL;

	for (int i = 0; i < n_pixels; i++) {
		uint8_t a = src[i * 4 + 0];
		uint8_t r = src[i * 4 + 1];
		uint8_t g = src[i * 4 + 2];
		uint8_t b = src[i * 4 + 3];

		/*
		 * Skip premultiplying fully opaque and fully transparent
		 * pixels.
		 */
		if (a == 0) {
			dest[i] = 0;

		} else if (a == 255) {
			dest[i] = ((uint32_t)a << 24) | ((uint32_t)r << 16) |
			          ((uint32_t)g << 8) | ((uint32_t)b);

		} else {
			dest[i] = ((uint32_t)a << 24) |
			          ((uint32_t)PREMUL_ALPHA(r, a) << 16) |
			          ((uint32_t)PREMUL_ALPHA(g, a) << 8) |
			          ((uint32_t)PREMUL_ALPHA(b, a));
		}
	}

	return dest;
}

Icon *
createicon(const uint8_t *buf, int width, int height, int size)
{
	Icon *icon = NULL;

	int n_pixels;
	pixman_image_t *img = NULL;
	size_t pixbuf_size;
	uint32_t *buf_pixman = NULL;
	uint8_t *buf_orig = NULL;

	if (!buf || width <= 0 || height <= 0 || width > 512 || height > 512 ||
			size != width * height * 4)
		return NULL;
	n_pixels = width * height;

	icon = calloc(1, sizeof(Icon));
	buf_orig = malloc(size);
	buf_pixman = to_pixman(buf, n_pixels, &pixbuf_size);
	if (!icon || !buf_orig || !buf_pixman)
		goto fail;

	img = pixman_image_create_bits(PIXMAN_a8r8g8b8, width, height,
	                               buf_pixman, width * 4);
	if (!img)
		goto fail;

	memcpy(buf_orig, buf, size);

	icon->buf_orig = buf_orig;
	icon->buf_pixman = buf_pixman;
	icon->img = img;
	icon->size_orig = size;
	icon->size_pixman = pixbuf_size;

	return icon;

fail:
	free(buf_orig);
	if (img)
		pixman_image_unref(img);
	free(buf_pixman);
	free(icon);
	return NULL;
}

Icon *
create_named_icon(const char *name, const char *search_path, const char *theme_name)
{
	GtkIconTheme *theme;
	GdkPixbuf *pixbuf;
	const uint8_t *pixels, *pixel;
	uint8_t *argb;
	Icon *icon = NULL;
	int width, height, stride, channels, x, y, offset;

	if (!name || !*name)
		return NULL;
	if (g_path_is_absolute(name)) {
		pixbuf = gdk_pixbuf_new_from_file_at_scale(name, 64, 64, TRUE, NULL);
	} else {
		/* A standalone icon theme needs no display connection or GTK event loop. */
		theme = gtk_icon_theme_new();
		gtk_icon_theme_set_custom_theme(theme, theme_name);
		if (search_path && g_path_is_absolute(search_path))
			gtk_icon_theme_prepend_search_path(theme, search_path);
		pixbuf = gtk_icon_theme_load_icon(theme, name, 64, GTK_ICON_LOOKUP_FORCE_SIZE, NULL);
		g_object_unref(theme);
	}
	if (!pixbuf)
		return NULL;

	width = gdk_pixbuf_get_width(pixbuf);
	height = gdk_pixbuf_get_height(pixbuf);
	channels = gdk_pixbuf_get_n_channels(pixbuf);
	stride = gdk_pixbuf_get_rowstride(pixbuf);
	if (width <= 0 || height <= 0 || width > 512 || height > 512 ||
			(channels != 3 && channels != 4))
		goto done;
	argb = malloc((size_t)width * height * 4);
	if (!argb)
		goto done;
	pixels = gdk_pixbuf_read_pixels(pixbuf);
	for (y = 0; y < height; y++) {
		for (x = 0; x < width; x++) {
			pixel = pixels + y * stride + x * channels;
			offset = (y * width + x) * 4;
			argb[offset] = channels == 4 ? pixel[3] : 255;
			memcpy(argb + offset + 1, pixel, 3);
		}
	}
	icon = createicon(argb, width, height, width * height * 4);
	free(argb);
done:
	g_object_unref(pixbuf);
	return icon;
}

void
destroyicon(Icon *icon)
{
	if (icon->img)
		pixman_image_unref(icon->img);
	free(icon->buf_orig);
	free(icon->buf_pixman);
	free(icon);
}

FallbackIcon *
createfallbackicon(const char *appname, int fgcolor, struct fcft_font *font)
{
	const struct fcft_glyph *glyph;
	char initial;

	if ((unsigned char)appname[0] > 127) {
		/* first character is not ascii */
		initial = '?';
	} else {
		initial = toupper(*appname);
	}

	glyph = fcft_rasterize_char_utf32(font, initial, FCFT_SUBPIXEL_DEFAULT);
	if (!glyph)
		return NULL;

	return glyph;
}

int
resize_image(pixman_image_t *image, int new_width, int new_height)
{
	int src_width = pixman_image_get_width(image);
	int src_height = pixman_image_get_height(image);
	pixman_transform_t transform;
	pixman_fixed_t scale_x, scale_y;

	if (src_width == new_width && src_height == new_height)
		return 0;

	scale_x = pixman_double_to_fixed((double)src_width / new_width);
	scale_y = pixman_double_to_fixed((double)src_height / new_height);

	pixman_transform_init_scale(&transform, scale_x, scale_y);
	if (!pixman_image_set_filter(image, PIXMAN_FILTER_BEST, NULL, 0) ||
	    !pixman_image_set_transform(image, &transform)) {
		return -1;
	}

	return 0;
}
