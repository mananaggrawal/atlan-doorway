/**
 * The Cowork / claude.ai setup steps: for each screen, what it is and the one
 * thing to click on it.
 *
 * These were screenshots once. They are text now, on purpose: a screenshot of
 * a setup flow is a photograph of somebody's actual workspace — their
 * organisation name, their linked accounts, their host names — and this
 * package is published, so every deployment that installs it shows whatever
 * the capture happened to contain. The instruction is the part that carries
 * the meaning; the pixels only carried a liability.
 *
 * `alt` names the screen AND the control to click, so it reads the same to a
 * screen reader and to anyone following along. `boxes` are kept because they
 * still record WHERE on each screen the control sits, as PERCENTAGES of a
 * 1400x1080 capture — if these ever become images again, the callouts are
 * already measured.
 */

/**
 * A click target, as PERCENTAGES (0–100) of the image's width and height —
 * `ScreenshotStep` writes them straight into `left: x%`, so `0.881` would be
 * a box a hundredth of the size meant.
 */
export interface ShotHighlight {
  x: number;
  y: number;
  w: number;
  h: number;
}

export interface Shot {
  /** Names the screen AND the highlighted control: the box is decoration. */
  alt: string;
  boxes: ShotHighlight[];
}

/** Intrinsic size of every shot, so the column reserves the space before load. */
export const SHOT_WIDTH = 1400;
export const SHOT_HEIGHT = 1080;

export const addManuallyShot: Shot = {
  alt: "Claude's admin settings, Claude Code page: the Add manually button beside GitHub Enterprise, under Self-hosted infrastructure.",
  boxes: [{ x: 88.1, y: 80.5, w: 10.9, h: 3.7 }],
};

export const addConfigurationShot: Shot = {
  alt: 'The Add GitHub Enterprise dialog: the GitHub App credential fields, and the Add configuration button that saves them.',
  boxes: [
    { x: 30.0, y: 43.7, w: 39.8, h: 33.6 },
    { x: 57.3, y: 94.4, w: 12.5, h: 3.9 },
  ],
};

export const connectAccountShot: Shot = {
  alt: "Claude's admin settings, GitHub page: the Connect button above the list of connected GitHub accounts.",
  boxes: [{ x: 88.9, y: 16.7, w: 8.7, h: 3.7 }],
};

export const pickInstanceShot: Shot = {
  alt: 'The Install the Claude Code GitHub App dialog, with the GitHub instance list open on the row naming this deployment rather than github.com.',
  boxes: [{ x: 37.8, y: 76.9, w: 24.3, h: 4.2 }],
};

export const selectRepositoryShot: Shot = {
  alt: 'Claude Code on the web, with the Select repository button highlighted below the empty session area.',
  boxes: [{ x: 38.7, y: 87.3, w: 13.6, h: 3.8 }],
};

export const pluginsAddShot: Shot = {
  alt: 'The Customize screen, with the Plugins tab and the Add button above the list highlighted.',
  boxes: [
    { x: 40.3, y: 11.8, w: 6.2, h: 3.9 },
    { x: 89.7, y: 11.8, w: 6.8, h: 3.9 },
  ],
};

export const addMarketplaceShot: Shot = {
  alt: 'The Add menu open on the Customize screen, with Add marketplace at the top.',
  boxes: [{ x: 79.8, y: 16.5, w: 15.6, h: 3.5 }],
};

export const pasteUrlShot: Shot = {
  alt: 'The Add marketplace dialog: the URL field holding the marketplace address, and the Sync button that fetches it.',
  boxes: [
    { x: 21.8, y: 52.5, w: 56.5, h: 4.1 },
    { x: 72.8, y: 62.1, w: 5.3, h: 3.8 },
  ],
};

export const installPluginsShot: Shot = {
  alt: 'The Discover list after a sync, with the whole Doorway all row highlighted as the bundle that installs everything at once.',
  boxes: [{ x: 27.0, y: 32.1, w: 69.4, h: 7.5 }],
};
