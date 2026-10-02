Config = {}

-- Framework selection:
--   'auto'       -> detect automatically (qbx_core / qb-core / es_extended)
--   'qbx'        -> QBox (qbx_core)
--   'qb'         -> QBCore (qb-core)
--   'esx'        -> ESX (es_extended)
--   'standalone' -> no framework (money / job / needs are not shown)
Config.Framework = 'qbx'

-- Status refresh interval (ms)
Config.UpdateInterval = 200

-- Currency prefix
Config.MoneyPrefix = '$'

-- Use MPH (false = KMH)
Config.UseMPH = true

-- Default language (the player can change it in the menu and the choice is saved).
-- Available: 'en' (English), 'ru' (Русский), 'zh' (中文),
--            'ko' (한국어), 'fr' (Français), 'mn' (Mongolian)
Config.Language = 'en'

-- Default HUD size (scale).
-- The HUD adapts automatically to the screen resolution / aspect ratio (800x600
-- up to 4K; 4:3 / 16:10 / 16:9 / 21:9 / 32:9). This value is a general
-- multiplier applied ON TOP of that automatic scale. If the player picks their
-- own size (70% - 150%) in the /toxichud menu, that choice takes priority.
Config.HudScale = 1.0

-- Which status elements to show
Config.ShowHunger = true
Config.ShowThirst = true
Config.ShowStress = true    -- Stress system (Config.Stress below) is enabled
Config.ShowStamina = true   -- Sprint stamina
Config.ShowVoice = true     -- Microphone / voice range (pma-voice)
Config.ShowLungCapacity = true  -- Lung capacity (time left to breathe underwater)

-- Lung capacity (LUNG CAPACITY)
--   maxTime      -> seconds of air with full lungs. GTA's default is 10 s. If
--                   another resource (SetPedMaxTimeUnderwater etc.) raises it,
--                   give the same value here; if the real remaining time ever
--                   exceeds it, the HUD raises its own maximum automatically.
--   hideWhenFull -> hide the bar when lungs are full and the player is not underwater
Config.LungCapacity = {
    maxTime      = 10.0,
    hideWhenFull = true,
}

-- Show the speedometer only inside vehicles
Config.ShowSpeedoOnlyInVehicle = true

-- The speedometer style is decided ONLY by the vehicle type (players cannot
-- change it). Set to false to use the 'petrol' style for every vehicle.
-- Automatic speedo style selection:
--   Helicopter (class 15)        -> 'heli'   (rotor RPM ring + altitude)
--   Plane (class 16)             -> 'air'    (6 aviation instruments)
--   Motorcycle (class 8)         -> 'moto'   (dual analog gauges)
--   Bicycle (class 13)           -> 'bike'   (LCD bike computer)
--   Electric car (list below)    -> 'ev'     (battery / eco digital)
--   Diesel vehicle (list below)  -> 'diesel' (torque band)
--   Everything else              -> 'petrol' (big number + RPM/FUEL bars)
Config.AutoSpeedoStyle = true

-- ============================================================
--  Electric vehicles -> 'ev' style
--  Taken from the real vehicles in qbx_core/shared/vehicles.lua
--  (no non-existent models). Add new vehicles here.
-- ============================================================
Config.ElectricVehicles = {
    -- GTA - electric passenger cars
    'voltic', 'cyclone', 'tezeract', 'virtue',
    'imorgon', 'omnisegt', 'khamelion', 'raiden',
    'surge', 'dilettante', 'dilettante2', 'buffalo5',
    'iwagen', 'vivanite',
    -- GTA - electric bikes / small
    'shotaro', 'powersurge', 'inductor', 'inductor2',
    'rcbandito',
    -- GTA - electric work carts
    'caddy', 'caddy2', 'caddy3', 'airtug',
    -- Emergency service electric variants
    'tstudio_polraiden', 'tstudio_medraiden', 'tstudio_polomnisegt', 'tstudio_medomnisegt',
    -- Add-on - real electric models
    'model3', 'models', 'modelx', 'teslaroad',
    'teslapd', 'DLCyber', 'taycan', 'taycanani',
    'ocnetrongt', 'gmcev2', 'DLI8', 'mi8',
}

-- ============================================================
--  Diesel vehicles -> 'diesel' style
--  Any vehicle in neither this list nor ElectricVehicles above
--  automatically gets the 'petrol' style.
-- ============================================================
Config.DieselVehicles = {
    -- Trucks / trailers (commercial)
    'benson', 'biff', 'hauler', 'hauler2',
    'packer', 'phantom', 'phantom2', 'phantom3',
    'phantom4', 'pounder', 'pounder2', 'stockade',
    'stockade3', 'terbyte',
    -- Industrial
    'bulldozer', 'cutter', 'dump', 'flatbed',
    'guardian', 'handler', 'rubble', 'tiptruck',
    'tiptruck2',
    -- Work / towing (utility)
    'docktug', 'forklift', 'ripley', 'sadler',
    'sadler2', 'scrap', 'towtruck', 'towtruck2',
    'towtruck3', 'towtruck4', 'tractor', 'tractor2',
    'tractor3', 'utillitruck', 'utillitruck2', 'utillitruck3',
    -- Buses / public service
    'airbus', 'bus', 'coach', 'pbus2',
    'rentalbus', 'tourbus', 'brickade', 'brickade2',
    'trash', 'trash2', 'wastelander',
    -- Emergency / police (heavy)
    'ambulance', 'firetruk', 'pbus', 'riot',
    'riot2', 'policet', 'tstudio_polriot',
    -- Delivery vans
    'boxville', 'boxville2', 'boxville3', 'boxville4',
    'boxville6', 'pony', 'pony2', 'speedo',
    'speedo2', 'speedo4', 'taco',
    -- Add-on - real diesel trucks
    'sw_sprinter', 'DLF450', 'madf350lift', 'raid',
    'RYGBus',
}

-- Show street name / speed limit
Config.ShowStreetInfo = true

-- ============================================================
--  Minimap frame (Status HUD "Minimap frame" mode)
--  The frame aligns itself with GTA's real radar position, computed from
--  natives. But if a resource changes the minimap (expanded map, round /
--  square minimap mods etc.) the automatic calculation will not match.
--
--  In that case set enabled = true and provide the values below as a
--  FRACTION OF THE SCREEN (0.0 - 1.0). Fields left nil keep their
--  automatically calculated value.
--     x -> fraction of screen width from the left edge
--     b -> fraction of screen height from the bottom edge
--     w -> minimap width (fraction of screen width)
--     h -> minimap height (fraction of screen height)
--
--  Example (340x224 px minimap at 1920x1080, 30/40 px from bottom-left):
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
--  GTA's NATIVE health / armour bars
--  The game's original green (health) and blue (armour) bars appear under
--  the minimap. Toxic HUD already shows health / armour, so they are hidden
--  to avoid duplicates.
--  Hiding uses the "minimap" scaleform's SETUP_HEALTH_ARMOUR method, so no
--  minimap.gfx replacement is needed.
-- ============================================================
Config.HideNativeHealthArmour = true

-- ============================================================
--  STRESS SYSTEM
--  Stress is stored in qbx_core's metadata.stress and is also exposed to
--  other resources through the Player(src).state.stress statebag
--  (envi-bridge, jg-stress-addon etc. read it).
--
--  PRINCIPLE: stress is tuned to be "almost unnoticeable" - it barely rises
--  in everyday play and drops immediately when smoking / vaping.
--  The numbers below are PERCENTAGES (0-100).
-- ============================================================
Config.Stress = {
    enabled = true,

    -- Natural decay: a fixed amount is removed at a fixed interval.
    decayInterval = 60,     -- seconds
    decayAmount   = 1.0,    -- percent removed each time

    -- ═══════════ STRESS GAIN ═══════════
    -- DRIVING FAST gives NO stress. It only rises when you CRASH.
    gain = {
        -- Vehicle crash. Measured by the body damage taken.
        crash = {
            enabled   = true,
            minDamage = 40,    -- minimum damage in a single crash (out of 1000)
            perDamage = 0.02,  -- stress added per unit of damage
            maxPerHit = 6.0,   -- cap per single crash
            cooldown  = 3,     -- seconds
        },

        -- Falling / losing balance. ls_core/antipunchspam knocks the player
        -- down when they spam punches - we listen to that event. It also
        -- triggers on any other ragdoll (falling from height, being thrown
        -- off a motorcycle).
        ragdoll = {
            enabled  = true,
            amount   = 1.5,
            cooldown = 10,     -- seconds
        },

        -- Minor injury - every time health drops. For small damage that
        -- is NOT a fall: being punched, shot, etc.
        injury = {
            enabled   = true,
            minDrop   = 5,     -- minimum health lost in one go
            perHp     = 0.25,  -- stress added per health point lost
            maxPerHit = 8.0,
        },

        -- Downed / bleeding out - OFFICIAL p_ambulancejob hook
        --   server: RegisterNetEvent('p_ambulancejob/onDeathStateChange')
        --   deathType: 'death' | 'bleeding' | 'recovering' | 'none'
        -- Separate from minor injury and much larger.
        downed = {
            enabled  = true,
            bleeding = 12.0,   -- when going down and starting to bleed
            death    = 20.0,   -- on death

            -- Continuous gain while lying down bleeding.
            -- Tracked via the LocalPlayer.state.deathType statebag.
            whileBleeding = {
                enabled  = true,
                amount   = 1.0,
                interval = 15,   -- seconds
            },
        },
    },

    -- ═══════════ STRESS RELIEF ═══════════
    relief = {
        -- Fast driving - "wind in your hair". Relieves slowly while holding
        -- a steady high speed. (Stopping / slow driving does not relieve.)
        fastDriving = {
            enabled  = true,
            minSpeed = 80,     -- km/h - must be faster than this
            amount   = 0.6,
            interval = 20,     -- seconds
        },

        -- GYM - connected via the onRep hook in
        --       prompt_anim_core_2_new's hooks/hooks_server.lua. Per exercise
        --       repetition. (The amount is changed there.)

        -- FOOD / ALCOHOL - qbx_consumables itself reduces stress (it has a
        --       stressRelief field in its config.lua) and writes the value to
        --       the statebag. Toxic HUD follows it directly - no extra code.

        -- CIGARETTES / VAPE - see Config.Smoking below.
    },

    max = 100.0,
}

-- ============================================================
--  CIGARETTES / VAPE - stress relief
--  Animations, props, item names and images are taken from lusty94_smoking.
--  The logic is rewritten on top of ox_inventory + ox_lib (the original
--  was built for qb-core/qb-inventory).
--
--  Items are registered in ox_inventory/data/items.lua and the images
--  are copied to ox_inventory/web/images.
-- ============================================================
Config.Smoking = {
    enabled = true,

    -- Item name of the single cigarette that opening a pack gives
    cigItem = 'cigs',

    items = {
        -- ---- Packs: opening gives cigs, no effect on stress ----
        ['redwoodpack'] = {
            label = 'Opening Redwood pack',
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
            label = 'Opening Debonaire pack',
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
            label = 'Opening Yukon pack',
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
            label = 'Opening 69 Brand pack',
            duration = 6,
            returns = { item = 'cigs', amount = 20 },
            dict = 'amb@prop_human_parking_meter@female@base',
            anim = 'base_female',
            prop = 'p_cigar_pack_02_s',
            bone = 57005,
            pos  = vec3(0.14, 0.01, -0.03),
            rot  = vec3(2.0, 68.0, -32.0),
        },

        -- ---- Smokables: reduce stress ----
        ['cigs'] = {
            label = 'Smoking a cigarette',
            duration = 30,
            requires = { item = 'lighter', label = 'Lighter' },  -- not consumed
            stress = 25.0,     -- percent of stress removed
            armour = 0,        -- was 10 in lusty94; adding armour makes no sense for a HUD
            health = 2,        -- health lost per cigarette (0 = none)
            -- Emote: ["smoke"] = { "scenario", "WORLD_HUMAN_SMOKING", "Smoke" }
            scenario = 'WORLD_HUMAN_SMOKING',

            -- The scenario's own smoke does not always render, so we add our
            -- own particles + ember glow on the ped's hand / head.
            --   exhale -> puff from the mouth (ptfx asset 'core')
            --   ember  -> the cigarette tip glows red while drawing
            --   handBone / headBone -> ped bones the effects are attached to
            fx = {
                exhale   = 'exp_grd_bzgas_smoke',
                scale    = 0.12,
                ember    = true,
                handBone = 28422,   -- SKEL_R_Hand
                headBone = 31086,   -- SKEL_Head
            },
        },
        ['vape'] = {
            label = 'Vaping',
            duration = 20,
            requires = { item = 'vapejuice', label = 'Vape juice' },
            consumesRequired = 0.25,   -- 25% chance to consume a juice
            keepItem = true,           -- the vape itself is not consumed
            stress = 25.0,
            armour = 0,
            health = 0,
            fx = {
                exhale = 'exp_grd_bzgas_smoke',
                scale  = 0.25,                        -- vape clouds are thicker
                ember  = false,
                led    = true,                        -- blue vape LED glow
            },
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
--  Minimap (radar) position
--     'bottom-left' - GTA default (bottom left). The radar is untouched.
--     'top-right'   - top-right corner.
--
--  When the position changes, the rest of the HUD follows AUTOMATICALLY:
--    * The status frame (4 bars around the minimap) moves to that corner
--    * The status circle cluster moves to the opposite side of the minimap
--
--  The shift distance is calculated AUTOMATICALLY from resolution / aspect
--  ratio / safezone. The game's three components (image / mask / blur) are
--  moved by the same distance, so the mask never separates from the image
--  and the compass never separates from the map.
--
--  LIMITATIONS (the game's own, parts that do not follow the move):
--    * "Bigmap" (Z key) still opens at the bottom left
--    * The native health / armour arc position will be off - but
--      HideNativeHealthArmour above hides them, so it has no effect
-- ============================================================
Config.MinimapPosition = 'top-right'

-- Correction ADDED on top of the automatic calculation (screen fraction,
-- 0.0 = no correction).
--     positive x = right, positive y = up
-- Usually not needed. If another resource modifies the minimap (square
-- minimap, expanded map etc.) it can be off by 2-3 thousandths.
-- Nudge it in game with /mmpos <dx> <dy> and put the resulting value here.
Config.MinimapNudge = { x = 0.0, y = 0.0 }

-- Whether players may place the minimap WHEREVER they want.
-- If true, in /toxichud -> "Edit layout" mode a box representing the
-- minimap rectangle appears; dragging it moves the real radar to that
-- position. The choice is saved along with the other HUD elements and
-- restored on reconnect.
--
-- Config.MinimapPosition above is only the DEFAULT position - if the
-- player has dragged it, their choice takes priority. The menu's Reset
-- button also returns the minimap to the game's default position.
Config.AllowPlayerMinimapMove = true

-- ============================================================
--  CINEMATIC MODE - players temporarily hide the HUD
--  For screenshots / video recording. Players can rebind the key in
--  FiveM's Settings > Key Bindings > FiveM.
--  Via chat: /cinematic
-- ============================================================
Config.Cinematic = {
    Key        = 'F9',   -- default key (players can change it)
    HideRadar  = true,   -- also hide the minimap
    Bars       = false,  -- cinematic black bars (top / bottom)
    BarHeight  = 0.11,   -- height of each bar, as a screen fraction
}

return Config
