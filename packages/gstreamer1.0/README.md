# gstreamer1.0 — ядро (crick Debian backports)

Сборка ядра GStreamer 1.28.7 для Debian 13 (trixie, amd64). Упаковка взята из
Debian (`gstreamer1.0 1.28.7-1`) и упрощена. Это фундамент медиастека: от него
зависят все четыре набора плагинов, а также `gtk4` и `pipewire`.

## Включено

- `libgstreamer1.0-0` — библиотека ядра, сканер плагинов и плагины ядра.
- `libgstreamer1.0-dev` — заголовки, pkg-config и данные GObject
  introspection (`gir1.2-gstreamer-1.0`).
- `gstreamer1.0-tools` — `gst-inspect-1.0`, `gst-launch-1.0`, `gst-stats-1.0`,
  `gst-tester-1.0`, `gst-typefind-1.0`, bash-дополнения.

## Отключено

- Документация: `-Ddoc=disabled`. Пакеты `gstreamer1.0-doc` и
  `gstreamer1.0-doc-hotdoc` не публикуются, `hotdoc` в `Build-Depends` не
  нужен. Man-страниц у пакетов нет.
- Примеры: `-Dexamples=disabled`.
- Тесты: `-Dtests=disabled`, каталог `debian/tests` удалён. Debian патчит
  `0001_skip-gstdevice-test.patch` для обхода тестов — он не переносится,
  потому что тесты не собираются.
- Отладочный стек: `-Dlibunwind=disabled -Dlibdw=disabled` — так же, как в
  Debian, где поведение нестабильно между архитектурами. Убраны `libunwind-dev`
  и `libdw-dev`.
- PTP-помощник: `-Dptp-helper=disabled`. Он написан на Rust, и `rustc` в
  `Build-Depends` тянет целый toolchain ради одной программы, которая нужна
  только серверам точного времени (PTP), а не десктопу. Символы `gst_ptp_*`
  в библиотеке при этом остаются — они не связаны с бинарником-помощником.
- Инструмент сопровождения Debian `dh_gstscancodecs` и его man-страница не
  публикуются: это проверка списка кодеков при сборке, а не то, что нужно
  пользователю.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Версия: `1.28.7-1+crick`.
- Плагины `gst-plugins-doc-cache-generator` и `gst-hotdoc-plugins-scanner`
  исключены через `debian/not-installed`: они относятся к документации.
- `Maintainer`: нейтральная идентичность проекта.

## Откат

`apt install gstreamer1.0/libgstreamer1.0-0/trixie libgstreamer1.0-dev/trixie
gstreamer1.0-tools/trixie gir1.2-gstreamer-1.0/trixie` возвращает ядро из
архива. Обратная совместимость полная: SONAME `libgstreamer-1.0.so.0` и
`libgstbase-1.0.so.0` не менялись, символы не удалялись.
