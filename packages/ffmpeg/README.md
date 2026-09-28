# ffmpeg (crick Debian backports)

Сборка `ffmpeg` 9.0.2 для Debian 13 (trixie, amd64). Упаковка взята из Debian
(`ffmpeg_9.0.2-1`) и сильно упрощена. Это основа медиастека репозитория: `mpv`
собирается против этих `libav*-dev`, а `gstreamer1.0-libav` — мост между
GStreamer и FFmpeg.

## Включено

- Общие библиотеки: `libavcodec`, `libavdevice`, `libavfilter`, `libavformat`,
  `libavutil`, `libswresample`, `libswscale` — все `Multi-Arch: same`.
- Кодеки: AOM, AV1 (через libaom и libdav1d), Opus, Vorbis, Theora, FLAC,
  Speex, WavPack, AMR, MP3 (lame), MP2/3 (mpg123), Opus, LAME, Ogg, FLAC,
  Speex, WavPack, BS2B, libmysofa, OpenJPEG, WebP, XZ и Brotli, GSM, GME,
  OpenAL, libzimg, libxml2, libvorbis, libtwolame, libshine, libvidstab.
- Субтитры: `--enable-libass` (это то, чем `celluloid` и `mpv` показывают
  `.srt`/`.ass`).
- Аппаратное ускорение: `--enable-vaapi` (VA-API) и `--enable-ffnvcodec`
  (динамическая загрузка NVIDIA, то есть NVDEC/NVENC). Оба не VDPAU.
- GPL и GPLv3: `--enable-gpl --enable-version3`, нужные для x264/x265/xvid.

## Отключено

- **Оптические диски**: `--disable-libcdio --disable-libbluray
  --disable-libdvdnav --disable-libdvdread`. `libcdio-paranoia-dev` убран из
  `Build-Depends` (в Debian он был включён через `--enable-libcdio`).
- **DVB-тюнеры и захват с видеоустройств**: `--disable-v4l2-m2m`. Демьксер DVB
  в FFmpeg отсутствует как минимум с 6.1 — `libavformat/dvdec.c` не существует
  и в n7.1, и в n9.0.2, — поэтому отключать нечего.
- **VDPAU**: `--disable-vdpau`, `libvdpau-dev` убран из `Build-Depends`.
  Правило — в `.clinerules/project.md`, раздел «Аппаратное ускорение VDPAU
  отключается».
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
- **Документация и man-страницы**: `--disable-doc --disable-manpages`, поэтому
  `Build-Depends-Indep` (doxygen, node-less, cleancss, tree) и `texinfo`
  удалены, пакет `ffmpeg-doc` не публикуется, а `debian/ffmpeg.manpages`
  вместе с `debian/qt-faststart.1` не используется. `man ffmpeg` не работает.
- **Тесты**: `override_dh_auto_test` пуст, FATE не собирается и не запускается.

## Изменено

- Версия: `7:9.0.2-2+crick`. **Epoch 7 обязателен** — историческое значение
  Debian. Без него наша `9.0.2-2+crick` оказалась бы *старее* штатной
  `7:7.1.5-0+deb13u1`, потому что apt сравнивает epoch первым, и `apt upgrade`
  новую сборку не подхватил бы. Карта epoch живёт в `scripts/fetch-upstream.sh`.
- `qt-faststart` остаётся в пакете `ffmpeg`. Это не Qt: утилита переставляет
  атом `moov` в начало QuickTime/MP4-файла, чтобы он воспроизводился по HTTP
  во время загрузки. Зависимостей, кроме libc, не добавляет. Собирается
  отдельной целью `tools/qt-faststart` (в общий `all` она не входит) — это
  сделано в `override_dh_auto_build`.
- Символьные файлы минимальные (только строка SONAME). Debian версионирует
  каждый символ (`LIBAVCODEC_63@LIBAVCODEC_63 7:8.0`), но в этом репозитории
  важнее, чтобы `-dev`-пакет требовал ровно свою версию runtime-библиотеки:
  `dpkg-shlibdeps` доводит символьные файлы сам, а `Depends` в
  `debian/control` пинит sibling-пакеты через `= ${binary:Version}`.
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
