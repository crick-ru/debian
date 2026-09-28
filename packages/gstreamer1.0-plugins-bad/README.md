# gstreamer1.0-plugins-bad (crick Debian backports)

Сборка GStreamer Bad Plugins 1.28.7 для Debian 13 (trixie, amd64). Упаковка
взята из Debian (`gst-plugins-bad1.0 1.28.7-2`) и сильно упрощена.

## Включено

- `libgstreamer-plugins-bad1.0-0` и `-dev` — общие библиотеки набора
  (конвертер DXA, RTP/RTCP, GL-интеграция для Vulkan). **Здесь же живёт
  GstPlay** — та самая библиотека, за которой стоит `gstreamer-play-1.0.pc`,
  который требует медиабэкенд GTK 4. В 1.28.7 она в наборе «bad», а не в
  «base», — поэтому `gtk4` собирается в стадии 4, после этого пакета.
- `gstreamer1.0-plugins-bad` — элементы набора: аппаратное декодирование
  (VA-API, oneVPL, NVDEC/NVENC через библиотеку FFmpeg, Vulkan), аудиокодеки
  вне набора «good», элементы RTP/RTCP, субтитры и видеоконвертеры.
- `gir1.2-gst-plugins-bad-1.0` — данные GObject introspection.

## Отключено

- **X11**: `-Dx11=disabled` и `-Dvulkan-windowing=wayland`. В GStreamer 1.28.7
  `libxkbcommon` встречается ровно в двух местах — в плагине `wpe` и в окне
  XCB плагина `vulkan`. Оба выключены, поэтому наш
  `libgstreamer-plugins-bad1.0-0` **не зависит ни от `libxkbcommon-x11-0`, ни
  от `libxkbcommon0`**. Это и было целью: устаревшая версия из триxie
  (1.7.0-2, жёстко запинена `libxkbcommon-x11-0`) не должна попадать в
  систему, а наша `libxkbcommon0` 1.13.1 должна быть пригодна для GTK и
  pipewire. Проверка: `dpkg -s libgstreamer-plugins-bad1.0-0 | grep xkbcommon`
  не даёт совпадений.
- **wpe**: `-Dwpe=disabled -Dwpe2=disabled`. Плагин нужен только приложениям
  на WebKit (встраивание видео в веб-страницу); ни один пакет репозитория его
  не использует. Вдобавок `libwpewebkit-2.0-1` из триxie сам
  `Depends: libgstreamer-plugins-bad1.0-0`, то есть плагин создал бы
  зависимость нашей сборки на штатную. Пакет `gstreamer1.0-wpe` не
  публикуется, `libwpewebkit-2.0-dev` и `libwpebackend-fdo-1.0-dev` убраны из
  `Build-Depends`.
- **DVB-тюнеры и DVD**: `-Ddvb=disabled -Dresindvd=disabled`; `libdvdnav-dev`
  убран из `Build-Depends`. Опция DVD называется именно `resindvd` (плагин
  `libgstresindvd.so`): имени `dvdnav` в `meson.options` нет, а meson падает
  на неизвестной опции (`ERROR: Unknown options`). Правило — в
  `.clinerules/project.md`, раздел «Оптические диски и DVB-тюнеры
  отключаются».
- **OpenCV**: `-Dopencv=disabled`, как и в Debian: тяжёлая библиотека
  компьютерного зрения, в триxie тянет X11. `libopencv-dev` убран.
  Пакеты `gstreamer1.0-opencv` и `libgstreamer-opencv1.0-0` не публикуются.
- **Нейросетевые фильтры**: `-Donnx=disabled -Dtflite=disabled
  -Dtflite-edgetpu=disabled`. ONNX Runtime весит около 74 МБ вместе с
  зависимостями (`libonnx1t64`, `libdnnl3.6`, `libxnnpack0.20241108`,
  `libcpuinfo0`, `libpthreadpool0`, `libprotobuf32t64`, `libre2-11`), а
  ML-фильтры не нужны ни десктопу, ни серверу.
- **Устройства захвата**: `-Dbluez=disabled -Ddc1394=disabled -Dfbdev=disabled
  -Duvch264=disabled -Dv4l2codecs=disabled -Dlibrfb=disabled`. Bluetooth-звук
  обслуживает pipewire, камеры и framebuffer в целевом сценарии не нужны.
  Опция VNC-источника называется `librfb` (`gst/librfb`), имени `rfb` в
  `meson.options` нет. Строка `libgstrfbsrc.so` убрана из
  `gstreamer1.0-plugins-bad.install`.
- **Платформенное и тяжёлое**: `-Dladspa=disabled -Dlv2=disabled
  -Dopenni2=disabled -Dwebrtc=disabled -Dsctp=disabled -Dmicrodns=disabled
  -Dopensles=disabled -Dtinyalsa=disabled -Dmagicleap=disabled
  -Ddirectfb=disabled -Damfcodec=disabled -Dandroidmedia=disabled
  -Dfaac=disabled -Dgs=disabled -Diqa=disabled -Disac=disabled -Dldac=disabled
  -Dmsdk=disabled -Dlcevcdecoder=disabled -Dlcevcencoder=disabled
  -Dsvtjpegxs=disabled -Dcuda-nvmm=disabled -Dnvcomp=disabled
  -Dnvdswrapper=disabled -Dmpeghdec=disabled -Dvmaf=disabled -Dfdkaac=disabled
  -Dfaad=disabled` — тот же список, что и в Debian, только без вариантов для
  не-Linux.
- Документация и примеры: `-Ddoc=disabled -Dexamples=disabled`; man-страниц
  нет.
- Тесты: `-Dtests=disabled`, `xvfb` и `xauth` убраны из `Build-Depends`.
- Утилиты `gst-transcoder-service` и `gst-transcoder` из
  `gstreamer1.0-plugins-bad-apps` не публикуются.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Версия: `1.28.7-1+crick`.
- Пакет `gstreamer1.0-plugins-bad` в Debian объявляет `Breaks` и `Replaces`
  на `gstreamer1.0-plugins-base` и `gstreamer1.0-plugins-good` версий
  ancient (`<< 0.11.94`, `<< 1.1.2`) — они не перенесены, они относятся к
  2008 году.
- `Maintainer`: нейтральная идентичность проекта.

## Влияние на систему и откат

`libgstreamer1.0-plugins-bad1.0-dev` больше не подтягивает `libopencv-dev`
и `libgstreamer-opencv1.0-0`, а `gstreamer1.0-wpe` и `gstreamer1.0-opencv`
из триxie будут сняты. Если нужны, верните триxie-пакеты:

```
apt install gstreamer1.0-wpe/trixie gstreamer1.0-opencv/trixie
```
