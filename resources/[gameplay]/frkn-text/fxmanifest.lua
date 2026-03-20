fx_version 'bodacious'

version '0.0.0'

games { 'gta5' }


ui_page 'html/index.html'
files {
  'html/index.html',
  'html/script.js',
  'html/style.css',
  'html/*ttf',
  'images/*.png',
  'images/*.jpg',
  'fonts/*.ttf',
}

client_scripts{
    'client/client.lua',
    'config.lua'
}

escrow_ignore {
  'config.lua',
  'client/client.lua',
}

lua54 "yes"

dependency '/assetpacks'