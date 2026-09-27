# sfwbar (crick Debian backports)

Сборка `sfwbar` 1.0~beta17 для Debian 13 (trixie): плавающая панель задач для
Wayland-композиторов.

## Включено

- Протоколы layer-shell и foreign-toplevel — панель работает со всеми
  композиторами, которые их поддерживают (Sway, Hyprland, labwc и др.).
- Собирается против `libgtk-3-dev` этого репозитория (стадия CI 3), поэтому в
  бинарь не попадают ссылки на `gdk_x11_*`, отсутствующие в публикуемой
  `libgtk-3.so.0`. Сам `sfwbar` X11-API GTK не использует вовсе.

## Отключено

- Man-страница не генерируется: шаг `rst2man` для `doc/*.rst` в
  `override_dh_auto_build` удалён, `python3-docutils` убран из
  `Build-Depends`. Готовых страниц в tar-боле нет, поэтому `man sfwbar` не
  документирован.
- X11 нигде не нужен: ветки X11 из исходников просто не активируются
  в Wayland-сессии, зависимостей от X11 в пакете не остаётся.

## Изменено

- Версия: `1.0~beta17-2+crick` (ревизия 2 — из-за переработки упаковки).
- Патчи `0001-docs-fix-typos.patch` и `0002-config-fix-typos.patch`: исправление
  опечаток в документации и примере конфигурации.
- Патч `0003-fix-replace-python-with-python3-in-embedded-scripts.patch`:
  встроенные python-скрипты вызывают `python3`, так как бинарник `python`
  в trixie больше не поставляется.
- `override_dh_install` дополнительно удаляет `usr/share/sfwbar/icons/weather/LICENSE`,
  которая не должна поставляться в пакете.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

