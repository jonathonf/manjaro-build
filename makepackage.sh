#!/bin/bash
set -euo pipefail

cd /build
mkdir packages sources srcpackages makepkglogs || true
cp -r /gpg /home/builder/.gnupg
chown -R builder /build /home/builder
sudo -u builder gpg --list-keys >/dev/null

if [ ! -z "${PACKAGER:-}" ]; then
	sed -i "122cPACKAGER=\"$PACKAGER\"" /etc/makepkg.conf
fi

if [ ! -z "${GPGKEY:-}" ]; then
	sed -i "124cGPGKEY=\"$GPGKEY\"" /etc/makepkg.conf
fi

# Clean package cache to avoid rebuilding issues
for package in /build/packages/*.pkg.tar.xz; do
	rm -f /pkgcache/"$package"
done

if [ ! -r /build/packages/packages.db.tar.xz ]; then
	echo "Initialising local package repository..."
	sudo -u builder repo-add /build/packages/packages.db.tar.xz
fi

if [ ! -z "${BRANCH:-}" ]; then
	pacman-mirrors -f3 -y -b"$BRANCH"
else
	pacman-mirrors -f3 -y
fi
pacman --noconfirm --noprogressbar -Syu

if [ ! -z "${IMTOOLAZYTOCHECKSUMS:-}" ]; then
	echo "Updating checksums..."
	sudo -u builder /usr/bin/updpkgsums
fi

echo "Building package..."
sudo -u builder script -q -c "/usr/bin/makepkg --noconfirm --noprogressbar --sign -Csfc" /dev/null

echo "Updating local package repository..."
sudo -u builder /usr/bin/repo-add /build/packages/packages.db.tar.xz /build/packages/*.pkg.tar.xz
