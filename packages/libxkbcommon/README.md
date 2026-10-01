# libxkbcommon (crick Debian backports)

Сборка `libxkbcommon` 1.13.1 для Debian 13 (trixie, amd64) **без X11**.
Упаковка взята из Debian (`libxkbcommon_1.13.1-1`) и переработана.

## Включено

- `libxkbcommon0`, `libxkbcommon-dev`, `libxkbcommon-tools` (`xkbcli`),
  `libxkbregistry0`, `libxkbregistry-dev`. Набор закрытый: `-dev`-пакеты
  требуют ровно эти версии.
- Готовые man-страницы `xkbcli`: в апстриме они приходят готовыми в тарболе и
  просто устанавливаются, ничего не собирается.

## Отключено

- **Вся X11-часть: `-Denable-x11=false`.** Не собирается
  `libxkbcommon-x11.so.0` (символы `xkb_x11_*`), не устанавливаются
  `xkbcommon-x11.h` и `xkbcommon-x11.pc`, не собираются
  `xkbcli-dump-keymap-x11` и `xkbcli-interactive-x11`. Пакеты
  `libxkbcommon-x11-0` и `libxkbcommon-x11-dev` не публикуются, из
  `Build-Depends` убраны `libxcb-xkb-dev`, `x11-xkb-utils`, `x11proto-dev`.
  Исключение «X11 не трогаем ради libxkb», которое действовало в репозитории
  до 2026 года, снято: X11-библиотек в репозитории не осталось совсем.
- `libxkbcommon-doc` — документация не собирается
  (`-Denable-docs=false`), `doxygen` и `graphviz` убраны из `Build-Depends`.
- Тесты не собираются и не запускаются: каталог `debian/tests` удалён, из
  `Build-Depends` убраны `xvfb` и `xkb-data <!nocheck>`.
- `libxkbcommon0-udeb` — минимальный пакет для установщика Debian, в
  репозиторий не попадает (`scripts/build-package.sh` собирает только
  `*.deb`).
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Версия: `1.13.1-2+crick` (новее штатной 1.7.0-2). У Debian есть и официальный
  бэкпорт `1.13.1-1~bpo13+1` в `trixie-backports`, но здесь версия
  публикуется вместе с остальными библиотеками wlroots из одного места.
  Ревизия 2 — из-за переработки упаковки (по правилам проекта).
- Формат исходников `3.0 (quilt)`; собственных патчей у пакета нет.
- `Section: x11` в исходнике оставлен: это разметка исходного пакета Debian
  (xkbcommon — проект xorg-team), сами бинарные пакеты X11 не содержат.

## Влияние на другие пакеты

`libxkbcommon.so.0` — SONAME прежний, файл меняется с `libxkbcommon.so.0.7.0`
на `libxkbcommon.so.0.13.1`; из нового добавлены только символы и макросы (в
том числе API построения keymap 2-го поколения), удалённых нет. Зависимость от
`xkb-data` не меняется, поэтому GTK, Qt и оконные менеджеры продолжают
работать без пересборки.

**Но исчезает `libxkbcommon-x11-0`, и это видно на живой системе.** Штатный
`libxkbcommon-x11-0` 1.7.0-2 жёстко пинит `libxkbcommon0 (= 1.7.0-2)`, а
замены у него в этом репозитории больше нет, поэтому `apt upgrade` его снимет.
Всё, что от него зависит, тоже будет снято, а среди этих пакетов:

- `libgstreamer-plugins-bad1.0-0` (а с ним `totem`, `shotwell` и прочие
  потребители gstreamer-bad);
- Qt: `libqt5gui5t64`, `libqt6gui6`, `kwin-x11`, `plasma`-компоненты;
- `alacritty`, `rofi`, `kitty`, `i3`, `i3lock`, `awesome`, `lxqt-panel`,
  `fcitx5-modules`, `libmutter-16-0` (то есть GNOME Shell), `mesa-utils-bin`,
  `libmagpie-0-0`, `libevas1-engines-wayland`.

Проверить, что сломается на конкретной машине:

```
apt-get -s upgrade | grep -E '^(Remv|The following.*be REMOVED)'
apt-cache rdepends libxkbcommon-x11-0
```

`libgstreamer-plugins-bad1.0-0` в этом репозитории публикуется собственный
(`gstreamer1.0-plugins-bad` 1.28.7), и он собран с `-Dx11=disabled`, то есть
не зависит ни от `libxkbcommon-x11-0`, ни от `libxkbcommon0` — в GStreamer
1.28.7 `libxkbcommon` встречается только в плагине `wpe` и в окне XCB
плагина `vulkan`, а оба выключены. Поэтому штатный пакет trixie будет снят
и заменён нашим, а не останется конфликтующим пинном. Подробности — в
`packages/gstreamer1.0-plugins-bad/README.md`.

## Откат

```
sudo apt install libxkbcommon0=1.7.0-2 libxkbcommon-dev=1.7.0-2 \
                 libxkbcommon-x11-0=1.7.0-2 libxkbcommon-x11-dev=1.7.0-2
```

При `Pin-Priority: 1001` следующий `apt upgrade` вернёт версии из этого
репозитория; `wlroots` после отката установить нельзя.
