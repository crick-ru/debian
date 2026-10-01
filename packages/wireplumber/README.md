# wireplumber (crick Debian backports)

Сборка `wireplumber` 0.5.17 для Debian 13 (trixie) — сессионный менеджер
(session/policy manager) для PipeWire и GObject-обёртка над его API.

## Зачем он нужен в этом репозитории

Главная причина — **`pwvucontrol`**. Наш pwvucontrol 0.5.3 требует
`wireplumber-0.5 >= 0.5.11`, а в trixie только 0.5.8, то есть без этого
пакета pwvucontrol не собирается в принципе. Проверка версии стоит в
`meson.build` апстрима:

```
dependency('wireplumber-0.5', version: '>= 0.5.11')
```

Дополнительно wireplumber — сам session manager системы: без него
`pipewire` из этого репозитория не запускает пользовательские сессии.

В trixie это `8:0.5.8` → здесь `0.5.17-1+crick`, то есть новее на девять
минорных релизов. ABI не менялся: SONAME остался `libwireplumber-0.5.so.0`.

## Включено

- Демон, модули и утилиты (`-Dmodules=true -Ddaemon=true -Dtools=true`).
- Lua из системы: `-Dsystem-lua=true` (в trixie есть `liblua5.4-dev`).
- systemd-интеграция и logind: `-Dsystemd=enabled`, пользовательские
  службы; системные службы — отдельным пакетом
  `wireplumber-system-services` (с `--no-enable --no-start`, как в Debian).

## Отключено

- **Документация и man-страницы** (`-Ddoc=disabled`): пакет
  `wireplumber-doc` не публикуется, удалены `wireplumber-doc.doc-base`,
  `wireplumber-doc.install`, `wireplumber-doc.manpages` и
  `wireplumber-doc.lintian-overrides`, из `Build-Depends` убраны
  `doxygen`, `python3-breathe`, `python3-sphinx`,
  `python3-sphinx-rtd-theme`. В пакетах не остаётся страниц `wpctl.1`
  и man7 для модулей. `lintian-overrides` для `wireplumber` тоже удалён:
  он подавлял именно жалобу на отсутствие man-страницы у `wpctl`.
- **GObject-интроспекция** (`-Dintrospection=disabled`): пакет
  `gir1.2-wp-0.5` не публикуется, удалён `gir1.2-wp-0.5.install` и строка
  `/usr/share/gir-1.0/*.gir` из `libwireplumber-0.5-dev.install`, из
  `Build-Depends` убраны `dh-sequence-gir`, `gobject-introspection`,
  `gir1.2-gio-2.0-dev`, `gir1.2-gobject-2.0-dev`, а из `Depends` пакета
  `libwireplumber-0.5-dev` — `gir1.2-wp-0.5 (= ${binary:Version})`.
  - **Почему:** апстрим подключает `docs/meson.build` безусловно, и именно
    включённая интроспекция делает две вещи жёсткими: `python3` с модулем
    `lxml` (`required: get_option('introspection')`) и `doxygen`
    (`required: true`, если `doc` или `introspection` включены). В trixie это
    9 дополнительных пакетов — `libllvm19`, `libclang-cpp19`, `libclang1-19`,
    `libz3-4`, `libxslt1.1`, `libxapian30`, `libfmt10`, ~150 МБ — ради одного
    типилиба. Это ровно тот toolchain, который правило репозитория («документация
    и её зависимости не собираются») запрещает тянуть в CI.
  - **Что теряется:** типилиб `Wp-0.5.typelib`, то есть GObject-API
    WirePlumber для приложений на языках с биндингами gir (python3-gi и
    подобные). Ни один пакет этого репозитория его не использует:
    `pwvucontrol` работает через Rust-FFI (`libwireplumber-0.5-dev` даёт
    заголовки и `pkgconfig`), сборка и запуск не требуют типилиба.
  - **Масштаб для пользователя:** в trixie от `gir1.2-wp-0.5` зависит
    только `libwireplumber-0.5-dev`, а он у нас свой и этой зависимости
    больше не содержит; `waybar` и `wireplumber` из trixie зависят от
    `libwireplumber-0.5-0`, который публикуется по-прежнему. Пакет
    `gir1.2-wp-0.5` ещё никогда не публиковался в этом репозитории (в
    опубликованном индексе его нет), поэтому `apt upgrade` ни у кого ничего
    не удалит; убрать его можно только у того, кто поставил его вручную:
    `apt-get purge gir1.2-wp-0.5`.
  - **Как вернуть:** в `debian/rules` заменить `-Dintrospection=disabled` на
    `enabled`, вернуть в `Build-Depends` `dh-sequence-gir`,
    `gobject-introspection (>= 1.80)`, `gir1.2-gio-2.0-dev`,
    `gir1.2-gobject-2.0-dev`, восстановить stanza `gir1.2-wp-0.5` и файл
    `gir1.2-wp-0.5.install` с `/usr/lib/*/girepository-1.0`, вернуть строку
    `/usr/share/gir-1.0/*.gir` в `libwireplumber-0.5-dev.install` и
    зависимость `gir1.2-wp-0.5 (= ${binary:Version})` в
    `libwireplumber-0.5-dev`; в списке установки `pwvucontrol` в
    `.github/workflows/build.yml` вернуть `./stage5-pool/gir1.2-wp-0.5_*.deb`.
    Поскольку пакет ещё не публиковался, ревизию поднимать не нужно.

- **Тесты** (`-Dtests=false -Ddbus-tests=false`): каталог `debian/tests`
  (autopkgtest) удалён, `override_dh_auto_test` пуст. Тестовое дерево
  `tests/` и вспомогательные программы не собираются. Из `Build-Depends`
  убраны `dbus-daemon` и `pipewire` — они были нужны ровно для тестов.
- **Примеры конфигураций** (сохраняются): апстрим ставит каталог
  `wireplumber.conf.d.examples` как файлы данных в
  `/usr/share/doc/wireplumber/examples/wireplumber.conf.d`
  (`src/config/meson.build`, `install_subdir`), отключить это опцией нельзя.
  Это примеры конфигурационных файлов, поэтому они остаются — разрешённое
  исключение из правила «примеры не публикуются»; путь перечислен в
  `debian/wireplumber.install`. Рабочие конфиги лежат отдельно, в
  `/usr/share/wireplumber/wireplumber.conf.d`.
- X11 в апстриме **отсутствует как таковой**: ни `libx11`/`libxcb` в
  `Build-Depends`, ни X11-кода в `lib/`, `modules/`, `src/` (проверено
  `grep -rniE 'libx(11|ext|render)|libxcb'` по исходникам — пусто).
  Правило «X11 нет нигде» соблюдается автоматически, ничего отключать
  не пришлось.

## Изменено

- Версия: `0.5.17-1+crick` (ревизия 1 — первая публикация пакета в
  этом репозитории).
- Патч `Remove-privacy-breach-documentation.patch` перенесён из Debian:
  убирает из `README.rst` бейджи, которые при рендеринге в HTML
  показывают внутренние адреса инфраструктуры проекта.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.
