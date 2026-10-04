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

Не публикуются: `libglx0`, `libgl1`, `libopengl0`, `libgles1`, `libgles2`,
`libgles-dev`, `libgl-dev`, `libglx-dev`, `libopengl-dev`, `libglvnd-dev`.
Всё это GLX, OpenGL и OpenGL ES — то есть либо X11, либо GL, а в этом
репозитории нет ни того, ни другого.

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
| `egl.pc` | совпадает со штатным |
| `EGL_EGLEXT_VERSION` | 20211210, `wlroots` требует ≥ 20210604 |

Символы не отличаются от штатных, поэтому ABI совместим: приложения, собранные
против `libegl-dev` из trixie, работают против нашей `libegl1` без пересборки.

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
