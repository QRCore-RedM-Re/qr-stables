fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

description 'qr-stables'
version '1.0.0'

shared_scripts { '@ox_lib/init.lua', 'shared/config.lua', }
client_script 'client/main.lua'
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }

dependencies { 'qr-core' }