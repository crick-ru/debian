# crick Debian backports

Новые версии пакетов для **Debian 13 (trixie, amd64)**.

Репозиторий собран по трём правилам, которые действуют для **всех** пакетов
(подробности — в `.clinerules/project.md`, в `repo/`):

1. **Ничего лишнего не собирается:** ни документации (включая man-страницы,
   генерируемые из docbook/rst/scdoc), ни примеров, ни тестов. Пакеты
   `*-doc`, `*-examples`, `*-tests` и `installed-tests` не публикуются,
   тестовые сьюты не собираются и не запускаются.
2. **X11 нет нигде:** ни одной зависимости от `libX11`, `libXext`,
   `libXrender`, `libxcb*`, `x11proto-dev`, Xwayland — ни в `Build-Depends`,
   ни в собранных библиотеках. Даже `libxkbcommon-x11` не публикуется.
3. **Оптические диски, DVB-тюнеры и VDPAU не поддерживаются.** Аппаратное
   ускорение там, где оно не устарело: VA-API и NVDEC/NVENC работают.

Цена второго правила — **два намеренных нарушения ABI** (SONAME сохранён,
символы удалены): у GTK 3/4 и у `cairo`. Разбор — в README каждого
пакета.

## Состав

| Пакет | | Версия | Особенности |
|---|---|---|---|
| **Графический стек** | | | |
| `wayland` | [🔗](packages/wayland/README.md) | 1.26.0 | базовая библиотека Wayland |
| `libdrm` | [🔗](packages/libdrm/README.md) | 2.4.134 | управление DRM, без X11 |
| `libxkbcommon` | [🔗](packages/libxkbcommon/README.md) | 1.13.1 | **без X11-части** — это ломает состав системы |
| `pixman` | [🔗](packages/pixman/README.md) | 0.46.4 | растеризация 2D |
| `wayland-protocols` | [🔗](packages/wayland-protocols/README.md) | 1.47 | протоколы Wayland |
| `cairo` | [🔗](packages/cairo/README.md) | 1.18.6 | **Xlib/XCB вырезаны, ломается ABI** |
| `gtk+3.0` | [🔗](packages/gtk+3.0/README.md) | 3.24.52 | **только Wayland, ломается ABI** |
| `gtk4` | [🔗](packages/gtk4/README.md) | 4.22.5 | **только Wayland, ломается ABI** |
| `wlroots` | [🔗](packages/wlroots/README.md) | 0.20.2 | библиотека композитора, без Xwayland |
| `labwc` | [🔗](packages/labwc/README.md) | 0.20.2 | Wayland-композитор |
| **Медиастек** | | | |
| `ffmpeg` | [🔗](packages/ffmpeg/README.md) | 9.0.2 | **epoch 7**; без X11, дисков, DVB и VDPAU |
| `gstreamer1.0` | [🔗](packages/gstreamer1.0/README.md) | 1.28.7 | ядро GStreamer |
| `gstreamer1.0-plugins-base` | [🔗](packages/gstreamer1.0-plugins-base/README.md) | 1.28.7 | конвейер воспроизведения, GL только под Wayland |
| `gstreamer1.0-plugins-good` | [🔗](packages/gstreamer1.0-plugins-good/README.md) | 1.28.7 | Matroska, VP8/VP9, FLAC; без видеосинков Qt и GTK |
| `gstreamer1.0-plugins-bad` | [🔗](packages/gstreamer1.0-plugins-bad/README.md) | 1.28.7 | аппаратное декодирование; **без X11 и wpe** |
| `gstreamer1.0-libav` | [🔗](packages/gstreamer1.0-libav/README.md) | 1.28.7 | мост к нашему FFmpeg |
| `mpv` | [🔗](packages/mpv/README.md) | 0.41.0 | чистый Wayland; без X11, дисков, DVB и VDPAU |
| `celluloid` | [🔗](packages/celluloid/README.md) | 0.29 | GTK 4-фронтенд для mpv |
| **Аудио и терминал** | | | |
| `pipewire` | [🔗](packages/pipewire/README.md) | 1.6.9 | Bluetooth AAC; X11, JACK, V4L2 и libcamera отключены |
| `wireplumber` | [🔗](packages/wireplumber/README.md) | 0.5.17 | сессионный менеджер PipeWire; в trixie только 0.5.8 |
| `pwvucontrol` | [🔗](packages/pwvucontrol/README.md) | 0.5.3 | регулятор громкости на GTK 4 + Rust; **нет в Debian** |
| `fdk-aac` | [🔗](packages/fdk-aac/README.md) | 2.0.3 | AAC-кодек для pipewire |
| `libtsm` | [🔗](packages/libtsm/README.md) | 4.8.0 | конечный автомат терминала для KMSCON |
| `kmscon` | [🔗](packages/kmscon/README.md) | 10.0.3 | терминальный эмулятор на DRM/KMS, без X11 |
| `sfwbar` | [🔗](packages/sfwbar/README.md) | 1.0~beta17 | панель задач для Wayland-композиторов |
| **Графика** | | | |
| `imagemagick` | [🔗](packages/imagemagick/README.md) | 7.1.2-32 | **epoch 8**, только Q16, **без X11**; снимает часть пакетов trixie |

### Что ломает состав системы

Три пакета удаляют то, что есть в trixie, и это нужно понимать до `apt upgrade`:

- **`libxkbcommon` собран без X11-части** (`-Denable-x11=false`): пакетов
  `libxkbcommon-x11-0`/`-dev` в репозитории нет, поэтому штатный
  `libxkbcommon-x11-0` будет снят вместе со всем, что от него зависит
  (Qt-приложения, `libmutter-16-0` и далее). Собственный
  `libgstreamer-plugins-bad1.0-0` этого репозитория от `libxkbcommon-x11-0`
  не зависит — он собран с `-Dx11=disabled`, и в GStreamer 1.28.7
  `libxkbcommon` встречается только в плагине `wpe` и в окне XCB плагина
  `vulkan`, а оба выключены. Проверка: `apt-get -s upgrade`, разбор — в
  `packages/libxkbcommon/README.md`.
- **GTK 3 и GTK 4 собраны без X11** (только Wayland-бэкенд): при неизменном
  SONAME из `libgtk-3.so.0` удалено 101 символ, из `libgtk-4.so.1` — 81
  (все `gdk_x11_*`, `gdk_broadway_*` и часть X11-only API). Приложения,
  зовущие X11-API GTK напрямую, после `apt upgrade` падают; порядок отката —
  в README каждого пакета.
- **`cairo` собран без Xlib/XCB** (`-Dxlib=disabled -Dxcb=disabled
  -Dxlib-xcb=disabled`): при неизменном SONAME `libcairo.so.2` удалены 26
  публичных функций `cairo_xlib_*` и `cairo_xcb_*`. Реально ломаются GTK 2
  и `libghc-gi-gdkx11-dev`; GTK 3/4 и labwc используют только
  `cairo_image_surface_*` и `cairo_create`.
- **`imagemagick` снимает часть своего набора из trixie.** Мы не публикуем
  PerlMagick, Magick++ и переходные метапакеты: их триксийские версии пинят
  точную версию `imagemagick-7-common` и `-dev`-пакетов своей сборки, поэтому
  автоматически снимаются `libimage-magick-perl`, `libimage-magick-q16-perl`,
  `libmagick++-7-headers`, `libmagick++-7.q16-dev`, `libmagickcore-dev`,
  `libmagickwand-dev`, `libmagick++-dev`, `perlmagick` и
  `libmagickcore-7.q16-10-extra`. Все кодировщики и фильтры при этом входят
  в `libmagickcore-7.q16-10`, так что поддержка форматов не теряется.
  Проверка: `apt-get -s upgrade`, разбор — в `packages/imagemagick/README.md`.

### Отключённые аппаратные и форматные возможности

- **Оптические диски и DVB-тюнеры**: у `mpv` выключены CD, DVD, Blu-ray и
  `dvbin`, у `ffmpeg` — `libcdio`, `libbluray`, `libdvdnav`, `libdvdread` и
  `--disable-v4l2-m2m`, у GStreamer — `cdparanoia`, `dvb` и `dvdnav`.
- **VDPAU** отключён везде: у `mpv` (`-Dvdpau=disabled`), у `ffmpeg`
  (`--disable-vdpau`). В GStreamer плагина vdpau в 1.28.7 нет. VA-API и
  NVDEC/NVENC работают.
- Man-страниц нет ни у одного пакета, кроме готовых, приходящих в tar-боле.

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

