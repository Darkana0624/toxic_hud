# Toxic HUD (`toxic_hud`)

Status / vehicle HUD, minimap байрлал, cinematic mode, stress систем, тамхи-вэйп.

- Тохиргооны цэс: **`/toxichud`** (товчны холбоосгүй — зөвхөн командаар)
- Cinematic mode: `/cinematic` (анхдагч F9)
- Status HUD: HEALTH / ARMOR / HUNGER / THIRST / STAMINA / STRESS / **LUNG** (усан доор амьсгалах багтаамж) / VOICE
- Export: `exports['toxic_hud']:hideHud()`, `showHud()`, `toggleHud()`, `setHudHidden(bool)`, `isHudVisible()`
- Server export: `GetStress / SetStress / AddStress / RelieveStress`

## Нэр солигдсон тул шинэчлэх зүйлс
- Resource folder нь `toxic_hud` байх ёстой, `server.cfg` дотор `ensure toxic_hud`.
- Event нэрс: `ls_hud:*` -> `toxic_hud:*`, `lshud:auth` -> `toxic_hud:auth`.
- **ox_inventory `items.lua`**: тамхи / вэйп / хайрцгийн `client.event` -ийг
  `toxic_hud:client:useSmoke` болгож солино.
- Хуучин export `exports['ls_hud']` -> `exports['toxic_hud']`.
