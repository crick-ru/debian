# Debian Trixie (Wayland-Only) APT Repository

Репозиторий свежих версий приложений для **Debian 13 (trixie, amd64)**, собранных в чистом Wayland-окружении без устаревших зависимостей X11, Xorg и Xwayland.

Сборка осуществляется через GitHub Actions CI, а публикация готового APT-репозитория — на GitHub Pages:
`https://crick-ru.github.io/debian/`

---

## Включённые пакеты

| Пакет | Версия | Секция | Особенности сборки |
|-------|--------|--------|---------------------|
| `libtsm` | 4.8.0 | `main` | Библиотека конечного автомата терминала для KMSCON |
| `kmscon` | 10.0.3 | `main` | DRM/KMS терминальный эмулятор, работает напрямую на Linux console без X11 |
| `wlroots` | 0.20.2 | `main` | `-Dbackends=drm,libinput -Dxwayland=disabled`, удалены все зависимости X11/xcb |
| `labwc` | 0.20.2 | `main` | `-Dxwayland=disabled`, легковесный Wayland-композитор с открытым API |
| `sfwbar` | 1.0~beta17 | `main` | Панель задач для Wayland compositors (wlr foreign toplevel + layer shell) |
| `mpv` | 0.41.0 | `main` | Чистый Wayland (`-Dx11=disabled -Dwayland=enabled`), вырезаны X11/Xv/VDPAU-X11 |
| `celluloid`| 0.30 | `main` | Графический GTK4-фронтенд для mpv с нативным Wayland |
| `fdk-aac` | 2.0.3 | `non-free` | Библиотека Fraunhofer FDK AAC |
| `pipewire` | 1.6.9 | `non-free` | Поддержка Bluetooth AAC-кодека через `libfdk-aac` (`-Dbluez5-codec-aac=enabled`), модуль X11 отключён |

---

## Подключение репозитория в Debian trixie

### 1. Скачайте и установите публичный GPG-ключ репозитория

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://crick-ru.github.io/debian/repo.gpg | sudo tee /etc/apt/keyrings/crick-wayland.gpg > /dev/null
```

*(Или текстовый ключ: `curl -fsSL https://crick-ru.github.io/debian/public.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/crick-wayland.gpg`)*

### 2. Добавьте репозиторий в источники APT

Создайте файл `/etc/apt/sources.list.d/crick-wayland.sources`:

```ini
Types: deb
URIs: https://crick-ru.github.io/debian
Suites: trixie
Components: main non-free
Signed-By: /etc/apt/keyrings/crick-wayland.gpg
```

Или в классическом формате `/etc/apt/sources.list.d/crick-wayland.list`:

```apt
deb [signed-by=/etc/apt/keyrings/crick-wayland.gpg] https://crick-ru.github.io/debian trixie main non-free
```

### 3. Обновите список пакетов и установите нужные программы

```bash
sudo apt update
sudo apt install labwc sfwbar mpv celluloid pipewire
```

---

## Структура проекта

- `packages/` — каталоги с Debian-рецептами упаковки (`debian/control`, `debian/rules`, `debian/changelog`, `debian/source/format`) для каждого пакета.
- `scripts/` — скрипты сборки и генерации репозитория:
  - `fetch-upstream.sh` — скачивание upstream-исходников и tarball.
  - `build-package.sh` — распаковка, наложение конфигураций, обновление changelog и вызов `dpkg-buildpackage`.
  - `generate-repo.sh` — сканирование собранных deb-пакетов, создание метаданных APT (`Packages`, `Packages.gz`, `Packages.xz`, `Release`, `InRelease`) и их подпись GPG.
- `.github/workflows/` — CI/CD пайплайны:
  - `build.yml` — матричная сборка пакетов в контейнере `debian:trixie`.
  - `pages.yml` — скачивание собранных `.deb`, подпись и публикация APT-репозитория на GitHub Pages.

---

## Автор и сопровождение

- **Maintainer**: crick <mail@crick.ru>
- **GitHub**: [crick-ru/debian](https://github.com/crick-ru/debian)
