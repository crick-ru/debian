# mesa

3D-графическая библиотека Mesa: реализация OpenGL, OpenGL ES, EGL, Vulkan.

## Источник упаковки

Упаковка взята из Debian (`mesa_26.1.6-1~bpo13+1`, trixie-backports, ветка 26.1)
и переработана: X11 выключено полностью, GLX не собирается, VDPAU и OpenCL
отключены. Tarball побайтово совпадает с Debian-овским
`mesa_26.1.6.orig.tar.xz`.

## Версии

- **В trixie:** 25.0.7-2+deb13u1
- **В исходной упаковке:** 26.1.6-1~bpo13+1
- **В нашем репозитории:** 26.1.6-3+crick (ревизия 3)

**Почему 26.1.6, а не 26.2.4:** в sid есть mesa 26.2.4, но её `Build-Depends`
требуют `llvm-22-dev`, `libdrm-dev >= 2.4.134-3~`, чего в trixie нет (только
llvm-19). 26.1.6 из backports — это сборка Debian под trixie (llvm-19),
совместимая с нашим `libdrm` 2.4.134.

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libgbm1` | `libgbm.so.1`, плагин `gbm/dri_gbm.so` |
| `libgbm-dev` | `gbm.h`, `gbm.pc`, `libgbm.so` |
| `libegl-mesa0` | `libEGL_mesa.so.0`, `50_mesa.json` для glvnd |
| `mesa-libgallium` | `libgallium-*.so` (настоящие DRI-драйверы) **и** VA-драйверы `*_drv_video.so` |
| `mesa-common-dev` | `dri_interface.h`, заголовки `EGL/eglmesaext.h`, `dri.pc` |
| `mesa-vulkan-drivers` | Vulkan-драйверы и слои |

Не публикуются: `libgl1-mesa-dri` (X11-обёртка, настоящие DRI в
`mesa-libgallium`), `libglx-mesa0` (GLX = X11), `libegl1-mesa-dev`,
`libgles2-mesa-dev`, `libgl1-mesa-dev` (переходные обёртки над glvnd),
`mesa-opencl-icd`, `mesa-drm-shim`.

## Что изменено

### Отключено

- **X11 и GLX:** `-Dplatforms=['wayland'] -Dglx=disabled`. Из `Build-Depends`
  удалены все X11-библиотеки: `libx11-dev`, `libx11-xcb-dev`, `libxcb-*-dev`,
  `libxext-dev`, `libxrandr-dev`, `libxshmfence-dev`, `x11proto-dev`,
  `libxxf86vm-dev`. Штатная mesa в trixie тянет X11 даже через `libgbm1`:
  `mesa-libgallium Depends: libx11-xcb1, libxcb-*, …`.
- **VDPAU:** в mesa 26.1.6 VDPAU-драйверов нет вовсе, пакет не публикуется.
- **OpenCL (rusticl):** `-Dgallium-rusticl=false`. Убраны `rustc`, `bindgen`,
  `cbindgen`, `librust-*-dev`, `llvm-spirv`. Пакет `mesa-opencl-icd` не
  публикуется.
- **D3D12:** требует `directx-headers-dev` из Wine — не собирается.
- **Rust-Vulkan драйверы** (asahi, nouveau через naga): отключены.
- **virgl:** отдельный wrap-файл — не собирается.
- **teflon:** только для arm64.
- **mesa-drm-shim:** `-Dtools=` пуст.
- **Тесты:** `-Dbuild-tests=false`, `debian/tests` удалён, `override_dh_auto_test`
  пуст.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- **Gallium-драйверы:** softpipe, nouveau, r300, r600, crocus, iris, i915,
  svga, freedreno, radeonsi, zink, llvmpipe.
- **Vulkan:** amd, intel, intel_hasvk, swrast, virtio, freedreno.
- **VA-API (gallium-va):** `-Dgallium-va=enabled` — не отключается по правилу
  репозитория. VA-драйверы `*_drv_video.so` едут внутри `mesa-libgallium`.
- GLES и OpenGL-без-GLX: `-Dgles1=disabled -Dgles2=enabled`.

## Патчи

Два патча Debian сохранены: `path_max.diff`,
`src_glx_dri_common.h.diff` — оба относятся к GLX, который не собирается,
но они не удаляются, чтобы не нарушать соответствие с Debian-овским tarball.

## Изменения ABI

SONAME не меняются (`libgbm.so.1`, `libEGL_mesa.so.0`, `libOpenGL.so.0`).
Символьные файлы `libgbm1.symbols` и `libegl-mesa0.symbols` из Debian
без изменений: `libGLX_mesa.so.0` не собирается вовсе, поэтому
`libglx-mesa0.symbols` не нужен.

## Важные нюансы

### DRI: что где лежит

Пакет называется `libgl1-mesa-dri`, но настоящих DRI-драйверов в нём нет.
DRI-драйверы — это `libgallium-*.so` в пакете `mesa-libgallium`
(цель `src/gallium/targets/dri`). `libgl1-mesa-dri` — X11-обёртка над ней
(цель `src/gallium/targets/dril`), которая собирается только при
`with_glx == 'dri' or with_platform_x11 or with_platform_xcb`. Без X11 и GLX
её нет — и она не нужна: `libEGL_mesa` зависит от `mesa-libgallium` напрямую.

### VA-API берётся из этого репозитория

`libva-dev` ставится из сборки `libva` этого репозитория (см.
`packages/libva/README.md`). Штатный `libva-dev` несовместим с нашим
`libglvnd0`: он тянет `libva-glx2 → libgl1 → libglvnd0` (trixie версии).

### mesa-common-dev и libgl-dev

`mesa-common-dev` не зависит от `libgl-dev`: GL не собирается, заголовки
не используются. Проверено по исходникам: `gbm.pc` не требует `libgl-dev`,
`dri.pc` требует только `libdrm`, `gbm.h` включает только `stddef.h`/`stdint.h`.

`libgl-dev` (пакет glvnd) объявляет `Breaks: mesa-common-dev (<< 19.3.0~rc6-1)`,
а наша версия 26.1.6 попадает в это ограничение. Если `mesa-common-dev`
зависит от `libgl-dev`, `libegl-dev` становится неразрешимым для пяти пакетов
(`wlroots`, `mpv`, `kmscon`, `gstreamer1.0-plugins-base`, `neatvnc`).

### apt upgrade

`libglx-mesa0` из trixie пинит `mesa-libgallium (= 25.0.7-2+deb13у1)`.
Наша `mesa-libgallium` имеет другую версию → `apt upgrade` снимет
`libglx-mesa0`. `mesa-va-drivers` и `mesa-vdpau-drivers` из trixie снимаются
автоматически — наш `mesa-libgallium` объявляет `Breaks`/`Replaces`.

Проверить:
```
apt-get -s upgrade
```
