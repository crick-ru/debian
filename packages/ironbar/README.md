# ironbar

Customisable GTK4 Layer Shell bar for Wayland compositors, written in Rust.

## Источник упаковки

**Упаковка написана с нуля** для этого репозитория: `ironbar` отсутствует в
Debian (ни в trixie, ни в sid — проверено по `Sources` на
`sources.debian.org`). Нет ни исходного, ни двоичного пакета для переработки.

Tarball взят из GitHub release v0.19.1 (git tag). Исходный код идентичен
апстриму.

## Версии

- **В trixie:** (пакет не существует)
- **В исходной упаковке:** (написано с нуля)
- **В нашем репозитории:** 0.19.1-1+crick (ревизия 1)

## Содержимое

| Пакет | Содержимое |
|---|---|
| `ironbar` | `usr/bin/ironbar`, systemd user unit `usr/lib/systemd/user/ironbar.service` |

Один бинарный пакет.

## Что изменено

### Отключено

- **Тесты:** `override_dh_auto_test` пуст, каталог `debian/tests` не создан.
  Сборка не запускает cargo-тесты.
- **Документация:** документация не собирается, man-страниц нет, пакетов
  `*-doc` не публикуется.
- **X11:** приложение GTK4 Layer Shell для Wayland, X11 не используется ни при
  сборке, ни в runtime. Сборка идёт против GTK 4 этого репозитория.
- **Диски/DVB/VDPAU/JACK/libcaca/libaa1/at-spi2-core:** не используются,
  отсутствуют в `Build-Depends` и `Depends`.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- GTK4 (`libgtk-4-dev`) и GTK Layer Shell (`libgtk4-layer-shell-dev`) —
  штатные зависимости апстрима.
- Дополнительные библиотеки сборки: `libdbus-1-dev`, `libgit2-dev`,
  `libinput-dev`, `libluajit-5.1-dev`, `libpulse-dev`, `libssl-dev`,
  `pkgconf`.
- Инструментарий Rust: `rustc`, `cargo`, `dh-cargo`.
- systemd user unit `ironbar.service` — устанавливается из исходников
  апстрима.
- Release-сборка (`cargo build --release --locked`).

## Патчи

Нет. Упаковка применяется как есть.

## Изменения ABI

Приложение, а не библиотека. Нет символьных файлов.

## Важные нюансы

### Требования к сети при сборке

**Сборка ходит в сеть.** `cargo build` скачивает crate-ы с crates.io, а
исходники crate-ов в tar-боле не поставляются, поэтому офлайн-сборка
невозможна. Версии зафиксированы в `Cargo.lock` из тарболла, результат
воспроизводим по составу.

### GTK-версия

Апстрим требует GTK ≥ 4.20. Пакет собирается против GTK 4 этого репозитория
(4.22.x), а не против trixie (4.12), поэтому `ironbar` ставится на стадию CI
позже `gtk4`.
