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
| `wlroots` | 0.20.2 | `main` | **временно отключён** (сборка падает), сборка возобновляется после разбора ошибки |
| `labwc` | 0.20.2 | `main` | **временно отключён** вместе с `wlroots`, от которого зависит |
| `sfwbar` | 1.0~beta17 | `main` | Панель задач для Wayland compositors (wlr foreign toplevel + layer shell) |
| `mpv` | 0.41.0 | `main` | Чистый Wayland (`-Dx11=disabled -Dwayland=enabled`), вырезаны X11/Xv/VDPAU-X11 |
| `celluloid`| 0.30 | `main` | Графический GTK4-фронтенд для mpv с нативным Wayland |
| `fdk-aac` | 2.0.3 | `non-free` | Библиотека Fraunhofer FDK AAC |
| `pipewire` | 1.6.9 | `non-free` | Поддержка Bluetooth AAC-кодека через `libfdk-aac` (`-Dbluez5-codec-aac=enabled`), модуль X11 отключён, плагин libcamera не собирается (в trixie libcamera 0.4.0, pipewire требует 0.6.0) — камера доступна через `pipewire-v4l2` |

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
sudo apt install sfwbar mpv celluloid pipewire
```

---

## Структура проекта

- `packages/` — каталоги с Debian-рецептами упаковки (`debian/control`, `debian/rules`, `debian/changelog`, `debian/source/format`) для каждого пакета.
- `scripts/` — скрипты сборки и генерации репозитория:
  - `fetch-upstream.sh` — скачивание upstream-исходников и tarball.
  - `build-package.sh` — распаковка, наложение конфигураций, обновление changelog и вызов `dpkg-buildpackage`.
  - `generate-repo.sh` — сканирование собранных deb-пакетов, создание метаданных APT (`Packages`, `Packages.gz`, `Packages.xz`, `Release`, `InRelease`) и их подпись GPG.
- `.github/workflows/` — CI/CD пайплайн (`build.yml`), три стадии в контейнере `debian:trixie`:
  - **Stage 1** — пакеты без внутренних зависимостей (`fdk-aac`, `libtsm`, `mpv`; `wlroots` временно отключён), сборка по матрице, `.deb` сохраняются как артефакты;
  - **Stage 2** — пакеты, зависящие от библиотек Stage 1 (`kmscon`, `pipewire`, `celluloid`, `sfwbar`; `labwc` временно отключён вместе с `wlroots`): скачивание `.deb` Stage 1, установка и сборка;
  - **Stage 3** — слияние пула всех пакетов, генерация метаданных APT (`generate-repo.sh`) и публикация на GitHub Pages (без Stage 3 для pull request).

---

## Автор и сопровождение

- **Maintainer**: crick <mail@crick.ru>
- **GitHub**: [crick-ru/debian](https://github.com/crick-ru/debian)
