# wayland (crick Debian backports)

Сборка `wayland` 1.26.0 для Debian 13 (trixie, amd64). Упаковка взята из
Debian (`wayland_1.26.0-1`).

## Зачем нужна более свежая версия

`wlroots` 0.20.2 требует в meson wayland не ниже 1.24 и использует API,
которого нет в wayland 1.23.1 из trixie:

- `wl_resource_get_interface()` — `types/wlr_compositor.c`;
- `wl_resource_post_error_vargs()` — там же, обёртка для ошибок протокола.

Это не только проверка версии в meson: обе функции попадают в
`libwlroots-0.20.so` как неопределённые символы, поэтому trixie-версии
библиотеки для готового пакета недостаточно.

## Включено

- Все бинарные пакеты упаковки Debian, кроме документации:
  `libwayland-client0`, `libwayland-server0`, `libwayland-cursor0`,
  `libwayland-egl1`, `libwayland-egl-backend-dev`, `libwayland-dev`,
  `libwayland-bin` (`wayland-scanner`). Набор закрытый: `libwayland-dev`
  требует ровно эти версии.

## Отключено

- `libwayland-doc` — документация не собирается (`-Ddocumentation=false`
  безусловно), поэтому удалены весь `Build-Depends-Indep` (doxygen, graphviz,
  xmlto, xsltproc, mdbook) и файл `libwayland-doc.install`.
- Man-страницы тоже не собираются: они генерируются в апстриме вместе с API-документацией (опция `documentation`), поэтому строки `usr/share/man/man3` убраны из `libwayland-dev.install`.
- Собственные тесты wayland не собираются (`-Dtests=false`) и не запускаются:
  `override_dh_auto_test` пуст, каталог `debian/tests` удалён.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Версия: `1.26.0-2+crick` (новее штатной 1.23.1-3; ревизия 2 — из-за
  переработки упаковки).
- `Maintainer`: нейтральная идентичность проекта.
- Формат исходников `3.0 (quilt)`; собственных патчей у пакета нет.

## Влияние на другие пакеты

SONAME всех библиотек прежние (`libwayland-client.so.0`,
`libwayland-server.so.0`, `libwayland-cursor.so.0`, `libwayland-egl.so.1`),
файлы меняются с `…so.0.23.1` на `…so.0.26.0`. Добавлены только новые
символы, удалённых нет, поэтому GTK, Qt, Electron и Wayland-приложения
продолжают работать без пересборки.

## Откат

```
sudo apt install libwayland-client0=1.23.1-3 libwayland-server0=1.23.1-3
```

При `Pin-Priority: 1001` следующий `apt upgrade` вернёт версии из этого
репозитория. `wlroots` и `labwc` этого репозитория после отката
установить нельзя: им нужны символы wayland 1.24+.
