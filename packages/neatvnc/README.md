# neatvnc

Библиотека VNC-сервера: `libneatvnc.so.1`.

## Источник упаковки

Упаковка взята из Debian (`neatvnc_1.0.1+dfsg-1`, ветка unstable) и
перерабатывается. Tarball побайтово совпадает с Debian-овским
`neatvnc_1.0.1+dfsg.orig.tar.xz` (Debian перепаковывает как `+dfsg`, версия
с сохраняет суффикс).

## Версии

- **В trixie:** 0.9.1+dfsg-1 (`libneatvnc0`)
- **В исходной упаковке:** 1.0.1+dfsg-1
- **В нашем репозитории:** 1.0.1+dfsg-1+crick (ревизия 1)

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libneatvnc1` | `libneatvnc.so.1` |
| `libneatvnc-dev` | заголовки, `libneatvnc.so`, `neatvnc.pc` |

Набор закрытый: `libneatvnc-dev` требует ровно `libneatvnc1 (= ${binary:Version})`.

## Что изменено

### Отключено

- **Тесты:** `-Dtests=false` (Debian использует `-Dtests=true` и `meson test`).
  `override_dh_auto_test` пуст. Из `Build-Depends` удалены `openssl <!nocheck>`,
  `dbus-daemon`, `pipewire` (были нужны ровно для тестов).
- **Документация и примеры:** README не ставится в `/usr/share/doc`, примеры
  не публикуются.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

## Патчи

Нет: `debian/patches/series` отсутствует.

## Изменения ABI

`libneatvnc.so.1` — SONAME не меняется, файл меняется с `libneatvnc.so.0.9.1`
на `libneatvnc.so.1.0.1`. Удалённых символов нет.

## Важные нюансы

### Зачем нужен

`wayvnc 0.10.1` требует `libneatvnc-dev (>= 1.0.0)`, а в trixie только 0.9.1
(упаковка `libneatvnc0`). `libneatvnc0` и `libneatvnc1` — разные имена пакетов,
поэтому оба могут быть установлены одновременно, но `wayvnc 0.10.1` требует
именно `libneatvnc1`.

### Стадия сборки

`neatvnc` собирается в стадии 3 CI: против нашего FFmpeg (`libavcodec-dev`,
`libavfilter-dev`, `libavutil-dev`) и нашей mesa (`libgbm-dev`). Оба
собираются раньше.

### apt upgrade

Штатный `libneatvnc0` остаётся установленным (другое имя пакета). `libaml0t64`
из trixie тоже остаётся. Их заменят `libneatvnc1` и `libaml1` от нашей сборки.
Очистить: `apt autoremove`.

Штатный `wayvnc 0.9.1` из trixie продолжает работать — он линкуется к
`libneatvnc.so.1` любой версии, а SONAME не менялся.
