Config = {}

-- Framework сонголт:
--   'auto'       -> автоматаар илрүүлнэ (qbx_core / qb-core / es_extended)
--   'qbx'        -> QBox (qbx_core)
--   'qb'         -> QBCore (qb-core)
--   'esx'        -> ESX (es_extended)
--   'standalone' -> framework байхгүй (мөнгө / job / needs харагдахгүй)
Config.Framework = 'qbx'

-- Цаг шинэчлэх давтамж (ms)
Config.UpdateInterval = 200

-- Юаны нэгж тэмдэг
Config.MoneyPrefix = '$'

-- MPH ашиглах эсэх (false бол KMH)
Config.UseMPH = true

-- Анхдагч хэл (тоглогч цэснээс өөрчилж болно, сонголт нь хадгалагдана).
-- Боломжтой утга: 'en' (English), 'ru' (Русский), 'zh' (中文),
--                 'ko' (한국어), 'fr' (Français), 'mn' (Монгол)
Config.Language = 'en'

-- HUD-ийн анхдагч хэмжээ (масштаб).
-- HUD нь дэлгэцийн нягтрал/дүрсний харьцаанд автоматаар тохирдог (800x600-оос
-- 4K хүртэл, 4:3 / 16:10 / 16:9 / 21:9 / 32:9). Энэ утга нь тэрхүү авто
-- масштабын ДЭЭР үржигдэх ерөнхий коэффициент бөгөөд тоглогч /lshud цэснээс
-- өөрийн хэмжээг (70% - 150%) сонговол түүнийг нь давуу эрхтэйгээр хэрэглэнэ.
Config.HudScale = 1.0

-- Status элементүүдийг харуулах эсэх
Config.ShowHunger = true
Config.ShowThirst = true
Config.ShowStress = true    -- Stress систем (доорх Config.Stress) идэвхтэй тул асаалттай
Config.ShowStamina = true   -- Гүйх тэнхээ (stamina)
Config.ShowVoice = true     -- Микрофон / voice range (pma-voice)

-- Speedometer-ийг зөвхөн машинд харуулах
Config.ShowSpeedoOnlyInVehicle = true

-- Speedometer загварыг ЗӨВХӨН тээврийн хэрэгслийн төрөл шийднэ (тоглогч
-- гараар сольж чадахгүй). false болговол бүх машинд 'petrol' загвар гарна.
-- Автомат speedo загвар сонголт:
--   Нисдэг тэрэг (class 15)          -> 'heli'   (ротор RPM ring + өндөр)
--   Онгоц (class 16)                 -> 'air'    (нисэхийн 6 багаж)
--   Мотоцикл (class 8)               -> 'moto'   (хос аналог хэмжүүр)
--   Унадаг дугуй (class 13)          -> 'bike'   (LCD дугуйн компьютер)
--   Цахилгаан машин (доорх жагсаалт) -> 'ev'     (батерей / eco дижитал)
--   Дизель машин (доорх жагсаалт)    -> 'diesel' (торкын зурвас)
--   Бусад бүх машин                  -> 'petrol' (том тоо + RPM/FUEL багана)
Config.AutoSpeedoStyle = true

-- ============================================================
--  Цахилгаан тээврийн хэрэгслүүд -> 'ev' загвар
--  Жагсаалт нь qbx_core/shared/vehicles.lua доторх бодит машинуудаас
--  гаргасан (байхгүй model оруулаагүй). Шинэ машин нэмвэл энд бичнэ.
-- ============================================================
Config.ElectricVehicles = {
    -- GTA — цахилгаан суудлын машин
    'voltic', 'cyclone', 'tezeract', 'virtue',
    'imorgon', 'omnisegt', 'khamelion', 'raiden',
    'surge', 'dilettante', 'dilettante2', 'buffalo5',
    'iwagen', 'vivanite',
    -- GTA — цахилгаан мото / жижиг
    'shotaro', 'powersurge', 'inductor', 'inductor2',
    'rcbandito',
    -- GTA — цахилгаан ажлын тэрэг
    'caddy', 'caddy2', 'caddy3', 'airtug',
    -- Алба хаагчийн цахилгаан хувилбар
    'tstudio_polraiden', 'tstudio_medraiden', 'tstudio_polomnisegt', 'tstudio_medomnisegt',
    -- Add-on — бодит цахилгаан загварууд
    'model3', 'models', 'modelx', 'teslaroad',
    'teslapd', 'DLCyber', 'taycan', 'taycanani',
    'ocnetrongt', 'gmcev2', 'DLI8', 'mi8',
}

-- ============================================================
--  Дизель тээврийн хэрэгслүүд -> 'diesel' загвар
--  Жагсаалтад ч, дээрх ElectricVehicles-д ч байхгүй бүх машин
--  автоматаар 'petrol' загварыг авна.
-- ============================================================
Config.DieselVehicles = {
    -- Ачааны / чиргүүлтэй (commercial)
    'benson', 'biff', 'hauler', 'hauler2',
    'packer', 'phantom', 'phantom2', 'phantom3',
    'phantom4', 'pounder', 'pounder2', 'stockade',
    'stockade3', 'terbyte',
    -- Аж үйлдвэрийн (industrial)
    'bulldozer', 'cutter', 'dump', 'flatbed',
    'guardian', 'handler', 'rubble', 'tiptruck',
    'tiptruck2',
    -- Ажлын / чирэх (utility)
    'docktug', 'forklift', 'ripley', 'sadler',
    'sadler2', 'scrap', 'towtruck', 'towtruck2',
    'towtruck3', 'towtruck4', 'tractor', 'tractor2',
    'tractor3', 'utillitruck', 'utillitruck2', 'utillitruck3',
    -- Автобус / нийтийн үйлчилгээ (service)
    'airbus', 'bus', 'coach', 'pbus2',
    'rentalbus', 'tourbus', 'brickade', 'brickade2',
    'trash', 'trash2', 'wastelander',
    -- Онцгой байдал / цагдаа (хүнд)
    'ambulance', 'firetruk', 'pbus', 'riot',
    'riot2', 'policet', 'tstudio_polriot',
    -- Хүргэлтийн фургон
    'boxville', 'boxville2', 'boxville3', 'boxville4',
    'boxville6', 'pony', 'pony2', 'speedo',
    'speedo2', 'speedo4', 'taco',
    -- Add-on — бодит дизель ачааны
    'sw_sprinter', 'DLF450', 'madf350lift', 'raid',
    'RYGBus',
}

-- Гудамжны нэр / speed limit харуулах
Config.ShowStreetInfo = true

-- ============================================================
--  Minimap-ийн хүрээ (Status HUD "Minimap frame" горим)
--  Хүрээ нь GTA-гийн radar-ийн бодит байрлалыг нативуудаар бодож
--  автоматаар зэрэгцдэг. Гэхдээ minimap-ийг өөрчилдөг resource
--  (өргөтгөсөн газрын зураг, дугуй/дөрвөлжин minimap mod г.м)
--  байвал автомат тооцоо таарахгүй.
--
--  Тэр үед enabled = true болгож, доорх утгуудыг ДЭЛГЭЦИЙН ХУВИАР
--  (0.0 - 1.0) гараар өгнө. Тавиагүй (nil) талбарыг автомат
--  тооцоолсон утгаараа үлдээнэ.
--     x -> зүүн ирмэгээс дэлгэцийн өргөний хэдэн хувь
--     b -> доод ирмэгээс дэлгэцийн өндрийн хэдэн хувь
--     w -> minimap-ийн өргөн (дэлгэцийн өргөний хувиар)
--     h -> minimap-ийн өндөр (дэлгэцийн өндрийн хувиар)
--
--  Жишээ (1920x1080 дээр 340x224 px minimap, зүүн доод буланд 30/40 px):
--     enabled = true, x = 30/1920, b = 40/1080, w = 340/1920, h = 224/1080
-- ============================================================
Config.MinimapOverride = {
    enabled = false,
    x = nil,
    b = nil,
    w = nil,
    h = nil,
}

-- ============================================================
--  GTA-гийн ҮНДСЭН health / armour бар
--  Тоглоомын анхны ногоон (амь) ба цэнхэр (хуяг) зураас minimap-ийн
--  доор гарч ирдэг. LS HUD өөрөө амь / хуягийг харуулдаг тул
--  давхардуулахгүйн тулд нууна.
--  Нуулт нь "minimap" scaleform-ийн SETUP_HEALTH_ARMOUR аргаар
--  хийгддэг тул minimap.gfx файл солих шаардлагагүй.
-- ============================================================
Config.HideNativeHealthArmour = true

-- ============================================================
--  STRESS СИСТЕМ
--  Stress нь qbx_core-ийн metadata.stress дотор хадгалагдаж,
--  мөн Player(src).state.stress statebag-аар бусад resource-д
--  нээлттэй байна (envi-bridge, jg-stress-addon г.м. уншина).
--
--  ЗАРЧИМ: stress нь "бараг мэдэгдэхгүй" байхаар тохируулсан —
--  өдөр тутмын тоглолтод бараг өсөхгүй, тамхи / вэйп татахад
--  шууд буурна. Доорх тоонууд ХУВЬ (0-100).
-- ============================================================
Config.Stress = {
    enabled = true,

    -- Байгалийн бууралт: тодорхой хугацаа тутам тогтмол хэмжээгээр хасна.
    decayInterval = 60,     -- секунд
    decayAmount   = 1.0,    -- тухай бүрт хасах хувь

    -- ═══════════ STRESS НЭМЭГДЭХ ═══════════
    -- ЗҮГЭЭР ЖОЛООДОХ нь stress ӨГӨХГҮЙ. Зөвхөн МӨРГӨХ үед л нэмэгдэнэ.
    gain = {
        -- Машинаар мөргөх. Бие махбодын эвдрэлийн хэмжээгээр тооцно.
        crash = {
            enabled   = true,
            minDamage = 40,    -- нэг мөргөлтөд эвдрэх хамгийн бага хэмжээ (1000-аас)
            perDamage = 0.02,  -- эвдрэлийн нэгж тутамд нэмэх stress
            maxPerHit = 6.0,   -- нэг мөргөлтөд нэмэгдэх дээд хязгаар
            cooldown  = 3,     -- секунд
        },

        -- Унах / тэнцвэрээ алдах. ls_core/antipunchspam нударга спам
        -- хийхэд тоглогчийг унагадаг — тэр эвентийг сонсоно. Мөн бусад
        -- шалтгаанаар (өндрөөс унах, мотоциклоос нисэх) ragdoll болоход
        -- ч нэмэгдэнэ.
        ragdoll = {
            enabled  = true,
            amount   = 1.5,
            cooldown = 10,     -- секунд
        },

        -- Жижиг гэмтэл — амь буурах бүрт. Зодуулах / буудуулах / унах
        -- зэрэг УНААГҮЙ үеийн бага зэргийн гэмтэлд зориулав.
        injury = {
            enabled   = true,
            minDrop   = 5,     -- нэг удаад алдсан хамгийн бага амь
            perHp     = 0.25,  -- алдсан амь тутамд нэмэх stress
            maxPerHit = 8.0,
        },

        -- Унаж / цус алдах — p_ambulancejob-ийн АЛБАН ЁСНЫ hook
        --   server: RegisterNetEvent('p_ambulancejob/onDeathStateChange')
        --   deathType: 'death' | 'bleeding' | 'recovering' | 'none'
        -- Жижиг гэмтлээс тусад нь, хамаагүй том хэмжээтэй.
        downed = {
            enabled  = true,
            bleeding = 12.0,   -- унаж цус алдаж эхлэхэд
            death    = 20.0,   -- үхэх үед

            -- Цус алдаж хэвтэх хугацаанд тасралтгүй нэмэгдэх.
            -- LocalPlayer.state.deathType statebag-аар хянана.
            whileBleeding = {
                enabled  = true,
                amount   = 1.0,
                interval = 15,   -- секунд
            },
        },
    },

    -- ═══════════ STRESS ТАЙЛАГДАХ ═══════════
    relief = {
        -- Хурдтай жолоодох — "салхинд гарах". Тогтмол хурдтай явахад
        -- аажим тайлагдана. (Зогсох / удаан явахад тайлагдахгүй.)
        fastDriving = {
            enabled  = true,
            minSpeed = 80,     -- км/ц — үүнээс дээш хурдтай байх ёстой
            amount   = 0.6,
            interval = 20,     -- секунд
        },

        -- GYM — prompt_anim_core_2_new-ийн hooks/hooks_server.lua дотор
        --       onRep hook-оор холбогдсон. Дасгалын давталт бүрт.
        --       (Тэнд хэмжээг өөрчилнө.)

        -- ХООЛ / АРХИ — qbx_consumables өөрөө stress бууруулдаг
        --       (config.lua дотор stressRelief талбартай) бөгөөд утгыг
        --       statebag руу бичдэг. LS HUD түүнийг шууд дагана —
        --       нэмэлт код шаардахгүй.

        -- ТАМХИ / ВЭЙП — доорх Config.Smoking хэсэгт.
    },

    max = 100.0,
}

-- ============================================================
--  ТАМХИ / ВЭЙП — stress бууруулах
--  Анимаци, prop, item нэр, зураг нь lusty94_smoking-аас авсан.
--  Ажиллагаа нь ox_inventory + ox_lib дээр дахин бичигдсэн
--  (эх код нь qb-core/qb-inventory дээр байсан).
--
--  Item-үүдийг ox_inventory/data/items.lua дотор бүртгэсэн,
--  зургуудыг ox_inventory/web/images рүү хуулсан.
-- ============================================================
Config.Smoking = {
    enabled = true,

    -- Тамхины хайрцаг задлахад гардаг ширхэгийн item нэр
    cigItem = 'cigs',

    items = {
        -- ---- Хайрцгууд: задлахад cigs гарна, stress-д нөлөөлөхгүй ----
        ['redwoodpack'] = {
            label = 'Redwood хайрцаг задалж байна',
            duration = 6,
            returns = { item = 'cigs', amount = 20 },
            dict = 'amb@prop_human_parking_meter@female@base',
            anim = 'base_female',
            prop = 'v_ret_ml_cigs',
            bone = 57005,
            pos  = vec3(0.14, 0.01, -0.03),
            rot  = vec3(2.0, 68.0, -32.0),
        },
        ['debonairepack'] = {
            label = 'Debonaire хайрцаг задалж байна',
            duration = 6,
            returns = { item = 'cigs', amount = 20 },
            dict = 'amb@prop_human_parking_meter@female@base',
            anim = 'base_female',
            prop = 'v_ret_ml_cigs3',
            bone = 57005,
            pos  = vec3(0.14, 0.01, -0.03),
            rot  = vec3(2.0, 68.0, -32.0),
        },
        ['yukonpack'] = {
            label = 'Yukon хайрцаг задалж байна',
            duration = 6,
            returns = { item = 'cigs', amount = 20 },
            dict = 'amb@prop_human_parking_meter@female@base',
            anim = 'base_female',
            prop = 'p_cigar_pack_02_s',
            bone = 57005,
            pos  = vec3(0.14, 0.01, -0.03),
            rot  = vec3(2.0, 68.0, -32.0),
        },
        ['sixtyninepack'] = {
            label = '69 Brand хайрцаг задалж байна',
            duration = 6,
            returns = { item = 'cigs', amount = 20 },
            dict = 'amb@prop_human_parking_meter@female@base',
            anim = 'base_female',
            prop = 'p_cigar_pack_02_s',
            bone = 57005,
            pos  = vec3(0.14, 0.01, -0.03),
            rot  = vec3(2.0, 68.0, -32.0),
        },

        -- ---- Татдаг зүйлс: stress бууруулна ----
        ['cigs'] = {
            label = 'Тамхи татаж байна',
            duration = 12,
            requires = { item = 'lighter', label = 'Асаагуур' },  -- зарцуулагдахгүй
            stress = 25.0,     -- бууруулах хувь
            armour = 0,        -- lusty94 дээр 10 байсан; хуяг нэмэх нь HUD-д логикгүй
            health = 2,        -- татахад амиас хасах (0 бол хасахгүй)
            dict = 'amb@world_human_aa_smoke@male@idle_a',
            anim = 'idle_c',
            prop = 'prop_cs_ciggy_01',
            bone = 28422,
            pos  = vec3(0.0, 0.0, 0.0),
            rot  = vec3(0.0, 0.0, 0.0),
        },
        ['vape'] = {
            label = 'Вэйп татаж байна',
            duration = 12,
            requires = { item = 'vapejuice', label = 'Вэйп шингэн' },
            consumesRequired = 0.25,   -- 25% магадлалаар шингэн зарцуулна
            keepItem = true,           -- вэйп өөрөө зарцуулагдахгүй
            stress = 25.0,
            armour = 0,
            health = 0,
            dict = 'amb@world_human_smoking@male@male_b@base',
            anim = 'base',
            prop = 'ba_prop_battle_vape_01',
            bone = 28422,
            pos  = vec3(-0.029, 0.007, -0.005),
            rot  = vec3(91.0, 270.0, -360.0),
        },
    },
}

-- ============================================================
--  Minimap (radar)-ийн байрлал
--     'bottom-left' — GTA-гийн анхдагч (зүүн доод). Radar-ийг огт хөндөхгүй.
--     'top-right'   — баруун дээд булан.
--
--  Байрлал өөрчлөгдөхөд HUD-ийн бусад хэсэг АВТОМАТААР дагана:
--    * Status frame (minimap-ийг тойрсон 4 бар) тэр булан руу шилжинэ
--    * Status тойргийн кластер minimap-ийн эсрэг тал руу шилжинэ
--
--  Шилжих зайг дэлгэцийн нягтрал / дүрсний харьцаа / safezone-оос
--  АВТОМАТААР бодно. Тоглоомын гурван бүрдлийг (зураг / маск / бүдгэрэлт)
--  нэг ижил зайгаар шилжүүлдэг тул маск зурагнаасаа, компас газрын
--  зурагнаасаа хэзээ ч салахгүй.
--
--  ХЯЗГААРЛАЛТ (тоглоомын өөрийнх, зөөлтийг дагадаггүй хэсгүүд):
--    * "Bigmap" (Z товч) хэвээр зүүн доод буланд нээгдэнэ
--    * Үндсэн health / armour arc байрлал зөрнө — гэхдээ дээрх
--      HideNativeHealthArmour тэдгээрийг нууж байгаа тул нөлөөгүй
-- ============================================================
Config.MinimapPosition = 'top-right'

-- Автомат тооцооны ДЭЭР нэмэх засвар (дэлгэцийн хувиар, 0.0 = засваргүй).
--     x эерэг = баруун тийш, y эерэг = дээш
-- Ихэвчлэн хэрэггүй. Minimap-ийг өөрчилдөг өөр resource байвал (дөрвөлжин
-- minimap, өргөтгөсөн газрын зураг г.м) 2-3 мянганы нэгжээр зөрж болно.
-- Тоглоом дундаас /mmpos <dx> <dy> гэж нударч олоод, гарсан утгыг энд бичнэ.
Config.MinimapNudge = { x = 0.0, y = 0.0 }

-- Тоглогч minimap-ийг ӨӨРӨӨ хүссэн газраа тавьж болох эсэх.
-- true бол F7 -> "Байрлал засах" горимд minimap-ийн тэгш өнцөгтийг
-- төлөөлсөн хайрцаг гарч ирэх бөгөөд түүнийг чирснээр бодит radar
-- тэр байрлал руу шилжинэ. Сонголт нь бусад HUD элементийн хамт
-- хадгалагдаж, дахин холбогдоход сэргэнэ.
--
-- Дээрх Config.MinimapPosition нь зөвхөн АНХДАГЧ байрлал болно —
-- тоглогч чирсэн бол түүний сонголт давуу эрхтэй. Цэсний Reset товч
-- minimap-ийг ч тоглоомын анхдагч байрлал руу буцаана.
Config.AllowPlayerMinimapMove = true

-- ============================================================
--  CINEMATIC MODE — тоглогч HUD-ээ түр унтраах
--  Скриншот / видео бичихэд зориулав. Товчийг тоглогч FiveM-ийн
--  Settings > Key Bindings > FiveM хэсгээс дураараа сольж болно.
--  Чатаар: /cinematic
-- ============================================================
Config.Cinematic = {
    Key        = 'F9',   -- анхдагч товч (тоглогч сольж болно)
    HideRadar  = true,   -- minimap-ыг ч хамт унтраах уу
    Bars       = false,  -- кино маягийн хар зураас (дээр/доор)
    BarHeight  = 0.11,   -- зураас тус бүрийн өндөр, дэлгэцийн хувиар
}

return Config
