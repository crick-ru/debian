# sfwbar (crick Debian backports)

Сборка `sfwbar` 1.0~beta17 для Debian 13 (trixie): плавающая панель задач для
Wayland-композиторов.

## Включено

- Протоколы layer-shell и foreign-toplevel — панель работает со всеми
  композиторами, которые их поддерживают (Sway, Hyprland, labwc и др.).
- Страницы man генерируются на этапе сборки: `override_dh_auto_build` вызывает
  `rst2man` для `doc/*.rst`, предварительно сгенерированные страницы из
  апстрима не используются.

## Отключено

- Ничего явно не отключалось: ветки X11 из исходников просто не активируются
  в Wayland-сессии, зависимостей от X11 в пакете не остаётся.

## Изменено

- Патчи `0001-docs-fix-typos.patch` и `0002-config-fix-typos.patch`: исправление
  опечаток в документации и примере конфигурации.
- Патч `0003-fix-replace-python-with-python3-in-embedded-scripts.patch`:
  встроенные python-скрипты вызывают `python3`, так как бинарник `python`
  в trixie больше не поставляется.
- `override_dh_install` дополнительно удаляет `usr/share/sfwbar/icons/weather/LICENSE`,
  которая не должна поставляться в пакете.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

