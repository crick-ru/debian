# gstreamer1.0

Ядро GStreamer 1.28: библиотека `libgstreamer1.0-0`, dev-пакет
`libgstreamer1.0-dev`, утилиты `gstreamer1.0-tools`, GIR `gir1.2-gstreamer-1.0`.

## Источник упаковки

Упаковка взята из Debian (`gstreamer1.0_1.28.7-1`, ветка unstable) и
переработана. Tarball побайтово совпадает с Debian-овским
`gstreamer_1.28.7.orig.tar.xz`.

## Версии

- **В trixie:** 1.26.2-2
- **В исходной упаковке:** 1.28.7-1
- **В нашем репозитории:** 1.28.7-1+crick

Все пять пакетов GStreamer в этом репозитории носят одну строку версии
`1.28.7-1+crick`: их `-dev`-пакеты пинят sibling-пакеты `= ${binary:Version}`.

## Содержимое

- `libgstreamer1.0-0` — библиотека ядра, сканер плагинов, плагины ядра
- `libgstreamer1.0-dev` — заголовки, pkg-config, GIR
- `gstreamer1.0-tools` — `gst-inspect-1.0`, `gst-launch-1.0`,
  `gst-stats-1.0`, `gst-typefind-1.0` + bash-дополнения
- `gir1.2-gstreamer-1.0` — данные GObject introspection

## Что изменено

### Отключено

- **Документация:** `-Ddoc=disabled`. Пакеты `gstreamer1.0-doc` и
  `gstreamer1.0-doc-hotdoc` не публикуются.
- **Примеры:** `-Dexamples=disabled`.
- **Тесты:** `-Dtests=disabled`, категек `debian/tests` удалён. Патч Debian
  `0001_skip-gstdevice-test.patch` не переносится — тесты не собираются.
- **Отладочный стек:** `-Dlibunwind=disabled -Dlibdw=disabled`. Убраны
  `libunwind-dev` и `libdw-dev`.
- **PTP-помощник:** `-Dptp-helper=disabled` (написан на Rust, `rustc` в
  `Build-Depends` тянул бы целый toolchain ради одной программы, которая
  нужна только серверам точного времени). Символы `gst_ptp_*` в библиотеке
  при этом остаются.
- **Инструмент Debian `dh_gstscancodecs`** и его man-страница не публикуются.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- Готовые man-страницы (`gst-inspect-1.0.1` и т.д.) приходят в tar-боле и
  устанавливаются — как исключение из правила «man-страницы не публикуются».

## Патчи

Нет: `debian/patches/series` отсутствует. Плагины `gst-plugins-doc-cache-generator`
и `gst-hotdoc-plugins-scanner` исключены через `debian/not-installed`.

## Важные нюансы

`gstreamer1.0` является фундаментом медиастека: от него зависят все четыре
набора плагинов, а также `gtk4` и `pipewire`.
