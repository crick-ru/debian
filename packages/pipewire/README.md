# pipewire (crick Debian backports)

Сборка `pipewire` 1.6.9 для Debian 13 (trixie), оптимизированная под чистое
Wayland-окружение без компонентов, не нужных на обычной рабочей станции.

## Включено

- Bluetooth-кодеки: **AAC** (через `libfdk-aac` из этого репозитория), aptX,
  LC3, LDAC, Opus, SBC.
- ALSA-мост и сетевое обнаружение: `pipewire-alsa`, `-Davahi=enabled`.
- Поддержка `libffado`, `libmysofa`, ROC, LV2.
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
- **ONNX Runtime** (`-Donnxruntime=disabled`): ML-фильтры в
  `filter-graph` (шумоподавление, VAD по нейросетевым моделям) не собираются,
  плагина `spa-filter-graph-plugin-onnx` в `libspa-0.2-modules` нет. Отказ от
  него убирает из системы 8 пакетов (около 74 МБ): `libonnxruntime1.21`,
  `libonnx1t64`, `libdnnl3.6`, `libxnnpack0.20241108`, `libcpuinfo0`,
  `libpthreadpool0`, `libprotobuf32t64`, `libre2-11`.
- **Bluetooth-PLC на spandsp** (`-Dbluez5-plc-spandsp=disabled`): сокрытие
  потерь пакетов в голосовом профиле HFP (mSBC) апстрим реализует через
  `spandsp`; без неё остаются встроенные заглушки, которые просто не
  маскируют потери, но не ломают кодек. Поле `libspandsp-dev` убрано из
  сборочных зависимостей, а `libspandsp2t64` (он же тянет `libtiff6`) больше
  не является зависимостью `libspa-0.2-bluetooth`. Для A2DP (музыка) этот
  алгоритм не применяется.

**Следствие:** в этой сборке pipewire нет источников видео с камеры вообще
(ни через libcamera, ни через V4L2).

## Изменено

- Патч `0001-CVE-2026-14330.patch` переносит апстрим-исправление уязвимости
  CVE-2026-14330 (`spa_alloca` с проверками переполнения и лимитов).
- `pipewire-audio-client-libraries` оставлен только как переходный метапакет
  для `pipewire-alsa`.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

