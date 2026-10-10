# cairo (crick Debian backports)

Сборка `cairo` 1.18.6 для Debian 13 (trixie, amd64) **без X11**. Упаковка
написана с нуля для этого репозитория.

## Зачем эта сборка

1. **Свежее, чем в trixie:** в trixie `cairo` 1.18.4-1+b1, здесь 1.18.6
   (выпуск 2026-09-20, последний в ветке 1.18).
2. **Это последняя X11-библиотека в графическом стеке.** `libgtk-3-0t64` и
   `libgtk-4-1` этого репозитория собраны без X11-бэкенда, `mpv` собран с
   `-Dx11=disabled`, у `pipewire` выключены X11 и X11-xfixes, `wlroots` —
   с `-Dxwayland=disabled`, `labwc` — с `-Dxwayland=disabled`, `kmscon` к
   X11 не привязан. `cairo` был единственным звеном, которое тянуло
   `libX11`, `libXext`, `libXrender` и `libxcb` в готовую систему: Xlib- и
   XCB-бэкенды cairo (`cairo_xlib_*`, `cairo_xcb_*`) умеют рисовать прямо в
   окно X-сервера, и без них остаётся чистый Wayland.
3. **Цель репозитория** — система на чистом Wayland, поэтому зависимость от
   X11 здесь не оставляется ни в виде символов, ни в виде
   `Build-Depends` (по правилам проекта).

## Включено

- Бэкенды поверхностей: `image`, `png`, `svg`, `ps`, `pdf`, `script`
  (Lua-интерпретатор), `tee`.
- Шрифты: `freetype` + `fontconfig`, свой `user-font-engine`.
- GObject-привязки (`libcairo-gobject2`) — их требует GTK.
- Lua-интерпретатор скриптов (`libcairo-script-interpreter2`) — его требует
  `libgtk-4-1` из этого репозитория.
- `liblzo2` — сжатие в формате скриптов cairo, как в Debian.

Состав бинарных пакетов: `libcairo2`, `libcairo-gobject2`,
`libcairo-script-interpreter2`, `libcairo2-dev`. **Набор закрытый**: все четыре
имеют `Multi-Arch: same` и пинят друг друга через `= ${binary:Version}`.
Это не педантизм — штатные `libcairo-gobject2` и
`libcairo-script-interpreter2` из trixie тоже пинят `libcairo2
(= 1.18.4-1+b1)`, поэтому без собственных копий всех троих `apt upgrade`
`libcairo2` был бы неразрешим.

## Отключено

- **X11-бэкенды: `-Dxlib=disabled -Dxcb=disabled -Dxlib-xcb=disabled`.**
  Не компилируются `cairo-xlib-surface.c`, `cairo-xcb-*.c` и прочие
  X11-исходники, не устанавливаются заголовки `cairo-xlib.h`,
  `cairo-xlib-xrender.h`, `cairo-xcb.h` и файлы `pkgconfig/cairo-xlib.pc`,
  `pkgconfig/cairo-xcb.pc`. Из `Build-Depends` убраны `libx11-dev`,
  `libxext-dev`, `libxrender-dev`, `libxcb1-dev`, `libxcb-render0-dev`,
  `libxcb-shm0-dev`, `libx11-xcb-dev`.
- Тесты: `-Dtests=disabled` (иначе подтягиваются `ghostscript`,
  `libspectre`, `poppler-glib`, `librsvg-2.0`). Тесты не собираются и не
  запускаются.
- Документация: `-Dgtk_doc=false` (дефолт апстрима), пакет `libcairo2-doc`
  не публикуется. Готовой документации, которую можно просто
  установить, в cairo нет.
- Отладочные утилиты: `-Dsymbol-lookup=disabled` — иначе при наличии
  `libbfd-dev` собирается поддержка symbol lookup в отладочных утилитах.
  Кроме того, `libcairo-trace.so`, `libcairo-fdr.so` (<libdir>/cairo/) и
  `cairo-trace(1)` удаляются из дерева установки в
  `override_dh_auto_install` — пакетов под них нет и в Debian.
- `libcairo2-udeb` — минимального пакета для установщика Debian в trixie нет.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Версия: `1.18.6-1+crick` (новее штатной 1.18.4-1+b1). Ревизия 1: пакет
  публикуется впервые. Собирается в последней стадии CI: кроме trixie ему
  ничего не нужно, а требование `libpixman-1-dev >= 0.40.0` закрывает
  штатный pixman 0.44.0.
- Тарбол берётся как есть: `cairo-1.18.6.tar.xz` с cairographics.org. Debian
  перепаковывает ровно этот же архив в `cairo_1.18.4.orig.tar.*`, так что
  upstream-версия совпадает.
- Формат исходников `3.0 (quilt)`; собственных патчей нет.
- Символьных файлов (`debian/*.symbols`) нет намеренно: их пришлось бы
  переписывать под урезанный набор символов, а проверять тут нечего —
  единственное, что делает сборка, это убирает символы.

## Влияние на другие пакеты: ломается ABI

SONAME не меняется: `libcairo.so.2`. Меняется имя файла:
`libcairo.so.2.11800.4` → `libcairo.so.2.11800.6`. **При неизменном SONAME
из библиотеки удалены 26 публичных функций** — все, что объявлены в
`cairo-xlib.h`, `cairo-xlib-xrender.h` и `cairo-xcb.h`:

| Префикс | Функций | Примеры |
|---------|---------|---------|
| `cairo_xlib_*` | 16 | `cairo_xlib_surface_create`, `cairo_xlib_surface_get_visual`, `cairo_xlib_surface_set_size`, `cairo_xlib_device_debug_set_precision` |
| `cairo_xcb_*` | 10 | `cairo_xcb_surface_create`, `cairo_xcb_device_get_connection`, `cairo_xcb_surface_set_drawable`, `cairo_xcb_device_debug_cap_xshm_version` |

Апстрим об этом предупреждает сам: опции `xlib`/`xcb` меняют ABI без смены
SONAME. Это **второе намеренное нарушение инварианта** в репозитории (первое —
`gtk+3.0` и `gtk4`, см. их README).

Масштаб: в trixie на `libcairo2` завязано **около 880 пакетов**
(`apt-cache rdepends libcairo2`).


### Что перестаёт работать

Только код, который зовёт `cairo_xlib_*`/`cairo_xcb_*` напрямую:

- **GTK 2** — `libgtk2.0-0t64` (gdk-x11 создаёт поверхности cairo через
  Xlib), а вместе с ним всё, что на нём построено:
  `uim-gtk2.0`, `gtk2-engines` и его плагины, `lazarus-ide-gtk2-4.0`,
  GTK2-приложения.
- **`libghc-gi-gdkx11-dev`** — Haskell-биндинг GdkX11.

### Что работает и почему

- **X-сервер:** `xserver-xorg-core` вообще не зависит от `libcairo2`
  (проверено по метаданным trixie), поэтому Xorg на libcairo не завязан.
- **Этот репозиторий:** `libgtk-3-0t64` и `libgtk-4-1` собраны без
  X11-бэкенда, поэтому Xlib-поверхности им не нужны; `labwc` использует
  только `cairo_image_surface_*` и `cairo_create` (проверено по исходникам
  0.20.2); `librsvg`, `weston`, `gdk-pixbuf` рисуют в обычные поверхности и
  X11-API cairo не зовут.
- **Обратная совместимость не нарушена:** новые символы только добавляются
  (1.18.5 и 1.18.6 — багфиксы), удалённых нет, кроме перечисленных выше.

### Как проверить конкретную программу

```
readelf -Ws /usr/bin/ПРОГРАММА | grep -E 'cairo_(xlib|xcb)_'
```

Пусто — программа переживёт обновление. Непусто — при загрузке получит
«undefined symbol» и не запустится.

## Откат

Полный откат пакета:

```
sudo apt install libcairo2=1.18.4-1+b1 libcairo2-dev=1.18.4-1+b1 \
                 libcairo-gobject2=1.18.4-1+b1 \
                 libcairo-script-interpreter2=1.18.4-1+b1
```

При `Pin-Priority: 1001` следующий `apt upgrade` вернёт версию из этого
репозитория; чтобы этого не произошло, не подключайте репозиторий вовсе или
закрепите `libcairo2` на штатной версии:

```
Package: libcairo2 libcairo2-dev libcairo-gobject2 libcairo-script-interpreter2
Pin: release l=crick-backports
Pin-Priority: -1
```

Если в системе нужен GTK 2 (например, ради старого проприетарного
приложения), этот pin обязателен, иначе после `apt upgrade` приложение
перестанет запускаться, а откат одного `libcairo2` не поможет — придётся
снимать и его.
