fx_version 'cerulean'
game 'gta5'

name 'LS HUD'
author 'LS'
description 'LS HUD — status / vehicle HUD, minimap байрлал, cinematic mode, stress систем + тамхи-вэйп'
version '2.3.0'

lua54 'yes'

shared_script '@ox_lib/init.lua'

client_scripts {
    'config.lua',
    'client.lua',
    'client/stress.lua',    -- stress-ийн эх үүсвэрүүд (ЖОЛООДЛОГО ОРООГҮЙ)
    'client/smoking.lua',   -- тамхи / вэйп — анимаци + prop
}

server_scripts {
    'server/stress.lua',    -- stress хадгалалт / өөрчлөлт / байгалийн бууралт
    'server/smoking.lua',   -- ox_inventory item зарцуулалт
}

ui_page 'html/index.html'

files {
    'bridge.lua',   -- client.lua дотор require 'bridge'-ээр ачаалагдана
    'config.lua',   -- server талаас ч require 'config'-оор уншигдана
    'html/index.html',
    'html/style.css',
    'html/skin.css',
    'html/script.js',
}

-- Зөвхөн ox_lib шаардлагатай. Framework (qbx_core / qb-core / es_extended)
-- нь автомат илрэх тул заавал биш — standalone горимд ч ажиллана.
dependency 'ox_lib'
