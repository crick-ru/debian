# gtkmm4.0

gtkmm — C++ интерфейс к GTK 4 (API version 4.0), версия 4.22.0.

## Источник упаковки

Упаковка взята из Debian (`gtkmm4.0 4.24.0-2`, ветка debian/sid) и переведена
на апстримный gtkmm 4.22.0. Tarball `gtkmm-4.22.0.tar.xz` скачан с GNOME
(https://download.gnome.org/sources/gtkmm/4.22/), а Debian `debian/`
адаптирована под эту версию.

Отличие от Debian: Debian собирает gtkmm 4.24.0 с `libgtk-4-dev (>= 4.24)`,
но наш репозиторий имеет GTK4 4.22.5 (4.24.x требует glib 2.90 и meson 1.8,
недоступных в trixie). Поэтому используем апстримный gtkmm 4.22.0, который
требует `libgtk-4-dev (>= 4.22)` и `libglibmm-2.68-dev (>= 2.75.0)` —
всё это доступно из trixie.

## Версии

- **В trixie:** 4.18.0-1
- **В исходной упаковке:** 4.24.0-2 (Debian unstable)
- **В нашем репозитории:** 4.22.0-1+crick (апстрим 4.22.0 + Debian упаковка 4.24.0-2, адаптированная)

## Содержимое

`libgtkmm-4.0-0` (общие библиотеки), `libgtkmm-4.0-dev` (заголовки, pkg-config,
gmmproc).

## Что изменено

### Отключено

- **Документация:** `-Dbuild-documentation=false`; удалены `doxygen`, `graphviz`,
  `xsltproc` из `Build-Depends`; удалена stanza `libgtkmm-4.0-doc` и файлы
  `libgtkmm-4.0-doc.*`/`.docs`; удалён `libgtkmm-4.0-0.docs`.
- **Демки:** `-Dbuild-demos=false`; `libcairomm-1.16` из trixie тянет
  X11-символы `cairo_xlib_*`, которые недоступны при сборке без X11.
- **Тесты/X11:** `xauth` и `xvfb` (`<!nocheck>`) удалены из `Build-Depends`;
  `-Dbuild-tests=false` (тесты не собираются, а не только не запускаются —
  `libcairomm-1.16` из trixie тянет X11-символы `cairo_xlib_*`);
  `override_dh_auto_test` пустой.
- **debhelper-compat** понижен с 14 на 13 (соответствует общему правилу репозитория).
- **dbgsym-пакеты** не собираются (общее правило `scripts/build-package.sh`).

### Версии зависимостей

- `libgtk-4-dev (>= 4.24)` → `(>= 4.22)`: сборка против GTK 4.22.5 этого
  репозитория, а не GTK 4.24 из sid.
- `libglibmm-2.68-dev (>= 2.89.0)` → `(>= 2.75.0)`: требование соответствует
  апстриму gtkmm 4.22.0, а не Debian-пакету 4.24.0.

## Патчи

Патчей Debian нет (пустой `debian/patches/series`).

## Важные нюансы

Этот пакет нужен как Build-Depend для `transmission` (GTK-клиент использует gtkmm).
Trixie `libgtkmm-4.0-dev` 4.18.0 несовместим с нашим GTK4 4.22.5: заголовок
`gtkmm/iconpaintable.h` объявляет `using GtkIconPaintableClass = struct _GtkIconPaintableClass`,
что конфликтует с `G_DECLARE_FINAL_TYPE` в GTK4 4.22.x (который уже typedef-ит этот класс).
Апстримный gtkmm 4.22.0 исправляет это: использует `using BaseClassType = GtkIconPaintableClass;`
без повторного объявления.
