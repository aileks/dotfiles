// ==UserScript==
// @name        Reddit Ad Hider
// @description Hide promoted posts and ad labels on reddit.com.
// @match       *://*.reddit.com/*
// @run-at      document-start
// @noframes
// ==/UserScript==

"use strict";

// qutebrowser's adblock method only blocks network requests, and promoted
// posts come from reddit.com itself. These selectors mirror EasyList's
// reddit.com element-hiding rules, which qutebrowser never applies.
// https://github.com/qutebrowser/qutebrowser/issues/6480
const css = `
    shreddit-ad-post,
    [data-faceplate-tracking-context*='"promoted":true'],
    div[data-before-content='advertisement'],
    .promotedlink {
        display: none !important;
    }
`;

const style = document.createElement("style");
style.textContent = css;
(document.head || document.documentElement).appendChild(style);
