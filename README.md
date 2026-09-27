# crick Debian backports

Новые версии пакетов для **Debian 13 (trixie, amd64)**.

## Состав

| Пакет       |                                    | Версия     | Особенности |
|-------------|------------------------------------|------------|------------------------------------------------------|
| `fdk-aac`   | [🔗](packages/fdk-aac/README.md)   | 2.0.3      | Fraunhofer FDK AAC |
| `libtsm`    | [🔗](packages/libtsm/README.md)    | 4.8.0      | конечный автомат терминала для KMSCON |
| `kmscon`    | [🔗](packages/kmscon/README.md)    | 10.0.3     | терминальный эмулятор на DRM/KMS, без X11 |
| `sfwbar`    | [🔗](packages/sfwbar/README.md)    | 1.0~beta17 | панель задач для Wayland-композиторов |
| `mpv`       | [🔗](packages/mpv/README.md)       | 0.41.0     | чистый Wayland, X11 вырезан |
| `celluloid` | [🔗](packages/celluloid/README.md) | 0.29       | GTK4-фронтенд для mpv |
| `pipewire`  | [🔗](packages/pipewire/README.md)  | 1.6.9      | Bluetooth AAC; X11, JACK, V4L2 и libcamera отключены |
| `wlroots`   | [🔗](packages/wlroots/README.md)   | 0.20.2     | библиотека композитора; DRM/libinput, без Xwayland |
| `labwc`     | [🔗](packages/labwc/README.md)     | 0.20.2     | Wayland-композитор на wlroots |

Библиотеки, которые публикуются в связи с `wlroots` (у 0.20.2 нет в trixie
версий с нужным API, поэтому версии вытесняют штатные при `apt upgrade` —
в каждом README есть разбор влияния и порядок отката):

| Пакет               |                                            | Версия  | Зачем |
|---------------------|--------------------------------------------|---------|----------------------------------------------------|
| `wayland`           | [🔗](packages/wayland/README.md)           | 1.26.0  | API wayland 1.24+ использует `wlroots` |
| `libdrm`            | [🔗](packages/libdrm/README.md)            | 2.4.134 | 17 констант `DRM_FORMAT_*` из libdrm 2.4.129+ |
| `libxkbcommon`      | [🔗](packages/libxkbcommon/README.md)      | 1.13.1  | `XKB_LED_NAME_COMPOSE`/`KANA` из libxkbcommon 1.8+ |
| `pixman`            | [🔗](packages/pixman/README.md)            | 0.46.4  | 64-битный формат `PIXMAN_a16b16g16r16` |
| `wayland-protocols` | [🔗](packages/wayland-protocols/README.md) | 1.47    | color-management-v1 второй версии |

GTK собирается без X11 (только Wayland-бэкенд) — это урезает и набор
зависимостей, и состав репозитория, но **ломает ABI**: из
`libgtk-3.so.0`/`libgtk-4.so.1` удалены символы `gdk_x11_*` при неизменном
SONAME. Приложения, зовущие X11-API GTK напрямую (без
`#ifdef GDK_WINDOWING_X11`), после `apt upgrade` падают; порядок отката —
в README каждого пакета:

| Пакет               |                                            | Версия  | Особенности |
|---------------------|--------------------------------------------|---------|----------------------------------------------------|
| `gtk+3.0`              | [🔗](packages/gtk+3.0/README.md)              | 3.24.52 | GTK 3 без X11; без doc/examples/tests |
| `gtk4`              | [🔗](packages/gtk4/README.md)              | 4.22.5  | GTK 4 без X11; без doc/examples/tests |

Состав бинарных пакетов сокращён против Debian: `gtk+3.0` — 7 пакетов
(`libgtk-3-0t64`, `libgail-3-0t64`, `libgail-3-dev`, `libgtk-3-common`,
`libgtk-3-bin`, `libgtk-3-dev`, `gir1.2-gtk-3.0`), `gtk4` — 6 пакетов
(`libgtk-4-1`, `libgtk-4-common`, `libgtk-4-bin`, `libgtk-4-dev`,
`gir1.2-gtk-4.0`, `gtk-update-icon-cache`). Именно `libgail-3-0t64`
(пинит `libgtk-3-0t64`) и `gtk-update-icon-cache` (от него зависят
`libgtk-3-bin` и `libgtk-4-bin`) обязательны в этих наборах.

## Подключение

Ключ репозитория:

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://crick-ru.github.io/debian/crick-backports.gpg \
  | sudo tee /etc/apt/keyrings/crick-backports.gpg > /dev/null
```

Источник `/etc/apt/sources.list.d/crick-backports.sources`:

```ini
Types: deb
URIs: https://crick-ru.github.io/debian
Suites: trixie
Components: backports
Signed-By: /etc/apt/keyrings/crick-backports.gpg
```

Или формат одной строкой в `/etc/apt/sources.list`:

```
deb [signed-by=/etc/apt/keyrings/crick-backports.gpg] https://crick-ru.github.io/debian trixie backports
```

Оба варианта равнозначны. Если в системе есть `pin` с приоритетом выше 500 для
официального архива, apt будет предпочитать версии из Debian и предлагать откат
наших более новых пакетов. Тогда закрепите и этот репозиторий (по Label, без
пробелов и кавычек):

```
Package: *
Pin: release l=crick-backports
Pin-Priority: 1001
```

Файл должен называться `*.pref` (например `/etc/apt/preferences.d/crick.pref`).

