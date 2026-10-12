# wayland

Протокол и библиотека дисплейного сервера Wayland: клиент, сервер, курсоры, EGL.

## Источник упаковки

Упаковка взята из Debian (`wayland_1.26.0-1`, ветка unstable) и переработана.
Tarball побайтово совпадает с официальным релизом GitLab:
`wayland_1.26.0.orig.tar.xz`.

## Версии

- **В trixie:** 1.23.1-3
- **В исходной упаковке:** 1.26.0-1
- **В нашем репозитории:** 1.26.0-2+crick (ревизия 2)

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libwayland-client0` | `libwayland-client.so.0` |
| `libwayland-server0` | `libwayland-server.so.0` |
| `libwayland-cursor0` | `libwayland-cursor.so.0` |
| `libwayland-egl1` | `libwayland-egl.so.1` |
| `libwayland-egl-backend-dev` | EGL backend заголовки |
| `libwayland-dev` | заголовки, `.pc`, `wayland-scanner` |
| `libwayland-bin` | `wayland-scanner` (утилита) |

Не публикуется: `libwayland-doc` (документация).

## Что изменено

### Отключено

- **Документация и man-страницы:** `-Ddocumentation=false`. Эта опция
  покрывает и man3-страницы (они генерируются вместе с API-документацией),
  и Doxygen-документацию. Из `Build-Depends` удалены весь `Build-Depends-Indep`
  (doxygen, graphviz, xmlto, xsltproc, mdbook) и `libwayland-doc.install`.
  Строки `usr/share/man/man3` удалены из `libwayland-dev.install`.
- **Тесты:** `-Dtests=false`. Каталог `debian/tests` удалён.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

## Патчи

Нет: `debian/patches/series` отсутствует.

## Изменения ABI

Все SONAME сохранены: `libwayland-client.so.0`, `libwayland-server.so.0`,
`libwayland-cursor.so.0`, `libwayland-egl.so.1`. Файлы меняются с
`…so.0.23.1` на `…so.0.26.0`. Добавлены только новые символы, удалённых
нет. Зависимость от `xkb-data` не меняется (она в `libxkbcommon0`). GTK, Qt,
Electron и прочие Wayland-клиенты работают без пересборки.

Набор `libwayland-dev` закрытый: `libwayland-dev` требует ровно эти версии.

## Важные нюансы

### Зачем нужен

`wlroots 0.20.2` требует `libwayland-dev >= 1.24.0` для
`wl_resource_get_interface()` и `wl_resource_post_error_vargs()` — функций,
которых в wayland 1.23.1 (trixie) нет. GTK 4.22.5 требует
`libwayland-dev (wayland-protocols) >= 1.41` и `libegl-dev` из этого репозитория.
