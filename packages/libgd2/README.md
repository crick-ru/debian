# libgd2

Библиотека графики GD (`libgd.so.3`): рисование изображений, текст, фильтры,
форматы PNG/JPEG/AVIF/HEIF/WebP/TIFF.

## Источник упаковки

Упаковка взята из Debian (`libgd2_2.3.3-14`, `unstable`) и перерабатывается.
Tarball побайтово совпадает с Debian-овским `libgd2_2.3.3.orig.tar.gz`.
Взято из `unstable`, а не `trixie` (`2.3.3-14~deb13u1`), чтобы получить
самый свежий security-fix — ветка Debian 2.3.3 одна и та же, только
security-аплоад уже содержит CVE-исправления.

## Версии

- **В trixie:** 2.3.3-14~deb13u1
- **В исходной упаковке:** 2.3.3-14
- **В нашем репозитории:** 2.3.3-15+crick (ревизия 15)

Ревизия 15 необходима: Debian-ревизия в trixie равна 14 (2.3.3-14~deb13u1),
и наша сборка с ревизией 1 отсортировалась бы как **старая** (`1 < 14`).
`15 > 14`, и `+crick` сравнивается с `~deb13u1` как большее.

## Содержимое

| Пакет | Содержимое |
|---|---|
| `libgd3` | `libgd.so.3` — единственная библиотека |
| `libgd-dev` | заголовки, `libgd.pc`, `libgd.a`, `libgd.so` для линковки |

Не публикуется: `libgd-tools` (примеры `gddemo`, `gdtest`, `testac` + man на них).

Набор закрыт: `libgd-dev` требует ровно `libgd3 (= ${binary:Version})`.

## Что изменено

### Отключено

- **XPM (X11):** `--without-xpm`. Из `Build-Depends` удалены `libx11-dev`,
  `libxpm-dev`. Из `Depends: libgd-dev` удалены те же пакеты. В trixie `libgd3`
  зависит от `libxpm4` — это нарушало бы правило «X11 нет нигде».
- **RAQM:** `--without-raqm` (как в Debian: ломает вертикальный текст).
- **Примеры и man-страницы:** `override_dh_auto_install` удаляет `usr/bin/*`
  (утилиты `annotate`, `gdtopng`, `pngtogd`, `bdftogd` и т.д.), которые в Debian
  едут в `libgd-tools`.
- **Тесты:** каталог `debian/tests` удалён, `override_dh_auto_test` пуст.
  Четые quilt-патча, правящие `tests/` (`0002`, `0003`), оставлены — без них
  дерево не накладывается, а на символы они не влияют.
- **libtool-файлы:** `*.la` удаляются из staging-дерева.
- dbgsym-пакеты не собираются (общее правило `scripts/build-package.sh`),
  `override_dh_strip` с миграцией `libgd-dbg` удалён.

## Патчи

Шесть патчей Debian сохранены:
1. `0001-Fix-error-ISO-C99-requires-at-least-one-argument-for.patch`
2. `0002-Disable-failing-test-that-breaks-some-builds.patch`
3. `0003-tests-make-a-little-change-for-autopkgtest.patch`
4. `0004-Revert-upstream-318-fix-to-fix-the-PHP-5.6-8.0-FTBFS.patch`
5. `0005-Fix-847-enable-back-GD_BICUBIC-interpolation-methods.patch`
6. `0006-libgd-patch-for-CVE-2026-9672.patch`

## Изменения ABI

**ABI не ломается.** Единственный X11-символ `gdImageCreateFromXpm` при
отсутствии `HAVE_LIBXPM` остаётся как заглушка (`src/gdxpm.c`, ветка
`#ifndef HAVE_LIBXPM`): функция возвращает `NULL` и печатает сообщение об ошибке.
Экспортируется, SONAME остаётся `libgd.so.3`, `libgd3.symbols` не меняется.

## Важные нюансы

### Почему XPM не ломает PHP

`php8.4-gd` из trixie имеет `Depends: libgd3 (>= 2.3.3)` — **без пина версии**,
наша `2.3.3-15+crick` подходит. В `NEEDED` `gd.so` только `libgd.so.3` и
`libc.so.6` — никаких `libXpm.so.4`. Единственный X11-символ, который зовёт
`gd.so`, — `gdImageCreateFromXpm`, и он у нас есть.

Функциональная потеря: `imagecreatefromxpm()` в PHP вернёт `false` с
предупреждением; всё остальное работает.

Проверить после публикации:
```
php -r 'var_dump(gd_info());'
php -r '$i=imagecreatetruecolor(8,8); var_dump(imagepng($i));'
```

### Имя каталога

Каталог называется `libgd2`, хотя бинарный пакет — `libgd3`: имя каталога
должно совпадать с именем **исходного** пакета Debian. `dpkg-source` ищет
`../libgd2_2.3.3.orig.tar.gz` — имя `libgd3` (бинарного пакета) сломало бы
поиск (та же ловушка, что с `gtk+3.0`).

### apt upgrade

`libgd-dev` из trixie пинит `libgd3` точной версии (`-14~deb13u1`) — apt снимет
штатный `libgd-dev` и поставит наш. `libgd-tools` остаётся на своей версии
(zavisит `libgd3 (>= 2.1.0~alpha)` — нас устраивает). `libxpm4` пропадёт из
`Depends` нашей `libgd3` — если он стоял только ради libgd3, apt снимет его и
вместе с ним `libx11-6` и прочие X11-пакеты.

Проверить:
```
apt-get -s upgrade
```
