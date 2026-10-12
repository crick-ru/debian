# wayland-protocols

Набор XML-файлов протоколов Wayland, расширяющих core-протокол.

## Источник упаковки

Упаковка взята из Debian (`wayland-protocols_1.47-1~bpo13+1`,
trixie-backports) и переработана. Tarball побайтово совпадает с
официальным релизом GitLab: `wayland-protocols_1.47.orig.tar.xz`.

Взято из `trixie-backports`, а не из `unstable`: нужная версия 1.47 уже
загружена туда, а в sid её ещё нет.

## Версии

- **В trixie:** 1.44-1
- **В исходной упаковке:** 1.47-1~bpo13+1
- **В нашем репозитории:** 1.47-2+crick (ревизия 2)

## Содержимое

| Пакет | Содержимое |
|---|---|
| `wayland-protocols` | XML-файлы протоколов (`/usr/share/wayland-protocols/`) |

Один пакет, архитектура `all`, `Multi-Arch: foreign`. Используется только
во время сборки — не выполняется runtime-зависимостями.

## Что изменено

### Отключено

- **Тесты:** `override_dh_auto_test` пуст, каталог `debian/tests` удалён.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

## Патчи

Нет: `debian/patches/series` отсутствует.

## Изменения ABI

Пакет состоит только из данных (XML-файлов) и используется только при сборке:
работающие программы от него не зависят. Обновление безопасно — в 1.47
добавлены новые и обновлены существующие протоколы.

## Важные нюансы

### Зачем нужен

`wlroots 0.20.2` требует `wayland-protocols >= 1.47` для color-management-v1
версии 2 (`send_ready2`, `send_preferred_changed2`,
`TRANSFER_FUNCTION_COMPOUND_POWER_2_4`, `ERROR_CHROMA_LOCATION`).
В trixie только 1.44 — сборка падала бы.
