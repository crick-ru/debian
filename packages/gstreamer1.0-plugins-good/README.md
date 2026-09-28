# gstreamer1.0-plugins-good (crick Debian backports)

Сборка GStreamer Good Plugins 1.28.7 для Debian 13 (trixie, amd64). Упаковка
взята из Debian (`gst-plugins-good1.0 1.28.7-1`) и упрощена.

## Включено

- `libgstreamer-plugins-good1.0-0` и `-dev` — библиотеки Matroska, FLV и
  RTP-payloader'ы.
- `gstreamer1.0-plugins-good` — элементы набора: демьксеры Matroska, FLV и
  RTP, кодеки VP8 и VP9, FLAC, Speex, WavPack, AMR, MP3, AAC, Shout и
  PulseAudio.
- `gir1.2-gst-plugins-good-1.0` — данные GObject introspection.

## Отключено

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
- **PulseAudio**: пакет `gstreamer1.0-pulseaudio` не публикуется, плагин
  `libgstpulseaudio.so` убран из `gstreamer1.0-plugins-good.install`. В
  репозитории `pipewire` с pulse-совместимостью, он и обслуживает вывод звука.
  `libpulse-dev` остаётся в `Build-Depends`: без него mp3g2 в mpv и часть
  фильтров не собираются.
- Документация: `-Ddoc=disabled`; man-страниц нет.
- Тесты: `-Dtests=disabled`, `xvfb` и `xauth` убраны из `Build-Depends`.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Версия: `1.28.7-1+crick`.
- `Maintainer`: нейтральная идентичность проекта.

## Влияние на систему и откат

Пакеты `gstreamer1.0-qt5`, `gstreamer1.0-qt6` и `gstreamer1.0-gtk3` из
триxie при `apt upgrade` будут сняты вместе со всем, что их требует (Qt5/Qt6
приложения). Если они нужны, верните триxie-пакеты:

```
apt install gstreamer1.0-qt5/trixie gstreamer1.0-gtk3/trixie
```
