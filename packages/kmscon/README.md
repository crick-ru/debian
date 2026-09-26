# kmscon (crick Debian backports)

Сборка `kmscon` 10.0.3 для Debian 13 (trixie): эмулятор терминала, работающий
напрямую на DRM/KMS-консоли Linux без X11-сервера.

## Включено

- Все штатные возможности autotools: `--auto-features=enabled`.
- Документация и страницы man (docbook). Отключаются автоматически при профиле
  сборки `nodoc` (`-Ddocs=disabled`).
- Служба переключения виртуальных терминалов `kmsconvt@`, поставляемая вместе
  с эмулятором.

## Отключено

- `-Dwerror=false`: предупреждения новых версий GCC не должны валить сборку.
- Набор тестов (`override_dh_auto_test` пуст): тесты интерактивные и требуют
  root, поэтому при сборке пакета не запускаются.
- X11 не используется и не заявлен в зависимостях.

## Изменено

- Установка этапа сборки идёт в `debian/tmp` (`dh_auto_install --destdir=debian/tmp`),
  как в upstream-пакете для разделения файлов.
- `DEB_CFLAGS_MAINT_APPEND := -Wno-error=array-bounds` глушит ложное срабатывание
  компилятора в заголовках `libtsm`.
- `SYSTEMD_SYSTEM_UNIT_DIR` запрашивается через `pkg-config systemd` вместо
  жёстко прописанного пути, поэтому юниты попадают в верный каталог на trixie.
- Патч `0001-Change-kmsconvt-.service-to-match-getty-.service.patch` переименовывает
  `kmsconvt@.service` в точное соответствие системному `getty.service`.
- Патч `0002-Do-not-use-git-describe-to-generate-version.patch` убирает вызов
  `git describe` из meson (в релизном архиве нет каталога `.git`).
- `debian/kmscon.install` использует `dh-exec`, поэтому файл обязан быть
  исполняемым (бит `+x`) — иначе `dh_install` сам разбирает строку `=>` и
  падает с `Cannot find (any matches for) "=>"`.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

