// ==UserScript==
// @name         YouTube Ad Skipper
// @version      1.0
// @description  Instantly skips and fast-forwards YouTube ads
// @match        *://*.youtube.com/*
// ==/UserScript==

(function() {
    'use strict';
    setInterval(() => {
        const skipBtn = document.querySelector('.ytp-ad-skip-button, .ytp-ad-skip-button-modern, .ytp-skip-ad-button');
        if (skipBtn) skipBtn.click();

        const overlayCloseBtn = document.querySelector('.ytp-ad-overlay-close-button');
        if (overlayCloseBtn) overlayCloseBtn.click();

        if (document.querySelector('.ad-showing')) {
            const video = document.querySelector('video');
            if (video && !isNaN(video.duration)) {
                video.currentTime = video.duration;
            }
        }
    }, 500);
})();
