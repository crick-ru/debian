# gtk+3.0 (crick Debian backports)

Сборка GTK 3.24.52 для Debian 13 (trixie, amd64). Упаковка взята из Debian
(`gtk+3.0 3.24.52-2`) и переработана: состав бинарных пакетов урезан,
X11-бэкенд отключён.

Бинарные пакеты: `libgtk-3-0t64`, `libgail-3-0t64`, `libgail-3-dev`,
`libgtk-3-common`, `libgtk-3-bin`, `libgtk-3-dev`, `gir1.2-gtk-3.0`.

## Включено

- Все нужные для работы компоненты: Wayland-бэкенд GDK, CUPS и
  «file»-бэкенды печати, colord, cloudproviders, sysprof-профилировщик,
  интроспекция (`gir1.2-gtk-3.0`), темы Adwaita/HighContrast (собираются из
  SCSS через `sassc`), модули ввода и печати.
- Ровно те бинарные пакеты, которые реально нужны системе: 7 пакетов
  вместо 12 в Debian. `libgtk-3-bin` зависит от `gtk-update-icon-cache`,
  который собирается из пакета `gtk4` этого же репозитория (в trixie так же).
- Требования версий не занижены патчами: glib 2.57.2+, pango 1.41+,
  cairo 1.14+, gdk-pixbuf 2.30+, wayland 1.14.91+, wayland-protocols 1.17+,
  epoxy 1.4+ — всё есть в trixie. Все пакеты Debian-упаковки, кроме
  документации, собраны как есть.

## Отключено

- **X11-бэкенд GDK** (`-Dx11_backend=false`) — намеренно, под цель
  «чистый Wayland» (по правилам проекта). Единственный бэкенд —
  Wayland. Из библиотек удалены **101 символ** при неизменном SONAME:
  79 `gdk_x11_*`, 8 `gdk_broadway_*`, а также 14 символов классов, чьи
  исходники в GTK 3 объявлены как X11-only в `gtk/meson.build`
  (`gtk_use_x11_sources`): `gtk_plug_*` (8) и `gtk_socket_*` (5) —
  то есть встраивание окон одного GTK-приложения в другое, и
  `gtk_tray_icon_get_type` (1) — значок в трее. Заголовок `gdk/gdkx.h`,
  GIR-пространство имён `GdkX11` и файлы `gdk-x11-3.0.pc` /
  `gtk+-x11-3.0.pc` не устанавливаются. Из
  `Build-Depends` убраны `libx11-dev`, `libxcomposite-dev`, `libxcursor-dev`,
  `libxdamage-dev`, `libxext-dev`, `libxfixes-dev`, `libxi-dev`,
  `libxinerama-dev`, `libxrandr-dev`, `libxkbfile-dev`, `gir1.2-xlib-2.0-dev`.
- **at-spi2-core и ATK-мост (доступность для скринридеров)**. Убран
  `Depends: at-spi2-core` у пакета `libgail-3-0t64`, а `libatk-bridge2.0-dev`
  убран из `Build-Depends` и из `Depends` пакета `libgtk-3-dev`. Никакой
  опции сборки для этого в GTK 3 нет — отключение сделано на уровне
  зависимостей, и вот почему это работает:
  - `atk-bridge` в GTK 3.24.52 нужен **только X11-бэкенду**. В
    `meson.build` строка `atkbridge_dep = [] # only used in x11 backend`
    идёт рядом с комментарием, а настоящая зависимость
    `dependency('atk-bridge-2.0', ...)` стоит внутри блока
    `if x11_enabled`. X11-бэкенд у нас и так выключен
    (`-Dx11_backend=false`), поэтому `atkbridge_dep` остаётся пустым
    списком и в `gtk_deps` (`gtk/meson.build`: `gtk_deps += [ atkbridge_dep, ]`)
    попадает пустота;
  - `libgail-3-0t64` собирается без `libatspi` и `libatk-bridge` — проверено
    по `NEEDED` библиотеки из trixie: только `libgtk-3`, `libgdk-3`,
    `libglib-2.0`, `libgobject-2.0`, `libpango-1.0`, `libatk-1.0`, `libc`.
    То есть `at-spi2-core` в `Depends` был нужен Debian для скринридеров
    (Orca), а не для линковки.
  - **Что осталось:** сам ATK (`libatk1.0-dev` в `Build-Depends`,
    `libatk1.0-0t64` в `${shlibs:Depends}`) — это другое. GTK 3 использует
    `AtkObject` непосредственно в `gtk/a11y` (без него не собирается
    `GtkAccessible`), и ATK не связан с `at-spi2-core` ничем, кроме общего
    исходного пакета Debian `at-spi2-core`.
  - **Практический эффект:** приложения GTK 3 теряют экспорт доступности
    в AT-SPI, то есть скринридер Orca с ними не работает. Мышь и клавиатура
    работают как обычно — это не «специальные возможности», а их удалённый
    экспорт для оркестровки.
- Broadway (HTML5-бэкенд, `-Dbroadway_backend=false`) — как и в X11-случае,
  это альтернативный дисплейный бэкенд, а не обязательная функциональность.
- Тесты, примеры, демо, man-страницы и документация:
  `-Dtests=false -Dinstalled_tests=false -Ddemos=false -Dexamples=false
  -Dgtk_doc=false -Dman=false`. Не собираются пакеты `libgtk-3-doc`,
  `libgail-3-doc`, `gtk-3-examples`, `libgtk-3-0-udeb` (udeb — для
  debian-installer, в этом репозитории не публикуется).
- Отладочные символы (`-dbgsym`) не собираются и не публикуются (общее
  правило `scripts/build-package.sh`).
- Патчей quilt нет: все 7 патчей Debian в `gtk+3.0 3.24.52-2` относятся к
  тестам (`reftest_*`, `tests-*`), которые не собираются. Перегенерирование
  данных emoji из CLDR (`debian/missing-sources/`, 70 МБ) не выполняется —
  используются готовые `gtk/emoji/*.data` из тарбола GNOME.

## Изменено

- Версия: `3.24.52-1+crick` (новее штатной `3.24.49-3`). Тарбол GNOME
  `gtk-3.24.52.tar.xz` побайтово совпадает с
  `gtk+3.0_3.24.52.orig.tar.xz` из Debian (sha256 `80931fa4…`).
- Формат исходников `3.0 (quilt)`; собственных патчей у пакета нет.
- `debian/libgtk-3-0t64.symbols` перегенерирован без `gdk_x11_*` и
  `gdk_broadway_*` — иначе `dpkg-gensymbols` ругается на удалённые символы.

## Влияние на другие пакеты

**Это самое важное в этом пакете.** Обратных зависимостей в trixie:

| Пакет                       | Обратных зависимостей |
|-----------------------------|-----------------------|
| `libgtk-3-0t64`             | **984**               |
| `gir1.2-gtk-3.0`            | 288                   |
| `libgail-3-0t64`            | 5                     |

SONAME не изменились: `libgtk-3.so.0`, `libgdk-3.so.0`, `libgailutil-3.so.0`.
Версия 3.24.x совместима по ABI сама по себе, поэтому приложения, собранные
против GTK из trixie, продолжают работать — **кроме тех, кто напрямую
вызывает X11-API GTK без `#ifdef GDK_WINDOWING_X11`**: у таких программ
`gdk_x11_*` не находится и они падают при запуске. Проверить конкретную
программу можно так:

```bash
readelf -Ws /usr/bin/ПРИЛОЖЕНИЕ | grep gdk_x11_    # есть — сломается
```

Приложения, которые используют X11-API GTK корректно (через
`#ifdef GDK_WINDOWING_X11`, как это делает `celluloid` в этом же
репозитории), собираются и работают: у нашей сборки в
`gdkconfig.h` стоит `/* #undef GDK_WINDOWING_X11 */`, и такой код просто
выключается. `sfwbar` из этого репозитория X11-API GTK не использует вовсе.

`libgail-3-0t64` пиннит `libgtk-3-0t64 (= версия)`, поэтому он собирается
вместе с ним — иначе `apt` утащил бы `planner`, `nemo`, `caja` и
`libevolution` обратно на GTK из trixie.

Отключение `at-spi2-core` обратных зависимостей наших пакетов не имеет, но
затрагивает пользователя системы: в trixie `at-spi2-core` тянут ещё 9
пакетов (`cjs-tests`, `gjs-tests`, `mutter-16-tests`, `orca`, `phrog`,
`python3-dogtail`, `python3-pyatspi`, `caja`, `nemo`), а `libgail-3-0t64` — 4
(`caja`, `libevolution`, `nemo`, `planner`). При `apt upgrade` они снимаются
только если стояли **ради** `at-spi2-core`; если нужны сами по себе, `apt`
предложит поставить их из trixie. Для наших пакетов ничего не ломается:
ни один из них не ссылается на `at-spi2-core` ни прямо, ни через
`${shlibs:Depends}`.

## Откат

Вернуть GTK 3 из trixie нужно **всем** пакетам сразу — иначе
`libgail-3-0t64` останется без своей пары:

```bash
sudo apt install libgtk-3-0t64=3.24.49-3 libgail-3-0t64=3.24.49-3 \
  libgtk-3-common=3.24.49-3 libgtk-3-bin=3.24.49-3 \
  libgtk-3-dev=3.24.49-3 libgail-3-dev=3.24.49-3 \
  gir1.2-gtk-3.0=3.24.49-3
```

При `Pin-Priority: 1001` следующий `apt upgrade` вернёт версии из этого
репозитория обратно. `sfwbar` этого репозитория после отката
установить нельзя: ему нужен `libgtk-3-dev` версии из этого репозитория
(он требует `libwayland-dev` с API, которого нет в trixie).
