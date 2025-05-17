import rosepine

c = c  # pyright: ignore  # noqa: F821
config = config  # pyright: ignore  # noqa: F821

# General
c.tabs.show = "multiple"
c.tabs.title.format = "{audio}{current_title}"
c.tabs.last_close = "close"
c.tabs.select_on_remove = "last-used"
c.tabs.new_position.related = "next"
c.tabs.new_position.unrelated = "last"
c.url.default_page = "about:blank"
c.auto_save.session = True
c.editor.command = ["zed", "{file}"]
c.completion.open_categories = [
    "searchengines",
    "quickmarks",
    "bookmarks",
    "history",
    "filesystem",
]

# Search Engines
c.url.searchengines = {
    "DEFAULT": "https://www.ecosia.org/search?q={}",
    "!aw": "https://wiki.archlinux.org/?search={}",
    "!gh": "https://github.com/search?o=desc&q={}&s=stars",
    "!yt": "https://www.youtube.com/results?search_query={}",
}

# Privacy Settings
config.set("content.headers.do_not_track", True)
config.set("content.webgl", False, "*")
config.set("content.canvas_reading", False)
config.set("content.geolocation", False)
config.set("content.webrtc_ip_handling_policy", "disable-non-proxied-udp")
config.set("content.cookies.accept", "no-3rdparty")
config.set("content.cookies.store", True)
c.content.javascript.enabled = True
c.content.javascript.clipboard = "access-paste"
c.content.autoplay = False
c.content.site_specific_quirks.enabled = False
c.content.desktop_capture = "ask"
c.content.media.audio_capture = "ask"
c.content.media.video_capture = "ask"
c.content.notifications.enabled = False
c.content.headers.user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36"  # it ain't much but it's honest work
c.content.headers.accept_language = "en-US,en;q=0.9"

# Content Blocking
c.content.blocking.enabled = True
c.content.blocking.method = "both"
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/badware.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/annoyances.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt",
    "https://raw.githubusercontent.com/yokoffing/filterlists/refs/heads/main/privacy_essentials.txt",
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/refs/heads/main/adblock/pro.mini.txt",
    "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/LegitimateURLShortener.txt",
    "https://raw.githubusercontent.com/yokoffing/filterlists/refs/heads/main/annoyance_list.txt",
    "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/BrowseWebsitesWithoutLoggingIn.txt",
    "https://raw.githubusercontent.com/liamengland1/miscfilters/refs/heads/master/antipaywall.txt",
    "https://www.i-dont-care-about-cookies.eu/abp/",
    "https://secure.fanboy.co.nz/fanboy-annoyance.txt",
]

# Appearance
rosepine.setup(c, "rose-pine", True)
c.colors.webpage.preferred_color_scheme = "dark"
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.algorithm = "lightness-cielab"
c.colors.webpage.darkmode.policy.images = "never"
config.set("colors.webpage.darkmode.enabled", False, "file://*")

# Fonts & Scaling
c.fonts.default_family = []
c.fonts.web.family.fixed = "BerkeleyMono Nerd Font"
c.fonts.web.family.sans_serif = "Rubik"
c.fonts.web.family.serif = "Literata"
c.fonts.web.family.standard = "Rubik"
c.fonts.default_size = "18pt"
c.fonts.web.size.default = 20
c.zoom.default = "133%"
c.qt.highdpi = True
c.qt.force_software_rendering = "none"

# Keybindings
config.bind("cs", "cmd-set-text -s :config-source")
config.bind("h", "history")
config.bind("T", "hint links tab")
config.bind("pP", "open -- {primary}")
config.bind("pp", "open -- {clipboard}")
config.bind("pt", "open -t -- {clipboard}")
config.bind("qm", "macro-record")
config.bind("pw", "spawn --detach proton-pass")
config.bind("<ctrl-v>", "insert-text -- {clipboard}")

# Misc
c.downloads.location.prompt = True
c.downloads.open_dispatcher = "xdg-open"
c.scrolling.smooth = True
c.qt.chromium.process_model = "process-per-site"

config.load_autoconfig()

# !!!!!!!!!!!!!!!!!!!!!!! #
# MANUAL SETTING OF THEME #
# !!!!!!!!!!!!!!!!!!!!!!! #
palette = {
    "Base": "#191724",
    "Surface": "#1f1d2e",
    "Overlay": "#26233a",
    "Muted": "#6e6a86",
    "Subtle": "#908caa",
    "Text": "#e0def4",
    "Love": "#eb6f92",
    "Gold": "#f6c177",
    "Rose": "#ebbcba",
    "Pine": "#31748f",
    "Foam": "#9ccfd8",
    "Iris": "#c4a7e7",
    "HighlightLow": "#21202e",
    "HighlightMed": "#403d52",
    "HighlightHigh": "#524f67",
}
