script_version('18.10.2023')

local dlstatus = require('moonloader').download_status
local encoding = require('encoding')
encoding.default = 'CP1251'
u8 = encoding.UTF8

local bool = false
local servers = {
    ['185.169.134.163'] = '#neskvik', -->> Центральный Округ
    ['185.169.134.60'] = '', -->> Южный Округ
    ['185.169.134.62'] = '', -->> Северный Округ
    ['185.169.134.108'] = '', -->> Восточный Округ
    ['80.66.71.85'] = '#ютуб', -->> Западный округ
}

function main()
    while not isSampAvailable() do wait(0) end
    sampAddChatMessage('verison: ' .. thisScript().version, -1)
    autoupdate('https://raw.githubusercontent.com/Xkelling/autoPromo/main/version')
    while not sampIsLocalPlayerSpawned() do wait(100) end
    if sampGetPlayerScore(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) >= 6 and #servers[select(1, sampGetCurrentServerAddress())] > 0 then
        bool = true
        sampSendChat('/mm')
    end
    wait(-1)
end

function autoupdate(json_url)
  local dlstatus = require('moonloader').download_status
  local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'
  if doesFileExist(json) then os.remove(json) end
  downloadUrlToFile(json_url, json,
    function(id, status, p1, p2)
      if status == dlstatus.STATUSEX_ENDDOWNLOAD then
        if doesFileExist(json) then
          local f = io.open(json, 'r')
          if f then
            local info = decodeJson(f:read('*a'))
            updatelink = info.updateurl
            updateversion = info.latest
            f:close()
            os.remove(json)
            if updateversion ~= thisScript().version then
              lua_thread.create(function()
                local dlstatus = require('moonloader').download_status
                -- нужно обновление
                wait(250)
                downloadUrlToFile(updatelink, thisScript().path,
                  function(id3, status1, p13, p23)
                    if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                      -- download
                    elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                      -- download ok
                      goupdatestatus = true
                      lua_thread.create(function() wait(500) thisScript():reload() end)
                    end
                    if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                      if goupdatestatus == nil then
                        -- download error
                        update = false
                      end
                    end
                  end
                )
              end)
            else
              update = false
              -- не нужно обновление
            end
          end
        else
          -- ошибка при проверке обновления
          update = false
        end
      end
    end
  )
  while update ~= false do wait(100) end
end

function sendCEF(str)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt32(bs, string.len(str))
    raknetBitStreamWriteString(bs, str)
    raknetBitStreamWriteInt8(bs, 0)
    raknetBitStreamWriteInt8(bs, 0)
    raknetBitStreamWriteInt8(bs, 0)
    raknetSendBitStreamEx(bs, 2, 9, 6)
    raknetDeleteBitStream(bs)
end

function onSendPacket(id, bs, priority, reliability, orderingChannel) 
    if id == 220 and bool then
        local id = raknetBitStreamReadInt8(bs)
        local packettype = raknetBitStreamReadInt8(bs)
        local strlen = raknetBitStreamReadInt8(bs)
        local _1 = raknetBitStreamReadInt8(bs)
        local _2 = raknetBitStreamReadInt8(bs)
        local _3 = raknetBitStreamReadInt8(bs)
        local str = raknetBitStreamReadString(bs, strlen)
        local _4 = raknetBitStreamReadInt32(bs)
        local _5 = raknetBitStreamReadInt8(bs)
        local _6 = raknetBitStreamReadInt8(bs)
        if strlen > 1 and str ~= "" and packettype ~= 0 and packettype ~= 1 and str == 'onSidebarMenuItemSelected|phone' then
            sendCEF('phone.launchApp|promo')
        end
    end
end

function onReceivePacket(id, bs) 
    if id == 220 and bool then
        raknetBitStreamIgnoreBits(bs, 8)
        if (raknetBitStreamReadInt8(bs) == 17) then
            raknetBitStreamIgnoreBits(bs, 32)
            local str = raknetBitStreamReadString(bs, raknetBitStreamReadInt32(bs))
            if str:find("vue%.showModal%(%'Dialog%'") then
                local event, js = str:match("vue%.showModal%(%'(.+)%'%, (.+)")
                local js = js:gsub("%{......%}", "")
                local js = js:gsub("\n", "")
                local id, type, title, text, btn1, btn2, mode = js:match("%{id%:(%d+)%,type%:(%d+)%,header%:%'(.+)%'%,body%:%`(.+)%`%,primaryButton%:%'(.+)%'%,secondaryButton%:%'(.+)%'%,mode%:(%d+)")
                if text:find('Промо%-код: Не использованУправление собственным промо%-кодом') then
                    sendCEF('@0, sendResponse, ' .. id .. ', 0, 1, ')
                end

                if text:find('Введите промо%-код пригласившего вас человека!') then
                    sendCEF('@0, sendResponse, ' .. id .. ', 0, 1, ' .. u8(servers[select(1, sampGetCurrentServerAddress())]))
                end

                if text:find('Вы действительно хотите использовать промо%-код') then
                    sendCEF('@0, sendResponse, ' .. id .. ', 0, 1, ')
                    bool = false
                end
            end
        end
    end
end