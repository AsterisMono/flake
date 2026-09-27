#define _POSIX_C_SOURCE 200809L
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <linux/input-event-codes.h>
#include <wayland-client.h>
#include "vpointer.h"

struct state {
  struct wl_seat *seat;
  struct wl_output *output;
  struct zwlr_virtual_pointer_manager_v1 *mgr;
  struct zwlr_virtual_pointer_v1 *ptr;
  uint32_t mgr_version;
  int x, y;
  int click;
};

static void noop(void) {}

static void global(void *data, struct wl_registry *registry, uint32_t name, const char *iface, uint32_t version) {
  struct state *s = data;
  if (strcmp(iface, wl_seat_interface.name) == 0 && !s->seat)
    s->seat = wl_registry_bind(registry, name, &wl_seat_interface, version < 7 ? version : 7);
  if (strcmp(iface, wl_output_interface.name) == 0 && !s->output)
    s->output = wl_registry_bind(registry, name, &wl_output_interface, version < 4 ? version : 4);
  if (strcmp(iface, zwlr_virtual_pointer_manager_v1_interface.name) == 0 && !s->mgr) {
    s->mgr_version = version;
    s->mgr = wl_registry_bind(registry, name, &zwlr_virtual_pointer_manager_v1_interface, version < 2 ? version : 2);
  }
}

static const struct wl_registry_listener reg_listener = { .global = global, .global_remove = (void *)noop };
static const struct wl_output_listener output_listener = {
  .geometry = (void *)noop,
  .mode = (void *)noop,
  .done = (void *)noop,
  .scale = (void *)noop,
  .name = (void *)noop,
  .description = (void *)noop,
};

static uint32_t now_ms(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (uint32_t)(ts.tv_sec * 1000 + ts.tv_nsec / 1000000);
}

static void pause_ms(int ms) {
  struct timespec ts = { .tv_sec = ms / 1000, .tv_nsec = (long)(ms % 1000) * 1000000L };
  nanosleep(&ts, NULL);
}

int main(int argc, char **argv) {
  if (argc < 3) {
    fprintf(stderr, "usage: pointer-click X Y [c]\n");
    return 2;
  }
  struct state s = {0};
  s.x = atoi(argv[1]);
  s.y = atoi(argv[2]);
  s.click = argc >= 4 && argv[3][0] == 'c';
  struct wl_display *dpy = wl_display_connect(NULL);
  if (!dpy) { perror("wl_display_connect"); return 1; }
  struct wl_registry *reg = wl_display_get_registry(dpy);
  wl_registry_add_listener(reg, &reg_listener, &s);
  wl_display_roundtrip(dpy);
  if (!s.seat || !s.mgr || !s.output) {
    fprintf(stderr, "missing seat=%p mgr=%p output=%p version=%u\n", (void *)s.seat, (void *)s.mgr, (void *)s.output, s.mgr_version);
    return 1;
  }
  wl_output_add_listener(s.output, &output_listener, &s);
  wl_display_roundtrip(dpy);
  if (s.mgr_version < 2) {
    fprintf(stderr, "virtual pointer manager version %u has no output binding\n", s.mgr_version);
    return 1;
  }
  s.ptr = zwlr_virtual_pointer_manager_v1_create_virtual_pointer_with_output(s.mgr, s.seat, s.output);
  wl_display_roundtrip(dpy);
  uint32_t t = now_ms();
  zwlr_virtual_pointer_v1_motion_absolute(s.ptr, t, (uint32_t)s.x, (uint32_t)s.y, 1920, 1080);
  zwlr_virtual_pointer_v1_frame(s.ptr);
  wl_display_flush(dpy);
  wl_display_roundtrip(dpy);
  pause_ms(80);
  if (s.click) {
    t = now_ms();
    zwlr_virtual_pointer_v1_button(s.ptr, t, BTN_LEFT, WL_POINTER_BUTTON_STATE_PRESSED);
    zwlr_virtual_pointer_v1_frame(s.ptr);
    wl_display_roundtrip(dpy);
    pause_ms(40);
    t = now_ms();
    zwlr_virtual_pointer_v1_button(s.ptr, t, BTN_LEFT, WL_POINTER_BUTTON_STATE_RELEASED);
    zwlr_virtual_pointer_v1_frame(s.ptr);
    wl_display_roundtrip(dpy);
  }
  fprintf(stderr, "pointer output-bound x=%d y=%d click=%d\n", s.x, s.y, s.click);
  return 0;
}
