# mpv (crick Debian backports)

Сборка `mpv` 0.41.0 для Debian 13 (trixie), собранная как чисто Wayland-проигрыватель.
Пакеты не содержат библиотек X11 — этим сборка отличается от пакетного дистрибутива.

## Включено

- Вывод и ввод через Wayland: `-Dwayland=enabled`, `-Degl-wayland=enabled`.
- Рендеринг через GPU без копирования: `-Ddmabuf-wayland=enabled`.
- Аппаратное декодирование через VA-API под Wayland: `-Dvaapi-wayland=enabled`.
- Клиентская библиотека libmpv: `-Dlibmpv=true` (нужна `celluloid`).
- Оптические диски и дополнительно: `-Dcdda=enabled`, `-Ddvdnav=enabled`,
  `-Ddvbin=enabled` на Linux.

## Отключено

- **X11 и все бэкенды X11**: `-Dx11=disabled`, `-Degl-x11=disabled`,
  `-Dgl-x11=disabled`, `-Dvaapi-x11=disabled`, `-Dvdpau-gl-x11=disabled`,
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

- Версия: `0.41.0-2+crick` (ревизия 2 — из-за переработки упаковки).
- `-Dbuild-date=false` для воспроизводимости сборки (без временных меток).
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

