// ==UserScript==
// @name        CleanURLs
// @description Strip common tracking parameters from URLs.
// @match       *://*/*
// @run-at      document-start
// @noframes
// ==/UserScript==

"use strict";

const trackingPattern = /^(?:utm_|fbclid|gclid|dclid|msclkid|yclid|mc_eid|igshid|_ga)/;

const params = new URLSearchParams(location.search);
let changed = false;
for (const key of [...params.keys()]) {
    if (trackingPattern.test(key)) {
        params.delete(key);
        changed = true;
    }
}

if (changed) {
    const search = params.toString();
    history.replaceState(
        history.state,
        "",
        location.pathname + (search ? `?${search}` : "") + location.hash
    );
}
