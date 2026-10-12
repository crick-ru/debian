# gstreamer1.0-plugins-good

Плагины GStreamer 1.28 из набора «good»: Matroska/FLV/RTP-демультиплексоры,
кодеки VP8/VP9, FLAC, MP3, AAC, видеофильтры, адаптивный демультиплексор.

## Источник упаковки

Упаковка взята из Debian (`gst-plugins-good1.0_1.28.7-1`, ветка unstable) и
переработана. Tarball побайтово совпадает с Debian-овским
`gst-plugins-good-1.28.7.orig.tar.xz`.

## Версии

- **В trixie:** 1.26.2-1+deb13u2
- **В исходной упаковке:** 1.28.7-1
- **В нашем репозитории:** 1.28.7-3+crick (ревизия 3 — из-за переработки набора
  плагинов)

Все пять пакетов GStreamer носят одну строку версии `1.28.7-1+crick`.

## Содержимое

Единственный пакет: `gstreamer1.0-plugins-good` — плагины набора.

## Что изменено

### Отключено

- **Видеосинки Qt** (правило репозитория): `-Dqt5=disabled -Dqt6=disabled`.
  Это QML/X11-ориентированный API. Пакеты `gstreamer1.0-qt5`/`gstreamer1.0-qt6`
  не публикуются, `qtbase5-dev`/`qttools5-dev`/`qttools6` убраны из `Build-Depends`.
- **Видеосинк GTK 3** (правило репозитория): `-Dgtk3=disabled`. Пакет
  `gstreamer1.0-gtk3` не публикуется, `libgtk-3-dev` убран из `Build-Depends`.
- **X11** (правило репозитория): `-Dximagesrc=disabled`. Плагин `ximagesrc`
  (снимок экрана X11) не собирается. В `gst-plugins-good` 1.28.7 опции `x11`
  **не существует** — есть `ximagesrc` и подопции, поэтому `-Dx11=disabled`
  обрывал конфигурацию с `ERROR: Unknown options: x11`.
- **PulseAudio** (правило репозитория): `-Dpulse=disabled`. Плагин
  `libgstpulseaudio.so` не публикуется: звук обслуживает `pipewire`.
  `libpulse-dev` убран из `Build-Depends`.
- **V4L2** (правило репозитория): `-Dv4l2=disabled`. Плагин
  `libgstvideo4linux2.so` не публикуется: телекамеры и ТВ-тюнеры.
- **JACK** (правило репозитория): `-Djack=disabled`. Плагин `libgstjack.so`
  не публикуется. `libjack-jackd2-dev` убран из `Build-Depends`.
- **Вывод видео в текстовую консоль** (правило репозитория): `-Dlibcaca=disabled`
  и `-Daalib=disabled`. Плагины `libgstcacasink.so` и `libgstaasink.so` не
  публикуются. Из `Build-Depends` убраны `libcaca-dev` и `libaa1-dev`.
- **OSSv4:** `-Doss4=disabled`.
- **Icecast/Shout:** `-Dshout2=disabled`. Плагин `libgstshout2.so` не публикуется.
  `libshout-dev` убран из `Build-Depends`.
- **AMR, Speex, WavPack, audiofx:** `-Ddamrnb=disabled -Damrwbdec=disabled
  -Dspeex=disabled -Dwavpack=disabled -Daudiofx=disabled`. Из `Build-Depends`
  убраны `libopencore-amrnb-dev`, `libopencore-amrwb-dev`, `libspeex-dev`,
  `libwavpack-dev`; из `.install` убраны соответствующие плагины.
- **Документация:** `-Ddoc=disabled`.
- **Тесты:** `-Dtests=disabled`, `xvfb` и `xauth` убраны из `Build-Depends`.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- `-Dauto_features` не задаётся намеренно: встроенная опция meson превращает
  все `auto`-опции в `enabled`, что приводило к сборке с `nasm`, `libraw1394`,
  `libgudev`, `libv4l2` — библиотек, от которых отказались.

## Патчи

Нет: `debian/patches/series` отсутствует.

## Важные нюансы

- В 1.28.7 набор не производит общих библиотек: `gst-libs/gst` содержит только
  заголовок. Поэтому `libgstreamer-plugins-good1.0-0`, `-dev` и
  `gir1.2-gst-plugins-good-1.0` не публикуются.
- `gstreamer1.0-plugins-good.install` перечисляет ровно 60 плагинов, которые
  фактически собираются при флагах из `debian/rules`. Любое расхождение
  останавливает сборку (`dh_missing --fail-missing`).
- `libdrm-dev` и `zlib1g-dev` добавлены из-за `.pc`-файлов нашего
  `gstreamer1.0-plugins-base`.
