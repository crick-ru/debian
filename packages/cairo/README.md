# cairo

Библиотека 2D-векторной графики (`libcairo2`, `libcairo-gobject2`,
`libcairo-script-interpreter2`, `libcairo2-dev`).

## Источник упаковки

Упаковка написана с нуля для этого репозитория. Debian имеет пакет `cairo`,
но его упаковка привязана к X11-бэкендам (`cairo-xlib`, `cairo-xcb`,
`cairo-xlib-xrender`), которые здесь не собираются. Tarball берётся
как есть с cairographics.org (`cairo-1.18.6.tar.xz`), Debian перепаковывает
тот же архив.

## Версии

- **В trixie:** 1.18.4-1+b1
- **В исходной упаковке:** (упаковка написана с нуля)
- **В нашем репозитории:** 1.18.6-2+crick

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libcairo2` | `libcairo.so.2` |
| `libcairo-gobject2` | GObject-привязки |
| `libcairo-script-interpreter2` | Lua-интерпретатор для cairo-скриптов |
| `libcairo2-dev` | заголовки, pkg-config, симлинки |

Все четыре пакета имеют `Multi-Arch: same` и пинят друг друга через
`= ${binary:Version}`.

## Что изменено

### Отключено

- **X11-бэкенды** (правило репозитория): `-Dxlib=disabled -Dxcb=disabled
  -Dxlib-xcb=disabled`. Не компилируются `cairo-xlib-surface.c`,
  `cairo-xcb-*.c`, не устанавливаются заголовки `cairo-xlib.h`,
  `cairo-xlib-xrender.h`, `cairo-xcb.h` и файлы `pkgconfig/cairo-xlib.pc`,
  `pkgconfig/cairo-xcb.pc`. Из `Build-Depends` убраны `libx11-dev`,
  `libxext-dev`, `libxrender-dev`, `libxcb1-dev`, `libxcb-render0-dev`,
  `libxcb-shm0-dev`, `libx11-xcb-dev`.
- **Тесты:** `-Dtests=disabled` (иначе подтягиваются `ghostscript`,
  `libspectre`, `poppler-glib`, `librsvg-2.0`). Тесты не собираются и не
  запускаются.
- **Документация:** `-Dgtk_doc=false` (дефолт апстрима), пакет
  `libcairo2-doc` не публикуется.
- **Отладочные утилиты:** `-Dsymbol-lookup=disabled`, удалены
  `libcairo-trace.so`, `libcairo-fdr.so` и `cairo-trace(1)` из staging-дерева.
- `libcairo2-udeb` не публикуется.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- Бэкенды: `image`, `png`, `svg`, `ps`, `pdf`, `script`, `tee`
- Шрифты: `freetype` + `fontconfig`
- GObject-привязки (`libcairo-gobject2`)
- Lua-интерпретатор (`libcairo-script-interpreter2`)
- `liblzo2`

## Патчи

Нет: `debian/patches/series` отсутствует.

## Изменения ABI

SONAME `libcairo.so.2` не меняется (файл `libcairo.so.2.11800.6`). При
неизменном SONAME из библиотеки удалены 26 публичных функций — все, что
объявлено в `cairo-xlib.h`, `cairo-xlib-xrender.h` и `cairo-xcb.h`
(16 функций `cairo_xlib_*` + 10 функций `cairo_xcb_*`). Апструп предупреждает
об этом: опции `xlib`/`xcb` меняют ABI без смены SONAME.

### Последствия

Масштаб: в trixie на `libcairo2` завязано около 880 пакетов.

Код, который перестаёт работать:
- **GTK 2** — `libgtk2.0-0t64` создаёт Xlib-поверхности через cairo.
- **`libghc-gi-gdkx11-dev`** — Haskell-биндинг GdkX11.

Код, который работает (X11-API не вызывается):
- `xserver-xorg-core` не зависит от `libcairo2`.
- Пакеты этого репозитория (`libgtk-3-0t64`, `libgtk-4-1`, `labwc`,
  `librsvg`, `weston`, `gdk-pixbuf`) не используют X11-API cairo.

Проверка конкретной программы:
```
readelf -Ws /usr/bin/ПРОГРАММА | grep -E 'cairo_(xlib|xcb)_'
```
Пусто — программа переживёт обновление.

## Важные нюансы

Символьных файлов (`debian/*.symbols`) нет намеренно: их пришлось бы
переписывать под урезанный набор символов. Статических библиотек нет
(`--disable-static`).
