# pulseaudio

Клиентская библиотека PulseAudio (`libpulse0`, `libpulse-mainloop-glib0`,
`libpulse-dev`).

## Источник упаковки

Упаковка взята из Debian (`pulseaudio_17.0+dfsg1-2`, trixie) и перерабатывается.
Tarball побайтово совпадает с Debian-овским `pulseaudio_17.0+dfsg1.orig.tar.xz`
(перепаковка `+dfsg1` сохранена — Debian удаляет не-DFSG биты из апстрима).

## Версии

- **В trixie:** 17.0+dfsg1-2+b1
- **В исходной упаковке:** 17.0+dfsg1-2
- **В нашем репозитории:** 17.0+dfsg1-2+crick (ревизия 2)

Ревизия 2 важна: штатная версия trixie `17.0+dfsg1-2+b1`, а наша `17.0+dfsg1-1+crick`
была бы старее (`-1 < -2`). Суффикс `+crick` сравнивается с `+b1` как большей.

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libpulse0` | `libpulse.so.0`, `libpulse-simple.so.0`, `libpulsecommon-17.0.so`, `client.conf`, переводы |
| `libpulse-mainloop-glib0` | `libpulse-mainloop-glib.so.0` |
| `libpulse-dev` | заголовки, `.pc`, CMake, Vala VAPI |

Не публикуются: `pulseaudio` (демон), `pulseaudio-utils` (`pactl`, `pacat`,
`paplay` и т.д.), `pulseaudio-equalizer`, `pulseaudio-module-*`, `libpulsedsp`/`padsp`.

## Что изменено

### Отключено

- **Демон:** `-Ddaemon=false`. Не собираются пакеты `pulseaudio`,
  `pulseaudio-utils`, `pulseaudio-equalizer`, `pulseaudio-module-*`,
  `libpulsedsp`. Из `Build-Depends` удалены ALSA, Bluetooth, GStreamer, LIRC,
  RAOP/OpenSSL, ресемплеры (soxr/speex), FFTW, orc, avahi, udev, tcpwrap,
  WebRTC/adrian AEC, GSettings.
- **X11:** `-Dx11=disabled`. Штатный `libpulse0` из trixie зависит от
  `libx11-6`, `libx11-xcb1`, `libxcb1` — это нарушает правило репозитория
  «X11 нет нигде». Ни один экспортируемый символ не удаляется:
  `pa_client_conf_from_x11()` нужен только для автозапуска `pax11publish`.
- **JACK:** `-Djack=disabled`.
- **libpulsedsp:** `-Doss-output=disabled` (OSS-обёртка для устаревших программ).
- **Man-страницы:** `-Dman=false`. **doxygen:** `-Ddoxygen=false`.
- **Тесты:** `-Dtests=false`.
- **GTK:** `-Dgtk=disabled`.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- **Клиент:** `-Dclient=true`. `libpulse0` использует `libasyncns`, `libdbus`,
  `libglib`, `libsndfile`, `libsystemd`.
- **GLib-поддержка:** `-Dglib=enabled` (`libpulse-mainloop-glib0`).
- **D-Bus:** `-Ddbus=enabled`.
- **systemd:** `-Dsystemd=enabled`.
- **ASи:** `-Dasyncns=enabled`.
- **IPv6:** `-Dipv6=true`.

## Патчи

Пять патчей Debian: `disable-autospawn.patch`,
`selectively-disable-libpulsedsp.patch`, `git_tests_alignment.patch`,
`ucm-check-verb-for-device-status.patch`,
`ucm-replace-context-assertion-with-error.patch`,
`ucm-fix-infinite-recursion.patch`.

## Изменения ABI

`libpulse.so.0` — SONAME не меняется. `libpulse0.symbols` и
`libpulse-mainloop-glib0.symbols` из Debian используются как есть.
Удалённых символов нет: `pa_client_conf_from_x11()` есть в таблице символов,
но не линкуется (отсутствует в `NEEDED`).

## Важные нюансы

### Зачем нужен

`mpv` (звуковой вывод `ao_pulse`) и `sfwbar` (модуль `pulsectl.c`) собираются
против `libpulse-dev`. Это единственные потребители в репозитории.

### Как работает звук

Настоящий звуковой сервер — `pipewire` + `wireplumber` (см.
`packages/pipewire/`, `packages/wireplumber/`). PulseAudio здесь — только
клиентские библиотеки для приложений, которые используют PulseAudio-интерфейс
(mpv, sfwbar). `pipewire-pulse` предоставляет совместимость на стороне сервера.

### Клиентские утилиты

Утилиты (`pactl`, `pacat`, `paplay` и т.д.) собираются апстримом
(`-Dclient=true`), но удаляются из дерева установки в `override_dh_auto_install`
вместе с автодополнением bash/zsh: нужны библиотеки, а не утилиты. Если
нужен `pactl` — ставьте его из trixie: он работает с нашим `libpulse0`,
поскольку SONAME не менялся.

### apt upgrade

Штатный `libpulse0` из trixie снимается: он зависит от X11-библиотек, которые
в этом репозитории не публикуются. Проверить: `apt-get -s upgrade`.
