# ffmpeg (crick Debian backports)

Сборка `ffmpeg` 9.0.2 для Debian 13 (trixie, amd64). Упаковка взята из Debian
(`ffmpeg_9.0.2-1`) и сильно упрощена. Это основа медиастека репозитория: `mpv`
собирается против этих `libav*-dev`, а `gstreamer1.0-libav` — мост между
GStreamer и FFmpeg.

## Включено

- Общие библиотеки: `libavcodec`, `libavdevice`, `libavfilter`, `libavformat`,
  `libavutil`, `libswresample`, `libswscale` — все `Multi-Arch: same`.
- Кодеки: AOM, AV1 (через libaom и libdav1d), Opus, Vorbis, FLAC, MP3 (lame),
  MP2/3 (mpg123), LAME, Ogg, BS2B, OpenJPEG, WebP, XZ и Brotli, libzimg,
   libxml2, libvorbis, libtwolame, libshine. Speex, Theora, GSM, GME,
   OpenAL, libmysofa, libvidstab и sndio — выключены (см. «Отключено»). Родные
   кодеки DNxHD и ProRes остаются включёнными: их нельзя отключить отдельными
   флагами (см. «Отключено»). (WavPack и AMR в ffmpeg не включаются configure по
   умолчанию — отсутствуют в сборке, их не перечисляем.)
- Субтитры: `--enable-libass` (это то, чем `celluloid` и `mpv` показывают
  `.srt`/`.ass`).
- Аппаратное ускорение: `--enable-vaapi` (VA-API) и `--enable-ffnvcodec`
  (динамическая загрузка NVIDIA, то есть NVDEC/NVENC). Оба не VDPAU.
- GPL и GPLv3: `--enable-gpl --enable-version3`, нужные для x264/x265/xvid.

## Отключено

- **Оптические диски**: `--disable-libcdio --disable-libbluray
  --disable-libdvdnav --disable-libdvdread`. `libcdio-paranoia-dev` убран из
  `Build-Depends` (в Debian он был включён через `--enable-libcdio`).
- **DVB-тюнеры и захват с видеоустройств**: `--disable-v4l2-m2m`. Демультиплексор DVB
  в FFmpeg отсутствует как минимум с 6.1 — `libavformat/dvdec.c` не существует
  и в n7.1, и в n9.0.2, — поэтому отключать нечего.
- **VDPAU**: `--disable-vdpau`, `libvdpau-dev` убран из `Build-Depends`
  (по правилам проекта).
- **JACK**: `--disable-libjack`. В `configure` он и так по умолчанию `[no]`
  (включается только `--enable-libjack`), а `libjack-dev` отсутствует в
  `Build-Depends`; опция задана явно, чтобы правило было видно в `debian/rules`.
- **X11**: `--disable-libxcb --disable-libxcb-shm --disable-libxcb-xfixes
  --disable-libxcb-shape`. Из `Build-Depends` убраны `libx11-xcb-dev`,
  `libxcb-shape0-dev`, `libxcb-shm0-dev`, `libxcb-xfixes0-dev` и `libxv-dev`.
- **ffplay**: `--disable-sdl2`. Это SDL2, то есть X11; отдельный бинарный
  пакет `ffplay` не публикуется. В 9.0.2 `ffplay` вынесен в отдельный пакет
  Debian, в нашей сборке его просто нет.
- **Rust-библиотеки**: `--disable-librav1e --disable-librsvg`, иначе в
  `Build-Depends` нужен полный `rustc` toolchain. AV1 остаётся доступен через
  `libaom` и `libdav1d`.
- **Варианты сборки standard/extra**: у Debian их два, второй нужен ради
  x264, libtesseract, libsmbclient и AMR в кодирующем варианте. Один вариант
  означает, что пакеты `libav*-extra*` не публикуются.
- **libplacebo**: `--disable-libplacebo` (тянет Vulkan, а задача вывода видео
  решается `mpv`).
- **Редкие аудио/видео-кодеки**: `--disable-libgme --disable-libgsm
  --disable-libmysofa --disable-libspeex --disable-libtheora
  --disable-libvidstab --disable-openal --disable-sndio` (GME, GSM, libmysofa,
  Speex, Theora, libvidstab, OpenAL, sndio). Аудио — через Opus/Vorbis/FLAC,
  видео — через AOM/libvpx/x265. Из `Build-Depends` убраны `libgme-dev`,
  `libgsm-dev`, `libmysofa-dev`, `libspeex-dev`, `libtheora-dev`,
  `libvidstab-dev`, `libopenal-dev` и `libsndio-dev`. Родные DNxHD и ProRes
  остаются включёнными: `--disable-dnxhd`/`--disable-prores` нет, а
  `--disable-everything` выключил бы весь `libavcodec`.
- **Документация и man-страницы**: `--disable-doc --disable-manpages`, поэтому
  `Build-Depends-Indep` (doxygen, node-less, cleancss, tree) и `texinfo`
  удалены, пакет `ffmpeg-doc` не публикуется, а `debian/ffmpeg.manpages`
  вместе с `debian/qt-faststart.1` не используется. `man ffmpeg` не работает.
- **Тесты**: `override_dh_auto_test` пуст, FATE не собирается и не запускается.
- **Примеры**: исходники `doc/examples/*.c` вместе с `Makefile` и `README`
  ставятся целью `install` — она складывается из двух правил: верхнего
  `Makefile` (`install-libs install-headers`) и включаемого
  `doc/examples/Makefile` (`install-examples`). Опции configure для примеров
  нет, `--disable-doc` их не отключает, поэтому каталог
  `usr/share/ffmpeg/examples` удаляется в `override_dh_auto_install` и в
  репозиторий не попадает.

## VA-API берётся из этого репозитория

`libva-dev`, `libva2`, `libva-drm2`, `libva-wayland2` ставятся из сборки
`libva` (см. `packages/libva/README.md`). Штатный `libva-dev` не ставится
рядом с нашим `libglvnd0`: он тянет `libva-glx2`, а тот зависит от `libgl1`,
пинящий `libglvnd0` версии trixie. Пин снят, потому что наш `libva` собран без
GLX и X11: пути DRM и Wayland на месте, VA-API работает полностью.
Исключений в `CLOSURE_EXCEPT` нет.

## Изменено

- Версия: `7:9.0.2-4+crick`. **Epoch 7 обязателен** — историческое значение
  Debian. Без него наша `9.0.2-4+crick` оказалась бы *старее* штатной
  `7:7.1.5-0+deb13u1`, потому что apt сравнивает epoch первым, и `apt upgrade`
  новую сборку не подхватил бы. Карта epoch живёт в
  `scripts/upstream/<pkg>.conf` (поле `EPOCH`).
- `qt-faststart` остаётся в пакете `ffmpeg`. Это не Qt: утилита переставляет
  атом `moov` в начало QuickTime/MP4-файла, чтобы он воспроизводился по HTTP
  во время загрузки. Зависимостей, кроме libc, не добавляет. Собирается
  отдельной целью `tools/qt-faststart` (в общий `all` она не входит) — это
  сделано в `override_dh_auto_build`.
- Символьные файлы минимальные (только строка SONAME, ни одного символа).
  Debian версионирует каждый символ (`LIBAVCODEC_63@LIBAVCODEC_63 7:8.0`), но
  здесь это не нужно: точную версию runtime-библиотеки и так задаёт `Depends`
  в `debian/control` — все `-dev` пинят соседний пакет через
  `= ${binary:Version}`. Фактический список символов `dpkg-gensymbols`
  дописывает в `DEBIAN/symbols` сам (он и определяет `shlibs:Depends`), так
  что при обновлении FFmpeg переписывать `.symbols` не приходится.
  Проверка символов отключена: `dh_makeshlibs -- -c0`. Уровень `-c4`
  (и даже `-c2`) считает появление нового символа ошибкой сборки, а новые
  символы в новом релизе FFmpeg появляются всегда — с `-c4` пакет не собрался
  бы ни разу.
- У всех восьми runtime-библиотек в `debian/control` есть
  `${shlibs:Depends}`. Без него `dpkg-shlibdeps` вычисляет зависимости, но
  подставлять их некуда, и пакет уходит в репозиторий **без `Depends` вообще**.
  Так и вышло: `libavcodec63` публиковался без `Depends`, хотя
  `libavcodec.so.63` ссылается более чем на 20 библиотек (`libvpx.so.9`,
  `libaom.so.3`, `libdav1d.so.7`, ...). Сборка проходила, а ломалось это
  уже у потребителей: `apt` не ставил runtime-библиотеки, и `mpv` падал при
  `meson --internal exe` с «libvpx.so.9: cannot open shared object file».
  Проверка: у каждой stanza `libav*`/`libsw*`, кроме `-dev`, в control
  должен быть `${shlibs:Depends}`.
- Статические библиотеки не собираются (`--disable-static`), поэтому в
  `*.install` пакетов `-dev` нет строк `libav*.a` — Debian их ставила.
- `usr/share/man` удаляется из дерева после установки: готовых man-страниц в
  tar-боле нет, а сгенерированные не собираются.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Влияние на систему

Пакеты называются иначе, чем в trixie, потому что FFmpeg 9 поднял SONAME:
вместо `libavcodec61` публикуется `libavcodec63`, вместо `libavutil59` —
`libavutil61`, вместо `libswscale8` — `libswscale10`, вместо
`libswresample5` — `libswresample7`. При `apt upgrade` старые пакеты trixie
остаются установленными как посторонние, если что-то ещё их требует, и могут
быть удалены через `apt autoremove`. SONAME не меняются, символы не удалены:
у нас сняты VDPAU, диски и X11, а эти возможности не входили в публичный API.

## Ревизия 3 → 4

Ревизия поднята с 1 до 4 (обоснование — в `scripts/upstream/ffmpeg.conf`).

- **Ревизия 3**: в `Depends libavfilter-dev` возвращены `libavcodec-dev` и
  `libavformat-dev` — оба публикуются этим репозиторием с пином
  `= ${binary:Version}`, так что тянут за собой остальные части набора.
  `libavfilter.pc` без `libavformat` не резолвится: любой потребитель FFmpeg
  падает на `meson setup`, а не на линковке. `libpostproc-dev` не добавляется:
  публикация нового пакета решается пользователем, а пин `= ${binary:Version}`
  делает установку неразрешимой, если пакета нет. На сборку это не влияет:
  `libpostproc` нужен только для статической линковки, `.pc`-файлы его не требуют.
- **Ревизия 4**: выключены редкие аудио/видео-кодеки (gme, gsm, mysofa, speex,
  theora, vidstab, openal, sndio), чтобы не тянуть их `-dev`. Родные DNxHD и
  ProRes остаются включёнными: их нельзя отключить отдельными флагами. Откат:
  вернуть `--disable-lib*` в `debian/rules` и `-dev` в `Build-Depends` — кодеки
  лежат в `libavcodec`, удалить их нельзя.
