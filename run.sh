#!/bin/bash
set -euo pipefail
set -x

declare -r PACKAGER="Jonathon Fernyhough <jonathon@manjaro.org>"
declare -r GPGKEY="0x9C08A255442FAFF0"

declare -r BUILDDIR="${PWD}"
declare -r GPGDIR="${HOME}/.gnupg"
declare -r PKGDEST="/build/packages"
declare -r SRCDEST="/build/sources"
declare -r SRCPKGDEST="/build/srcpackages"
declare -r LOGDEST="/build/makepkglogs"
declare -r PKGCACHE="/misc/tomatousb/cache/pkg"

declare EXISTING="$(docker ps -a | grep manjaro-build | cut -d' ' -f1)"
declare -r EXISTING

if [ ! "${EXISTING}" ]; then
	docker run --rm -it \
		-e PACKAGER="${PACKAGER}" \
		-e GPGKEY="${GPGKEY}" \
		-e BRANCH="${BRANCH:-stable}" \
		-v "${BUILDDIR}":/build:rw \
		-v "${PKGDEST:-$BUILDDIR/packages}":/build/packages:rw \
		-v "${SRCDEST:-$BUILDDIR/sources}":/build/sources:rw \
		-v "${SRCPKGDEST:-$BUILDDIR/srcpackages}":/build/srcpackages:rw \
		-v "${LOGDEST:-$BUILDDIR/makepkglogs}":/build/makepkglogs:rw \
		-v "${PKGCACHE:-$BUILDDIR/pkgcache}":/pkgcache:rw \
		-v "${GPGDIR:=$BUILDDIR/gpg}":/gpg:ro \
		jonathonf/manjaro-build
else
	docker start "${EXISTING}"
	docker attach "${EXISTING}"
fi
