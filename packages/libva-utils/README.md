# libva-utils

Утилита `vainfo` для диагностики VA-API.

## Источник упаковки

Упаковка взята из Debian (`libva-utils_2.23.0-1`, ветка 2.23 из `unstable`) и
переработана. Tarball взят из GitHub release **2.24.0** (git tag), а не из
Debian-овского `libva-utils_2.23.0.orig.tar.xz`: Debian-овский tarball содержит
только autotools-файлы (`make dist`), а `debian/rules` требует meson
(`--buildsystem=meson`). GitHub release включает `meson.build`, которые нужны
для сборки. Исходный код идентичен: тот же проект intel/libva-utils, версия
2.24.0 совместима с libva 2.24.1 (API стабилен, `libva-dev` требует `>= 1.6.0`).

## Версии

- **В trixie:** 2.22.0+ds1-2
- **В исходной упаковке:** 2.23.0-1
- **В нашем репозитории:** 2.24.0-1+crick (ревизия 1)

## Содержимое

| Пакет | Содержимое |
|---|---|
| `vainfo` | утилита `vainfo` — вывод информации о поддерживаемых VA-API профилях и драйвере |

Один бинарный пакет. В `override_dh_auto_install` удалены все демо-утилиты
(`mpeg2vldemo`, `loadjpeg`, `avcenc`, `h264encode`, `hevcencode`, `vp8enc`,
`vp9enc`, `av1encode` и т.п.) — остаётся только `vainfo`.

## Что изменено

### Отключено

- **X11-путь:** `-Dx11=false` отключает сборку `va_display_x11.c` и связь с
  `libva-x11-2`/`libx11-dev`. DRM и Wayland пути собираются. Из `Build-Depends`
  удалён `libx11-dev`.
- **Тесты:** `-Dtests=false`.
- **Документация:** не генерируется (никаких doc-опций в meson.build).
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

## Патчи

Нет: `debian/patches/series` отсутствует.

## Изменения ABI

`vainfo` собирается как статическая утилита. При `-Dx11=false` в `NEEDED`
бинарника нет `libva-x11.so.2`, `libx11.so.6`, `libX11.so.6`. Зависимости:
`libva.so.2`, `libva-drm.so.2`, `libva-wayland.so.2`, `libc.so.6`, `libdl.so.2`,
`libm.so.6`, `libpthread.so.2`.

## Важные нюансы

Собирается против нашего `libva 2.24.1` (без X11 и GLX). Проверка
`grep -rniE 'libx(11|ext|render)|libxcb|x11proto|x11-xkb|xvfb|xwayland'`
в `debian/control` даёт пустой результат.
