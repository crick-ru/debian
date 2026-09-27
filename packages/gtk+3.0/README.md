# gtk+3.0 (crick Debian backports)

Сборка GTK 3.24.52 для Debian 13 (trixie, amd64). Упаковка взята из Debian
(`gtk+3.0 3.24.52-2`) и переработана: состав бинарных пакетов урезан,
X11-бэкенд отключён.

Бинарные пакеты: `libgtk-3-0t64`, `libgail-3-0t64`, `libgail-3-dev`,
`libgtk-3-common`, `libgtk-3-bin`, `libgtk-3-dev`, `gir1.2-gtk-3.0`.

## Зачем нужна более свежая версия

В trixie — `3.24.49-3`, здесь `3.24.52-1+crick`. Между ними три релиза
апстрима, и они не только косметические:

- `3.24.50` — починен краш в Wayland-бэкенде, добавлена сборка с libcups 3,
  убран захардкоженный шрифт Cantarell в темах;
- `3.24.51` — обход use-after-free с потоками в X11, корректные utf8-заголовки
  окон на Wayland, замена `gdk_pixbuf_get_pixels` на потокобезопасный
  `read_pixels`;
- `3.24.52` — краши Firefox в `gdk_wayland_drag_context_manage_dnd()` без
  toplevel-`wl_surface`, корректная обработка сбоев инициализации XKB,
  обновление данных emoji до CLDR 48, починены утечки памяти и a11y-события
  в нефокусированном `GtkTreeView`.

Версия 3.24.52 — последняя: апстрим сокращает частоту релизов GTK 3 до
критических исправлений, следующий ожидается в марте 2027.

## Включено

- Все нужные для работы компоненты: Wayland-бэкенд GDK, ATK-мост, CUPS и
  «file»-бэкаенды печати, colord, cloudproviders, sysprof-профилировщик,
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
  «чистый Wayland» (см. `.clinerules/project.md`). Единственный бэкенд —
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
- `Maintainer`: нейтральная идентичность проекта.
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
