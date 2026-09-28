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
- GObject-introspection: `-Dintrospection=enabled`, поэтому
  `gir1.2-wp-0.5` публикуется, а `libwireplumber-0.5-dev` тянет его
  зависимостью.

## Отключено

- **Документация и man-страницы** (`-Ddoc=disabled`): пакет
  `wireplumber-doc` не публикуется, удалены `wireplumber-doc.doc-base`,
  `wireplumber-doc.install`, `wireplumber-doc.manpages` и
  `wireplumber-doc.lintian-overrides`, из `Build-Depends` убраны
  `doxygen`, `python3-breathe`, `python3-sphinx`,
  `python3-sphinx-rtd-theme`. В пакетах не остаётся страниц `wpctl.1`
  и man7 для модулей. `lintian-overrides` для `wireplumber` тоже удалён:
  он подавлял именно жалобу на отсутствие man-страницы у `wpctl`.
- **Тесты** (`-Dtests=false -Ddbus-tests=false`): каталог `debian/tests`
  (autopkgtest) удалён, `override_dh_auto_test` пуст. Тестовое дерево
  `tests/` и вспомогательные программы не собираются. Из `Build-Depends`
  убраны `dbus-daemon` и `pipewire` — они были нужны ровно для тестов.
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
