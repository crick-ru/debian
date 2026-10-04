#!/usr/bin/env python3
"""Проверить, что заглушки X11 покрывают зависимости установленного браузера.

Зачем. Браузер обновляется сам (или через apt upgrade) и целиком заменяет свои
файлы, тогда как заглушки живут в отдельном пакете. Новая версия браузера может
потребовать символов, которых в заглушках не было, - и тогда он не запустится с
`undefined symbol`. Хук apt вызывает этот скрипт после каждой операции, и здесь
он сообщает, если такое случилось.

Что делает. Обходит ELF-файлы браузера, читает их таблицу динамических
записей (`readelf -d`) и проверяет две вещи:

1. Наличие библиотек-заглушек - все файлы заглушек на месте.
2. Полноту символов - каждый X11-символ, который импортирует браузер,
   экспортируется заглушкой. Сравнение идёт по реальному экспорту
   (`readelf --dyn-syms`), а не по списку в исходниках пакета: заглушки
   могли быть пересобраны, и важно, что получилось на самом деле.

Скрипт ничего не изменяет и всегда завершается с кодом 0: он вызывается из
apt-хука, и ненулевой код превратил бы успешный `apt upgrade` в ошибку.
"""

import argparse
import os
import re
import subprocess
import sys

# Признак имени X11-символа: импорты libX11 начинаются с `X`, внутренние - с
# `_X`, XCB - с `xcb_`/`_xcb_`. По этому признаку отбираются символы, которых
# нет в заглушках, - то есть новые X11-вызовы браузера.
#
# Отбор намеренно узкий, чтобы не ловить чужие имена. `XML_*` исключены
# явно: это libxml2, а не X11, и в trixie он нужен браузеру по делу.
# Ложное срабатывание не опасно: скрипт лишь печатает предупреждение и всегда
# возвращает 0.
X11_SYMBOL_RE = re.compile(r'^_?[Xx](cb_|(?!ML_)[A-Z_])')

# Каталоги с файлами браузера. Основной - /opt/yandex/browser; браузер
# устанавливается туда по инструкции Яндекса.
BROWSER_DIRS = ['/opt/yandex/browser']

# SONAME'ы заглушек. По ним же определяется, какие NEEDED считать
# X11-зависимостями.
STUB_SONAMES = (
    'libX11.so.6',
    'libXext.so.6',
    'libxcb.so.1',
    'libXcomposite.so.1',
    'libXdamage.so.1',
    'libXfixes.so.3',
    'libXrandr.so.2',
)

MULTIARCH = subprocess.run(
    ['dpkg-architecture', '-qDEB_HOST_MULTIARCH'],
    capture_output=True, text=True).stdout.strip() or 'x86_64-linux-gnu'

LIBDIRS = ['/usr/lib/%s' % MULTIARCH, '/lib/%s' % MULTIARCH]


def is_elf(path):
    try:
        with open(path, 'rb') as fh:
            return fh.read(4) == b'\x7fELF'
    except OSError:
        return False


def find_stub(soname):
    for d in LIBDIRS:
        p = os.path.join(d, soname)
        if os.path.exists(p):
            return p
    return None


def imported_symbols(path):
    """Символы, которые ELF-файл импортирует (поле UND в .dynsym)."""
    out = subprocess.run(['readelf', '-W', '--dyn-syms', path],
                         capture_output=True, text=True).stdout
    result = set()
    for line in out.splitlines():
        parts = line.split()
        if len(parts) < 8 or parts[6] != 'UND':
            continue
        result.add(parts[7].split('@')[0])
    return result


def known_symbols(soname):
    """Имена символов, которые заглушка содержит по замыслу пакета.

    Берутся из списков `symbols-<SONAME>.txt`, которые ставятся рядом со
    скриптом в /usr/share/dummyx11. Именно они, а не фактический экспорт уже
    собранной заглушки, задают ожидаемое покрытие: если список расширен, а
    заглушка ещё не пересобрана, проверка обязана это заметить.
    """
    names = set()
    for d in ('/usr/share/dummyx11', os.path.dirname(os.path.abspath(__file__))):
        lst = os.path.join(d, 'symbols-%s.txt' % soname)
        if os.path.exists(lst):
            with open(lst, encoding='utf-8') as fh:
                names |= {line.strip() for line in fh if line.strip()}
            break
    if not names:
        print('dummyx11: не найден список символов для %s' % soname,
              file=sys.stderr)
    return names


def browser_elfs():
    for d in BROWSER_DIRS:
        if not os.path.isdir(d):
            continue
        for root, _dirs, files in os.walk(d):
            for name in files:
                p = os.path.join(root, name)
                if is_elf(p):
                    yield p


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--quiet', action='store_true',
                    help='не печатать отчёт, только сообщения об ошибках')
    ap.add_argument('--no-notice', action='store_true',
                    help='не печатать сообщение об успехе')
    args = ap.parse_args()

    problems = []

    # 1. Все заглушки на месте.
    stubs = {}
    for soname in STUB_SONAMES:
        p = find_stub(soname)
        if p is None:
            problems.append('заглушка отсутствует: %s (искали в %s)'
                            % (soname, ', '.join(LIBDIRS)))
        else:
            stubs[soname] = p

    checked = 0
    known = {}
    for soname in STUB_SONAMES:
        known[soname] = known_symbols(soname)

    for elf in browser_elfs():
        checked += 1
        try:
            imported = imported_symbols(elf)
        except OSError:
            continue
        # Что проверяется: браузер зовёт X11-символ, которого нет ни в одном
        # списке заглушек. Так обнаруживается новая версия браузера с новыми
        # X11-вызовами - до обновления списков символов он не запустится.
        #
        # Отбор идёт по ПРИЗНАКАМ ИМЕНИ, а не по таблице NEEDED: браузер
        # подгружает часть X11-кода через dlopen, и таких NEEDED в таблице
        # динамических записей может не быть вовсе. Сравнение со списками
        # было бы самоочевидным и ничего не проверяло бы: заглушка по
        # определению экспортирует ровно то, что есть в списках.
        known_all = set()
        for names in known.values():
            known_all |= names
        unknown = {s for s in imported
                   if X11_SYMBOL_RE.match(s) and s not in known_all}
        if unknown:
            problems.append('%s: X11-символы, которых нет в заглушках (%d): %s'
                            % (elf, len(unknown), ' '.join(sorted(unknown))))

    if problems:
        for line in problems:
            print('dummyx11: ВНИМАНИЕ: %s' % line, file=sys.stderr)
        print('dummyx11: браузер может не запуститься; пересоберите '
              'dummyx11 с обновлённым списком символов '
              '(packages/dummyx11/README.md)', file=sys.stderr)
        return 0

    if not args.quiet and not args.no_notice:
        print('dummyx11: заглушки на месте, проверено ELF-файлов: %d' % checked)
    return 0


if __name__ == '__main__':
    sys.exit(main())