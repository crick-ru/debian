# libglvnd — зачем он здесь

## Что это

`libglvnd` — посредник (dispatch layer) между приложением и драйверами OpenGL.
Он даёт `libEGL.so.1` и `libGLdispatch.so.0`: приложение вызывает `eglGetDisplay`,
а уже glvnd решает, какому драйверу передать вызов.

Собирается **только EGL-часть**. Из четырнадцати бинарных пакетов Debian
публикуются четыре:

| Пакет | Что внутри |
|---|---|
| `libglvnd0` | `libGLdispatch.so.0` — сама диспетчеризация |
| `libglvnd-core-dev` | `usr/include/glvnd/*.h`, `libglvnd.pc` |
| `libegl1` | `libEGL.so.1` — runtime |
| `libegl-dev` | `EGL/egl.h`, `eglext.h`, `eglplatform.h`, `KHR/khrplatform.h`, `egl.pc`, `libEGL.so` |
| `libgles1` | `libGLESv1_CM.so.1` — OpenGL ES 1.x |
| `libgles2` | `libGLESv2.so.2` — OpenGL ES 2.x и 3.x |
| `libgles-dev` | заголовки `GLES/`, `GLES2/`, `GLES3/`, `glesv1_cm.pc`, `glesv2.pc` |
| `libopengl0` | `libOpenGL.so.0` — OpenGL **без** GLX |
| `libopengl-dev` | `GL/gl.h`, `GL/glext.h`, `GL/glcorearb.h`, `opengl.pc`, `libOpenGL.so` |

Не публикуются: `libglx0`, `libgl1`, `libgl-dev`, `libglx-dev`,
`libglvnd-dev` — это GLX и GL. GLX есть X11-протокол, а GL в этом
репозитории не собирается.

**Почему GLES и OpenGL-без-GLX публикуются, а GLX и GL — нет.** В
`src/meson.build` три независимых блока:

```meson
if with_glx            → subdir('GLX'); subdir('GL')   # ← выключено
if get_option('gles1') → subdir('GLESv1')             # ← включено
if get_option('gles2') → subdir('GLESv2')             # ← включено
```

GLES линкует статическую `libopengl_main`, в `libopengl.c` нет ни одного
упоминания GLX или X11. То есть GLES через EGL — не X11-код, и собирается
без GLX целиком. Проверено: у всех пяти собранных библиотек в `NEEDED`
только `libGLdispatch.so.0` и `libc.so.6`.

## Почему мы его собираем, а не берём из trixie

Штатный `libegl-dev` несовместим с нашей mesa, и это выяснилось не сразу —
трижды пришлось разбираться, потому что причина всё время оказывалась не
той, что ожидалось.

Цепочка ровно такая:

```
libegl-dev (glvnd) → libgl-dev → libgl1-mesa-dev
libgl1-mesa-dev Depends: libgbm1 (= 25.0.7-2+deb13u1)   ← ПИН ВЕРСИИ TRIXIE
                                  ↓
наша mesa: libgbm1 = 26.1.6-3+crick                     ← НЕ СОВПАДАЕТ
```

`libegl-dev` нужен по `Build-Depends` пяти пакетам: `wlroots`, `mpv`, `kmscon`,
`gstreamer1.0-plugins-base`, `neatvnc`. Пока ставился штатный `libegl-dev`,
`apt` не мог его разрешить — прогон CI `37161161444` падал с
`cannot resolve build-dependency 'libegl-dev'`.

Два ложных объяснения, которые пришлось отбросить, полезно помнить:

- **`Breaks: mesa-common-dev`** у `libgl-dev` не при чём: `mesa-common-dev` в
  список потребителей не входит и не ставится. Проверено по логу CI — наша mesa
  устанавливалась успешно, сбой происходил на следующем шаге.
- **Зависимость `libgl-dev` в `mesa-common-dev`** тоже не при чём. Её убрали
  (это само по себе верно: GL-заголовки у нас не нужны, `gbm.pc` и `dri.pc` их
  не требуют, `gbm.h` включает только `stddef.h` и `stdint.h`) — но на
  разрешимость `libegl-dev` это не повлияло. Пин `libgbm1` остался.

Вывод, который стоит запомнить: проверять надо `Depends` с пинами версий, а не
`Breaks`/`Replaces`. Пин версии не снимается заменой пакета — его снимает
только пересборка того, что пришпинено.

## Сборка без X11

```
-Dx11=disabled          платформа X11 в EGL не собирается
-Dglx=disabled          GLX не собирается
-Dgles1=false           OpenGL ES 1 не собирается
-Dgles2=false           OpenGL ES 2/3 не собирается
-Dentrypoint-patching=disabled
-Dhgl=false
```

Механизм `-Dx11=disabled` такой: `meson.build` ставит `-DENABLE_EGL_X11` только
если нашёл зависимость `x11`. Без этого макроса `IsX11Display()` в
`src/EGL/libegl.c` компилируется в `return EGL_FALSE;`, а весь X11-код вместе с
`dlopen("libX11.so.6", ...)` отбрасывается препроцессором.

Апстрим прямо пишет в README, что для сборки нужен `libx11` и `libxext` — то
есть штатно X11 в сборочных зависимостях обязателен. Здесь он убран: без X11
собирается и работает, проверено.

## Проверка результата

| Проверка | Результат |
|---|---|
| `readelf -d libEGL.so.1.1.0` | `NEEDED`: только `libGLdispatch.so.0`, `libc.so.6` |
| `readelf -d libGLdispatch.so.0.0.0` | `NEEDED`: только `libc.so.6` |
| строки `libX11.so.6`, `libGLX.so.0` в бинарниках | отсутствуют |
| символы `libEGL.so.1` против штатного | 44 против 44, потерь нет |
| символы `libGLdispatch.so.0` против штатного | 18 против 18, потерь нет |
| символы `libGLESv1_CM.so.1` против штатного | 145 против 145, потерь нет |
| символы `libGLESv2.so.2` против штатного | 358 против 358, потерь нет |
| символы `libOpenGL.so.0` против штатного | 1044 против 1044, потерь нет |
| `egl.pc` | совпадает со штатным |
| `EGL_EGLEXT_VERSION` | 20211210, `wlroots` требует ≥ 20210604 |

Символы не отличаются от штатных, поэтому ABI совместим: приложения, собранные
против `libegl-dev` из trixie, работают против нашей `libegl1` без пересборки.

## Заголовки KHR и GL публикуются — иначе сборка падает

Первая версия пакета удаляла заголовки `GL/` из дерева сборки: они относятся
к API, который мы не публикуем, а пакета `libgl-dev` у нас нет. Оказалось
неверно, и прогон CI `37190102272` упал на двух пакетах:

```
gstreamer1.0-plugins-base: gst-libs/gst/gl/gstglfuncs.h:71: fatal error: GL/gl.h
wlroots: EGL/eglplatform.h:18: fatal error: KHR/khrplatform.h
```

`KHR/khrplatform.h` включает сам `eglplatform.h`, а `GL/gl.h` нужен gstreamer
при сборке `libgstgl` — то есть заголовки нужны не только в готовом бинарнике,
но и при компиляции. Заголовки сами по себе не тянут ни GLX, ни X11, поэтому
публикуются: `KHR/` в `libegl-dev`, `GL/` в `libopengl-dev`. `opengl.pc` в
 описании прямо говорит «library and headers», так что это ожидаемо.

Не публикуются по-прежнему: `libGL.so`, `gl.pc`, `libGLX.so` и пакеты
`libgl1`/`libglx0` — они и есть GLX.

## Что снято у потребителей

Проверено по фактическим `.deb` из зелёного прогона CI, а не по `debian/control`:

| Пакет | Снято | Чем проверено, что не нужно |
|---|---|---|
| `wlroots` | `libgles2-mesa-dev` → `libgles-dev` | `libwlroots-0.20.so` в `NEEDED`: `libEGL.so.1`, `libGLESv2.so.2`. Нужен `glesv2.pc`, который даёт наш glvnd; mesa-овский пакет тянет `libglvnd-dev` с пином версии |
| `wlroots`, `gtk+3.0`, `gtk4` | `libegl1-mesa-dev` | Пакет состоит ровно из двух заголовков — `eglmesaext.h` и `eglext_angle.h` — и оба уже ставит наша `mesa-common-dev`. Сама mesa объявляет `Breaks: libegl1-mesa-dev`, то есть рядом с ней этот пакет не ставится вовсе |
| `gstreamer1.0-plugins-base` | `libgl-dev` из `Build-Depends` | `libgstgl-1.0.so` в `NEEDED`: только `libEGL.so.1`, ни `libGL.so.1`, ни GLX |
| `gstreamer1.0-plugins-bad` | `libopengl-dev` | В собранных библиотеках ни одного `NEEDED` на `libGL`/`libGLX`/`libOpenGL`/`libGLES` |

`libopengl-dev` в `Depends` у `libgstreamer-plugins-base1.0-dev` остался:
`gstreamer-gl-prototypes-1.0.pc` объявляет `Requires: opengl`, и без
`opengl.pc` pkg-config не разрешит файл.

## Побочная выгода: X11 ушёл из сборочной среды

`libegl-dev` из trixie объявляет `Depends: libx11-dev`, то есть EGL-заголовки
формально тянут X11 в сборочную среду. На практике заголовков для этого не
нужно: ветка `#include <X11/Xlib.h>` в `EGL/eglplatform.h` включается только
под `USE_X11`, а для Linux есть `#elif defined(__unix__)`. Это проверено
компиляцией — `eglGetDisplay` собирается и линкуется с `-lEGL` без единого
X11-заголовка. Теперь и в нашем `libegl-dev` такой зависимости нет.

## Лицензия

MIT, с оговоркой: изменения в исходниках должны быть явно отмечены в
сопроводительной документации. Заголовки Khronos — Apache-2.0. GPL-3+ есть
только в двух `m4`-макросах (`ax_check_link_flag.m4`, `ax_pthread.m4`), они в
сборочную систему, в бинарник не попадают, и у `ax_pthread` в README апстрима
есть явное исключение для генерируемых скриптов.

Наша переработка меняет только `debian/` — исходники патчатся в дереве сборки и
в опубликованные `.deb` не входят. Правка отмечена в `debian/copyright` и здесь.

## Откат

Вернуть пакеты `libglx0`, `libgl1`, `libopengl0`, `libgles1`, `libgles2`,
`libgles-dev`, `libgl-dev`, `libglx-dev`, `libopengl-dev`, `libglvnd-dev` и
снять `-Dx11=disabled -Dglx=disabled` с `-Dgles1/-Dgles2=false`, подняв
ревизию на 2. Тогда пять пакетов снова придётся собирать против штатного
`libgbm-dev`, и нарушение правила X11 вернётся — это фиксируется исключением в
`CLOSURE_EXCEPT` генератора.
