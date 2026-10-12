# libdrm

Пользовательский интерфейс к ядру DRM-сервисам Linux (Direct Rendering Manager).

## Источник упаковки

Упаковка взята из Debian (`libdrm_2.4.134-3`, ветка unstable) и переработана.
Tarball побайтово совпадает с Debian-овским `libdrm_2.4.134.orig.tar.xz`.

## Версии

- **В trixie:** 2.4.124-2
- **В исходной упаковке:** 2.4.134-3
- **В нашем репозитории:** 2.4.134-2+crick (ревизия 2 — из-за переработки)

## Содержимое

На amd64 публикуются: `libdrm2`, `libdrm-common`, `libdrm-dev`,
`libdrm-amdgpu1`, `libdrm-freedreno1`, `libdrm-intel1`, `libdrm-nouveau2`,
`libdrm-radeon1`.

Набор закрытый: `libdrm-dev` требует ровно эти версии
(`= ${binary:Version}`).

## Что изменено

### Отключено

- **Тестовые программы:** `-Dinstall-test-programs=false`. Файл
  `libdrm-tests.install` удалён. Тестовая сборочная система не запускается:
  `override_dh_auto_test` пуст.
- **Man-страницы:** `-Dman-pages=disabled`. Убран `python3-docutils`
  (для `rst2man`) и строки `usr/share/man` из `libdrm-dev.install`.
- **X11:** `libx11-dev` убран из `Build-Depends` — в libdrm он был только
  ради тестовых программ.
- Пакеты для arm-архитектур (`libdrm-omap1`, `libdrm-exynos1`,
  `libdrm-tegra0`, `libdrm-etnaviv1`) на amd64 не собираются — ограничены
  в `debian/control`.
- `libdrm2-udeb` (для debian-installer) не попадает в репозиторий:
  `scripts/build-package.sh` собирает в пул только `*.deb`.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- `--default_library=both` (shared + static)
- Все драйверы для amd64, как в Debian

## Патчи

Один патч Debian: `01_default_perms.diff` (установка прав по умолчанию).

## Изменения ABI

SONAME всех библиотек прежние: `libdrm.so.2`, `libdrm_amdgpu.so.1`,
`libdrm_intel.so.1`, `libdrm_nouveau.so.2`, `libdrm_radeon.so.1`.
Добавлено новых символов, удалённых нет. Mesa, Wayland и X-стек
продолжают работать без пересборки.

## Важные нюансы

- Формат исходников принудительно `3.0 (quilt)` (`scripts/build-package.sh`),
  поэтому патч накладывается `dpkg-source`.
- Версия 2.4.134 новее trixie (2.4.124) и новее первой сборки 2.4.134-1+crick,
  поэтому `apt upgrade` подхватывает переработанную упаковку.
