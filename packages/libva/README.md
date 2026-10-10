# libva — зачем он здесь

## Что это

`libva` — интерфейс Video Acceleration API. Приложение просит ускорение
декодирования и кодирования видео, а драйвер решает, через какой аппаратный
путь это сделать. Собираются три библиотеки:

| Пакет | Что внутри |
|---|---|
| `libva2` | `libva.so.2` — ядро интерфейса, то самое, что ищут VA-драйверы |
| `libva-drm2` | `libva-drm.so.2` — путь DRM: передача DRM-устройств и буферов |
| `libva-wayland2` | `libva-wayland.so.2` — путь Wayland: передача поверхностей и EGL-буферов |
| `libva-dev` | заголовки `va/`, `libva.pc`, `libva-drm.pc`, `libva-wayland.pc` |

Не публикуются: `libva-x11-2` и `libva-glx2`. Это X11-путь и GLX-вариант
VA-API, а X11 в репозитории нет.

## Почему мы его собираем

Штатный `libva-dev` неразрешим рядом с нашими пакетами:

```
libva-dev (Debian) → libva-glx2 → libgl1 → libglvnd0 (= 1.7.0-1+b2)  ← ПИН TRIXIE
                                       └─ libx11-6                          ← X11
```

`libva-dev` нужен `mesa` по `Build-Depends` (`libva-dev (>= 1.6.0) [linux-any]`)
ради VA-API. Пока ставился штатный, `mesa` падала с
`cannot resolve build-dependency 'libva-dev'` — прогон CI `37168394656`.
Пин `libglvnd0` снимается нашей сборкой glvnd, а X11 уходит вместе с
`libva-glx2`.

## VA-API при этом полностью сохраняется

VA-API имеет три пути отображения. Теряется только X11-путь, которого в
репозитории нет по правилу:

| Путь | Статус |
|---|---|
| DRM | публикуется, `libva-drm.so.2` в `NEEDED`: `libva.so.2`, `libdrm.so.2`, `libc.so.6` |
| Wayland | публикуется, `libva-wayland.so.2` в `NEEDED`: `libva.so.2`, `libdrm.so.2`, `libwayland-client.so.0`, `libc.so.6` |
| X11 | не публикуется |
| GLX | не публикуется |

Проверено фактической сборкой 2.24.1 (25 целей): `libva-x11.so` и
`libva-glx.so` не строятся вовсе, строк `libX11.so.6`, `libGLX.so.0`,
`libva-x11.so.2`, `libva-glx.so.2` в бинарниках нет ни одной. Символов
92 / 1 / 3 — ровно столько же, сколько у штатного libva 2.22.0, то есть ABI
сохраняется при версии 2.24.1.

## Как отключается X11

Одной опцией `-Dwith_x11=no`:

```meson
WITH_X11 = false
if get_option('with_x11') != 'no'
  x11_dep = dependency('x11', required : ...)     # ← не ищется вовсе
  ...
endif
if not WITH_X11 and get_option('with_glx') == 'yes'   # meson.build:104
  error('VA/GLX explicitly enabled, but VA/X11 isn\'t built')
endif
if WITH_X11          → subdir x11      # ← не выполняется
if WITH_GLX          → subdir glx      # ← не выполняется
```

`-Dwith_x11=no` обнуляет `WITH_X11`, а следом и `WITH_GLX` — явное `-Dwith_glx=yes`
при выключенном X11 даёт ошибку, так что ошибиться нельзя.

Из `Build-Depends` убраны `libx11-dev`, `libxext-dev`, `libxfixes-dev`,
`libx11-xcb-dev`, `libxcb1-dev`, `libxcb-dri3-dev`, `libgl-dev`: они нужны
ровно для `-Dwith_x11=yes`.

## Драйверный ABI: почему поле `Provides` обязательно

VA-драйвер зависит от `libva` не по имени библиотеки, а по **виртуальному
имени драйнерного ABI**:

```
intel-media-va-driver-non-free → Depends: libva-driver-abi-1.22
intel-media-va-driver          → Depends: libva-driver-abi-1.22
i965-va-driver                 → Depends: libva-driver-abi-1.22
```

`libva-driver-abi-1.22` не существует как отдельный пакет — его даёт поле
`Provides` у `libva2`. То есть набор этих имён и есть контракт с драйверами.

Поле `Provides` в `libva2` возвращено (`REVISION=2`): набор `1.0, 1.8,
1.17-1.21` сохранён от trixie без изменений, чтобы не отнять виртуальных имён
ни у одного драйвера (принцип: virtual-`Provides` — это объявление
совместимости, а не украшение; лишние имена не ломают, недостающие ломают).
`1.22-1.24` добавлены по unstable.

Без поля `Provides` при `apt upgrade` наш `libva2` не предоставляет имена
`libva-driver-abi-1.22`, и установленный VA-драйвер (intel-media-va-driver,
i965-va-driver и др.) теряет удовлетворённость зависимостей.

**Проверка после обновления на реальной системе:**

```bash
apt-cache policy libva2                       # наша версия 2.24.1-2+crick
dpkg -s intel-media-va-driver-non-free | grep -i 'depends\|status'
apt-get -s upgrade                            # без «held broken packages»
```

`libva-driver-abi-1.24` нужен драйверу версии 26.2.4 и новее (в unstable он
уже требует `>= 22.10.1+ds1` от `libigdgmm12`, которого в trixie нет) — то есть
если с этого момента нужен свежий драйвер, его придётся собирать у нас.

## Упаковка

Упаковка взята из Debian (`libva_2.24.1-2`, ветка 2.24) и переработана.
Взята именно `unstable`, а не `trixie` (там `2.22.0-3`) — по правилу
«Источник упаковки» порядок выбора начинается с unstable. Tarball совпадает с
пулом Debian.

Переработано: `control` (сняты X11-зависимости, четыре пакета вместо шести),
`rules` (`conf_flags`, пустые тесты, убран `shlibs.local` под несуществующий
переходный пакет `libva1`), `libva-dev.install` (Debian-овский тянет
dh-скрипты `dh_libva` и `libva.pm` — это инструмент сборки, пользователю не
нужен).

## Откат

Вернуть `libva-x11-2` и `libva-glx2`, снять `-Dwith_x11=no` с `-Dwith_glx=no`,
поднять ревизию на 3. Тогда пять пакетов снова придётся собирать против
штатного `libglvnd0`, и нарушение правила X11 вернётся — фиксируется
исключением в `CLOSURE_EXCEPT`.
