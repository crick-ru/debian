# celluloid

Графический GTK4-фронтенд для `mpv`.

## Источник упаковки

Упаковка взята из Debian (`celluloid_0.29-1`, ветка unstable) и переработана.
Tarball побайтово совпадает с Debian-овским `celluloid_0.29.orig.tar.xz`.

## Версии

- **В trixie:** 0.28-2
- **В исходной упаковке:** 0.29-3
- **В нашем репозитории:** 0.29-2+crick (ревизия 2 — из-за переработки упаковки)

Сборка 0.29 новее версии из trixie (0.28).

## Содержимое

- `celluloid` — единственный бинарный пакет: GTK4-интерфейс и библиотека
  `libmpv`.

## Что изменено

### Отключено

- **Тесты:** патч `02_no-tests.patch` убирает `subdir('test')` из `meson.build`
  (опций для отключения тестов у celluloid нет). Тестовые программы
  `test-option-parser` и `test-playlist-model` не компилируются.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- Собирается против `libgtk-4-dev` **этого репозитория**, а не GTK из trixie:
  в публикуемой `libgtk-4.so.1` нет символов `gdk_x11_*`, а линковка с
  `-Wl,-z,now` означала бы, что бинарь, собранный с X11-API, не запустился бы.
- X11-API GTK не используется: код `celluloid` находится за
  `#ifdef GDK_WINDOWING_X11`, который в сборке GTK без X11 не определён.
- `libadwaita-1-dev` из trixie совместим: требует `libgtk-4-dev (>= 1.17.5)`.

## Патчи

Два патча из упаковки Debian:

1. `01_use-appstreamcli.patch` — метаданные AppStream собираются через
   `appstreamcli`, так как `appstream-util` в trixie больше не поставляется.
2. `02_no-tests.patch` — удаляет `subdir('test')` из `meson.build`.

## Важные нюансы

`celluloid` работает напрямую с чисто Wayland-библиотекой `libmpv2` из этого
репозитория (см. `packages/mpv/README.md`). Готовая man-страница `celluloid.1`
устанавливается из tar-бола, ничего не собирается.
