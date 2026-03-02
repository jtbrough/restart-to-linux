set shell := ["sh", "-eu", "-c"]

default:
    just --list

lint:
    sh -n src/bin/restart-to-linux
    sh -n src/libexec/restart-to-linux-common
    sh -n install.sh
    sh -n uninstall.sh
    sh -n packaging/macos/build-app.sh
    sh -n tools/collect-asahi-debug.sh
    sh -n tests/smoke.sh

validate:
    tests/smoke.sh

test:
    tests/smoke.sh

build-app:
    packaging/macos/build-app.sh

ci:
    just lint
    just validate
