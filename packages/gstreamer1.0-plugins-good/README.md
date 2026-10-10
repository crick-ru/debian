# gstreamer1.0-plugins-good (crick Debian backports)

Сборка GStreamer Good Plugins 1.28.7 для Debian 13 (trixie, amd64). Упаковка
взята из Debian (`gst-plugins-good1.0_1.28.7-1`, ветка unstable) и переработана.

## Включено

- `gstreamer1.0-plugins-good` — элементы набора: демультиплексоры Matroska, FLV и
  RTP, кодеки VP8 и VP9, FLAC, MP3, AAC, видеофильтры, а также
  `libgstadaptivedemux2.so` — адаптивный демультиплексор (его `-dev`-зависимость
  `libxml2-dev` уже есть в `Build-Depends`).

Отдельных пакетов с библиотеками у этого набора нет: в апстриме 1.28.7
каталог `gst-libs/gst` содержит только один заголовок, то есть общих
библиотек набор не производит. Поэтому `libgstreamer-plugins-good1.0-0`,
`libgstreamer-plugins-good1.0-dev` и `gir1.2-gst-plugins-good-1.0` не
публикуются: им нечего нести, и `dh_install` упал бы на пустом пакете.
Все нужные этому набору библиотеки (Matroska, RTP, RTSP, SDP, tag,
`gstreamer-plugins-base-1.0`) приходят из `gstreamer1.0-plugins-base`.

## Отключено

- **X11**: `-Dximagesrc=disabled`. Единственный X11-плагин набора — `ximagesrc`
  (снимок экрана) — не собирается, в репозитории X11 нет вообще. Важно:
  опции `x11` в `gst-plugins-good` 1.28.7 **не существует** (есть `ximagesrc`
  и её подопции `ximagesrc-xshm`, `ximagesrc-xfixes`,
  `ximagesrc-xdamage`, `ximagesrc-navigation`), поэтому `-Dx11=disabled`
  обрывал конфигурацию с `ERROR: Unknown options: "x11"`.
- **Видеосинки Qt**: `-Dqt5=disabled -Dqt6=disabled`. Это QML, то есть
  X11-ориентированный API; в репозитории нет ни Qt, ни X11. Видео показывают
  `labwc` и `mpv`. Пакеты `gstreamer1.0-qt5` и `gstreamer1.0-qt6` не
  публикуются, а `qtbase5-dev`, `qtdeclarative5-dev`, `qttools5-dev`,
  `qt6-base-private-dev` и `qt6-declarative-dev` убраны из `Build-Depends`.
- **Видеосинк GTK 3**: `-Dgtk3=disabled`. В репозитории есть `gtk+3.0` без
  X11, но задачу вывода видео решает `labwc`, поэтому собственный GTK-синк
  GStreamer не нужен. Пакет `gstreamer1.0-gtk3` не публикуется, `libgtk-3-dev`
  убран из `Build-Depends`. Стоит отметить: в 1.28.7 `gstreamer1.0-gtk3`
  собирается только с GTK 3, использующим X11, — то есть в сборке Debian он
  всё равно бесполезен на чистом Wayland.
- **PulseAudio**: `-Dpulse=disabled`. Плагин `libgstpulseaudio.so` не
  публикуется: в репозитории `pipewire` с pulse-совместимостью, он и
  обслуживает вывод звука. Опциями сборки, а не только строкой в `.install`:
  иначе `dh_missing --fail-missing` (в compat 13 это поведение по умолчанию)
  роняет сборку на неустановленном файле. `libpulse-dev` убран из
  `Build-Depends`; `mpv` приносит его себе сам.
- **Захват с видеоустройств**: `-Dv4l2=disabled`. Плагин
  `libgstvideo4linux2.so` (V4L2) не публикуется — это телекамеры и
  ТВ-тюнеры, тот же класс, что и отключённые DVB/DVD. Без явного
  отключения он собирался бы: заголовки `linux/videodev2.h` есть в
  `libc6-dev`/`linux-libc-dev`, то есть проверка `cc.has_header` проходит.
- **JACK**: `-Djack=disabled`. Плагин `libgstjack.so` не публикуется:
  звук обслуживает pipewire, а JACK-клиенту нужен настоящий JACK-сервер
  (например, `jackd2` из дистрибутива). `libjack-jackd2-dev` убран из
  `Build-Depends`.
- **Вывод видео в текстовую консоль**: `-Dlibcaca=disabled` и
  `-Daalib=disabled`. Не публикуются `libgstcacasink.so` (caca) и
  `libgstaasink.so` (aa1) — это ASCII-арт-вывод в терминал, тот же
  класс, что и отключённые DVB: видео показывают `labwc` и `mpv`.
  Из `Build-Depends` убраны `libcaca-dev` и `libaa1-dev`. Обратите
  внимание на имя опции: в апстриме оно **`aalib`**, а не `aa1`, хотя
  пакет Debian называется `libaa1-dev` — проверка в
  `ext/aalib/meson.build` идёт по заголовку `aalib.h` и по `-laa`, и
  именно их этот пакет и предоставляет.
- **OSSv4**: `-Doss4=disabled`. Плагин `libgstoss4.so` — устаревший аудио-API;
  звук идёт через ALSA и `pipewire`. Отключается опцией, потому что
  `libgstoss4.so` собирается по одним стандартным заголовкам.
- **Icecast/Shout**: `-Dshout2=disabled`. Плагин `libgstshout2.so` (icecastsink)
  не публикуется — это отправка потока на Icecast-сервер, а серверов в
  репозитории нет. `libshout-dev` убран из `Build-Depends`, `libgstshout2.so` —
  из `.install`.
- **AMR, Speex, WavPack и audiofx**: `-Damrnb=disabled -Damrwbdec=disabled
  -Dspeex=disabled -Dwavpack=disabled -Daudiofx=disabled`. AMR (NB/WB),
  Speex и WavPack не публикуются — аудио в репозитории идёт через Opus,
  Vorbis и FLAC, а AMR/Speex/WavPack-клиентов нет. Плагин `libgstaudiofx.so`
  (чистый плагин без внешних зависимостей, аудио-эффекты) исключён по списку
  репозитория. Из `Build-Depends` убраны `libopencore-amrnb-dev`,
  `libopencore-amrwb-dev`, `libspeex-dev` и `libwavpack-dev`; из `.install`
  убраны `libgstamrnb.so`, `libgstamrwbdec.so`, `libgstaudiofx.so`,
  `libgstspeex.so` и `libgstwavpack.so`.
- **Опции, которые нельзя включать все сразу**: `-Dauto_features` намеренно не
  задаётся. Эта встроенная опция meson превращает все опции `auto` в
  `enabled`, то есть необязательные зависимости становятся обязательными, и
  сборка последовательно падала на отсутствующих `nasm` (опция `asm`),
  `libraw1394`/`libavc1394`/`libiec61883` (опция `dv1394`) и
  `libgudev`/`libv4l2` (подопции `v4l2`). Состав набора задают перечисленные
  выше отключения плюс фактический состав `Build-Depends`.
- **`libdrm-dev` и `zlib1g-dev`**: добавлены из-за `.pc`-файлов нашего
  `gstreamer1.0-plugins-base`. `gstreamer-allocators-1.0.pc` объявляет
  `Requires: libdrm >= 2.4.98`, а `gstreamer-audio-1.0.pc` и другие — `zlib`
  и `orc-0.4` в `Requires.private`. `pkg-config` в trixie (pkgconf)
  разрешает и `Requires.private`, поэтому без `libdrm.pc` и `zlib.pc` не
  находится даже `gstreamer-pbutils-1.0`, и meson пытается скачать сабпроект
  `gst-plugins-base`.
- Документация: `-Ddoc=disabled`; man-страниц нет.
- Тесты: `-Dtests=disabled`, `xvfb` и `xauth` убраны из `Build-Depends`.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Синхронизация .install

`gstreamer1.0-plugins-good.install` перечисляет ровно те плагины, которые
фактически собираются при флагах из `debian/rules` (60 плагинов, проверено
`meson setup`). Это обязательно: в compat 13 `dh_missing` работает с
`--fail-missing` по умолчанию, и любое расхождение — лишний файл в
`debian/tmp` или отсутствующая строка — останавливает сборку.

## Изменено

- Версия: `1.28.7-3+crick` (ревизия поднята с 2 до 3: переработка набора
  плагинов — удалены AMR, Speex, WavPack, audiofx и Icecast/Shout, требуют
  пересборки).
- Состав пакета: из `gstreamer1.0-plugins-good.install` и `Build-Depends`
  удалены плагины AMR (NB/WB), `audiofx`, Speex, WavPack и Icecast/Shout —
  кодеки не используются клиентами (аудио идёт через Opus/Vorbis/FLAC), а
  `audiofx` — чистый плагин без внешних зависимостей, исключённый по списку
  репозитория. Icecast/Shout (icecastsink) удалён: в репозитории нет
  Icecast-серверов. Из `Build-Depends` убраны `libopencore-amrnb-dev`,
  `libopencore-amrwb-dev`, `libspeex-dev`, `libwavpack-dev` и `libshout-dev`;
  из `.install` убраны `libgstamrnb.so`, `libgstamrwbdec.so`,
  `libgstaudiofx.so`, `libgstspeex.so`, `libgstwavpack.so` и `libgstshout2.so`.
  Стало 60 плагинов вместо 69 в исходной сборке Debian.

## Влияние на систему и откат

Пакеты `gstreamer1.0-qt5`, `gstreamer1.0-qt6` и `gstreamer1.0-gtk3` из
trixie при `apt upgrade` будут сняты вместе со всем, что их требует (Qt5/Qt6
приложения). Если они нужны, верните trixie-пакеты:

```
apt install gstreamer1.0-qt5/trixie gstreamer1.0-gtk3/trixie
```

`gstreamer1.0-plugins-good` из trixie больше не поставляет
`libgstreamer-plugins-good1.0-0`, `libgstreamer-plugins-good1.0-dev` и
`gir1.2-gst-plugins-good-1.0` (в 1.28.7 набор не производит библиотек).
Пакеты, которые на них ссылались, переводятся на `gstreamer1.0-plugins-good`
и `gstreamer1.0-plugins-base`:

```
apt install gstreamer1.0-plugins-good/trixie
```
