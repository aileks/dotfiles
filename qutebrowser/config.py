import rosepine

config = config  # type: ignore # noqa: F821
c = c  # type: ignore # noqa: F821

config.load_autoconfig()
rosepine.setup(c, "rose-pine", False)

# General
c.downloads.open_dispatcher = "xdg-open"
c.editor.command = ["ghostty", "-e", "vim", "{}"]
c.auto_save.session = True
c.scrolling.smooth = True
c.tabs.select_on_remove = "last-used"
c.tabs.new_position.related = "next"
c.tabs.new_position.unrelated = "last"
c.url.default_page = "about:blank"
c.downloads.location.directory = "~/Downloads"
c.downloads.location.prompt = True
c.tabs.title.format = "{audio}{current_title}"
c.url.start_pages = ["https://ecosia.com"]
c.colors.webpage.preferred_color_scheme = "dark"
c.zoom.default = "120%"
c.url.searchengines = {
    "DEFAULT": "https://ecosia.com/search?q={}",
    "yt": "https://www.youtube.com/results?search_query={}",
    "gh": "https://github.com/search?q={}",
}
c.completion.open_categories = [
    "searchengines",
    "quickmarks",
    "bookmarks",
    "history",
    "filesystem",
]

# Fonts
c.fonts.default_family = ["sans-serif"]
c.fonts.default_size = "13pt"
c.fonts.web.family.fixed = "BerkeleyMono Nerd Font Mono"
c.fonts.web.family.sans_serif = "Rubik"
c.fonts.web.family.serif = "Literata"
c.fonts.web.family.standard = "Rubik"

# Privacy
c.content.webgl = False
c.content.headers.do_not_track = True
c.content.autoplay = False
c.content.webrtc_ip_handling_policy = "disable-non-proxied-udp"
c.content.canvas_reading = False
c.content.geolocation = False
c.content.cookies.accept = "no-3rdparty"
c.content.cookies.store = True

# Content Blocking
c.content.blocking.enabled = True
c.content.blocking.method = "both"
c.content.blocking.adblock.lists = [
    "https://github.com/ewpratten/youtube_ad_blocklist/blob/master/blocklist.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-cookies.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-others.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2020.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2021.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2022.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2023.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2024.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/legacy.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/quick-fixes.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/resource-abuse.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt",
    "https://github.com/uBlockOrigin/uAssets/blob/master/filters/lan-block.txt",
    "https://github.com/yokoffing/filterlists/blob/main/annoyance_list.txt",
    "https://gitflic.ru/project/magnolia1234/bypass-paywalls-clean-filters/blob/?file=bpc-paywall-filter.txt&branch=main",
    "https://github.com/hagezi/dns-blocklists/blob/main/adblock/pro.mini.txt",
    "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/LegitimateURLShortener.txt",
    "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/BrowseWebsitesWithoutLoggingIn.txt",
]

# Keybindings
config.bind("J", "tab-prev")
config.bind("K", "tab-next")
config.bind("M", "tab-mute")
config.bind("cs", "cmd-set-text -s :config-source")
config.bind("h", "history")
config.bind("T", "hint links tab")
config.bind("pP", "open -- {primary}")
config.bind("pp", "open -- {clipboard}")
config.bind("pt", "open -t -- {clipboard}")
config.bind("qm", "macro-record")
