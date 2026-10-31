addon.name    = 'yunagearopt';
addon.author  = 'Yunas';
addon.version = '1.1.61';   -- the release workflow sets this to the release number (core.lua too)
addon.desc    = 'Builds every set for a job from the gear you own (augments included) and exports LegacyAC XML, LuAshitacast and GearSwap.';
addon.link    = 'https://github.com/YunasXI/yunagearopt';
-- YunaGearOpt - Copyright (C) 2026 Yunas (https://github.com/YunasXI) - GPL-3.0 with an author-credit term: see LICENSE and NOTICE

--[[
YunaGearOpt, a VanaCore addon (VanaCore\addons\vanacore\yunagearopt). This file is the entry: it gives YunaGearOpt's
main code (core.lua, written against the Ashita addon API) the few Ashita names it uses (AshitaCore, ashita.*, struct,
GetPlayerEntity) on top of vana.*: items, bags and the player come from the Ashita objects VanaCore hosts
(vana.ashita.object, called through their vtables like VanaCore's own compatibility layer does), the rest from
vana.game, vana.chat, vana.packets, vana.fs and vana.imgui. Then it loads core.lua.

In game:   /addon load yunagearopt
--]]

-- VanaCore addons only: not plain Ashita (no `vana`), not as an Ashita addon inside VanaCore (AshitaCore already there)
if rawget(_G, 'vana') == nil or rawget(_G, 'AshitaCore') ~= nil then
    print('[YunaGearOpt] YunaGearOpt runs only on VanaCore, as a VanaCore addon (VanaCore\\addons\\vanacore\\yunagearopt): /addon load yunagearopt');
    return;
end

local vana = vana
local ffi = require('ffi')

-- Where this addon's files are (core.lua, data.lua, images\ ...)
local HERE = (function ()
    local src = debug.getinfo(1, 'S').source or ''
    src = src:gsub('^@', '')
    local dir = src:match('^(.*)[\\/][^\\/]+$')
    if dir == nil or dir == '' then
        dir = vana.paths.addon .. '\\yunagearopt'
    end
    return dir
end)()

addon.path = HERE .. '\\'

-- Ashita's addon libraries (common, chat, settings, imgui, d3d8 ...), the copies VanaCore ships for Ashita addons
local LIBS = vana.paths.addons .. '\\vanacore\\libs\\'
package.path = table.concat({
    HERE .. '\\?.lua',
    LIBS .. 'ashita-4.30\\?.lua', LIBS .. 'ashita-4.30\\?\\init.lua',
    LIBS .. 'ashita\\?.lua', LIBS .. 'ashita\\?\\init.lua',
    package.path,
}, ';')

if table.unpack == nil then table.unpack = unpack end
if table.pack == nil then table.pack = function (...) return { n = select('#', ...), ... } end end

-------------------------------------------------------------------------------
-- The Ashita objects VanaCore hosts, called through their vtables (the slots of Ashita's SDK, interface 4.16)
-------------------------------------------------------------------------------
ffi.cdef[[
    typedef struct { uint16_t Id; uint16_t Index; uint32_t Count; uint32_t Flags; uint32_t Price; uint8_t Extra[28]; } ygo_item_t;
    typedef struct { uint32_t Slot; uint32_t Index; } ygo_equipentry_t;
    typedef struct { uint16_t AbilityId; int8_t Level; uint8_t Unknown0000; } ygo_IMonAbility;
    typedef struct {
        uint32_t Id; uint16_t Flags; uint16_t StackSize; uint16_t Type; uint16_t ResourceId; uint16_t Targets;
        uint16_t Level; uint16_t Slots; uint16_t Races; uint32_t Jobs; uint16_t SuperiorLevel; uint16_t ShieldSize;
        uint8_t MaxCharges; uint16_t CastTime; uint16_t CastDelay; uint32_t RecastDelay; uint16_t BaseItemId;
        uint16_t ItemLevel; uint16_t Damage; uint16_t Delay; uint16_t DPS; uint8_t Skill; uint8_t JugSize;
        uint32_t WeaponUnknown0000; uint8_t Range; uint8_t AreaRange; uint8_t AreaShapeType; uint8_t AreaCursorTargetType;
        uint16_t Element; uint32_t Storage; uint32_t AttachmentFlags;
        uint16_t InstinctCost;
        uint16_t MonstrosityId; char MonstrosityName[0x20]; uint8_t MonstrosityData[0x0A];
        ygo_IMonAbility MonstrosityAbilities[0x10];
        uint16_t PuppetSlotId; uint32_t PuppetElements;
        uint8_t SlipData[0x46];
        uint16_t UsableData0000; uint32_t UsableData0001; uint32_t UsableData0002;
        uint32_t Article;
        const char* Name[3]; const char* Description[3]; const char* LogNameSingular[3]; const char* LogNamePlural[3];
        uint32_t ImageSize; uint8_t ImageType; uint8_t ImageName[0x10]; uint8_t Bitmap[0x980];
    } ygo_IItem;
    typedef struct {
        uint16_t Index; uint16_t Type; uint16_t Element; uint16_t Targets; uint16_t Skill; uint16_t ManaCost;
        uint8_t CastTime; uint8_t RecastDelay; int16_t LevelRequired[24]; uint16_t Id; uint16_t ListIconNQ;
        uint16_t ListIconHQ; uint8_t Requirements; int8_t Range; uint8_t AreaRange; uint8_t AreaShapeType;
        uint8_t CursorTargetType; uint8_t Unknown0000[3]; uint32_t AreaFlags; uint16_t Unknown0001; uint8_t Unknown0002;
        uint8_t Unknown0003; uint8_t Unknown0004[8]; uint32_t JobPointMask; uint8_t Unknown0005[3]; uint8_t EOE;
        const char* Name[3]; const char* Description[3];
    } ygo_ISpell;
]]

-- object name -> its pointer (looked up again if it wasn't there yet)
local pointers = {}
local function pointer(name)
    local p = pointers[name]
    if p == nil then
        local raw = vana.ashita.object(name)
        if raw ~= nil then
            p = ffi.cast('void*', raw)
            pointers[name] = p
        end
    end
    return p
end

-- A method of an Ashita object: its vtable slot, cast once
local function method(object, slot, signature)
    local fntype = ffi.typeof(signature)
    local cache_vt, cache_fn
    return function (...)
        local p = pointer(object)
        if p == nil then return nil end
        local vt = ffi.cast('void***', p)[0]
        if vt ~= cache_vt then
            cache_vt, cache_fn = vt, ffi.cast(fntype, vt[slot])
        end
        return cache_fn(p, ...)
    end
end

local rm_item_by_id = method('resources', 5, 'void* (__thiscall *)(void*, uint32_t)')
local rm_spell_by_name = method('resources', 4, 'void* (__thiscall *)(void*, const char*, uint32_t)')
local inv_container_item = method('inventory', 1, 'void* (__thiscall *)(void*, uint32_t, uint32_t)')
local inv_count_max = method('inventory', 3, 'uint32_t (__thiscall *)(void*, uint32_t)')
local inv_equipped = method('inventory', 11, 'void* (__thiscall *)(void*, uint32_t)')
local pl_job_level = method('player', 78, 'uint8_t (__thiscall *)(void*, uint32_t)')

-- An item as Ashita's Lua gives it: numbers as they are; Name / Description as { default, Japanese, English };
-- Bitmap as the image's bytes (a string: D3DX takes it as the pointer)
local item_mt = {
    __index = function (self, key)
        local it = rawget(self, '__s')
        if key == 'Name' or key == 'Description' then
            local list = it[key]
            local function text(i) return list[i] ~= nil and ffi.string(list[i]) or nil end
            local v = { text(0) or text(2), text(1), text(2) }
            rawset(self, key, v)
            return v
        end
        if key == 'Bitmap' then
            local v = ffi.string(it.Bitmap, math.min(tonumber(it.ImageSize) or 0, 0x980))
            rawset(self, key, v)
            return v
        end
        local ok, v = pcall(function () return it[key] end)
        if ok then return v end
        return nil
    end,
}
local items = setmetatable({}, { __mode = 'v' })
local function item_by_id(id)
    id = tonumber(id) or 0
    local cached = items[id]
    if cached ~= nil then return cached end
    local ok, p = pcall(rm_item_by_id, id)
    if not ok or p == nil then return nil end
    local s = ffi.cast('ygo_IItem*', p)
    if s == nil then return nil end
    local obj = setmetatable({ __s = s }, item_mt)
    items[id] = obj
    return obj
end

-- Cure cast times (LandSandBoat's spell list), in Ashita's units (1/4 s), if the spell data can't be read
local CURE_CAST = { ['cure'] = 8, ['cure ii'] = 9, ['cure iii'] = 10, ['cure iv'] = 10, ['cure v'] = 10, ['cure vi'] = 8 }
local function spell_by_name(name, lang)
    local ok, p = pcall(rm_spell_by_name, tostring(name or ''), tonumber(lang) or 0)
    if ok and p ~= nil then
        local s = ffi.cast('ygo_ISpell*', p)
        if s ~= nil then return { CastTime = s.CastTime, Id = s.Id, ManaCost = s.ManaCost } end
    end
    local t = CURE_CAST[tostring(name or ''):lower()]
    return t and { CastTime = t } or nil
end

-------------------------------------------------------------------------------
-- Bags, equipment, player, party
-------------------------------------------------------------------------------
local function bag_item(cid, idx)
    local ok, p = pcall(inv_container_item, tonumber(cid) or 0, tonumber(idx) or 0)
    if not ok or p == nil then return nil end
    local s = ffi.cast('ygo_item_t*', p)
    if s == nil then return nil end
    return { Id = s.Id, Index = s.Index, Count = s.Count, Flags = s.Flags, Price = s.Price, Extra = ffi.string(s.Extra, 28) }
end

local inventory = {
    GetContainerItem = function (_, cid, idx) return bag_item(cid, idx) end,
    GetContainerCountMax = function (_, cid)
        local ok, n = pcall(inv_count_max, tonumber(cid) or 0)
        return ok and tonumber(n) or 0
    end,
    GetEquippedItem = function (_, slot)
        local ok, p = pcall(inv_equipped, tonumber(slot) or 0)
        if ok and p ~= nil then
            local s = ffi.cast('ygo_equipentry_t*', p)
            if s ~= nil then return { Slot = s.Slot, Index = s.Index } end
        end
        -- (from VanaCore's own table if the object can't be read)
        local eq = vana.game.equipment()
        local e = eq and eq[tonumber(slot) or 0]
        if e then return { Slot = slot, Index = bit.bor(bit.lshift(e.container or 0, 8), e.index or 0) } end
        return nil
    end,
}

-- Job levels from the server's job info packet (0x01B), remembered, for when the player object can't say
local job_levels = {}
local function player_info() return vana.game.player() end
local player = {
    GetMainJob = function () local p = player_info(); return p and p.main_job or 0 end,
    GetSubJob = function () local p = player_info(); return p and p.sub_job or 0 end,
    GetMainJobLevel = function () local p = player_info(); return p and p.main_job_level or 0 end,
    GetSubJobLevel = function () local p = player_info(); return p and p.sub_job_level or 0 end,
    GetJobLevel = function (_, job)
        job = tonumber(job) or 0
        local ok, lv = pcall(pl_job_level, job)
        if ok and tonumber(lv) and tonumber(lv) > 0 then return tonumber(lv) end
        if job_levels[job] then return job_levels[job] end
        local p = player_info()
        if p and p.main_job == job then return p.main_job_level end
        return 0
    end,
    GetBuffs = function ()
        local p = player_info()
        local out = {}
        for i = 1, 32 do out[i] = (p and p.buffs and p.buffs[i]) or -1 end
        return out
    end,
    GetLoginStatus = function ()
        if vana.game.zoning and vana.game.zoning() then return 1 end
        return player_info() ~= nil and 2 or 0
    end,
}

local function member(i)
    local party = vana.game.party()
    return party and party.members and party.members[(tonumber(i) or 0) + 1]
end
local party = {
    GetMemberName = function (_, i) local m = member(i); return m and m.name or '' end,
    GetMemberServerId = function (_, i) local m = member(i); return m and m.id or 0 end,
    GetMemberIsActive = function (_, i) local m = member(i); return (m and m.active) and 1 or 0 end,
    GetMemberMainJob = function (_, i) local m = member(i); return m and m.main_job or 0 end,
    GetMemberMainJobLevel = function (_, i) local m = member(i); return m and m.main_job_level or 0 end,
}

-------------------------------------------------------------------------------
-- AshitaCore and the ashita namespace YunaGearOpt and Ashita's libraries use
-------------------------------------------------------------------------------
local function packet_bytes(data)
    if type(data) == 'table' then
        local b = {}
        for i = 1, #data do b[i] = string.char(bit.band(tonumber(data[i]) or 0, 0xFF)) end
        return table.concat(b)
    end
    return tostring(data)
end

AshitaCore = {
    GetInstallPath = function () return vana.paths.install .. '\\' end,
    GetGuiManager = function () return vana.imgui end,
    GetDirect3DDevice = function () return vana.ashita.object('device') end,
    GetResourceManager = function ()
        return {
            GetItemById = function (_, id) return item_by_id(id) end,
            GetSpellByName = function (_, name, lang) return spell_by_name(name, lang) end,
            GetString = function (_, t, i, lang) return vana.ashita.string(tostring(t), i, tonumber(lang) or 0) end,
        }
    end,
    GetMemoryManager = function ()
        return {
            GetInventory = function () return inventory end,
            GetPlayer = function () return player end,
            GetParty = function () return party end,
        }
    end,
    GetChatManager = function ()
        return {
            QueueCommand = function (_, mode, command)
                mode = tonumber(mode) or 1
                vana.chat.run(tostring(command), mode < 0 and 1 or mode)
            end,
            AddChatMessage = function (_, mode, _, message) vana.chat.write(tostring(message), tonumber(mode) or 1) end,
        }
    end,
    GetPacketManager = function ()
        return {
            AddOutgoingPacket = function (_, id, data) vana.packets.inject(false, id, packet_bytes(data)) end,
            AddIncomingPacket = function (_, id, data) vana.packets.inject(true, id, packet_bytes(data)) end,
        }
    end,
    GetPluginManager = function ()
        return {
            IsLoaded = function (_, name)
                local ok, list = pcall(vana.plugins.loaded)
                if not ok or type(list) ~= 'table' then return false end
                name = tostring(name):lower()
                for k, v in pairs(list) do
                    local n = type(v) == 'string' and v or (type(k) == 'string' and k) or (type(v) == 'table' and (v.name or v[1]))
                    if n and tostring(n):lower() == name then return true end
                end
                return false
            end,
        }
    end,
}

-- ashita.bits: Ashita's UnpackBitsBE / PackBitsBE (bits from each byte's lowest, as FFXI packs its packets)
local function byte_access(data)
    local kind = type(data)
    if kind == 'string' then
        return function (i) return data:byte(i + 1) or 0 end, nil
    elseif kind == 'table' then
        return function (i) return tonumber(data[i + 1]) or 0 end, function (i, v) data[i + 1] = v end
    end
    local p = ffi.cast('uint8_t*', data)
    return function (i) return p[i] end, function (i, v) p[i] = v end
end
local function unpack_be(data, byte_offset, bit_offset, bits)
    if bits == nil then byte_offset, bit_offset, bits = 0, byte_offset, bit_offset end
    local read = byte_access(data)
    local pos = (tonumber(byte_offset) or 0) * 8 + (tonumber(bit_offset) or 0)
    bits = tonumber(bits) or 0
    local value, scale = 0, 1
    while bits > 0 do
        local shift = pos % 8
        local take = math.min(8 - shift, bits)
        value = value + (math.floor(read(math.floor(pos / 8)) / 2 ^ shift) % 2 ^ take) * scale
        scale, pos, bits = scale * 2 ^ take, pos + take, bits - take
    end
    return value
end
local function pack_be(data, value, byte_offset, bit_offset, bits)
    if bits == nil then byte_offset, bit_offset, bits = 0, byte_offset, bit_offset end
    local read, write = byte_access(data)
    if write == nil then error('ashita.bits.pack_be: a string can\'t be written', 2) end
    local pos = (tonumber(byte_offset) or 0) * 8 + (tonumber(bit_offset) or 0)
    bits = tonumber(bits) or 0
    value = math.floor(tonumber(value) or 0) % 2 ^ bits
    while bits > 0 do
        local index, shift = math.floor(pos / 8), pos % 8
        local take = math.min(8 - shift, bits)
        local part = value % 2 ^ take
        value = math.floor(value / 2 ^ take)
        local byte = read(index)
        write(index, byte + (part - math.floor(byte / 2 ^ shift) % 2 ^ take) * 2 ^ shift)
        pos, bits = pos + take, bits - take
    end
    return pos
end

local EVENT_NAMES = { d3d_present = 'present' }
ashita = {
    events = {
        register = function (name, key, fn)
            name = tostring(name):lower()
            vana.events.on(EVENT_NAMES[name] or name, fn, key)
        end,
        unregister = function (name, key)
            name = tostring(name):lower()
            vana.events.off(EVENT_NAMES[name] or name, key)
        end,
    },
    bits = { unpack_be = unpack_be, pack_be = pack_be },
    misc = { open_url = vana.system.open_url },
    fs = {
        exists = function (p) return vana.fs.exists(p) == true end,
        create_dir = function (p) return vana.fs.create_dir(p) end,
        create_directory = function (p) return vana.fs.create_dir(p) end,
    },
}

-- Ashita's `struct` library: the few formats Ashita's settings library reads (the zone-in packet)
struct = struct or {
    unpack = function (fmt, data, pos)
        pos = tonumber(pos) or 1
        local out = {}
        for code, n in fmt:gmatch('([%a])(%d*)') do
            n = tonumber(n)
            if code == 'c' then
                out[#out + 1] = data:sub(pos, pos + (n or 1) - 1); pos = pos + (n or 1)
            elseif code == 'L' or code == 'I' or code == 'l' or code == 'i' then
                local b1, b2, b3, b4 = data:byte(pos, pos + 3)
                local v = (b1 or 0) + (b2 or 0) * 256 + (b3 or 0) * 65536 + (b4 or 0) * 16777216
                if (code == 'l' or code == 'i') and v >= 2147483648 then v = v - 4294967296 end
                out[#out + 1] = v; pos = pos + 4
            elseif code == 'H' or code == 'h' then
                local b1, b2 = data:byte(pos, pos + 1)
                local v = (b1 or 0) + (b2 or 0) * 256
                if code == 'h' and v >= 32768 then v = v - 65536 end
                out[#out + 1] = v; pos = pos + 2
            elseif code == 'B' or code == 'b' then
                local v = data:byte(pos) or 0
                if code == 'b' and v >= 128 then v = v - 256 end
                out[#out + 1] = v; pos = pos + 1
            end
        end
        out[#out + 1] = pos
        return unpack(out)
    end,
}

-- The player's entity, as Ashita's settings library reads it (name and server id)
function GetPlayerEntity()
    local m = member(0)
    if m == nil or (m.id or 0) == 0 then return nil end
    return { Name = m.name, ServerId = m.id }
end

-- Every job's level, from the server's job info packet (byte 0x48 + job)
vana.events.on('packet_in', function (e)
    if e.id == 0x01B and type(e.data) == 'string' then
        for job = 1, 22 do
            local lv = e.data:byte(0x48 + job + 1)
            if lv and lv > 0 then job_levels[job] = lv end
        end
    end
end, 'ygo_native_joblevels')

-------------------------------------------------------------------------------
-- YunaGearOpt itself
-------------------------------------------------------------------------------
YGO_NATIVE = true   -- core.lua runs only when loaded through this file (VanaCore only)
local chunk, err = loadfile(HERE .. '\\core.lua')
if chunk == nil then
    print('YunaGearOpt (VanaCore): core.lua could not be read: ' .. tostring(err))
    return
end
chunk()
