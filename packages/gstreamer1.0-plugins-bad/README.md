# gstreamer1.0-plugins-bad (crick Debian backports)

Сборка GStreamer Bad Plugins 1.28.7 для Debian 13 (trixie, amd64). Упаковка
взята из Debian (`gst-plugins-bad1.0_1.28.7-2`, ветка unstable) и переработана.

## Включено

- `libgstreamer-plugins-bad1.0-0` и `-dev` — общие библиотеки набора
  (конвертер DXA, RTP/RTCP, **VA-API, Vulkan, HIP, CUDA и Wayland**).
  **Здесь же живёт GstPlay** — та самая библиотека, за которой стоит
  `gstreamer-play-1.0.pc`, который требует медиабэкенд GTK 4. В 1.28.7 она в
  наборе «bad», а не в «base», — поэтому `gtk4` собирается в стадии 4, после
  этого пакета.
- `gstreamer1.0-plugins-bad` — элементы набора: аппаратное декодирование
  (VA-API, oneVPL, NVDEC/NVENC через библиотеку FFmpeg, Vulkan), аудиокодеки
  вне набора «good», элементы RTP/RTCP, субтитры и видеоконвертеры. Сюда же
  попадают плагины, собираемые без внешних SDK: `kms`, `qsv`, `uvcgadget`,
  `hip` (драйверы и библиотеки вроде ROCm, Intel MFX и AMD они загружают
  в рантайме, поэтому в `Build-Depends` их нет). Плагины BlackMagic
  (`libgstdecklink.so`) и AJA (`libgstaja.so`) выключены — см. «Отключено».
- `gir1.2-gst-plugins-bad-1.0` — данные GObject introspection.

## Отключено

- **X11**: `-Dx11=disabled` и `-Dvulkan-windowing=wayland`. В GStreamer 1.28.7
  `libxkbcommon` встречается ровно в двух местах — в плагине `wpe` и в окне
  XCB плагина `vulkan`. Оба выключены, поэтому наш
  `libgstreamer-plugins-bad1.0-0` **не зависит ни от `libxkbcommon-x11-0`, ни
  от `libxkbcommon0`**. Эта цель достигается: устаревшая версия из trixie
  (1.7.0-2, жёстко запинена `libxkbcommon-x11-0`) не должна попадать в
  систему, а наша `libxkbcommon0` 1.13.1 должна быть пригодна для GTK и
  pipewire. Проверка: `dpkg -s libgstreamer-plugins-bad1.0-0 | grep xkbcommon`
  не даёт совпадений.
- **wpe**: `-Dwpe=disabled -Dwpe2=disabled`. Плагин нужен только приложениям
  на WebKit (встраивание видео в веб-страницу); ни один пакет репозитория его
  не использует. Вдобавок `libwpewebkit-2.0-1` из trixie сам
  `Depends: libgstreamer-plugins-bad1.0-0`, то есть плагин создал бы
  зависимость нашей сборки на штатную. Пакет `gstreamer1.0-wpe` не
  публикуется, `libwpewebkit-2.0-dev` и `libwpebackend-fdo-1.0-dev` убраны из
  `Build-Depends`.
- **DVB-тюнеры и DVD**: `-Ddvb=disabled -Dresindvd=disabled`; `libdvdnav-dev`
  убран из `Build-Depends`. Опция DVD называется именно `resindvd` (плагин
  `libgstresindvd.so`): имени `dvdnav` в `meson.options` нет, а meson падает
  на неизвестной опции (`ERROR: Unknown options`). Отключается по правилам
  проекта.
- **OpenCV**: `-Dopencv=disabled`, как и в Debian: тяжёлая библиотека
  компьютерного зрения, в trixie тянет X11. `libopencv-dev` убран.
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
- **Платформенное и тяжёлое**: `-Dladspa=disabled -Dlv2=disabled -Dsbc=disabled
  -Dopenni2=disabled -Dwebrtc=disabled -Dsctp=disabled -Dmicrodns=disabled
  -Dopensles=disabled -Dtinyalsa=disabled -Dmagicleap=disabled
  -Ddirectfb=disabled -Damfcodec=disabled -Dandroidmedia=disabled
  -Dfaac=disabled -Dgs=disabled -Diqa=disabled -Disac=disabled -Dldac=disabled
  -Dmsdk=disabled -Dlcevcdecoder=disabled -Dlcevcencoder=disabled
  -Dsvtjpegxs=disabled -Dcuda-nvmm=disabled -Dnvcomp=disabled
  -Dnvdswrapper=disabled -Dmpeghdec=disabled -Dvmaf=disabled -Dfdkaac=disabled
  -Dfaad=disabled` — тот же список, что и в Debian, только без вариантов для
  не-Linux.
- **DeckLink, AJA, gme, OpenAL и OpenEXR**: `-Ddecklink=disabled
  -Daja=disabled -Dgme=disabled -Dopenal=disabled -Dopenexr=disabled`. Плагины
  `libgstdecklink.so` (BlackMagic), `libgstaja.so` (AJA), `libgstgme.so`
  (игровая музыка), `libgstopenal.so` (OpenAL) и `libgstopenexr.so` (OpenEXR)
  не публикуются: ни один пакет репозитория их не использует, а SDK
  BlackMagic/AJA — проприетарные и отсутствуют. Из `Build-Depends` убраны
  `libopenal-dev`, `libopenexr-dev` и `libgme-dev`; из `.install` —
  `libgstdecklink.so`, `libgstgme.so`, `libgstopenal.so`, `libgstopenexr.so`.
  `libgstaja.so` в `.install` не попадает: плагин не публикуется.
- **Vulkan Video**: `-Dvulkan-video=disabled`. Кодирование и декодирование
  через Vulkan Video Extensions выключено: в trixie нет заголовков
  `vulkan_video_codec_*.h` (их даёт `libvulkan-dev` в более новых версиях
  Khronos), а с `-Dauto_features=enabled` опция `auto` становится обязательной
  и конфигурация падала с `Vulkan Video extensions headers not found`. Сам
  плагин `vulkan` и библиотека `libgstvulkan-1.0` при этом собираются.
- **Плагины без сборочных зависимостей**: `-Dauto_features` намеренно не
  задаётся. Эта встроенная опция meson превращает все опции `auto` в
  `enabled`, то есть необязательные зависимости становятся обязательными;
  для этого набора сборка последовательно падала на отсутствующих
  `libajantv2` (AJA NTV2), `vulkan_video_codec_*.h` и других. Состав набора
  задают перечисленные ниже отключения плюс фактический состав
  `Build-Depends`.
- **`libssl-dev`**: добавлен ради плагинов `libgstaes.so` и `libgstdtls.so` —
  оба ищут `openssl` и `libcrypto` через pkg-config (`ext/aes`,
  `ext/dtls`). Без пакета они молча выключаются, и сборка падает на
  `dh_install: missing files`.
- **`libdrm-dev`, `zlib1g-dev`, `libopengl-dev`, `libegl-dev`,
  `libgles-dev`**: добавлены из-за `.pc`-файлов нашего
  `gstreamer1.0-plugins-base`.
- **Синхронизация `.install`**: `gstreamer1.0-plugins-bad.install` и
  `libgstreamer-plugins-bad1.0-0.install` перечисляют ровно то, что
  фактически собирается (проверено `meson setup` с флагами из `debian/rules`).
  Это обязательно: в compat 13 `dh_missing` работает с `--fail-missing` по
  умолчанию, и любое расхождение — лишний файл в `debian/tmp` или
  отсутствующая строка — останавливает сборку. Поэтому в наборе нет
  плагинов, требующих `libaom-dev`, `libzbar-dev`, `libcurl4-openssl-dev`,
  `libflite-dev`, `libfrei0r-dev`, `libde265-dev`, `librsvg2-dev`,
  `libsndfile1-dev`, `libsoundtouch-dev`, `libspandsp-dev`, `libsrt-dev`,
  `libmodplug-dev`, `libwildmidi-dev`, `libfluidsynth-dev`, `libbs2b-dev`,
  `libchromaprint-dev`, `libgsm-dev`, `liblc3-dev`, `libneon27-dev`,
  `libopenaptx-dev` и подобных, - их `-dev` пакетов в `Build-Depends` нет, и
  добавлять их ради плагинов, которые в этом репозитории никто не
  использует, смысла нет.
- Документация и примеры: `-Ddoc=disabled -Dexamples=disabled`; man-страниц
  нет.
- Тесты: `-Dtests=disabled`, `xvfb` и `xauth` убраны из `Build-Depends`.
- Утилиты `gst-transcoder-1.0` и `gst-transcoder-service` из
  `gstreamer1.0-plugins-bad-apps` не публикуются: в `debian/rules` они
  удаляются из staging-дерева в `override_dh_auto_install`. Без этого
  `dh_missing` (в compat 13 он по умолчанию работает с `--fail-missing`)
  падает на файле, который никто не устанавливает.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## VA-API берётся из этого репозитория

`libva-dev`, `libva2`, `libva-drm2`, `libva-wayland2` ставятся из сборки
`libva` (см. `packages/libva/README.md`). Штатный `libva-dev` не ставится
рядом с нашим `libglvnd0`: он тянет `libva-glx2`, а тот зависит от `libgl1`,
пинящий `libglvnd0` версии trixie. Пин снят, потому что наш `libva` собран без
GLX и X11: пути DRM и Wayland на месте, VA-API работает полностью.
Исключений в `CLOSURE_EXCEPT` нет.

## GL и GLES берутся из этого репозитория

`libegl-dev`, `libegl1`, `libgles-dev`, `libgles1`, `libgles2`, `libopengl-dev`,
`libopengl0`, `libglvnd0`, `libglvnd-core-dev` ставятся из нашей сборки
`libglvnd` (см. `packages/libglvnd/README.md`).

Здесь `libopengl-dev` убран из `Build-Depends`: ни одного `NEEDED` на GL в
собранных библиотеках нет. Исключений в `CLOSURE_EXCEPT` сейчас нет.

## Почему добавлен libpixman-1-dev

Прогон CI `37190873627` упал: `dh_install` не нашёл `libgstanalyticsoverlay.so`
и `libgstttmlsubs.so`. Плагины молча выключились, потому что не находился
`pangocairo`:

```
Run-time dependency pangocairo found: NO
Run-time dependency cairo found: NO
```

Причина цепочкой. `pangocairo.pc` требует `pango` и `cairo >= 1.18.0`.
`cairo.pc` кладёт `pixman-1` в `Requires.private`, а pkgconf в trixie
`Requires.private` разрешает. В сборочной среде ставился только
`libpixman-1-0` (runtime), но не `libpixman-1-dev`, то есть `pixman-1.pc`
отсутствовал — и `cairo.pc` не резолвился.

  Существующий комментарий в `control` про это предупреждал: «pkg-config в
  trixie (pkgconf) разрешает и Requires.private», и `libpixman-1-dev` добавлен
  в `Build-Depends`.

## Изменено

- Версия: `1.28.7-4+crick` (ревизия поднята с 3 до 4: выключены DeckLink, AJA,
  gme, OpenAL и OpenEXR — требует пересборки).
- Пакет `gstreamer1.0-plugins-bad` в Debian объявляет `Breaks` и `Replaces`
  на `gstreamer1.0-plugins-base` и `gstreamer1.0-plugins-good` версий
  ancient (`<< 0.11.94`, `<< 1.1.2`) — они не перенесены, они относятся к
  2008 году.

## Влияние на систему и откат

`libgstreamer-plugins-bad1.0-dev` больше не подтягивает `libopencv-dev`
и `libgstreamer-opencv1.0-0`, а `gstreamer1.0-wpe` и `gstreamer1.0-opencv`
из trixie будут сняты. Если нужны, верните trixie-пакеты:

```
apt install gstreamer1.0-wpe/trixie gstreamer1.0-opencv/trixie
```
