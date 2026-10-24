# libadwaita-1

Библиотека с виджетами GTK для мобильных устройств (libadwaita).

## Источник упаковки

Упаковка взята из Debian (`libadwaita-1_1.10.0-2`, ветка unstable) и
переработана. Tarball побайтово совпадает с Debian-овским
`libadwaita-1_1.10.0.orig.tar.xz`.

## Версии

- **В trixie:** 1.7.6
- **В исходной упаковке:** 1.10.0-2
- **В нашем репозитории:** 1.10.0-2+crick (ревизия 1)

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libadwaita-1-0` | `libadwaita-1.so.0` |
| `libadwaita-1-dev` | заголовки, `libadwaita-1.so`, `libadwaita-1.pc`, typelib |
| `gir1.2-adw-1` | GIR-данные для libadwaita |

## Что изменено

### Отключено

- **Документация:** `-Ddocumentation=false`. Удалён пакет `libadwaita-1-doc`,
  из `Build-Depends` удалены `gi-docgen`.
- **Примеры:** `-Dexamples=false`. Удалён пакет `libadwaita-1-examples`.
- **Тесты:** `-Dtests=false`. `override_dh_auto_test` пуст, удалён каталог
  `debian/tests`, из `Build-Depends` удалены `xvfb`, `xauth`, `python3-gi`,
  `mesa-vulkan-drivers`.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

## Патчи

Два патча из Debian:
- `stylesheet-common-Use-disabled-opacity-for-disabled-pictu.patch` —
  использует непрозрачность для отключённых изображений.
- `#stylesheet-common-Use-opacity-for-all-disabled-gtk-images.patch` —
  закомментирован.

## Важные нюансы

### celluloid

celluloid 0.30 требует `libadwaita-1 >= 1.8.0`, а в Debian trixie доступна
лишь 1.7.6. Пакет `libadwaita-1-dev` из этого репозитория (версия 1.10.0)
удовлетворяет этому требованию.
