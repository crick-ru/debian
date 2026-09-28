# gstreamer1.0-libav (crick Debian backports)

Сборка GStreamer libav 1.28.7 для Debian 13 (trixie, amd64). Упаковка взята из
Debian (`gst-libav1.0 1.28.7-1`) и упрощена. Это мост между GStreamer и
FFmpeg: плагин оборачивает кодировщики и декодировщики `libavcodec`,
фильтры `libavfilter` и масштабирование `libswscale` в элементы GStreamer.

## Включено

- `gstreamer1.0-libav` — один пакет с плагином `libgstlibav.so`: элементы
  `avdec_*` (декодирование), `avenc_*` (кодирование), `avmux`, `avdemux`,
  конвертеры звука и видео на libavfilter, субтитры.

## Отключено

- Документация: `-Ddoc=disabled`; man-страниц нет.
- Тесты: `-Dtests=disabled`, `xvfb` и `xauth` убраны из `Build-Depends`.

Больше ничего выключать не нужно: сам плагин не обращается ни к X11, ни к
оптическим дискам, ни к VDPAU. Видеосинки лежат в наборах «base» и «good»,
а они собраны без X11.

## Изменено

- Версия: `1.28.7-1+crick`.
- `libav*-dev` в `Build-Depends` имеют нижнюю границу `(>= 7:9.0)`: она
  закрывается только сборкой с epoch 7 из этого репозитория, и в CI плагин
  собирается именно против неё (стадии 1–3 в `build.yml`), а не против
  версии из триxie.
- `Maintainer`: нейтральная идентичность проекта.

## Влияние на систему и откат

Пакет снимает из `Depends` `libavcodec61`/`libavutil59` триxie и ставит
`libavcodec63`/`libavutil61` нашего FFmpeg. Если нужен триxie-плагин:

```
apt install gstreamer1.0-libav/trixie
```
