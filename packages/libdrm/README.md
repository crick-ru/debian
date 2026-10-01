# libdrm (crick Debian backports)

Сборка `libdrm` 2.4.134 для Debian 13 (trixie, amd64). Упаковка взята из
Debian (`libdrm_2.4.134-3`).

## Включено

- Все библиотеки драйверов для amd64 из упаковки Debian:
  `libdrm2`, `libdrm-common`, `libdrm-dev`, `libdrm-amdgpu1`,
  `libdrm-freedreno1`, `libdrm-intel1`, `libdrm-nouveau2`, `libdrm-radeon1`.
  Набор закрытый: `libdrm-dev` требует ровно эти версии
  (`= ${binary:Version}`), поэтому пакет нельзя поставить частично.

## Отключено

- `libdrm-tests` — тестовые программы (`modetest`, `amdgpu_stress`,
  `drmdevice`, `vbltest`, `modeprint`, `proptest`) не собираются
  (`-Dinstall-test-programs=false`), файл `libdrm-tests.install` удалён.
- Тестовая сборочная система не запускается: `override_dh_auto_test` пуст.
- Man-страницы не генерируются (`-Dman-pages=disabled`), поэтому убран
  `python3-docutils` (нужен был для `rst2man`) и строки `usr/share/man` из
  `libdrm-dev.install`.
- X11 не нужен: `libx11-dev` убран из `Build-Depends` — в libdrm он был только
  ради тестовых программ.
- Пакеты других архитектур (`libdrm-omap1`, `libdrm-exynos1`,
  `libdrm-tegra0`, `libdrm-etnaviv1`) — в `debian/control` они ограничены
  arm-архитектурами, на amd64 не собираются.
- `libdrm2-udeb` — минимальный пакет для установщика Debian;
  `scripts/build-package.sh` собирает в пул только `*.deb`, поэтому udeb в
  репозиторий не попадает.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Версия: `2.4.134-2+crick` (версия `-2+crick` новее штатной 2.4.124-2 и
  новее первой опубликованной сборки `2.4.134-1+crick`, поэтому `apt upgrade`
  подхватывает и переработанную упаковку).
- Формат исходников принудительно `3.0 (quilt)` (`scripts/build-package.sh`),
  поэтому патч `debian/patches/01_default_perms.diff` накладывает `dpkg-source`.

## Влияние на другие пакеты

Совместимость сохранена: SONAME всех библиотек прежние (`libdrm.so.2`,
`libdrm_amdgpu.so.1`, `libdrm_intel.so.1`, `libdrm_nouveau.so.2`,
`libdrm_radeon.so.1`), версия на сборке `libdrm.so.2.124.0` → `libdrm.so.2.134.0`.
Новых символов добавлено, удалённых нет, поэтому Mesa, X-сервер и
Wayland-стек продолжают работать без пересборки (в trixie от libdrm2 зависят
110 пакетов).

## Откат

```
sudo apt install libdrm2=2.4.124-2 libdrm-dev=2.4.124-2
```

При `Pin-Priority: 1001` на репозиторий следующий `apt upgrade` вернёт версии
из этого репозитория — тогда просто отключите репозиторий.
