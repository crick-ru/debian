/*
 * test_public_api - autopkgtest for the installed libtsm shared library
 *
 * Unlike the upstream test suite under test/, this test links only against the
 * installed libtsm shared library via its public API (libtsm.h). It never
 * includes internal headers (libtsm-int.h) nor recompiles library sources, so
 * it validates the shipped ABI, headers and pkg-config file as consumers see
 * them. Only public APIs up to v4.3.0 are included at this moment.
 *
 * The check(3) harness macros are reused from upstream test/test_common.h.
 *
 * SPDX-License-Identifier: MIT
 */

#include "test_common.h"
#include "libtsm.h"

#include <stdint.h>
#include <string.h>

/* Silent log callback so the tests do not spam stderr. */
static void log_cb(void *data, const char *file, int line, const char *func,
		   const char *subs, unsigned int sev, const char *format,
		   va_list args)
{
	UNUSED(data); UNUSED(file); UNUSED(line); UNUSED(func);
	UNUSED(subs); UNUSED(sev); UNUSED(format); UNUSED(args);
}

static void write_cb(struct tsm_vte *vte, const char *u8, size_t len,
		     void *data)
{
	UNUSED(vte); UNUSED(u8); UNUSED(len); UNUSED(data);
}

/* Capture the first code point of each drawn cell into a small grid so the
 * tests can assert on rendered output using only the public draw callback. */
#define GRID_W 20
#define GRID_H 5
struct grid {
	uint32_t ch[GRID_H][GRID_W];
};

static int draw_cb(struct tsm_screen *con, uint64_t id, const uint32_t *ch,
		   size_t len, unsigned int width, unsigned int posx,
		   unsigned int posy, const struct tsm_screen_attr *attr,
		   tsm_age_t age, void *data)
{
	struct grid *g = data;

	UNUSED(con); UNUSED(id); UNUSED(width); UNUSED(attr); UNUSED(age);

	if (posy < GRID_H && posx < GRID_W)
		g->ch[posy][posx] = (len > 0) ? ch[0] : 0;

	return 0;
}

/* --- UCS4 / UTF-8 helpers ------------------------------------------------ */

START_TEST(test_ucs4_width)
{
	/* Plain ASCII is single-width. */
	ck_assert_uint_eq(tsm_ucs4_get_width('A'), 1);
}
END_TEST

START_TEST(test_ucs4_to_utf8)
{
	char buf[4];
	size_t len;

	len = tsm_ucs4_to_utf8((uint32_t)'A', buf);
	ck_assert_uint_eq(len, 1);
	ck_assert_int_eq(buf[0], 'A');
}
END_TEST

/* --- Screen lifecycle & geometry ----------------------------------------- */

START_TEST(test_screen_lifecycle)
{
	struct tsm_screen *screen;
	int r;

	r = tsm_screen_new(&screen, log_cb, NULL);
	ck_assert_int_eq(r, 0);
	ck_assert_ptr_ne(screen, NULL);

	/* Exercise refcounting through the public API. */
	tsm_screen_ref(screen);
	tsm_screen_unref(screen);
	tsm_screen_unref(screen);
}
END_TEST

START_TEST(test_screen_resize)
{
	struct tsm_screen *screen;
	int r;

	r = tsm_screen_new(&screen, log_cb, NULL);
	ck_assert_int_eq(r, 0);

	r = tsm_screen_resize(screen, 20, 5);
	ck_assert_int_eq(r, 0);
	ck_assert_uint_eq(tsm_screen_get_width(screen), 20);
	ck_assert_uint_eq(tsm_screen_get_height(screen), 5);

	/* Fresh screen: cursor sits at the origin. */
	ck_assert_uint_eq(tsm_screen_get_cursor_x(screen), 0);
	ck_assert_uint_eq(tsm_screen_get_cursor_y(screen), 0);

	tsm_screen_unref(screen);
}
END_TEST

/* --- VTE input drives the screen ----------------------------------------- */

START_TEST(test_vte_plain_text)
{
	struct tsm_screen *screen;
	struct tsm_vte *vte;
	struct grid g;
	int r;

	r = tsm_screen_new(&screen, log_cb, NULL);
	ck_assert_int_eq(r, 0);
	r = tsm_screen_resize(screen, GRID_W, GRID_H);
	ck_assert_int_eq(r, 0);

	r = tsm_vte_new(&vte, screen, write_cb, NULL, log_cb, NULL);
	ck_assert_int_eq(r, 0);
	ck_assert_ptr_ne(vte, NULL);

	tsm_vte_input(vte, "hi", 2);

	/* Cursor advanced by the two printed characters. */
	ck_assert_uint_eq(tsm_screen_get_cursor_x(screen), 2);
	ck_assert_uint_eq(tsm_screen_get_cursor_y(screen), 0);

	/* Render the screen through the public draw callback and check output. */
	memset(&g, 0, sizeof(g));
	tsm_screen_draw(screen, draw_cb, &g);
	ck_assert_uint_eq(g.ch[0][0], (uint32_t)'h');
	ck_assert_uint_eq(g.ch[0][1], (uint32_t)'i');

	tsm_vte_unref(vte);
	tsm_screen_unref(screen);
}
END_TEST

START_TEST(test_vte_newline)
{
	struct tsm_screen *screen;
	struct tsm_vte *vte;
	int r;

	r = tsm_screen_new(&screen, log_cb, NULL);
	ck_assert_int_eq(r, 0);
	r = tsm_screen_resize(screen, 20, 5);
	ck_assert_int_eq(r, 0);
	r = tsm_vte_new(&vte, screen, write_cb, NULL, log_cb, NULL);
	ck_assert_int_eq(r, 0);

	/* CR+LF moves the cursor to the start of the next row. */
	tsm_vte_input(vte, "a\r\nb", 4);
	ck_assert_uint_eq(tsm_screen_get_cursor_y(screen), 1);
	ck_assert_uint_eq(tsm_screen_get_cursor_x(screen), 1);

	tsm_vte_unref(vte);
	tsm_screen_unref(screen);
}
END_TEST

/* --- Suite wiring -------------------------------------------------------- */

TEST_DEFINE_CASE(ucs4)
	TEST(test_ucs4_width)
	TEST(test_ucs4_to_utf8)
TEST_END_CASE

TEST_DEFINE_CASE(screen)
	TEST(test_screen_lifecycle)
	TEST(test_screen_resize)
TEST_END_CASE

TEST_DEFINE_CASE(vte)
	TEST(test_vte_plain_text)
	TEST(test_vte_newline)
TEST_END_CASE

TEST_DEFINE(
	TEST_SUITE(public_api,
		TEST_CASE(ucs4),
		TEST_CASE(screen),
		TEST_CASE(vte),
		TEST_END
	)
)
