fx_version 'cerulean'
use_fxv2_oal 'yes'
game 'gta5'
lua54 'yes'

name 'JLRP-Reports'
author 'Mahan Moulaei'
discord 'Mahan#8183'
description 'JolbakLifeRP Report System'

version '0.0'

ui_page 'web/ui.html'

files {
	'web/*.*',
}

shared_scripts {
	'@JLRP-Framework/imports.lua',
	'config.lua'
}

client_scripts {
	'client.lua',
}

server_scripts {
	'server.lua',
}

