# wlroots

Модульная библиотека Wayland-композитора: `libwlroots.so`.

## Источник упаковки

Упаковка взята из Debian (`wlroots_0.20.2-1`, ветка unstable) и перерабатывается.
Tarball побайтово совпадает с Debian-овским `wlroots_0.20.2.orig.tar.gz`.

## Версии

- **В trixie:** 0.18.2-1
- **В исходной упаковке:** 0.20.2-1
- **В нашем репозитории:** 0.20.2-2+crick (ревизия 2)

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libwlroots-0.20` | `libwlroots.so.0.20` — shared library |
| `libwlroots-0.20-dev` | заголовки, `.pc` |

Не публикуется: `libwlroots-0.20-examples` (примеры), `libwlroots-0.20-0-udeb`.

## Что изменено

### Отключено

- **Xwayland:** `-Dxwayland=disabled`. Вместе с ним отключена обработка ошибок
  XCB (`-Dxcb-errors=disabled`). Из `Build-Depends` и пакетов нет зависимостей
  от `libxcb`/`libx11`.
- **Примеры:** `-Dexamples=false`. Не собираются `cairo-buffer`, `embedded`,
  `output-layers`, `output-layout`, `pointer`, `rotation`, `scene-graph`,
  `simple`, `tablet`, `touch`. Пакет `libwlroots-0.20-examples` не публикуется,
  `libwlroots-0.20-examples.install` удалён.
- **Тесты:** каталог `debian/tests` удалён.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- **Только нужные бэкенды:** `-Dbackends=drm,libinput`.
- Все библиотеки берутся из этого репозитория: `wayland` 1.26.0, `libdrm`
  2.4.134, `libxkbcommon` 1.13.1, `pixman` 0.46.4, `wayland-protocols` 1.47.
- `libegl-dev`, `libgles-dev`, `libgbm-dev` — из `libglvnd` и `mesa` этого репозитория.

## Патчи

Один патч Debian сохранён: `Revert-layer-shell-error-on-0-dimension-without-anchors.patch`.

## Изменения ABI

`libwlroots.so.0.20` — SONAME не меняется, удалённых символов нет.

## Важные нюансы

### Таблица зависимостей

wlroots 0.20.2 требует API, которого в trixie нет. Сборка идёт против версий из
этого репозитория (они вытесняют trixie при `apt upgrade`):

| Пакет | trixie | Нужно | Используется в коде |
|---|---|---|---|
| wayland | 1.23.1 | 1.24 | `wl_resource_get_interface()`, `wl_resource_post_error_vargs()` |
| libdrm | 2.4.124 | 2.4.129 | 17 констант `DRM_FORMAT_*` |
| libxkbcommon | 1.7.0 | 1.8 | `XKB_LED_NAME_COMPOSE`, `XKB_LED_NAME_KANA` |
| pixman | 0.44.0 | 0.46 | `PIXMAN_a16b16g16r16` |
| wayland-protocols | 1.44 | 1.47 | color-management-v1 v2: `send_ready2`, `TRANSFER_FUNCTION_COMPOUND_POWER_2_4` |

Ослаблять требования нельзя: макросов и функций в trixie-версиях нет, сборка
падала бы.

### Сводная таблица: trixie → нужно → что используется

См. также `packages/wlroots/README.md` в репозитории для полной таблицы
зависимости по библиотекам.

### GL берётся из этого репозитория

`libegl-dev`, `libgles-dev`, `libgbm-dev` — из сборок `libglvnd` и `mesa`
этого репозитория. Штатный `libegl-dev` несовместим: он тянет
`libgl1-mesa-dev`, пинящий `libgbm1` trixie. Исключений в `CLOSURE_EXCEPT` нет.

В `debian/control` заменено: `libgles2-mesa-dev` → `libgles-dev`,
`libegl1-mesa-dev` удалён — наша `mesa-common-dev` уже содержит оба заголовка,
а mesa объявляет `Breaks: libegl1-mesa-dev`.
