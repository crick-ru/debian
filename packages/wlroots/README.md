# wlroots (crick Debian backports)

Сборка `wlroots` 0.20.2 для Debian 13 (trixie, amd64), ограниченная только теми
бэкендами, которые нужны в чистом Wayland.

## Включено

- Только бэкенды `drm` и `libinput`: `-Dbackends=drm,libinput`.
- Библиотеки и протоколы, которых требует 0.20.2, берутся из этого же
  репозитория (см. ниже): `wayland` 1.26.0, `libdrm` 2.4.134,
  `libxkbcommon` 1.13.1, `pixman` 0.46.4 и `wayland-protocols` 1.47. Сборка
  в CI идёт в стадии 2 после этих пакетов.

## Отключено

- **Xwayland**: `-Dxwayland=disabled`. Вместе с ним отключается обработка
  ошибок XCB (`-Dxcb-errors=disabled`), поэтому в пакетах нет зависимостей от
  `libxcb`/`libx11`.
- **Примеры**: `-Dexamples=false`. Не собираются `cairo-buffer`, `embedded`,
  `output-layers`, `output-layout`, `pointer`, `rotation`, `scene-graph`,
  `simple`, `tablet`, `touch`; пакет `libwlroots-0.20-examples` не
  публикуется, его `.install` удалён. Побочный эффект: из `Build-Depends`
  убран `libcairo2-dev` — cairo в wlroots нужен только примеру
  `examples/cairo-buffer`, сама библиотека cairo не использует.
- Тесты не собираются и не запускаются: каталог `debian/tests` (автотест
  `build-test`, компилирующий `debian/tests/test.c` и запускающий его с
  `WLR_BACKENDS=headless`) удалён.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Версия: `0.20.2-2+crick` (ревизия 2 — из-за переработки упаковки).
- Требования версий не понижаются: `wayland` 1.24, `libdrm` 2.4.129,
  `libxkbcommon` 1.8, `pixman` 0.46 и `wayland-protocols` 1.47 закрываются
  пакетами этого репозитория. В `debian/control` эти минимумы указаны явно
  (в т.ч. у пакета `libwlroots-0.20-dev`) — так требования соответствуют
  реально используемому API.

## С какими библиотеками он собирается

`wlroots` 0.20.2 требует API, которого в trixie нет, поэтому против него
собираются библиотеки и протоколы этого же репозитория (версии из
`apt upgrade` вытесняют штатные):

| Пакет | trixie | Нужно | Используется в коде |
|---|---|---|---|
| wayland | 1.23.1 | 1.24 | `wl_resource_get_interface()`, `wl_resource_post_error_vargs()` |
| libdrm | 2.4.124 | 2.4.129 | 17 констант `DRM_FORMAT_*` (`R16F`, `BGR161616`, `S010`…`S416` и др.) |
| libxkbcommon | 1.7.0 | 1.8 | `XKB_LED_NAME_COMPOSE`, `XKB_LED_NAME_KANA` |
| pixman | 0.44.0 | 0.46 | `PIXMAN_a16b16g16r16` (единственный нужный 64-битный формат) |
| wayland-protocols | 1.44 | 1.47 | color-management-v1 версии 2: `send_ready2`, `send_preferred_changed2`, `TRANSFER_FUNCTION_COMPOUND_POWER_2_4`, `ERROR_CHROMA_LOCATION` |

Ослаблять эти требования патчем нельзя: макросов `DRM_FORMAT_*` в libdrm
2.4.124 нет, `PIXMAN_a16b16g16r16` в pixman 0.44 не существует (до 0.46 у
pixman не было 64-битных форматов вовсе), а color-management-v1 в 1.44 ещё
без событий второй версии — сборка падала бы.

Влияние на систему: SONAME всех библиотек не меняются, удалённых символов
нет, поэтому уже установленные программы продолжают работать без
пересборки. Подробности и порядок отката — в `packages/<pkg>/README.md`.

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
