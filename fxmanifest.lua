fx_version 'cerulean'
game 'gta5'

name 'Toxic HUD'
author 'LS'
description 'Toxic HUD - status / vehicle HUD, minimap position, cinematic mode, stress system + cigarettes / vape'
version '2.3.0'

lua54 'yes'

shared_script '@ox_lib/init.lua'

client_scripts {
    'client.lua',
    'client/stress.lua',    -- stress sources (DRIVING IS NOT INCLUDED)
    'client/smoking.lua',   -- cigarettes / vape - animation + prop
}

server_scripts {
    'server/stress.lua',    -- stress storage / changes / natural decay
    'server/smoking.lua',   -- ox_inventory item consumption
}

ui_page 'html/index.html'

files {
    'bridge.lua',   -- loaded via require 'bridge' in client.lua
    'config.lua',   -- read via require 'config' on client / server
    'html/index.html',
    'html/style.css',
    'html/skin.css',
    'html/script.js',
}

-- Only ox_lib is required. The framework (qbx_core / qb-core / es_extended)
-- is detected automatically and is optional - it also works standalone.
dependency 'ox_lib'
