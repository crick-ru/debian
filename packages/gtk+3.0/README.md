# gtk+3.0

GTK 3.24.52: многоплатформенный toolkit для создания графических интерфейсов.

## Источник упаковки

Упаковка взята из Debian (`gtk+3.0 3.24.52-2`, ветка unstable) и переработана:
состав бинарных пакетов урезан, X11-бэкенд отключён. Tarball побайтово
совпадает с Debian-овским `gtk+3.0_3.24.52.orig.tar.xz`
(sha256 `80931fa4…`).

## Версии

- **В trixie:** 3.24.49-3
- **В исходной упаковке:** 3.24.52-2
- **В нашем репозитории:** 3.24.52-2+crick

## Содержимое

`libgtk-3-0t64`, `libgtk-3-common`, `libgtk-3-bin`, `libgtk-3-dev`,
`gir1.2-gtk-3.0`, `libgail-3-0t64`, `libgail-3-dev`.

Семь пакетов вместо 12 в Debian.

## Что изменено

### Отключено

- **X11-бэкенд GDK** (правило репозитория): `-Dx11_backend=false`. Единственный
  бэкенд — Wayland. Broadway также выключен (`-Dbroadway_backend=false`).
  Из `Build-Depends` убраны все X11-библиотеки: `libx11-dev`,
  `libxcomposite-dev`, `libxcursor-dev`, `libxdamage-dev`, `libxext-dev`,
  `libxfixes-dev`, `libxi-dev`, `libxrandr-dev`, `libxkbfile-dev`,
  `gir1.2-xlib-2.0-dev`. Заголовок `gdk/gdkx.h`, GIR `GdkX11-3.0` и файлы
  `gdk-x11-3.0.pc` / `gtk+-x11-3.0.pc` не устанавливаются.
- **at-spi2-core / ATK-мост** (доступность для скринридеров): убран
  `Depends: at-spi2-core` из `libgail-3-0t64`, `libatk-bridge2.0-dev` убран
  из `Build-Depends` и из `Depends` `libgtk-3-dev`. В GTK 3 `atk-bridge`
  нужен только X11-бэкенду (инициализируется внутри `if x11_enabled`),
  который у нас выключен. Сам ATK (`libatk1.0-dev`) не трогается — GTK
  использует `AtkObject` напрямую.
- **Тесты, примеры, демо, man-страницы, документация:** `-Dtests=false
  -Dinstalled_tests=false -Ddemos=false -Dexamples=false -Dgtk_doc=false
  -Dman=false`. Не собираются пакеты `libgtk-3-doc`, `libgail-3-doc`,
  `gtk-3-examples`, `libgtk-3-0-udeb`.
- **Перегенерация emoji из CLDR** не выполняется: используются готовые
  `gtk/emoji/*.data` из тарбола GNOME.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- Wayland-бэкенд GDK, CUPS и file-бэкенды печати, colord, cloudproviders,
  sysprof-профилировщик, интроспекция, темы Adwaita/HighContrast.

## Патчи

Нет: все 7 патчей Debian в `gtk+3.0 3.24.52-2` относятся к тестам, которые
не собираются, и не переносятся.

## Изменения ABI

SONAME не меняются: `libgtk-3.so.0`, `libgdk-3.so.0`, `libgailutil-3.so.0`.

При выключении X11 из `libgtk-3.so.0` удалено **101 символ** при неизменном
SONAME: 79 `gdk_x11_*`, 8 `gdk_broadway_*`, 14 символов классов
(`gtk_plug_*` (8), `gtk_socket_*` (5), `gtk_tray_icon_get_type` (1)).

### Последствия

В trixie на `libgtk-3-0t64` зависят **984** пакета, на `gir1.2-gtk-3.0` — 288.

Приложения, которые перестают работать: те, кто зовёт `gdk_x11_*` напрямую
без `#ifdef GDK_WINDOWING_X11`. Приложения с корректной проверкой
(`#ifdef GDK_WINDOWING_X11`) работают: в нашей сборке
`/* #undef GDK_WINDOWING_X11 */`.

Проверка конкретной программы:
```
readelf -Ws /usr/bin/ПРИЛОЖЕНИЕ | grep gdk_x11_
```
Пусто — программа переживёт обновление.

## Важные нюансы

`libgail-3-0t64` пиннит `libgtk-3-0t64 (= ${binary:Version})`.
`celluloid` и `sfwbar` из этого репозитория собираются против этой сборки GTK.
`libgtk-3-bin` зависит от `gtk-update-icon-cache` из `gtk4` этого репозитория.
