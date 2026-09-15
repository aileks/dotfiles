# Ad blocking in qutebrowser

Researched 2026-09-14 against qutebrowser 3.7.0 (installed source at
`/usr/lib/python3.14/site-packages/qutebrowser/`), QtWebEngine 6.11.1
(Chromium 140), `dev-python/adblock` 0.6.0, on Gentoo.

## TL;DR

The config already uses the strongest blocking qutebrowser has. Reddit
promoted posts survive because they come from reddit.com itself, so no
network rule can block them. uBlock Origin hides them with cosmetic
(element-hiding) rules from EasyList, and qutebrowser does not apply
cosmetic rules. There is no way to enable them; the feature is still open
upstream. The practical fix is a small greasemonkey script.

## Recommendations

1. Keep `content.blocking.method = "both"` and the current list set. It
   already matches uBlock Origin's default lists plus annoyances.
2. Optionally drop the yoyo.org hosts URL from `adblock.lists`. The hosts
   blocker in `both` mode already loads StevenBlack hosts by default, and
   that file includes yoyo.org. Keeping it is harmless.
3. Run `:adblock-update` after changing lists. Updates are manual; there is
   no auto-update.
4. Add the greasemonkey script below to hide Reddit promoted posts and the
   ADVERTISEMENT banner. That is the part filter lists cannot currently do.

Current relevant config lines in `config/config/qutebrowser/config.py`
(already correct, listed for reference):

```python
c.content.blocking.method = "both"
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
```

New file `config/config/qutebrowser/greasemonkey/reddit-ads.user.js`
(the `~/.config/qutebrowser` symlink points here, and qutebrowser reads
greasemonkey scripts from the config dir's `greasemonkey/` folder):

```js
// ==UserScript==
// @name         Reddit ad hider
// @version      1.0
// @description  Hide promoted posts and ad labels on Reddit
// @match        *://*.reddit.com/*
// @run-at       document-start
// ==/UserScript==

// Selectors mirror EasyList's reddit.com cosmetic rules, which qutebrowser
// cannot apply: https://easylist.to/easylist/easylist.txt
const selector = [
    "shreddit-ad-post",
    "[data-faceplate-tracking-context*='\"promoted\":true']",
    "div[data-before-content='advertisement']",
    ".promotedlink",
].join(", ");

function removeAds(root) {
    for (const el of root.querySelectorAll(selector)) {
        el.remove();
    }
}

new MutationObserver((mutations) => {
    for (const m of mutations) {
        for (const node of m.addedNodes) {
            if (node.nodeType === Node.ELEMENT_NODE) {
                removeAds(node);
            }
        }
    }
}).observe(document.documentElement, {childList: true, subtree: true});

removeAds(document);
```

The same pattern (selectors from the site's EasyList `##` rules in a
userscript with a MutationObserver) generalizes to the ADVERTISEMENT banner
on any other site. `document-end` also works if you do not need to catch
content before first paint.

## What the built-in methods do

`content.blocking.method` picks one of `auto`, `adblock`, `hosts`, `both`:

- `hosts`: a simple host blocker. It loads `/etc/hosts`-style lists from
  `content.blocking.hosts.lists` (default: StevenBlack hosts) and can only
  block whole hosts.
  Source: qutebrowser configdata.yml, `content.blocking.hosts.lists`.
- `adblock`: Brave's Rust adblocker (adblock-rust) via the Python `adblock`
  package (python-adblock, Gentoo package `dev-python/adblock`). Parses
  ABP-style filter lists such as EasyList.
  Source: https://qutebrowser.org/doc/faq.html ("Is there an ad blocker?"),
  https://github.com/brave/adblock-rust, https://github.com/ArniDagur/python-adblock
- `both`: runs both. Needed if you want custom `blocked-hosts` /
  `file://` host lists alongside the ABP-style blocker, since v2.0.0 the
  Brave blocker otherwise ignores them.
  Source: https://github.com/qutebrowser/qutebrowser/blob/master/doc/changelog.asciidoc (v2.0.0 notes)

### The key limitation: network blocking only

The adblock method checks every request through a URL request interceptor
and cancels matches:

```python
result = self._engine.check_network_urls(...)
...
info.block()
```

Source: `qutebrowser/components/braveadblock.py`, `filter_request()` /
`_is_blocked()`.
https://github.com/qutebrowser/qutebrowser/blob/main/qutebrowser/components/braveadblock.py

It never calls the cosmetic-filtering APIs. The installed Python binding
does expose them (`url_cosmetic_resources`, `hidden_class_id_selectors` on
`adblock.Engine`), and adblock-rust implements element hiding, so the
capability exists in the stack but is not wired up:

- qutebrowser FAQ: "even the more sophisticated blocker does not support
  element hiding (cosmetic filtering) yet, it only blocks network requests."
  https://qutebrowser.org/doc/faq.html
- Open issue tracking element hiding and scriptlets:
  https://github.com/qutebrowser/qutebrowser/issues/6480 (still open as of
  June 2026 per the last comment)
- Split off from https://github.com/qutebrowser/qutebrowser/issues/5754

### Why Reddit promoted posts survive

Promoted posts and the ADVERTISEMENT label are rendered by reddit.com's own
markup. EasyList's reddit.com section contains no network rules for them,
only four element-hiding rules:

```
reddit.com##.promotedlink:not([style^="height: 1px;"])
reddit.com##[data-faceplate-tracking-context*="\"promoted\":true"]
reddit.com##div[data-before-content="advertisement"]
reddit.com##shreddit-ad-post
```

Source: https://easylist.to/easylist/easylist.txt (searched 2026-09-14).

uBlock Origin applies these selectors and hides the elements. qutebrowser
ignores `##` rules entirely, so the posts render. The first-party problem
also applies to most "native" or sponsored content on other sites.

### Other gaps vs uBlock Origin

- No scriptlets (`##+js(...)`). Required for current YouTube ad blocking
  per EasyList maintainers; see issue 6480. This is why the existing
  `greasemonkey/youtube-adblock.js` skip-button script is still needed.
- No `$redirect` request rewriting (open item in issue 5754).
- No dynamic filtering or per-site rule toggles; only
  `content.blocking.whitelist` (URL patterns always allowed) and
  `content.blocking.enabled` per site.
- Requests without a first-party URL are never blocked (FIXME in
  braveadblock.py `_is_blocked`).
- uAssets lists contain uBO-specific syntax (`:style`, `:remove-attr`,
  trusted rules). adblock-rust supports some uBO syntax extensions and
  skips the rest, so these lists still contribute their network rules.
  https://github.com/brave/adblock-rust

## uBlock Origin itself: not possible

QtWebEngine does not support loading Chrome extensions. It only offers
script injection (`QWebEngineScript`, "implementations of the Chromium API
for Content Script Extensions" with Greasemonkey-like metadata). Source:
https://doc.qt.io/qt-6/qtwebengine-overview.html

qutebrowser has no extension system; issues #29 and #30 are the long-open
umbrella requests, and the "ublock Origin support" issue was closed pointing
at them:

- https://github.com/qutebrowser/qutebrowser/issues/30
- https://github.com/qutebrowser/qutebrowser/issues/29
- https://github.com/qutebrowser/qutebrowser/issues/4832

## Greasemonkey as the workaround

- Scripts: `.js` files with a `==UserScript==` block in
  `<config>/greasemonkey/` or `<data>/greasemonkey/`; reload with
  `:greasemonkey-reload`; debug with
  `--debug --logfilter greasemonkey,js`. Source:
  https://qutebrowser.org/doc/faq.html ("How do I make qutebrowser use
  greasemonkey scripts?"), `qutebrowser/browser/greasemonkey.py`
- Supported metadata: `@match`, `@include`, `@exclude`, `@run-at`
  (`document-start`, `document-end`, `document-idle`), `@require`,
  `@noframes`. Source: `qutebrowser/browser/greasemonkey.py`
- The wrapper provides `GM_addStyle`, `GM_getValue`, `GM_setValue`,
  `GM_xmlhttpRequest`, and others. `GM_xmlhttpRequest` cannot bypass CORS,
  and UI-related APIs are missing. Source:
  https://qutebrowser.org/doc/faq.html,
  `qutebrowser/javascript/greasemonkey_wrapper.js`
- `content.user_stylesheets` exists but is a global setting; it does not
  support per-site URL patterns (verified against configdata.yml,
  `supports_pattern: False`), so a userscript is the right per-site tool.
  A global stylesheet scoped only to element names reddit owns
  (`shreddit-ad-post { display: none !important; }`) is a JS-free fallback.

## Canonical list sources

- EasyList / EasyPrivacy / Fanboy lists: https://easylist.to/ (canonical,
  and the qutebrowser defaults come from there).
  Overview of ABP lists: https://adblockplus.org/en/subscriptions
- uBlock Origin lists: https://github.com/uBlockOrigin/uAssets/tree/master/filters
  (`filters.txt` = Ads, `privacy.txt`, `badware.txt`, `quick-fixes.txt`,
  `unbreak.txt`, `annoyances.txt`; note `annoyances.txt` includes
  `annoyances-others.txt` via an `!#include` line, which neither
  qutebrowser's downloader nor adblock-rust resolves, so that subset is
  missing unless `annoyances-others.txt` is added directly; tested with the
  installed binding: rules from the included file do not load).
  Verification: https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/annoyances.txt
- Hosts lists for `content.blocking.hosts.lists`:
  https://github.com/StevenBlack/hosts (default; unified file already
  includes yoyo.org per its README sources table).
