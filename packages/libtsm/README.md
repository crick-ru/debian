# libtsm (crick Debian backports)

Сборка `libtsm` 4.8.0 для Debian 13 (trixie): библиотека конечного автомата
терминала, на которой работает `kmscon`.

## Включено

- И разделяемая, и статическая библиотеки (см. патч ниже).

## Отключено

- Модульные тесты на базе `check(3)` не собираются и не запускаются:
  `-Dtests=false` выставлен безусловно (раньше его включал профиль `nocheck`),
  `check` убран из `Build-Depends`, каталог `debian/tests` (автотест
  `public-api` с отдельной сборочной копией тестов) удалён.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Версия: `4.8.0-2+crick` (ревизия 2 — из-за переработки упаковки).
- Патч `0001-tsm-meson.build-Change-library-build-to-both_libraries.patch`:
  собираются `both_libraries` вместо только разделяемой, чтобы статическая
  версия была доступна другим пакетам.
- `DPKG_GENSYMBOLS_CHECK_LEVEL := 4`: строгая проверка таблицы символов для `libtsm4`.
- Документация `libtsm-dev` связывается с документацией `libtsm4` через
  `dh_installdocs -plibtsm-dev --link-doc=libtsm4`.
- Усилены сборочные флаги: `DEB_BUILD_MAINT_OPTIONS := qa=+bug hardening=+all reproducible=+all`.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

