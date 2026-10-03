# pulseaudio (crick Debian backports)

Клиентская часть `PulseAudio` 17.0 для Debian 13 (trixie, amd64).
**Демон не собирается и не публикуется.**

Версия: `17.0+dfsg1-2+crick`.

Упаковка взята из Debian (`pulseaudio_17.0+dfsg1-2`) и переработана.

## Почему свой PulseAudio

`mpv` (звуковой выход `ao_pulse`) и `sfwbar` (модуль `pulsectl.c`) собираются
против `libpulse-dev`. Штатный `libpulse0` в trixie тянет X11:

```
libpulse0  Depends: libx11-6, libx11-xcb1, libxcb1
```

Это прямо нарушает правило репозитория «X11 нет нигде». Наш клиент собран
с `-Dx11=disabled` и в runtime-зависимостях этих трёх пакетов не имеет.

## Что публикуется

| Пакет | Что внутри |
|---|---|
| `libpulse0` | `libpulse.so.0`, `libpulse-simple.so.0`, `libpulsecommon-17.0.so`, `etc/pulse/client.conf`, переводы |
| `libpulse-mainloop-glib0` | `libpulse-mainloop-glib.so.0` |
| `libpulse-dev` | заголовки, `.pc`, CMake, Vala VAPI |

Не публикуются: `pulseaudio` (демон), `pulseaudio-utils` (`pactl`, `pacat`,
`paplay`, …), `pulseaudio-equalizer`, `pulseaudio-module-*`,
`libpulsedsp`/`padsp`.

Клиентские утилиты **собираются** апстримом (`-Dclient=true`), но удаляются
из дерева установки в `override_dh_auto_install` вместе с автодополнением
bash/zsh: нужны библиотеки, а не утилиты. Если понадобится `pactl`, проще
поставить его из trixie — он работает и с нашим `libpulse0`, поскольку
SONAME `libpulse.so.0` не менялся, а удалённых символов нет.

## Почему ревизия 2, а не 1

Штатная версия в trixie — `17.0+dfsg1-2+b1`. Наша `17.0+dfsg1-1+crick` была
бы **старее** неё (ревизия 1 < 2), и `apt upgrade` её просто не подхватил бы.
`17.0+dfsg1-2+crick` новее: сравнение доходит до локальной части и `+crick` >
`+b1`. Карта ревизий живёт в `scripts/upstream/<pkg>.conf` (поле `REVISION`).

## Почему `-Ddaemon=false`

Демон тянет ALSA, Bluetooth, GStreamer, LIRC, RAOP/OpenSSL, ресемплеры
(soxr/speex), FFTW, orc, avahi, udev, tcpwrap, WebRTC/adrian AEC, GSettings,
libltdl, tdb, systemd-юниты — больше половины `Build-Depends` Debian и
большинство модулей `pulseaudio-module-*`. Клиенту всё это не нужно: он только
соединяется с сервером по протоколу. `-Ddaemon=false` оставляет в сборке
только клиентскую часть; из `Build-Depends` остаются `libasyncns-dev`,
`libdbus-1-dev`, `libglib2.0-dev`, `libsndfile1-dev`, `libsystemd-dev`
(`sndfile` и `systemd` в upstream запрашиваются безусловно).

Остальные возможности выключены **явно**, чтобы правило было видно в `rules`,
а не зависело от того, нашлась ли зависимость: `-Dx11=disabled`,
`-Djack=disabled` (правило репозитория), `-Dgtk`, `-Dfftw`, `-Dalsa`,
`-Davahi`, `-Dbluez5`, `-Dgstreamer`, `-Dgsettings`, `-Dlirc`, `-Dopenssl`,
`-Dorc`, `-Dsoxr`, `-Dspeex`, `-Dudev`, `-Dtcpwrap`, `-Doss-output` (из-за
него не строится libpulsedsp) и другие.

## Что изменится в поведении клиента

Единственная X11-функция внутри самой библиотеки —
`pa_client_conf_from_x11()`, которая нужна для автозапуска `pax11publish`
(публикации `PULSE_SERVER` в свойствах окна). Её нет, поэтому клиент не
поднимет `pax11publish` автоматически. На системе без X11 это и не требуется.
`pa_client_conf_load()` сохраняет сигнатуру, поэтому **ни один экспортируемый
символ не исчезает** — `libpulse0.symbols` и
`libpulse-mainloop-glib0.symbols` из Debian используются как есть.

## Что не собирается

- man-страницы (`-Dman=false`), doxygen (`-Ddoxygen=false`), тесты
  (`-Dtests=false`);
- dbgsym-пакеты (общее правило `scripts/build-package.sh`).

## Откат

```bash
sudo apt install libpulse0=17.0+dfsg1-2+b1 \
                 libpulse-dev=17.0+dfsg1-2+b1 \
                 libpulse-mainloop-glib0=17.0+dfsg1-2+b1
```

Настоящий звуковой сервер в этом репозитории — `pipewire` (+ `wireplumber`,
`pwvucontrol`). Демон PulseAudio не публикуется, и правило
«PulseAudio — только зависимость клиентских библиотек» сохраняется.