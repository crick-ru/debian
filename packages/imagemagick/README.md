# imagemagick (crick Debian backports)

Сборка `ImageMagick` 7.1.2-32 для Debian 13 (trixie) **без X11**, с
делегатом HEIF/AVIF, только в квантовой глубине Q16.

Версия: `8:7.1.2-32-4+crick` (ревизия 4 — WMF и OpenEXR выключены); ревизия 3,
`8:7.1.2-32-3+crick`, включила обратно HEIF против `libheif` этого репозитория;
ревизия 2, `8:7.1.2-32-2+crick`, была с выключенным делегатом, ревизия 1,
`8:7.1.2-32-1+crick`, — с включённым, но на `libheif` из trixie).

## Почему epoch 8 — обязателен

Trixie содержит `8:7.1.1.43+dfsg1-1+deb13u12`, то есть с **epoch 8**.
apt сравнивает epoch первым, поэтому наша сборка без epoch — `7.1.2-32-1+crick`
— оказалась бы **старее** штатной, и `apt upgrade` её просто не подхватил бы.
Ровно та же причина, по которой epoch 7 задан для `ffmpeg`. Карта epoch живёт
в `scripts/upstream/<pkg>.conf` (поле `EPOCH`).

Обратите внимание: `7.1.2-32` действительно новее `7.1.1.43` — сравнение
идёт по компонентам, `2 > 1` в третьем разряде.

`-32` в `7.1.2-32` — это **апстрим-нумерация ImageMagick**, а не Debian-ревизия:
свои релизы апстрим нумерует через дефис. Наша Debian-ревизия — это `-2` в
`8:7.1.2-32-2+crick`, и она меняется при правке упаковки (карта живёт в
`scripts/upstream/imagemagick.conf`). По этой же причине orig-тарболл называется
`imagemagick_7.1.2-32.orig.tar.xz`: `dpkg-source` ищет его по upstream-версии
из changelog, то есть по всей строке `7.1.2-32`. Раньше дефис отбрасывался, и
сборка исходного пакета (`dpkg-source -b`) не находила тарболл — этого не было
видно в CI, который собирает только бинарные пакеты.

## Включено

- Квантовая глубина Q16: `--with-quantum-depth=16`, `--enable-hdri=no`.
- Динамически загружаемые модули: `--with-modules`. Все кодировщики
  (coders) и фильтры едут **внутри** `libmagickcore-7.q16-10`, а не отдельным
  пакетом `-extra` (см. ниже).
- Делегаты: DjVu, OpenJPEG, WebP, FFTW, `zlib`/`bzip2`/`lzma`,
  JPEG, PNG, TIFF, Raw, liblqr, LCMS, Fontconfig/FreeType, pango,
  XML. librsvg выключен (`--without-rsvg`), как и в Debian: вместо него
  работает встроенный рендерер MSVG, а зависимость от cairo/pango в
  `libmagickcore` не появляется. WMF и OpenEXR выключены
  (`--without-wmf --without-openexr`) — см. «Отключено». `libheif` включён
  (`--with-heic`) — см. `packages/libheif`.
- `policy.xml` — `--with-security-policy=secure`, самый строгий из вариантов,
  которые принимает штатный `configure` апстрима (`open`, `limited`, `secure`,
  `websafe`). Значение `debian`, которое передаёт Debian, работает только с их
  пропатченным `configure` (`debian/patches/*security*`), поэтому здесь оно
  невозможно; `secure` — ближайший аналог: прямой доступ к файлам запрещён,
  кодировщик `follow` и выход за пределы каталога заблокированы, запись
  разрешена только через список безопасных кодировщиков. Если кому-то нужен
  кодировщик, который `secure` блокирует, значение меняется на `limited`
  (мягче) или `open` (по умолчанию апстрима, максимально открыто) в
  `debian/rules` и пересобирается пакет.
- Воспроизводимая сборка: `--enable-reproducible-build`,
  `--without-gcc-arch` (иначе `-march=native` ломает воспроизводимость).
- Desktop-файл и значки hicolor **не публикуются**: апстрим 7.1.2-32 их вообще
  не ставит (единственный `.desktop` в tar-боле — `app-image/imagemagick.desktop`,
  он нужен только для сборки AppImage, а иконок `share/icons/hicolor` в тарболе
  нет). Строки `usr/share/applications/imagemagick*.desktop` и
  `usr/share/icons/hicolor/*/apps/*.svg` из `imagemagick-7.q16.install`
  убраны: с ними `dh_install` падал с `missing files`. Практической потери
  нет — единственный desktop-файл ImageMagick открывает X11-просмотрщик
  `display`, который здесь не публикуется.
- Утилиты `display` и `import` **не публикуются**: `--without-x` убирает
  X11-делегат, но сами бинарники апстрим собирает, поэтому они удаляются из
  staging-дерева в `override_dh_auto_install` (`rm -f`). Без делегата они
  всё равно ничего не делают. Описание `imagemagick-7.q16` про это говорит.
- Libtool-архивы `*.la` **не публикуются**: `find … -name '*.la' -delete` в
  том же `override_dh_auto_install`. Причина техническая: libtool предпочитает
  `.la` одноимённой `.so`, и программа, собранная против нашего пакета,
  слинковала бы статическую библиотеку, оставив в бинарнике пути каталога
  сборки.
  Статические библиотеки `libMagickCore-7.Q16.a` и `libMagickWand-7.Q16.a`
  в `-dev`-пакеты входят, как в Debian.

## Отключено

- **X11** (`--without-x`). Debian собирает ImageMagick **с** X11:
  `--x-includes=/usr/include/X11 --x-libraries=/usr/lib/X11`, из чего
  следует `libx11-dev`, `libxext-dev`, `libxt-dev` в `Build-Depends` и
  зависимости `libx11-6`, `libxext-6` у `libmagickcore-7.q16-10` и
  `libmagickwand-7.q16-10`. Здесь этого нет: `--without-x` выключает
  делегат, и апстрим защищает каждое своё X11-использование макросом
  `MAGICKCORE_X11_DELEGATE`, поэтому патчи не потребовались. Следствия:
  - кодировщики `x` и `xwd` не собираются;
  - утилиты **`display` и `import` не устанавливаются** — это X11-инструменты,
    на чистом Wayland им нечего делать;
  - проверка: `grep -rniE 'libx(11|ext|render)|libxcb|x11proto|x11-xkb|xvfb|xwayland' packages/*/debian/control`
    даёт пустой результат.
- **WMF и OpenEXR** (`--without-wmf --without-openexr`): кодировщики
  `coders/wmf.so` (WMF) и `coders/exr.so` (OpenEXR) не собираются. Ни один
  пакет репозитория не использует форматы WMF и EXR, поэтому `libwmf-dev` и
  `libopenexr-dev` убраны из `Depends` пакета `libmagickcore-7.q16-dev` (они
  там были как транзитивные dev-зависимости, а coder не собирается: `-dev` в
  `Build-Depends` нет). Без `--without-openexr` configure молча отключил бы
  coder (заголовков нет), но опция задаёт это явно — правило репозитория
  требует, чтобы слово делегата встречалось в `debian/rules`.
- **HEIF/AVIF — делегат включён.** В ревизии 2 он был выключен
  (`--without-heic`), теперь в `debian/rules` стоит `--with-heic`, а
  `libheif-dev` снова в `Build-Depends` и в `Depends` пакета
  `libmagickcore-7.q16-dev`. Делегат берётся из этого репозитория:
  `libheif1` + `libheif-dev` 1.23.4, причём плагины кодеков лежат внутри
  `libheif1` (см. `packages/libheif/README.md`).
  Один кодировщик `coders/heic.so` даёт четыре формата — `HEIC`, `HEIF`,
  `AVCI` и `AVIF`: отдельного ключа для AVIF в апстриме нет, поэтому он
  включается и выключается вместе с HEIC.
  `libheif.so.1` в `DT_NEEDED` есть **только** у `heic.so`, главная библиотека
  `libMagickCore-7.Q16.so.10` его не линкует (проверено `readelf -d`),
  поэтому `libheif1` появляется в `Depends` пакета
  `libmagickcore-7.q16-10` — ровно как было в ревизии 1.
  Проверка собранного пакета:
  ```
  dpkg-deb -c libmagickcore-7.q16-10_*_amd64.deb | grep -iE 'heic|avif'  # есть coders/heic.so
  dpkg-deb -f libmagickcore-7.q16-10_*_amd64.deb Depends | grep -i heif  # есть libheif1
  ```
- **Q16HDRI**. Debian собирает две глубины (`q16` и `q16hdri`) — это два
  полных прохода компиляции. Здесь только Q16. Пакеты `*q16hdri*` из
  trixie продолжают работать со своими библиотеками: они зависят от
  `imagemagick-7-common (>= 8:7.0.0~)`, а не от нашей версии, и их путь
  модулей содержит `ImageMagick-7.1.1`, который наш 7.1.2 не читает, но
  читают они сами.
- **PerlMagick** (`--without-perl`) и **Magick++**
  (`--without-magick-plus-plus`): ни то, ни другое не нужно ни одному
  пакету этого репозитория. PerlMagick вдобавок потребовал бы `perl` и
  свою обвязку из `perl Makefile.PL`, а его каталоги `demo/` и `t/` —
  это ровно те примеры и тесты, которые запрещены правилами проекта.
- **Документация и man-страницы**: пакет `imagemagick-7-doc` не
  публикуется, `override_dh_auto_install` удаляет `usr/share/doc` и
  `usr/share/man` из дерева установки. В `Build-Depends` не осталось
  `doxygen`, `graphviz`, `xsltproc`, `xmlto`, `jdupes`, `rsync`.
- **Тесты** (`override_dh_auto_test` пуст): `make check` у ImageMagick —
  это большой набор на Perl и Ghostscript, он не вызывается.
- **dbgsym** не собираются (общее правило `scripts/build-package.sh`).


## Что произойдёт при `apt upgrade` (обязательно к прочтению)

Мы **не** публикуем PerlMagick, Magick++ и переходные «пустышки». Их
версии из trixie пинят **точную** версию `imagemagick-7-common` и
`-dev`-пакетов своей сборки, поэтому рядом с нашими они не могут
остаться. Чтобы это было детерминированно, а не «apt не разрешается»,
в `debian/control` проставлены `Conflicts`/`Replaces`, и следующие
пакеты будут **сняты автоматически**:

| Пакет | Почему снимается |
|---|---|
| `libimage-magick-perl`, `libimage-magick-q16-perl` | `Depends: imagemagick-7-common (= <версия trixie>)` |
| `libmagick++-7-headers` | `Depends: imagemagick-7-common (= <версия trixie>)` |
| `libmagick++-7.q16-dev` | `Depends: libmagickcore-7.q16-dev (= <версия trixie>)` и ещё четыре точных пина |
| `libmagickcore-dev`, `libmagickwand-dev`, `libmagick++-dev`, `perlmagick` | переходные метапакеты с `= <версия trixie>` на `imagemagick-7-common` |
| `libmagickcore-7.q16-10-extra` | носители модулей `djvu`/`exr`/`wmf`/`svg`/`pango`/`dot`, собранных под 7.1.1; наш 7.1.2 их всё равно не загрузил бы |

**Оставьте `libmagick++-7.q16-5`** (без `-dev`): он зависит от
`libmagickcore-7.q16-10 (>= 8:7.1.1.21)` — то есть только снизу, и нашу
новую библиотеку принимает. Но его `-dev`-пакет снять придётся, так что
собирать что-то против C++ API после обновления будет нельзя, пока вы не
поставите наш `libmagickcore-7.q16-dev` вручную (его состав изменился).

Проверить последствия **до** обновления:

```
apt-get -s upgrade
```

### Почему модули внутри `libmagickcore-7.q16-10`, а не в `-extra`

Путь модулей содержит версию апстрима: `ImageMagick-7.1.2/modules-Q16/`.
Модули из trixie-пакета `-extra` лежат в `ImageMagick-7.1.1/` и наша
7.1.2 их не загрузит — то есть после обновления молча пропала бы поддержка
SVG, DjVu, EXR, WMF и Graphviz. Чтобы этого не случилось, все кодировщики
и фильтры кладутся в основной пакет, а `-extra` снимается.

## Символьные файлы

`.symbols` **не поставляются**: их генерирует `dh_makeshlibs` на лету.
Причина практическая — файл `libmagickcore-...symbols` в Debian содержит
994 строки с привязкой к версиям 7.1.1.x, и любой символ, удалённый между
7.1.1 и 7.1.2, сорвал бы сборку на `dpkg-gensymbols`. Если понадобится
полноценный symbols-файл, его надо сгенерировать один раз из собранных
пакетов (`dpkg-gensymbols`) и положить в `debian/`.

## Откат

Вернуться на штатный ImageMagick trixie:

```
sudo apt install imagemagick=8:7.1.1.43+dfsg1-1+deb13u12 \
                 imagemagick-7-common=8:7.1.1.43+dfsg1-1+deb13u12 \
                 libmagickcore-7.q16-10=8:7.1.1.43+dfsg1-1+deb13u12 \
                 libmagickwand-7.q16-10=8:7.1.1.43+dfsg1-1+deb13u12
```

Символьные имена не менялись (`libMagickCore-7.Q16.so.10`,
`libMagickWand-7.Q16.so.10`), удалённых символов нет — в отличие от
намеренных разрывов ABI в `gtk+3.0`, `gtk4` и `cairo`.

Выключить HEIF обратно (и вместе с ним AVIF) — четыре правки, обратные тем,
что были сделаны при включении:

1. `--with-heic` → `--without-heic` в `debian/rules`;
2. `libheif-dev` убрать из `Build-Depends` в `debian/control`;
3. `libheif-dev` убрать из `Depends` пакета `libmagickcore-7.q16-dev`
   (тогда же из `Depends` уйдёт `libheif1` у `libmagickcore-7.q16-10`,
   который подставляется автоматически по `${shlibs:Depends}`);
4. следующая ревизия пакета в `scripts/upstream/imagemagick.conf`
   (`REVISION=4`), иначе `apt upgrade` новую сборку не подхватит.

Причина, по которой HEIF когда-то выключали, и которую стоит помнить: без
него пропадают сразу четыре формата — `HEIC`, `HEIF`, `AVCI` и `AVIF`.
