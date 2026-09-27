# labwc (crick Debian backports)

Сборка `labwc` 0.20.2 для Debian 13 (trixie, amd64): компактный скриптуемый
Wayland-композитор.

## Включено

- Библиотека композитора `wlroots` 0.20.2 из этого репозитория: бэкенды
  DRM/libinput без Xwayland (см. `packages/wlroots/README.md`).
- `libwayland`, `libdrm`, `libxkbcommon` и `pixman` также берутся из этого
  репозитория — labwc собирается в стадии 3 CI сразу после wlroots и
  библиотек из стадии 1.

## Отключено

- **Xwayland**: `-Dxwayland=disabled`. X11-клиентам потребуется XWayland из
  другого источника либо вложенный Wayland-композитор.
- Man-страницы не генерируются (`-Dman-pages=disabled`), поэтому убран
  `scdoc`, а `labwc.1`, `labwc-actions.5`, `labwc-config.5`, `labwc-menu.5`,
  `labwc-theme.5` и `labnag.1` в поставку не входят.
- Тесты не собираются и не запускаются (`-Dtest=disabled`).
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Версия: `0.20.2-2+crick` (ревизия 2 — из-за переработки упаковки).
- Дополнительных правок поверх апстрим-упаковки Debian нет; исходники
  накладываются скриптом `scripts/build-package.sh`.
- Требования к версиям зависимостей не понижались: libwlroots 0.20.2,
  libinput 1.28.1, wayland 1.26.0, wayland-protocols 1.44 и libsfdo 0.1.3
  в trixie доступны в нужных версиях.
- `cairo` берётся из trixie при сборке labwc: `dependency('cairo')` в meson
  не имеет нижней границы версии, поэтому 1.18.4 из trixie подходит. labwc
  использует только `cairo_image_surface_*` и `cairo_create` — ни одного
  вызова `cairo_xlib_*`/`cairo_xcb_*` в исходниках 0.20.2 нет, поэтому и
  сборка против `libcairo2` этого репозитория без X11-бэкендов, и сборка
  против штатного trixie одинаково корректны (см.
  `packages/cairo/README.md`).

