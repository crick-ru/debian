# libxkbcommon

Библиотека для работы с клавиатурными описаниями XKB (`libxrandr`, `xkbcli`).

## Источник упаковки

Упаковка взята из Debian (`libxkbcommon_1.13.1-1`, ветка unstable) и
переработана. Tarball побайтово совпадает с Debian-овским
`libxkbcommon_1.13.1.orig.tar.gz`.

## Версии

- **В trixie:** 1.7.0-2
- **В исходной упаковке:** 1.13.2-2
- **В нашем репозитории:** 1.13.2-3+crick (ревизия 3)

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libxkbcommon0` | `libxkbcommon.so.0` |
| `libxkbcommon-dev` | заголовки, `xkbcommon.pc`, `libxcbcommon.so` |
|   `libxkbcommon-tools` | `xkbcli` (Wayland-подкоманды) — включает `xkbcli info`, который требует `xkeyboard-config` для определения макросов путей расширений XKB (в 1.13.2 `tools/info.c` использует `DFLT_XKB_CONFIG_UNVERSIONED_EXTENSIONS_PATH` без `#ifdef`). |
| `libxkbregistry0` | `libxkbregistry.so.0` — запрос RMLVO |
| `libxkbregistry-dev` | заголовки, `xkbregistry.pc` |

Не публикуются: `libxkbcommon-x11-0`, `libxkbcommon-x11-dev` (X11-часть),
`libxkbcommon-doc` (документация).

`libxkbcommon0-udeb` — для установщика Debian, в репозиторий не попадает
(`scripts/build-package.sh` собирает только `*.deb`).

## Что изменено

### Отключено

- **Вся X11-часть:** `-Denable-x11=false`. Не собирается `libxkbcommon-x11.so.0`
  (символы `xkb_x11_*`), `xkbcommon-x11.h`, `xkbcommon-x11.pc`,
  `xkbcli-dump-keymap-x11`, `xkbcli-interactive-x11`. Из `Build-Depends`
  удалены `libxcb-xkb-dev`, `x11-xkb-utils`, `x11proto-dev`.
- **Документация:** `-Denable-docs=false`. Из `Build-Depends` удалены `doxygen`,
  `graphviz`.
- **Тесты:** удалён каталог `debian/tests`, из `Build-Depends` удалены `xvfb`,
  `xkb-data <!nocheck>`. `override_dh_auto_test` пуст.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

## Патчи

## Патчы

- `xkbcli-info-guard-extensions-macros.patch` — оборачивает макросы
  `DFLT_XKB_CONFIG_UNVERSIONED_EXTENSIONS_PATH` и
  `DFLT_XKB_CONFIG_VERSIONED_EXTENSIONS_PATH` в `#ifdef` в `tools/info.c`.
  На системах без `xkeyboard-config` pkg-config эти макросы не определяются,
  и компиляция падает — аналогичные `#ifdef` guards уже есть в `src/context.c`
  и `src/registry.c`.

## Изменения ABI

SONAME прежний (`libxcbcommon.so.0`), файл меняется с `libxcbcommon.so.0.7.0`
на `libxcbcommon.so.0.13.1`. Добавлены только новые символы и макросы
(включая API построения keymap 2-го поколения), удалённых нет. Зависимость
от `xkb-data` не меняется.

## Важные нюансы

### apt upgrade: снимаемый пакет

Штатный `libxkbcommon-x11-0` из trixie пинит `libxkbcommon0 (= 1.7.0-2)`.
Поскольку у нас нет пакета `libxkbcommon-x11-0` — нашей сборки он не заменяет —
`apt upgrade` снимет его вместе со всеми обратными зависимостями:

- `libgstreamer-plugins-bad1.0-0` (наш `gstreamer1.0-plugins-bad 1.28.7`
  собран с `-Dx11=disabled`, поэтому не зависит от него);
- Qt: `libqt5gui5t64`, `libqt6gui6`, `kwin-x11`, `plasma`-компоненты;
- `alacritty`, `rofi`, `kitty`, `i3`, `i3lock`, `awesome`, `lxqt-panel`,
  `fcitx5-modules`, `libmutter-16-0`, `mesa-utils-bin`, `libmagpie-0-0`,
  `libevas1-engines-wayland`.

Проверка:
```
apt-get -s upgrade | grep -E '^(Remv|The following.*be REMOVED)'
apt-cache rdepends libxkbcommon-x11-0
```

### man-страницы xkbcli

Готовые man-страницы `xkbcli` из trixie приходят в tar-боле и просто
устанавливаются — ничего не собирается.

### Секция

`Section: x11` в `debian/control` оставлена: это разметка исходного пакета
Debian (xkbcommon — проект xorg-team), сами бинарные пакеты X11 не содержат.
