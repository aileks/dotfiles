// ==UserScript==
// @name        github-declutter
// @description Hide Copilot UI clutter and the dashboard news sidebar on github.com.
// @match       https://github.com/*
// @run-at      document-start
// @noframes
// ==/UserScript==

"use strict";

// Best-effort selectors against GitHub's DOM; expect to update them when
// GitHub changes its markup. Copilot code completions in the web editor are
// account-level, not CSS-hideable: disable them in GitHub settings if wanted.
const css = `
    a[href="/copilot"],
    a[href="https://github.com/copilot"],
    [data-testid*="copilot" i],
    [aria-label*="copilot" i],
    .feed-right-sidebar {
        display: none !important;
    }
`;

const style = document.createElement("style");
style.textContent = css;
(document.head || document.documentElement).appendChild(style);
