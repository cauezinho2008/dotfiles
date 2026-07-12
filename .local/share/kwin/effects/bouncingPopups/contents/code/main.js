"use strict";

var blacklist = [
    "ksmserver ksmserver",
    "ksmserver-logout-greeter ksmserver-logout-greeter",
    "kscreenlocker_greet kscreenlocker_greet",
    "ksplashqml ksplashqml"
];

function readConfig(key, fallback) {
    return effect.readConfig(key, fallback);
}

function isPopupWindow(window) {
    if (blacklist.includes(window.windowClass)) {
        return false;
    }

    if (window.popupWindow || window.outline) {
        return true;
    }

    if (!window.managed) {
        return !window.utility;
    }

    if (
        window.dock ||
        window.splash ||
        window.toolbar ||
        window.notification ||
        window.onScreenDisplay ||
        window.criticalNotification ||
        window.appletPopup
    ) {
        return true;
    }

    return false;
}

function setPopupVisualRoles(window, enabled) {
    window.setData(Effect.WindowForceBlurRole, enabled);
    window.setData(Effect.WindowForceBackgroundContrastRole, enabled);
}

var bouncePopupsEffect = {

    loadConfig() {
        this.openDuration =
            animationTime(readConfig("OpenDuration", 265));

        this.closeDuration =
            animationTime(readConfig("CloseDuration", 170));

        this.scaleInFactor =
            readConfig("ScaleInFactor", 0.85);

        this.scaleOutFactor =
            readConfig("ScaleOutFactor", 0.85);
    },

    slotWindowAdded(window) {
        if (effects.hasActiveFullScreenEffect) return;

        if (!isPopupWindow(window) || !window.visible) {
            return;
        }

        if (!effect.grab(window, Effect.WindowAddedGrabRole)) {
            return;
        }

        setPopupVisualRoles(window, true);

        window.scaleInAnimation = animate({
            window,
            curve: QEasingCurve.OutBack,
            duration: this.openDuration,
            type: Effect.Scale,
            from: this.scaleInFactor,
            to: 1.0
        });

        window.opacityInAnimation = animate({
            window,
            curve: QEasingCurve.OutCubic,
            duration: this.openDuration,
            type: Effect.Opacity,
            from: 0.0,
            to: 1.0
        });
    },

    slotWindowClosed(window) {
        if (effects.hasActiveFullScreenEffect) return;

        if (
            !isPopupWindow(window) ||
            !window.visible ||
            window.skipsCloseAnimation
        ) {
            return;
        }

        if (!effect.grab(window, Effect.WindowClosedGrabRole)) {
            return;
        }

        setPopupVisualRoles(window, true);

        window.scaleOutAnimation = animate({
            window,
            curve: QEasingCurve.InBack,
            duration: this.closeDuration,
            type: Effect.Scale,
            from: 1.0,
            to: this.scaleOutFactor
        });

        window.opacityOutAnimation = animate({
            window,
            curve: QEasingCurve.InCubic,
            duration: this.closeDuration,
            type: Effect.Opacity,
            from: 1.0,
            to: 0.0
        });
    },

    slotWindowDataChanged(window, role) {
        if (role === Effect.WindowAddedGrabRole) {
            if (window.scaleInAnimation)
                cancel(window.scaleInAnimation);

            if (window.opacityInAnimation)
                cancel(window.opacityInAnimation);

        } else if (role === Effect.WindowClosedGrabRole) {

            if (window.scaleOutAnimation)
                cancel(window.scaleOutAnimation);

            if (window.opacityOutAnimation)
                cancel(window.opacityOutAnimation);
        }
    },

    init() {
        this.loadConfig();

        effect.configChanged.connect(
            this.loadConfig.bind(this)
        );

        effects.windowAdded.connect(
            this.slotWindowAdded.bind(this)
        );

        effects.windowClosed.connect(
            this.slotWindowClosed.bind(this)
        );

        effects.windowDataChanged.connect(
            this.slotWindowDataChanged.bind(this)
        );
    }
};

bouncePopupsEffect.init();