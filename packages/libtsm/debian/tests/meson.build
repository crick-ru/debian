# SPDX-License-Identifier: MIT
#
# Standalone meson project used only by the Debian autopkgtest. It builds a
# public-API test against the *installed* libtsm shared library (found via
# pkg-config), mirroring the style of the upstream test/meson.build without
# pulling in any internal sources or headers.

project('libtsm-installed-test', 'c', default_options: ['c_std=c11'])

tsm_dep = dependency('libtsm')
check_dep = dependency('check')

test_public_api = executable(
    'test_public_api',
    'test_public_api.c',
    dependencies: [tsm_dep, check_dep],
)

test('public_api', test_public_api)
