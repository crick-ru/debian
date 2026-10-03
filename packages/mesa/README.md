# mesa (crick Debian backports)

`mesa` 26.1.6 для Debian 13 (trixie, amd64) — **без X11**.

Версия: `26.1.6-1+crick`.

Упаковка взята из Debian (`mesa_26.1.6-1~bpo13+1`, ветка 26.1) и
переработана.

## Почему свой mesa

Штатная mesa в trixie тянет X11 уже в сам `libgallium`:

```
mesa-libgallium Depends: libx11-xcb1, libxcb-dri3-0, libxcb-present0,
                         libxcb-randr0, libxcb-sync1, libxcb-xfixes0, libxcb1, libxshmfence1
libgbm1            Depends: mesa-libgallium
libegl-mesa0       Depends: libgbm1, mesa-libgallium, libx11-xcb1, libxcb-*
libglx-mesa0       Depends: libx11-6, libx11-xcb1, libxcb-glx0, libgl1-mesa-dri, …
```

То есть даже `libgbm1`, от которого зависит `neatvnc`, в trixie приводит за
собой X11 — XCB приходит транзитивно через `mesa-libgallium`. Это нарушает
правило репозитория «X11 нет нигде», поэтому mesa собирается здесь:
`-Dplatforms=['wayland']` и `-Dglx=disabled`.

Побочный эффект, важный для wayvnc: с нашей mesa `libneatvnc1` больше не
тянет X11 через gbm.

## Почему 26.1.6, а не 26.2.4

В sid есть mesa 26.2.4, но её `Build-Depends` требуют `llvm-22-dev`,
`libclang-22-dev`, `libclc-22`, `spirv-tools-dev` и `libdrm-dev >= 2.4.134-3~`.
В trixie есть только llvm-19 и `libdrm` 2.4.124, то есть 26.2.x в trixie не
собирается без отдельного бэкпорта тулчейна. Mesa 26.1.6 из
`trixie-backports` — это ровно та сборка, которую Debian уже сделала под
trixie (llvm-19), и под наш `libdrm` 2.4.134 она подходит.

Тарболл — тот же orig, что лежит в пуле Debian
(`pool/main/m/mesa/mesa_26.1.6.orig.tar.xz`), чтобы `dpkg-source` находил его
по имени `mesa_26.1.6.orig.tar.xz`.

## Что публикуется

| Пакет | Что внутри |
|---|---|
| `libgbm1` | `libgbm.so.1`, плагин `gbm/dri_gbm.so` |
| `libgbm-dev` | `gbm.h`, `gbm.pc`, `libgbm.so` |
| `libegl-mesa0` | `libEGL_mesa.so.0`, `50_mesa.json` для glvnd |
| `mesa-libgallium` | `libgallium-*.so` (настоящий DRI) **и VA-драйверы** `*_drv_video.so` |
| `mesa-common-dev` | `dri_interface.h`, `dri.pc` |
| `mesa-vulkan-drivers` | Vulkan-драйверы и слои |

Не публикуются: `libgl1-mesa-dri` (X11-обёртка для GLX, настоящий DRI лежит
в `mesa-libgallium` — разбор в разделе «DRI: что где лежит»), `libglx-mesa0`
(это GLX, то есть X11), `libegl1-mesa-dev`,
`libgles2-mesa-dev`, `libgl1-mesa-dev` (переходные обёртки над glvnd),
`mesa-teflon-delegate` (только arm64), `mesa-opencl-icd`, `mesa-drm-shim`.

`mesa-va-drivers` и `mesa-vdpau-drivers` отдельными пакетами не собираются,
но `mesa-libgallium` их **`Provides`** (и `Breaks`/`Replaces` версии trixie) —
это уже сделано в упаковке Debian, поэтому apt аккуратно снимет штатные
`mesa-va-drivers` и `mesa-vdpau-drivers` при обновлении.

`mesa-common-dev` больше не зависит от `libx11-dev` и `libglx-dev`.

Отключено:

| Что | Почему | Чем вместо |
|---|---|---|
| GLX и платформа `x11` | правило «X11 нет нигде» | `-Dglx=disabled`, `-Dplatforms=['wayland']` |
| VDPAU | правило репозитория | в mesa 26.1.6 VDPAU-драйверов нет вовсе; пакет не публикуется |
| OpenCL (`rusticl`) | тянет rustc, bindgen, cbindgen, `librust-*-dev`, llvm-spirv, libllvmspirvlib, libclang — около сотни мегабайт | `-Dgallium-rusticl=false` |
| `asahi`, Vulkan `nouveau` | это `naga` на Rust | — |
| `d3d12` | нужен `directx-headers-dev` из Wine | — |
| `virgl` | отдельный wrap-файл, лишняя зависимость | — |
| `teflon` | только arm64 | — |
| `mesa-drm-shim` | инструмент для тестов | `-Dtools=` пуст |
| тесты | правило репозитория | `-Dbuild-tests=false`, `override_dh_auto_test` пуст, `debian/tests` удалён |

VA-API (`-Dgallium-va=enabled`) и аппаратное декодирование **оставлены** —
правило репозитория их не отключает.

## Почему `debian/control` статический, а не генерируется

У mesa 26.1.6 появился `meson.options` вместо `meson_options.txt`, и Debian
генерирует `debian/control` из `debian/control.in` через цель `regen_control`
с подстановками вида `@LLVM_ARCHS@` — они нужны, чтобы одна упаковка
собиралась под 12 архитектур. Репозиторий собирает только `amd64`, поэтому
`control` здесь статический, а `regen_control` и `control.in` убраны.

Символьные файлы `libgbm1.symbols` и `libegl-mesa0.symbols` — из Debian, без
изменений: ни SONAME, ни набор экспортируемых символов от отключения X11 не
меняются (`libGLX_mesa.so.0` не собирается вовсе, поэтому
`libglx-mesa0.symbols` не нужен).

## DRI: что где лежит (и почему `libgl1-mesa-dri` не публикуется)

Пакет называется `libgl1-mesa-dri`, но **настоящих DRI-драйверов в нём
нет**. Это X11-специфичная склейка, и разобраться пришлось по исходникам
mesa и по содержимому штатных пакетов Debian.

В mesa 25.x и 26.x DRI-драйверы не собираются как отдельные библиотеки.
Собирается один общий мега-драйвер, и раскладка такая:

| Что | Пакет | Чем строится | Нужен X11? |
|---|---|---|---|
| `libgallium-<версия>.so` — **настоящий DRI-драйвер**, все gallium-драйверы внутри | `mesa-libgallium` | `src/gallium/targets/dri` (`with_dri`) | **нет** |
| `dri/libdril_dri.so` + симлинки `*_dri.so` — обёртка для GLX | `libgl1-mesa-dri` | `src/gallium/targets/dril` | **да** |

Ключевой факт: **`libegl-mesa0` зависит от `mesa-libgallium` напрямую**, а
не через dlopen. Проверено на штатном trixie:

```
$ dpkg-deb -f libegl-mesa0_25.0.7-2+deb13u1_amd64.deb Depends
… libgbm1 (= 25.0.7-2+deb13u1), mesa-libgallium (= 25.0.7-2+deb13u1) …
```

А `libglx-mesa0` — единственный потребитель `libgl1-mesa-dri`, и он целиком
X11:

```
$ dpkg-deb -f libglx-mesa0_25.0.7-2+deb13u1_amd64.deb Depends
… libx11-6, libxcb-glx0, libgl1-mesa-dri, mesa-libgallium …
```

Симлинки `*_dri.so` создаёт цель `src/gallium/targets/dril`, которая
подключается так (`src/meson.build:158` в 26.1.6, `:140` в 25.0.7):

```meson
if with_gallium
  if with_glx == 'dri' or with_platform_x11 or with_platform_xcb
    subdir('gallium/targets/dril')
  endif
endif
```

То есть без GLX/X11 её нет — и она не нужна: `libdril_dri.so` лишь
`dlopen`ает `libEGL.so.1`, чтобы отдать GLX запросы в EGL
(`src/gallium/targets/dril/dril_target.c:362`). Это обратный путь для
устаревшей связки GLX → EGL, а не источник драйверов.

**Вывод: `libgl1-mesa-dri` в этом репозитории не публикуется**, и OpenGL,
VA-API и EGL при этом полностью работают — они идут через
`mesa-libgallium` → `libgallium-*.so`, который собирается без X11.
Штатный trixie-пакет при этом остаётся: мы его не заменяем и не удаляем,
просто он не нужен нашей ветке. То, что он лежит в trixie с X11 внутри,
не делает его нашим — правило репозитория касается публикуемых пакетов.

Проверено, что тарболл и патчи Debian совпадают с нашими побайтно
(md5 `1b93168f…` из `.dsc`, патчи sid и backports идентичны), так что
расхождение поведения объясняется не исходником, а составом сборки:
Debian собирает с X11 и получает обе цели, мы — только `targets/dri`.

### Что публикуется

| Пакет | Состав | X11 |
|---|---|---|
| `mesa-libgallium` | `libgallium-*.so`, симлинки `*_drv_video.so`, `drirc.d/00-mesa-defaults.conf` | нет |
| `libgbm1` | `libgbm.so.1`, `gbm/dri_gbm.so` | нет |
| `libgbm-dev` | заголовки, `.pc` | нет |
| `libegl-mesa0` | `libEGL_mesa.so.0`, `50_mesa.json` | нет |
| `mesa-vulkan-drivers` | драйверы и слои Vulkan | нет |
| `mesa-common-dev` | заголовки DRI, `dri.pc` | нет |

`libglapi-mesa`, `mesa-va-drivers` и `mesa-vdpau-drivers` отдельными
пакетами не публикуются: glapi живёт внутри `libgallium`, а VA-драйверы
едят в `mesa-libgallium` (Debian держит для них `Provides`/`Breaks` —
это сохранено).

### Последствие для `apt upgrade`

`libglx-mesa0` из trixie пинит `mesa-libgallium (= 25.0.7-2+deb13u1)`.
Наша `mesa-libgallium` имеет другую версию, поэтому при `apt upgrade`
штатный `libglx-mesa0` будет снят — его нечем удовлетворить. Это
ожидаемо и правильно: GLX на X11 в репозитории не публикуется.
Своего `libglx-mesa0` мы не собираем.

## dbgsym

Не собираются — общее правило `scripts/build-package.sh`.

## Что произойдёт при `apt upgrade`

Штатные `libegl-mesa0`, `libgbm1`, `mesa-libgallium`, `mesa-common-dev`,
`mesa-vulkan-drivers` заменяются нашими (те же имена, версия выше). Штатный
`libgl1-mesa-dri` **остаётся**: мы пакет с таким именем не производим, apt
не считает его нашим и не трогает. Он лежит на месте, но больше ничего
общего с нашей mesa не связывает — `libEGL_mesa` смотрит на
`mesa-libgallium`, а не на него.

`libglx-mesa0` из trixie, наоборот, **будет снят**: он пинит
`mesa-libgallium (= 25.0.7-2+deb13u1)`, а наша версия другая, и удовлетворить
пин нечем. Это ожидаемо — GLX на X11 в репозитории не публикуется.

**Про `libclc` и clang.** Они остаются в `Build-Depends` и не имеют отношения
к OpenCL. `libclc`, `libllvmspirvlib` и `spirv-tools` — это компиляция
SPIR-V-шейдеров драйверов `iris`, `crocus` и `intel` (в `meson.build` это
`with_clc` / `with_driver_using_clc`), а `libclang`/`libclang-cpp` нужны той же
ветке `with_clc`. В ней требуются **все пять сразу**, и отсутствие любого
роняет `meson setup`:

| Не хватает | Ошибка |
|---|---|
| `libclc-19(-dev)` | `Dependency "libclc" not found` |
| `libllvmspirvlib-19-dev` | `Dependency "LLVMSPIRVLib" not found` |
| `libclang-19-dev` | `C++ library 'clangBasic' not found` |

А вот `rustc`, `bindgen`, `cbindgen`, `librust-*-dev`, `llvm-spirv` — они как
раз про OpenCL на Rust, и они убраны. Набор зависимостей и сами опции
проверены локальным прогоном `meson setup` на sysroot из
`tools/local-sysroot.sh mesa`: он даёт `build.ninja` и сводку
`glx: disabled`, `platforms: ['wayland']`, `gallium-rusticl: false`.

Оговорка про инструменты: `tools/local-meson-setup.sh mesa` для mesa не
годится — он читает из `debian/rules` только литеральный блок `conf_flags`, а
у mesa списки драйверов вычисляются в make (`$(GALLIUM_DRIVERS_LIST)`), и после
извлечения текста они не раскрываются. Поэтому `meson setup` запускался
вручную с теми же флагами, что и CI. Для остальных мезон-пакетов инструмент
работает как обычно.

`mesa-va-drivers` и `mesa-vdpau-drivers` из trixie будут сняты автоматически:
наш `mesa-libgallium` объявляет `Breaks`/`Replaces` для их версий.

Проверить заранее:

```bash
apt-get -s upgrade
```

## Откат

```bash
sudo apt install mesa-libgallium=25.0.7-2+deb13u1 \
                 libgbm1=25.0.7-2+deb13u1 \
                 libegl-mesa0=25.0.7-2+deb13u1 \
                 mesa-common-dev=25.0.7-2+deb13u1 \
                 mesa-vulkan-drivers=25.0.7-2+deb13u1
```

и убрать пакет `mesa` из матрицы стадии 2 в `build.yml` (иначе `neatvnc` и
`wayvnc` продолжат собираться против нашей mesa, пока она есть).

Если всё же нужен X11 — проще не откатывать mesa, а поставить
`libglx-mesa0=25.0.7-2+deb13u1` из trixie: это независимый пакет, он не
конфликтует с нашей mesa.
GLX-заголовки в установку не попадают.

## Какие драйверы оставлены

| Gallium | VA-API | Vulkan |
|---|---|---|
| `softpipe` и `llvmpipe` (софтверные), `radeonsi`, `zink` (OpenGL поверх Vulkan), `iris` и `i915` (Intel), `crocus`, `freedreno` (Adreno), `nouveau`, `r300`, `r600`, `svga` | `r600`, `radeonsi`, `nouveau` — едут внутри `mesa-libgallium` как `*_drv_video.so` | `amd`, `intel`, `intel_hasvk`, `swrast`, `virtio`, `freedreno` |

Слои Vulkan: `anti-lag`, `device-select`, `intel-nullhw`, `overlay`,
`screenshot`.