# transmission

Легкий BitTorrent-клиент с демоном, CLI и GTK-интерфейсом.

## Источник упаковки

Упаковка взята из Debian (`transmission_4.1.3+dfsg-1`, ветка `debian/sid`
на salsa.debian.org/debian/transmission) и переработана.

Tarball побайтово совпадает с Debian-овским `transmission_4.1.3+dfsg.orig.tar.xz`
в тех файлах, которые не исключены `Files-Excluded` в `debian/copyright`.
Debian репакует tarball с суффиксом `+dfsg`, удаляя bundled third-party
библиотеки (fast_float, fmt, googletest, libb64, libdeflate, libevent,
libnatpmp, libpsl, utfcpp, miniupnp, rapidjson) и предсобранный web-ассет
`web/public_html/transmission-app.*`. Для сборки из чистого upstream-тарбола
`transmission-4.1.3.tar.xz` патч `use-system-libs.patch` переключает CMake
на системные библиотеки, а webui собирается из исходников через `esbuild`
(цель `webui` в `debian/rules`), поэтому суффикс `+dfsg` не нужен: версия в
нашем репозитории — чистый `4.1.3-1+crick`.

## Версии

- **В trixie:** 4.1.0~beta2+dfsg-3+deb13u2
- **В исходной упаковке:** 4.1.3+dfsg-1
- **В нашем репозитории:** 4.1.3-1+crick (REVISION=1 — упаковка взята без изменений после первой публикации)

Сборка 4.1.3 новее версии из trixie (4.1.0~beta2).

## Содержимое

| Пакет | Содержимое |
|---|---|
| `transmission` | метапакет: зависит от `transmission-common` + `transmission-gtk` или `transmission-cli` |
| `transmission-common` | общие файлы: web UI (`public_html`), иконки, справка |
| `transmission-cli` | `transmission-cli`, `transmission-create`, `transmission-edit`, `transmission-remote`, `transmission-show` |
| `transmission-gtk` | GTK4-клиент `transmission-gtk` |
| `transmission-daemon` | `transmission-daemon` + systemd-юнит + настройки по умолчанию |
| `libtransmission-dev` | статическая библиотека `libtransmission.a` и заголовки |

## Что изменено

### Отключено

- **Qt-клиент:** `-DENABLE_QT=OFF`. Qt6-стек не входит в репозиторий, поэтому
  `qt6-base-dev`, `qt6-tools-dev`, `qt6-tools-dev-tools`, `qt6-svg-dev` удалены
  из `Build-Depends`, а пакет `transmission-qt` не собирается. Метапакет
  `transmission` больше не предлагает Qt-клиент как альтернативу.
- **X11 / системный трей:** `libayatana-appindicator3-dev` удалён из
  `Build-Depends`. AppIndicator — это GTK3-only system tray, опция
  `WITH_APPINDICATOR` в CMake описана как «GTK+ 3 only», и GTK4-клиент
  transmission не использует X11-бэкенды. Добавлен `-DWITH_APPINDICATOR=OFF`.
- **Тесты:** `-DENABLE_TESTS=OFF`. `libgtest-dev` удалён из `Build-Depends`,
  `USE_SYSTEM_GTEST` удалён из cmake-флагов. Тестовые бинарники не компилируются.
- **Документация:** `-DINSTALL_DOC=OFF`. Man-страницы и справка не генерируются.
  Готовые man-страницы из tar-бола (`*.manpages`) устанавливаются как есть — это
  не сгенерированная документация.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- **GTK4:** сборка GTK-клиента против `libgtk-4-dev` **этого репозитория** (без X11),
  а не GTK из trixie. `libgtk-4-dev` добавлен в `Build-Depends` для замыкания
  CI-зависимостей на gtk4 (как в `celluloid`).
- **Web UI:** сборка web-интерфейса через `esbuild` (esbuild, rsass,
  node-fast-deep-equal в `Build-Depends`). Предкомпилированный CSS
  (`transmission-app.css`) поставляется из tarball (патч `web-easier-build.patch`
  переключает импорт с SCSS на CSS).
- **CMake hardening:** `hardening=+all`, `CMAKE_BUILD_TYPE=RelWithDebInfo`.

## Патчи

Шесть патчей из упаковки Debian (ветка `debian/sid`), все применяются как есть:

1. `use-system-libs.patch` — CMake ищет системные third-party библиотеки
   (libevent, libdeflate, libb64, libpsl, libnatpmp, libminiupnpc, utfcpp,
   libfast-float, libfmt, rapidjson) вместо bundled-версий.
2. `web-easier-build.patch` — импорт CSS вместо SCSS в web-сборке.
3. `systemd_service_fixes.patch` — `User=debian-transmission` в systemd-юните.
4. `fix-gnome-icon.patch` — статический application ID для GTK.
5. `0003-disable-git-hook-installation.patch` — отключение установки git hook'ов.
6. `0004-do-not-mess-revision.patch` — `REVISION` файл не перезаписывается сборкой.

## Изменения ABI

Нет: Transmission — приложение, а не библиотека. `libtransmission-dev` содержит
только статическую библиотеку (`libtransmission.a`) и заголовки — shared library
не собирается (`INSTALL_LIB=ON` устанавливает `.a` и заголовки в `-dev`).

## Важные нюансы

- Сборка GTK-клиента против нашей GTK4 (без X11) требует, чтобы `libgtk-4-dev`
  из stage 6 был установлен до сборки. Это обеспечивается добавлением
  `libgtk-4-dev` в `Build-Depends` — `gen-workflow.py` автоматически замыкает
  gtk4 и добавляет его `.deb` в список установки.
- `transmission-daemon` использует `libsystemd-dev` для systemd-уведомлений
  (`WITH_SYSTEMD` в CMake). Это не X11 и не at-spi2-core — это systemd.
- Веб-интерфейс daemon пересобирается из исходников (esbuild), предсобранный JS
  из tarball перезаписывается флагом `--allow-overwrite`.
