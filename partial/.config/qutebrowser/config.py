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
c.colors.webpage.darkmode.algorithm = "lightness-hsl"
c.colors.webpage.darkmode.policy.images = "never"
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
config.bind(',t', 'config-cycle tabs.show always never')

c.fonts.default_family = ["Iosevka Nerd Font Propo", "monospace"]
c.fonts.default_size = "12pt"
c.fonts.web.family.standard = "Adwaita Sans"
c.fonts.web.family.serif = "Adwaita Sans"
c.fonts.web.family.sans_serif = "Adwaita Sans"
c.fonts.web.family.cursive = "Adwaita Sans"
c.fonts.web.family.fantasy = "Adwaita Sans"
c.statusbar.show = "in-mode"

background = "#080503"
foreground = "#DED6D0"
surface = "#221B17"
overlay = "#342C26"
bright = "#F1EAE5"
muted = "#A2968E"
accent = "#B39887"
secondary = "#C6BBB5"
selection = "#725F52"
border = "#80756E"
error = "#E07972"
warning = "#C69E58"
success = "#78AA79"
info = "#6DA1CD"

c.colors.tooltip.fg = foreground
c.colors.tooltip.bg = overlay
c.colors.webpage.bg = background

c.colors.completion.fg = foreground
c.colors.completion.odd.bg = background
c.colors.completion.even.bg = surface
c.colors.completion.category.bg = background
c.colors.completion.category.fg = accent
c.colors.completion.category.border.top = border
c.colors.completion.category.border.bottom = border
c.colors.completion.item.selected.bg = selection
c.colors.completion.item.selected.fg = bright
c.colors.completion.item.selected.border.top = selection
c.colors.completion.item.selected.border.bottom = selection
c.colors.completion.item.selected.match.fg = bright
c.colors.completion.match.fg = accent
c.colors.completion.scrollbar.bg = background
c.colors.completion.scrollbar.fg = muted

c.colors.tabs.bar.bg = background
c.colors.tabs.odd.bg = background
c.colors.tabs.even.bg = background
c.colors.tabs.odd.fg = foreground
c.colors.tabs.even.fg = foreground
c.colors.tabs.selected.odd.bg = selection
c.colors.tabs.selected.even.bg = selection
c.colors.tabs.selected.odd.fg = bright
c.colors.tabs.selected.even.fg = bright
c.colors.tabs.pinned.odd.bg = surface
c.colors.tabs.pinned.even.bg = surface
c.colors.tabs.pinned.odd.fg = bright
c.colors.tabs.pinned.even.fg = bright
c.colors.tabs.pinned.selected.odd.bg = selection
c.colors.tabs.pinned.selected.even.bg = selection
c.colors.tabs.pinned.selected.odd.fg = bright
c.colors.tabs.pinned.selected.even.fg = bright
c.colors.tabs.indicator.start = muted
c.colors.tabs.indicator.stop = accent
c.colors.tabs.indicator.error = error
c.colors.tabs.indicator.system = "none"

c.colors.statusbar.normal.bg = background
c.colors.statusbar.normal.fg = foreground
c.colors.statusbar.command.bg = background
c.colors.statusbar.command.fg = bright
c.colors.statusbar.insert.bg = selection
c.colors.statusbar.insert.fg = bright
c.colors.statusbar.passthrough.bg = selection
c.colors.statusbar.passthrough.fg = bright
c.colors.statusbar.private.bg = surface
c.colors.statusbar.private.fg = accent
c.colors.statusbar.command.private.bg = surface
c.colors.statusbar.command.private.fg = accent
c.colors.statusbar.caret.bg = selection
c.colors.statusbar.caret.fg = bright
c.colors.statusbar.caret.selection.bg = selection
c.colors.statusbar.caret.selection.fg = bright
c.colors.statusbar.progress.bg = accent
c.colors.statusbar.url.fg = foreground
c.colors.statusbar.url.hover.fg = accent
c.colors.statusbar.url.success.http.fg = warning
c.colors.statusbar.url.success.https.fg = foreground
c.colors.statusbar.url.warn.fg = warning
c.colors.statusbar.url.error.fg = error

c.colors.hints.bg = selection
c.colors.hints.fg = bright
c.colors.hints.match.fg = bright
c.hints.border = f"1px solid {border}"
c.colors.keyhint.bg = background
c.colors.keyhint.fg = foreground
c.colors.keyhint.suffix.fg = accent
c.colors.prompts.bg = background
c.colors.prompts.fg = bright
c.colors.prompts.selected.bg = selection
c.colors.prompts.border = f"1px solid {border}"
c.colors.messages.info.bg = background
c.colors.messages.info.fg = foreground
c.colors.messages.info.border = info
c.colors.messages.warning.bg = surface
c.colors.messages.warning.fg = warning
c.colors.messages.warning.border = warning
c.colors.messages.error.bg = surface
c.colors.messages.error.fg = error
c.colors.messages.error.border = error
c.colors.downloads.bar.bg = background
c.colors.downloads.start.bg = surface
c.colors.downloads.start.fg = foreground
c.colors.downloads.stop.bg = surface
c.colors.downloads.stop.fg = success
c.colors.downloads.error.bg = surface
c.colors.downloads.error.fg = error
c.colors.downloads.system.bg = "none"
c.colors.downloads.system.fg = "none"
c.colors.contextmenu.menu.bg = overlay
c.colors.contextmenu.menu.fg = foreground
c.colors.contextmenu.selected.bg = selection
c.colors.contextmenu.selected.fg = bright
c.colors.contextmenu.disabled.bg = overlay
c.colors.contextmenu.disabled.fg = muted
