# libheif (crick Debian backports)

Сборка `libheif` 1.23.4 для Debian 13 (trixie, amd64).

Версия: `1.23.4-1+crick`.

Упаковка взята из Debian (`libheif_1.23.4`, ветка 1.23) и переработана.

## Почему минимальный набор

`imagemagick` — единственный пакет этого репозитория, которому нужен libheif:
он требует `libheif-dev` для кодировщика `coders/heic.so`, который даёт форматы
HEIC, HEIF, AVCI и AVIF. Поэтому публикуются ровно два пакета:

| Пакет | Что внутри |
|---|---|
| `libheif1` | `libheif.so.1` **и плагины кодеков внутри него** |
| `libheif-dev` | заголовки, `libheif.pc`, файлы CMake |

Debian разбивает плагины по отдельным пакетам (`libheif-plugin-libde265`,
`libheif-plugin-dav1d`, `libheif-plugin-x265`, …) — 13 штук, плюс метапакет
`libheif-plugins-all`. Здесь они едут внутри `libheif1`: ровно так же, как
модули кодировщиков ImageMagick едут внутри `libmagickcore-7.q16-10` вместо
пакета `-extra`. Путь установки (`/usr/lib/<triplet>/libheif/plugins/`) не
изменён, поэтому `dlopen` находит плагины без всяких патчей.

## Какие кодеки включены

Ровно те, что нужны для HEIC и AVIF:

| Кодек | Пакет | Зачем |
|---|---|---|
| libde265 | `libheif-plugin-libde265` | декодирование HEVC → чтение HEIC/HEIF |
| x265 | `libheif-plugin-x265` | кодирование HEVC → запись HEIC |
| aom | `libheif-plugin-aomdec`, `-aomenc` | AV1 → AVIF |
| dav1d | `libheif-plugin-dav1d` | AV1, декодирование (быстрее libaom) |

Выключены: ffmpeg, jpeg, openjpeg (J2K), kvazaar, rav1e, SVT-AV1, x264,
OpenH264, VVC (uvg266, vvdec, vvenc). Также выключены сжатие заголовков
(`-DWITH_HEADER_COMPRESSION=OFF`, иначе нужен libbrotli) и `libsharpyuv`
(`-DWITH_LIBSHARPYUV=OFF`, иначе нужен libwebp). Внутренний кодек
`uncompressed` (ISO/IEC 23001-17) оставлен включённым: он не тянет внешних
зависимостей, кроме zlib, и его символы есть в `libheif1.symbols`.

Символьный файл `libheif1.symbols` взят из Debian без изменений: плагины
собираются как отдельные модули, поэтому `libheif.so.1` содержит тот же набор
символов, что и в Debian.

## Что не собирается

- документация (doxygen), примеры (`heif-info`, `heif-dec`, `heif-enc`,
  `heif-convert`, `heif-view`), `heif-thumbnailer` и плагин gdk-pixbuf;
- тесты (`-DBUILD_TESTING=OFF`, `override_dh_auto_test` пуст);
- dbgsym-пакеты (общее правило `scripts/build-package.sh`).

Правило репозитория «ничего лишнего не собирается» — в `rules/`.

## Что произойдёт при `apt upgrade`

Наша версия выше и в trixie, и в trixie-security (`1.23.4-1~deb13u1`):
`1+crick` сравнивается с `1~deb13u1` как большая (`~` в Debian-сортировке
меньше всего, даже конца строки).

Плагины trixie (`libheif-plugin-*-1.23.4-1~deb13u1`) зависят от
`libheif1 (= 1.23.4-1~deb13u1)` — точной версии, которой у нас нет, поэтому
apt **снимет** их: их функцию выполняют плагины внутри нашего `libheif1`.
Ничего не сломается, но перечень установленных пакетов изменится. Проверить
заранее:

```bash
apt-get -s upgrade
```

Пакеты `libheif-examples`, `heif-thumbnailer`, `heif-gdk-pixbuf` и
`libheif-plugins-all` из репозитория не приходят — если они стояли из
trixie, они останутся на своей версии и будут работать со старым API
(`libheif1` с SONAME `libheif.so.1` не изменился, удалённых символов нет).

## Откат

Вернуться на штатный libheif trixie:

```bash
sudo apt install libheif1=1.19.8-1+deb13u1 libheif-dev=1.19.8-1+deb13u1
```

Или убрать из `debian/control` imagemagick зависимость и вернуть
`--without-heic` (см. `packages/imagemagick/README.md`).