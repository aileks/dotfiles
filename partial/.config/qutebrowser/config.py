config.load_autoconfig()

c.scrolling.smooth = True

c.content.blocking.method = "both"
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://secure.fanboy.co.nz/fanboy-annoyance.txt",
    "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=adblockplus&showintro=1&mimetype=plaintext",
    "https://easylist-downloads.adblockplus.org/antiadblockfilters.txt",
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.mini.txt",
    "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Dandelion%20Sprout%27s%20Anti-Malware%20List.txt",
    "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/BrowseWebsitesWithoutLoggingIn.txt",
    "https://raw.githubusercontent.com/yokoffing/filterlists/main/antipaywall_filters_without_element_hiding.txt",
]
c.colors.webpage.preferred_color_scheme = "dark"
c.colors.webpage.darkmode.enabled = True
c.editor.command = ["emacsclient", "-c", "-a=", "+{line}:{column0}", "{file}"]

c.url.searchengines = {
    "DEFAULT": "https://omnisearch.tail0d2ded.ts.net/search?q={}",
    "g": "https://www.google.com/search?q={}",
    "yt": "https://www.youtube.com/results?search_query={}",
    "wp": "https://en.wikipedia.org/w/index.php?search={}",
    "gh": "https://github.com/search?q={}",
}
c.url.yank_ignored_parameters = [
    "ref",
    "utm_source",
    "utm_medium",
    "utm_campaign",
    "utm_term",
    "utm_content",
    "utm_name",
    "fbclid",
    "gclid",
    "dclid",
    "msclkid",
]

config.bind(",d", "config-cycle -p -u *://{url:host}/* colors.webpage.darkmode.enabled ;; reload")
config.bind(",b", "config-cycle -p -u *://{url:host}/* content.blocking.enabled ;; reload")
config.bind(",m", "spawn mpv -- {url}")
config.bind(",M", "hint links spawn mpv -- {hint-url}")
config.bind(",v", "spawn st -e qutebrowser-download {url}")
config.bind(",V", "hint links spawn st -e qutebrowser-download {hint-url}")
config.bind(",r", "spawn --userscript /usr/share/qutebrowser/userscripts/readability")
config.bind(",u", "adblock-update")
config.bind(",g", "greasemonkey-reload")
config.bind(",f", "spawn firefox {url}")

c.fonts.default_family = ["Iosevka Nerd Font Propo", "monospace"]
c.fonts.default_size = "12pt"
c.fonts.web.family.standard = "Adwaita Sans"
c.fonts.web.family.serif = "Adwaita Sans"
c.fonts.web.family.sans_serif = "Adwaita Sans"
c.fonts.web.family.cursive = "Adwaita Sans"
c.fonts.web.family.fantasy = "Adwaita Sans"
c.statusbar.show = 'in-mode'

background = "#15110f"
foreground = "#c5afa4"
surface = "#1e1815"
overlay = "#271e1a"
bright = "#e9d1c5"
muted = "#5f5049"
accent = "#f1a278"
secondary = "#c2764e"
red = "#a45751"

c.colors.tooltip.fg = background

c.colors.completion.fg = foreground
c.colors.completion.odd.bg = background
c.colors.completion.even.bg = surface
c.colors.completion.category.bg = background
c.colors.completion.category.fg = accent
c.colors.completion.category.border.top = muted
c.colors.completion.category.border.bottom = muted
c.colors.completion.item.selected.bg = muted
c.colors.completion.item.selected.fg = bright
c.colors.completion.item.selected.border.top = muted
c.colors.completion.item.selected.border.bottom = muted
c.colors.completion.item.selected.match.fg = accent
c.colors.completion.match.fg = accent
c.colors.completion.scrollbar.bg = background
c.colors.completion.scrollbar.fg = muted

c.colors.tabs.bar.bg = background
c.colors.tabs.odd.bg = background
c.colors.tabs.even.bg = background
c.colors.tabs.odd.fg = foreground
c.colors.tabs.even.fg = foreground
c.colors.tabs.selected.odd.bg = secondary
c.colors.tabs.selected.even.bg = secondary
c.colors.tabs.selected.odd.fg = overlay
c.colors.tabs.selected.even.fg = overlay
c.colors.tabs.pinned.odd.bg = surface
c.colors.tabs.pinned.even.bg = surface
c.colors.tabs.pinned.odd.fg = bright
c.colors.tabs.pinned.even.fg = bright
c.colors.tabs.pinned.selected.odd.bg = muted
c.colors.tabs.pinned.selected.even.bg = muted
c.colors.tabs.pinned.selected.odd.fg = accent
c.colors.tabs.pinned.selected.even.fg = accent
c.colors.tabs.indicator.start = muted
c.colors.tabs.indicator.stop = accent
c.colors.tabs.indicator.error = red

c.colors.statusbar.normal.bg = background
c.colors.statusbar.normal.fg = foreground
c.colors.statusbar.command.bg = background
c.colors.statusbar.command.fg = bright
c.colors.statusbar.insert.bg = secondary
c.colors.statusbar.insert.fg = background
c.colors.statusbar.passthrough.bg = muted
c.colors.statusbar.passthrough.fg = bright
c.colors.statusbar.private.bg = surface
c.colors.statusbar.private.fg = accent
c.colors.statusbar.command.private.bg = surface
c.colors.statusbar.command.private.fg = accent
c.colors.statusbar.caret.bg = muted
c.colors.statusbar.caret.fg = bright
c.colors.statusbar.caret.selection.bg = accent
c.colors.statusbar.caret.selection.fg = background
c.colors.statusbar.progress.bg = accent
c.colors.statusbar.url.fg = overlay
c.colors.statusbar.url.hover.fg = accent
c.colors.statusbar.url.success.http.fg = red
c.colors.statusbar.url.success.https.fg = overlay
c.colors.statusbar.url.warn.fg = accent
c.colors.statusbar.url.error.fg = red

c.colors.hints.bg = accent
c.colors.hints.fg = background
c.colors.hints.match.fg = red
c.hints.border = f"1px solid {muted}"
c.colors.keyhint.bg = background
c.colors.keyhint.fg = foreground
c.colors.keyhint.suffix.fg = accent
c.colors.prompts.bg = background
c.colors.prompts.fg = bright
c.colors.prompts.selected.bg = muted
c.colors.prompts.border = f"1px solid {muted}"
c.colors.messages.info.bg = background
c.colors.messages.info.fg = foreground
c.colors.messages.info.border = muted
c.colors.messages.warning.bg = accent
c.colors.messages.warning.fg = background
c.colors.messages.warning.border = accent
c.colors.messages.error.bg = red
c.colors.messages.error.fg = bright
c.colors.messages.error.border = red
