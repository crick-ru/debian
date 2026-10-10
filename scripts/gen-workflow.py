#!/usr/bin/env python3
"""Генератор .github/workflows/build.yml: стадии -> граф по пакетам.

Зачем. Пока сборка описана стадиями (`stage3: needs: stage2`), пакет ждёт
ВСЕХ пакетов предыдущей стадии, даже тех, от которых он не зависит: gtk+3.0
не зависит от mesa, но ждал её 16 минут. Граф по пакетам снимает барьер -
`needs` указывает конкретные пакеты-поставщики.

Списки .deb НЕ переписываются заново: генератор читает их из текущего build.yml
дословно вместе с поясняющими комментариями и переносит в job каждого пакета.
Единственный источник истины по составу пакетов - сам workflow, поэтому
check-ci-deps.py продолжает проверять именно то, что реально ставится.

Использование:
  scripts/gen-workflow.py            # напечатать сгенерированный workflow
  scripts/gen-workflow.py --check    # сравнить с текущим файлом (код 1 = расхождение)
"""

import os
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(SCRIPT_DIR)
WORKFLOW = os.path.join(REPO, '.github', 'workflows', 'build.yml')

JOB_RE = re.compile(r'^  (stage[0-9]+):$')
MATRIX_PKG_RE = re.compile(r'^ {10}- (\S+)$')
GEN_JOB_RE = re.compile(r'^  build_[A-Za-z0-9_-]+:$', re.M)
LEVEL_RE = re.compile(r'path: stage(\d+)-pool')
CASE_RE = re.compile(r'^ {12}([\w.+-]+(?:\|[\w.+-]+)*)\)$')
DEB_RE = re.compile(r'\./stage(\d+)-pool/([A-Za-z0-9][A-Za-z0-9.+-]*)_\*\.deb')
# Помечает служебные комментарии замыкания, чтобы не добавлять их повторно
# при перегенерации (иначе список разрастался бы на каждом запуске).
MARK = 'ci-closure: '

FULL = open(WORKFLOW).read()
HEADER = FULL.split('\njobs:')[0] + '\n'
# Хвост начиная с job публикации переносится дословно: генератор отвечает за
# граф сборки, но не за подписание и публикацию.
TAIL = '\n' + FULL.split('\n  publish:', 1)[1].join(['  publish:', ''])
if TAIL.strip() == 'publish:':
    TAIL = ''
else:
    # Ensure publish job has container credentials (needed for Docker Hub rate limits)
    # Only add if not already present - check if credentials exist after container:
    if 'container:' in TAIL:
        after_container = TAIL.split('container:')[1]
        # The container block ends at the next key with 4-space indent (e.g., 'permissions:')
        # Find where the container block ends (next line starting with 4 spaces + word:)
        lines = after_container.split('\n')
        container_lines = []
        for line in lines:
            if line.startswith('    ') and ':' in line and not line.startswith('      '):
                # This is a top-level key (4 spaces), not part of container
                break
            container_lines.append(line)
        container_block = '\n'.join(container_lines)
        if 'credentials:' not in container_block:
            TAIL = TAIL.replace(
                '    container:\n      image: debian:trixie',
                '    container:\n      image: debian:trixie\n      credentials:\n        username: ${{ secrets.DOCKERHUB_USERNAME }}\n        password: ${{ secrets.DOCKERHUB_TOKEN }}'
            )


def build_deps():
    """{исходный пакет: {её бинарные пакеты в Build-Depends}}.

    Читается из packages/*/debian/control и служит для замыкания: если
    пакет требует сборочную зависимость, которую публикует этот же
    репозиторий, ставить её нужно отсюда, а не из trixie.

    Соблюдаются <...>‑ограничения Debian: положительные (<cross>, <stage1>)
    в том числе `<cross>` означают «только для кросс‑сборки», так что для
    нативной amd64‑сборки такие deps не берутся — иначе пакет, зависящий от
    собственного `<cross>`‑бинаря (как wayland от libwayland-bin <cross>),
    попадает в замыкание сам на себя и ставит свои stage1‑дебы в собственный
    job (BAD-PATH). Отрицания (<!stage1>, <!nocheck>) — наоборот, нужны, берутся.
    """
    result = {}
    # Имя, за которым сразу следует положительное <X> (без «!») — исключаем.
    CROSS_DEP_RE = re.compile(
        r'([a-z0-9][a-z0-9+.\-]*)\s*(?:\([^)]*\)\s*)?'
        r'(?:\[[^\]]*\]\s*)?<[^!][^>]*>')
    for control in sorted(os.listdir(os.path.join(REPO, 'packages'))):
        path = os.path.join(REPO, 'packages', control, 'debian', 'control')
        if not os.path.exists(path):
            continue
        for stanza in re.split(r'\n\n', open(path).read()):
            source = re.search(r'^Source:\s*(\S+)', stanza, re.M)
            package = re.search(r'^Package:\s*(\S+)', stanza, re.M)
            name = source.group(1) if source else (package.group(1) if package else None)
            if name != control:
                continue
            field = re.search(r'^Build-Depends:\s*(.*?)(?=^[A-Z][a-zA-Z-]*:|\Z)',
                              stanza, re.M | re.S)
            if field:
                deps = set(re.findall(
                    r'(?:^|[\s,(])([a-z0-9][a-z0-9+.\-]*)', field.group(1)))
                for excluded in CROSS_DEP_RE.findall(field.group(1)):
                    deps.discard(excluded)
                result[control] = deps
    return result


def deb_sets(text):
    """{исходный пакет: {(уровень, бинарный пакет)}} - наборы .deb из workflow."""
    result = {}
    for stage, deb in DEB_RE.findall(text):
        if deb in OWNER:
            result.setdefault(OWNER[deb], set()).add((int(stage), deb))
    return result


# Исключения из правила «свои зависимости берём из своего репозитория».
# {пакет: (поставщик, чью сборку этот пакет НЕ берёт)}. Пусто: исключений
# больше нет. Оно было нужно, пока mesa-common-dev зависела от libgl-dev —
# тот объявляет Breaks: mesa-common-dev, и установка libegl-dev становилась
# неразрешимой. Зависимость убрана, CLOSURE_EXCEPT оставлено как место для
# следующих случаев: молчаливый обход правила опаснее явного.
CLOSURE_EXCEPT = {}

# Пакеты, требующие нестандартного раннера, задавались здесь таблицей
# RUNNER_OVERRIDE: chromium требовал self-hosted с бо́льшим диском и памятью,
# и его нельзя было убрать без continue-on-error (иначе publish ждал бы job
# вечно). Сейчас таких пакетов нет, поэтому и таблицы нет: если появится
# пакет, которому ubuntu-latest не хватает, её надо вернуть вместе с
# обоснованием - молча упавший job тянет за собой публикацию репозитория.

DEFAULT_RUNNER = 'ubuntu-latest'


def runner_for(package):
    """Строка runs-on для пакета."""
    return DEFAULT_RUNNER


def continue_on_error_for(package):
    """Нужен ли continue-on-error: job не должен ронять публикацию репозитория."""
    return False

# Эталонный набор .deb для поставщика: какой набор его пакетов кладёт в список
# потребителя. Берётся из самого workflow — если набора нет, замыкание падает
# (CLOSURE_EXCEPT мог скрыть отсутствие набора, и это молчание стоило нам
# одного неудачного прогона CI).
DEB_SETS = {
    'mesa': ((2, 'libgbm1'), (2, 'libgbm-dev'), (2, 'mesa-libgallium')),
}


def transitive_closure(deps):
    """Возвращает транзитивное замыкание зависимостей: {пакет: {все поставщики}}."""
    result = {}
    for name, direct in deps.items():
        # Прямые зависимости
        closure = set(direct)
        # Добавляем транзитивные
        changed = True
        while changed:
            changed = False
            for dep in list(closure):
                if dep in deps:
                    for transitive in deps[dep]:
                        if transitive not in closure:
                            closure.add(transitive)
                            changed = True
        result[name] = closure
    return result


def close(packages, order, transitive_wanted):
    """Достраивает списки .deb: всё, что есть в этом репозитории, ставится
    отсюда, а не из trixie.

    Правило простое: если бинарный пакет в Build-Depends публикует этот же
    репозиторий, он добавляется в список наравне с уже перечисленными.
    Так список не может «разъехаться» с debian/control, а решение «всё
    равно брать из trixie» перестаёт быть молчаливым: если набор не
    найден, замыкание падает с понятным сообщением.
    """
    sets = dict(DEB_SETS)
    sets.update(deb_sets(FULL))
    # transitive_wanted maps source package -> set of source packages
    # We need to convert source packages to their binary packages using DEB_SETS
    added = 0
    for name in order:
        data = packages[name]
        # Пакет не устанавливает собственные бинарники: путь ./stageN-pool/<свой
        # бинарник> в собственной job даёт BAD-PATH (стадия N >= стадия N). Очень
        # появляется при self-reference в Build-Depends (например wayland ->
        # libwayland-bin <cross>, где <cross> для нативной сборки не берётся):
        # раньше такой пакет ставил свои stage1-дебы в собственный job. Сам
        # пакет никогда не ставит свои бинарники — иначе это bootstrap, которого
        # в этом репозитории нет (см. CLOSURE_EXCEPT и BUILD_DEPS).
        data['debs'] = [(s, d) for s, d in data['debs'] if OWNER.get(d) != name]
        # Наборы, попавшие в список до того, как появилось исключение,
        # должны из него уйти: иначе правило молчаливо перестаёт действовать
        # после правки CLOSURE_EXCEPT.
        excluded = set(CLOSURE_EXCEPT.get(name, ()))
        if excluded:
            data['debs'] = [d for d in data['debs'] if OWNER.get(d[1]) not in excluded]
        # transitive_wanted gives us source packages we need; convert to binary packages
        need_source = transitive_wanted.get(name, set())
        need_source -= excluded
        # Convert source packages to binary packages we need to install
        need_bins = set()
        for src in need_source:
            if src in sets:
                need_bins.update(deb for _, deb in sets[src])
        present = {OWNER[d] for _, d in data['debs'] if d in OWNER}
        have = {d for _, d in data['debs']}
        for provider in sorted(need_source):
            known = sets.get(provider)
            if not known:
                if provider in present:
                    continue
                raise SystemExit(
                    'Нет эталонного набора .deb для %s, нужного пакету %s: '
                    'добавь его список вручную хотя бы в одной job' % (provider, name))
            for stage, deb in sorted(known):
                if (stage, deb) not in data['debs'] and deb not in have:
                    data['debs'].append((stage, deb))
                    have.add(deb)
                    added += 1
            if not any(provider in c for c in data['comments']):
                data['comments'].append(
                    '%s%s собирается против пакетов этого репозитория, а не '
                    'trixie (добавлено замыканием по Build-Depends)'
                    % (MARK, provider))
    return added


def owner_map():
    """{бинарный пакет: исходный пакет} по packages/*/debian/control."""
    result = {}
    for control in sorted(os.listdir(os.path.join(REPO, 'packages'))):
        path = os.path.join(REPO, 'packages', control, 'debian', 'control')
        if not os.path.exists(path):
            continue
        text = open(path).read()
        for match in re.finditer(r'^Package:\s*(\S+)', text, re.M):
            result[match.group(1)] = control
    return result


def parse_generated():
    """Чтение workflow, уже сгенерированного этим же скриптом."""
    text = open(WORKFLOW).read()
    jobs = list(GEN_JOB_RE.finditer(text))
    packages, order = {}, []
    for position, match in enumerate(jobs):
        end = jobs[position + 1].start() if position + 1 < len(jobs) else len(text)
        body = text[match.end():end]
        name = re.search(r'^ {10}package: (\S+)$', body, re.M).group(1)
        stage = max((int(s) for s in LEVEL_RE.findall(body)), default=1)
        debs = [(int(stage_no), deb) for stage_no, deb in DEB_RE.findall(body)]
        comments = []
        in_debs = False
        for line in body.split('\n'):
            stripped = line.strip()
            # Блок debs=( ... ) заканчивается, как только отступ становится
            # меньше 10 пробелов: там начинаются заголовки уровня и следующие
            # шаги, а поясняющих комментариев у них нет.
            if line.strip() and not line.startswith(' ' * 10):
                in_debs = False
            if stripped.startswith('debs=('):
                in_debs = True
                continue
            # Пользовательские пояснения несут одиночный '#'; строки вида
            # '# #' — служебные заголовки уровня, перенесённые из прежнего
            # workflow, и повторно добавлять их нельзя.
            if in_debs and stripped.startswith('#') and not stripped.startswith('# #'):
                text = stripped.lstrip('# ').strip()
                if text.startswith(MARK):
                    text = text[len(MARK):]
                comments.append(text)
            elif in_debs and not stripped.startswith('#'):
                in_debs = False
        packages[name] = {'stage': stage, 'debs': debs, 'comments': comments}
        order.append(name)
    return packages, order


def parse():
    """{пакет: (уровень, [(stage, имя_deb)], комментарии)} из текущего workflow."""
    lines = open(WORKFLOW).read().split('\n')
    starts = [(i, JOB_RE.match(line).group(1))
              for i, line in enumerate(lines) if JOB_RE.match(line)]
    if not starts:
        # Файл уже в новом формате (job на пакет, без стадий): читаем его
        # собственную структуру, иначе перегенерация была бы неидемпотентной.
        return parse_generated()
    packages = {}
    order = []
    for position, (start, job) in enumerate(starts):
        end = starts[position + 1][0] if position + 1 < len(starts) else len(lines)
        body = lines[start:end]
        stage = int(job.replace('stage', ''))
        matrix = [m.group(1) for m in (MATRIX_PKG_RE.match(l) for l in body) if m]

        debs = {}
        label = None
        pending = []
        for line in body:
            case = CASE_RE.match(line)
            if case:
                label = case.group(1).split('|')
                pending = []
                continue
            deb = DEB_RE.search(line)
            if deb:
                for name in label:
                    # Ключ включает стадию: один case-блок может называть
                    # пакет, который собирается в другой стадии (например
                    # gtk4 входит в метку wlroots|gtk+3.0|gtk4|labwc стадии 2,
                    # хотя сам собирается в стадии 4).
                    debs.setdefault((stage, name), []).append(
                        (int(deb.group(1)), deb.group(2)))
                continue
            if label and line.strip().startswith('#'):
                pending.append(line.strip())

        # Один case-блок может называть пакеты разных стадий (например
        # wlroots|gtk+3.0|gtk4|labwc в стадии 2 и в стадии 4), поэтому список
        # берётся только у тех имён, что реально стоят в матрице этой стадии.
        for name in matrix:
            if name in packages:
                continue
            packages[name] = {'stage': stage,
                              'debs': debs.get((stage, name), []),
                              'comments': pending if (label and name in label) else []}
            order.append(name)
    return packages, order


def levels(packages):
    """Номер уровня по фактическим спискам .deb: 1 + максимум поставщиков."""
    providers = {}
    for name, data in packages.items():
        providers[name] = sorted({OWNER[deb] for _, deb in data['debs']
                                  if deb in OWNER and OWNER[deb] != name})
    level = {}

    def compute(name, stack):
        if name in level:
            return level[name]
        if name in stack:
            raise SystemExit('Цикл в зависимостях: ' + ' -> '.join(stack + [name]))
        stack.append(name)
        level[name] = 1 + max([compute(d, stack) for d in providers[name]] or [0])
        stack.pop()
        return level[name]

    for name in packages:
        compute(name, [])
    return level, providers


def renumber(packages, level, providers):
    """Проставляет в списках .deb номер уровня, которому пакет реально
    принадлежит.

    Номера пулов в путях `./stageN-pool/` - это НЕ уровень, записанный при
    разборе файла: после перехода на граф уровни меняются, а старые номера
    остались бы в путях и job скачивал бы из пула, который никто не
    наполняет. Именно так сломался labwc: он ждал libwlroots из пула 2, хотя
    wlroots собирается на уровне 4. Путь переписывается здесь.
    """
    fixed = 0
    for name, data in packages.items():
        renamed = []
        for old_stage, deb in data['debs']:
            source = OWNER.get(deb)
            if source and source != name and source in level:
                new_stage = level[source]
                if new_stage != old_stage:
                    fixed += 1
                renamed.append((new_stage, deb))
            else:
                renamed.append((old_stage, deb))
        data['debs'] = sorted(set(renamed))
    return fixed


def job_id(name):
    """Имя job'а в YAML: допустимы буквы, цифры, дефис и подчёркивание."""
    return 'build_' + re.sub(r'[^A-Za-z0-9_-]', '_', name)


def render(packages, order, level, build_deps):
    out = []
    add = out.append
    add('jobs:')
    for name in order:
        data = packages[name]
        data['level'] = level[name]
    for wanted in range(1, max(level.values()) + 1):
        add('')
        add('  # %s' % ('-' * 73))
        add('  # Stage %d.' % wanted)
        add('  #')
        add('  # Stage считается по фактическим спискам .deb ниже: пакет стоит')
        add('  # здесь, если все пакеты, чьи .deb он ставит, собраны раньше.')
        add('  # Барьеров стадий нет - job ждёт только тех, от кого зависит.')
        add('  # %s' % ('-' * 73))
        for name in order:
            if level[name] != wanted:
                continue
            data = packages[name]
            jid = job_id(name)
            deps = data['debs']
            add('  %s:' % jid)
            add('    name: %s (stage %d)' % (name, wanted))
            # workflow_dispatch с выбором пакета: собираем выбранный пакет и
            # всех, кто от него зависит; остальные job'и пропускаются. При
            # пустом входе условие истинно - обычный запуск не меняется.
            #
            # Исключение - пакет с особым раннером (RUNNER_OVERRIDE): его job
            # нельзя запускать на обычном прогоне. Пока нужного раннера нет,
            # job висит в ожидании и удерживает прогон открытым, а прогон
            # без результата не возвращает место в очереди. Поэтому такой
            # пакет собирается только по явному выбору: workflow_dispatch с
            # package=<имя>. continue-on-error тогда означает ровно то, что
            # написано: ошибка сборки не роняет остальные пакеты.
            if continue_on_error_for(name):
                add('    if: inputs.package == \'%s\'' % name)
            else:
                add('    if: >-')
                add('      ${{ !inputs.package || %s }}'
                    % ' || '.join("inputs.package == '%s'" % d
                                  for d in sorted(dependents(name, PROVIDERS))))
            # needs вычисляем из прямых зависимостей (BUILD_DEPS), а не из
            # полного списка debs (который включает транзитивные зависимости),
            # чтобы не создавать лишние барьеры между job'ами.
            direct_need = {OWNER[d] for d in build_deps.get(name, ())
                           if d in OWNER and OWNER[d] != name}
            needed = sorted(direct_need)
            if needed:
                add('    needs: [%s]' % ', '.join(job_id(n) for n in needed))
            if continue_on_error_for(name):
                add('    # Раннер для этого пакета отличается от github-hosted:')
                add('    # см. RUNNER_OVERRIDE в scripts/gen-workflow.py и README пакета.')
                add('    # Job собирается только по явному выбору пакета: пока')
                add('    # такого раннера нет, обычный прогон не должен висеть.')
                add('    continue-on-error: true')
                add('    timeout-minutes: 360')
            add('    runs-on: %s' % runner_for(name))
            add('    container:')
            add('      image: debian:trixie')
            add('      credentials:')
            add('        username: ${{ secrets.DOCKERHUB_USERNAME }}')
            add('        password: ${{ secrets.DOCKERHUB_TOKEN }}')
            add('    steps:')
            add('      - name: Checkout repository')
            add('        uses: actions/checkout@v7')
            add('')
            add('      - name: Configure APT sources and install build toolchain')
            add('        run: |')
            add("          # Ensure Debian trixie repositories are configured")
            add("          # Remove deb822 format if present (it can be problematic to modify)")
            add("          rm -f /etc/apt/sources.list.d/debian.sources")
            add("          # Create proper sources.list for trixie with all components")
            add("          cat > /etc/apt/sources.list <<'EOF'")
            add("          deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware")
            add("          deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware")
            add("          deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware")
            add("          EOF")
            add("          apt-get update")
            add('          apt-get install -y --no-install-recommends \\')
            for tool in ('build-essential', 'debhelper', 'devscripts', 'dpkg-dev',
                         'curl', 'ca-certificates', 'rsync', 'git', 'python3'):
                add('            %s \\' % tool)
            for stage in sorted({s for s, _ in deps}):
                add('')
                add('      - name: Download stage %d packages' % stage)
                add('        uses: actions/download-artifact@v8')
                add('        with:')
                add('          pattern: deb-stage%d-*' % stage)
                add('          path: stage%d-pool' % stage)
                add('          merge-multiple: true')
            if deps:
                add('')
                add('      - name: Install required packages of earlier stages')
                add('        run: |')
                add('          shopt -s nullglob')
                add('          # apt-get трактует аргументы без разделителя пути как')
                add('          # имена пакетов, поэтому скачанные .deb передаются как')
                add('          # ./stageN-pool/<файл>.deb')
                for comment in data['comments']:
                    add('          # %s' % comment)
                add('          debs=(')
                for stage, deb in deps:
                    add('                ./stage%d-pool/%s_*.deb' % (stage, deb))
                add('          )')
                add('          echo "Installing: ${debs[*]}"')
                add('          apt-get install -y --no-install-recommends "${debs[@]}"')
            add('')
            add('      - name: Build package (cached, reuses unchanged results)')
            add('        uses: ./.github/actions/build-deb')
            add('        with:')
            add('          package: %s' % name)
            add('          stage: %d' % wanted)
    return '\n'.join(out)


def dependents(name, providers):
    """{все, кого надо пересобрать}, если пересобирается пакет `name`.

    Обратное замыкание: кроме самого пакета - все, кто от него зависит.
    Список подставляется в условие `if` как inputs.package, поэтому при пустом
    входе (обычный запуск) условие истинно и workflow ведёт себя как прежде.
    """
    selected = {name}
    changed = True
    while changed:
        changed = False
        for candidate, sources in providers.items():
            if candidate not in selected and set(sources) & selected:
                selected.add(candidate)
                changed = True
    return selected


OWNER = owner_map()
BUILD_DEPS = build_deps()

# Convert BUILD_DEPS to source package names (filter to only packages in our repo)
SOURCE_DEPS = {}
for pkg, deps in BUILD_DEPS.items():
    SOURCE_DEPS[pkg] = set()
    for dep in deps:
        if dep in OWNER:
            SOURCE_DEPS[pkg].add(OWNER[dep])

TRANSITIVE_DEPS = transitive_closure(SOURCE_DEPS)
PACKAGES, ORDER = parse()
close(PACKAGES, ORDER, TRANSITIVE_DEPS)
LEVEL, PROVIDERS = levels(PACKAGES)
renumber(PACKAGES, LEVEL, PROVIDERS)
if __name__ == '__main__':
    body = render(PACKAGES, ORDER, LEVEL, BUILD_DEPS)
    # Публикация ждёт всех пакетов, а не несуществующую стадию: needs
    # перечисляет каждый job, чтобы публикация не началась раньше времени.
    wait = '[' + ', '.join(job_id(n) for n in ORDER) + ']'
    # TAIL берётся из текущего build.yml, поэтому needs в нём может быть
    # уже устаревшим (например, 32 из 38: новые пакеты в список не попали
    # после перехода на граф). Перезаписываем его всегда - замыкание строится
    # из полного ORDER, а не из отрывка строки, что делает replace идемпотентным.
    tail = re.sub(r'(?m)^    needs: .*\n',
                  '    needs: %s\n' % wait, TAIL, count=1)
    # При выборе одного пакета набор неполон, публиковать нечего: apt-метаданные
    # собрались бы из части репозитория и опубликовали репозиторий с дырами.
    # Поэтому к существующему условию (пропуск на pull_request) добавляется
    # запрет на частичную сборку.
    tail = tail.replace(
        "    if: github.event_name != 'pull_request'\n",
        "    if: github.event_name != 'pull_request' && !inputs.package\n", 1)
    body += tail
    text = HEADER + body
    # TAIL переносится дословно из текущего build.yml, вместе с его
    # концевыми пустыми строками. `print(text)` добавлял бы ещё один `\n`
    # каждый запуск - количество пустых строк росло бы на единицу каждый раз,
    # и --check никогда не проходил бы. Нормализуем: ровно один перевод строки.
    text = re.sub(r'\n+\Z', '\n', text)
    if '--check' in sys.argv:
        current = re.sub(r'\n+\Z', '\n', open(WORKFLOW).read())
        if current == text:
            print('OK: workflow совпадает со сгенерированным')
            sys.exit(0)
        print('РАСХОЖДЕНИЕ: workflow отличается от сгенерированного')
        sys.exit(1)
    sys.stdout.write(text)
