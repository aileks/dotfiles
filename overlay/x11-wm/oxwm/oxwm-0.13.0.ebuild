# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ZIG_SLOT="0.16"
inherit zig pax-utils

DESCRIPTION="OXWM: dynamic window manager written in Zig with Lua config"
HOMEPAGE="https://github.com/tonybanters/oxwm"

declare -g -r -A ZBS_DEPENDENCIES=(
	[N-V-__8AAKEzFAAA695b9LXBhUSVK5MAV_VKSm1mEj3Acbze.tar.gz]='https://www.lua.org/ftp/lua-5.4.8.tar.gz'
)

SRC_URI="https://codeload.github.com/tonybanters/oxwm/tar.gz/refs/tags/v${PV} -> ${P}.tar.gz
	${ZBS_DEPENDENCIES_SRC_URI}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"

RDEPEND="
	x11-libs/libX11
	x11-libs/libXft
	x11-libs/libXinerama
	media-libs/fontconfig
	media-libs/freetype
"

DEPEND="${RDEPEND}"

BDEPEND="
	|| ( dev-lang/zig:${ZIG_SLOT} dev-lang/zig-bin:${ZIG_SLOT} )
	virtual/pkgconfig
"

src_install() {
	zig_src_install

	insinto /usr/share/xsessions
	doins "${S}/resources/oxwm.desktop"

	insinto /usr/share/oxwm
	doins -r "${S}/templates"

	doman "${S}/resources/oxwm.1"

	pax-mark m "${ED}/usr/bin/oxwm"
}
