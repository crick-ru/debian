# wayland-protocols (crick Debian backports)

Сборка `wayland-protocols` 1.47 для Debian 13 (trixie, arch: all). Упаковка
взята из Debian (`wayland-protocols_1.47-1~bpo13+1`, тот же бэкпорт, что
Debian публикует в `trixie-backports`).

## Зачем нужна более свежая версия

`wlroots` 0.20.2 требует в meson wayland-protocols не ниже 1.47, и это
требование не завышено: с версией 1.44 из trixie сборка `wlroots` падает в
`types/wlr_color_management_v1.c` и `types/wlr_color_representation_v1.c` —
в 1.44 ещё нет событий и перечислений color-management-v1 версии 2
(`wp_image_description_v1_send_ready2`,
`wp_color_management_surface_feedback_v1_send_preferred_changed2`,
`WP_COLOR_MANAGER_V1_TRANSFER_FUNCTION_COMPOUND_POWER_2_4`,
`WP_COLOR_REPRESENTATION_SURFACE_V1_ERROR_CHROMA_LOCATION`).
Все они есть начиная с 1.47.

## Включено

- Пакет `wayland-protocols` целиком (архитектура `all`, `Multi-Arch:
  foreign`): это набор XML-файлов протоколов, используемых только при сборке.

## Отключено

- Тестовая сборочная система wayland-protocols не собирается и не запускается:
  в `debian/rules` добавлен пустой `override_dh_auto_test`, каталог
  `debian/tests` (с `Test-Command: dh_auto_configure; dh_auto_build;
  dh_auto_test`) удалён.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Версия: `1.47-2+crick` (новее штатной 1.44-1; ревизия 2 — из-за
  переработки упаковки).
- `Maintainer`: нейтральная идентичность проекта.
- Формат исходников `3.0 (quilt)`; собственных патчей у пакета нет.

## Влияние на другие пакеты

Пакет состоит только из данных (XML-файлов) и используется только во время
сборки: работающие программы от него не зависят, обновление безопасно —
в 1.47 добавлены новые и обновлены существующие протоколы. При этом
`apt upgrade` поднимет его до 1.47, и это не помешает сборке пакетов, которым
хватает 1.44.

## Откат

```
sudo apt install wayland-protocols=1.44-1
```

`wlroots` этого репозитория после отката установить нельзя: его сборка
требует 1.47.
