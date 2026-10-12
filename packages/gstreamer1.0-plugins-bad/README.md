# gstreamer1.0-plugins-bad

Плагины GStreamer 1.28 из набора «bad»: аппаратное декодирование (VA-API,
oneVPL, NVDEC/NVENC, Vulkan), аудиокодеки, RTP/RTCP, субтитры, видеоконвертеры,
GL-интеграция Vulkan.

## Источник упаковки

Упаковка взята из Debian (`gst-plugins-bad1.0_1.28.7-2`, ветка unstable) и
переработана. Tarball побайтово совпадает с Debian-овским
`gst-plugins-bad-1.28.7.orig.tar.xz`.

## Версии

- **В trixie:** 1.26.2-3+deb13u3
- **В исходной упаковке:** 1.28.7-2
- **В нашем репозитории:** 1.28.7-4+crick (ревизия 4 — из-за выключения
  DeckLink/AJA/gme/OpenAL/OpenEXR)

Все пять пакетов GStreamer носят одну строку версии `1.28.7-1+crick`.

## Содержимое

- `libgstreamer-plugins-bad1.0-0` — общие библиотеки: DXA-конвертер, RTP/RTCP,
  GL-интеграция Vulkan
- `libgstreamer-plugins-bad1.0-dev` — заголовки, GIR
- `gstreamer1.0-plugins-bad` — плагины набора
- `gir1.2-gst-plugins-bad-1.0` — GIR

## Что изменено

### Отключено

- **X11** (правило репозитория): `-Dx11=disabled`. В 1.28.7 `libxkbcommon`
  встречается только в плагине `wpe` и окне XCB плагина Vulkan — оба выключены,
  поэтому `libgstreamer-plugins-bad1.0-0` не зависит ниот `libxkbcommon-x11-0`,
  ни от `libxkbcommon0`.
- **wpe:** `-Dwpe=disabled -Dwpe2=disabled`. Плагин нужен только WebKit-приложениям;
  ни один пакет репозитория его не использует; `libwpewebkit-2.0-1` из trixie
  `Depends` на наш пакет.
- **DVB-тюнеры:** `-Ddvb=disabled`.
- **DVD навигация** (правило репозитория): `-Dresindvd=disabled`. Именно
  `resindvd`, а не `dvdnav`. `libdvdnav-dev` убран из `Build-Depends`.
- **OpenCV** (правило репозитория): `-Dopencv=disabled`, как и в Debian.
- **Нейросетевые фильтры:** `-Donnx=disabled -Dtflite=disabled`
  `-Dtflite-edgetpu=disabled`. ONNX Runtime ~74 МБ с зависимостями.
- **Vulkan Video:** `-Dvulkan-video=disabled` (заголовков нет в trixie).
- **Платформенное/тяжёлое:** `-Dbluez=disabled -Ddc1394=disabled
  -Dfbdev=disabled -Duvch264=disabled -Dv4l2codecs=disabled
  -Dlibrfb=disabled -Dladspa=disabled -Dlv2=disabled -Dsbc=disabled
  -Dopenni2=disabled -Dwebrtc=disabled -Dsctp=disabled -Dmicrodns=disabled
  -Dopensles=disabled -Dtinyalsa=disabled -Dmagicleap=disabled
  -Ddirectfb=disabled -Damfcodec=disabled -Dandroidmedia=disabled
  -Dfaac=disabled -Dgs=disabled -Diqa=disabled -Disac=disabled
  -Dldac=disabled -Dmsdk=disabled -Dmpeghdec=disabled -Dvmaf=disabled
  -Dfdkaac=disabled -Dfaad=disabled`.
- **DeckLink, AJA, gme, OpenAL, OpenEXR:** `-Ddecklink=disabled -Daja=disabled
  -Dgme=disabled -Dopenal=disabled -Dopenexr=disabled`. Из `Build-Depends`
  убраны `libopenal-dev`, `libopenexr-dev`, `libgme-dev`; из `.install` убраны
  `libgstdecklink.so`, `libgstgme.so`, `libgstopenal.so`, `libgstopenexr.so`.
- **Утилиты gst-transcoder:** `gst-transcoder-1.0` и
  `gst-transcoder-service` удаляются из staging-дерева.
- **Документация:** `-Ddoc=disabled`.
- **Тесты:** `-Dtests=disabled`, `xvfb`/`xauth` убраны из `Build-Depends`.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- Vulkan: `-Dvulkan=enabled -Dvulkan-windowing=wayland`.
- GL: `-Dauto_features=enabled`.
- `libssl-dev` добавлен для плагинов `libgstaes.so` и `libgstdtls.so`.
- `libdrm-dev`, `zlib1g-dev`, `libopengl-dev`, `libegl-dev`, `libgles-dev`
  добавлены из-за `.pc`-файлов нашего `gstreamer1.0-plugins-base`.

## Патчи

Нет: `debian/patches/series` отсутствует.

## Важные нюансы

- `gstreamer1.0-plugins-bad` ставится на стадии 4 CI: он содержит
  `gstreamer-play-1.0.pc`, который требуется `gtk4`.
- VA-API берётся из этого репозитория (`libva`) и из `libglvnd`.
- `gstreamer1.0-wpe`, `gstreamer1.0-opencv` и `gstreamer1.0-plugins-bad-apps`
  не публикуются.
