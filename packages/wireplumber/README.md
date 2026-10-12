# wireplumber

Модульный session/policy manager для PipeWire: управление устройствами,
маршрутизация аудио/видео, политика доступа.

## Источник упаковки

Упаковка взята из Debian (`wireplumber_0.5.17-1`, ветка unstable) и
перерабатывается. Tarball побайтово совпадает с официальным релизом GitLab:
`wireplumber_0.5.17.orig.tar.xz`.

## Версии

- **В trixie:** 0.5.8-1
- **В исходной упаковке:** 0.5.17-1
- **В нашем репозитории:** 0.5.17-1+crick (ревизия 1)

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libwireplumber-0.5-0` | `libwireplumber-0.5.so.0` — обёртка над PipeWire API |
| `libwireplumber-0.5-dev` | заголовки, `.pc` |
| `wireplumber` | демон и CLI-утилиты (`wpctl`, `wpexec`) |
| `wireplumber-system-services` | системные systemd-юниты |

## Что изменено

### Отключено

- **Документация и man-страницы:** `-Ddoc=disabled`. Пакет `wireplumber-doc`
  не публикуется, удалены `wireplumber-doc.*`. Из `Build-Depends` удалены
  `doxygen`, `python3-breathe`, `python3-sphinx`,
  `python3-sphinx-rtd-theme`.
- **GObject-интроспекция:** `-Dintrospection=disabled`. Пакет `gir1.2-wp-0.5`
  не публикуется, удалён `gir1.2-wp-0.5.install`. Из `Build-Depends` удалены
  `dh-sequence-gir`, `gobject-introspection`, `gir1.2-gio-2.0-dev`,
  `gir1.2-gobject-2.0-dev`. Из `Depends` `libwireplumber-0.5-dev` удалена
  `gir1.2-wp-0.5`.
- **Тесты:** `-Dtests=false -Ddbus-tests=false`. Каталог `debian/tests` удалён,
  `override_dh_auto_test` пуст. Из `Build-Depends` удалены `dbus-daemon`,
  `pipewire`.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- **Демон, модули и утилиты:** `-Dmodules=true -Ddaemon=true -Dtools=true`.
- **Lua из системы:** `-Dsystem-lua=true`.
- **systemd:** `-Dsystemd=enabled`, пользовательские и системные службы.

## Патчи

Один патч Debian: `Remove-privacy-breach-documentation.patch` — убирает из
`README.rst` бейджи, которые при рендеринге в HTML показывают внутренние
адреса инфраструктуры проекта.

## Изменения ABI

`libwireplumber-0.5.so.0` — SONAME не меняется, удалённых символов нет.

## Важные нюансы

### Зачем нужен

`pwvucontrol 0.5.3` требует `wireplumber-0.5 >= 0.5.11` (проверка в
`meson.build` апстрима). В trixie только 0.5.8 — pwvucontrol не собирается.
Дополнительно wireplumber — session manager системы: без него `pipewire`
из этого репозитория не запускает пользовательские сессии.

### Почему выключена интроспекция

Апстрим подключает `docs/meson.build` безусловно, и именно включённая
интроспекция делает две вещи жёсткими: `python3` с модулем `lxml`
(`required: get_option('introspection')`) и `doxygen`
(`required: true`, если `doc` или `introspection` включены). В trixie это
9 дополнительных пакетов (~150 МБ `libllvm19`, `libclang-cpp19`, …) ради одного
типилиба.

**Что теряется:** типилиб `Wp-0.5.typelib` — GObject-API для приложений на
языках с биндингами gir (python3-gi и подобные). Ни один пакет этого
репозитория его не использует: `pwvucontrol` работает через Rust-FFI
(заголовки и `pkgconfig` из `libwireplumber-0.5-dev`, сборка и запуск не
требуют типилиба).

### Примеры конфигураций сохраняются

Апстрим устанавливает каталог `wireplumber.conf.d.examples` как файлы данных
в `/usr/share/doc/wireplumber/examples/`. Отключить нельзя (нет опции), поэтому
они сохраняются — разрешённое исключение из правила «примеры не публикуются»
(это конфигурационные файлы, а не код/документация). Путь перечислен в
`debian/wireplumber.install`.

### X11

В апстриме отсутствует как таковой: ни `libx11`/`libxcb` в `Build-Depends`,
ни X11-кода в `lib/`/`modules/`/`src/` (проверено grep — пусто). Правило
«X11 нет нигде» соблюдается автоматически.

### apt upgrade

В trixie от `libwireplumber-0.5-0` зависят только `libwireplumber-0.5-dev`
(наш, без зависимости от `gir1.2-wp-0.5`) и `wireplumber`/`waybar`. Пакет
`gir1.2-wp-0.5` никогда не публиковался в этом репозитории — его можно удалить
вручную: `apt-get purge gir1.2-wp-0.5`.
