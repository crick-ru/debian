# libtsm

TSM — конечный автомат для эмуляции терминалов, совместимых с DEC VT100-VT520
(`libtsm.so.4`).

## Источник упаковки

Упаковка взята из Debian (`libtsm_4.7.1-0.1`, ветка 4.7) и переработана.
Tarball побайтово совпадает с Debian-овским `libtsm_4.7.1.orig.tar.gz`.

## Версии

- **В trixie:** 4.7.1-0.1
- **В исходной упаковке:** 4.7.1-0.1
- **В нашем репозитории:** 4.8.0-2+crick (ревизия 2 — апгрейд версии)

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libtsm4` | `libtsm.so.4` — runtime |
| `libtsm-dev` | заголовки, `libtsm.pc`, `libtsm.so` |

Набор закрытый: `libtsm-dev` требует ровно `libtsm4 (= ${binary:Version})`.

## Что изменено

### Отключено

- **Тесты:** `-Dtests=false`. Убран `check` из `Build-Depends`, удалён
  каталог `debian/tests` (автотест `public-api` с отдельной сборочной копией
  тестов). `override_dh_auto_test` пуст.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- **Разделяемая и статическая библиотеки:** собираются обе (`both_libraries`
  вместо только разделяемой) — статическая версия доступна другим пакетам.

## Патчи

Один патч Debian сохранён как есть:
`0001-tsm-meson.build-Change-library-build-to-both_libraries.patch` —
переключает сборку с `shared_library` на `both_libraries`.

## Изменения ABI

SONAME не меняется (`libtsm.so.4`), файл меняется с `libtsm.so.4.7.1` на
`libtsm.so.4.8.0`. Удалённых публичных символов нет — `libtsm4.symbols`
перегенерирован (строгая проверка `DPKG_GENSYMBOLS_CHECK_LEVEL := 4`).

## Важные нюансы

### Зачем нужен

`libtsm` — сборочная зависимость `kmscon` (консольный оконный менеджер).
`kmscon` требует `libtsm-dev >= 3.0.0` для `libtsm.so.4`.

### Сборочные флаги

`DEB_BUILD_MAINT_OPTIONS := qa=+bug hardening=+all reproducible=+all` —
усиленные флаги безопасности и воспроизводимость сборки.

### apt upgrade

trixie версия 4.7.1 → наша 4.8.0. `libtsm4` меняется, `libtsm-dev` пинит
ровно эту версию.
