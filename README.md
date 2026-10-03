# crick Debian backports

Новые версии пакетов для **Debian 13 (trixie, amd64)**.

Репозиторий собран по трём правилам, которые действуют для **всех** пакетов
(что именно отключено и как откатить — в README каждого пакета):

1. **Ничего лишнего не собирается:** ни документации (включая man-страницы,
   генерируемые из docbook/rst/scdoc), ни примеров, ни тестов. Пакеты
   `*-doc`, `*-examples`, `*-tests` и `installed-tests` не публикуются,
   тестовые сьюты не собираются и не запускаются. Примеры конфигурационных
   файлов при этом сохраняются.
2. **X11 нет нигде:** ни одной зависимости от `libX11`, `libXext`,
   `libXrender`, `libxcb*`, `x11proto-dev`, Xwayland — ни в `Build-Depends`,
   ни в собранных библиотеках. Даже `libxkbcommon-x11` не публикуется.
3. **Оптические диски, DVB-тюнеры и VDPAU не поддерживаются.** Аппаратное
   ускорение там, где оно не устарело: VA-API и NVDEC/NVENC работают.

Цена второго правила — **два намеренных нарушения ABI** (SONAME сохранён,
символы удалены): у GTK 3/4 и у `cairo`. Разбор и порядок отката — в README
соответствующего пакета.

## Состав

| Пакет | | Версия | Особенности |
|---|---|---|---|
| **Графический стек** | | | |
| `wayland` | [🔗](packages/wayland/README.md) | 1.26.0 | базовая библиотека Wayland |
| `libdrm` | [🔗](packages/libdrm/README.md) | 2.4.134 | управление DRM, без X11 |
| `libxkbcommon` | [🔗](packages/libxkbcommon/README.md) | 1.13.1 | **без X11-части** — это ломает состав системы |
| `pixman` | [🔗](packages/pixman/README.md) | 0.46.4 | растеризация 2D |
| `wayland-protocols` | [🔗](packages/wayland-protocols/README.md) | 1.47 | протоколы Wayland |
| `mesa` | [🔗](packages/mesa/README.md) | 26.1.6 | драйверы GL/Vulkan **без X11**; от них зависит `neatvnc` |
| `cairo` | [🔗](packages/cairo/README.md) | 1.18.6 | **Xlib/XCB вырезаны, ломается ABI** |
| `gtk+3.0` | [🔗](packages/gtk+3.0/README.md) | 3.24.52 | **только Wayland, ломается ABI** |
| `gtk4` | [🔗](packages/gtk4/README.md) | 4.22.5 | **только Wayland, ломается ABI** |
| `wlroots` | [🔗](packages/wlroots/README.md) | 0.20.2 | библиотека композитора, без Xwayland |
| `labwc` | [🔗](packages/labwc/README.md) | 0.20.2 | Wayland-композитор |
| `sfwbar` | [🔗](packages/sfwbar/README.md) | 1.0~beta17 | панель задач для Wayland-композиторов |
| **Медиастек** | | | |
| `ffmpeg` | [🔗](packages/ffmpeg/README.md) | 9.0.2 | **epoch 7**; без X11, дисков, DVB и VDPAU |
| `gstreamer1.0` | [🔗](packages/gstreamer1.0/README.md) | 1.28.7 | ядро GStreamer |
| `gstreamer1.0-plugins-base` | [🔗](packages/gstreamer1.0-plugins-base/README.md) | 1.28.7 | конвейер воспроизведения, GL только под Wayland |
| `gstreamer1.0-plugins-good` | [🔗](packages/gstreamer1.0-plugins-good/README.md) | 1.28.7 | Matroska, VP8/VP9, FLAC; без X11, видеосинков Qt и GTK, PulseAudio и V4L2 |
| `gstreamer1.0-plugins-bad` | [🔗](packages/gstreamer1.0-plugins-bad/README.md) | 1.28.7 | аппаратное декодирование; **без X11 и wpe** |
| `gstreamer1.0-libav` | [🔗](packages/gstreamer1.0-libav/README.md) | 1.28.7 | мост к нашему FFmpeg |
| `mpv` | [🔗](packages/mpv/README.md) | 0.41.0 | чистый Wayland; без X11, дисков, DVB и VDPAU |
| `celluloid` | [🔗](packages/celluloid/README.md) | 0.29 | GTK 4-фронтенд для mpv |
| **Аудио** | | | |
| `pipewire` | [🔗](packages/pipewire/README.md) | 1.6.9 | Bluetooth AAC; X11, JACK, V4L2 и libcamera отключены |
| `wireplumber` | [🔗](packages/wireplumber/README.md) | 0.5.17 | сессионный менеджер PipeWire; в trixie только 0.5.8 |
| `pwvucontrol` | [🔗](packages/pwvucontrol/README.md) | 0.5.3 | регулятор громкости на GTK 4 + Rust; **нет в Debian** |
| `fdk-aac` | [🔗](packages/fdk-aac/README.md) | 2.0.3 | AAC-кодек для pipewire |
| `pulseaudio` | [🔗](packages/pulseaudio/README.md) | 17.0 | **только клиентские библиотеки**, демон не публикуется |
| **Терминал** | | | |
| `libtsm` | [🔗](packages/libtsm/README.md) | 4.8.0 | конечный автомат терминала для KMSCON |
| `kmscon` | [🔗](packages/kmscon/README.md) | 10.0.3 | терминальный эмулятор на DRM/KMS, без X11 |
| **Графика** | | | |
| `imagemagick` | [🔗](packages/imagemagick/README.md) | 7.1.2-32 | **epoch 8**, только Q16, **без X11**; снимает часть пакетов trixie |
| `libheif` | [🔗](packages/libheif/README.md) | 1.23.4 | минимальный набор (libheif1 + libheif-dev) ради кодировщика HEIF |
| **Удалённый доступ** | | | |
| `aml` | [🔗](packages/aml/README.md) | 1.0.0 | цикл событий, нужен `neatvnc` и `wayvnc` |
| `neatvnc` | [🔗](packages/neatvnc/README.md) | 1.0.1 | библиотека VNC-сервера |
| `wayvnc` | [🔗](packages/wayvnc/README.md) | 0.10.1 | VNC-сервер для wlroots-композиторов (в т. ч. к `labwc`) |

### Что ломает состав системы

Часть пакетов меняет состав системы, и это нужно понимать до `apt upgrade`:

- **`libxkbcommon` собран без X11-части** (`-Denable-x11=false`): пакетов
  `libxkbcommon-x11-0`/`-dev` в репозитории нет, поэтому штатный
  `libxkbcommon-x11-0` будет снят вместе со всем, что от него зависит
  (Qt-приложения, `libmutter-16-0` и далее). Проверка `apt-get -s upgrade` и
  полный разбор — в `packages/libxkbcommon/README.md`.
- **GTK 3 и GTK 4 собраны без X11** (только Wayland-бэкенд): при неизменном
  SONAME из библиотек удалены символы `gdk_x11_*`, `gdk_broadway_*` и часть
  X11-only API. Приложения, зовущие X11-API GTK напрямую, после `apt upgrade`
  падают; порядок отката — в `packages/gtk+3.0/README.md` и
  `packages/gtk4/README.md`.
- **`cairo` собран без Xlib/XCB** (`-Dxlib=disabled -Dxcb=disabled`): при
  неизменном SONAME удалены публичные функции `cairo_xlib_*`/`cairo_xcb_*`.
  Реально ломаются GTK 2 и `libghc-gi-gdkx11-dev`; разбор — в
  `packages/cairo/README.md`.
- **`imagemagick` снимает часть своего набора из trixie** (PerlMagick,
  Magick++ и переходные метапакеты): их версии из trixie пинят точную версию
  `imagemagick-7-common`, поэтому эти пакеты устанавливаются из нашего набора
  автоматически. Проверка `apt-get -s upgrade`, разбор — в
  `packages/imagemagick/README.md`.
- **`pulseaudio` публикуется только как клиентская библиотека и без X11**:
  наш `libpulse0` не зависит от `libx11-6`, `libx11-xcb1` и `libxcb1`, как
  штатный. Демон `pulseaudio`, `pulseaudio-utils` и модули не публикуются —
  звуковый сервер здесь `pipewire`. Разбор — в
  `packages/pulseaudio/README.md`.
- **`mesa` собрана без X11**: `libegl-mesa0`, `libgbm1` и `mesa-libgallium`
  заменяются нашими и перестают тянуть `libx11-xcb1`, `libxcb-*` и `libxshmfence1`.
  `libgl1-mesa-dri` (X11-обёртка для GLX) и `libglx-mesa0` не публикуются:
  настоящий DRI-драйвер — `libgallium-*.so` внутри `mesa-libgallium`, и
  `libEGL_mesa` зависит от него напрямую. Штатный `libgl1-mesa-dri` при этом
  остаётся установленным, а штатный `libglx-mesa0` будет снят — его пин на
  `mesa-libgallium` нечем удовлетворить. VDPAU и OpenCL выключены, VA-API
  оставлен. Разбор — в `packages/mesa/README.md`.
- **`libheif` публикуется как два пакета с плагинами кодеков внутри
  `libheif1`**, поэтому плагины trixie (`libheif-plugin-*`) будут сняты: они
  пинят точную версию `libheif1`, которой у нас нет. Разбор — в
  `packages/libheif/README.md`.
- **`libaml1` и `libneatvnc1` — новые имена**: в trixie те же библиотеки
  называются `libaml0t64` и `libneatvnc0`, поэтому старые пакеты останутся
  установленными как неиспользуемые (убрать через `apt autoremove`).
  Разбор — в `packages/aml/README.md` и `packages/neatvnc/README.md`.

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

