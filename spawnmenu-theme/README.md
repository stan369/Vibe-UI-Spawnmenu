# TheGmod.Club Spawnmenu Theme

A client-side addon that reskins the Garry's Mod spawn menu (hold `Q`) to match
the TheGmod.Club brand — dark surfaces, a subtle grid, a soft purple glow, and
orange→purple gradient highlights.

## Features

- Dark themed windows with a faint grid pattern and a soft purple bottom glow
- Orange→purple gradient on the active tab, selected tree item, and selected tool
- White, readable text across the tree, tool list, and tool panels
- Orange outline when hovering prop/tool icons
- Subtle accent divider between the columns

## Install

1. Copy the `spawnmenu-theme` folder into `garrysmod/addons/`.
2. Reconnect to the server (or restart the game) so the client Lua loads.
3. Hold `Q` — the spawn menu is themed automatically.

It's client-side only, so each player loads it on join. Nothing needs to run on
the server.

## Configuration

Everything lives in one file:

```
lua/autorun/client/cl_tgc_spawnmenu_skin.lua
```

- **Colors** — edit the `C` table at the top of the file.
- **Purple glow** — the `windowGlowPaint` function (alpha / position).
- **Disable** — set `ENABLED = false` near the top, or remove the addon.

## Notes

- Reskinning the spawn menu is done with a custom derma skin plus a panel-tree
  walker, because large parts of the menu are hardcoded and a skin alone can't
  reach them.
- Third-party tools that draw their own panels (e.g. Advanced Duplicator 2) keep
  their own look — they'd need to be themed separately.
