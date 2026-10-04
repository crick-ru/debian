# at-spi2-core

Упаковка взята из Debian (`at-spi2-core_2.56.2-1+deb13u2`, ветка 13) и
переработана под правила репозитория. Tarball побайтово совпадает с
Debian-овским `at-spi2-core_2.56.2.orig.tar.xz` — ни repack, ни `+dfsg` здесь
не применяется.

## Зачем пакет в репозитории

Официальный `yandex-browser-stable` требует `libatk-bridge2.0-0` и
`libatspi2.0-0`, а штатный `libatspi.so.0` из trixie линкуется с
`libX11.so.6` и `libXi.so.6`. Поставить его в систему без X11 нельзя.

Этот пакет — тот же `at-spi2-core`, но собранный с `-Dx11=disabled`, поэтому
`libatspi.so.0` не зависит ни от `libX11`, ни от `libXi`.

## Отключение X11

Апстрим содержит готовую опцию:

```
# meson_options.txt
option('x11', description: 'Enable X11 support', type: 'feature', value: 'auto')
```

При `-Dx11=disabled` в `meson.build` не выполняется блок
`if x11_dep.found()`, поэтому:

- `x11_deps` остаётся пустым и в `atspi_deps` (`atspi/meson.build`) не
  попадает — `libatspi.so.0` не линкуется с X11;
- `atspi-device-x11.c` не компилируется (`atspi/meson.build`);
- `HAVE_X11` не определяется в `config.h`, а весь X11-код (`atspi-misc.c`,
  `atspi-device-legacy.c`, `atspi-device.c`, `registryd/deviceeventcontroller.c`)
  заключён в `#ifdef HAVE_X11`.

Проверка результата:

```bash
readelf -d /usr/lib/x86_64-linux-gnu/libatspi.so.0 | grep NEEDED
```

В списке не должно быть ни `libX11.so.6`, ни `libXi.so.6`.

Опция покрывает X11 целиком — патчей для этого не потребовалось, все четыре
quilt-патча упаковки Debian применяются без изменений.

## Что ещё отключено по правилам репозитория

- **X11-сессия.** Из `libatk-adaptor.install` и `at-spi2-core.install` убраны
  строки `debian/90atk-adaptor etc/X11/Xsession.d` и
  `debian/90qt-a11y etc/X11/Xsession.d`: это запуск из X11-сессии, которой на
  чистом Wayland не бывает. Автозапуск в Wayland обеспечивает
  `etc/xdg/Xwayland-session.d/00-at-spi`, который устанавливается как обычно.
  Строки `*.conf → etc/environment.d` остались: они не X11-специфичны.
- **Тесты.** `override_dh_auto_test` пуст. В Debian тесты гонялись через
  `xvfb-run`, а `xauth` и `xvfb` стояли в `Build-Depends` под профилем
  `nocheck` — это прямо противоречит правилу «никакого X11».
- **Документация.** `-Ddocs=false`, пакеты `at-spi2-doc` и
  `libatk1.0-doc` удалены из `debian/control`.
- **udeb.** Пять udeb-пакетов не собираются: это Debian Installer, а не
  обычная система. Из `debian/rules` убраны все `--add-udeb`.
- **dbgsym.** Общее правило `scripts/build-package.sh`.

## Что осталось в пакетах

`at-spi2-core`, `at-spi2-common`, `libatspi2.0-0t64`, `libatspi2.0-dev`,
`gir1.2-atspi-2.0`, `libatk1.0-0t64`, `libatk1.0-dev`, `gir1.2-atk-1.0`,
`libatk-bridge2.0-0t64`, `libatk-bridge2.0-dev`, `libatk-adaptor`.

Символьные файлы Debian (`libatspi2.0-0t64` не имеет своего, а
`libatk1.0-0t64` и `libatk-bridge2.0-0t64` имеют) оставлены как есть:
отключение X11 не добавляет и не убирает символов, ABI не меняется,
SONAME прежний.

## Исключение из правил репозитория

Правило репозитория — брать максимально свежие версии. Здесь намеренно взята
версия trixie (2.56.2), а не более свежая апстримовая: пересборка на новой
версии потребовала бы пересмотра quilt-патчей, а задача пакета (доступность
без X11) от версии не зависит. Причина появления пакета — зависимость
чужого бинарного пакета, который пересобрать нельзя.

## Проверка

```bash
# правила репозитория: пустой вывод = ок
grep -rniE 'libx(11|ext|render)|libxcb|xtst|xvfb|xauth' packages/at-spi2-core/debian/control \
  | grep -vE '^[^:]*:[0-9]+:[[:space:]]*#'

# фактические зависимости собранной библиотеки
readelf -d libatspi.so.0 | grep NEEDED
```