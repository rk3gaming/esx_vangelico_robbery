fx_version 'cerulean'

game 'gta5'

author 'LSC Development'
description 'Vangelico Robbery Remastered'
version '1.0.0'

-- Redid the fxmanifest.lua.

client_scripts {
	'client/*.lua',
}

server_scripts {
	'server/*.lua'
}

shared_scripts {
	'@es_extended/imports.lua', -- Use imports instead of the shitty old getsharedobject.
	'@es_extended/locale.lua', 
	'@ox_lib/init.lua', -- Use ox_lib as its more modern.
	'locales/*.lua',
	'shared/*.lua',
	'config.lua'
}

dependencies {
	'es_extended',
	'ox_lib', -- New dependency.
}

lua54 'true' 
