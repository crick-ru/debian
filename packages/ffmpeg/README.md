# ffmpeg

Фреймворк для декодирования/кодирования/трансляции аудио и видео
(`libavcodec`, `libavdevice`, `libavfilter`, `libavformat`, `libavutil`,
`libswresample`, `libswscale`, утилиты `ffmpeg`, `ffprobe`, `qt-faststart`).

## Источник упаковки

Упаковка взята из Debian (`ffmpeg_9.0.2-1`) и сильно упрощена: один вариант
сборки вместо standard/extra, без `ffmpeg-doc`, без `ffplay`, без пакетов
`libav*-extra*`, минимальные символьные файлы. Tarball побайтово совпадает с
Debian-овским `ffmpeg_9.0.2.orig.tar.xz`.

## Версии

- **В trixie:** 7:7.1.5-0+deb13u1
- **В исходной упаковке:** 7:9.0.2-1
- **В нашем репозитории:** 7:9.0.2-4+crick (epoch 7)

**Epoch 7 обязателен** — историческое значение Debian. Без него `9.0.2-4+crick`
оказалась бы *старее* штатной `7:7.1.5-0+deb13u1`, потому что `apt` сравнивает
epoch первым. Карта epoch живёт в `scripts/upstream/ffmpeg.conf`.

## Содержимое

Все пакеты `Multi-Arch: same`:

- `ffmpeg` — утилиты `ffmpeg`, `ffprobe`, `qt-faststart`
- `libavcodec63` / `libavcodec-dev`
- `libavdevice63` / `libavdevice-dev`
- `libavfilter12` / `libavfilter-dev`
- `libavformat63` / `libavformat-dev`
- `libavutil61` / `libavutil-dev`
- `libswresample7` / `libswresample-dev`
- `libswscale10` / `libswscale-dev`

## Что изменено

### Отключено

- **Документация и man-страницы:** `--disable-doc --disable-manpages`.
  Убраны `doxygen`, `node-less`, `cleancss`, `tree`, `texinfo` из
  `Build-Depends`. Пакет `ffmpeg-doc` не публикуется.
- **Тесты:** `override_dh_auto_test` пуст, FATE не собирается и не запускается.
  Каталог `debian/tests` удалён.
- **ffplay:** `--disable-sdl2` (SDL2 = X11). Пакет `ffplay` не публикуется.
- **X11:** `--disable-libxcb --disable-libxcb-shm --disable-libxcb-xfixes
  --disable-libxcb-shape`. Из `Build-Depends` убраны `libx11-xcb-dev`,
  `libxcb-shape0-dev`, `libxcb-shm0-dev`, `libxcb-xfixes0-dev`, `libxv-dev`.
- **Оптические диски:** `--disable-libcdio --disable-libbluray
  --disable-libdvdnav --disable-libdvdread`. `libcdio-paranoia-dev` убран.
- **DVB-тюнеры и V4L2-захват:** `--disable-v4l2-m2m`.
- **VDPAU:** `--disable-vdpau`, `libvdpau-dev` убран.
- **JACK:** `--disable-libjack` (в `configure` по умолчанию `[no]`).
- **Rust:** `--disable-librav1e --disable-librsvg` — AV1 через `libaom`,
  `libdav1d`.
- **Варианты standard/extra:** один вариант, пакеты `libav*-extra*` не
  публикуются.
- **libplacebo:** `--disable-libplacebo` (Vulkan, задача вывода — `mpv`).
- **Редкие аудио/видео-кодеки:** `--disable-libgme --disable-libgsm
  --disable-libmysofa --disable-libspeex --disable-libtheora
  --disable-libvidstab --disable-openal --disable-sndio`. Из
  `Build-Depends` убраны соответствующие `-dev`-пакеты.
- **Примеры:** исходники `doc/examples/*.c` удаляются из staging-дерева в
  `override_dh_auto_install` (нет опции configure для отключения,
  `--disable-doc` не помогает).

### Включено

- Библиотеки: `libavcodec`, `libavdevice`, `libavfilter`, `libavformat`,
  `libavutil`, `libswresample`, `libswscale`
- Кодеки: AOM, AV1, Opus, Vorbis, MP3 (lame), MP2/3 (mpg123), Ogg, BS2B,
  OpenJPEG, WebP, XZ, libzimg, libvorbis, libtwolame, libshine
- Субтитры: `--enable-libass`
- Аппаратное ускорение: `--enable-vaapi` (VA-API), `--enable-ffnvcodec`
  (NVDEC/NVENC)
- GPL/GPLv3: `--enable-gpl --enable-version3`
- Родные DNxHD и ProRes остаются включёнными (нет отдельного флага)

## Патчи

Нет: `debian/patches/series` отсутствует.

## Изменения ABI

SONAME подняты (FFmpeg 9): `libavcodec61` → `libavcodec63`,
`libavutil59` → `libavutil61`, `libswscale8` → `libswscale10`,
`libswresample5` → `libswresample7`. Символы не удалены — отключённые
возможности (VDPAU, диски, X11) не входят в публичный API.

## Важные нюансы

- `libva-dev` ставится из этого репозитория (`packages/libva/README.md`):
  штатный `libva-dev` тянет `libva-glx2`, а тот зависит от `libgl1`, пинящий
  `libglvnd0` из trixie. Исключений в `CLOSURE_EXCEPT` нет.
- Символьные файлы минимальны (только строка SONAME, ни одного символа).
  Проверка символов отключена: `dh_makeshlibs -- -c0`. Фактический список
  символов `dpkg-gensymbols` дописывает в `DEBIAN/symbols` сам.
- Статических библиотек нет (`--disable-static`).
