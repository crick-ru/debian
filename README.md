# crick Debian backports

Новые версии пакетов для **Debian 13 (trixie, amd64)**.

## Состав

| Пакет | Версия | Особенности | Упаковка |
|-------|--------|-------------|----------|
| `fdk-aac` | 2.0.3 | Fraunhofer FDK AAC | [README](packages/fdk-aac/README.md) |
| `libtsm` | 4.8.0 | конечный автомат терминала для KMSCON | [README](packages/libtsm/README.md) |
| `kmscon` | 10.0.3 | терминальный эмулятор на DRM/KMS, без X11 | [README](packages/kmscon/README.md) |
| `sfwbar` | 1.0~beta17 | панель задач для Wayland-композиторов | [README](packages/sfwbar/README.md) |
| `mpv` | 0.41.0 | чистый Wayland, X11 вырезан | [README](packages/mpv/README.md) |
| `celluloid` | 0.29 | GTK4-фронтенд для mpv | [README](packages/celluloid/README.md) |
| `pipewire` | 1.6.9 | Bluetooth AAC; X11, JACK, V4L2 и libcamera отключены | [README](packages/pipewire/README.md) |
| `wlroots` | 0.20.2 | временно не собирается | [README](packages/wlroots/README.md) |
| `labwc` | 0.20.2 | временно не собирается (зависит от wlroots) | [README](packages/labwc/README.md) |

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

Старый формат — одной строкой в `/etc/apt/sources.list.d/crick-backports.list`:

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

