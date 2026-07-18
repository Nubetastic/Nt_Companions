fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'A simple dog companion script'
derivedFrom 'tbrp-companions'
version '1.0.2'

shared_scripts {
    '@ox_lib/init.lua',
    '@rsg-core/shared/locale.lua',
    'locales/en.lua',
    'shared/*.lua'
}

client_scripts {
    'client/client.lua',
    'client/npcs.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
    'server/versionchecker.lua'
}

dependencies {
    'rsg-core',
    'rsg-inventory',
    'ox_lib'
}

lua54 'yes'
