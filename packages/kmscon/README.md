# kmscon (crick Debian backports)

Сборка `kmscon` 10.0.3 для Debian 13 (trixie): эмулятор терминала, работающий
напрямую на DRM/KMS-консоли Linux без X11-сервера.

## Включено

- Все штатные возможности autotools: `--auto-features=enabled`.
- Служба переключения виртуальных терминалов `kmsconvt@`, поставляемая вместе
  с эмулятором.

## Отключено

- Документация и страницы man не собираются (`-Ddocs=disabled` выставлен
  безусловно, раньше его включал профиль `nodoc`), поэтому убраны
  `docbook-xml`, `docbook-xsl`, `xsltproc`, файл `kmscon.docs`, строки
  `usr/share/man/man1/kmscon.1` и `usr/share/man/man5/kmscon.conf.5` из
  `kmscon.manpages` и строка `usr/share/man/man5/kmscon.conf.5` из
  `kmscon.install`. В поставке остаётся только `kmscon-launch-gui.1` — она
  написана руками в `debian/man`, а не генерируется.
- `-Dwerror=false`: предупреждения новых версий GCC не должны валить сборку.
- Набор тестов не собирается и не запускается: в `debian/rules` выставлено
  `-Dtests=false` (в апстриме опция по умолчанию `true`, и именно она включает
  зависимость `check`), `override_dh_auto_test` пуст (тесты интерактивные и
  требуют root), `check` убран из `Build-Depends`.
- X11 не используется и не заявлен в зависимостях.

## Изменено

- Версия: `10.0.3-2+crick` (ревизия 2 — из-за переработки упаковки).
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

## Исключение из правила «свои зависимости из своего репозитория»

`libgbm-dev` берётся из trixie, а не из нашей `mesa`. Причина: этот пакет
требует `libegl1-mesa-dev`, которого наша `mesa` не публикует (в `README`
mesa перечислено, что не собирается). Штатный `libegl-dev` тянет `libx11-dev`,
то есть X11, и конфликтует с нашей `mesa-libgallium` версии 26.1.6. Поэтому
подстановка нашей `mesa` здесь технически невозможна, а не просто неудобна.

Замена на собственную сборку станет возможна, когда репозиторий начнёт
публиковать `libegl1-mesa-dev` (или иной пакет с теми же заголовками EGL).
Обходного пути, который обошёл бы это ограничение, здесь нет: понизить
требование в `debian/control` нельзя (правило о версиях).
