# pixman (crick Debian backports)

Сборка `pixman` 0.46.4 для Debian 13 (trixie, amd64). Упаковка взята из
Debian (`pixman_0.46.4-1`).

## Зачем нужна более свежая версия

`wlroots` 0.20.2 требует в `render/pixman/meson.build` pixman не ниже 0.46
и использует константу формата `PIXMAN_a16b16g16r16`
(`render/pixman/pixel_format.c`), которой в pixman 0.44 нет: версии до 0.46
вообще не имеют 64-битных форматов. В 0.46 также появился API
`pixman_region64f_*`, но `wlroots` его не использует — из всех изменений
нужна ровно одна константа формата.

## Включено

- `libpixman-1-0` и `libpixman-1-dev`. Пара закрытая: `-dev` требует
  `libpixman-1-0 (= ${binary:Version})`.

## Отключено

- `libpixman-1-0-udeb` — минимальный пакет для установщика Debian, в
  репозиторий не попадает (`scripts/build-package.sh` собирает только
  `*.deb`).
- Сборка GTK-демо (`-Dgtk=disabled`, как в упаковке Debian).
- Тесты pixman не собираются и не запускаются: `override_dh_auto_test` пуст
  (сборочная система meson в `build/` их генерирует, но запускать нечего —
  правило «тесты не собираются» в `.clinerules/project.md`).
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Версия: `0.46.4-2+crick` (новее штатной 0.44.0-3; ревизия 2 — из-за
  переработки упаковки).
- `Maintainer`: нейтральная идентичность проекта.
- Формат исходников: в Debian он `1.0`, а `scripts/build-package.sh`
  принудительно ставит `3.0 (quilt)`, поэтому из `debian/rules` убран
  add-on `--with quilt` — иначе патчи применились бы дважды.
  Патч `debian/patches/test-increase-timeout.diff` накладывает `dpkg-source`.

## Влияние на другие пакеты

SONAME прежний (`libpixman-1.so.0`), файл меняется с
`libpixman-1.so.0.44.0` на `libpixman-1.so.0.46.4`; удалённых публичных
идентификаторов нет (сверены заголовки 0.44.0 и 0.46.4), поэтому cairo, GTK и
другие клиенты работают без пересборки. В trixie от libpixman-1-0 зависят
62 пакета.

## Откат

```
sudo apt install libpixman-1-0=0.44.0-3 libpixman-1-dev=0.44.0-3
```

При `Pin-Priority: 1001` следующий `apt upgrade` вернёт версию из этого
репозитория.
