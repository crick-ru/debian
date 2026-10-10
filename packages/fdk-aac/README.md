# fdk-aac (crick Debian backports)

Сборка `fdk-aac` 2.0.3 для Debian 13 (trixie): библиотека Fraunhofer FDK AAC.
Главная причина сборки — предоставление AAC-кодека, необходимого модулю
Bluetooth в pipewire.

Упаковка взята из Debian (`fdk-aac_2.0.3-1`, unstable) и переработана.
Файл апстрима берётся с того же GitHub-тега, что и Debian.

> Библиотека распространяется под несвободной лицензией (Fraunhofer). В нашем
> репозитории поставляется в единой секции `backports`.

## Включено

- Только библиотека: `libfdk-aac2t64` и `libfdk-aac-dev`. Пара закрытая:
  `-dev` требует `libfdk-aac2t64 (= ${binary:Version})`.

## Отключено

- **Пример `aac-enc` не собирается**: флаг `--enable-example` убран из
  `debian/rules` (настройка теперь целиком у debhelper), пакет `aac-enc` не
  публикуется, удалены `aac-enc.1`, `aac-enc.docs`, `aac-enc.install` и
  `aac-enc.manpages`. Вместе с примером уходит и PDF-документация из
  `documentation/*.pdf` — она ставилась тем же `--enable-example`.
- Отладочные символы (`-dbgsym`) не собираются и не публикуются.

## Изменено

- Версия: `2.0.3-2+crick` (ревизия 2 — из-за переработки упаковки).
- Патч `add_more_arch` расширяет список поддерживаемых архитектур в
  `libFDK/include/FDK_archdef.h` (в апстриме список минимален).
- `DEB_LDFLAGS_MAINT_APPEND = -Wl,--no-undefined`: разделяемая библиотека не
  должна содержать неразрешённых символов.
- Пакеты имеют суффикс `+crick`, поэтому `pipewire` из этого репозитория
  может жёстко зависеть именно от этой сборки: `libfdk-aac-dev` требует
  `libfdk-aac2t64 (= 2.0.3-2+crick)`.

