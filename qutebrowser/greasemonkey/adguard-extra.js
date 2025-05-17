// ==UserScript==
// @name        AdGuard Extra
// @namespace   qutebrowser
// @match       *://*/*
// @run-at      document-start
// @version     1.0
// @description Counteracts anti-adblock techniques
// ==/UserScript==

(function () {
  "use strict";

  const script = document.createElement("script");
  script.src = "https://userscripts.adtidy.org/release/adguard-extra/1.0/adguard-extra.user.js";
  document.head.appendChild(script);
})();
