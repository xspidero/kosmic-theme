/**
 * ====================================================================
 *  Kosmic Theme Engine & Runtime
 *  Author: xspidero
 *  Build: Release 1.0.0
 * ====================================================================
 */

(function () {
    'use strict';

    const CONFIG = {
        apiEndpoint: 'https://licensing.veloracloud.site/api/verify',
        productSlug: 'kosmic-theme',
        discordInvite: 'https://discord.com/invite/hc9TUCsQpS',
        storageKey: 'kosmic_theme_license',
    };

    /**
     * Suppress irritating reCAPTCHA badge overlay permanently
     */
    function silenceCaptchaBadge() {
        if (!document.getElementById('kosmic-captcha-silencer')) {
            const style = document.createElement('style');
            style.id = 'kosmic-captcha-silencer';
            style.innerHTML = `
                .grecaptcha-badge {
                    visibility: hidden !important;
                    opacity: 0 !important;
                    pointer-events: none !important;
                    transform: scale(0) !important;
                    display: none !important;
                }
            `;
            document.head.appendChild(style);
        }
    }

    /**
     * Inject Discord Community Pill in Navigation Bar
     */
    function initNavigationEnhancements() {
        const checkNav = setInterval(() => {
            const navRight = document.querySelector('div[class*="RightNavigation"]');
            if (!navRight || document.querySelector('#kosmic-theme-controls')) return;

            clearInterval(checkNav);

            // Container for controls
            const controls = document.createElement('div');
            controls.id = 'kosmic-theme-controls';
            controls.style.cssText = 'display: flex; align-items: center; margin-right: 0.5rem;';

            // Discord Community Pill
            const discordBtn = document.createElement('a');
            discordBtn.href = CONFIG.discordInvite;
            discordBtn.target = '_blank';
            discordBtn.rel = 'noopener noreferrer';
            discordBtn.title = 'Join Discord for Support & Free Licenses';
            discordBtn.style.cssText = `
                display: inline-flex;
                align-items: center;
                gap: 6px;
                padding: 5px 12px;
                font-size: 0.78rem;
                font-weight: 600;
                color: #ffffff;
                background: linear-gradient(135deg, #5865f2 0%, #4752c4 100%);
                border-radius: 9999px;
                text-decoration: none;
                box-shadow: 0 2px 10px rgba(88, 101, 242, 0.35);
                transition: all 0.2s ease;
            `;
            discordBtn.innerHTML = `
                <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028c.462-.63.874-1.295 1.226-1.994.021-.041.001-.09-.041-.106a13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.929 1.793 8.18 1.793 12.061 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.894.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.028z"/>
                </svg>
                <span>Discord</span>
            `;
            discordBtn.onmouseenter = () => {
                discordBtn.style.transform = 'translateY(-1px)';
                discordBtn.style.boxShadow = '0 4px 15px rgba(88, 101, 242, 0.6)';
            };
            discordBtn.onmouseleave = () => {
                discordBtn.style.transform = 'translateY(0)';
                discordBtn.style.boxShadow = '0 2px 10px rgba(88, 101, 242, 0.35)';
            };

            controls.appendChild(discordBtn);
            navRight.prepend(controls);
        }, 300);
    }

    // Clean up any legacy customizer preferences
    try {
        localStorage.removeItem('kosmic_theme_prefs');
    } catch (e) {}

    // Auto-init on page load
    silenceCaptchaBadge();
    initNavigationEnhancements();

    // Listen for DOM changes in case of SPA transitions
    const observer = new MutationObserver(() => {
        silenceCaptchaBadge();
        if (!document.querySelector('#kosmic-theme-controls')) {
            initNavigationEnhancements();
        }
    });
    observer.observe(document.body, { childList: true, subtree: true });

})();
