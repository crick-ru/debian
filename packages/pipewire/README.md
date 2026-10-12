# pipewire

Сервер мультимедиа: аудио/видео-пайплайны, захват и воспроизведение, JACK/PulseAudio-совместимость.

## Источник упаковки

Упаковка взята из Debian (`pipewire_1.6.9-1`, ветка 1.6, `unstable`) и
перерабатывается. Tarball побайтово совпадает с Debian-овским
`pipewire_1.6.9.orig.tar.xz`.

## Версии

- **В trixie:** 1.4.8-1
- **В исходной упаковке:** 1.6.9-1
- **В нашем репозитории:** 1.6.9-3+crick (ревизия 3 — libmysofa выключена)

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libpipewire-0.3-0t64` | `libpipewire.so.0.3`, `libpipewire-module-*` |
| `libpipewire-0.3-common` | переводы, `client.conf` |
| `libpipewire-0.3-dev` | заголовки, `.pc` |
| `libpipewire-0.3-modules` | модули сервера и клиента |
| `libspa-0.2-dev` | заголовки SPA |
| `libspa-0.2-modules` | `libspa-0.2-*` (модули), включая `audiotestsrc`/`videotestsrc` |
| `pipewire` | метапакет |
| `pipewire-bin` | `pipewire`, `pw-*`, `pw-cli` |
| `pipewire-pulse` | PulseAudio-замена |
| `pipewire-alsa` | ALSA-мост |
| `pipewire-system-services` | системные systemd-юниты |
| `gstreamer1.0-pipewire` | GStreamer-плагин |
| `libspa-0.2-bluetooth` | Bluetooth-плагины |
| `pipewire-audio-client-libraries` | переходной пакет → `pipewire-alsa` |
| `pipewire-audio` | метапакет (alsa + pulse + bluetooth + wireplumber) |
| `wireplumber-system-services` | системные сервисы WirePlumber |

Не публикуются: `pipewire-jack`, `libspa-0.2-jack`, `pipewire-v4l2`,
`gir1.2-spa-0.2`, `gir1.2-pw-1.0`/`libpipewire-0.3-dev-doc`.

## Что изменено

### Отключено

- **X11:** `-Dx11=disabled -Dx11-xfixes=disabled`. Модули X11 не собираются.
- **JACK:** `-Djack=disabled`. Пакеты `pipewire-jack`, `libspa-0.2-jack` не
  публикуются. Модули `jack-tunnel`, `jackdbus-detect`, `netjack2` удаляются
  из `libpipewire-0.3-modules` в `override_dh_auto_install`.
- **V4L2:** `-Dv4l2=disabled`. Пакет `pipewire-v4l2` и spa-плагин `v4l2`
  не собираются. **В этом репозитории нет источника видео с камеры вообще**
  (ни через libcamera, ни через V4L2).
- **libcamera:** `-Dlibcamera=disabled`. В trixie libcamera 0.4.0, а
  pipewire 1.6.x требует >= 0.6.0 с controls-API 0.5+.
- **Avahi:** `-Davahi=disabled`. Модули `raop-discover`, `rtp-session`,
  `snapcast-discover`, `zeroconf-discover` не собираются. `libavahi-client-dev`
  удалён из `Build-Depends`.
- **ROC:** `-Droc=disabled`. `libroc-dev` удалён.
- **libmysofa:** `-Dlibmysofa=disabled`. HRTF-пространство звучания не
  используется клиентами (`mpv`, `sfwbar`). `libmysofa-dev` удалён.
  Отключение убирает ~7 пакетов с зависимостями.
- **ONNX Runtime:** `-Donnxruntime=disabled`. ML-фильтры spa
  `spa-filter-graph-plugin-onnx` не собираются. Отключение убирает 8 пакетов
  (~74 МБ): `libonnxruntime1.21`, `libonnx1t64`, `libdnnl3.6`,
  `libxnnpack0.20241108`, `libcpuinfo0`, `libpthreadpool0`, `libprotobuf32t64`,
  `libre2-11`.
- **Bluetooth-PLC на spandsp:** `-Dbluez5-plc-spandsp=disabled`.
  `libspandsp-dev` удалён (а `libspandsp2t64` больше не зависит от
  `libspa-0.2-bluetooth`). Для A2DP (музыка) не применяется.
- **SDL2:** `-Dsdl2=disabled`. Был нужен только для видео-примеров из
  `pipewire-tests`.
- **Vulkan:** `-Dvulkan=disabled`.
- **FFmpeg:** `-Dffmpeg=disabled`. (FFmpeg есть в репозитории, но pipewire
  не использует его напрямую.)
- **snap:** `-Dsnap=disabled` (не Ubuntu).
- **Документация и man-страницы:** `DOCS=disabled`, `MAN=disabled`.
  Из `Build-Depends` удалены `doxygen`, `graphviz`, `python3-docutils`.
- **Тесты:** `-Dtest=disabled`. Каталог `debian/tests` удалён.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- **Bluetooth-кодеки:** AAC (через `libfdk-aac`), aptX, LDAC, Opus, SBC.
  `libfdk-aac-dev` — из этого репозитория (см. `packages/fdk-aac/README.md`).
- **ALSA-мост:** `pipewire-alsa`.
- **libffado и LV2:** `-Dlibffado=enabled -Dlv2=enabled`.
- **systemd:** пользовательские, системные и logind-интеграция.
- **Аудио/видео тестовые источники:** `-Daudiotestsrc=enabled -Dvideotestsrc=enabled`.
- **Бификсация BlueZ5:** native-neteq, AAC, aptX, LDAC, Opus.

## Патчи

Один патч Debian сохранён: `0001-CVE-2026-14330.patch` — переносит апстрим-
исправление уязвимости CVE-2026-14330 (`spa_alloca` с проверками переполнения
и лимитов).

## Изменения ABI

`libpipewire.so.0.3` — SONAME не меняется, удалённых символов нет (все
отключённые функции — модули, а не экспорт в библиотеку).

## Важные нюансы

### Зачем нужен

Звук в этом репозитории работает через `pipewire` + `wireplumber`.
`pwvucontrol` требует `libpipewire-0.3-dev`, `libpulse-dev` (mpv, sfwbar)
работают через PulseAudio-совместимость (`pipewire-pulse`). ALSA → `pipewire-alsa`.

### libfdk-aac из репозитория

`libfdk-aac-dev` берётся из этого репозитория (см. `packages/fdk-aac/README.md`).
`pipewire` использует его для Bluetooth AAC, а `pipewire` публикует
`libspa-0.2-bluetooth`, который имеет `libfdk-aac2t64` в `NEEDED` — поэтому
версии `libfdk-aac2` и `libfdk-aac-dev` обязаны совпадать (суффикс `+crick`).

### apt upgrade

Пакеты из trixie заменяются нашими: `pipewire*`, `libspa-0.2-*` (имена те же,
версия выше). `gstreamer1.0-libav` и `gstreamer1.0-plugins-*` из того же
источника — тоже.

Проверить:
```
apt-get -s upgrade
```
