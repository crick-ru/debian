# imagemagick

ImageMagick 7.1.2-34: программы и библиотеки для обработки изображений
(`libmagickcore-7.q16-10`, `libmagickwand-7.q16-10`, `imagemagick-7.q16`).

## Источник упаковки

Упаковка взята из Debian (`imagemagick_8:7.1.1.43+dfsg1-1`, ветка trixie) и
переработана. Debian перепаковывает tarball как `+dfsg1`, но для самых
свежих версий 7.1.2-x Debian использует чистый апстрим-архив, поэтому
наш tarball побайтово совпадает.

## Версии

- **В trixie:** 8:7.1.1.43+dfsg1-1+deb13u12
- **В исходной упаковке:** 8:7.1.2-34-4
- **В нашем репозитории:** 8:7.1.2-34-4+crick (epoch 8, ревизия 4)

**Epoch 8 обязателен** — в trixie лежит `8:7.1.1.43+dfsg1`, и без epoch
`7.1.2-32` оказалась бы старее. apt сравнивает epoch первым.

`7.1.2-32` новее `7.1.1.43` (сравнение по компонентам: `2 > 1` в третьем
разряде). `-32` — апструп-номер релиза, `-4` — наша Debian-ревизия.

## Содержимое

- `imagemagick-7-common` — общие файлы
- `libmagickcore-7-headers` / `libmagickcore-7.q16-10` / `libmagickcore-7.q16-dev`
- `libmagickwand-7-headers` / `libmagickwand-7.q16-10` / `libmagickwand-7.q16-dev`
- `imagemagick-7.q16` / `imagemagick` (переходной)
- `libmagickcore-7-arch-config`

Все кодеки и фильтры (`coders/`, `filters/`) находятся **внутри**
`libmagickcore-7.q16-10` (динамически загружаемые модули).

## Что изменено

### Отключено

- **X11** (правило репозитория): `--without-x`. Debian собирает с
  `--x-includes`/`--x-libraries`, что тянет `libx11-dev`/`libxext-dev`/
  `libxt-dev` и зависимости `libx11-6`/`libxext-6`. Здесь ничего из X11 нет.
  Утилиты `display` и `import` удаляются из staging-дерева — они X11-инструменты.
- **WMF и OpenEXR:** `--without-wmf --without-openexr`. `libwmf-dev` и
  `libopenexr-dev` убраны из `Depends` `libmagickcore-7.q16-dev`.
- **Q16HDRI:** только Q16 (`-with-quantum-depth=16 -enable-hdri=no`). Debian
  собирает две глубины.
- **PerlMagick** (`--without-perl`) и **Magick++** (`--without-magick-plus-plus`):
  не используются ни одним пакетом репозитория.
- **Документация и man-страницы:** удаляются из staging-дерева
  (`usr/share/doc`, `usr/share/man`).
- **Тесты:** `override_dh_auto_test` пуст, `make check` не вызывается.
- **Desktop-файлы и значки:** `imagemagick*.desktop` убраны из
  `imagemagick-7.q16.install` (апстрруп 7.1.2 их не ставит).
- **libtool-архивы `*.la`:** удаляются из staging-дерева.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- Делегат HEIF/AVIF (`--with-heic`): `coders/heic.so` даёт HEIC, HEIF, AVCI, AVIF.
  `libheif-dev` в `Build-Depends`, `libheif1` в `Depends` `libmagickcore-7.q16-10`.
- Делегаты DjVu, OpenJPEG, WebP, FFTW, `zlib`/`bzip2`/`lzma`, JPEG, PNG, TIFF,
  Raw, liblqr, LCMS, Fontconfig/FreeType, pango, XML.
- Воспроизводимая сборка (`--enable-reproducible-build`, `--without-gcc-arch`).
- `policy.xml` — `--with-security-policy=secure`.

## Патчи

Нет: `debian/patches/series` отсутствует.

## Изменения ABI

SONAME не меняются: `libMagickCore-7.Q16.so.10`, `libMagickWand-7.Q16.so.10`.
Добавлено новых символов, удалённых нет.

## Важные нюансы

### apt upgrade: снимаемые пакеты

Следующие пакеты из trixie будут сняты автоматически (они пинят версию из trixie):
`libimage-magick-perl`, `libimage-magick-q16-perl`, `libmagick++-7-headers`,
`libmagick++-7.q16-dev`, `libmagickcore-dev`, `libmagickwand-dev`,
`libmagick++-dev`, `perlmagick`, `libmagickcore-7.q16-10-extra`.

Проверить до обновления: `apt-get -s upgrade`.

### libheif из репозитория

`libheif-dev` и `libheif1` берутся из сборки `libheif` этого репозитория
(см. `packages/libheif/README.md`).

### Символьные файлы

`.symbols` не поставляются — их генерирует `dh_makeshlibs` (`-c0`).
В Debian-файле 994 строк с привязкой к версиям 7.1.1.x, и любой удалённый
символ ронял бы сборку.
