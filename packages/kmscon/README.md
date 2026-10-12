# kmscon

Эмулятор терминала для DRM/KMS-консоли Linux без X11-сервера
(`kmscon` + системный юнит `kmsconvt@`).

## Источник упаковки

Упаковка взята из Debian (`kmscon_10.0.3-1`, ветка unstable) и переработана.
Tarball побайтово совпадает с Debian-овским `kmscon_10.0.3.orig.tar.xz`.

## Версии

- **В trixie:** 10.0.3-1
- **В исходной упаковке:** 10.0.3-1
- **В нашем репозитории:** 10.0.3-2+crick (ревизия 2 — из-за переработки)

## Содержимое

- `kmscon` — единственный бинарный пакет: эмулятор + юнит `kmsconvt@`.

## Что изменено

### Отключено

- **Документация и man-страницы:** `-Ddocs=disabled`. Убраны `docbook-xml`,
  `docbook-xsl`, `xsltproc`, файл `kmscon.docs`, строки из `kmscon.install`
  и `kmscon.manpages`. Остаётся только `kmscon-launch-gui.1` (написана руками).
- **Тесты:** `-Dtests=false` (опция по умолчанию `true` в апструпе, включает
  зависимость `check`). `override_dh_auto_test` пуст, `check` убран из
  `Build-Depends`.
- **X11:** `kmscon` не использует X11 и не заявляет его в зависимостях.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- Все штатные возможности autotools (`-Dauto-features=enabled`).
- Служба `kmsconvt@` (переключение виртуальных терминалов).

## Патчи

Два патча из Debian:

1. `0001-Change-kmsconvt-.service-to-match-getty-.service.patch` — переименовывает
   `kmsconvt@.service` в точное соответствие системному `getty.service`.
2. `0002-Do-not-use-git-describe-to-generate-version.patch` — убирает
   `git describe` из meson (в релизном архиве нет `.git`).

## Важные нюансы

- `dh_auto_install --destdir=debian/tmp` — стандартная схема для разделения файлов.
- `DEB_CFLAGS_MAINT_APPEND := -Wno-error=array-bounds` — глушит ложное
  срабатывание GCC в заголовках `libtsm`.
- `SYSTEMD_SYSTEM_UNIT_DIR` запрашивается через `pkg-config systemd` вместо
  жёстко прописанного пути.
- GL и GLES берутся из этого репозитория (`libglvnd`, см.
  `packages/libglvnd/README.md`).
- `libtsm-dev (>= 4.6.0)` берётся из этого репозитория.
