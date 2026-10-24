# fdk-aac

Библиотека Fraunhofer FDK AAC (AAC-кодек).

## Источник упаковки

Упаковка взята из Debian (`fdk-aac_2.0.3-1`, ветка unstable) и переработана.
Tarball берётся с того же GitHub-тега, что и Debian.

## Версии

- **В trixie:** 2.0.3-1
- **В исходной упаковке:** 3.0.0-1
- **В нашем репозитории:** 3.0.0-3+crick (ревизия 3)

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libfdk-aac2t64` | `libfdk-aac.so.2` (SONAME не изменился — ABI совместим с 2.0.x) |
| `libfdk-xhe-aac0` | `libfdk-xhe-aac.so.0` (новая библиотека xHE-AAC encoder в 3.0.0) |
| `libfdk-aac-dev` | заголовки, `libfdk-aac.so`, `fdk-aac.pc`-файл |
| `libfdk-xhe-aac-dev` | заголовки `fdk-xhe-aac/`, `libfdk-xhe-aac.so`, `fdk-xhe-aac.pc`-файл |

Пара закрыта: `libfdk-aac-dev` требует `libfdk-aac2t64 (= ${binary:Version})`.

## Что изменено

### Отключено

- **Пример `aac-enc` не собирается:** флаг `--enable-example` убран из
  `debian/rules`, пакет `aac-enc` не публикуется, удалены `aac-enc.1`,
  `aac-enc.docs`, `aac-enc.install` и `aac-enc.manpages`. Вместе с примером
  уходит и PDF-документация из `documentation/*.pdf`.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`).

### Включено

- Только библиотека и dev-пакет.

## Патчи

В 3.0.0 патч `add_more_arch` больше не нужен: поддержка sparc и s390x
уже включена в апстрим (`cpp/libFDK/include/FDK_archdef.h`).

## Важные нюансы

- **Лицензия:** библиотека распространяется под несвободной лицензией
  Fraunhofer. В репозитории поставляется в одной секции `backports`.
- **Зачем нужен:** главная причина сборки — предоставление AAC-кодека,
  необходимого модулю Bluetooth в `pipewire` (см. `packages/pipewire/README.md`).
- **Версия `+crick`:** `libfdk-aac-dev` требует `libfdk-aac2t64 (=
  3.0.0-1+crick)`, поэтому `pipewire` из этого репозитория может жёстко зависеть
  именно от этой сборки.
- **Major bump 2.0.3 → 3.0.0:** в 3.0.0 добавлена отдельная библиотека
  `fdk-xhe-aac` с xHE-AAC encoder. Старая библиотека `fdk-aac` остаётся
  ABI-совместимой (SONAME `libfdk-aac.so.2` не изменилась), но major bump
  означает, что `pipewire` (зависящий от `libfdk-aac2t64 (= ${binary:Version})`)
  должен быть пересобран против новой версии.
