# gstreamer1.0 — ядро (crick Debian backports)

Сборка ядра GStreamer 1.28.7 для Debian 13 (trixie, amd64). Упаковка взята из
Debian (`gstreamer1.0 1.28.7-1`) и упрощена. Это фундамент медиастека: от него
зависят все четыре набора плагинов, а также `gtk4` и `pipewire`.

## Включено

- `libgstreamer1.0-0` — библиотека ядра, сканер плагинов и плагины ядра.
- `libgstreamer1.0-dev` — заголовки, pkg-config и данные GObject
  introspection (`gir1.2-gstreamer-1.0`).
- `gstreamer1.0-tools` — `gst-inspect-1.0`, `gst-launch-1.0`, `gst-stats-1.0`,
  `gst-typefind-1.0`, bash-дополнения и man-страницы этих четырёх утилит
  (готовые, из tar-бола — см. «Отключено»).

## Отключено

- Документация: `-Ddoc=disabled`. Пакеты `gstreamer1.0-doc` и
  `gstreamer1.0-doc-hotdoc` не публикуются, `hotdoc` в `Build-Depends` не
  нужен. Ни одна man-страница не генерируется: в логе сборки нет ни одного
  запуска `rst2man`, `hotdoc` собирается только как бинарник
  `gst-hotdoc-plugins-scanner`, а `docs/gst-plugins-doc-cache-generator`
  исключён через `debian/not-installed`.
- **Man-страницы утилит публикуются** — четыре готовые страницы
  `gst-inspect-1.0.1`, `gst-launch-1.0.1`, `gst-stats-1.0.1` и
  `gst-typefind-1.0.1`. Они не генерируются, а приходят готовыми в
  tar-боле (meson ставит их из каталога `tools/` в дереве исходников), то
  есть это то самое исключение из правила «документация не публикуется»,
  которым являются `xkbcli.1` в libxkbcommon и `celluloid.1`. Они описаны в
  `debian/gstreamer1.0-tools.manpages` и едут в `gstreamer1.0-tools` вместе
  с самими утилитами. `gst-tester-1.0` man-страницы не имеет: утилита не
  собирается (см. ниже про тесты). Раньше README утверждал, что man-страниц
  нет вовсе, и `override_dh_installman` был пустым — из-за этого
  `dh_missing --fail-missing` останавливал сборку с «exists in debian/tmp but
  is not installed to anywhere».
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
