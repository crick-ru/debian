# crick Debian backports

Новые версии пакетов для **Debian 13 (trixie, amd64)**.

## Состав

| Пакет | Версия | Особенности |
|-------|--------|-------------|
| `fdk-aac` | 2.0.3 | Fraunhofer FDK AAC |
| `libtsm` | 4.8.0 | конечный автомат терминала для KMSCON |
| `kmscon` | 10.0.3 | терминальный эмулятор на DRM/KMS, без X11 |
| `sfwbar` | 1.0~beta17 | панель задач для Wayland-композиторов |
| `mpv` | 0.41.0 | чистый Wayland, X11 вырезан |
| `celluloid` | 0.29 | GTK4-фронтенд для mpv |
| `pipewire` | 1.6.9 | Bluetooth AAC; X11 вырезан; libcamera отключена |

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
