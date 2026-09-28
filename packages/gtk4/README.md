# gtk4 (crick Debian backports)

Сборка GTK 4.22.5 для Debian 13 (trixie, amd64). Упаковка взята из Debian
(`gtk4 4.22.4+ds-1`, ветка 4.22) и переработана: состав бинарных пакетов
урезан, X11-бэкенд отключён.

Бинарные пакеты: `libgtk-4-1`, `libgtk-4-common`, `libgtk-4-bin`,
`libgtk-4-dev`, `gir1.2-gtk-4.0`, `gtk-update-icon-cache`.

## Включено

- Wayland-бэкенд GDK, рендереры Cairo/GL/Vulkan (включая GSK-рендерер
  4.22), CUPS-печать, colord, cloudproviders, sysprof, интроспекция,
  Accessibility (ATK-мост), emoji CLDR 48.
- **GStreamer-медиа внутри `libgtk-4-1`**: начиная с 4.19.2 модуль
  `libgtk-4-media-gstreamer` собирается в состав `libgtk-4.so.1`, поэтому
  пакет объявляет `Provides: libgtk-4-media-gstreamer (= ${binary:Version})`
  и `Breaks/Replaces libgtk-4-media-gstreamer (<< 4.19.2)`. Отдельного
  бинарного пакета `libgtk-4-media-gstreamer` в Debian больше нет, так что
  media-поддержка входит в набор «как есть».
- `gtk-update-icon-cache` собирается именно здесь (в trixie — тоже из gtk4),
  поэтому `gtk-update-icon-cache.links` создаёт синоним
  `/usr/bin/gtk-update-icon-cache`, а `libgtk-4-bin` и `libgtk-3-bin`
  зависят от него.
- Один патч Debian сохранён:
  `print-Fix-listing-printers-with-synchronous-backends.patch` (иначе в
  списке CUPS-принтеров остаются синхронные бэкенды). Ещё два патча Debian
  (`gtkapplication-wayland` NULL-проверка и 32-битная сборка
  `gskvulkanimage`) в 4.22.5 уже в апстриме и удалены из серии.
- Требования к зависимостям не занижены патчами: glib ≥ 2.84, pango ≥ 1.56,

## Отключено

- **X11-бэкенд GDK** (`-Dx11-backend=false`) — намеренно, под цель
  «чистый Wayland» (см. `.clinerules/project.md`). Единственный бэкенд —
  Wayland. Из `libgtk-4.so.1` удалены **81 символ** при неизменном SONAME:
  69 `gdk_x11_*` (включая `(arch=linux-any)gdk_x11_vulkan_context_get_type`),
  9 `gdk_broadway_*`, 2 `gsk_broadway_renderer_*` (рендерер broadway — тоже
  X11/HTML5-ветка, но в GSK) и служебный `(optional)_gtk_resource_data`.
  Заголовок `gdk/gdkx.h`, GIR `GdkX11-4.0` и файл
  `gtk4-x11-4.0.pc` не устанавливаются. В отличие от GTK 3, в GTK 4 нет
  классов, живущих только на X11 (GtkPlug/GtkSocket/GtkTrayIcon в GTK 4
  отсутствуют), поэтому других символов не теряется. Из `Build-Depends`
  убраны `libx11-dev`, `libxcomposite-dev`, `libxcursor-dev`, `libxdamage-dev`,
  `libxext-dev`, `libxfixes-dev`, `libxi-dev`, `libxinerama-dev`,
  `libxrandr-dev`, `libxkbfile-dev`, `gir1.2-xlib-2.0-dev`.
- Broadway (`-Dbroadway-backend=false`), тесты, примеры, демо, man-страницы,
  документация: `-Dbuild-testsuite=false -Dbuild-tests=false
  -Dbuild-examples=false -Dbuild-demos=false -Ddocumentation=false
  -Dman-pages=false`. Не собираются `libgtk-4-doc`, `gtk-4-examples`,
  `gtk-4-tests`, `libgtk-4-1-udeb`.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются (общее
  правило `scripts/build-package.sh`).
- Перегенерирование данных emoji из CLDR не выполняется: `debian/convert-emoji`
  требовал бы `libjson-glib-dev:native` и дерево `debian/missing-sources`
  объёмом 70 МБ, поэтому удалён из `Build-Depends`, а готовые
  `gtk/emoji/*.data` берутся из тарбола GNOME.

## Изменено

- Версия: `4.22.5-1+crick` (новее штатной `4.18.6+ds-2`).
- `Maintainer`: нейтральная идентичность проекта.
- Формат исходников `3.0 (quilt)`; quilt-серия сокращена с 22 патчей до 1.
- `debian/libgtk-4-1.symbols` перегенерирован без `gdk_x11_*` и
  `gdk_broadway_*` — иначе `dpkg-gensymbols` ругается на удалённые символы.
- `libgtk-4-dev` требует `libwayland-dev (>= 1.24.0)`: GTK 4.22.5 жёстко
  требует wayland ≥ 1.24, которого в trixie (1.23.1) нет, поэтому GTK
  собирается против `wayland` 1.26.0 из этого репозитория (стадия CI 2).

## Влияние на другие пакеты

Обратных зависимостей в trixie:

| Пакет              | Обратных зависимостей |
|--------------------|-----------------------|
| `libgtk-4-1`       | **170**               |
| `gir1.2-gtk-4.0`   | 58                    |

SONAME прежний: `libgtk-4.so.1`, поэтому `celluloid`, `libadwaita`,
`libvte`, `gnome-control-center`, `webkitgtk` и остальные GTK 4-приложения
продолжают работать без пересборки: GTK гарантирует совместимость внутри
мажорной версии 4.x, а `libadwaita`/`celluloid`, собранные против 4.18,
используют только стабильный API.

Как и в `gtk3`, программы, которые зовут X11-API GTK напрямую (без
`#ifdef GDK_WINDOWING_X11`), сломаются — у них `gdk_x11_*` не находится:

```bash
readelf -Ws /usr/bin/ПРИЛОЖЕНИЕ | grep gdk_x11_    # есть — сломается
```

`celluloid` из этого репозитория использует `#ifdef GDK_WINDOWING_X11`
(в `celluloid-mpv.c`, `celluloid-application.c`, `celluloid-video-area.c`),
поэтому собирается и работает с этой сборкой как есть: у нас в
`gdkconfig.h` стоит `/* #undef GDK_WINDOWING_X11 */`, и X11-ветки кода
выключаются препроцессором.

## Откат

Все пакеты GTK 4 надо вернуть разом, иначе `-dev`/`bin` останутся без своей
пары:

```bash
sudo apt install libgtk-4-1=4.18.6+ds-2 libgtk-4-common=4.18.6+ds-2 \
  libgtk-4-bin=4.18.6+ds-2 libgtk-4-dev=4.18.6+ds-2 \
  gir1.2-gtk-4.0=4.18.6+ds-2 gtk-update-icon-cache=4.18.6+ds-2
```

При `Pin-Priority: 1001` следующий `apt upgrade` вернёт версии из этого
репозитория обратно. После отката `celluloid` этого репозитория
установить нельзя: ему нужен `libgtk-4-dev` с wayland ≥ 1.24.

  cairo ≥ 1.18.2, harfbuzz ≥ 8.4, graphene ≥ 1.10, epoxy ≥ 1.4,
  gobject-introspection ≥ 1.84, gstreamer ≥ 1.24 — всё есть в trixie.
