# neatvnc (crick Debian backports)

`neatvnc` 1.0.1 — библиотека VNC-сервера для Debian 13 (trixie, amd64).

Версия: `1.0.1+dfsg-1+crick`.

Упаковка взята из Debian (`neatvnc_1.0.1+dfsg-1`) и переработана.

## Зачем он здесь

`wayvnc` 0.10.1 собирается против `libneatvnc-dev`, и требует версию
**не ниже 1.0.0**. В trixie только 0.9.1, и к тому же он называется
`libneatvnc0`, а не `libneatvnc1`. Поэтому neatvnc 1.0.1 собирается здесь.

Сам по себе neatvnc тоже ничему в репозитории не нужен: это сборочная
зависимость wayvnc, как `aml`.

## Что публикуется

| Пакет | Что внутри |
|---|---|
| `libneatvnc1` | `libneatvnc.so.1` |
| `libneatvnc-dev` | заголовки, `libneatvnc.so`, `neatvnc.pc` |

## Почему стадия 3

`neatvnc` собирается против двух наборов пакетов этого репозитория:

- **нашего FFmpeg** (`libavcodec-dev`, `libavfilter-dev`, `libavutil-dev`) —
  `libavfilter-dev` пинит `libavfilter12`, а тот `libavformat63`, поэтому
  в список установки стадии входит вся нужная часть набора FFmpeg;
- **нашей mesa** (`libgbm-dev`) — без неё `libneatvnc1` линковался бы с
  `libgbm1` из trixie, а тот тянет X11 через
  `mesa-libgallium → libgl1-mesa-dri → libx11-6`.

FFmpeg собран в стадии 1, mesa — в стадии 2, поэтому neatvnc стоит в стадии 3.

## Что изменено по сравнению с Debian

| Что | Debian | Здесь | Зачем |
|---|---|---|---|
| тесты | `-Dtests=true`, гоняет `meson test` | `-Dtests=false`, `override_dh_auto_test` убран | правило «тесты не собираются» |
| `openssl` | `Build-Depends: openssl <!nocheck>` | убран | это сборочная зависимость тестов |
| TLS-зависимость | `gnutls-dev` (виртуальный пакет) | `libgnutls28-dev` | реальное имя пакета |
| примеры | `libheif-dev.examples`-подобный файл | удалён | правило «примеры не публикуются» |
| README | ставится в `/usr/share/doc` | удалён | правило «документация не публикуется» |
| dbgsym | — | не собираются | общее правило `scripts/build-package.sh` |

## Что не собирается

- примеры и бенчмарки (`-Dexamples=false`, `-Dbenchmarks=false` — это же
  значение по умолчанию в апстриме);
- dbgsym-пакеты.

X11, оптические диски, DVB и VDPAU в neatvnc не применяются: библиотека
работает только с DRM/GBM, Wayland-протоколами и сжатием FFmpeg. JACK,
libcaca, libaa1 и at-spi2-core тоже не встречаются — у neatvnc таких
возможностей нет.

## Что произойдёт при `apt upgrade`

`libneatvnc0` от trixie **останется установленным** (другое имя пакета).
`libaml0t64` — тоже. Они просто перестанут использоваться: их заменят
`libneatvnc1` и `libaml1`. Штатный `wayvnc` от trixie при этом продолжает
работать — он линкуется к `libneatvnc.so.1` любой версии, а SONAME не
изменился.

Очистить лишнее:

```bash
sudo apt autoremove
```

## Откат

```bash
sudo apt remove libneatvnc1 libneatvnc-dev
```

## `libgbm-dev` берётся из этого репозитория

`libgbm-dev`, `libgbm1` и `mesa-libgallium` ставятся из нашей `mesa`
(см. `CLOSURE_EXCEPT` в `scripts/gen-workflow.py` — исключений нет). Зависимость
`mesa-common-dev` от `libgl-dev` (который объявляет `Breaks: mesa-common-dev`)
убрана: GL не собирается, заголовки не требуются, `libegl-dev` ставится без
конфликтов. Подробности — в `packages/mesa/README.md`.
