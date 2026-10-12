# gstreamer1.0-plugins-base

Базовый набор плагинов GStreamer 1.28: библиотеки `libgstreamer-plugins-base1.0-0`,
`libgstreamer-gl1.0-0`, GL-плагины, ALSA-плагин, Ogg/Vorbis/Theora/Opus,
RTP/RTSP/SDP, конвертеры, playbin/decodebin.

## Источник упаковки

Упаковка взята из Debian (`gst-plugins-base1.0_1.28.7-1`, ветка unstable) и
переработана. Tarball побайтово совпадает с Debian-овским
`gst-plugins-base-1.28.7.orig.tar.xz`.

## Версии

- **В trixie:** 1.26.2-1+deb13u2
- **В исходной упаковке:** 1.28.7-1
- **В нашем репозитории:** 1.28.7-2+crick (ревизия 2 — из-за правок)

Все пять пакетов GStreamer носят одну строку версии: их `-dev`-пакеты пинят
sibling-пакеты `= ${binary:Version}`.

## Содержимое

- `libgstreamer-plugins-base1.0-0` — библиотеки audio, video, app, RTP/RTSP/SDP, FFT, tag
- `libgstreamer-plugins-base1.0-dev` — заголовки, GIR
- `libgstreamer-gl1.0-0` — GL-интеграция (Wayland/EGL)
- `gstreamer1.0-gl` — GL-плагины
- `gstreamer1.0-plugins-base` — конвертеры, playbin, decodebin, typefinder, парсер субтитров, Ogg, Vorbis, Opus
- `gstreamer1.0-alsa` — ALSA audio source/sink
- `gir1.2-gst-plugins-base-1.0` — GIR

## Что изменено

### Отключено

- **X11** (правило репозитория): `-Dx11=disabled -Dxshm=disabled
  -Dxvideo=disabled -Dxi=disabled`. Исчезают `ximagesink` и `xvimagesink`,
  а также X11 внутри библиотек. Из `Build-Depends` убраны `libx11-xcb-dev`,
  `libxi-dev`, `libxt-dev`, `libxv-dev`. Пакет `gstreamer1.0-x` не публикуется.
- **Аудио-CD** (правило репозитория): `-Dcdparanoia=disabled`. `libcdparanoia-dev`
  убран из `Build-Depends`.
- **Theora** (устаревший кодек): `-Dtheora=disabled`. `libtheora-dev`
  убран из `Build-Depends`. Плагин `libgsttheora.so` не публикуется.
- **Утилиты для сопровождения:** пакет `gstreamer1.0-plugins-base-apps`
  (`gst-play-1.0`, `gst-discoverer-1.0`, `gst-device-monitor-1.0`) не
  публикуется. Утилиты и man-страницы удаляются из staging-дерева в
  `override_dh_auto_install`.
- **Документация:** `-Ddoc=disabled`. **Примеры:** `-Dexamples=disabled`.
- **Тесты:** `-Dtests=disabled`, `xvfb` и `xauth` убраны из `Build-Depends`.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- GL только под Wayland и EGL: `-Dgl_winsys=wayland,egl -Dgl_platform=egl`.
  Без этого `libgstreamer-gl1.0-0` получил бы зависимости `libx11-6` и
  `libxcb1`.
- Плагин `pango` (текстовые наложения, субтитры) остаётся: использует
  `pangocairo`, а не X11.
- `libvorbis` и `libopus` включены.

## Патчи

Нет: `debian/patches/series` отсутствует.

## Изменения ABI

SONAME библиотек не менялись. X11-видеосинки (`ximagesink`, `xvimagesink`) —
это отдельные плагины, а не часть ABI.

**Исключение — `libgstreamer-gl1.0-0`:** при выключении X11 удалены три
символа (`gst_gl_display_x11_get_type`, `gst_gl_display_x11_new`,
`gst_gl_display_x11_new_with_display`). SONAME `libgstgl-1.0.so.0` прежний,
символы пропали — `debian/libgstreamer-gl1.0-0.symbols` перегенерирован.
Программы, вызывающие `gst_gl_display_x11_*` напрямую, не запустятся.
`mpv`, `celluloid` и `sfwbar` из этого репозитория таких вызовов не делают.

## Важные нюансы

- GL и GLES берутся из этого репозитория: `libegl-dev`, `libegl1`,
  `libgles-dev`, `libgles1`, `libgles2`, `libopengl-dev`, `libopengl0`,
  `libglvnd0` ставятся из сборки `libglvnd` (см. `packages/libglvnd/README.md`).
- `libgl-dev` убран из `Build-Depends`: `libgstgl-1.0.so` линкуется только с
  `libEGL.so.1`.
