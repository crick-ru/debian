# chromium (crick Debian backports)

Сборка `chromium` 154.0.8037.92 для Debian 13 (trixie, amd64).

Версия: `154.0.8037.92-1+crick`.

Упаковка взята из Debian (`chromium_154.0.8037.92-1`, unstable) и переработана.

## Главное: X11 нет вообще

Браузер собран **только под Wayland**. Это не «X11 отключён по умолчанию»,
а отсутствие X11 в бинарнике: в `debian/rules` задано

```
use_ozone=true
ozone_auto_platforms=false      # иначе gn сам ставит ozone_platform_x11=true для is_linux
ozone_platform="wayland"
ozone_platform_wayland=true
ozone_platform_headless=true     # режим --headless, без дисплея
ozone_platform_x11=false
use_xkbcommon=true
```

Ключевой момент — `ozone_auto_platforms=false`. Пока эта переменная равна
`use_ozone` (то есть `true` для Linux), ветка в `build/config/ozone.gni`
для `is_linux` сама выставляет `ozone_platform = "x11"`,
`ozone_platform_x11 = true` и `ozone_platform_wayland = true`. Одного
`ozone_platform_x11=false` без `ozone_auto_platforms=false` недостаточно:
аргумент был бы перезаписан.

Что убрано из упаковки (`debian/control`):

| Убрано | Откуда | Почему |
|---|---|---|
| `xcb-proto`, `xfonts-base`, `xvfb` | Build-Depends | X11-инфраструктура и шрифты |
| `libx11-xcb-dev`, `libxt-dev`, `libxss-dev`, `libxtst-dev`, `libxnvctrl-dev`, `libxshmfence-dev`, `libxcb-dri3-dev` | Build-Depends | заголовки X11/XCB |
| `x11-utils` | Depends `chromium-common` | утилиты X11 (`xdpyinfo` и т. п.) |
| `libgl1-mesa-dri` | Recommends `chromium-common` | X11-DRI |
| `libgl1-mesa-swx11` | Conflicts `chromium` | software-GL для X11 |

Что убрано из `debian/rules` для самого пакета:

- `libglu1-mesa-dev`, `libegl1-mesa-dev`, `libgles2-mesa-dev`,
  `libopenh264-dev` — chromium берёт GL/GLES из собственных
  `libEGL.so`/`libGLESv2.so` пакета `chromium-common`, а не из системы;
- **`libgl-dev`** — здесь не «оставлено для заголовков GL», а **убрано
  сознательно**. В Debian оно нужно было для GLX. В trixie
  `libgl-dev` Depends `libglx-dev`, а тот — `libx11-dev`: пакет с X11-заголовками
  попал бы в сборочную среду, что нарушает правило репозитория. Проверено по
  исходникам версии 154: `GL/gl.h` не включается **ни одним** файлом сборки
  (единственные совпадения — bundled
  `third_party/dawn/third_party/OpenGL-Registry/src/api/GL/glcorearb.h` и
  заголовки glfw, которые идут в комплекте с angle), а `pkg_config("gl")` в gn
  не запрашивается ни разу. То есть заголовки GL Chromium не нужны;
- `mesa-common-dev` оставлен: он даёт заголовки расширений Mesa
  (`GL/extension`), которые нужны VA-API и аннотациям.

Проверяется на собранном `.deb`:

```bash
readelf -d /usr/lib/chromium/chromium | grep NEEDED | grep -E 'libX|xcb'
# ожидается пустой вывод
```

## Аппаратное ускорение под Wayland не пострадало

Это главный риск отключения X11, поэтому проверено по коду upstream
(`media/gpu/args.gni`, версия 154):

```
use_vaapi = is_linux && !is_castos
            && (ozone_platform_x11 || ozone_platform_wayland)
            && (target_cpu == "x64" || ...)
```

| Вид ускорения | Состояние | Почему X11 не нужен |
|---|---|---|
| **VA-API** (аппаратное декодирование и кодирование видео) | **включено** | Условие выше — логическое ИЛИ: при `ozone_platform_wayland=true` оно и так истинно, X11 не требуется. Debian дополнительно передаёт `use_vaapi=true` для amd64 явно, и мы это не убираем |
| AV1 через VA-API (`use_av1_hw_decoder`) | включено | Выводится из `is_linux && use_vaapi` |
| **V4L2-кодек** | выключен | Debian не включает его на amd64 вовсе (только `arm64`/`armhf`), так что отключение X11 его не затрагивает. Наша mesa собирается без него по правилу репозитория |
| DRM/KMS, GBM-путь | включено | Нужен для VA-API и захвата экрана, X11 не участвует |
| Захват экрана/запись (скринкаст) | PipeWire | `rtc_use_pipewire=true`, работает через портал, X11 не нужен |
| Раскладки клавиатуры | работают | `use_xkbcommon=true` — это и есть Wayland-путь, X11 не нужен |

Итог: из разрешённых правилами репозитория видов ускорения (VA-API; VDPAU в
chromium не используется вовсе, а в mesa выключен) не пострадал ни один.

**Чего chromium не умеет и не потерял:** X11-specific вещи — расширения X11,
`xprop`/`xdotool`-автоматизация, старые XEmbed-приложения как вкладки. Под
чистым Wayland они и не нужны.

## Что публикуется

| Пакет | Что внутри |
|---|---|
| `chromium` | бинарник браузера + `/etc/chromium.d` + `.desktop` |
| `chromium-common` | ресурсы: `*.pak`, локаль `en-US`, ANGLE-шимсы `libEGL.so`/`libGLESv2.so`, SwiftShader, `chrome_crashpad_handler` |
| `chromium-ru` | русская локализация: `ru.pak` + гендерные варианты |
| `chromium-sandbox` | setuid-песочница |

Не публикуются: `chromium-l10n` (заменён на `chromium-ru`, см. ниже),
`chromium-shell`, `chromium-headless-shell`, `chromium-driver` (все три —
дублирующие бинарники по 40–90 МБ; для headless хватает
`chromium --headless`). Соответствующие таргеты `ninja` не собираются вовсе,
поэтому время сборки меньше.

### Локали: только русский, а не 54 языка

Debian публикует `chromium-l10n` — 54 языка, 118 МБ после распаковки.
У нас вместо него `chromium-ru`: один язык, ~2,4 МБ.

Сделано quilt-патчем `debianization/only-russian-locale.patch` в
`build/config/locales.gni`:

```
if (is_linux) {
  platform_pak_locales = [ "ru" ]
}
```

`platform_pak_locales` — единственный список, из которого берутся все
`.pak`-файлы локалей (они объявлены в `chrome/app/generated_resources.grd`).
Ограничение списка, а не копирование готовых файлов, по двум причинам:

1. **Это убирает остальные языки из сборки вообще**, а не выбрасывает их
   после: 73 лишних `.pak` не генерируются, что экономит и время сборки;
2. **Проверяемо по исходникам**: `en-US` в `generated_resources.grd`
   отсутствует вовсе (0 вхождений `lang="en-US"`), он копируется отдельно в
   `debian/rules` (`cp out/Release/locales/en-US.pak out/Release/resources`).
   То есть английская локаль остаётся в `chromium-common` и не зависит от
   патча.

Гендерные варианты (`ru_FEMININE.pak`, `ru_MASCULINE.pak`, `ru_NEUTER.pak`)
появляются автоматически: аргумент `translate_genders` в
`build/config/locales.gni` по умолчанию равен `!is_ios`, то есть на Linux он
включён. Файлы `.pak.info` (карты идентификаторов строк) ставим вместе с
`.pak` — без них Chromium не сможет сопоставлять строки при локализации
интерфейса.

Чтобы вернуть полный набор языков, достаточно убрать патч из
`debian/patches/series` и вернуть stanza `chromium-l10n` в
`debian/control` из `debian/` Debian.

## Про два orig-тарбола

У chromium их два: `chromium_154.0.8037.92.orig.tar.xz` (995 МБ) и
`chromium_154.0.8037.92.orig-pre-gen.tar.xz` (16 МБ). Второй — файлы,
которые Chromium генерирует во время сборки (bindgen, nodejs); Debian готовит
их заранее, потому что в stable бывают слишком старые bindgen/nodejs.
`dpkg-source` требует оба.

Поэтому в `scripts/fetch-upstream.sh` и `scripts/build-package.sh` добавлена
поддержка дополнительных тарболов: список приходит из `.conf` через
`EXTRA_TARBALLS`/`EXTRA_TARBALL_URLS`. У пакетов с одним тарболом значения
пустые, поведение прежнее.

## Что не собирается

- тесты и бенчмарки (патчи `disable/tests.patch`, `disable/catapult.patch`,
  `disable/font-tests.patch` и др. оставлены);
- `chromium-driver`, `content_shell`, `headless_shell` — таргеты убраны;
- man-страница (`chromium.manpages` удалён) — по правилу репозитория;
- dbgsym-пакеты (общее правило `scripts/build-package.sh`).

Quilt-патчи Debian (259 штук) оставлены все: они привязаны к версии 154, и
пересматривать их по одной не требуется.

## Требования к CI и почему это проблема

Chromium — самый тяжёлый пакет в репозитории:

- **Диск:** ~100 ГБ (распакованное дерево 4,3 ГБ + `out/Release` с
  thin-LTO). GitHub-hosted `ubuntu-latest` даёт 4 vCPU, 16 ГБ RAM и около
  30 ГБ свободного SSD — этого **не хватает**.
- **RAM:** `use_thin_lto=true` требует 16+ ГБ на финальную линковку.
- **Время:** 4–8 часов на 4 ядрах; лимит job — 6 часов.
- **Квота:** `.deb`-артефакты `chromium` (87 МБ) + `chromium-common` (27 МБ) —
  ~114 МБ при квоте 0,5 ГБ на аккаунт, то есть треть квоты на один прогон.

Поэтому пакет требует self-hosted раннера либо другого решения инфраструктуры.


## Что произойдёт при `apt upgrade`

Штатный `chromium` из trixie — `150.0.7871.181-1~deb13u1`, наш —
`154.0.8037.92-1+crick`: и по upstream-версии, и по суффиксу мы новее, apt
подхватит.

Ожидаемые изменения состава пакетов:

1. `chromium-l10n` из trixie объявляет
   `chromium (>= 150.0.7871.181-1~deb13u1)` и
   `chromium (<< 150.0.7871.181-1~deb13u1.1~)` — то есть строго свою же версию
   с точностью до следующей. Наша `154.0.8037.92-1+crick` в этот диапазон не
   попадает, поэтому apt **снимет** `chromium-l10n`. Взамен ставится наш
   `chromium-ru` с русским языком.
2. `chromium-shell`, `chromium-headless-shell`, `chromium-driver` из trixie
   зависят на `chromium-common (= <версия trixie>)` или `chromium (= ...)` —
   точной версии у нас нет, поэтому apt **снимет** все три. Их функции:
   минимальная оболочка, headless-бинарник, WebDriver.
3. `chromium-common` из trixie Depends `x11-utils` — пакет снимется.
4. `libx11-6`, `libxext6`, `libxcb1`, `libxcomposite1`, `libxdamage1`,
   `libxfixes3`, `libxrandr2`, `libxnvctrl0` исчезнут из `Depends` нашего
   `chromium`: в сборке без X11 этих `NEEDED` нет. Если они стояли только
   ради chromium, apt их снимет — это ожидаемо для системы на чистом Wayland.
5. `libatk-bridge2.0-0t64` и `libatspi2.0-0t64` в `Depends` останутся: они
   приходят из `libgtk-3-0t64`, а не из X11 (см. ниже).

Проверить заранее:

```bash
apt-get -s upgrade
```

После установки русский язык включается в самом браузере:
Настройки → Язык → Русский. Файлы `ru*.pak` должны лежать в
`/usr/lib/chromium/locales/`.

### Про GTK3 и atk-bridge

Наш `gtk+3.0` собран без `at-spi2-core` и без ATK-моста (см.
`packages/gtk+3.0/README.md`). Chromium линкуется с `libatk-bridge-2.0`
**напрямую**: в его `NEEDED` есть `libatk-bridge-2.0.so.0`, а символ
`atk_bridge_adaptor_init` присутствует и в `libatk-bridge`, и в
`libgtk-3.so.0`. Поэтому `libatk-bridge2.0-dev` должен остаться в
`Build-Depends` — собирать chromium надо против GTK3 этого репозитория, но
libatk-bridge2.0-dev берётся из trixie: это не X11-зависимость и не нарушение
правила.

## Откат

Убрать репозиторий crick из источников и вернуть штатные версии:

```bash
apt-get install --allow-downgrades \
  chromium=150.0.7871.181-1~deb13u1 \
  chromium-common=150.0.7871.181-1~deb13u1 \
  chromium-sandbox=150.0.7871.181-1~deb13u1
apt-get install chromium-l10n chromium-shell chromium-driver chromium-headless-shell
```

Откат возвращает X11-зависимости и `x11-utils` в систему.

