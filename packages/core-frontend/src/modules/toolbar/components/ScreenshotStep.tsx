import type { Shot } from './claude-setup-shots';

/**
 * One step of the Cowork / claude.ai setup walkthrough: the screen you should
 * be looking at, and the control to click on it.
 *
 * This used to render a screenshot with the control boxed in red. It renders
 * the instruction as text instead — see the note in `claude-setup-shots.ts`
 * for why. `alt` was always written to name both the screen and the control,
 * precisely so a screen reader got the whole instruction without the image;
 * that makes it the right thing to show everyone. `role="note"` marks it as
 * one discrete aside within the walkthrough, the same job `role="img"` did.
 */
export function ScreenshotStep({ shot }: { shot: Shot }) {
  return (
    <p role="note" className="rounded-md border border-line bg-sunken px-3 py-2 text-sm text-ink">
      {shot.alt}
    </p>
  );
}
