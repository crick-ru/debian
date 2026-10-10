# libva-utils

Утилита `vainfo` для диагностики VA-API (Video Acceleration API). Собирается
против нашего `libva 2.24.1` (без X11 и GLX).

## Упаковка

Упаковка взята из Debian (`libva-utils_2.23.0-1`, ветка 2.23 из unstable) и
переработана. Взята именно `unstable`, а не `trixie` (там `2.22.0+ds1-2`) —
по правило «Источник упаковки» порядок выбора начинается с unstable.

Tarball взят не из пула Debian, а из GitHub release 2.24.0 (git tag
`2.24.0`). Debian-овский `libva-utils_2.23.0.orig.tar.xz` содержит только
autotools-файлы (создан `make dist`), а `debian/rules` требует meson
(`--buildsystem=meson`). GitHub release tarball включает `meson.build` и
`meson_options.txt`, которые нужны для сборки. Исходный код идентичен: тот же
проект intel/libva-utils, версия 2.24.0 совместима с libva 2.24.1 (API стабилен,
`libva-dev` требует только `>= 1.6.0`).

Переработано:
- `control`: `libx11-dev` удалён из `Build-Depends` — X11 не собирается;
- `rules`: добавлена `-Dx11=false` к `dh_auto_configure`;
- `override_dh_auto_install`: удалены все демо-утилиты, остаётся только `vainfo`.

## Отключённые компоненты

1. **X11-путь VA-API**: `-Dx11=false` отключает сборку `va_display_x11.c` и
   связь с `libva-x11-2`/`libx11-dev`. Путь DRM (`va_display_drm.c`) и Wayland
   (`va_display_wayland.c`) собираются — `vainfo` работает через
   `LIBVA_DRIVER_NAME=drm` и в Wayland-сессии.

2. **Тесты**: `-Dtests=false` (опция `tests` по умолчанию `false`, выставлена
   явно). Сборка gtest и `test_va_api` не выполняется.

3. **Документация**: не генерируется (никаких doc-опций в meson.build, man-страница
   `vainfo.1` — статическая, из `debian/vainfo.1`).

4. **Демо-утилиты**: `mpeg2vldemo`, `loadjpeg`, `avcenc`, `h264encode`,
   `hevcencode`, `vp8enc`, `vp9enc`, `av1encode` и т.п. удаляются в
   `override_dh_auto_install` — не являются частью публичного API.

5. **dbgsym-пакеты**: не собираются (общее правило `scripts/build-package.sh`).

## Что публикуется

Один бинарный пакет:

| Пакет | Что внутри |
|---|---|
| `vainfo` | утилита, выводящая информацию о поддерживаемых VA-API профилях и драйвере |

## Символы и ABI

`vainfo` собирается как статическая утилита (`meson.build`:
`default_library=static`). При `-Dx11=false` в `NEEDED` бинарника нет
`libva-x11.so.2`, `libx11.so.6` и `libX11.so.6` — X11-only символы
(`HAVE_VA_X11`) не определены. Зависимости: `libva.so.2`, `libva-drm.so.2`,
`libva-wayland.so.2`, `libc.so.6`, `libdl.so.2`, `libm.so.6`, `libpthread.so.2`.

## Откат

Чтобы вернуть X11:
1. Убрать `-Dx11=false` из `debian/rules`;
2. Добавить `libx11-dev` обратно в `Build-Depends`;
3. Поднять ревизию на 2.

Это нарушает правило репозитория (нет X11).
