# pipewire (crick Debian backports)

Сборка `pipewire` 1.6.9 для Debian 13 (trixie), оптимизированная под чистое
Wayland-окружение без компонентов, не нужных на обычной рабочей станции.

## Включено

- Bluetooth-кодеки: **AAC** (через `libfdk-aac` из этого репозитория), aptX,
  LC3, LDAC, Opus, SBC, плюс `bluez5-plc-spandsp`.
- ALSA-мост и сетевое обнаружение: `pipewire-alsa`, `-Davahi=enabled`.
- Поддержка `libffado`, `libmysofa`, ROC, LV2, ONNX Runtime (шумоподавление на ML).
- Пользовательские **и** системные службы WirePlumber (`pipewire-system-services`).
- Документация и справочные страницы man.

## Отключено

- **X11** (`-Dx11=disabled -Dx11-xfixes=disabled`): модули X11 не собираются,
  зависимостей от X11 в пакетах нет.
- **JACK** (`-Djack=disabled`): пакеты `pipewire-jack` и `libspa-0.2-jack` не
  собираются; модули моста `jack-tunnel`, `jackdbus-detect` и `netjack2`
  исключены из `libpipewire-0.3-modules`. Приложениям JACK требуется реальный
  JACK-сервер (например, `jackd2` из дистрибутива).
- **V4L2** (`-Dv4l2=disabled`): пакет `pipewire-v4l2` и spa-плагин `v4l2` не
  собираются.
- **libcamera** (`-Dlibcamera=disabled`): в Debian trixie поставляется
  libcamera 0.4.0, тогда как pipewire 1.6.x требует >= 0.6.0 с новым
  controls-API — сборка плагина невозможна.
- **Тестовый набор и примеры** (`pipewire-tests`): пакет полностью исключён из
  сборки, опция `-Dinstalled_tests=disabled`. Библиотека SDL2 требовалась
  только для видео-примеров из этого набора, поэтому `-Dsdl2=disabled`, а
  `libsdl2-dev` убран из сборочных зависимостей.
- Vulkan, FFmpeg, snap, LC3plus, декодер LDAC.

**Следствие:** в этой сборке pipewire нет источников видео с камеры вообще
(ни через libcamera, ни через V4L2).

## Изменено

- Патч `0001-CVE-2026-14330.patch` переносит апстрим-исправление уязвимости
  CVE-2026-14330 (`spa_alloca` с проверками переполнения и лимитов).
- `pipewire-audio-client-libraries` оставлен только как переходный метапакет
  для `pipewire-alsa`.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

