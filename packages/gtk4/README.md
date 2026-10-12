# gtk4

GTK 4.22.5: многоплатформенный toolkit для создания графических интерфейсов
(4-я версия).

## Источник упаковки

Упаковка взята из Debian (`gtk4 4.22.4+ds-1`, ветка 4.22) и переведена на
GTK 4.22.5. Состав бинарных пакетов урезан, X11-бэкенд отключён.
Tarball побайтово совпадает с Debian-овским `gtk4_4.22.4+ds.orig.tar.xz`
(Debian не использует `+ds` для самых свежих версий 7.1.2).

## Версии

- **В trixie:** 4.18.6+ds-2
- **В исходной упаковке:** 4.22.4+ds-1
- **В нашем репозитории:** 4.22.5-2+crick

Ограничение: GTK 4.24 требует glib 2.90 и meson 1.8, чего в trixie нет,
поэтому 4.22.5 — максимум для этого репозитория.

## Содержимое

`libgtk-4-1`, `libgtk-4-common`, `libgtk-4-bin`, `libgtk-4-dev`,
`gir1.2-gtk-4.0`, `gtk-update-icon-cache`.

## Что изменено

### Отключено

- **X11-бэкенд GDK** (правило репозитория): `-Dx11-backend=false`.
  Единственный бэкенд — Wayland. Из `Build-Depends` убраны все X11-библиотеки:
  `libx11-dev`, `libxcomposite-dev`, `libxcursor-dev`, `libxdamage-dev`,
  `libxext-dev`, `libxfixes-dev`, `libxi-dev`, `libxinerama-dev`,
  `libxrandr-dev`, `libxkbfile-dev`, `gir1.2-xlib-2.0-dev`. Заголовок
  `gdk/gdkx.h`, GIR `GdkX11-4.0` и файл `gtk4-x11-4.0.pc` не устанавливаются.
- **Broadway** (`-Dbroadway-backend=false`).
- **Тесты, примеры, демо, man-страницы, документация:** `-Dbuild-testsuite=false
  -Dbuild-tests=false -Dbuild-examples=false -Dbuild-demos=false
  -Ddocumentation=false -Dman-pages=false`. Не собираются пакеты `libgtk-4-doc`,
  `gtk-4-examples`, `gtk-4-tests`, `libgtk-4-1-udeb`.
- **Перегенерация emoji из CLDR** не выполняется: используются готовые
  `gtk/emoji/*.data` из тарбола GNOME.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- Wayland-бэкенд GDK, CUPS/file-бэкенды печати, colord, cloudproviders,
  sysprof, интроспекция, темы Adwaita/HighContrast.
- **GStreamer-медиа** внутри `libgtk-4-1`: `-Dmedia-gstreamer=enabled`.
  Пакет объявляет `Provides: libgtk-4-media-gstreamer (= ${binary:Version})`.

## Патчи

Один патч Debian сохранён: `print-Fix-listing-printers-with-synchronous-backends.patch`.
Ещё два патча Debian (`gtkapplication-wayland`, 32-битный `gskvulkanimage`)
в 4.22.5 уже в апступе и удалены.

## Изменения ABI

SONAME не меняется: `libgtk-4.so.1`. При выключении X11 из `libgtk-4.so.1`
удалено **81 символ**: 69 `gdk_x11_*`, 9 `gdk_broadway_*`, 2
`gsk_broadway_renderer_*`, служебный `_gtk_resource_data`.

### Последствия

В trixie на `libgtk-4-1` зависят **170** пакетов, на `gir1.2-gtk-4.0` — 58.

Приложения, которые перестают работать: те, кто зовёт `gdk_x11_*` напрямую
без `#ifdef GDK_WINDOWING_X11`. GTK 4 не имеет классов, живущих только на
X11 (GtkPlug/GtkSocket/GtkTrayIcon в GTK 4 отсутствуют), поэтому
потерь помимо X11-символов нет.

`celluloid` из этого репозитория использует `#ifdef GDK_WINDOWING_X11`
(в `celluloid-mpv.c`, `celluloid-application.c`, `celluloid-video-area.c`),
поэтому собирается и работает как есть.

Проверка конкретной программы:
```
readelf -Ws /usr/bin/ПРИЛОЖЕНИЕ | grep gdk_x11_
```
Пусто — программа переживёт обновление.

## Важные нюансы

- `libgtk-4-dev` требует `libwayland-dev (>= 1.24.0)`: GTK 4.22.5 жёстко
  требует wayland ≥ 1.24, которого в trixie (1.23.1) нет, поэтому wayland
  берётся из этого репозитория (см. `packages/wayland/README.md`).
- `gtk-update-icon-cache` собирается именно здесь, `libgtk-3-bin` зависит
  от него.
- `debian/libgtk-4-1.symbols` перегенерирован без `gdk_x11_*` и
  `gdk_broadway_*`.
