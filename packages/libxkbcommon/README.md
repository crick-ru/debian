# libxkbcommon (crick Debian backports)

Сборка `libxkbcommon` 1.13.1 для Debian 13 (trixie, amd64). Упаковка взята
из Debian (`libxkbcommon_1.13.1-1`).

## Зачем нужна более свежая версия

`wlroots` 0.20.2 требует в meson libxkbcommon не ниже 1.8 и использует
константы имён индикаторов, которых нет в libxkbcommon 1.7.0 из trixie:
`XKB_LED_NAME_COMPOSE` и `XKB_LED_NAME_KANA`
(`types/wlr_keyboard.c`, список имён LED). В meson 1.7.0 объявлены только
`XKB_LED_NAME_CAPS`, `XKB_LED_NAME_NUM` и `XKB_LED_NAME_SCROLL`.

## Включено

- Все бинарные пакеты упаковки Debian: `libxkbcommon0`,
  `libxkbcommon-dev`, `libxkbcommon-x11-0`, `libxkbcommon-x11-dev`,
  `libxkbcommon-tools` (`xkbcli`), `libxkbcommon-doc`, `libxkbregistry0`,
  `libxkbregistry-dev`. Набор закрытый: `-dev`-пакеты требуют ровно эти
  версии.

## Отключено

- `libxkbcommon0-udeb` — минимальный пакет для установщика Debian, в
  репозиторий не попадает (`scripts/build-package.sh` собирает только
  `*.deb`).
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Версия: `1.13.1-1+crick` (новее штатной 1.7.0-2). У Debian есть и официальный
  бэкпорт `1.13.1-1~bpo13+1` в `trixie-backports`, но здесь версия
  публикуется вместе с остальными библиотеками wlroots из одного места.
- `Maintainer`: нейтральная идентичность проекта.
- Формат исходников `3.0 (quilt)`; собственных патчей у пакета нет.
- Свои тесты упаковки Debian (в том числе X11-тесты) выполняются в CI, для
  них в `Build-Depends` есть `xvfb`.

## Влияние на другие пакеты

SONAME прежний (`libxkbcommon.so.0`, `libxkbcommon-x11.so.0`), файл меняется
с `libxkbcommon.so.0.7.0` на `libxkbcommon.so.0.13.1`; из нового добавлены
только символы и макросы (в том числе API построения keymap 2-го поколения),
удалённых нет. Зависимость от `xkb-data` остаётся без изменений, поэтому
GTK, Qt и оконные менеджеры продолжают работать без пересборки.

## Откат

```
sudo apt install libxkbcommon0=1.7.0-2 libxkbcommon-dev=1.7.0-2
```

При `Pin-Priority: 1001` следующий `apt upgrade` вернёт версии из этого
репозитория; `wlroots` после отката установить нельзя.
