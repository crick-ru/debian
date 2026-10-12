# mpv

Видеоплеер на базе MPlayer/mplayer2 с поддержкой широкого спектра форматов.

## Источник упаковки

Упаковка взята из Debian (`mpv_0.41.0-2`, ветка 0.41, `unstable`) и
переработана. Tarball побайтово совпадает с Debian-овским `mpv_0.41.0.orig.tar.gz`.

## Версии

- **В trixie:** 0.311.0-1
- **В исходной упаковке:** 0.41.0-2
- **В нашем репозитории:** 0.41.0-3+crick (ревизия 3 — апгрейд версии +
  отключение оптических дисков, DVB и VDPAU)

## Содержимое

| Пакет | Содержимое |
|---|---|
| `mpv` | видеоплеер `mpv` |
| `libmpv2` | `libmpv.so.2` — клиентская библиотека (нужна `celluloid`) |
| `libmpv-dev` | заголовки, `libmpv.pc`, `libmpv.so` |

## Что изменено

### Отключено

- **X11 и все бэкенды X11:** `-Dx11=disabled`, `-Degl-x11=disabled`,
  `-Dgl-x11=disabled`, `-Dvaapi-x11=disabled`, `-Dxv=disabled`,
  `-Dx11-clipboard=disabled`. Пакеты не объявляют зависимостей `libx11*`.
- **Оптические диски:** `-Dcdda=disabled` (CD-аудио), `-Ddvdnav=disabled`,
  `-Dlibbluray=disabled` (Blu-ray), `-Dlibarchive=disabled` (движок чтения
  BD/ISO). Из `Build-Depends` и `Depends` `libmpv-dev` удалены `libcdio-dev`,
  `libcdio-paranoia-dev`, `libdvdnav-dev`, `libbluray-dev`, `libarchive-dev`.
- **DVB-тюнеры:** `-Ddvbin=disabled`.
- **VDPAU:** `-Dvdpau=disabled`, `-Dvdpau-gl-x11=disabled`. Из `Build-Depends`
  удалён `libvdpau-dev`.
- **JACK:** `-Djack=disabled`. Из `Build-Depends` удалён `libjack-dev`.
- **Тесты:** `-Dtests=false`.
- **Man-страницы:** `-Dmanpage-build=false`. Из `Build-Depends` удалён
  `python3-docutils` (больше нет `rst2man`). Готовых man-страниц в tar-боле
  нет, `man mpv` не документирован — осознанная плата за правило
  «документация не собирается».
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- **Wayland:** `-Dwayland=enabled`, `-Degl-wayland=enabled`,
  `-Ddmabuf-wayland=enabled`, `-Dvaapi-wayland=enabled` — аппаратное
  декодирование через VA-API под Wayland.
- **Клиентская библиотека:** `-Dlibmpv=true` (нужна `celluloid`).
- **Воспроизводимость:** `-Dbuild-date=false`.
- **Все аппаратные ускорители из репозитория:** `-Dvulkan=enabled`,
  `-Dlibplacebo`, NVENC/NVDEC (`-Dffmpeg-nvenc=enabled`).

## Патчи

Нет: `debian/patches/series` отсутствует.

## Изменения ABI

`libmpv.so.2` — SONAME не меняется. Символы не удаляются.

## Важные нюансы

### Сборка против наших пакетов

`mpv` собирается против FFmpeg 9.0.2 этого репозитория (стадия 1 CI), а не
против версии из trixie: `libavcodec-dev (>= 7:7.0)` закрывает только сборку
с epoch 7.

`libva-dev`, `libva-drm2`, `libva-wayland2` — из нашей сборки `libva`
(см. `packages/libva/README.md`). Штатный `libva-dev` несовместим с нашим
`libglvnd0`.

`libegl-dev`, `libegl1`, `libgles-dev`, `libgles2`, `libgbm-dev`,
`mesa-libgallium` — из нашей сборки `mesa` (см. `packages/mesa/README.md`).
Штатный `libegl-dev` несовместим с нашей `mesa-common-dev`.

### X11 в apt upgrade

Штатный mpv из trixie (`0.311.0-1`) может иметь X11-символы. При `apt upgrade`
переход на нашу сборку (без X11) проходит без проблем: mpv — приложение, а
не библиотека, его `Depends` скрываются в `${shlibs:Depends}`.
