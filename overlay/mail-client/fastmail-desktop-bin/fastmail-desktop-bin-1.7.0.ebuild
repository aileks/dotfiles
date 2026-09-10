# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

DESCRIPTION="Fastmail desktop application"
HOMEPAGE="https://www.fastmail.com/"
SRC_URI="https://dl.fastmailcdn.com/desktop/production/linux/x64/com.fastmail.Fastmail-${PV}.AppImage"
S="${WORKDIR}/squashfs-root"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror strip"

BDEPEND="sys-fs/squashfs-tools"
RDEPEND="
	app-accessibility/at-spi2-core
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	app-crypt/libsecret
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxkbcommon
	x11-libs/libXrandr
	x11-libs/pango
	x11-misc/xdg-utils
"

QA_PREBUILT="opt/fastmail/*"

src_unpack() {
	# Extract the filesystem without executing the downloaded AppImage runtime.
	local image="${DISTDIR}/com.fastmail.Fastmail-${PV}.AppImage"
	# ELF section table ends at byte 188392 in this Manifest-pinned release.
	unsquashfs -o 188392 "${image}" || die
}

src_install() {
	insinto /opt/fastmail
	doins -r .
	fperms 0755 /opt/fastmail/fastmail /opt/fastmail/chrome-sandbox /opt/fastmail/chrome_crashpad_handler
	# Electron uses unprivileged user namespaces; do not disable its sandbox.
	dosym /opt/fastmail/fastmail /usr/bin/fastmail
	sed -e 's|^Exec=.*|Exec=fastmail %U|' -e 's|^Name=.*|Name=Fastmail|' \
		fastmail.desktop > "${T}/fastmail.desktop" || die
	domenu "${T}/fastmail.desktop"
	insinto /usr/share/icons
	doins -r usr/share/icons/hicolor
}
