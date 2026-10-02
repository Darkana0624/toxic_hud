# Toxic HUD (`toxic_hud`)

Status / vehicle HUD, minimap position, cinematic mode, stress system, cigarettes / vape.

- Settings menu: **`/toxichud`** (no key binding - command only)
- Cinematic mode: `/cinematic` (default F9)
- Status HUD: HEALTH / ARMOR / HUNGER / THIRST / STAMINA / STRESS / **LUNG** (underwater breathing capacity) / VOICE
- Exports: `exports['toxic_hud']:hideHud()`, `showHud()`, `toggleHud()`, `setHudHidden(bool)`, `isHudVisible()`
- Server exports: `GetStress / SetStress / AddStress / RelieveStress`

## After the rename
- The resource folder must be `toxic_hud`, and `server.cfg` needs `ensure toxic_hud`.
- Event names: `ls_hud:*` -> `toxic_hud:*`, `lshud:auth` -> `toxic_hud:auth`.
- **ox_inventory `items.lua`**: change the `client.event` of the cigarette / vape / pack items to
  `toxic_hud:client:useSmoke`.
- Old export `exports['ls_hud']` -> `exports['toxic_hud']`.
