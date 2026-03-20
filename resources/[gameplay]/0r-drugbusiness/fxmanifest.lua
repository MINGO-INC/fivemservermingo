fx_version 'cerulean'
lua54 'yes'
game 'gta5'
name '0r-drugbusiness'
author '0resmon | aliko.'
version '1.0.2'
description 'Drug business | aliko.'

shared_scripts {
	'@ox_lib/init.lua',
	'config.lua',
	'shared/init.lua',
}

files {
	'data/**/*',
	'locales/*.json',
	'modules/**/client.lua',
	'modules/bridge/**/client.lua',
	'ui/build/index.html',
	'ui/build/**/*',
}

client_scripts {
	'escrow/**/client.lua',
	'client.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'escrow/**/server.lua',
	'main.js' -- don't delete it
	'server.lua'
}

ui_page 'ui/build/index.html'

dependencies { 'ox_lib', 'oxmysql' }