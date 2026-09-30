# imagemagick (crick Debian backports)

Сборка `ImageMagick` 7.1.2-32 для Debian 13 (trixie) **без X11**, только в
квантовой глубине Q16.

Версия: `8:7.1.2-32-1+crick` (ревизия 1 — первая публикация).

## Почему epoch 8 — обязателен

Trixie содержит `8:7.1.1.43+dfsg1-1+deb13u12`, то есть с **epoch 8**.
apt сравнивает epoch первым, поэтому наша сборка без epoch — `7.1.2-32-1+crick`
— оказалась бы **старее** штатной, и `apt upgrade` её просто не подхватил бы.
Ровно та же причина, по которой epoch 7 задан для `ffmpeg`. Карта epoch живёт
в `scripts/fetch-upstream.sh`.

Обратите внимание: `7.1.2-32` действительно новее `7.1.1.43` — сравнение
идёт по компонентам, `2 > 1` в третьем разряде.

## Включено

- Квантовая глубина Q16: `--with-quantum-depth=16`, `--enable-hdri=no`.
- Динамически загружаемые модули: `--with-modules`. Все кодировщики
  (coders) и фильтры едут **внутри** `libmagickcore-7.q16-10`, а не отдельным
  пакетом `-extra` (см. ниже).
- Делегаты: DjVu, HEIC, OpenJPEG, WebP, WMF, FFTW, `zlib`/`bzip2`/`lzma`,
  JPEG, PNG, TIFF, Raw, OpenEXR, liblqr, LCMS, Fontconfig/FreeType, pango,
  XML. librsvg выключен (`--without-rsvg`), как и в Debian: вместо него
  работает встроенный рендерер MSVG, а зависимость от cairo/pango в
  `libmagickcore` не появляется.
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
триксийские версии пинят **точную** версию `imagemagick-7-common` и
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
Модули из триксийского `-extra` лежат в `ImageMagick-7.1.1/` и наша
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
