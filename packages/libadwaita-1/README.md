# libadwaita-1

Библиотека с виджетами GTK для мобильных устройств (libadwaita). Содержит
`libadwaita-1.so.0`, GIR-данные `gir1.2-adw-1` и dev-файлы для сборки
клиентских GTK-приложений вроде celluloid.

## Источник упаковки

Упаковка взята из Debian trixie (`libadwaita-1_1.7.6-1~deb13u1`) и
перерабатывается под нужный апстрим. GNOME orig.tar 1.8.8 скачивается
отдельно — Debian не упаковывал 1.8.x.

## Версии

- **В trixie:** 1.7.6
- **В исходной упаковке:** 1.7.6-1~deb13u1 (Debian trixie)
- **В нашем репозитории:** 1.8.8-1+crick (ревизия 1)

Причина смены версии: libadwaita 1.10.0 (и его упаковка 1.10.0-2 из
unstable) требует `glib >= 2.89.3` (development release) и `GTK4 >= 4.23.1`,
которые недоступны в Debian trixie (glib 2.84.4, GTK 4.18.6). Вернёмся на
1.8.8: требует `glib >= 2.80.0` и `GTK4 >= 4.19.4` — обе версии доступны
в trixie (glib 2.84.4) или нашем репозитории (GTK 4.22.5).

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libadwaita-1-0` | `libadwaita-1.so.0` |
| `libadwaita-1-dev` | заголовки, `libadwaita-1.so`, `libadwaita-1.pc`, typelib |
| `gir1.2-adw-1` | GIR-данные для libadwaita |

## Что изменено

### Отключено

- **Документация:** `-Ddocumentation=false`. Удалён пакет `libadwaita-1-doc`,
  из `Build-Depends` удалены `gi-docgen`.
- **Примеры:** `-Dexamples=false`. Удалён пакет `libadwaita-1-examples`.
- **Тесты:** `-Dtests=false`. `override_dh_auto_test` пуст, удалён каталог
  `debian/tests`, из `Build-Depends` удалены `xvfb`, `xauth`, `python3-gi`,
  `mesa-vulkan-drivers`.
- **X11:** `libgnome-desktop-3-dev` удалён из `Build-Depends` и `Depends` — он
  тащит `libgtk-3-dev` и `libxkbcommon-x11-dev` (X11), а 1.8.8 `meson.build`
  не использует libgnome-desktop (см. `meson.build:146`).
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Повышены версии в Build-Depends/Depends

- `libgtk-4-dev` — `>= 4.19.4` (в 1.7.6 было `>= 4.17.5`). Это заставляет
  CI использовать наш GTK 4.22.5 (без X11-символов) вместо trixie 4.18.6.

## Патчи

Два патча из Debian 1.7.6:
- `stylesheet-common-Use-disabled-opacity-for-disabled-pictu.patch` —
  использует непрозрачность для отключённых изображений.
- `#stylesheet-common-Use-opacity-for-all-disabled-gtk-images.patch` —
  закомментирован: не применяется к 1.8.8 (Hunk FAILED at line 34; нужное
  поведение уже покрывается первым патчом).

## Изменения ABI

Символьный файл `libadwaita-1-0.symbols` основан на 1.7.6 и расширен 32
символами, появившимися в 1.8 (теги `1.8~alpha` / `1.8~beta`), перенятыми из
упаковки 1.10.0. SONAME (`libadwaita-1.so.0`) не меняется — 1.8.8 ABI-совместима
с 1.7.x.

## Важные нюансы

### celluloid

celluloid 0.30 требует `libadwaita-1 >= 1.8.0`, а в Debian trixie доступна
лишь 1.7.6. Пакет `libadwaita-1-dev` из этого репозитория (версия 1.8.8)
удовлетворяет этому требованию.
