# mesa (crick Debian backports)

`mesa` 26.1.6 для Debian 13 (trixie, amd64) — **без X11**.

Версия: `26.1.6-1+crick`.

Упаковка взята из Debian (`mesa_26.1.6-1~bpo13+1`, ветка 26.1) и
переработана.

## Почему свой mesa

Штатная mesa в trixie тянет X11 практически во всё:

```
libglx-mesa0    Depends: libx11-6, libx11-xcb1, libxcb-glx0, libxcb-*, libxext6, libxxf86vm1
libegl-mesa0    Depends: libx11-xcb1, libxcb-dri3-0, libxcb-present-0, libxcb-randr0, libxcb-shm0, libxcb-xfixes0
mesa-libgallium Depends: libgl1-mesa-dri  (а тот — libx11-6, libxcb-*)
libgbm1         Depends: mesa-libgallium
```

То есть даже `libgbm1`, от которого зависит `neatvnc`, в trixie приводит за
собой X11. Это нарушает правило репозитория «X11 нет нигде», поэтому mesa
собирается здесь: `-Dplatforms=['wayland']` и `-Dglx=disabled`.

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
| `libgl1-mesa-dri` | DRI-модули `*_dri.so` (hardlink-и, переносятся вручную) |
| `mesa-libgallium` | `libgallium-*.so` **и VA-драйверы** `*_drv_video.so` |
| `mesa-common-dev` | `dri_interface.h`, `dri.pc` |
| `mesa-vulkan-drivers` | Vulkan-драйверы и слои |

Не публикуются: `libglx-mesa0` (это GLX, то есть X11), `libegl1-mesa-dev`,
`libgles2-mesa-dev`, `libgl1-mesa-dev` (переходные обёртки над glvnd),
`mesa-teflon-delegate` (только arm64), `mesa-opencl-icd`, `mesa-drm-shim`.

`mesa-va-drivers` и `mesa-vdpau-drivers` отдельными пакетами не собираются,
но `mesa-libgallium` их **`Provides`** (и `Breaks`/`Replaces` версии trixie) —
это уже сделано в упаковке Debian, поэтому apt аккуратно снимет штатные
`mesa-va-drivers` и `mesa-vdpau-drivers` при обновлении.

`mesa-common-dev` больше не зависит от `libx11-dev` и `libglx-dev`: без них
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

## DRI-модули: открытая проблема версии 26.1.6

В mesa 26.x DRI-модули устроены иначе, чем в 25.x: собирается **один**
`libgallium-<версия>.so`, а не отдельные `swrast_dri.so`, `iris_dri.so` и
прочие. Симлинки `*_dri.so` на него создаёт цель
`src/gallium/targets/dril` — а она в 26.1.6 **вообще не подключена**:
`subdir('targets/dril')` не вызывается ни из `meson.build`, ни из
`src/gallium/meson.build`. Проверено на распакованном дереве.

Практические следствия для нашей сборки:

* в `debian/tmp/usr/lib/<triplet>/dri/` попадают только симлинки
  `*_drv_video.so` (VA-драйверы) — их создаёт `install_megadrivers` в цели
  `src/gallium/targets/dri`, и они работают;
* симлинков `*_dri.so` нет вообще, поэтому `libgl1-mesa-dri` собрать нечем;
* при этом **Debian в trixie-backports публикует**
  `libgl1-mesa-dri_26.1.6-1~bpo13+1` с единственным файлом
  `usr/lib/x86_64-linux-gnu/dri/libdril_dri.so` — то есть у Debian
  `libdril_dri.so` получается, а у нас нет. Значит, либо Debian собирает не
  совсем тот тарбол, либо у него есть ещё одна правка, которая это включает.

Поэтому сейчас `override_dh_install` **падает внятно**, а не публикует
`libgl1-mesa-dri` без DRI-модулей: такой пакет молча сломал бы OpenGL и
VA-API. До решения задача не закрыта, и вариантов два:

1. выяснить, чем Debian включает `dril` (вероятнее всего патч или опция),
   и повторить это у нас;
2. взять базовой упаковку mesa **25.0.7-2+deb13u1** (версия из trixie),
   где раскладка DRI-модулей старая и совпадает с упаковкой Debian. Тогда
   понадобится epoch 8 — ровно как у `ffmpeg` и `imagemagick`: без него
   наша `25.0.7-1+crick` окажется старее штатной `25.0.7-2+deb13u1` и apt
   её не подхватит.

Первый вариант сохраняет свежую версию, второй — снимает риск целиком.
Выбор за владельцем репозитория; второй реализуется за час, первый
требует ещё одной экспедиции по исходникам mesa.

## dbgsym

Не собираются — общее правило `scripts/build-package.sh`.

## Что произойдёт при `apt upgrade`

Штатные `libegl-mesa0`, `libgbm1`, `libgl1-mesa-dri`, `mesa-libgallium`,
`mesa-common-dev` заменяются нашими (те же имена, версия выше). Штатный
`libglx-mesa0` **останется установленным**: его больше никто не производит,
но apt не считает его «нашим» пакетом и не удаляет. Он нужен только для
X11-клиентов, которых в системе быть не должно.
| `mesa-drm-shim` | инструмент для тестов | `-Dtools=` пуст |
| тесты | правило репозитория | `-Dbuild-tests=false`, `override_dh_auto_test` пуст, `debian/tests` удалён |

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
                 libgl1-mesa-dri=25.0.7-2+deb13u1 \
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