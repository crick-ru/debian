# libglvnd

Посредник (dispatch layer) между приложением и драйверами OpenGL/EGL.

## Источник упаковки

Упаковка взята из Debian (`libglvnd_1.7.0-3`, ветка unstable) и переработана.
Tarball побайтово совпадает с Debian-овским `libglvnd_1.7.0.orig.tar.xz`.

## Версии

- **В trixie:** 1.7.0-1+b2
- **В исходной упаковке:** 1.7.0-3
- **В нашем репозитории:** 1.7.0-4+crick (ревизия 4)

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libglvnd0` | `libGLdispatch.so.0` — диспетчеризация |
| `libglvnd-core-dev` | `usr/include/glvnd/*.h`, `libglvnd.pc` |
| `libegl1` | `libEGL.so.1` — EGL runtime |
| `libegl-dev` | заголовки `EGL/`, `KHR/`, `egl.pc`, `libEGL.so` |
| `libgles1` | `libGLESv1_CM.so.1` — OpenGL ES 1.x |
| `libgles2` | `libGLESv2.so.2` — OpenGL ES 2.x и 3.x |
| `libgles-dev` | заголовки `GLES/`, `glesv1_cm.pc`, `glesv2.pc` |
| `libopengl0` | `libOpenGL.so.0` — OpenGL без GLX |
| `libopengl-dev` | `GL/gl.h`, `opengl.pc`, `libOpenGL.so` |
| `libgl-dev` | `gl.pc`, `libGL.so` (симлинк → `libOpenGL.so`) |

Не публикуются: `libglx0`, `libgl1`, `libglx-dev`, `libglvnd-dev` — это GLX
(X11-протокол) и GL (не собирается).

Из 14 бинарных пакетов Debian остается 7 (9 пакетов выше + `libgl-dev`).

## Что изменено

### Отключено

- **X11** (правило репозитория): `-Dx11=disabled`. Платформа X11 в EGL не
  собирается. Из `Build-Depends` убраны `libx11-dev`, `libxext-dev`,
  `x11proto-dev`, `xauth`, `xvfb`. Тесты не собираются (они проверяют GLX).
- **GLX:** `-Dglx=disabled`. GLX не собирается и не публикуется.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- EGL (`-Dx11=disabled` убирает только X11-платформу, EGL остаётся).
- OpenGL ES 1 и 2 (`-Dgles1=true -Dgles2=true`).
- OpenGL без GLX (`-Dgl` не выключен отдельно).
- `entrypoint-patching=disabled`, `-Dhgl=false`.

## Патчи

Нет: `debian/patches/series` отсутствует.

## Важные нюансы

### Почему собираем

Штатный `libegl-dev` из trixie несовместим с нашей mesa: `libegl-dev` →
`libgl-dev` → `libgl1-mesa-dev`, который пинит `libgbm1` на версию trixie
(25.0.7), а наша mesa даёт `libgbm1` 26.1.6. Результат: `apt` не может
разрешить `libegl-dev` для пяти пакетов (`wlroots`, `mpv`, `kmscon`,
`gstreamer1.0-plugins-base`, `neatvnc`).

Наш `libglvnd` не содержит X11 и GL-обёрток, поэтому пинов нет. Исключений
в `CLOSURE_EXCEPT` нет.

### libgl-dev — синтетический пакет

`libgl-dev` создан вручную в `debian/rules`: `libGL.so` — симлинк на
`libOpenGL.so`, `gl.pc` — написанный вручную. Его нет в Debian без GLX.
Добавлен в `DEB_SETS` в `scripts/gen-workflow.py`, чтобы автоматически
попадать в stage1-установку пакетов, зависящих от `libglvnd`.

### Заголовки

`KHR/khrplatform.h` и `GL/gl.h` публикуются: без них сборка падает
(`gstreamer1.0-plugins-base` включает `GL/gl.h`, `wlroots` включает
`KHR/khrplatform.h`). Заголовки сами по себе не тянут GLX и X11.

### Проверка ABI

Символы совпадают с штатными: `libEGL.so.1` — 44/44, `libGLdispatch.so.0` —
18/18, `libGLESv1_CM.so.1` — 145/145, `libGLESv2.so.2` — 358/358,
`libOpenGL.so.0` — 1044/1044. Приложения, собранные против `libegl-dev`
из trixie, работают против нашей `libegl1` без пересборки.
