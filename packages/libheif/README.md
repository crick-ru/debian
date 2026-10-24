# libheif

HEIF и AVIF: декодер и кодер файловых форматов изображений (ISO/IEC 23008-12).

## Источник упаковки

Упаковка взята из Debian (`libheif_1.23.4-1~deb13u1`, trixie-security,
ветка 1.23) и переработана: публикуется только `libheif1` и `libheif-dev`.
Tarball побайтово совпадает с Debian-овским
`libheif_1.23.4.orig.tar.gz` — Debian не использует repack-суффикс, версия
 остаётся чистой `1.23.4` (без `+dfsg`/`+ds`).

## Версии

- **В trixie:** 1.19.8-1 (`libheif1` 1.19.8-1, SONAME `libheif.so.1`)
- **В исходной упаковке:** 1.23.6-1
- **В нашем репозитории:** 1.23.6-1+crick (ревизия 1)

`1+crick` сравнивается с `1~deb13u1` как большая: `~` в Debian-сортировке
меньше всего, поэтому `1+crick > 1~deb13u1` и наша версия выигрывает.

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libheif1` | `libheif.so.1` и **все плагины кодеков внутри него** |
| `libheif-dev` | заголовки, `libheif.pc`, файлы CMake |

В отличие от Debian, где плагины разбиты по 13 отдельным пакетам
(`libheif-plugin-libde265`, `libheif-plugin-dav1d`, …) и метапакету
`libheif-plugins-all`, здесь все плагины едут внутри `libheif1` — ровно так же,
как модули кодеков ImageMagick едут внутри `libmagickcore-7.q16-10`.

## Что изменено

### Отключено

- **Все плагины, кроме HEIC/AVIF:** `-DWITH_X264=OFF`, `-DWITH_OpenH264_DECODER=OFF`,
  `-DWITH_OpenJPEG_ENCODER/DECODER=OFF`, `-DWITH_OPENJPH_ENCODER=OFF`,
  `-DWITH_JPEG_ENCODER/DECODER=OFF`, `-DWITH_FFMPEG_DECODER=OFF`,
  `-DWITH_KVAZAAR=OFF`, `-DWITH_UVG266=OFF`, `-DWITH_VVDEC=OFF`,
  `-DWITH_VVENC=OFF`, `-DWITH_SvtEnc=OFF`, `-DWITH_RAV1E=OFF`.
  Пакеты `ffmpeg`, `jpeg`, `openjpeg` (J2K), `kvazaar`, `rav1e`, SVT-AV1,
  `x264`, OpenH264, VVC — не нужны для репозитория.
- **Сжатие заголовков** `-DWITH_HEADER_COMPRESSION=OFF` — иначе нужен `libbrotli-dev`.
- **libsharpyuv** `-DWITH_LIBSHARPYUV=OFF` — иначе нужен `libwebp-dev`.
- **Документация, примеры, thumbnailer, gdk-pixbuf-плагин:** `-DBUILD_DOCUMENTATION=OFF
  -DWITH_EXAMPLES=OFF -DWITH_EXAMPLE_HEIF_THUMB=OFF -DWITH_EXAMPLE_HEIF_VIEW=OFF
  -DWITH_EXAMPLE_HEIF_VIEW=OFF -DWITH_GDK_PIXBUF=OFF`.
- **Тесты:** `-DBUILD_TESTING=OFF`, `override_dh_auto_test` пуст.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- **HEIC/HEIF:** libde265 (декодер), x265 (кодер).
- **AVIF:** aom (декодер+кодер), dav1d (декодер).
- **Встроенный uncompressed-кодек** (`-DWITH_UNCOMPRESSED_CODEC=ON`) — не
  тянет внешних зависимостей, только `zlib`.

## Патчи

Нет: `debian/patches/series` отсутствует.

## Изменения ABI

`libheif1.symbols` взят из Debian без изменений: плагины собираются как
отдельные модули, поэтому `libheif.so.1` содержит тот же набор экспортируемых
символов, что и в Debian. SONAME `libheif.so.1` не меняется, удалённых символов
нет.

## Важные нюансы

### Зачем нужен

`imagemagick` требует `libheif-dev` для кодировщика `coders/heic.so`, который
даёт форматы HEIC, HEIF, AVCI и AVIF. Без libheif этот кодировщик отключается.

### Плагины внутри библиотеки

Путь загрузки `/usr/lib/<triplet>/libheif/plugins/` не изменён, `dlopen`
находит плагины без патчей. Debian-овские пакеты `libheif-plugin-*` приходятся
снять: они зависят от `libheif1` с точной версией Debian (`1.23.4-1~deb13u1`),
которая у нас отсутствует. Их функцию выполняют плагины внутри нашего `libheif1`.

### apt upgrade

Пакеты `libheif-examples`, `heif-thumbnailer`, `heif-gdk-pixbuf` и
`libheif-plugins-all` из trixie остаются на своей версии — они работают со
старым API (`libheif.so.1` не изменён, удалённых символов нет). Очистить:

```
apt-get -s upgrade
```
