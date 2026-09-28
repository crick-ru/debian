# gstreamer1.0-plugins-base (crick Debian backports)

Сборка GStreamer Base Plugins 1.28.7 для Debian 13 (trixie, amd64). Упаковка
взята из Debian (`gst-plugins-base1.0 1.28.7-1`) и упрощена.

## Включено

- `libgstreamer-plugins-base1.0-0` и `-dev` — библиотеки audio, video, app,
  RTP/RTSP/SDP, FFT, tag.
- `libgstreamer-gl1.0-0` и `gstreamer1.0-gl` — интеграция с OpenGL.
- `gstreamer1.0-plugins-base` — конвертеры и масштабирование звука и видео,
  конвейер воспроизведения (`playbin`, `decodebin`, `parsebin`,
  `uridecodebin`), определитель типов, парсер субтитров, Ogg, Vorbis, Opus и
  Theora.
- `gstreamer1.0-alsa` — вывод и захват звука через ALSA.
- `gir1.2-gst-plugins-base-1.0` — данные GObject introspection.

## Отключено

- **X11**: `-Dx11=disabled -Dxshm=disabled -Dxvideo=disabled -Dxi=disabled`.
  Исчезают `ximagesink` и `xvimagesink`, а также X11 внутри библиотек. Из
  `Build-Depends` убраны `libx11-xcb-dev`, `libxi-dev`, `libxt-dev` и
  `libxv-dev`. Пакет `gstreamer1.0-x` не публикуется.
- **Аудио-CD**: `-Dcdparanoia=disabled` — это оптический диск, поэтому
  `libcdparanoia-dev` убран из `Build-Depends`. Правило — в
  `.clinerules/project.md`, раздел «Оптические диски и DVB-тюнеры
  отключаются».
- **Утилиты для сопровождения**: пакет `gstreamer1.0-plugins-base-apps`
  (`gst-play-1.0`, `gst-discoverer-1.0`, `gst-device-monitor-1.0`) не
  публикуется. В репозитории есть `mpv`, а discoverer и device-monitor —
  инструменты сопровождения, а не то, что нужно пользователю.
- Документация и примеры: `-Ddoc=disabled -Dexamples=disabled`; man-страниц
  нет.
- Тесты: `-Dtests=disabled`, `xvfb` и `xauth` убраны из `Build-Depends`.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Версия: `1.28.7-1+crick`. Все пять пакетов GStreamer несут одну строку
  версии: их `-dev`-пакеты пинят sibling-пакеты `= ${binary:Version}`.
- **GL только под Wayland и EGL**: `-Dgl_winsys=wayland,egl
  -Dgl_platform=egl`. Это ключевое изменение: при `-Dauto_features=enabled`
  и дефолтном `gl_winsys=auto` meson подхватывает и X11, и Wayland, и
  `libgstreamer-gl1.0-0` получает зависимости `libx11-6` и `libxcb1`. С
  явным списком остаётся только Wayland, то есть EGL и `libwayland-client0`.
- Плагин `pango` (текстовые наложения, субтитры) остаётся: он использует
  `pangocairo`, а не X11.
- `Maintainer`: нейтральная идентичность проекта.

## Влияние на систему и откат

SONAME библиотек не менялись, символы не удалены: X11-видеосинки — это
отдельные плагины, а не часть ABI. Возврат к триxie-пакетам безопасен:

```
apt install gstreamer1.0-plugins-base/trixie gstreamer1.0-plugins-base-apps/trixie
```
