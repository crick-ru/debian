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

## GL и GLES берутся из этого репозитория

`libegl-dev`, `libegl1`, `libgles-dev`, `libgles1`, `libgles2`, `libopengl-dev`,
`libopengl0`, `libglvnd0`, `libglvnd-core-dev` ставятся из нашей сборки
`libglvnd` (см. `packages/libglvnd/README.md`).

Раньше здесь было исключение для `libegl-dev`: штатный пакет нельзя поставить
рядом с нашей mesa — он тянет `libgl1-mesa-dev`, а тот пинит `libgbm1` версии
trixie. Теперь пин снят, и заодно сняты GL-зависимости, которые этому пакету
не нужны: у GLX и GL в нашем репозитории нет, а GLES и OpenGL-без-GLX
собраны без X11. Исключений в `CLOSURE_EXCEPT` сейчас нет.

