# crick Debian backports

Новые версии пакетов для **Debian 13 (trixie, amd64)**.

## Состав

| Пакет |   | Версия | Особенности |
|-------|---|--------|-------------|
| `fdk-aac` | [🔗](packages/fdk-aac/README.md) | 2.0.3 | Fraunhofer FDK AAC |
| `libtsm`  | [🔗](packages/libtsm/README.md) | 4.8.0 | конечный автомат терминала для KMSCON |
| `kmscon`  | [🔗](packages/kmscon/README.md) | 10.0.3 | терминальный эмулятор на DRM/KMS, без X11 |
| `sfwbar`  | [🔗](packages/sfwbar/README.md) | 1.0~beta17 | панель задач для Wayland-композиторов |
| `mpv`     | [🔗](packages/mpv/README.md) | 0.41.0 | чистый Wayland, X11 вырезан |
| `celluloid` | [🔗](packages/celluloid/README.md) | 0.29 | GTK4-фронтенд для mpv |
| `pipewire`| [🔗](packages/pipewire/README.md) | 1.6.9 | Bluetooth AAC; X11, JACK, V4L2 и libcamera отключены |
| `wlroots` | [🔗](packages/wlroots/README.md) | 0.20.2 | временно не собирается |
| `labwc`   | [🔗](packages/labwc/README.md) | 0.20.2 | временно не собирается (зависит от wlroots) |

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

