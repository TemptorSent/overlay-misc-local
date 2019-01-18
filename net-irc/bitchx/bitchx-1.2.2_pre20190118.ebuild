# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit git-r3

DESCRIPTION="BitchX IRC client"
HOMEPAGE="bitchx.sourceforge.net"
EGIT_REPO_URI="https://git.code.sf.net/p/bitchx/git -> bitchx"
EGIT_COMMIT_DATE="${PV##*_pre}"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="tcl ssl"

DEPEND="sys-libs/ncurses
	tcl? ( dev-lang/tcl )
	ssl? ( dev-libs/openssl )"

RDEPEND="${DEPEND}"

src_configure() {
	local myconf=(
		"--with-default-server=irc.freenode.net"
		$(use_with ssl)
		$(use_with tcl)
		"--with-plugins"
	)

	econf "${myconf[@]}"
}
