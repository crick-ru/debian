# libva

Video Acceleration API (VA-API): интерфейс аппаратного ускорения видео.

## Источник упаковки

Упаковка взята из Debian (`libva_2.24.1-2`, ветка 2.24, `unstable`) и
переработана. Tarball побайтово совпадает с Debian-овским `libva_2.24.1.orig.tar.gz`.

## Версии

- **В trixie:** 2.22.0-3
- **В исходной упаковке:** 2.24.1-2
- **В нашем репозитории:** 2.24.1-2+crick (ревизия 2)

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libva2` | `libva.so.2` — ядро интерфейса |
| `libva-drm2` | `libva-drm.so.2` — путь DRM |
| `libva-wayland2` | `libva-wayland.so.2` — путь Wayland |
| `libva-dev` | заголовки `va/`, `libva.pc`, `libva-drm.pc`, `libva-wayland.pc` |

Не публикуются: `libva-x11-2` и `libva-glx2` (X11-путь и GLX — X11 в репозитории
нет).

## Что изменено

### Отключено

- **X11-путь и GLX** (правило репозитория): `-Dwith_x11=no` отключает сборку
  `libva_x11.so` и `libva_glx.so`. Одной опцией `-Dwith_x11=no` снимается и
  GLX: `meson.build:104` запрещает явное `-Dwith_glx=yes` при выключенном X11.
  Из `Build-Depends` убраны `libx11-dev`, `libxext-dev`, `libxfixes-dev`,
  `libx11-xcb-dev`, `libxcb1-dev`, `libxcb-dri3-dev`, `libgl-dev`.
- **Тесты** (upstream проверяет GLX и X11): `override_dh_auto_test` пуст,
  `override_dh_autoreconf` пуст.
- **Документация:** `-Denable_docs=false`.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

Полностью сохраняется VA-API: пути DRM и Wayland на месте. В `NEEDED` бинарников
нет `libX11.so.6`, `libGLX.so.0`, `libva-x11.so.2`, `libva-glx.so.2` — проверено
фактической сборкой (25 целей).

## Патчи

Нет: `debian/patches/series` отсутствует.

## Изменения ABI

Символы не удаляются: `libva2.symbols`, `libva-drm2.symbols`,
`libva-wayland2.symbols` из Debian используются как есть. Проверено фактической
сборкой: 92/1/3 символа — ровно столько же, сколько у штатного libva 2.22.0.

## Важные нюансы

### Зачем нужен

Штатный `libva-dev` из trixie несовместим с нашей mesa: `libva-dev` →
`libva-glx2` → `libgl1` → `libglvnd0` (trixie версии). Собирать `mesa`
падало с `cannot resolve build-dependency 'libva-dev'` (CI 37168394656).

Наш `libva` не содержит X11 и GLX, поэтому пинов нет — `Build-Depends` mesa
разрешается.

### Поле `Provides` в `libva2`

VA-драйверы зависят от `libva` не по имени, а по виртуальному имени драйверного
ABI: `libva-driver-abi-1.22`. Поле `Provides` сохраняет набор имен
`1.0, 1.8, 1.17-1.21` от trixie и добавляет `1.22, 1.23, 1.24` из unstable.
Без него `apt upgrade` лишил бы установленных VA-драйверов удовлетворённости
зависимостей.

Проверка после обновления:
```
apt-cache policy libva2
dpkg -s intel-media-va-driver-non-free | grep -i 'depends\|status'
apt-get -s upgrade
```
