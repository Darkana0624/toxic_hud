# LS HUD — Aurora skin

Aurora бол ls_hud-ийн ХУУЧИН бүтцийг бүрэн ашигласан шинэ загвар. client.lua,
bridge.lua, config.lua, fxmanifest.lua-д ямар ч өөрчлөлт шаардахгүй.

## Суулгах

Дараах 4 файлыг resource-ийн `html/` дотор хуулна:

- `index.html`  — skin.css-ийг ачаалж, `.sp-aurora` загварыг нэмсэн
- `skin.css`    — ШИНЭ: өнгө/фонт/хүрээг дарж бичдэг skin layer (style.css-ийн дараа ачаална)
- `script.js`   — өмнөх логик хэвээр, зөвхөн 'aurora' загварыг whitelist/default-д нэмсэн
- `style.css`   — өөрчлөгдөөгүй (бүх хуучин загварын бүтэц хэвээр)

`fxmanifest.lua` дээр files-д skin.css нэмэх шаардлагагүй (NUI нь html фолдерыг
бүхэлд нь ачаалдаг бол); хэрэв тодорхой файлууд бичигдсэн байвал нэмнэ:

    files { 'html/index.html', 'html/style.css', 'html/skin.css', 'html/script.js' }

## client.lua (1 мөр)

`loadSettings` callback дээр status layout-ийг KVP-аас буцаах мөр нэмсэн:

    statusLayout = GetResourceKvpString('lshud:statusLayout'),

Үүнгүй бол зохион байгуулалт reconnect хийсний дараа localStorage-аас
сэргэнэ (сервер localStorage-ыг цэвэрлэвэл default 'frame' болно).

## Юу өөрчлөгдсөн

- Бүх хүрээ / дэвсгэр бүрэн тунгалаг (CEF дээр blur ашиглахгүй — хуучин
  тайлбартай нийцүүлсэн), уншигдац text-shadow-оор хангасан.
- Өнгө: terracotta #c67139 (accent), sage #7a8a5e (2nd), cream #f5ead8 (текст).
- Фонт: Caprasimo (тоонууд) + Figtree (текст). Интернэт байхгүй CEF дээр
  автоматаар system fallback (Segoe UI / Georgia) руу шилжинэ.
- Speedometer шинэ загвар `aurora`: RPM ring (script.js-ийн .sp-rpm-ring hook,
  r=88 / 552.9 dash) + том хурдны тоо, gear pill, түлшний bar, tell icons.
- Тохиргооны цэс Organic style (cream хуудас, pill товч), 5 загварын grid.
- modernpro / ev / minimal / retro / bike / moto / air загварууд хэвээр ажиллана.

## Status HUD — 2 зохион байгуулалт

Тохиргооны цэс (`/lshud`) → **Status HUD**:

- `Minimap frame` — minimap-ийг тойрсон 4 бар (дээр Stamina, доор Health,
  зүүн Hunger, баруун Thirst). Armor / Stress / Voice / Engine тойрог хэвээр.
- `Rings` — хуучин 8 тойрог кластер.

Сонголт нь `lshud:statusLayout` KVP + localStorage-д хадгалагдана.
setCircle() / showCircle() нь одоо querySelectorAll ашигладаг тул хоёр
зохион байгуулалт зэрэг зөв шинэчлэгдэнэ.

## Vehicle HUD — хөдөлгүүрийн эвдрэл

БҮХ загварт хөдөлгүүрийн эвдрэлийн зураас нэмсэн:
Aurora дээр `.au-damage`, бусад загварт (modernpro / ev / minimal / retro /
bike / moto / air) `.dmg` элемент — хоёулаа `data-key="engine"` +
`pathLength="119.38"` тул `setCircle('engine')` hook-ээр шинэчлэгдэнэ.
30%-аас доош бол улаан болж анивчина.
Өгөгдөл нь хуучин `status` message-ийн `engineHealth` талбараас шууд ирнэ.

## Тээврийн хэрэгслийн төрлөөр Speedometer

`Config.AutoSpeedoStyle = true` үед client.lua автоматаар сонгоно:

| Тээврийн хэрэгсэл | Загвар | Онцлог |
| --- | --- | --- |
| Унадаг дугуй (class 13) | `bike` | LCD дугуйн компьютер |
| Мотоцикл (class 8) | `moto` | Хос аналог хэмжүүр |
| Цахилгаан машин (`Config.ElectricVehicles`) | `ev` | Батерей / eco дижитал |
| Дизель машин (`Config.DieselVehicles`) | `diesel` | Торкын зурвас, 4.5k redline тэмдэг |
| Бензин машин (бусад бүх машин) | `petrol` | Том тоо + RPM/FUEL багана |
| Мотоцикл хурдны хязгаар | — | 0–250 km/h (өмнө 0–120) |
| Онгоц (class 16) | `air` | 6 нисэхийн багаж |
| Тэнгэрийн онгоц (class 15) | `heli` | Ротор RPM ring + өндөр (ft) |

client.lua-д нэмсэн:
- `dieselHashes` хүснэгт (`Config.DieselVehicles`-аас)
- `autoStyleFor`: heli / air / moto / bike / ev / diesel / petrol
- `alt/vspeed/heading/roll/pitch` дата heli дээр ч илгээгддэг
- заагч гэрлийн дата (indLeft/indRight) унадаг дугуйнаас бусад бүх загварт

config.lua-д `Config.DieselVehicles` жагсаалт нэмсэн — өөрийн серверийн
машинуудаар чөлөөтэй нэмж болно.

Тоглогч загварыг гараар сольж ЧАДАХГҮЙ — тохиргооны цэснээс "Speedometer
загвар" хэсгийг бүрэн хассан. `Config.AutoSpeedoStyle = false` болговол
бүх машин `petrol` загварыг авна.

## Хасагдсан загварууд

`modernpro`, `minimal`, `retro` гурвыг бүрэн хассан: index.html-ийн блокууд,
цэсний картууд, script.js-ийн GAUGES / buildGauge / buildCluster / setNeedle /
updateAnalogue код (~5.3k тэмдэгт) ба whitelist-ууд. style.css-д тэдгээрийн
хуучин дүрэм үлдсэн (ажиллахад нөлөөлөхгүй, хүсвэл цэвэрлэж болно).

`aurora` загварыг бас хассан (markup, CSS, display дүрэм).
Үлдсэн загварууд: `petrol`, `diesel`, `ev`, `bike`, `moto`, `heli`, `air` —
бүгд автоматаар машины төрлөөр сонгогдоно.

## Байрлал / хадгалалт

Drag-drop байрлал, HUD хэмжээ, нэгж, хэл — хуучин KVP + localStorage
механизмаараа хадгалагдана (`saveSetting` / `loadSettings`).
