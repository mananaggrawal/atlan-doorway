import fs from 'node:fs/promises';
import path from 'node:path';
import ignore, { type Ignore } from 'ignore';

/**
 * The ignore file's own name. Exported because the file-tree filter hides it
 * from non-admins, and both places must agree on the spelling.
 */
export const IGNORE_FILENAME = '.doorwayignore';

/** One .doorwayignore file's rules, scoped to the directory it lives in. */
interface IgnoreLayer {
  /** Absolute path of the directory where the .doorwayignore lives. */
  readonly root: string;
  readonly matcher: Ignore;
}

/**
 * A hierarchical stack of `.doorwayignore` rule sets.
 *
 * Each `.doorwayignore` file applies to paths beneath the directory it lives in,
 * using standard gitignore syntax (negations, `**`, directory-only patterns, anchoring).
 * Deeper files combine with — and can override — rules from shallower files,
 * mirroring how git layers `.gitignore` files.
 */
export class DoorwayIgnoreStack {
  private constructor(private readonly layers: readonly IgnoreLayer[]) {}

  static empty(): DoorwayIgnoreStack {
    return new DoorwayIgnoreStack([]);
  }

  /**
   * Return a new stack that additionally includes a `.doorwayignore` from `dir`
   * (if present). If no `.doorwayignore` exists in `dir`, returns this stack unchanged.
   */
  async extendedWith(dir: string): Promise<DoorwayIgnoreStack> {
    const file = path.join(dir, IGNORE_FILENAME);
    let contents: string;
    try {
      contents = await fs.readFile(file, 'utf-8');
    } catch {
      return this;
    }
    const matcher = ignore().add(contents);
    return new DoorwayIgnoreStack([...this.layers, { root: dir, matcher }]);
  }

  /**
   * Whether the given entry should be hidden from the file tree.
   * @param absolutePath absolute path of the entry
   * @param isDirectory needed because gitignore patterns ending in `/` match directories only
   */
  isIgnored(absolutePath: string, isDirectory: boolean): boolean {
    for (const layer of this.layers) {
      const rel = path.relative(layer.root, absolutePath).replace(/\\/g, '/');
      // Skip entries that aren't under this layer's root (shouldn't happen in normal
      // recursion, but guards against absolute-path quirks on Windows).
      if (!rel || rel.startsWith('..')) continue;
      // Append trailing slash for directories so `foo/`-style rules match correctly.
      const probe = isDirectory ? `${rel}/` : rel;
      if (layer.matcher.ignores(probe)) return true;
    }
    return false;
  }
}
