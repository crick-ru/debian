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
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Дополнительных правок поверх апстрим-упаковки Debian нет; исходники
  накладываются скриптом `scripts/build-package.sh`.
- Требования к версиям зависимостей не понижались: libwlroots 0.20.2,
  libinput 1.28.1, wayland 1.26.0, wayland-protocols 1.44 и libsfdo 0.1.3
  в trixie доступны в нужных версиях.

