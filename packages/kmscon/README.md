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

## `libgbm-dev` берётся из этого репозитория

`libgbm-dev`, `libgbm1` и `mesa-libgallium` ставятся из нашей `mesa`
(см. `CLOSURE_EXCEPT` в `tools/gen-workflow.py` — исключений сейчас нет).
Раньше здесь было исключение: наша `mesa-common-dev` зависела от
`libgl-dev`, а тот объявляет `Breaks: mesa-common-dev`, из-за чего установка
`libegl-dev` (нужного этому пакету по `Build-Depends`) становилась
неразрешимой. Зависимость убрана — GL у нас не собирается, и заголовки GL
ничем не требуются. Подробности — в `packages/mesa/README.md`.
