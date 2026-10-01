# mpv (crick Debian backports)

Сборка `mpv` 0.41.0 для Debian 13 (trixie), собранная как чисто Wayland-проигрыватель.
Пакеты не содержат библиотек X11 — этим сборка отличается от пакетного дистрибутива.

## Включено

- Вывод и ввод через Wayland: `-Dwayland=enabled`, `-Degl-wayland=enabled`.
- Рендеринг через GPU без копирования: `-Ddmabuf-wayland=enabled`.
- Аппаратное декодирование через VA-API под Wayland: `-Dvaapi-wayland=enabled`.
- Клиентская библиотека libmpv: `-Dlibmpv=true` (нужна `celluloid`).

## Отключено

- **Оптические диски**: `-Dcdda=disabled` (CD-аудио), `-Ddvdnav=disabled`
  (навигация по DVD), `-Dlibbluray=disabled` (Blu-ray), `-Dlibarchive=disabled`
  (движок чтения BD/ISO, который нужен только libbluray). Из `Build-Depends`
  и из `Depends` пакета `libmpv-dev` убраны `libcdio-dev`,
  `libcdio-paranoia-dev`, `libdvdnav-dev`, `libbluray-dev` и `libarchive-dev`
  (по правилам проекта).
- **DVB-тюнеры**: `-Ddvbin=disabled`. У этой опции не было внешних библиотек
  (только заголовок `linux/dvb/frontend.h`), и она была единственной,
  требовавшей блок `ARCH_CONFIGURE` в `debian/rules`; блок удалён вместе с
  ней, как и `include /usr/share/dpkg/architecture.mk`.
- **VDPAU**: `-Dvdpau=disabled`, `-Dvdpau-gl-x11=disabled`. Вторая опция и так
  была выключена из-за `-Dx11=disabled`, но задана явно (по правилам проекта).
- **JACK**: `-Djack=disabled`. Аудио выводится через pipewire (ALSA, Pulse и
  sndio остаются); JACK-клиент собирать нечего без JACK-сервера, поэтому
  `libjack-dev` убран и из `Build-Depends`, и из `Depends` пакета `libmpv-dev`
  (по правилам проекта).
- **X11 и все бэкенды X11**: `-Dx11=disabled`, `-Degl-x11=disabled`,
  `-Dgl-x11=disabled`, `-Dvaapi-x11=disabled`,
  `-Dxv=disabled`, `-Dx11-clipboard=disabled`. Пакеты `mpv` и `libmpv2` не
  объявляют зависимостей `libx11*`, поэтому библиотеки вроде `libxpresent1`
  не ставятся.
- Man-страница, HTML и PDF не генерируются из `DOCS/man/mpv.rst`
  (`-Dmanpage-build=false`), поэтому убран `python3-docutils` (нужен был для
  `rst2man`). Готовых man-страниц в tar-боле нет, так что `man mpv`
  не документирован — это осознанная плата за правило «документация не
  собирается».
- Тесты не собираются и не запускаются (`-Dtests=false`).

## Изменено

- Версия: `0.41.0-3+crick` (ревизия 2 — переработка упаковки Debian, 3 —
  отключение оптических дисков, DVB-тюнеров и VDPAU).
- Собирается против FFmpeg 9.0.2 этого репозитория (стадия 1 CI), а не
  против версии из trixie: `libavcodec-dev (>= 7:7.0)` закрывает только
  сборка с epoch 7.
- `-Dbuild-date=false` для воспроизводимости сборки (без временных меток).
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

