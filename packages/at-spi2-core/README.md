# at-spi2-core

ATK Bridge и D-Bus ядро GNOME Accessibility (библиотеки `libatspi.so.0`,
`libatk-bridge2.0.so.0`, `libatk1.0.so.0`, `libatk-adaptor`).

## Источник упаковки

Упаковка взята из Debian (`at-spi2-core_2.56.2-1+deb13u2`, ветка trixie) и
переработана под правила репозитория. Tarball побайтово совпадает с
Debian-овским `at-spi2-core_2.56.2.orig.tar.xz`.

## Версии

- **В trixie:** 2.56.2-1+deb13u2
- **В исходной упаковке:** 2.56.2-1+deb13u2
- **В нашем репозитории:** 2.56.2-2+crick

Версия взята из trixie, а не из более свежей ветки unstable, чтобы не
пересматривать quilt-патчи — задача пакета (доступность без X11) от версии
не зависит.

## Содержимое

- `at-spi2-core` — демоны accessibility bus и registry
- `at-spi2-common` — общие ресурсы
- `libatspi2.0-0t64` — общая библиотека
- `libatspi2.0-dev` — dev-файлы + `gir1.2-atspi-2.0`
- `libatk1.0-0t64` / `libatk1.0-dev` — ATK (`gir1.2-atk-1.0`)
- `libatk-bridge2.0-0t64` / `libatk-bridge2.0-dev` — ATK Bridge
- `libatk-adaptor` — мост ATK ↔ D-Bus

## Что изменено

### Отключено

- **X11** (правило репозитория): `-Dx11=disabled`. В `meson.build` не
  выполняется блок `if x11_dep.found()`, поэтому `atspi-device-x11.c` не
  компилируется, `x11_deps` остаётся пустым и `libatspi.so.0` не линкуется с
  `libX11`/`libXi`/`libXtst`. Весь X11-код заключён в `#ifdef HAVE_X11`. Из
  `Build-Depends` убраны все X11-библиотеки.
- **X11-сессия:** из `libatk-adaptor.install` и `at-spi2-core.install` убраны
  строки `etc/X11/Xsession.d/90atk-adaptor` и `etc/X11/Xsession.d/90qt-a11y` —
  это запуск из X11-сессии, которой на чистом Wayland нет. Автозапск в Wayland
  обеспечивает `etc/xdg/Xwayland-session.d/00-at-spi`.
- **Тесты:** `override_dh_auto_test` пуст, `xvfb`/`xauth` не в `Build-Depends`.
- **Документация:** `-Ddocs=false`, пакеты `at-spi2-doc` и `libatk1.0-doc`
  удалены из `debian/control`.
- **udeb:** пять udeb-пакетов не собираются (Debian Installer, а не обычная
  система). Из `debian/rules` убраны все `--add-udeb`.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- GObject introspection (`gir1.2-atspi-2.0`, `gir1.2-atk-1.0`)
- `dbus-broker` в качестве `default_bus`

## Патчи

Четыре quilt-патча из упаковки Debian применяются без изменений:
`at-spi-by_default`, `workaround_tests_issue.patch`, `keyboard-group`,
`debian-atkversion-c-linkage.patch`.

## Изменения ABI

SONAME `libatspi.so.0` не меняется. Отключение X11 не добавляет и не убирает
символов — X11-код заключён в `#ifdef HAVE_X11`, который не определяется.
Символьные файлы Debian оставлены как есть.

## Важные нюансы

Обратная совместимость сохранена: `at-spi2-core` из trixie линкуется с
`libX11`, поэтому `yandex-browser-stable` (который требует этот пакет) работает
только против нашей сборки. Пакет `libatk-bridge2.0-0t64` при этом можно
установить рядом с trixie-версией: имена пакетов совпадают, а версии
различаются (`+crick` новее).
