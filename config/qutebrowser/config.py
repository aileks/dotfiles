config.load_autoconfig(False)

c.fonts.default_family = "Iosevka Nerd Font"
c.fonts.default_size = "11pt"
c.fonts.web.family.standard = "Adwaita Sans"
c.fonts.web.family.fixed = "Iosevka Nerd Font Mono"
c.fonts.web.size.default = 16
c.scrolling.smooth = True
c.tabs.show = "multiple"
c.tabs.position = "top"
c.tabs.background = True
c.tabs.select_on_remove = "prev"
c.spellcheck.languages = ["en-US"]
c.content.pdfjs = True
c.content.plugins = True
c.url.start_pages = ["https://duckduckgo.com"]
c.url.default_page = "https://duckduckgo.com"
c.colors.webpage.preferred_color_scheme = "dark"

c.qt.args = [
    "enable-features=VaapiVideoDecodeLinuxGL",
    "ignore-gpu-blocklist",
    "enable-zero-copy",
]

c.content.cookies.accept = "no-3rdparty"
c.content.webrtc_ip_handling_policy = "default-public-interface-only"
c.content.blocking.method = "auto"
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://easylist.to/easylist/fanboy-annoyance.txt",
    "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=1&mimetype=plaintext",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/badware.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/quick-fixes.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/annoyances.txt",
]

c.url.searchengines = {
    "DEFAULT": "https://duckduckgo.com/?q={}",
    "gw": "https://wiki.gentoo.org/index.php?search={}",
    "gp": "https://packages.gentoo.org/packages/search?q={}",
    "yt": "https://www.youtube.com/results?search_query={}",
    "aw": "https://wiki.archlinux.org/index.php?search={}",
}

c.session.lazy_restore = True
c.completion.shrink = True
c.downloads.location.prompt = False
c.downloads.position = "bottom"
c.downloads.remove_finished = 5000
c.content.autoplay = False
c.editor.command = ["emacsclient", "-c", "--alternate-editor=", "{file}"]

config.bind(",p", "spawn --userscript qute-bitwarden")
config.bind("M", "hint links spawn --detach mpv {hint-url}")
config.bind("tD", "config-cycle colors.webpage.darkmode.enabled true false")
config.bind("[b", "tab-prev")
config.bind("]b", "tab-next")
