# gstreamer1.0-libav

Мост между GStreamer и FFmpeg: плагин `libgstlibav.so`, оборачивающий
кодеки `libavcodec`, фильтры `libavfilter` и масштабирование `libswscale`
в элементы GStreamer (`avdec_*`, `avenc_*`, конвертеры, субтитры).

## Источник упаковки

Упаковка взята из Debian (`gst-libav1.0_1.28.7-1`, ветка unstable) и
переработана. Tarball побайтово совпадает с Debian-овским
`gst-libav-1.28.7.orig.tar.xz`.

## Версии

- **В trixie:** 1.26.2-1+deb13u1
- **В исходной упаковке:** 1.28.7-1
- **В нашем репозитории:** 1.28.7-1+crick

Все пять пакетов GStreamer носят одну строку версии `1.28.7-1+crick`.

## Содержимое

- `gstreamer1.0-libav` — единственный пакет с плагином `libgstlibav.so`.

## Что изменено

### Отключено

- **Документация:** `-Ddoc=disabled`.
- **Тесты:** `-Dtests=disabled`, `xvfb` и `xauth` убраны из `Build-Depends`.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- Авто-фичи: `-Dauto_features=enabled`.

## Патчи

Нет: `debian/patches/series` отсутствует.

## Важные нюансы

Плагин собирается против **FFmpeg этого репозитория** (9.0.2, epoch 7), а не
против версии из trixie. `libav*-dev` в `Build-Depends` имеют нижнюю границу
`(>= 7:9.0)` — она закрывается только сборкой с epoch 7 из этого репозитория.
В CI плагин собирается на стадиях 1–3 (`build.yml`), где `-dev`-пакеты
FFmpeg уже установлены из stage6-*, а не из trixie.

Опции `examples` у gst-libav нет вовсе — апстрим объявляет только
`package-name`, `package-origin`, `doc` и `tests`. Передача
`-Dexamples=disabled` привела бы к `ERROR: Unknown options`.

Пакет снимает из `Depends` `libavcodec61`/`libavutil59` trixie и ставит
`libavcodec63`/`libavutil61` из нашего FFmpeg.
