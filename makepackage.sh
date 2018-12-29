#!/bin/bash
set -euo pipefail

cd /build
mkdir packages sources srcpackages makepkglogs || true
cp -r /gpg /home/builder/.gnupg
chown -R builder /build /home/builder
sudo -u builder gpg --list-keys >/dev/null
export CARCH=x86_64

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

if [ ! -r /build/packages/packages.db.tar.gz ]; then
	echo "Initialising local package repository..."
	sudo -u builder repo-add /build/packages/packages.db.tar.gz
fi

countries="United_Kingdom,Germany,France,Denmark,Netherlands,Ireland"
if [ ! -z "${BRANCH:-}" ]; then
	pacman-mirrors -c"$countries" -b"$BRANCH"
else
	pacman-mirrors -c"$countries"
fi

source PKGBUILD
repo_version=$(pacman -Siy "${pkgname}" | grep "Version" | cut -d":" -f2 | tr -d '[:space:]' || echo "0")
package_version="${pkgver}-${pkgrel}"
newenough="$(vercmp $repo_version $package_version)"
if [ $newenough -ge 0 ]; then
        echo "Nothing to do, repo version is same or newer."
        exit 0
fi

echo "Importing any valid PGP keys..."
if [ ! -z "${validpgpkeys:-}" ]; then
	for key in "${validpgpkeys[@]}"; do
	        sudo -u builder gpg --recv-key "$key"
	done
fi

pacman --noconfirm --noprogressbar -Syyu

if [ ! -z "${IMTOOLAZYTOCHECKSUMS:-}" ]; then
	echo "Updating checksums..."
	sudo -u builder /usr/bin/updpkgsums
fi

echo "Building package..."
sudo -u builder script -q -c "/usr/bin/makepkg --noconfirm --noprogressbar --sign -Csfc" /dev/null

#echo "Updating local package repository..."
#sudo -u builder GLOBEXCLUDE='*git*' /usr/bin/repo-add -n -R -s --key "$GPGKEY" \
#  /build/packages/packages.db.tar.xz \
#  /build/packages/*.pkg.tar.xz
