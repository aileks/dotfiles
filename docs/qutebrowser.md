# Qutebrowser trial

Qutebrowser is a secondary browser. Firefox remains the default; no MIME defaults or desktop browser shortcuts change. Bitwarden Desktop remains separate.

## Install and first launch

The normal `./install.sh` run installs the packages, links the configuration, and downloads the latest selected YouTube scripts. It also performs the rest of the system setup.

For a focused installation, run these from `~/.dotfiles`:

```sh
doas xbps-install -S qutebrowser python3-adblock python3-readability-lxml yt-dlp nodejs
mkdir -p "$HOME/.config/qutebrowser" "$HOME/.config/yt-dlp" "$HOME/.local/bin"
ln -s "$PWD/partial/.config/qutebrowser/config.py" "$HOME/.config/qutebrowser/config.py"
ln -s "$PWD/partial/.config/yt-dlp/config" "$HOME/.config/yt-dlp/config"
ln -s "$PWD/home/.local/bin/qutebrowser-download" "$HOME/.local/bin/qutebrowser-download"
ln -s "$PWD/home/.local/bin/qutebrowser-update-scripts" "$HOME/.local/bin/qutebrowser-update-scripts"
home/.local/bin/qutebrowser-update-scripts
qutebrowser
```

The links match the installer's Stow layout. If a link already exists, inspect it before proceeding; these commands deliberately do not overwrite existing files. This assumes the desktop's existing st, mpv, FFmpeg, xdg-utils, curl, and Emacs installation.

On first launch, run `:adblock-update` and wait for the success message before browsing. Lists are not populated merely by installing `python3-adblock`. Check `:version` for QtWebEngine 6.7 or newer, which supports the per-site dark-mode toggle. [Blocker initialization](https://github.com/qutebrowser/qutebrowser/blob/v3.7.0/qutebrowser/components/braveadblock.py), [dark-mode setting](https://github.com/qutebrowser/qutebrowser/blob/v3.7.0/qutebrowser/config/configdata.yml).

## Controls

Comma bindings run in normal mode. Press Escape to leave a page's text field first.

| Binding                 | Action                                                                  |
| ----------------------- | ----------------------------------------------------------------------- |
| `,m` / `,M`             | Play the current page / a hinted link in mpv                            |
| `,v` / `,V`             | Download the current video / a hinted link with yt-dlp in st            |
| `,r`                    | Open reader mode in a new tab                                           |
| `,d`                    | Toggle forced darkening for this site, save the exception, and reload   |
| `,b`                    | Toggle native ad blocking for this site, save the exception, and reload |
| `,u`                    | Download updated EasyList and EasyPrivacy lists                         |
| `,g`                    | Reload installed Greasemonkey scripts; reload open pages afterward      |
| `,f`                    | Open the current URL in Firefox                                         |
| `Ctrl-e` in insert mode | Edit the focused text field in Doom Emacs; finish with `C-x #`          |
| `yy`                    | Copy the URL without the configured tracking parameters                 |

Media downloads use the XDG Downloads directory and do not expand playlists. The terminal stays open to show success or errors; press Enter to close it. No browser cookies are exported to yt-dlp. Private or restricted videos may need to remain in the browser.

Type `:open yt search terms`, `:open g search terms`, `:open w search terms`, or `:open gh search terms`. Searches without a prefix use DuckDuckGo. Built-in bookmarks, quickmarks, sessions, hints, and file downloads retain their normal bindings; `:bind` lists bindings and `:help` opens the manual.

Forced dark mode starts enabled. The site toggle changes forced rendering, not the preference sent to websites with their own dark themes. Native blocking exceptions also do not disable the YouTube scripts.

## Updates and disabling scripts

Script updates happen only when you run `install.sh` or this command:

```sh
qutebrowser-update-scripts
```

The updater fetches the latest `master` versions of `youtube_adblock.js` and `youtube_sponsorblock.js` from afreakk's repository. It downloads both before installing either. Failed or invalid downloads leave installed copies unchanged. Replaced files have a `.previous` backup beside them. These are upstream scripts, so future updates can change their behavior.

After updating, press `,g` and reload YouTube pages. Update filter lists separately with `,u`. Update qutebrowser, yt-dlp, Node, and their packaged dependencies through the normal Void package update process. The installer installs missing packages; it does not upgrade packages already installed.

Scripts live in `${XDG_DATA_HOME:-$HOME/.local/share}/qutebrowser/greasemonkey`. To disable ad skipping while retaining SponsorBlock:

```sh
mv "$HOME/.local/share/qutebrowser/greasemonkey/youtube_adblock.js" "$HOME/.local/share/qutebrowser/greasemonkey/youtube_adblock.js.disabled"
```

Use the same operation on `youtube_sponsorblock.js` to disable SponsorBlock. Adjust the path if you set `XDG_DATA_HOME`. Press `,g`, then reload affected tabs to stop already-injected scripts. Rename a `.disabled` file back to `.js` to enable it. A future installer or script-update run installs both `.js` files again, re-enabling them. Restore a `.previous` copy over its `.js` file to roll back an update.

## Research and limits

Sources checked on 2026-09-23. Findings come from documentation and source inspection; playback has not been verified on this machine.

- **Native blocking:** `python3-adblock` supplies Brave's network filtering engine. EasyList and EasyPrivacy are upstream defaults. Qutebrowser still lacks cosmetic filtering and scriptlets, so additional lists cannot provide uBlock Origin parity. [Configuration](https://github.com/qutebrowser/qutebrowser/blob/v3.7.0/qutebrowser/config/configdata.yml), [upstream tracking issue](https://github.com/qutebrowser/qutebrowser/issues/6480).
- **YouTube ads:** the selected script clicks skip buttons, seeks past ads, and removes some advertising elements. It is an experimental workaround, not guaranteed ad prevention. Its Shorts ad-removal code is disabled upstream because it freezes playback. [Ad-skipping source](https://github.com/afreakk/greasemonkeyscripts/blob/master/youtube_adblock.js).
- **SponsorBlock:** this is separate from YouTube's own ads. The script queries SponsorBlock with a four-character hash prefix of the video ID and skips returned segments using API category defaults. It has no extension-style settings UI and reads the `v` query parameter, so Shorts and embedded-player URLs are not covered. [SponsorBlock source](https://github.com/afreakk/greasemonkeyscripts/blob/master/youtube_sponsorblock.js).
- **mpv fallback:** qutebrowser documents external video playback. Current yt-dlp needs a JavaScript runtime for full YouTube support. Void supplies the EJS dependency; the shared yt-dlp configuration explicitly enables Node. This does not add SponsorBlock to mpv. [Qutebrowser FAQ](https://qutebrowser.org/doc/faq.html), [yt-dlp runtime requirements](https://github.com/yt-dlp/yt-dlp/wiki/EJS), [Void package](https://github.com/void-linux/void-packages/blob/master/srcpkgs/yt-dlp/template).
- **Reader mode:** the shipped Python userscript uses `python3-readability-lxml`, avoiding the extra npm dependencies of the JavaScript alternative. [Reader source](https://github.com/qutebrowser/qutebrowser/blob/v3.7.0/misc/userscripts/readability).
- **Script compatibility:** external qutebrowser userscripts and page-injected Greasemonkey scripts have different interfaces. Greasemonkey support is incomplete, including cross-origin requests and UI APIs. Its loader does not implement automatic updates from script metadata. [Userscript guide](https://qutebrowser.org/doc/userscripts.html), [FAQ](https://qutebrowser.org/doc/faq.html), [loader](https://github.com/qutebrowser/qutebrowser/blob/v3.7.0/qutebrowser/browser/greasemonkey.py).
- **Excluded extras:** Return YouTube Dislike stores credential objects through a GM storage API that qutebrowser 3.7 only supports for scalar values; it also enables vote submission by default. No adapter is included. No maintained general cosmetic or cookie-consent solution was established. Translation, DRM setup, and unverified Reddit cleanup are outside this trial. [RYD source](https://github.com/Anarios/return-youtube-dislike/blob/main/Extensions/UserScript/Return%20Youtube%20Dislike.user.js), [GM storage implementation](https://github.com/qutebrowser/qutebrowser/blob/v3.7.0/qutebrowser/javascript/greasemonkey_wrapper.js), [Consent-O-Matic userscript request](https://github.com/cavi-au/Consent-O-Matic/issues/570).

## Manual acceptance checks

1. Launch from the application menu. Confirm no configuration errors, Cinder colors, and the expected Qt version. Confirm ordinary external web links still open Firefox.
2. Initialize filters with `,u`. Check a familiar ad-heavy page, then toggle `,b` twice and confirm the site still works.
3. Check YouTube preroll and midroll ads, a video with known sponsor segments, same-tab navigation, signed-in playback, and a live stream. Record failures rather than assuming every video should be ad-free. Disable each script independently if playback breaks.
4. Play current and hinted video links with `,m` and `,M`. Download a public video with `,v`; check its location, playback, and the terminal's exit status.
5. Use reader mode on an article. Toggle dark mode on a light page and confirm that the exception survives a browser restart.
6. Edit a non-sensitive text field with `Ctrl-e`, save and finish with `C-x #`, and confirm the text returns. Check a search shortcut, a copied URL with tracking parameters, and `,f`.
7. Run the script updater manually, check `.previous` backups, then reload scripts and YouTube tabs. Confirm native blocking and script-disable controls remain independent.

Agent verification is limited to linting, formatting, and diff review. No automated or agent-run browser checks are performed.
