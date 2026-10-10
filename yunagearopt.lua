addon.name    = 'yunagearopt';
addon.author  = 'Yunas';
addon.version = '1.1.7';   -- the release workflow sets this to the release number
addon.desc    = 'Builds every set for a job from the gear you own (augments included) and exports LegacyAC XML, LuAshitacast and GearSwap.';
addon.link    = '';

require('common');
local imgui    = require('imgui');

-- ImGui reads plain text as a printf format, so a '%' (e.g. "Haste%", "45%") turns into garbage.
-- Escape it once here for every Text call in this addon (tooltips are escaped where they're built).
do
    local raw_text, raw_colored, raw_disabled = imgui.Text, imgui.TextColored, imgui.TextDisabled;
    local function esc(t) return (tostring(t):gsub('%%', '%%%%')); end
    imgui.Text = function(t, ...) return raw_text(esc(t), ...); end
    imgui.TextColored = function(c, t, ...) return raw_colored(c, esc(t), ...); end
    if raw_disabled then imgui.TextDisabled = function(t, ...) return raw_disabled(esc(t), ...); end end
    -- Tooltips 15% smaller so long ones fit on screen (text arrives already %-escaped)
    local raw_tooltip = imgui.SetTooltip;
    if imgui.BeginTooltip and imgui.EndTooltip and imgui.SetWindowFontScale then
        imgui.SetTooltip = function(t)
            local opened = imgui.BeginTooltip();
            if opened == false then return; end
            imgui.SetWindowFontScale(0.85);
            raw_text(tostring(t));
            imgui.EndTooltip();
        end
    else
        imgui.SetTooltip = raw_tooltip;
    end
end
local chat     = require('chat');
local settings = require('settings');
local ffi      = require('ffi');
local d3d      = require('d3d8');

-- Item icons straight from the game files, loaded once per item id (false = no icon)
local icons = {};
local function item_icon(id)
    if id == nil or id == 0 or id == 65535 then return nil; end
    if icons[id] ~= nil then return icons[id] or nil; end
    icons[id] = false;
    pcall(function()
        local item = AshitaCore:GetResourceManager():GetItemById(id);
        if item == nil or item.Bitmap == nil or (item.ImageSize or 0) == 0 then return; end
        local ptr = ffi.new('IDirect3DTexture8*[1]');
        if ffi.C.D3DXCreateTextureFromFileInMemoryEx(d3d.get_device(), item.Bitmap, item.ImageSize, 0xFFFFFFFF, 0xFFFFFFFF, 1, 0,
                ffi.C.D3DFMT_A8R8G8B8, ffi.C.D3DPOOL_MANAGED, ffi.C.D3DX_DEFAULT, ffi.C.D3DX_DEFAULT, 0xFF000000, nil, nil, ptr) == ffi.C.S_OK then
            local tex = d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', ptr[0]));
            icons[id] = { tex = tex, ptr = tonumber(ffi.cast('uint32_t', tex)) };
        end
    end);
    return icons[id] or nil;
end

-- CatsEyeXI logo for the header, loaded once from images\catseye.png (false = missing)
local logo = nil;
local function logo_texture()
    if logo ~= nil then return logo or nil; end
    logo = false;
    pcall(function()
        local f = io.open(addon.path .. '/images/catseye.png', 'rb');
        if f == nil then return; end
        local data = f:read('*a');
        f:close();
        local ptr = ffi.new('IDirect3DTexture8*[1]');
        if ffi.C.D3DXCreateTextureFromFileInMemoryEx(d3d.get_device(), data, #data, 0xFFFFFFFF, 0xFFFFFFFF, 1, 0,
                ffi.C.D3DFMT_A8R8G8B8, ffi.C.D3DPOOL_MANAGED, ffi.C.D3DX_DEFAULT, ffi.C.D3DX_DEFAULT, 0, nil, nil, ptr) == ffi.C.S_OK then
            local tex = d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', ptr[0]));
            logo = { tex = tex, ptr = tonumber(ffi.cast('uint32_t', tex)) };
        end
    end);
    return logo or nil;
end

----------------------------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------------------------
local JOBS = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG',
               'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN' };

local CONTAINERS = {
    [0] = 'Inventory', [1] = 'Mog Safe', [2] = 'Storage', [4] = 'Mog Locker', [5] = 'Mog Satchel',
    [6] = 'Mog Sack', [7] = 'Mog Case', [8] = 'Wardrobe', [9] = 'Mog Safe 2', [10] = 'Wardrobe 2',
    [11] = 'Wardrobe 3', [12] = 'Wardrobe 4', [13] = 'Wardrobe 5', [14] = 'Wardrobe 6',
    [15] = 'Wardrobe 7', [16] = 'Wardrobe 8',
};
-- Bags LegacyAC can equip from
local EQUIP_BAGS = { Inventory = true, Wardrobe = true, ['Wardrobe 2'] = true, ['Wardrobe 3'] = true, ['Wardrobe 4'] = true,
                     ['Wardrobe 5'] = true, ['Wardrobe 6'] = true, ['Wardrobe 7'] = true, ['Wardrobe 8'] = true };

-- All slots, in LegacyAC order. tag = XML tag name from the LegacyAC "XML Structure" doc.
local SLOTS = {
    { key = 'main',  label = 'Main',   mask = 0x0001, tag = 'main',  weapon = true },
    { key = 'sub',   label = 'Sub',    mask = 0x0002, tag = 'sub',   weapon = true },
    { key = 'range', label = 'Range',  mask = 0x0004, tag = 'range', ranged = true },
    { key = 'ammo',  label = 'Ammo',   mask = 0x0008, tag = 'ammo' },
    { key = 'head',  label = 'Head',   mask = 0x0010, tag = 'head' },
    { key = 'neck',  label = 'Neck',   mask = 0x0200, tag = 'neck' },
    { key = 'ear1',  label = 'Ear 1',  mask = 0x1800, tag = 'lear' },
    { key = 'ear2',  label = 'Ear 2',  mask = 0x1800, tag = 'rear' },
    { key = 'body',  label = 'Body',   mask = 0x0020, tag = 'body' },
    { key = 'hands', label = 'Hands',  mask = 0x0040, tag = 'hands' },
    { key = 'ring1', label = 'Ring 1', mask = 0x6000, tag = 'lring' },
    { key = 'ring2', label = 'Ring 2', mask = 0x6000, tag = 'rring' },
    { key = 'back',  label = 'Back',   mask = 0x8000, tag = 'back' },
    { key = 'waist', label = 'Waist',  mask = 0x0400, tag = 'waist' },
    { key = 'legs',  label = 'Legs',   mask = 0x0080, tag = 'legs' },
    { key = 'feet',  label = 'Feet',   mask = 0x0100, tag = 'feet' },
};

-- Game equipment slot ids (GetEquippedItem, lockstyle packet)
local EQUIP_ID = { main = 0, sub = 1, range = 2, ammo = 3, head = 4, body = 5, hands = 6, legs = 7, feet = 8,
                   neck = 9, waist = 10, ear1 = 11, ear2 = 12, ring1 = 13, ring2 = 14, back = 15 };
-- Lockstyle helpers (one table: the main chunk can only hold 200 local names).
-- slots = the ones that show on your character, the only ones a lockstyle uses.
local look = { job = nil, checked = 0,
               slots = { main = true, sub = true, range = true, head = true, body = true, hands = true, legs = true, feet = true } };
-- Button actions defined further down (same 200-name limit)
local actions = {};

-- Saved picks come back from the settings file as Ashita T{} tables, whose built-in functions answer for
-- missing keys: picks.range (no Range pick) returned table.range, a function, and crashed the addon.
-- Strip that down to plain tables, all the way in (job|set -> slot -> { name, where }).
function actions.plain(t)
    if type(t) ~= 'table' then return t; end
    setmetatable(t, nil);
    for _, v in pairs(t) do actions.plain(v); end
    return t;
end

-- Weapon skills (FFXI skill ids)
local TWO_HANDED = { [4] = true, [6] = true, [7] = true, [8] = true, [10] = true, [12] = true };
local SKILL_H2H, INSTRUMENTS = 1, { [41] = true, [42] = true };
local SKILL_NAMES = { [1] = 'Hand-to-Hand', [2] = 'Dagger', [3] = 'Sword', [4] = 'Great Sword', [5] = 'Axe', [6] = 'Great Axe',
    [7] = 'Scythe', [8] = 'Polearm', [9] = 'Katana', [10] = 'Great Katana', [11] = 'Club', [12] = 'Staff',
    [25] = 'Archery', [26] = 'Marksmanship', [27] = 'Throwing' };
local SKILL_ORDER = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 25, 26, 27 };
local SKILL_IDS = { Archery = 25, Marksmanship = 26, Throwing = 27 };

local STOP_WORDS = {
    'latent effect', 'set:', 'unity ranking', 'pet:', 'avatar:', 'automaton:', 'wyvern:', 'luopan:',
    'night:', 'daytime:', 'dynamis', 'aftermath', 'occasionally', 'additional effect', 'enchantment',
    'weather:', 'campaign', 'besieged', 'assault:', 'salvage', 'abyssea:', 'reives:',
    'when ', 'during ', 'vs. ', 'in areas outside',
    -- Zone-only effects
    'lumoria', 'al\'taieu', 'temenos', 'apollyon', 'limbus', 'nyzul', 'einherjar', 'voidwatch',
    'walk of echoes', 'sortie', 'odyssey', 'escha', 'reisenjima', 'ambuscade',
};

local DW_MODES = { 'AUTO', 'ON', 'OFF' };

-- Minimal theme: near-black neutrals, white hairlines, and gold only where it matters (title, selection, exports, BiS)
local C = {
    bg       = { 0.052, 0.055, 0.064, 0.97 },
    side     = { 0.066, 0.070, 0.082, 1.00 },
    card     = { 0.082, 0.087, 0.101, 1.00 },
    frame    = { 0.110, 0.116, 0.134, 1.00 },
    frame_hi = { 0.150, 0.157, 0.180, 1.00 },
    border   = { 1.000, 1.000, 1.000, 0.06 },
    line     = { 1.000, 1.000, 1.000, 0.07 },
    gold     = { 0.940, 0.770, 0.420, 1.00 },
    gold_dim = { 0.940, 0.770, 0.420, 0.62 },
    gold_bg  = { 0.940, 0.770, 0.420, 0.92 },
    text     = { 0.910, 0.918, 0.935, 1.00 },
    muted    = { 0.500, 0.528, 0.590, 1.00 },
    aug      = { 0.720, 0.560, 1.000, 1.00 },
    green    = { 0.450, 0.900, 0.600, 1.00 },
    red      = { 1.000, 0.450, 0.450, 1.00 },
    dark     = { 0.060, 0.060, 0.070, 1.00 },
};

----------------------------------------------------------------------------------------------------
-- State
----------------------------------------------------------------------------------------------------
local defaults = T{ ignore_level = false, dw_mode = 1, weapons = true, compact = false, hide_notice = false, xml_phalanx = '', excluded = T{},
                    picks = T{},     -- your slot picks per 'JOB|set', kept between sessions
                    set_removed = T{}, set_added = T{},   -- sets you took out of / put into a job: JOB -> { set id, ... }
                    weapon_mode = 1 };   -- 1 = weapons swap, but the dual-wield pair (or nothing) with /NIN or /DNC
local s = settings.load(defaults);
s.picks = actions.plain(s.picks or {});
s.set_removed = actions.plain(s.set_removed or {});
s.set_added = actions.plain(s.set_added or {});

-- Weapons are always swapped, except while subbing NIN or DNC: then the job's dual-wield pair (picked in the
-- "/NIN and /DNC weapons" row) goes on instead, or the weapons are left alone if none is picked.
-- (weapon_mode 1 = this behaviour; the old AUTO / ON / OFF choice and "Swap weapons" checkbox are gone.)
function actions.fix_weapon_mode()
    s.weapon_mode, s.weapons = 1, true;
end
actions.fix_weapon_mode();

local S, data, AUG = nil, nil, {};
local BIS_REF = {};   -- bis.lua: curated Best in Slot sets per job
local SERVER = {};    -- server_stats.lua: real base stats per item id from the CatsEyeXI server

-- Crafting / gathering gear (Weaver's / Tanner's cuffs, smocks, aprons, synergy gear...) never belongs in a combat set.
-- Names need the possessive ("Miner's") so real gear such as Minerva's Ring is never caught by mistake.
local CRAFT_NAMES = { "^weaver's", "^tanner's", "^boneworker's", "^smithy's", "^goldsmith's", "^alchemist's", "^carpenter's",
                      "^culinarian's", "^chef's", "^fisherman's", "^angler's", "^digger's", "^miner's", "^craftsman's", "^artisan's" };
local CRAFT_WORDS = { 'craft', 'woodworking', 'smithing', 'alchemy', 'cooking', 'fishing', 'synthesis', 'synergy', 'digging' };
local function is_craft_gear(name, desc)
    local n = (name or ''):lower();
    for _, pat in ipairs(CRAFT_NAMES) do if n:find(pat) then return true; end end
    if n:find('smock', 1, true) or n:find('apron', 1, true) or n:find('synergy', 1, true) then return true; end
    local text = ((desc or '') .. ' ' .. n):lower();
    for _, w in ipairs(CRAFT_WORDS) do if text:find(w, 1, true) then return true; end end
    return false;
end
local owned, base_cache = {}, {};

local ui = {
    open = { false }, job = 1, set_idx = 1, sets = {}, desc = nil,
    result = nil, total = 0, full = {}, ctx = '',
    pins = s.picks, show_bis = false, dirty = true, last_scan = '--:--', augmented = 0,
    data_excl = {}, overrides = {}, job_restrict = {}, set_restrict = {}, stat_remove = {}, stat_fix = {},
};

----------------------------------------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------------------------------------
local function msg(text)
    print(chat.header(addon.name):append(chat.message(text)));
end

local function base_path()
    return (addon.path:gsub('[\\/]+$', '')) .. '\\';
end

local function fmt_num(v)
    if math.abs(v - math.floor(v + 0.5)) < 0.05 then return string.format('%+d', math.floor(v + 0.5)); end
    return string.format('%+.1f', v);
end

local function label_of(k) return (S and S.LABELS[k]) or k; end

local function in_list(list, value)
    for _, v in ipairs(list or {}) do if v == value then return true; end end
    return false;
end

-- Body pieces that also take up other slots (data.lua: covers). Matched without punctuation, so
-- "Rambler's Cloak" and "Ramblers Cloak" are the same piece.
local function cover_key(n)
    return ((n or ''):lower():gsub('[^%w%+]', ''));
end

-- Slots a set leaves covered (Kupo Suit -> legs). The exports write them as 'displaced' / empty so the
-- profile never equips something there, which would knock the suit off and start a swap loop.
local function covered_slots(assign)
    local out = {};
    for _, c in pairs(assign or {}) do
        for _, slot in ipairs((ui.covers or {})[cover_key(c.item.name)] or {}) do out[slot] = true; end
    end
    return out;
end

local function load_data()
    local okS, st = pcall(dofile, base_path() .. 'stats.lua');
    if not okS or type(st) ~= 'table' then msg('Could not load stats.lua: ' .. tostring(st)); return false; end
    local ok, d = pcall(dofile, base_path() .. 'data.lua');
    if not ok or type(d) ~= 'table' then msg('Could not load data.lua: ' .. tostring(d)); return false; end
    local ok2, a = pcall(dofile, base_path() .. 'augments.lua');
    if not ok2 or type(a) ~= 'table' then msg('Could not load augments.lua: ' .. tostring(a)); return false; end
    S, data, AUG = st, d, a;
    local okB, b = pcall(dofile, base_path() .. 'bis.lua');
    BIS_REF = (okB and type(b) == 'table') and b or {};
    local okV, v = pcall(dofile, base_path() .. 'server_stats.lua');
    SERVER = (okV and type(v) == 'table') and v or {};
    for _, sets in pairs(BIS_REF) do                       -- crafting gear is never a BiS piece
        for _, slots in pairs(sets) do
            for slot, v in pairs(slots) do
                local names = type(v) == 'table' and v or { v };
                for _, n in ipairs(names) do
                    if is_craft_gear(n, '') then slots[slot] = nil; break; end
                end
            end
        end
    end
    ui.data_excl, ui.overrides = {}, {};
    for _, name in ipairs(d.exclude or {}) do ui.data_excl[name:lower()] = true; end
    for name, stats in pairs(d.overrides or {}) do ui.overrides[name:lower()] = stats; end
    ui.job_restrict, ui.set_restrict = {}, {};
    for name, jobs in pairs(d.job_restrict or {}) do ui.job_restrict[name:lower()] = jobs; end
    -- Adept pieces count only for the job whose augment they carry
    for name, a in pairs(d.adept_augments or {}) do
        if a.job and ui.job_restrict[name:lower()] == nil then ui.job_restrict[name:lower()] = { a.job }; end
    end
    for name, sets in pairs(d.set_restrict or {}) do ui.set_restrict[name:lower()] = sets; end
    ui.stat_fix = {};
    for name, fix in pairs(d.stat_fix or {}) do ui.stat_fix[name:lower()] = fix; end
    ui.stat_remove = {};
    for name, keys in pairs(d.stat_remove or {}) do ui.stat_remove[name:lower()] = keys; end
    ui.covers = {};
    for name, slots in pairs(d.covers or {}) do ui.covers[cover_key(name)] = slots; end
    ui.no_stack = nil;                                         -- rebuilt from d.no_stack on first use
    ui.dirty = true;
    return true;
end

local function player_call(fn, default)
    local ok, v = pcall(function() return fn(AshitaCore:GetMemoryManager():GetPlayer()); end);
    if ok and v ~= nil then return v; end
    return default;
end

local function job_level(job_id)
    local lv = player_call(function(p) return p:GetJobLevel(job_id); end, 99);
    return type(lv) == 'number' and lv or 99;
end

local function main_job()
    local j = player_call(function(p) return p:GetMainJob(); end, 1);
    return (j >= 1 and j <= #JOBS) and j or 1;
end

local function sub_job()
    local j = player_call(function(p) return p:GetSubJob(); end, 0);
    return (j >= 1 and j <= #JOBS) and j or 0;
end

local function player_name()
    local ok, n = pcall(function() return AshitaCore:GetMemoryManager():GetParty():GetMemberName(0); end);
    return (ok and n and n ~= '') and n or 'Player';
end

local function dw_active(job_id)
    if s.dw_mode == 2 then return true; end
    if s.dw_mode == 3 then return false; end
    if in_list(data.dual_wield_jobs, JOBS[job_id]) then return true; end
    if job_id == main_job() then
        local sj = sub_job();
        return sj > 0 and in_list(data.dual_wield_jobs, JOBS[sj]);
    end
    return false;
end

----------------------------------------------------------------------------------------------------
-- Base stats from the item description (CatsEyeXI's own DATs, as loaded by the launcher)
----------------------------------------------------------------------------------------------------
local ZONE_WORDS = { 'lumoria', 'al\'taieu', 'temenos', 'apollyon', 'limbus', 'nyzul', 'einherjar', 'voidwatch',
                     'walk of echoes', 'sortie', 'odyssey', 'escha', 'reisenjima', 'ambuscade', 'dynamis', 'abyssea',
                     'salvage', 'assault', 'besieged', 'campaign' };

local function parse_stats(desc)
    local stats = {};
    if desc == nil or desc == '' then return stats; end
    local text = desc:gsub('[\r\n]', ' '):lower();

    -- Stats followed by a zone condition ("Double Attack+2% while in Lumoria") don't count
    for _, z in ipairs(ZONE_WORDS) do
        local zp = z:gsub('(%W)', '%%%1');
        text = text:gsub('[%a"%.][%a%s"%.]-%s*[%+%-]%d+%%?%s*,?%s*while in ' .. zp, ' ');
        text = text:gsub('[%a"%.][%a%s"%.]-%s*[%+%-]%d+%%?%s*,?%s*in ' .. zp, ' ');
    end

    -- Everything after a conditional keyword (latent, set bonus, pet, zone, ...) doesn't count
    local cut = #text + 1;
    for _, word in ipairs(STOP_WORDS) do
        local p = text:find(word, 1, true);
        if p and p < cut then cut = p; end
    end
    text = text:sub(1, cut - 1);

    local function add(k, v) stats[k] = (stats[k] or 0) + v; end

    local def = text:match('def:%s*(%d+)');
    if def then add('def', tonumber(def)); end
    for n in text:gmatch('spell interruption rate down%s*(%d+)') do add('sird', tonumber(n)); end
    for chunk, val in text:gmatch('([%a"%.][%a%s"%.]-)%s*([%+%-]%d+)') do
        local key = S.normalize(chunk);
        local n = tonumber((val:gsub('^%+', '')));
        if key and n then
            if S.ABS[key] then n = math.abs(n); end
            add(key, n);
        end
    end
    if stats.refresh == nil and text:find('adds "refresh" effect', 1, true) then add('refresh', 1); end
    if stats.regen == nil and text:find('adds "regen" effect', 1, true) then add('regen', 1); end
    for _, k in ipairs({ 'sublimation', 'berserk', 'warcry', 'meditate', 'boost' }) do
        if stats[k] == nil and (text:find('enhances "' .. k .. '" effect', 1, true) or text:find('augments "' .. k .. '"', 1, true)) then
            add(k, 1);
        end
    end
    return stats;
end

----------------------------------------------------------------------------------------------------
-- Augments: read from each item, decoded with the server table + the client's augment list
----------------------------------------------------------------------------------------------------
local function byte_reader(item)
    local e = item.Extra;
    if e == nil then return nil; end
    local t = type(e);
    if t == 'string' then return function(i) return e:byte(i + 1) or 0; end; end
    if t == 'table' then return function(i) return tonumber(e[i + 1]) or 0; end; end
    return function(i)
        local ok, v = pcall(function() return e[i]; end);
        return (ok and tonumber(v)) or 0;
    end;
end

local function decode_augments(rd)
    local stats, unknown = {}, {};
    if rd == nil then return stats, unknown, false; end
    local kind, sub = rd(0), rd(1);
    if bit.band(kind, 0x02) == 0 then return stats, unknown, false; end
    if bit.band(sub, 0x08 + 0x10 + 0x20 + 0x80) ~= 0 then return stats, unknown, false; end
    local count = bit.band(sub, 0x40) ~= 0 and 4 or 5;
    local any = false;
    for k = 0, count - 1 do
        local raw = rd(2 + k * 2) + rd(3 + k * 2) * 256;
        local id, v = bit.band(raw, 0x7FF), bit.rshift(raw, 11);
        if id ~= 0 then
            any = true;
            local defs = AUG[id];
            if defs then
                for _, d in ipairs(defs) do
                    local key, a, b, c, src = d[1], d[2], d[3], d[4], d[5];
                    local val;
                    if src == 'w' then
                        val = (v + a) * b;
                    else
                        val = (a > 0 and a + v or a - v) * math.max(b, 1) / c;
                    end
                    if S.ABS[key] then val = math.abs(val); end
                    stats[key] = (stats[key] or 0) + val;
                end
            else
                table.insert(unknown, id);
            end
        end
    end
    return stats, unknown, any;
end

----------------------------------------------------------------------------------------------------
-- Scanning
----------------------------------------------------------------------------------------------------
-- Job ability effects ("Enhances Berserk") are often scripted on the server rather than stored as a stat,
-- so for these the description is still read when the server data has nothing.
local SCRIPTED = { 'berserk', 'warcry', 'meditate', 'boost', 'sublimation', 'roll', 'rolldur', 'rolldelay', 'rollaoe' };

-- Base stats for an item: overrides > server stats (server_stats.lua) > parsed description,
-- then stat_fix / stat_remove from data.lua
local function compute_base(id, name, desc)
    local lname = name:lower();
    local base = ui.overrides[lname];
    if base == nil then
        base = base_cache[id];
        if base == nil then
            local server = SERVER[id];
            if server then
                base = {};
                for k, v in pairs(server) do base[k] = v; end
                local parsed = parse_stats(desc);
                for _, k in ipairs(SCRIPTED) do
                    if base[k] == nil and parsed[k] ~= nil then base[k] = parsed[k]; end
                end
            else
                base = parse_stats(desc);
            end
            base_cache[id] = base;
        end
    end
    local fix = ui.stat_fix[lname];
    if fix then
        local fixed = {};
        for k, v in pairs(base) do fixed[k] = v; end
        for k, v in pairs(fix) do fixed[k] = v; end
        base = fixed;
    end
    local remove = ui.stat_remove[lname];
    if remove then
        local trimmed = {};
        for k, v in pairs(base) do trimmed[k] = v; end
        for _, k in ipairs(remove) do trimmed[k] = nil; end
        base = trimmed;
    end
    return base;
end

local function scan()
    owned, ui.augmented = {}, 0;
    local ok, err = pcall(function()
        local inv = AshitaCore:GetMemoryManager():GetInventory();
        local res = AshitaCore:GetResourceManager();
        for cid, cname in pairs(CONTAINERS) do
            local max = inv:GetContainerCountMax(cid) or 0;
            for i = 0, max do
                local it = inv:GetContainerItem(cid, i);
                if it ~= nil and it.Id ~= 0 and it.Id ~= 65535 then
                    local r = res:GetItemById(it.Id);
                    if r ~= nil and r.Slots ~= nil and r.Slots ~= 0 then
                        local name = r.Name[1] or '';
                        local desc = r.Description and r.Description[1] or '';
                      if not is_craft_gear(name, desc) then
                        local base = compute_base(it.Id, name, desc);
                        local rd = byte_reader(it);
                        local aug, unknown, augmented = decode_augments(rd);
                        local stats = {};
                        for k, v in pairs(base) do stats[k] = v; end
                        for k, v in pairs(aug) do stats[k] = (stats[k] or 0) + v; end
                        if augmented then ui.augmented = ui.augmented + 1; end
                        table.insert(owned, {
                            id = it.Id, name = name, where = cname, desc = desc, rd = rd,
                            slots = r.Slots, jobs = r.Jobs or 0, level = r.Level or 0,
                            skill = r.Skill or 0, shield = r.ShieldSize or 0,
                            base = base, aug = aug, unknown = unknown, augmented = augmented, stats = stats,
                        });
                      end
                    end
                end
            end
        end
    end);
    if not ok then msg('Scan error: ' .. tostring(err)); end
    ui.last_scan = os.date('%H:%M:%S');
    ui.dirty = true;
    return #owned;
end

----------------------------------------------------------------------------------------------------
-- Best in Slot database: every piece of equipment in the game data (CatsEyeXI DATs), base stats only.
-- Built a slice per frame so the game never stutters.
----------------------------------------------------------------------------------------------------
local bis = { pool = {}, next_id = 1, done = false, cache = {} };
local BIS_LAST_ID, BIS_PER_FRAME = 65534, 2500;

-- "Combatant's Torque" == "Combatant Torque", "Cerb. Mantle +1" == "cerb mantle +1"
local function name_key(n)
    return (n or ''):lower():gsub("'s%f[%W]", ''):gsub('[^%w%+]', '');
end

-- data.lua no_stack: "Brutal Earring" and "Brutal Earring +1" share one family key; nil for every other item
function actions.stack_family(name)
    if ui.no_stack == nil then
        ui.no_stack = {};
        for _, n in ipairs((data and data.no_stack) or {}) do ui.no_stack[name_key(n)] = true; end
    end
    local base = name_key(((name or ''):gsub('%s*%+%d+$', '')));
    return ui.no_stack[base] and base or nil;
end

-- Only items you've provided can be BiS: your XML reference sets (bis.lua), the preferred / fixed /
-- Summit items in data.lua, and whatever you own. Retail items in the game files are never used.
local bis_allowed = nil;
local function build_bis_allowed()
    local set = {};
    local function add(n)
        if type(n) == 'table' then for _, x in ipairs(n) do add(x); end return; end
        if type(n) == 'string' and n ~= '' then set[name_key(n)] = true; end
    end
    for _, sets in pairs(BIS_REF or {}) do
        for _, slots in pairs(sets) do for _, n in pairs(slots) do add(n); end end
    end
    for _, rule in ipairs(data.preferred or {}) do for _, n in ipairs(rule.items or {}) do add(n); end end
    for _, fam in pairs(data.summit or {}) do for _, n in pairs(fam) do add(n); end end
    for _, def in pairs(data.sets or {}) do
        for _, n in pairs(def.fixed or {}) do add(n); end
        for _, fx in pairs(def.fixed_by_job or {}) do for _, n in pairs(fx) do add(n); end end
    end
    for _, n in ipairs(data.bis_extra or {}) do add(n); end
    for n in pairs(data.adept_augments or {}) do add(n); end
    for n in pairs(data.max_augments or {}) do add(n); end            -- Artifact +1 / Relic +1
    for _, list in pairs(data.keep_range or {}) do add(list); end      -- Gjallarhorn
    for _, list in pairs(data.keep_ammo or {}) do add(list); end       -- Yoru Shuriken
    return set;
end

-- Full augment for a piece, looked up by name: Adept (data.adept_augments) and Artifact +1 / Relic +1
-- (data.max_augments). Used for the Best in Slot list only.
local adept_by_key = nil;
local function adept_augment(name)
    if adept_by_key == nil then
        adept_by_key = {};
        for n, a in pairs(data.max_augments or {}) do adept_by_key[name_key(n)] = a.stats; end
        for n, a in pairs(data.adept_augments or {}) do adept_by_key[name_key(n)] = a.stats; end
    end
    return adept_by_key[name_key(name)];
end

local function bis_step()
    if bis.done or data == nil then return; end
    bis_allowed = bis_allowed or build_bis_allowed();
    local res = AshitaCore:GetResourceManager();
    local max_level = data.bis_level or 75;
    local last = math.min(bis.next_id + BIS_PER_FRAME - 1, BIS_LAST_ID);
    for id = bis.next_id, last do
        local ok, r = pcall(function() return res:GetItemById(id); end);
        if ok and r ~= nil and r.Slots ~= nil and r.Slots ~= 0 and (r.Level or 0) <= max_level then
            local name = r.Name and r.Name[1] or '';
            local desc = r.Description and r.Description[1] or '';
            if name ~= '' and name ~= '.' and bis_allowed[name_key(name)] and not is_craft_gear(name, desc) then
                local base = compute_base(id, name, desc);
                -- Adept Reforging pieces are rated with their full (Tier 3) augment
                local aug = adept_augment(name) or {};
                local stats = {};
                for k, v in pairs(base) do stats[k] = v; end
                for k, v in pairs(aug) do stats[k] = (stats[k] or 0) + v; end
                if next(stats) ~= nil then
                    table.insert(bis.pool, {
                        id = id, name = name, where = 'BiS', desc = desc,
                        slots = r.Slots, jobs = r.Jobs or 0, level = r.Level or 0,
                        skill = r.Skill or 0, shield = r.ShieldSize or 0,
                        base = base, aug = aug, unknown = {}, augmented = next(aug) ~= nil, stats = stats,
                    });
                end
            end
        end
    end
    bis.next_id = last + 1;
    if bis.next_id > BIS_LAST_ID then bis.done = true; ui.dirty = true; end
end

local function bis_reset()
    bis.pool, bis.next_id, bis.done, bis.cache = {}, 1, false, {};
    bis_allowed, adept_by_key = nil, nil;
end

----------------------------------------------------------------------------------------------------
-- Set descriptors per job
----------------------------------------------------------------------------------------------------
local function ws_weights(ws)
    local w, hits, kind = {}, ws.hits or 1, ws.kind or 'physical';
    local function add(k, v) w[k] = (w[k] or 0) + v; end
    for stat, m in pairs(ws.mods or {}) do add(stat, m * 2.0); end
    if kind == 'physical' then
        add('str', 0.5); add('att', 1.0); add('acc', 0.8); add('wsacc', 0.8); add('combatskill', 0.7);
        add('wsd', hits == 1 and 10 or 6); add('da', 4); add('ta', 6); add('qa', 7); add('tpb', 0.02);
    elseif kind == 'ranged' then
        add('agi', 0.5); add('ratt', 1.0); add('racc', 0.8); add('wsacc', 0.8);
        add('wsd', hits == 1 and 10 or 6); add('tpb', 0.02);
    elseif kind == 'hybrid' then
        add('str', 0.3); add('att', 0.6); add('acc', 0.6); add('combatskill', 0.5); add('mab', 5); add('macc', 0.5);
        add('wsd', 8); add('tpb', 0.02);
    else
        add('mab', 7); add('macc', 0.6); add('wsd', 9); add('tpb', 0.02);
    end
    if ws.crit then add('crit', 7); add('critdmg', 5); add('dex', 0.5); end
    add('ctp', 0.5); add('scb', 1);
    return w;
end

local function xml_set_name(name)
    return (name:gsub("[^%w_]", ''));
end

-- BST: the jug pets you own for this job (ammo-slot items only BST can use), highest level first
function actions.owned_jugs(job_id)
    local list, seen, lvl = {}, {}, job_level(job_id);
    for _, it in ipairs(owned) do
        if bit.band(it.slots, 0x0008) ~= 0 and it.jobs == bit.lshift(1, job_id) and not seen[it.name]
            and (s.ignore_level or it.level <= lvl) then
            seen[it.name] = true;
            table.insert(list, it);
        end
    end
    table.sort(list, function(a, b) if a.level ~= b.level then return a.level > b.level; end return a.name < b.name; end);
    local names = {};
    for _, it in ipairs(list) do table.insert(names, it.name); end
    return names;
end

-- BST Reward: the best pet food you own and can use (data.pet_foods, best first)
function actions.best_pet_food(job_id)
    local lvl = job_level(job_id);
    for _, n in ipairs(data.pet_foods or {}) do
        for _, it in ipairs(owned) do
            if name_key(it.name) == name_key(n) and (s.ignore_level or it.level <= lvl) then return it.name; end
        end
    end
    return nil;
end

-- The jug list as a Lua table literal for the exports
function actions.jug_literal(jugs)
    local parts = {};
    for _, n in ipairs(jugs) do table.insert(parts, string.format('%q', n)); end
    return '{ ' .. table.concat(parts, ', ') .. ' }';
end

-- The job's set ids: data.jobs' list (removed ones are dropped in build_sets). Sets from other jobs can't be
-- added any more (s.set_added from 1.1.4 is ignored): their rules may not fit the job.
function actions.job_set_ids(abbr)
    local ids = {};
    for _, id in ipairs(data.jobs[abbr] or {}) do table.insert(ids, id); end
    return ids;
end

function actions.set_removed(abbr, id)
    for _, r in ipairs(s.set_removed[abbr] or {}) do if r == id then return true; end end
    return false;
end

-- Slash commands a gear-swap export answers (/pdt, /mdt, /hybrid, /idle...), as a Lua table literal
function actions.slash_cmds(have)
    local c = { 'idle' };
    if have.PDT then table.insert(c, 'pdt'); end
    if have.MDT then table.insert(c, 'mdt'); end
    if have.TP_Hybrid then table.insert(c, 'hybrid'); end
    if have.Nuke_MB then table.insert(c, 'mb'); end
    if have.TH then table.insert(c, 'th'); end
    if have.Refresh then table.insert(c, 'refresh'); end
    if have.DW then table.insert(c, 'dw'); end
    if have.PetRanged and have.PetTank then table.insert(c, 'petranged'); end
    if have.__jugs then table.insert(c, 'jug'); end
    local parts = {};
    for _, x in ipairs(c) do table.insert(parts, x .. ' = true'); end
    -- (have.__jugs is a flag, not a set: keep it out of the set checks below this point)
    return '{ ' .. table.concat(parts, ', ') .. ' }', c;
end

function actions.list_without(t, v)
    local out = {};
    for _, x in ipairs(t or {}) do if x ~= v then table.insert(out, x); end end
    return out;
end

-- Take a set out of a job (it leaves the list and every export), or put one back / add a new one
function actions.remove_set(abbr, id)
    s.set_added[abbr] = actions.list_without(s.set_added[abbr], id);
    if in_list(data.jobs[abbr] or {}, id) or id == 'SP' or id == 'WS' or id:find('^ws:') then
        if not actions.set_removed(abbr, id) then
            s.set_removed[abbr] = s.set_removed[abbr] or {};
            table.insert(s.set_removed[abbr], id);
        end
    end
    settings.save();
end

function actions.add_set(abbr, id)
    s.set_removed[abbr] = actions.list_without(s.set_removed[abbr], id);
    if not in_list(data.jobs[abbr] or {}, id) and id ~= 'SP' and id ~= 'WS' and not id:find('^ws:') then
        s.set_added[abbr] = actions.list_without(s.set_added[abbr], id);
        table.insert(s.set_added[abbr], id);
    end
    settings.save();
end

local function build_sets(job_id)
    local abbr, list = JOBS[job_id], {};
    local wjob = in_list(data.weapon_jobs, abbr);
    local jr = (data.job_range or {})[abbr] or {};
    local function range_for(kind, id, current)
        if current then return current; end
        if in_list(jr, kind) or in_list(jr, id) then return 'any'; end
        return nil;
    end
    -- BiS ranged weapon for this job (Tonzoffun / Annihilator / Death Penalty). The set may wear the range slot
    -- (and ammo), but only with YOUR weapon from the list - never a different one, so a shot is never cancelled.
    local rw = (data.ranged_weapons or {})[abbr];
    local function attach_ranged(entry, skill_name)
        local weapon = rw and skill_name and rw[skill_name];
        if weapon then
            entry.range, entry.range_weapon, entry.range_skill = 'both', weapon, SKILL_IDS[skill_name];
            entry.pref_slots = entry.pref_slots or {};
            entry.pref_slots.range, entry.pref_slots.ammo = true, true;
        end
    end
    local function job_ranged_skill()
        if rw and rw.Archery then return 'Archery'; end
        if rw and rw.Marksmanship then return 'Marksmanship'; end
        return nil;
    end
    for _, id in ipairs(actions.job_set_ids(abbr)) do
        if id == 'SP' then
            local sp = (data.sp_abilities or {})[abbr];
            local fam = sp and (data.summit or {})[sp[2]];
            if sp and fam then
                local fixed = {};
                for k, v in pairs(fam) do fixed[k] = v; end
                table.insert(list, { id = 'SP', name = 'SP_' .. xml_set_name(sp[1]), label = sp[1] .. ' (2-hour, ' .. sp[2] .. ' set)',
                                     kind = 'other', base_weights = {}, caps = {}, weapons = false,
                                     fixed = fixed, sp_ability = sp[1] });
            end
        elseif id == 'WS' then
            local generic = nil;
            for _, ws in ipairs(data.weaponskills) do
                if in_list(ws.jobs, '*') and ws.kind == ((abbr == 'RNG') and 'ranged' or 'physical') and generic == nil then
                    generic = ws;
                end
            end
            generic = generic or data.weaponskills[1];
            table.insert(list, { id = 'WS', name = 'WS', label = 'WS - Default (any weaponskill)', kind = 'ws', ws = generic,
                                 range = range_for('ws', 'WS') });
            local weapons = (data.job_weapons or {})[abbr];
            for _, ws in ipairs(data.weaponskills) do
                local weapon_ok = weapons == nil or (ws.skill and in_list(weapons, SKILL_NAMES[ws.skill]));
                if not in_list(ws.jobs, '*') and in_list(ws.jobs, abbr) and weapon_ok then
                    local entry = { id = 'ws:' .. ws.name, name = xml_set_name(ws.name), label = 'WS - ' .. ws.name,
                                    kind = 'ws', ws = ws, range = range_for('ws', 'ws:' .. ws.name) };
                    if ws.skill == 25 or ws.skill == 26 or ws.skill == 27 then attach_ranged(entry, SKILL_NAMES[ws.skill]); end
                    table.insert(list, entry);
                end
            end
        else
            local def = data.sets[id];
            if def then
                local in_wset = in_list((data.weapon_sets or {})[abbr], id);
                local entry = {
                    id = id, name = def.name or id, label = def.label or id, kind = def.kind or 'other',
                    base_weights = def.weights, caps = def.caps or {},
                    weapons = (def.weapons and wjob) or in_wset or false, range = range_for(def.kind or 'other', id, def.range),
                    fixed = def.fixed or (def.fixed_by_job and def.fixed_by_job[abbr]), fallback = def.fallback, buff = def.buff, engaged_buff = def.engaged_buff, buff_any = def.buff_any, ws_only = def.ws_only,
                    info = def.info,
                };
                local pref = {};
                if in_wset then pref.main, pref.sub = true, true; end          -- melee weapons only from your list
                for _, k in ipairs(def.pref_slots or {}) do pref[k] = true; end
                if next(pref) then entry.pref_slots = pref; end
                if def.ranged then attach_ranged(entry, def.ranged == 'job' and job_ranged_skill() or def.ranged); end
                if def.ranged == 'job' and abbr == 'RNG' then entry.label = entry.label .. ' (bow)'; end
                -- Shooting sets without a listed ranged weapon (THF): the ammo slot holds what you shoot, never swap it
                if def.ranged and entry.range ~= 'both' then entry.no_ammo = true; end
                if def.pet_food then
                    local food = actions.best_pet_food(job_id);
                    local fixed = {};
                    for k, v in pairs(entry.fixed or {}) do fixed[k] = v; end
                    fixed.ammo = food;
                    entry.fixed = fixed;
                    if food == nil then entry.no_ammo = true; end
                end
                table.insert(list, entry);
            end
        end
    end
    -- Jobs that keep a weapon in the range slot (SAM's bow): a set that doesn't handle the range slot must not
    -- swap ammo either. Non-matching ammo (a Tathlum) makes the game take the bow off.
    if #jr > 0 then
        for _, entry in ipairs(list) do
            if entry.range == nil then entry.no_ammo = true; end
        end
    end
    -- Jobs that keep one item in the range slot in EVERY set (BRD: the instrument). Swapping it resets TP, so
    -- every set wears the same piece and never touches ammo (ammo would take the instrument off).
    local kr = (data.keep_range or {})[abbr];
    if kr then
        local keep = nil;
        for _, n in ipairs(kr) do                                -- the listed ones first (Gjallarhorn)
            for _, it in ipairs(owned) do
                if keep == nil and name_key(it.name) == name_key(n) then keep = it.name; end
            end
        end
        if keep == nil then                                       -- otherwise your best instrument for songs
            local w = ((data.sets or {}).Songs_Buff or {}).weights or {};
            local best, best_score = nil, -1;
            local lvl = job_level(job_id);
            for _, it in ipairs(owned) do
                local only = ui.job_restrict[it.name:lower()];
                local job_ok = only and in_list(only, abbr) or (not only and bit.band(it.jobs, bit.lshift(1, job_id)) ~= 0);
                if INSTRUMENTS[it.skill] and job_ok and (s.ignore_level or it.level <= lvl) then
                    local sc = it.level * 0.001;                  -- ties: the higher level one
                    for k, v in pairs(it.stats or {}) do sc = sc + v * (w[k] or 0); end
                    if sc > best_score then best, best_score = it.name, sc; end
                end
            end
            keep = best;
        end
        for _, entry in ipairs(list) do
            entry.no_ammo = true;
            entry.bis_range = kr[1];
            if keep then
                entry.range, entry.range_weapon = 'keep', keep;
                entry.pref_slots = entry.pref_slots or {};
                entry.pref_slots.range = true;                    -- only that piece, never another instrument
            else
                entry.range = nil;                                -- no instrument owned: leave the slot alone
            end
        end
    end
    -- Jobs that keep one ammo in every set except weaponskills (NIN: Yoru Shuriken). Weaponskills pick their own.
    local ka = (data.keep_ammo or {})[abbr];
    if ka then
        local keep = nil;
        for _, n in ipairs(ka) do
            for _, it in ipairs(owned) do
                if keep == nil and name_key(it.name) == name_key(n) then keep = it.name; end
            end
        end
        for _, entry in ipairs(list) do
            if entry.kind ~= 'ws' then
                entry.bis_ammo = ka[1];
                if keep then
                    entry.ammo_item = keep;
                    entry.pref_slots = entry.pref_slots or {};
                    entry.pref_slots.ammo = true;                 -- only that piece, nothing else in ammo
                else
                    entry.no_ammo = true;                         -- not owned: leave the ammo slot alone
                end
            end
        end
    end
    -- Sets you removed from this job (sidebar: right-click a set) leave the list and every export
    if #(s.set_removed[abbr] or {}) > 0 then
        local kept = {};
        for _, e in ipairs(list) do
            if not actions.set_removed(abbr, e.id) then table.insert(kept, e); end
        end
        list = kept;
    end
    -- Lockstyle: the look you want, picked by hand (or imported from what you wear). Nothing is chosen
    -- automatically and it never swaps gear; the addon locks it on when you log in or change job.
    table.insert(list, { id = 'Lockstyle', name = 'Lockstyle', label = 'Lockstyle (your look)', kind = 'lockstyle',
                         base_weights = {}, caps = {}, weapons = true, range = 'any', fixed = {}, lockstyle = true });
    for _, e in ipairs(list) do e.abbr = abbr; end
    return list;
end

local function weights_for(job_id, desc)
    local w = {};
    if desc.kind == 'ws' then
        w = ws_weights(desc.ws);
    else
        for k, v in pairs(desc.base_weights or {}) do w[k] = v; end
        if desc.kind == 'tp' and dw_active(job_id) then w.dw = data.dual_wield_weight or 5; end
    end
    -- "Polearm skill +7" etc. count like Combat Skill, but only for the weapon types this job uses
    if w.combatskill and w.combatskill > 0 and S and S.SKILL_KEY then
        for _, sn in ipairs((data.job_weapons or {})[JOBS[job_id]] or {}) do
            local k = S.SKILL_KEY[sn];
            if k and w[k] == nil then w[k] = w.combatskill; end
        end
    end
    -- Jobs with no MP of their own: MP / Refresh are worth nothing (no Royal Cloak, Wivre Hairpin on MNK).
    -- Magic accuracy, MAB and Fast Cast stay: NIN Ninjutsu / Utsusemi and COR Quick Draw use them.
    if in_list(data.no_mp_jobs, JOBS[job_id]) then
        for _, k in ipairs({ 'mp', 'refresh', 'hmp', 'cmp' }) do w[k] = nil; end
    end
    return w;
end

----------------------------------------------------------------------------------------------------
-- Optimization
----------------------------------------------------------------------------------------------------
local function is_excluded(name)
    local n = (name or ''):lower();
    return ui.data_excl[n];
end

-- data.set_exclude: an item never used in one job's set (e.g. no Shukuyu Ring in NIN TP)
local function set_excluded(job_id, desc, name)
    local by_set = (data.set_exclude or {})[JOBS[job_id]] or {};
    for _, list in ipairs({ by_set[desc.id] or {}, by_set['*'] or {} }) do   -- '*' = every set of the job
        for _, n in ipairs(list) do
            if name_key(n) == name_key(name) then return true; end
        end
    end
    return false;
end

local function score_of(stats, w)
    local total = 0;
    for k, v in pairs(stats) do
        local wk = w[k];
        if wk then total = total + v * wk; end
    end
    return total;
end

local function set_totals(assign, w)
    local totals = {};
    for _, c in pairs(assign) do
        for k, v in pairs(c.item.stats) do
            if w[k] then totals[k] = (totals[k] or 0) + v; end
        end
    end
    return totals;
end

local function capped(k, v, caps)
    local cap = caps[k];
    if cap == nil then return v; end
    if cap >= 0 then return math.min(v, cap); end
    return math.max(v, cap);
end

local function set_score(assign, w, caps)
    local sc = 0;
    for k, v in pairs(set_totals(assign, w)) do sc = sc + capped(k, v, caps) * w[k]; end
    return sc;
end

local function can_wear(item, job_id, lvl, strict)
    local only = ui.job_restrict[item.name:lower()];
    if only then
        if not in_list(only, JOBS[job_id]) then return false; end
    elseif bit.band(item.jobs, bit.lshift(1, job_id)) == 0 then
        return false;
    end
    if (strict or not s.ignore_level) and item.level > lvl then return false; end
    return true;
end

local function sub_ok(main, sub, dw)
    if sub == nil then return true; end
    local mi = main and main.item;
    if mi and mi.skill == SKILL_H2H then return false; end
    if mi and TWO_HANDED[mi.skill] then return sub.item.skill == 0 and sub.item.shield == 0; end   -- grip
    if sub.item.shield > 0 then return true; end                                                    -- shield
    if sub.item.skill > 0 and not TWO_HANDED[sub.item.skill] then return dw; end                   -- off-hand weapon
    return false;                                                                                   -- grip without 2H
end

-- bis_only = true: a fixed set (Chakra, Focus, 2-hour...) only uses its listed slots, as in the Best in Slot view.
-- Otherwise it shows every slot: the listed pieces plus empty slots you can fill with the dropdown.
local function active_slots(desc, bis_only)
    local list = {};
    if desc.info then return list; end                     -- an info panel (e.g. attachments) has no gear slots
    if desc.lockstyle then                                 -- only the slots you can see: weapons + armor, no BiS
        if bis_only then return list; end
        for _, def in ipairs(SLOTS) do
            if look.slots[def.key] then table.insert(list, def); end
        end
        return list;
    end
    if desc.fixed and bis_only then
        for _, def in ipairs(SLOTS) do
            if desc.fixed[def.key] then table.insert(list, def); end
        end
        return list;
    end
    for _, def in ipairs(SLOTS) do
        local use = true;
        if def.weapon then use = desc.weapons and s.weapons; end
        if def.ranged then use = (desc.range == 'instrument' or desc.range == 'any' or desc.range == 'both' or desc.range == 'keep'); end
        if def.key == 'ammo' and desc.range ~= nil and desc.range ~= 'both' then use = false; end
        if def.key == 'ammo' and desc.no_ammo then use = false; end
        -- A weapon you picked yourself (arrow on the Main / Sub / Range card) is used in any job, melee jobs too
        if not use and not bis_only and (def.weapon or def.ranged) and desc.abbr then
            local pick = (ui.pins[desc.abbr .. '|' .. desc.id] or {})[def.key];
            if type(pick) == 'table' and pick.name then use = true; end
        end
        if use then table.insert(list, def); end
    end
    return list;
end

local function slot_candidate_ok(def, item, desc)
    local sets = ui.set_restrict[item.name:lower()];
    if sets and not in_list(sets, desc.id) then return false; end
    if def.key == 'ammo' and item.skill > 0 and not (desc.range == 'both' and desc.range_skill == item.skill) then return false; end  -- ammunition follows the weapon
    if def.key == 'range' and desc.range == 'both' and desc.range_skill and item.skill ~= desc.range_skill then return false; end
    if def.key == 'main' and item.skill == 0 then return false; end
    if def.key == 'range' and desc.range == 'instrument' and not INSTRUMENTS[item.skill] then return false; end
    if def.key == 'range' and desc.range == 'any' and item.skill == 0 then return false; end
    return true;
end


local function same_piece(c, pin, loose)
    if type(pin.name) == 'table' then
        for _, n in ipairs(pin.name) do
            if name_key(c.item.name) == name_key(n) then return true; end
        end
        return false;
    end
    if loose then return name_key(c.item.name) == name_key(pin.name); end
    return c.item.name == pin.name and c.item.where == pin.where;
end

local curated_for;   -- defined with the BiS code further down

-- Preferred items (data.lua) that apply to this job + set
local function preferred_for(job_id, desc)
    local names = {};
    for _, rule in ipairs(data.preferred or {}) do
        local ok = true;
        if rule.jobs and not in_list(rule.jobs, JOBS[job_id]) then ok = false; end
        if ok and rule.sets and not in_list(rule.sets, desc.id) then ok = false; end
        if ok and rule.ws then
            if desc.kind ~= 'ws' or desc.ws == nil then
                ok = false;
            elseif rule.ws == 'single' then
                ok = (desc.ws.hits or 1) == 1;
            elseif rule.ws == 'multi' then
                ok = (desc.ws.hits or 1) > 1;
            end
        end
        if ok and rule.ws_stat then
            ok = desc.kind == 'ws' and desc.ws ~= nil and ((desc.ws.mods or {})[rule.ws_stat] or 0) > 0;
        end
        -- ws_names = only these weaponskills (e.g. Fotia on the fTP-replicating ones)
        if ok and rule.ws_names then
            ok = desc.kind == 'ws' and desc.ws ~= nil and in_list(rule.ws_names, desc.ws.name);
        end
        if ok and not rule.sets and not rule.ws and not rule.ws_stat and not rule.ws_names then ok = false; end
        if ok then for _, n in ipairs(rule.items or {}) do table.insert(names, n); end end
    end
    return names;
end

-- pins: slot -> {name, where} (force a piece), false (force empty), nil (optimizer decides)
local function optimize(job_id, desc, pins, pool)
    local w, caps = weights_for(job_id, desc), desc.caps or {};
    local pure = pool ~= nil;                -- BiS mode: whole game, base stats, no picks/preferred/fixed
    local lvl, dw = pure and (data.bis_level or 75) or job_level(job_id), dw_active(job_id);
    local slots = active_slots(desc, pure);
    pool = pool or owned;
    pins = pure and {} or (pins or {});
    if desc.fixed and not pure then
        local merged = {};
        -- The listed pieces; every other slot stays empty (so the set only swaps what it needs)
        -- unless you pick something for it with the dropdown
        for _, def in ipairs(slots) do merged[def.key] = false; end
        for k, v in pairs(desc.fixed) do merged[k] = { name = v, alt = desc.fallback and desc.fallback[k] }; end
        for k, v in pairs(pins) do merged[k] = v; end
        pins = merged;
    end

    local full, cands = {}, {};
    for _, def in ipairs(slots) do
        local all, list = {}, {};
        for idx, item in ipairs(pool) do
            -- Lockstyle: any piece you own that fits the slot, whatever its job or level
            if bit.band(item.slots, def.mask) ~= 0 and (desc.lockstyle or can_wear(item, job_id, lvl, pure)) then
                local c = { idx = idx, item = item, score = score_of(item.stats, w) };
                table.insert(all, c);
                if c.score > 0 and not is_excluded(item.name) and not set_excluded(job_id, desc, item.name)
                        and slot_candidate_ok(def, item, desc) then
                    table.insert(list, c);
                end
            end
        end
        table.sort(all, function(x, y) return x.score > y.score; end);
        table.sort(list, function(x, y) return x.score > y.score; end);
        if pure then
            -- BiS: an item's +1 version replaces it (Defending Ring +1, not Defending Ring)
            local plus = {};
            for _, c in ipairs(list) do plus[name_key(c.item.name)] = true; end
            local kept = {};
            for _, c in ipairs(list) do
                if not plus[name_key(c.item.name .. ' +1')] then table.insert(kept, c); end
            end
            list = kept;
            while #list > 25 do table.remove(list); end
            all = list;
        end
        if desc.pref_slots and desc.pref_slots[def.key] then list = {}; end   -- these slots only take your listed pieces
        full[def.key], cands[def.key] = all, list;
    end

    local assign, used, locked = {}, {}, {};
    for _, def in ipairs(slots) do
        local pin = pins[def.key];
        if pin == false then
            locked[def.key] = true;
        elseif pin then
            for pass = 1, 2 do
                for _, c in ipairs(full[def.key]) do
                    if not used[c.idx] and same_piece(c, pin, pass == 2) then
                        assign[def.key], used[c.idx], locked[def.key] = c, true, true;
                        break;
                    end
                end
                if locked[def.key] then break; end
            end
            if not locked[def.key] and pin.alt then
                for _, c in ipairs(full[def.key]) do
                    if not used[c.idx] and same_piece(c, { name = pin.alt }, true) then
                        assign[def.key], used[c.idx], locked[def.key] = c, true, true;
                        break;
                    end
                end
            end
        end
    end

    -- Preferred gear from data.lua (user picks always win)
    local forced, wanted = {}, {};
    local prefer_names, n_rules = {}, 0;
    if not pure then
        prefer_names = preferred_for(job_id, desc);
        if desc.range_weapon then table.insert(prefer_names, desc.range_weapon); end
        if desc.ammo_item then table.insert(prefer_names, desc.ammo_item); end
        n_rules = #prefer_names;                 -- your explicit rules (data.lua) come first and always win
        local ref = curated_for and curated_for(job_id, desc);
        if ref then
            for _, n in pairs(ref) do
                if type(n) == 'table' then for _, x in ipairs(n) do table.insert(prefer_names, x); end
                else table.insert(prefer_names, n); end
            end
        end
    end
    -- One entry per listed name, each claiming its own copy: a name listed twice (two Ghillie Earrings) uses two copies
    local claimed = {};
    for order, pname in ipairs(prefer_names) do
        local lname = name_key(pname);
        local found = nil;
        for _, def in ipairs(slots) do
            if not found then
                for _, c in ipairs(full[def.key]) do
                    if not claimed[c.idx] and name_key(c.item.name) == lname then found = c; break; end
                end
            end
        end
        if found then
            claimed[found.idx] = true;
            table.insert(wanted, { c = found, order = order, pri = (order <= n_rules) and 1 or 2 });
        end
    end
    table.sort(wanted, function(a, b)
        if a.pri ~= b.pri then return a.pri < b.pri; end         -- explicit rules beat the BiS reference
        if math.abs(a.c.score - b.c.score) > 1e-6 then return a.c.score > b.c.score; end
        return a.order < b.order;
    end);
    for _, wnt in ipairs(wanted) do
        if not used[wnt.c.idx] then
            for _, def in ipairs(slots) do
                if not locked[def.key] and bit.band(wnt.c.item.slots, def.mask) ~= 0 then
                    -- the same item can be listed under several slots (ears/rings); take this slot's entry
                    local entry = nil;
                    for _, c2 in ipairs(full[def.key]) do if c2.idx == wnt.c.idx then entry = c2; break; end end
                    if entry then
                        assign[def.key], used[entry.idx], locked[def.key], forced[def.key] = entry, true, true, true;
                        break;
                    end
                end
            end
        end
    end

    for _, def in ipairs(slots) do
        if not locked[def.key] then
            for _, c in ipairs(cands[def.key]) do
                if not used[c.idx] and (def.key ~= 'sub' or sub_ok(assign.main, c, dw)) then
                    assign[def.key], used[c.idx] = c, true;
                    break;
                end
            end
        end
    end

    -- Normal + HQ versions that don't work together (data.lua no_stack, e.g. Brutal Earring + Brutal Earring +1):
    -- keep the better one (a slot you picked by hand wins), the other slot takes its next best piece
    local fam = actions.stack_family;
    do
        local keep = {};
        for _, def in ipairs(slots) do
            local c = assign[def.key];
            local f = c and fam(c.item.name);
            if f then
                local k = keep[f];
                if k == nil or (locked[def.key] and not locked[k]) or (not locked[k] and c.score > assign[k].score) then keep[f] = def.key; end
            end
        end
        for _, def in ipairs(slots) do
            local c = assign[def.key];
            local f = c and fam(c.item.name);
            if f and keep[f] ~= def.key and not locked[def.key] then
                used[c.idx] = nil; assign[def.key] = nil;
                for _, alt in ipairs(cands[def.key]) do
                    local af = fam(alt.item.name);
                    if not used[alt.idx] and (af == nil or keep[af] == nil) then
                        assign[def.key], used[alt.idx] = alt, true;
                        if af then keep[af] = def.key; end
                        break;
                    end
                end
            end
        end
    end

    -- BiS mode: your own copy and the game-data copy of an item are the same piece
    if pure then
        local seen = {};
        for _, def in ipairs(slots) do
            local c = assign[def.key];
            if c then
                local k = name_key(c.item.name);
                if seen[k] and not locked[def.key] then
                    used[c.idx] = nil; assign[def.key] = nil;
                    for _, alt in ipairs(cands[def.key]) do
                        local ak = name_key(alt.item.name);
                        if not used[alt.idx] and not seen[ak] then assign[def.key], used[alt.idx] = alt, true; seen[ak] = true; break; end
                    end
                else
                    seen[k] = true;
                end
            end
        end
    end

    local best = set_score(assign, w, caps);
    for _ = 1, 10 do
        local improved = false;
        for _, def in ipairs(slots) do
            if not locked[def.key] then
                local cur, options = assign[def.key], cands[def.key];
                for i = 0, #options do
                    local c = options[i];
                    local valid = c ~= cur and (c == nil or not used[c.idx]);
                    if valid and pure and c then
                        local ck = name_key(c.item.name);
                        for k2, other in pairs(assign) do
                            if k2 ~= def.key and other and name_key(other.item.name) == ck then valid = false; end
                        end
                    end
                    if valid and c and fam(c.item.name) then         -- never swap in the other half of a no_stack pair
                        local cf = fam(c.item.name);
                        for k2, other in pairs(assign) do
                            if k2 ~= def.key and other and fam(other.item.name) == cf then valid = false; end
                        end
                    end
                    if valid and def.key == 'sub' and c then valid = sub_ok(assign.main, c, dw); end
                    if valid then
                        assign[def.key] = c;
                        local dropped = nil;
                        if def.key == 'main' and assign.sub and not locked.sub and not sub_ok(c, assign.sub, dw) then
                            dropped, assign.sub = assign.sub, nil;
                        end
                        local sc = set_score(assign, w, caps);
                        if sc > best + 1e-6 then
                            best = sc;
                            if cur then used[cur.idx] = nil; end
                            if c then used[c.idx] = true; end
                            if dropped then used[dropped.idx] = nil; end
                            cur, improved = c, true;
                        else
                            assign[def.key] = cur;
                            if dropped then assign.sub = dropped; end
                        end
                    end
                end
            end
        end
        if not improved then break; end
    end
    return assign, best, full, w, forced;
end

-- Curated BiS (bis.lua) for this job + set: exact set / weaponskill first, then by WS stats, then the default WS.
curated_for = function(job_id, desc)
    local ref = BIS_REF[JOBS[job_id]];
    if ref == nil or desc == nil then return nil; end
    if ref[desc.id] then return ref[desc.id]; end
    if desc.kind == 'ws' and desc.ws then
        local mods = desc.ws.mods or {};
        local keys = {};
        for k, v in pairs(mods) do if v > 0 then table.insert(keys, k); end end
        if #keys >= 2 then
            for rk, rv in pairs(ref) do
                local combo = rk:match('^ws_both:(.+)$');
                if combo then
                    local need, all = {}, true;
                    for st in combo:gmatch('[^+]+') do need[#need + 1] = st; end
                    for _, st in ipairs(need) do if (mods[st] or 0) <= 0 then all = false; end end
                    if all and #need == #keys then return rv; end
                end
            end
        end
        table.sort(keys, function(a, b) return mods[a] > mods[b]; end);
        for _, k in ipairs(keys) do
            if ref['ws_stat:' .. k] then return ref['ws_stat:' .. k]; end
        end
        return ref['WS'];
    end
    return nil;
end

local bis_index, bis_index_pool = nil, nil;
local function find_item_by_name(name)
    local key = name_key(name);
    for _, it in ipairs(owned) do if name_key(it.name) == key then return it; end end
    if bis_index_pool ~= bis.pool then bis_index, bis_index_pool = nil, bis.pool; end
    if bis_index == nil and bis.done then
        bis_index = {};
        for _, it in ipairs(bis.pool) do bis_index[name_key(it.name)] = bis_index[name_key(it.name)] or it; end
    end
    return bis_index and bis_index[key] or nil;
end

local function bis_for(job_id, desc)
    if desc == nil then return nil; end
    local curated = curated_for(job_id, desc) or desc.fixed;
    local bis_range = desc.bis_range or desc.range_weapon;          -- BRD: Gjallarhorn is the BiS instrument
    local bis_ammo = desc.bis_ammo or desc.ammo_item;               -- NIN: Yoru Shuriken outside weaponskills
    if bis_range or bis_ammo then
        local merged = {};
        for k, v in pairs(curated or {}) do merged[k] = v; end
        if bis_range then merged.range = bis_range; end
        if bis_ammo then merged.ammo = bis_ammo; end
        curated = merged;
    end
    if not bis.done and curated == nil then return nil; end
    local key = JOBS[job_id] .. '|' .. desc.id .. '|' .. tostring(dw_active(job_id)) .. '|' .. ui.last_scan;
    local hit = bis.cache[key];
    if hit == nil then
        -- The same list for everyone: reference items with their base stats (Adept pieces with their full augment).
        -- Your own pieces and their augments are NOT used here, so Best in Slot doesn't depend on who looks at it.
        local pool = {};
        for _, it in ipairs(bis.pool) do table.insert(pool, it); end
        local assign = {};
        if bis.done then assign = optimize(job_id, desc, nil, pool); end
        -- Your reference sets (bis.lua) win for every slot they list
        local w, caps = weights_for(job_id, desc), desc.caps or {};
        local active = {};
        for _, def in ipairs(active_slots(desc, true)) do active[def.key] = true; end
        for slot, iname in pairs(curated or {}) do
          if active[slot] then
            local it = nil;
            local names = type(iname) == 'table' and iname or { iname };
            for _, n in ipairs(names) do it = it or find_item_by_name(n); end
            iname = names[1];
            if it == nil then
                it = { name = iname, where = 'BiS', stats = {}, base = {}, aug = {}, unknown = {}, augmented = false, slots = 0 };
            end
            assign[slot] = { idx = -1, item = it, score = score_of(it.stats or {}, w), curated = true };
          end
        end
        -- A piece you listed can't also be filled in automatically in another slot (no ring or earring twice)
        do
            local listed = {};
            -- (an item's no_stack partner counts as the same piece: a listed Brutal Earring +1 blocks a plain one)
            for slot, c in pairs(assign) do
                if c.curated then
                    listed[name_key(c.item.name)] = slot;
                    local f = actions.stack_family(c.item.name);
                    if f then listed['family:' .. f] = slot; end
                end
            end
            for slot, c in pairs(assign) do
                local f = actions.stack_family(c.item.name);
                local at = listed[name_key(c.item.name)] or (f and listed['family:' .. f]);
                if not c.curated and at and at ~= slot then assign[slot] = nil; end
            end
        end
        -- Your explicit rules (data.lua: Fotia on fTP-replicating WS, STR rings, Boost gloves...) apply to the BiS view too
        local taken = {};
        for _, pname in ipairs(preferred_for(job_id, desc)) do
            local it = find_item_by_name(pname);
            -- only pieces this job can wear (Pinnacle only for its jobs, never for THF...)
            if it and it.slots and it.slots ~= 0 and (it.jobs == nil or can_wear(it, job_id, 99, false)) then
                for _, def in ipairs(active_slots(desc, true)) do
                    if active[def.key] and not taken[def.key] and bit.band(it.slots, def.mask) ~= 0 then
                        assign[def.key] = { idx = -1, item = it, score = score_of(it.stats or {}, w), curated = true };
                        taken[def.key] = true;
                        break;
                    end
                end
            end
        end
        hit = { assign = assign, total = set_score(assign, w, caps), curated = curated ~= nil };
        if bis.done then bis.cache[key] = hit; end
    end
    return hit;
end

local function recompute()
    if data == nil then return; end
    ui.sets = build_sets(ui.job);
    if ui.set_idx > #ui.sets then ui.set_idx = 1; end
    ui.desc = ui.sets[ui.set_idx];
    if ui.desc == nil then ui.result, ui.full = {}, {}; ui.dirty = false; return; end
    ui.ctx = JOBS[ui.job] .. '|' .. ui.desc.id;
    ui.pins[ui.ctx] = ui.pins[ui.ctx] or {};
    ui.result, ui.total, ui.full, ui.weights, ui.forced = optimize(ui.job, ui.desc, ui.pins[ui.ctx]);
    ui.bis = bis_for(ui.job, ui.desc);
    ui.dirty = false;
end

----------------------------------------------------------------------------------------------------
-- XML export (LegacyAC format: Ashita/config/LegacyAC/CharacterName_JOB.xml)
----------------------------------------------------------------------------------------------------
local function xml_escape(str)
    return (tostring(str):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;'));
end

local function set_xml_lines(out, ind, name, assign)
    table.insert(out, string.format('%s<set name="%s">', ind, xml_escape(name)));
    local covered = covered_slots(assign);
    for _, def in ipairs(SLOTS) do
        local c = assign[def.key];
        if covered[def.key] then
            table.insert(out, string.format('%s    <%s>displaced</%s>', ind, def.tag, def.tag));
        elseif c then
            table.insert(out, string.format('%s    <%s>%s</%s>', ind, def.tag, xml_escape(c.item.name), def.tag));
        end
    end
    table.insert(out, ind .. '</set>');
end

local function equip_set(name)
    return function(out, ind)
        table.insert(out, string.format('%s<equip set="%s" />', ind, xml_escape(name)));
        -- The set's weapons only when the subjob isn't NIN/DNC (dual wield: the pair or your own weapons)
        if actions.wsplit and actions.wsplit[name] then
            table.insert(out, string.format('%s<if p_subjob="%s"><equip set="%s_Weapons" /></if>', ind,
                xml_escape('!NIN&!DNC'), xml_escape(name)));
            if actions.wpair then
                table.insert(out, string.format('%s<else><equip set="DualWieldWeapons" /></else>', ind));
            end
        end
    end;
end

-- data.ja_sets / data.spell_sets entries are { name, set } or just 'Name' when the set has the same name
local function name_set_pair(p)
    if type(p) == 'table' then return p; end
    return { p, p };
end

-- Spells with their own midcast set (data.spell_sets), limited to the sets this export contains
local function spell_set_list(have)
    local list = {};
    for _, e in ipairs(data.spell_sets or {}) do
        local p = name_set_pair(e);
        if have[p[2]] then table.insert(list, p); end
    end
    return list;
end

-- A job's base set for spells / abilities (data.midcast_base, data.ability_base) if this export contains it
local function job_base(map, abbr, have)
    local name = (map or {})[abbr];
    return (name and have[name]) and name or nil;
end

-- branches: { { cond = 'attr="value"', body = fn }, ... }; default: fn or nil
-- Job abilities that wear their own set (data.ja_sets), limited to the sets this export contains
local function ja_list(built)
    local present = {};
    for _, b in ipairs(built) do present[b.desc.name] = true; end
    local list = {};
    for _, e in ipairs(data.ja_sets or {}) do
        local p = name_set_pair(e);
        if present[p[2]] then table.insert(list, p); end
    end
    return list;
end

local function emit_chain(out, ind, branches, default)
    for i, b in ipairs(branches) do
        local tag = (i == 1) and 'if' or 'elseif';
        if b.comment then table.insert(out, string.format('%s<!-- %s -->', ind, xml_escape(b.comment))); end
        table.insert(out, string.format('%s<%s %s>', ind, tag, b.cond));
        b.body(out, ind .. '    ');
        table.insert(out, string.format('%s</%s>', ind, tag));
    end
    if default then
        if #branches == 0 then
            default(out, ind);
        else
            table.insert(out, ind .. '<else>');
            default(out, ind .. '    ');
            table.insert(out, ind .. '</else>');
        end
    end
end

local function attr(name, value) return string.format('%s="%s"', name, xml_escape(value)); end

-- Obi block: equips the matching elemental obi on weather, day or storm buff
local function owned_obis()
    -- name exactly as the piece you own spells it (the server writes "Hachirin-no-obi"), so every export can equip it
    local have = {};
    for _, item in ipairs(owned) do have[item.name:lower()] = { where = item.where, name = item.name }; end
    local result = {};
    for element, o in pairs(data.obis or {}) do
        local mine = have[o.obi:lower()];
        if mine == nil and data.obi_all then mine = have[data.obi_all:lower()]; end   -- Hachirin-no-Obi: every element
        if mine then result[element] = { name = mine.name, storm = o.storm, where = mine.where }; end
    end
    return result;
end

local function obi_block(obis, only)
    return function(out, ind)
        local elements = {};
        for e in pairs(obis) do if only == nil or only == e then table.insert(elements, e); end end
        table.sort(elements);
        if #elements == 0 then return; end
        table.insert(out, ind .. '<!-- Elemental obi: weather, day, or storm buff matches the spell element -->');
        for _, e in ipairs(elements) do
            local o = obis[e];
            local put = function(o2, i2)
                table.insert(o2, string.format('%s<equip><waist>%s</waist></equip>', i2, xml_escape(o.name)));
            end;
            table.insert(out, string.format('%s<if %s>', ind, attr('ad_element', e)));
            emit_chain(out, ind .. '    ', {
                { cond = attr('e_weather', e .. '*'), body = put },
                { cond = attr('e_dayelement', e), body = put },
                { cond = attr('buffactive', o.storm), body = put },
            }, nil);
            table.insert(out, ind .. '</if>');
        end
    end;
end

local function with_obi(set_name, obis, only)
    local eq, ob = equip_set(set_name), obi_block(obis, only);
    return function(out, ind) eq(out, ind); ob(out, ind); end;
end

-- ws_only names ("Upheaval") -> weaponskill ids, so rules work in any client language
local function ws_ids_for(names)
    local ids = {};
    for _, n in ipairs(names or {}) do
        for _, ws in ipairs(data.weaponskills) do
            if ws.id and ws.name:lower() == n:lower() then table.insert(ids, ws.id); end
        end
    end
    return ids;
end

-- RNG shoots a bow or a gun: the gun's name tells the exports which Preshot / Midshot set to use
local function gun_name_for(abbr)
    local rw = (data.ranged_weapons or {})[abbr];
    if rw and rw.Archery and rw.Marksmanship then return rw.Marksmanship; end
    return nil;
end

local function build_full_xml(job_id)
    local abbr = JOBS[job_id];
    local descs = build_sets(job_id);
    local built, have = {}, {};
    for _, desc in ipairs(descs) do
        local pins = ui.pins[abbr .. '|' .. desc.id] or {};
        local assign = optimize(job_id, desc, pins);
        if next(assign) ~= nil then
            table.insert(built, { desc = desc, assign = assign });
            have[desc.name] = desc;
        end
    end

    local R = data.rules or {};
    local obis = owned_obis();
    local jugs = (abbr == 'BST') and actions.owned_jugs(job_id) or {};
    have.__jugs = #jugs > 0;
    local out = {};
    local function add(line) table.insert(out, line); end

    add('<ashitacast>');
    add(string.format('    <!-- Generated by YunaGearOpt %s for %s (%s) on %s from the gear you own. -->',
        addon.version, player_name(), abbr, os.date('%Y-%m-%d %H:%M')));
    -- When the server is slow the game resends spells/abilities; without this LegacyAC redoes every swap for each
    -- resend, which slows the server more (lag that snowballs with bots like Sidekick that act nonstop)
    add('    <settings>');
    add('        <blockresends>true</blockresends>');
    add('    </settings>');
    add('    <!-- Commands: /pdt /mdt /hybrid toggle defensive modes, /idle puts them back to normal, /mb toggles magic burst, /th toggles Treasure Hunter. -->');
    if abbr == 'PUP' then add('    <!-- PUP: while the automaton is out you wear its gear; /petranged switches tank / ranged gear. -->'); end
    add('    <!-- /warp: uses a Scroll of Instant Warp if you have one, otherwise equips and uses your Warp Ring. -->');
    add('    <!-- Any set can also be forced with: /la set SetName 60 -->');
    local prc = data.phalanx_received;
    if prc and have[prc.set] then
        add('    <!-- Phalanx cast on you: keep YunaGearOpt loaded and it puts on ' .. prc.set .. ' for a few seconds (/la set). -->');
    end
    if have.Lockstyle then
        add('    <!-- Lockstyle: keep YunaGearOpt loaded and it locks your Lockstyle look on after login / job change (/ygo lockstyle). -->');
    end
    -- Remember which jobs' XML has the Phalanx-received set, so the addon only sends /la set for those
    local list = {};
    for j in (s.xml_phalanx or ''):gmatch('[^,]+') do if j ~= abbr then table.insert(list, j); end end
    if prc and have[prc.set] then table.insert(list, abbr); end
    s.xml_phalanx = table.concat(list, ',');
    settings.save();
    add('');
    add('    <sets>');
    -- Weapons: a set's main/sub go in "<set>_Weapons", put on only when the subjob isn't NIN/DNC (equip_set);
    -- with /NIN or /DNC the job's dual-wield pair (DualWieldWeapons) goes on instead, if you picked one
    actions.wsplit = {};
    actions.wpair = nil;
    local mage = in_list(data.weapon_jobs, abbr);
    local pair = (s.weapon_mode == 1 and mage) and actions.dw_pair(abbr) or nil;
    if pair then
        local a = {};
        for k, v in pairs(pair) do a[k] = { item = { name = v } }; end
        add('        <!-- Dual-wield weapons: worn instead of a set\'s weapons while subbing NIN or DNC -->');
        set_xml_lines(out, '        ', 'DualWieldWeapons', a);
        actions.wpair = true;
    end
    for _, b in ipairs(built) do
        add(string.format('        <!-- %s -->', xml_escape(b.desc.label)));
        local a = b.assign;
        if s.weapon_mode == 1 and mage and b.desc.id ~= 'DW' and (a.main or a.sub) then
            local rest, wpn = {}, {};
            for k, v in pairs(a) do
                if k == 'main' or k == 'sub' then wpn[k] = v; else rest[k] = v; end
            end
            set_xml_lines(out, '        ', b.desc.name, rest);
            set_xml_lines(out, '        ', b.desc.name .. '_Weapons', wpn);
            actions.wsplit[b.desc.name] = true;
        else
            set_xml_lines(out, '        ', b.desc.name, b.assign);
        end
    end
    add('    </sets>');
    add('');

    -- Variables + toggle commands
    add('    <variables>');
    add('        <var name="Mode">normal</var>');
    add('        <var name="MB">off</var>');
    add('        <var name="TH">off</var>');
    if have.Refresh then add('        <var name="Refresh">off</var>'); end
    if have.DW then add('        <var name="DW">off</var>'); end
    if #jugs > 0 then add('        <var name="Jug">1</var>'); end
    add('    </variables>');
    add('');
    add('    <inputcommands>');
    local function toggle(cmd, var, on, label)
        add(string.format('        <cmd input="%s">', cmd));
        add(string.format('            <if advanced="$%s=%s">', var, on));
        add(string.format('                <setvar name="%s" value="%s" />', var, (var == 'Mode') and 'normal' or 'off'));
        add(string.format('                <addtochat color="167">%s: OFF</addtochat>', label));
        add('            </if>');
        add('            <else>');
        add(string.format('                <setvar name="%s" value="%s" />', var, on));
        add(string.format('                <addtochat color="158">%s: ON</addtochat>', label));
        add('            </else>');
        add('            <doidlegear />');
        add('        </cmd>');
    end
    if have.PDT then toggle('/pdt', 'Mode', 'pdt', 'PDT mode'); end
    if have.MDT then toggle('/mdt', 'Mode', 'mdt', 'MDT mode'); end
    if have.TP_Hybrid then toggle('/hybrid', 'Mode', 'hybrid', 'Hybrid TP mode'); end
    if have.Nuke_MB then toggle('/mb', 'MB', 'on', 'Magic Burst'); end
    if have.TH then toggle('/th', 'TH', 'on', 'Treasure Hunter'); end
    if have.Refresh then toggle('/refresh', 'Refresh', 'on', 'Refresh idle'); end
    if have.DW then toggle('/dw', 'DW', 'on', 'Dual wield weapons'); end
    if have.PetRanged and have.PetTank then toggle('/petranged', 'PetRanged', 'on', 'Automaton ranged gear (off = tank gear)'); end
    -- BST /jug: the next jug pet you own (used by Call Beast / Bestial Loyalty)
    if #jugs > 0 then
        add('        <cmd input="/jug">');
        local chain = {};
        for i, n in ipairs(jugs) do
            local nxt = (i % #jugs) + 1;
            table.insert(chain, { cond = attr('advanced', '$Jug=' .. i), body = function(o, ind)
                table.insert(o, string.format('%s<setvar name="Jug" value="%d" />', ind, nxt));
                table.insert(o, string.format('%s<addtochat color="158">Jug: %s</addtochat>', ind, xml_escape(jugs[nxt])));
            end });
        end
        emit_chain(out, '            ', chain, nil);
        add('        </cmd>');
    end
    -- /idle: every mode back to normal (no PDT / MDT / Hybrid / Refresh)
    add('        <cmd input="/idle">');
    add('            <setvar name="Mode" value="normal" />');
    if have.Refresh then add('            <setvar name="Refresh" value="off" />'); end
    add('            <addtochat color="158">Mode: normal</addtochat>');
    add('            <doidlegear />');
    add('        </cmd>');
    -- /warp: Instant Warp scroll if you have one, otherwise Warp Ring (needs the YunaGearOpt addon loaded)
    add('        <cmd input="/warp">');
    add('            <gearlock length="25" />');
    add('            <command>/ygo warp</command>');
    add('        </cmd>');
    add('    </inputcommands>');
    add('');

    -- Idle / engaged / resting
    add('    <idlegear>');
    local engaged = {};
    if have.PDT then table.insert(engaged, { cond = 'advanced="$Mode=pdt"', body = equip_set('PDT') }); end
    if have.MDT then table.insert(engaged, { cond = 'advanced="$Mode=mdt"', body = equip_set('MDT') }); end
    if have.TP_Hybrid then table.insert(engaged, { cond = 'advanced="$Mode=hybrid"', body = equip_set('TP_Hybrid') }); end
    local tp_body = have.TP and function(o, i)
        equip_set('TP')(o, i);
        if have.TH then emit_chain(o, i, { { cond = 'advanced="$TH=on"', body = equip_set('TH') } }, nil); end
    end or (have.Idle and equip_set('Idle'));
    local idle_branches = {};
    if have.PDT then table.insert(idle_branches, { cond = 'advanced="$Mode=pdt"', body = equip_set('PDT') }); end
    if have.MDT then table.insert(idle_branches, { cond = 'advanced="$Mode=mdt"', body = equip_set('MDT') }); end
    if have.Refresh then table.insert(idle_branches, { cond = 'advanced="$Refresh=on"', body = equip_set('Refresh') }); end
    if have.Idle_Avatar then table.insert(idle_branches, { cond = attr('pet_active', 'true'), body = equip_set('Idle_Avatar') }); end
    -- PUP: automaton out -> its gear (tank, or ranged while /petranged is on)
    if have.PetTank or have.PetRanged then
        table.insert(idle_branches, { cond = attr('pet_active', 'true'), body = function(o, i)
            if have.PetTank and have.PetRanged then
                emit_chain(o, i, { { cond = 'advanced="$PetRanged=on"', body = equip_set('PetRanged') } }, equip_set('PetTank'));
            else
                equip_set(have.PetTank and 'PetTank' or 'PetRanged')(o, i);
            end
        end });
    end
    -- A set tied to a buff (Counterstance) is worn on top of your engaged gear for as long as the buff is up
    local function buff_overlays(o, i)
        for _, b in ipairs(built) do
            if b.desc.engaged_buff then
                emit_chain(o, i, { { cond = attr('buffactive', b.desc.engaged_buff), body = equip_set(b.desc.name) } }, nil);
            end
        end
    end
    local top = {};
    if tp_body then
        table.insert(top, { cond = attr('p_status', 'engaged'), body = function(o, i)
            emit_chain(o, i, engaged, tp_body);
            buff_overlays(o, i);
        end });
    end
    if have.Resting then table.insert(top, { cond = attr('p_status', 'resting'), body = equip_set('Resting') }); end
    emit_chain(out, '        ', top, have.Idle and function(o, i)
        emit_chain(o, i, idle_branches, equip_set('Idle'));
        if have.Sublimation then
            emit_chain(o, i, { { cond = attr('buffactive', 'Sublimation: Activated'), body = equip_set('Sublimation') } }, nil);
        end
        for _, b in ipairs(built) do                     -- buff sets that apply engaged or not (THF Trick Attack)
            if b.desc.engaged_buff and b.desc.buff_any then
                emit_chain(o, i, { { cond = attr('buffactive', b.desc.engaged_buff), body = equip_set(b.desc.name) } }, nil);
            end
        end
        if have.Movement then
            table.insert(o, i .. '<!-- Running: movement speed gear -->');
            emit_chain(o, i, { { cond = attr('p_ismoving', 'true'), body = equip_set('Movement') } }, nil);
            if have.DesertBoots then
                table.insert(o, i .. '<!-- Running in earth weather: Desert Boots -->');
                emit_chain(o, i, { { cond = attr('p_ismoving', 'true'), body = function(o2, i2)
                    emit_chain(o2, i2, { { cond = attr('e_weather', 'Earth*'), body = equip_set('DesertBoots') } }, nil);
                end } }, nil);
            end
        end
    end or nil);
    if have.DW then
        add('        <!-- /dw ON: your dual-wield weapons on top of whatever set is active -->');
        emit_chain(out, '        ', { { cond = 'advanced="$DW=on"', body = equip_set('DW') } }, nil);
    end
    add('    </idlegear>');
    add('');

    -- Precast
    if have.Precast or have.Precast_Cure or have.Precast_Song then
        add('    <premagic>');
        local b = {};
        if have.Precast_Cure then table.insert(b, { cond = attr('ad_name', R.cure), body = equip_set('Precast_Cure') }); end
        if have.Precast_Song then table.insert(b, { cond = attr('ad_type', 'bardsong'), body = equip_set('Precast_Song') }); end
        emit_chain(out, '        ', b, have.Precast and equip_set('Precast') or nil);
        if have.Breath and R.breath_spells then
            add('        <!-- Spells that make the wyvern breathe: breath trigger piece on top -->');
            emit_chain(out, '        ', { { cond = attr('ad_name', R.breath_spells), body = equip_set('Breath') } }, nil);
        end
        add('    </premagic>');
        add('');
    end

    -- Midcast
    local m = {};
    local function pick(a, b2) return have[a] and a or (have[b2] and b2 or nil); end
    if have.Cure then table.insert(m, { cond = attr('ad_name', R.cure), body = with_obi('Cure', obis, 'light') }); end
    if have.Stoneskin then table.insert(m, { cond = attr('ad_name', 'Stoneskin'), body = equip_set('Stoneskin') }); end
    if have.Healing then table.insert(m, { cond = attr('ad_skill', 'healingmagic'), body = equip_set('Healing') }); end
    if have.Enhancing then table.insert(m, { cond = attr('ad_skill', 'enhancingmagic'), body = equip_set('Enhancing') }); end
    if have.Enfeebling_MND or have.Enfeebling_INT then
        local mnd, int = pick('Enfeebling_MND', 'Enfeebling_INT'), pick('Enfeebling_INT', 'Enfeebling_MND');
        table.insert(m, { cond = attr('ad_skill', 'enfeeblingmagic'), body = function(o, i)
            emit_chain(o, i, { { cond = attr('ad_name', R.enfeebling_mnd), body = equip_set(mnd) } }, equip_set(int));
        end });
    end
    if have.Divine then table.insert(m, { cond = attr('ad_skill', 'divinemagic'), body = with_obi('Divine', obis, 'light') }); end
    if have.Nuke or have.Nuke_MB or have.MagicAcc then
        local nuke = pick('Nuke', 'Nuke_MB') or 'MagicAcc';
        table.insert(m, { cond = attr('ad_skill', 'elementalmagic'), body = function(o, i)
            local b = {};
            if have.MagicAcc then table.insert(b, { cond = attr('ad_name', R.elemental_dot), body = equip_set('MagicAcc') }); end
            if have.Nuke_MB then table.insert(b, { cond = 'advanced="$MB=on"', body = with_obi('Nuke_MB', obis) }); end
            emit_chain(o, i, b, with_obi(nuke, obis));
        end });
    end
    if have.Dark or have.DrainAspir then
        table.insert(m, { cond = attr('ad_skill', 'darkmagic'), body = function(o, i)
            local b = {};
            if have.DrainAspir then table.insert(b, { cond = attr('ad_name', R.drain_aspir), body = with_obi('DrainAspir', obis, 'dark') }); end
            emit_chain(o, i, b, have.Dark and equip_set('Dark') or nil);
        end });
    end
    if have.Ninjutsu then table.insert(m, { cond = attr('ad_skill', 'ninjutsu'), body = with_obi('Ninjutsu', obis) }); end
    if have.Songs_Buff or have.Songs_Debuff then
        local buff, debuff = pick('Songs_Buff', 'Songs_Debuff'), pick('Songs_Debuff', 'Songs_Buff');
        table.insert(m, { cond = attr('ad_skill', 'singing'), body = function(o, i)
            emit_chain(o, i, { { cond = attr('ad_name', R.song_debuff), body = equip_set(debuff) } }, equip_set(buff));
        end });
    end
    if have.Precast and (data.utsusemi_precast or {})[abbr] then
        table.insert(m, { cond = attr('ad_name', 'Utsusemi*'), body = equip_set('Precast') });
    end
    if have.BlueMagic then table.insert(m, { cond = attr('ad_skill', 'bluemagic'), body = equip_set('BlueMagic') }); end
    if have.Geomancy then table.insert(m, { cond = attr('ad_skill', 'geomancy'), body = equip_set('Geomancy') }); end
    -- Spells with their own set (Flash, Reprisal, Phalanx) come before the magic-skill rules
    for i, p in ipairs(spell_set_list(have)) do
        table.insert(m, i, { cond = attr('ad_name', p[1]), body = equip_set(p[2]) });
    end
    local base_mid = job_base(data.midcast_base, abbr, have);
    if #m > 0 or base_mid then
        add('    <midmagic>');
        if base_mid then
            add('        <!-- Every spell: ' .. base_mid .. ' first, then the spell\'s own set on top -->');
            add(string.format('        <equip set="%s" />', base_mid));
        end
        emit_chain(out, '        ', m, nil);
        add('    </midmagic>');
        add('');
    end

    -- Weaponskills
    local ws_b, has_default = {}, have.WS ~= nil;
    for _, b in ipairs(built) do
        if b.desc.kind == 'ws' and b.desc.id ~= 'WS' then
            local cond = b.desc.ws.id and attr('ad_id', b.desc.ws.id) or attr('ad_name', b.desc.ws.name);
            table.insert(ws_b, { cond = cond, body = equip_set(b.desc.name) });
            ws_b[#ws_b].comment = b.desc.ws.name;
        end
    end
    if #ws_b > 0 or has_default then
        add('    <weaponskill>');
        emit_chain(out, '        ', ws_b, has_default and equip_set('WS') or nil);
        if have.MightyStrikes then
            local ms = have.MightyStrikes;
            local ids = ws_ids_for(ms.ws_only);
            local strs = {};
            for _, id in ipairs(ids) do table.insert(strs, tostring(id)); end
            add('        <!-- Mighty Strikes active: ' .. xml_escape(table.concat(ms.ws_only or {}, ', ')) .. ' -->');
            emit_chain(out, '        ', { { cond = attr('buffactive', 'Mighty Strikes'), body = function(o, i)
                if #strs > 0 then
                    emit_chain(o, i, { { cond = attr('ad_id', table.concat(strs, '|')), body = equip_set('MightyStrikes') } }, nil);
                else
                    equip_set('MightyStrikes')(o, i);
                end
            end } }, nil);
        end
        add('    </weaponskill>');
        add('');
    end

    -- Ranged
    local gun = gun_name_for(abbr);
    local function ranged_block(tag, base)
        if not have[base] then return; end
        add('    <' .. tag .. '>');
        if have[base .. '_Gun'] and gun then
            emit_chain(out, '        ', { { cond = attr('eq_range', gun), body = equip_set(base .. '_Gun') } }, equip_set(base));
        else
            equip_set(base)(out, '        ');
        end
        add('    </' .. tag .. '>');
        add('');
    end
    ranged_block('preranged', 'Preshot');
    ranged_block('midranged', 'Midshot');

    -- Job abilities
    local ja = {};
    if have.Waltz then table.insert(ja, { cond = attr('ad_type', 'waltz'), body = equip_set('Waltz') }); end
    if have.QuickDraw then table.insert(ja, { cond = attr('ad_type', 'quickdraw'), body = equip_set('QuickDraw') }); end
    if have.BP_Delay then table.insert(ja, { cond = attr('ad_type', 'bloodpactrage|bloodpactward'), body = equip_set('BP_Delay') }); end
    for _, p in ipairs(ja_list(built)) do
        table.insert(ja, { cond = attr('ad_name', p[1]), body = equip_set(p[2]) });
    end
    for _, b in ipairs(built) do
        if b.desc.sp_ability then
            table.insert(ja, { cond = attr('ad_name', b.desc.sp_ability), body = equip_set(b.desc.name) });
        end
    end
    if have.PhantomRoll then
        table.insert(ja, { cond = attr('ad_type', 'corsairroll'), body = equip_set('PhantomRoll') });
        table.insert(ja, { cond = attr('ad_name', 'Double-Up'), body = equip_set('PhantomRoll') });
    end
    local base_ja = job_base(data.ability_base, abbr, have);
    if #ja > 0 or base_ja or #jugs > 0 then
        add('    <jobability>');
        if base_ja then
            add('        <!-- Every ability: ' .. base_ja .. ' first, then the ability\'s own pieces on top -->');
            add(string.format('        <equip set="%s" />', base_ja));
        end
        emit_chain(out, '        ', ja, nil);
        -- BST: the jug you chose with /jug goes in the ammo slot for Call Beast / Bestial Loyalty
        if #jugs > 0 then
            add(string.format('        <if %s>', attr('ad_name', 'Call Beast|Bestial Loyalty')));
            for i, n in ipairs(jugs) do
                add(string.format('            <if %s><equip><ammo>%s</ammo></equip></if>', attr('advanced', '$Jug=' .. i), xml_escape(n)));
            end
            add('        </if>');
        end
        add('    </jobability>');
        add('');
    end

    local pet_b = {};
    if have.BloodPact then table.insert(pet_b, { cond = attr('ad_type', 'bloodpactrage|bloodpactward'), body = equip_set('BloodPact') }); end
    if have.BreathPotency and R.pet_breath then table.insert(pet_b, { cond = attr('ad_name', R.pet_breath), body = equip_set('BreathPotency') }); end
    if #pet_b > 0 or have.Ready then
        add('    <petskill>');
        -- BST: any other pet move (Ready / Sic) wears the Ready set
        emit_chain(out, '        ', pet_b, have.Ready and equip_set('Ready') or nil);
        add('    </petskill>');
    end

    add('</ashitacast>');

    -- Pieces stored in bags LegacyAC can't equip from
    local stored = {};
    for _, b in ipairs(built) do
        for _, c in pairs(b.assign) do
            if not EQUIP_BAGS[c.item.where] then stored[c.item.name .. ' (' .. c.item.where .. ')'] = true; end
        end
    end
    for _, o in pairs(obis) do if not EQUIP_BAGS[o.where] then stored[o.name .. ' (' .. o.where .. ')'] = true; end end

    actions.wsplit, actions.wpair = nil, nil;
    return table.concat(out, '\n') .. '\n', #built, stored;
end

local function write_file(path, text)
    local f, err = io.open(path, 'w');
    if f == nil then return false, err; end
    f:write(text);
    f:close();
    return true;
end

-- Make sure an export folder exists (shipped in the zip, but recreated if someone deleted it)
local function ensure_dir(dir)
    local probe = dir .. '.ygo_probe';
    local f = io.open(probe, 'w');
    if f then f:close(); os.remove(probe); return true; end
    for _, fn in ipairs({ 'create_directory', 'create_dir' }) do
        if ashita.fs and ashita.fs[fn] then
            local ok = pcall(ashita.fs[fn], dir);
            if ok then return true; end
        end
    end
    pcall(os.execute, 'mkdir "' .. dir:gsub('[\\/]+$', '') .. '"');
    return true;
end

-- Overwrite an export. If the file there wasn't made by YunaGearOpt (your hand-made XML/Lua), it's backed up
-- once first as NAME_backup_<date>.ext. Files YunaGearOpt made are simply overwritten every time.
local function write_export(dir, fname, text)
    local path = dir .. fname;
    local backup = nil;
    local f = io.open(path, 'r');
    if f then
        local old = f:read('*a');
        f:close();
        if not old:find('Generated by YunaGearOpt', 1, true) then
            local base, ext = fname:match('^(.*)(%.[^%.]+)$');
            backup = (base or fname) .. '_backup_' .. os.date('%Y%m%d_%H%M%S') .. (ext or '');
            if not write_file(dir .. backup, old) then backup = nil; end
        end
    end
    return write_file(path, text), backup;
end

-- Export folders inside the addon: legacyac\ for XML, gearswap\ for Lua
local function export_dir(kind)
    local dir = base_path() .. kind .. '\\';
    ensure_dir(dir);
    return dir;
end

local function export_full()
    local abbr = JOBS[ui.job];
    local xml, count, stored = build_full_xml(ui.job);
    local fname = string.format('%s_%s.xml', player_name(), abbr);
    imgui.SetClipboardText(xml);

    local saved, backups = {}, {};
    local okA = write_export(export_dir('legacyac'), fname, xml);
    if okA then table.insert(saved, 'addons\\yunagearopt\\legacyac\\' .. fname); end
    local install = '';
    pcall(function() install = AshitaCore:GetInstallPath(); end);
    local failed = nil;
    if install ~= '' then
        -- LegacyAC reads only from config\LegacyAC: create it first (it doesn't exist if LegacyAC was never used)
        local dir = install:gsub('[\\/]+$', '') .. '\\config\\LegacyAC\\';
        ensure_dir(dir);
        local ok, bak = write_export(dir, fname, xml);
        if ok then table.insert(saved, 'config\\LegacyAC\\' .. fname); else failed = dir; end
        if bak then table.insert(backups, 'config\\LegacyAC\\' .. bak); end
    end

    msg(string.format('%s XML exported: %d sets (also copied to clipboard).', abbr, count));
    for _, p in ipairs(saved) do msg('  Saved: ' .. p); end
    if failed then
        msg('  Could not save into ' .. failed .. ' - LegacyAC reads only from there.');
        msg('  Copy ' .. fname .. ' from addons\\yunagearopt\\legacyac\\ into that folder, then type /la load');
    end
    for _, b in ipairs(backups) do msg('  Your hand-made ' .. fname .. ' was kept as: ' .. b); end
    local list = {};
    for k in pairs(stored) do table.insert(list, k); end
    if #list > 0 then
        table.sort(list);
        msg('  Move these to Inventory/Wardrobe so LegacyAC can equip them: ' .. table.concat(list, ', '));
    end
end


----------------------------------------------------------------------------------------------------
-- GearSwap export (Windower: addons/GearSwap/data/CharacterName_JOB.lua)
----------------------------------------------------------------------------------------------------
local GS_SLOT = { main = 'main', sub = 'sub', range = 'range', ammo = 'ammo', head = 'head', neck = 'neck',
    ear1 = 'left_ear', ear2 = 'right_ear', body = 'body', hands = 'hands', ring1 = 'left_ring', ring2 = 'right_ring',
    back = 'back', waist = 'waist', legs = 'legs', feet = 'feet' };
local GS_ELEMENT = { fire = 'Fire', ice = 'Ice', wind = 'Wind', earth = 'Earth', thunder = 'Lightning',
    water = 'Water', light = 'Light', dark = 'Dark' };

-- "Cure*|Cura*" -> { "^Cure", "^Cura" }  (LegacyAC wildcards to Lua patterns)
local function wild_to_patterns(rule)
    local list = {};
    for part in (rule or ''):gmatch('[^|]+') do
        local starts, ends = part:sub(1, 1) ~= '*', part:sub(-1) ~= '*';
        local core = part:gsub('^%*', ''):gsub('%*$', '');
        core = core:gsub('([%^%$%(%)%%%.%[%]%+%-%?])', '%%%1'):gsub('%*', '.*');
        table.insert(list, (starts and '^' or '') .. core .. (ends and '$' or ''));
    end
    return list;
end

local function lua_list(list)
    local parts = {};
    for _, v in ipairs(list) do table.insert(parts, string.format('%q', v)); end
    return '{ ' .. table.concat(parts, ', ') .. ' }';
end

local function gs_name(name)
    local map = data.gs_names or {};
    for k, v in pairs(map) do if k:lower() == name:lower() then return v; end end
    return name;
end

local function build_gearswap(job_id)
    local abbr = JOBS[job_id];
    local built, have = {}, {};
    for _, desc in ipairs(build_sets(job_id)) do
        local assign = optimize(job_id, desc, ui.pins[abbr .. '|' .. desc.id] or {});
        if next(assign) ~= nil then
            table.insert(built, { desc = desc, assign = assign });
            have[desc.name] = true;
        end
    end
    local R, obis = data.rules or {}, owned_obis();
    local jugs = (abbr == 'BST') and actions.owned_jugs(job_id) or {};
    have.__jugs = #jugs > 0;
    local o = {};
    local function add(line) table.insert(o, line); end

    add(string.format('-- Generated by YunaGearOpt %s for %s (%s) on %s from the gear you own.', addon.version, player_name(), abbr, os.date('%Y-%m-%d %H:%M')));
    add('-- Put this file in Windower/addons/GearSwap/data/ as ' .. player_name() .. '_' .. abbr .. '.lua');
    add('-- Commands (type them like normal commands): ' .. table.concat((function() local _, c = actions.slash_cmds(have); local o = {}; for _, x in ipairs(c) do table.insert(o, '/' .. x); end; return o; end)(), ' ') .. ' /warp');
    add('--   (or //gs c pdt, //gs c idle ... the same toggles)');
    if abbr == 'PUP' then add('-- PUP: while the automaton is out you wear its gear; //gs c petranged switches tank / ranged gear'); end
    add('');
    add('function get_sets()');
    add('    sets = {}');
    add('');
    for _, b in ipairs(built) do
        add(string.format('    -- %s', b.desc.label));
        local parts, covered = {}, covered_slots(b.assign);
        for _, def in ipairs(SLOTS) do
            local c = b.assign[def.key];
            if covered[def.key] then
                table.insert(parts, string.format('        %s = empty,', GS_SLOT[def.key]));
            elseif c then
                table.insert(parts, string.format('        %s = %q,', GS_SLOT[def.key], gs_name(c.item.name)));
            end
        end
        add(string.format('    sets[%q] = {', b.desc.name));
        for _, p in ipairs(parts) do add(p); end
        add('    }');
    end
    add('');
    add('    -- Weaponskill id -> set name (ids are the same in every client language)');
    add('    ws_map = {');
    for _, b in ipairs(built) do
        if b.desc.kind == 'ws' and b.desc.ws and b.desc.ws.id then
            add(string.format('        [%d] = %q, -- %s', b.desc.ws.id, b.desc.name, b.desc.ws.name));
        end
    end
    add('    }');
    add('');
    add('    -- RNG: the gun tells Preshot / Midshot apart from the bow versions');
    add('    gun_range = ' .. (gun_name_for(abbr) and string.format('%q', gun_name_for(abbr)) or 'nil'));
    add('');
    add('    -- Sets worn on top of TP while a buff is active (e.g. Counterstance)');
    add('    engaged_buffs = {');
    for _, b in ipairs(built) do
        if b.desc.engaged_buff then add(string.format('        { buff = %q, set = %q, always = %s },', b.desc.engaged_buff, b.desc.name, tostring(b.desc.buff_any == true))); end
    end
    add('    }');
    add('');
    add('    -- Job abilities that wear their own set');
    add('    ja_map = {');
    for _, p in ipairs(ja_list(built)) do add(string.format('        [%q] = %q,', p[1], p[2])); end
    add('    }');
    add('');
    add('    -- 2-hour (SP ability) -> Summit set');
    add('    sp_map = {');
    for _, b in ipairs(built) do
        if b.desc.sp_ability then add(string.format('        [%q] = %q,', b.desc.sp_ability, b.desc.name)); end
    end
    add('    }');
    add('');
    add('    -- Elemental obis you own (worn when weather, day or a storm buff matches the spell element)');
    add('    obis = {');
    local els = {};
    for e in pairs(obis) do table.insert(els, e); end
    table.sort(els);
    for _, e in ipairs(els) do
        add(string.format('        [%q] = { obi = %q, storm = %q },', GS_ELEMENT[e], gs_name(obis[e].name), obis[e].storm));
    end
    add('    }');
    add('');
    add('    rules = {');
    add('        cure        = ' .. lua_list(wild_to_patterns(R.cure)) .. ',');
    add('        enf_mnd     = ' .. lua_list(wild_to_patterns(R.enfeebling_mnd)) .. ',');
    add('        ele_dot     = ' .. lua_list(wild_to_patterns(R.elemental_dot)) .. ',');
    add('        drain_aspir = ' .. lua_list(wild_to_patterns(R.drain_aspir)) .. ',');
    add('        song_debuff = ' .. lua_list(wild_to_patterns(R.song_debuff)) .. ',');
    add('        breath = ' .. lua_list(wild_to_patterns(R.breath_spells)) .. ',');
    add('        pet_breath = ' .. lua_list(wild_to_patterns(R.pet_breath)) .. ',');
    add('    }');
    add('    utsusemi_precast = ' .. tostring((data.utsusemi_precast or {})[abbr] == true));
    add('');
    add('    -- Spells with their own midcast set, and the base set worn first for every spell / ability (tanks)');
    add('    spell_sets = {');
    for _, p in ipairs(spell_set_list(have)) do
        add(string.format('        { pats = %s, set = %q },', lua_list(wild_to_patterns(p[1])), p[2]));
    end
    add('    }');
    local bm, ba = job_base(data.midcast_base, abbr, have), job_base(data.ability_base, abbr, have);
    add('    midcast_base = ' .. (bm and string.format('%q', bm) or 'nil'));
    add('    ability_base = ' .. (ba and string.format('%q', ba) or 'nil'));
    add('    -- With /NIN or /DNC: your dual-wield pair instead of a set\'s weapons (none picked = weapons left alone)');
    add('    weapon_auto = ' .. tostring(s.weapon_mode == 1 and in_list(data.weapon_jobs, abbr)));
    local gpair = (s.weapon_mode == 1 and in_list(data.weapon_jobs, abbr)) and actions.dw_pair(abbr) or nil;
    add('    dw_pair = ' .. (gpair and string.format('{ main = %q, sub = %q }', gs_name(gpair.main or ''), gs_name(gpair.sub or '')) or 'nil')
        .. '   -- worn instead of a set\'s weapons with /NIN or /DNC');
    add('');
    local prc = data.phalanx_received;
    local function id_set(ids)
        local parts = {};
        for _, id in ipairs(ids or {}) do table.insert(parts, string.format('[%d] = true', id)); end
        return '{ ' .. table.concat(parts, ', ') .. ' }';
    end
    add('    -- Phalanx cast on you: wear this set for a few seconds (Phalanx II aimed at you / Phalanx from a party member)');
    add('    phalanx_set = ' .. ((prc and have[prc.set]) and string.format('%q', prc.set) or 'nil'));
    add('    phalanx_single, phalanx_party = ' .. id_set(prc and prc.single) .. ', ' .. id_set(prc and prc.party));
    add(string.format('    phalanx_single_time, phalanx_party_time, phalanx_until = %d, %d, 0',
        (prc and prc.single_time) or 5, (prc and prc.party_time) or 8));
    add('');
    local ms_line = {};
    for _, b in ipairs(built) do
        if b.desc.id == 'MightyStrikes' then
            for _, id in ipairs(ws_ids_for(b.desc.ws_only)) do table.insert(ms_line, string.format('[%d] = true', id)); end
        end
    end
    add('    -- Weaponskills that use the MightyStrikes set while Mighty Strikes is active');
    add('    ms_ws = { ' .. table.concat(ms_line, ', ') .. ' }');
    add('');
    add('    -- Toggles you can type as /pdt, /mdt, /hybrid, /idle... (they run //gs c <name>)');
    add('    slash_cmds = ' .. actions.slash_cmds(have));
    add("    Mode, MB, TH, Moving, RefreshOn, DWOn = 'normal', false, false, false, false, false");
    add("    PetRangedOn = false   -- PUP: //gs c petranged switches the automaton gear between tank and ranged");
    add('    -- BST: your jug pets; /jug picks the one Call Beast / Bestial Loyalty puts in the ammo slot');
    add('    jugs, JugIdx = ' .. actions.jug_literal(jugs) .. ', 1');
    for _, b in ipairs(built) do
        if b.desc.lockstyle then
            add('');
            add('    -- Lockstyle: a few seconds after this file loads (login / job change), wear your look and lock it');
            add("    send_command('wait 3; gs equip sets.Lockstyle; wait 2; input /lockstyle on')");
        end
    end
    add('end');
    add('');
    add([[
local function matches(name, list)
    for _, p in ipairs(list or {}) do
        if name:match(p) then return true end
    end
    return false
end

local function eq(name)
    local set = sets[name]
    if not set then return false end
    -- With /NIN or /DNC (dual wield): your dual-wield pair instead of the set's weapons, or your weapons stay
    if weapon_auto and name ~= 'DW' and (player.sub_job == 'NIN' or player.sub_job == 'DNC') then
        local copy, had = {}, false
        for k, v in pairs(set) do
            if k ~= 'main' and k ~= 'sub' then copy[k] = v else had = true end
        end
        if had and dw_pair then
            if dw_pair.main ~= '' then copy.main = dw_pair.main end
            if dw_pair.sub ~= '' then copy.sub = dw_pair.sub end
        end
        set = copy
    end
    equip(set)
    return true
end

local function obi(element)
    local o = obis[element]
    if o and (world.weather_element == element or world.day_element == element or buffactive[o.storm]) then
        equip({ waist = o.obi })
    end
end

-- Gun or bow? (RNG) The Preshot / Midshot set follows the ranged weapon you have equipped
local function ranged_set(base)
    local r = player.equipment and player.equipment.range
    if gun_range and r == gun_range and sets[base .. '_Gun'] then return base .. '_Gun' end
    return base
end

function idle_gear()
    if player.status == 'Engaged' then
        if Mode == 'pdt' and eq('PDT') then
        elseif Mode == 'mdt' and eq('MDT') then
        elseif Mode == 'hybrid' and eq('TP_Hybrid') then
        elseif not eq('TP') then eq('Idle')
        end
        if TH then eq('TH') end
        for _, eb in ipairs(engaged_buffs) do
            if buffactive[eb.buff] then eq(eb.set) end
        end
    elseif player.status == 'Resting' and sets['Resting'] then
        eq('Resting')
    else
        if Mode == 'pdt' and eq('PDT') then
        elseif Mode == 'mdt' and eq('MDT') then
        elseif RefreshOn and eq('Refresh') then
        elseif pet.isvalid and eq('Idle_Avatar') then
        elseif pet.isvalid and PetRangedOn and eq('PetRanged') then
        elseif pet.isvalid and eq('PetTank') then
        else eq('Idle')
        end
        if buffactive['Sublimation: Activated'] then eq('Sublimation') end
        for _, eb in ipairs(engaged_buffs) do
            if eb.always and buffactive[eb.buff] then eq(eb.set) end
        end
        if Moving then eq('Movement') end
        if Moving and world.weather_element == 'Earth' then eq('DesertBoots') end
    end
    if DWOn then eq('DW') end
    if phalanx_set and os.clock() < phalanx_until then eq(phalanx_set) end
end

-- Phalanx received (logic from phalanx.lua): when a Phalanx starts on you, wear phalanx_set for a few seconds
local function in_party(id)
    local p = windower.ffxi.get_party()
    for _, k in ipairs({ 'p0', 'p1', 'p2', 'p3', 'p4', 'p5' }) do
        if p and p[k] and p[k].mob and p[k].mob.id == id then return true end
    end
    return false
end

windower.raw_register_event('action', function(act)
    if not phalanx_set or not sets[phalanx_set] then return end
    local me = windower.ffxi.get_player()
    if not me then return end
    for _, t in ipairs(act.targets or {}) do
        for _, a in ipairs(t.actions or {}) do
            if a.message == 3 or a.message == 327 then
                local hold = nil
                if phalanx_single[a.param] and t.id == me.id then hold = phalanx_single_time
                elseif phalanx_party[a.param] and in_party(act.actor_id) then hold = phalanx_party_time end
                if hold then
                    phalanx_until = os.clock() + hold
                    windower.send_command('gs c _phalanx; wait ' .. (hold + 0.2) .. '; gs c _phalanx')
                    return
                end
            end
        end
    end
end)

-- Typing /warp, /pdt, /mdt, /hybrid, /idle... runs the toggle (gs c <name>)
windower.raw_register_event('outgoing text', function(original)
    local c = original:lower():match('^/(%a+)%s*$')
    if c == 'warp' or (c and slash_cmds and slash_cmds[c]) then
        windower.send_command('gs c ' .. c)
        return true
    end
end)

-- Running detection: GearSwap has no "moving" flag, so check your position a few times a second
local last_pos, last_check = nil, 0
windower.raw_register_event('prerender', function()
    local now = os.clock()
    if now - last_check < 0.25 then return end
    last_check = now
    local me = windower.ffxi.get_mob_by_target('me')
    if not me then return end
    local moving = last_pos ~= nil and (math.abs(me.x - last_pos.x) + math.abs(me.y - last_pos.y)) > 0.1
    last_pos = { x = me.x, y = me.y }
    if moving ~= Moving then
        Moving = moving
        windower.send_command('gs c _moving')
    end
end)

function precast(spell)
    if ability_base and spell.type == 'JobAbility' then eq(ability_base) end
    if spell.type == 'WeaponSkill' then
        if not eq(ws_map[spell.id] or 'WS') then eq('WS') end
        if buffactive['Mighty Strikes'] and ms_ws[spell.id] then eq('MightyStrikes') end
    elseif spell.action_type == 'Magic' then
        if matches(spell.english, rules.cure) and eq('Precast_Cure') then
        elseif spell.type == 'BardSong' and eq('Precast_Song') then
        else eq('Precast')
        end
        if matches(spell.english, rules.breath) then eq('Breath') end
    elseif spell.action_type == 'Ranged Attack' then
        eq(ranged_set('Preshot'))
    elseif spell.type == 'CorsairRoll' or spell.english == 'Double-Up' then
        eq('PhantomRoll')
    elseif spell.type == 'CorsairShot' then
        eq('QuickDraw')
    elseif spell.type == 'Waltz' then
        eq('Waltz')
    elseif spell.type == 'BloodPactRage' or spell.type == 'BloodPactWard' then
        eq('BP_Delay')
    elseif sp_map[spell.english] then
        eq(sp_map[spell.english])
    elseif ja_map[spell.english] then
        eq(ja_map[spell.english])
    end
    if (spell.english == 'Call Beast' or spell.english == 'Bestial Loyalty') and jugs and jugs[JugIdx] then
        equip({ ammo = jugs[JugIdx] })
    end
end

function midcast(spell)
    if spell.action_type == 'Ranged Attack' then eq(ranged_set('Midshot')) return end
    if spell.action_type ~= 'Magic' then return end
    local name, skill = spell.english, spell.skill
    if midcast_base then eq(midcast_base) end
    if utsusemi_precast and name:match('^Utsusemi') and eq('Precast') then return end
    for _, ss in ipairs(spell_sets) do
        if matches(name, ss.pats) and eq(ss.set) then return end
    end
    if matches(name, rules.cure) and eq('Cure') then
        obi('Light')
    elseif name == 'Stoneskin' and eq('Stoneskin') then
    elseif skill == 'Healing Magic' then eq('Healing')
    elseif skill == 'Enhancing Magic' then eq('Enhancing')
    elseif skill == 'Enfeebling Magic' then
        if matches(name, rules.enf_mnd) then
            if not eq('Enfeebling_MND') then eq('Enfeebling_INT') end
        elseif not eq('Enfeebling_INT') then eq('Enfeebling_MND') end
    elseif skill == 'Divine Magic' then
        eq('Divine') obi('Light')
    elseif skill == 'Elemental Magic' then
        if matches(name, rules.ele_dot) and eq('MagicAcc') then
        elseif MB and eq('Nuke_MB') then obi(spell.element)
        else
            if not eq('Nuke') then eq('Nuke_MB') end
            obi(spell.element)
        end
    elseif skill == 'Dark Magic' then
        if matches(name, rules.drain_aspir) and eq('DrainAspir') then obi('Dark')
        else eq('Dark') end
    elseif skill == 'Ninjutsu' then
        eq('Ninjutsu') obi(spell.element)
    elseif skill == 'Singing' then
        if matches(name, rules.song_debuff) then
            if not eq('Songs_Debuff') then eq('Songs_Buff') end
        elseif not eq('Songs_Buff') then eq('Songs_Debuff') end
    elseif skill == 'Blue Magic' then eq('BlueMagic')
    elseif skill == 'Geomancy' then eq('Geomancy')
    end
end

function aftercast(spell) idle_gear() end

function pet_midcast(spell)
    if spell.type == 'BloodPactRage' or spell.type == 'BloodPactWard' then eq('BloodPact')
    elseif matches(spell.english, rules.pet_breath) then eq('BreathPotency')
    elseif sets['Ready'] then eq('Ready') end           -- BST: the pet's Ready / Sic move
end

function pet_aftercast(spell) idle_gear() end
function status_change(new, old) idle_gear() end

function buff_change(name, gain)
    if name == 'Sublimation: Activated' then idle_gear() end
    for _, eb in ipairs(engaged_buffs) do
        if name == eb.buff then idle_gear() end
    end
end

function self_command(command)
    local c = command:lower()
    if c == 'warp' then
        if player.inventory['Instant Warp'] then
            send_command('input /item "Instant Warp" <me>')
            add_to_chat(158, 'Warping with a Scroll of Instant Warp.')
            return
        end
        local bags = { 'inventory', 'wardrobe', 'wardrobe2', 'wardrobe3', 'wardrobe4', 'wardrobe5', 'wardrobe6', 'wardrobe7', 'wardrobe8' }
        for _, bag in ipairs(bags) do
            if player[bag] and player[bag]['Warp Ring'] then
                equip({ left_ring = 'Warp Ring' })
                disable('left_ring')
                add_to_chat(158, 'Warp Ring equipped - using it in 11 seconds.')
                send_command('wait 11; input /item "Warp Ring" <me>; wait 15; gs enable left_ring')
                return
            end
        end
        add_to_chat(167, 'No Scroll of Instant Warp in your inventory and no Warp Ring in Inventory/Wardrobes.')
        return
    end
    if c == '_moving' then
        if not midaction() and player.status ~= 'Engaged' then idle_gear() end
        return
    end
    if c == '_phalanx' then
        if not midaction() then idle_gear() end
        return
    end
    if c == 'pdt' or c == 'mdt' or c == 'hybrid' then
        Mode = (Mode == c) and 'normal' or c
        add_to_chat(158, 'Mode: ' .. Mode)
    elseif c == 'idle' then
        Mode, RefreshOn = 'normal', false
        add_to_chat(158, 'Mode: normal')
    elseif c == 'mb' then
        MB = not MB
        add_to_chat(158, 'Magic Burst: ' .. (MB and 'ON' or 'OFF'))
    elseif c == 'th' then
        TH = not TH
        add_to_chat(158, 'Treasure Hunter: ' .. (TH and 'ON' or 'OFF'))
    elseif c == 'refresh' then
        RefreshOn = not RefreshOn
        add_to_chat(158, 'Refresh idle: ' .. (RefreshOn and 'ON' or 'OFF'))
    elseif c == 'petranged' then
        PetRangedOn = not PetRangedOn
        add_to_chat(158, 'Automaton gear: ' .. (PetRangedOn and 'RANGED' or 'TANK'))
    elseif c == 'jug' then
        if jugs == nil or #jugs == 0 then add_to_chat(167, 'No jug pets in your bags.') return end
        JugIdx = JugIdx % #jugs + 1
        add_to_chat(158, 'Jug: ' .. jugs[JugIdx])
        return
    elseif c == 'dw' then
        DWOn = not DWOn
        add_to_chat(158, 'Dual wield weapons: ' .. (DWOn and 'ON' or 'OFF'))
    end
    idle_gear()
end]]);
    return table.concat(o, '\n') .. '\n', #built;
end

local function export_gearswap()
    local abbr = JOBS[ui.job];
    local text, count = build_gearswap(ui.job);
    local fname = string.format('%s_%s.lua', player_name(), abbr);
    imgui.SetClipboardText(text);
    local ok = write_export(export_dir('gearswap'), fname, text);
    msg(string.format('%s GearSwap file exported: %d sets (also copied to clipboard).', abbr, count));
    if ok then msg('  Saved: addons\\yunagearopt\\gearswap\\' .. fname); end
    msg('  Copy it to Windower\\addons\\GearSwap\\data\\' .. fname);
end

----------------------------------------------------------------------------------------------------
-- LuAshitacast export (Ashita: config/addons/luashitacast/CharName_CharId/JOB.lua)
----------------------------------------------------------------------------------------------------
local LAC_SLOT = { main = 'Main', sub = 'Sub', range = 'Range', ammo = 'Ammo', head = 'Head', neck = 'Neck',
    ear1 = 'Ear1', ear2 = 'Ear2', body = 'Body', hands = 'Hands', ring1 = 'Ring1', ring2 = 'Ring2',
    back = 'Back', waist = 'Waist', legs = 'Legs', feet = 'Feet' };
local LAC_ELEMENT = { fire = 'Fire', ice = 'Ice', wind = 'Wind', earth = 'Earth', thunder = 'Thunder',
    water = 'Water', light = 'Light', dark = 'Dark' };

local function player_server_id()
    local ok, id = pcall(function() return AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0); end);
    return (ok and id) or 0;
end

local function build_lac(job_id)
    local abbr = JOBS[job_id];
    local built, have = {}, {};
    for _, desc in ipairs(build_sets(job_id)) do
        local assign = optimize(job_id, desc, ui.pins[abbr .. '|' .. desc.id] or {});
        if next(assign) ~= nil then
            table.insert(built, { desc = desc, assign = assign });
            have[desc.name] = true;
        end
    end
    local R, obis = data.rules or {}, owned_obis();
    local jugs = (abbr == 'BST') and actions.owned_jugs(job_id) or {};
    have.__jugs = #jugs > 0;
    local o = {};
    local function add(line) table.insert(o, line); end

    add(string.format('-- Generated by YunaGearOpt %s for %s (%s) on %s from the gear you own.', addon.version, player_name(), abbr, os.date('%Y-%m-%d %H:%M')));
    add('-- LuAshitacast profile. Location: Ashita/config/addons/luashitacast/' .. player_name() .. '_' .. player_server_id() .. '/' .. abbr .. '.lua');
    add('-- Commands (type them like normal commands): ' .. table.concat((function() local _, c = actions.slash_cmds(have); local o = {}; for _, x in ipairs(c) do table.insert(o, '/' .. x); end; return o; end)(), ' ') .. ' /warp');
    add('--   (or /lac fwd pdt, /lac fwd idle ... the same toggles)');
    if abbr == 'PUP' then add('-- PUP: while the automaton is out you wear its gear; /lac fwd petranged switches tank / ranged gear'); end
    add('');
    add('local profile = {};');
    add('');
    add('local sets = {');
    for _, b in ipairs(built) do
        add(string.format('    -- %s', b.desc.label));
        add(string.format('    [%q] = {', b.desc.name));
        local covered = covered_slots(b.assign);
        for _, def in ipairs(SLOTS) do
            local c = b.assign[def.key];
            if covered[def.key] then
                add(string.format('        %s = \'displaced\',', LAC_SLOT[def.key]));
            elseif c then
                add(string.format('        %s = %q,', LAC_SLOT[def.key], c.item.name));
            end
        end
        add('    },');
    end
    add('};');
    add('profile.Sets = sets;');
    add('profile.Packer = {};');
    add('');
    add('-- Weaponskill id -> set name');
    add('local ws_map = {');
    for _, b in ipairs(built) do
        if b.desc.kind == 'ws' and b.desc.ws and b.desc.ws.id then
            add(string.format('    [%d] = %q, -- %s', b.desc.ws.id, b.desc.name, b.desc.ws.name));
        end
    end
    add('};');
    add('');
    add('-- Buff-only weaponskill sets (e.g. Mighty Strikes)');
    add('local buff_ws = {');
    for _, b in ipairs(built) do
        local d = b.desc;
        local list = d.ws_only or d.buff_ws;
        if d.buff and list then
            local ids = {};
            for _, wname in ipairs(list) do
                for _, ws in ipairs(data.weaponskills) do
                    if ws.id and ws.name:lower() == wname:lower() then table.insert(ids, string.format('[%d] = true', ws.id)); end
                end
            end
            add(string.format('    { set = %q, buff = %q, ids = { %s } },', d.name, d.buff, table.concat(ids, ', ')));
        end
    end
    add('};');
    add('');
    add('-- Elemental obis you own (WeatherElement already includes storm spells)');
    add('local obis = {');
    local els = {};
    for e in pairs(obis) do table.insert(els, e); end
    table.sort(els);
    for _, e in ipairs(els) do add(string.format('    [%q] = %q,', LAC_ELEMENT[e], obis[e].name)); end
    add('};');
    add('');
    add('-- Sets worn on top of TP while a buff is active (e.g. Counterstance)');
    add('local engaged_buffs = {');
    for _, b in ipairs(built) do
        if b.desc.engaged_buff then add(string.format('    { buff = %q, set = %q, always = %s },', b.desc.engaged_buff, b.desc.name, tostring(b.desc.buff_any == true))); end
    end
    add('};');
    add('');
    add('-- RNG: the gun tells Preshot / Midshot apart from the bow versions');
    add('local gun_range = ' .. (gun_name_for(abbr) and string.format('%q', gun_name_for(abbr)) or 'nil') .. ';');
    add('');
    add('-- Job abilities that wear their own set');
    add('local ja_map = {');
    for _, p in ipairs(ja_list(built)) do add(string.format('    [%q] = %q,', p[1], p[2])); end
    add('};');
    add('');
    add('-- 2-hour (SP ability) -> Summit set');
    add('local sp_map = {');
    for _, b in ipairs(built) do
        if b.desc.sp_ability then add(string.format('    [%q] = %q,', b.desc.sp_ability, b.desc.name)); end
    end
    add('};');
    add('');
    add('local rules = {');
    add('    cure        = ' .. lua_list(wild_to_patterns(R.cure)) .. ',');
    add('    enf_mnd     = ' .. lua_list(wild_to_patterns(R.enfeebling_mnd)) .. ',');
    add('    ele_dot     = ' .. lua_list(wild_to_patterns(R.elemental_dot)) .. ',');
    add('    drain_aspir = ' .. lua_list(wild_to_patterns(R.drain_aspir)) .. ',');
    add('    song_debuff = ' .. lua_list(wild_to_patterns(R.song_debuff)) .. ',');
    add('    breath      = ' .. lua_list(wild_to_patterns(R.breath_spells)) .. ',');
    add('    pet_breath  = ' .. lua_list(wild_to_patterns(R.pet_breath)) .. ',');
    add('};');
    add('local utsusemi_precast = ' .. tostring((data.utsusemi_precast or {})[abbr] == true) .. ';');
    add('');
    add('-- Spells with their own midcast set, and the base set worn first for every spell / ability (tanks)');
    add('local spell_sets = {');
    for _, p in ipairs(spell_set_list(have)) do
        add(string.format('    { pats = %s, set = %q },', lua_list(wild_to_patterns(p[1])), p[2]));
    end
    add('};');
    local bm, ba = job_base(data.midcast_base, abbr, have), job_base(data.ability_base, abbr, have);
    add('local midcast_base = ' .. (bm and string.format('%q', bm) or 'nil') .. ';');
    add('local ability_base = ' .. (ba and string.format('%q', ba) or 'nil') .. ';');
    add('-- With /NIN or /DNC: your dual-wield pair instead of a set\'s weapons (none picked = weapons left alone)');
    add('local weapon_auto = ' .. tostring(s.weapon_mode == 1 and in_list(data.weapon_jobs, abbr)) .. ';');
    local lpair = (s.weapon_mode == 1 and in_list(data.weapon_jobs, abbr)) and actions.dw_pair(abbr) or nil;
    add('local dw_pair = ' .. (lpair and string.format('{ Main = %q, Sub = %q }', lpair.main or '', lpair.sub or '') or 'nil')
        .. ';   -- worn instead of a set\'s weapons with /NIN or /DNC');
    add('');
    local prc = data.phalanx_received;
    local function id_set(ids)
        local parts = {};
        for _, id in ipairs(ids or {}) do table.insert(parts, string.format('[%d] = true', id)); end
        return '{ ' .. table.concat(parts, ', ') .. ' }';
    end
    add('-- Phalanx cast on you: wear this set for a few seconds (Phalanx II aimed at you / Phalanx from a party member)');
    add('local phalanx_set = ' .. ((prc and have[prc.set]) and string.format('%q', prc.set) or 'nil') .. ';');
    add('local phalanx_single, phalanx_party = ' .. id_set(prc and prc.single) .. ', ' .. id_set(prc and prc.party) .. ';');
    add(string.format('local phalanx_single_time, phalanx_party_time = %d, %d;',
        (prc and prc.single_time) or 5, (prc and prc.party_time) or 8));
    add('');
    add('-- Toggles you can type as /pdt, /mdt, /hybrid, /idle... (they run /lac fwd <name>)');
    add('local slash_cmds = ' .. actions.slash_cmds(have) .. ';');
    add('-- BST: your jug pets; /jug picks the one Call Beast / Bestial Loyalty puts in the ammo slot');
    add('local jugs, JugIdx = ' .. actions.jug_literal(jugs) .. ', 1;');
    add([[
local Mode, MB, TH, RefreshOn, DWOn = 'normal', false, false, false, false;
local PetRangedOn = false;   -- PUP: /lac fwd petranged switches the automaton gear between tank and ranged

local function matches(name, list)
    for _, p in ipairs(list or {}) do
        if name:match(p) then return true; end
    end
    return false;
end

local function eq(name)
    local set = sets[name];
    if set == nil then return false; end
    -- With /NIN or /DNC (dual wield): your dual-wield pair instead of the set's weapons, or your weapons stay
    if weapon_auto and name ~= 'DW' then
        local sj = gData.GetPlayer().SubJob;
        if sj == 'NIN' or sj == 'DNC' then
            local copy, had = {}, false;
            for k, v in pairs(set) do
                if k ~= 'Main' and k ~= 'Sub' then copy[k] = v; else had = true; end
            end
            if had and dw_pair then
                if dw_pair.Main ~= '' then copy.Main = dw_pair.Main; end
                if dw_pair.Sub ~= '' then copy.Sub = dw_pair.Sub; end
            end
            set = copy;
        end
    end
    gFunc.EquipSet(set);
    return true;
end

local function obi(element)
    local o = obis[element];
    if o == nil then return; end
    local env = gData.GetEnvironment();
    if env.WeatherElement == element or env.DayElement == element then gFunc.Equip('Waist', o); end
end

local function buff(name) return gData.GetBuffCount(name) > 0; end

-- Gun or bow? (RNG) The Preshot / Midshot set follows the ranged weapon you have equipped
local function ranged_set(base)
    local eqp = gData.GetEquipment();
    local r = eqp and eqp.Range and eqp.Range.Name;
    if gun_range and r == gun_range and sets[base .. '_Gun'] then return base .. '_Gun'; end
    return base;
end

-- /warp: lock the ring slot and let YunaGearOpt pick Instant Warp or the Warp Ring
local warp_until = nil;
local function warp()
    gFunc.Disable('Ring1');
    warp_until = os.time() + 25;
    AshitaCore:GetChatManager():QueueCommand(1, '/ygo warp');
end

-- Phalanx received (logic from phalanx.lua): reads the action packet and notes when a Phalanx starts on you
local phalanx_until = 0;
local function in_party(id)
    local party = AshitaCore:GetMemoryManager():GetParty();
    for i = 0, 5 do
        if party:GetMemberServerId(i) == id then return true; end
    end
    return false;
end

local function on_action(e)
    if phalanx_set == nil or sets[phalanx_set] == nil then return; end
    local raw, pos, max = e.data_raw, 40, e.size * 8;
    local function bits(n)
        if pos + n >= max then max = 0; return 0; end
        local v = ashita.bits.unpack_be(raw, 0, pos, n);
        pos = pos + n;
        return v;
    end
    local actor = bits(32);
    local targets = bits(6);
    pos = pos + 4;
    bits(4); bits(32); bits(32);                       -- action type, id, recast
    local me = GetPlayerEntity();
    local my_id = me and me.ServerId or 0;
    for _ = 1, targets do
        local target = bits(32);
        local count = bits(4);
        for _ = 1, count do
            bits(5); bits(12); bits(7); bits(3);        -- reaction, animation, effect, knockback
            local param = bits(17);
            local message = bits(10);
            bits(31);
            if bits(1) == 1 then bits(10); bits(17); bits(10); end
            if bits(1) == 1 then bits(10); bits(14); bits(10); end
            if message == 3 or message == 327 then
                if phalanx_single[param] and target == my_id then
                    phalanx_until = os.clock() + phalanx_single_time;
                    return;
                elseif phalanx_party[param] and in_party(actor) then
                    phalanx_until = os.clock() + phalanx_party_time;
                    return;
                end
            end
        end
    end
end

profile.OnLoad = function()
    gSettings.AllowAddSet = false;
    ashita.events.register('packet_in', 'ygo_lac_phalanx', function(e)
        if e.id == 0x28 then pcall(on_action, e); end
    end);
    ashita.events.register('command', 'ygo_lac_warp', function(e)
        local c = e.command:lower():match('^/(%a+)%s*$');
        if c == 'warp' then
            e.blocked = true;
            warp();
        elseif c and slash_cmds[c] then
            e.blocked = true;
            AshitaCore:GetChatManager():QueueCommand(1, '/lac fwd ' .. c);
        end
    end);
end

profile.OnUnload = function()
    ashita.events.unregister('command', 'ygo_lac_warp');
    ashita.events.unregister('packet_in', 'ygo_lac_phalanx');
end

profile.HandleCommand = function(args)
    local c = (args[1] or ''):lower();
    if c == 'pdt' or c == 'mdt' or c == 'hybrid' then
        Mode = (Mode == c) and 'normal' or c;
        gFunc.Message('Mode: ' .. Mode);
    elseif c == 'idle' then
        Mode, RefreshOn = 'normal', false;
        gFunc.Message('Mode: normal');
    elseif c == 'mb' then
        MB = not MB;
        gFunc.Message('Magic Burst: ' .. (MB and 'ON' or 'OFF'));
    elseif c == 'th' then
        TH = not TH;
        gFunc.Message('Treasure Hunter: ' .. (TH and 'ON' or 'OFF'));
    elseif c == 'refresh' then
        RefreshOn = not RefreshOn;
        gFunc.Message('Refresh idle: ' .. (RefreshOn and 'ON' or 'OFF'));
    elseif c == 'petranged' then
        PetRangedOn = not PetRangedOn;
        gFunc.Message('Automaton gear: ' .. (PetRangedOn and 'RANGED' or 'TANK'));
    elseif c == 'jug' then
        if #jugs == 0 then gFunc.Message('No jug pets in your bags.'); return; end
        JugIdx = JugIdx % #jugs + 1;
        gFunc.Message('Jug: ' .. jugs[JugIdx]);
    elseif c == 'dw' then
        DWOn = not DWOn;
        gFunc.Message('Dual wield weapons: ' .. (DWOn and 'ON' or 'OFF'));
    elseif c == 'warp' then
        warp();
    end
end

profile.HandleDefault = function()
    if warp_until and os.time() >= warp_until then
        gFunc.Enable('Ring1');
        warp_until = nil;
    end
    local petAction = gData.GetPetAction();
    if petAction ~= nil and petAction.Type ~= nil and petAction.Type:find('Blood Pact') then
        eq('BloodPact');
        return;
    end
    if petAction ~= nil and petAction.Name ~= nil and matches(petAction.Name, rules.pet_breath) and eq('BreathPotency') then
        return;
    end
    if petAction ~= nil and eq('Ready') then return; end      -- BST: the pet's Ready / Sic move
    local player = gData.GetPlayer();
    if player.Status == 'Engaged' then
        if Mode == 'pdt' and eq('PDT') then
        elseif Mode == 'mdt' and eq('MDT') then
        elseif Mode == 'hybrid' and eq('TP_Hybrid') then
        elseif not eq('TP') then eq('Idle');
        end
        if TH then eq('TH'); end
        for _, eb in ipairs(engaged_buffs) do
            if buff(eb.buff) then eq(eb.set); end
        end
    elseif player.Status == 'Resting' and sets['Resting'] then
        eq('Resting');
    else
        if Mode == 'pdt' and eq('PDT') then
        elseif Mode == 'mdt' and eq('MDT') then
        elseif RefreshOn and eq('Refresh') then
        elseif gData.GetPet() ~= nil and eq('Idle_Avatar') then
        elseif gData.GetPet() ~= nil and PetRangedOn and eq('PetRanged') then
        elseif gData.GetPet() ~= nil and eq('PetTank') then
        else eq('Idle');
        end
        if buff('Sublimation: Activated') then eq('Sublimation'); end
        for _, eb in ipairs(engaged_buffs) do
            if eb.always and buff(eb.buff) then eq(eb.set); end
        end
        if player.IsMoving and sets['Movement'] then eq('Movement'); end
        if player.IsMoving and sets['DesertBoots'] and gData.GetEnvironment().WeatherElement == 'Earth' then eq('DesertBoots'); end
    end
    if DWOn then eq('DW'); end
    if phalanx_set and os.clock() < phalanx_until then eq(phalanx_set); end
end

profile.HandleAbility = function()
    local action = gData.GetAction();
    local name, kind = action.Name or '', action.Type or '';
    if ability_base then eq(ability_base); end
    if kind == 'Corsair Roll' or name == 'Double-Up' then eq('PhantomRoll');
    elseif kind == 'Quick Draw' then eq('QuickDraw');
    elseif kind:find('Blood Pact') then eq('BP_Delay');
    elseif name:find('Waltz') then eq('Waltz');
    elseif sp_map[name] then eq(sp_map[name]);
    elseif ja_map[name] then eq(ja_map[name]);
    end
    if (name == 'Call Beast' or name == 'Bestial Loyalty') and jugs[JugIdx] then gFunc.Equip('Ammo', jugs[JugIdx]); end
end

profile.HandleItem = function()
end

profile.HandlePrecast = function()
    local spell = gData.GetAction();
    if matches(spell.Name, rules.cure) and eq('Precast_Cure') then
    elseif spell.Type == 'Bard Song' and eq('Precast_Song') then
    else eq('Precast');
    end
    if matches(spell.Name or '', rules.breath) then eq('Breath'); end
end

profile.HandleMidcast = function()
    local spell = gData.GetAction();
    local name, skill = spell.Name or '', spell.Skill or '';
    if midcast_base then eq(midcast_base); end
    if utsusemi_precast and name:match('^Utsusemi') and eq('Precast') then return; end
    for _, ss in ipairs(spell_sets) do
        if matches(name, ss.pats) and eq(ss.set) then return; end
    end
    if matches(name, rules.cure) and eq('Cure') then
        obi('Light');
    elseif name == 'Stoneskin' and eq('Stoneskin') then
    elseif skill == 'Healing Magic' then eq('Healing');
    elseif skill == 'Enhancing Magic' then eq('Enhancing');
    elseif skill == 'Enfeebling Magic' then
        if matches(name, rules.enf_mnd) then
            if not eq('Enfeebling_MND') then eq('Enfeebling_INT'); end
        elseif not eq('Enfeebling_INT') then eq('Enfeebling_MND'); end
    elseif skill == 'Divine Magic' then
        eq('Divine'); obi('Light');
    elseif skill == 'Elemental Magic' then
        if matches(name, rules.ele_dot) and eq('MagicAcc') then
        elseif MB and eq('Nuke_MB') then obi(spell.Element);
        else
            if not eq('Nuke') then eq('Nuke_MB'); end
            obi(spell.Element);
        end
    elseif skill == 'Dark Magic' then
        if matches(name, rules.drain_aspir) and eq('DrainAspir') then obi('Dark');
        else eq('Dark'); end
    elseif skill == 'Ninjutsu' then
        eq('Ninjutsu'); obi(spell.Element);
    elseif skill == 'Singing' then
        if matches(name, rules.song_debuff) then
            if not eq('Songs_Debuff') then eq('Songs_Buff'); end
        elseif not eq('Songs_Buff') then eq('Songs_Debuff'); end
    elseif skill == 'Blue Magic' then eq('BlueMagic');
    elseif skill == 'Geomancy' then eq('Geomancy');
    end
end

profile.HandlePreshot = function()
    eq(ranged_set('Preshot'));
end

profile.HandleMidshot = function()
    eq(ranged_set('Midshot'));
end

profile.HandleWeaponskill = function()
    local ws = gData.GetAction();
    if not eq(ws_map[ws.Id] or 'WS') then eq('WS'); end
    for _, bw in ipairs(buff_ws) do
        if buff(bw.buff) and bw.ids[ws.Id] then eq(bw.set); end
    end
end

return profile;]]);
    return table.concat(o, '\n') .. '\n', #built;
end

local function export_lac()
    local abbr = JOBS[ui.job];
    local text, count = build_lac(ui.job);
    local fname = abbr .. '.lua';
    imgui.SetClipboardText(text);
    local saved = {};
    if write_export(export_dir('lac'), player_name() .. '_' .. fname, text) then
        table.insert(saved, 'addons\\yunagearopt\\lac\\' .. player_name() .. '_' .. fname);
    end
    local install, backup = '', nil;
    pcall(function() install = AshitaCore:GetInstallPath(); end);
    if install ~= '' then
        local folder = player_name() .. '_' .. player_server_id();
        local dir = install:gsub('[\\/]+$', '') .. '\\config\\addons\\luashitacast\\' .. folder .. '\\';
        ensure_dir(dir);
        local ok, bak = write_export(dir, fname, text);
        if ok then table.insert(saved, 'config\\addons\\luashitacast\\' .. folder .. '\\' .. fname); end
        if bak then backup = 'config\\addons\\luashitacast\\' .. folder .. '\\' .. bak; end
    end
    msg(string.format('%s LuAshitacast profile exported: %d sets (also copied to clipboard).', abbr, count));
    for _, p in ipairs(saved) do msg('  Saved: ' .. p); end
    if backup then msg('  Your hand-made ' .. fname .. ' was kept as: ' .. backup); end
end

----------------------------------------------------------------------------------------------------
-- Export confirmation: every export button asks first and can back up the files it will replace
----------------------------------------------------------------------------------------------------
local EXPORTS = {
    xml = { label = 'LegacyAC XML',         run = export_full },
    lac = { label = 'LuAshitacast profile', run = export_lac },
    gs  = { label = 'GearSwap file',        run = export_gearswap },
};

-- Files an export writes: { folder, file name, path shown to the player }
local function export_targets(kind)
    local abbr, name = JOBS[ui.job], player_name();
    local install = '';
    pcall(function() install = AshitaCore:GetInstallPath(); end);
    install = install:gsub('[\\/]+$', '');
    local t = {};
    if kind == 'xml' then
        local f = name .. '_' .. abbr .. '.xml';
        table.insert(t, { base_path() .. 'legacyac\\', f, 'addons\\yunagearopt\\legacyac\\' .. f });
        if install ~= '' then table.insert(t, { install .. '\\config\\LegacyAC\\', f, 'config\\LegacyAC\\' .. f }); end
    elseif kind == 'lac' then
        local f = name .. '_' .. abbr .. '.lua';
        table.insert(t, { base_path() .. 'lac\\', f, 'addons\\yunagearopt\\lac\\' .. f });
        if install ~= '' then
            local folder = name .. '_' .. player_server_id();
            table.insert(t, { install .. '\\config\\addons\\luashitacast\\' .. folder .. '\\', abbr .. '.lua',
                              'config\\addons\\luashitacast\\' .. folder .. '\\' .. abbr .. '.lua' });
        end
    else
        local f = name .. '_' .. abbr .. '.lua';
        table.insert(t, { base_path() .. 'gearswap\\', f, 'addons\\yunagearopt\\gearswap\\' .. f });
    end
    return t;
end

local function file_exists(path)
    local f = io.open(path, 'r');
    if f then f:close(); return true; end
    return false;
end

-- Copy every file the export will replace to NAME_backup_<date>.ext in the same folder
local function backup_targets(kind)
    local stamp = os.date('%Y%m%d_%H%M%S');
    for _, t in ipairs(export_targets(kind)) do
        local f = io.open(t[1] .. t[2], 'r');
        if f then
            local old = f:read('*a');
            f:close();
            local base, ext = t[2]:match('^(.*)(%.[^%.]+)$');
            local bak = (base or t[2]) .. '_backup_' .. stamp .. (ext or '');
            if write_file(t[1] .. bak, old) then
                local folder = (t[3]:gsub('[^\\]+$', ''));
                msg('  Backup saved: ' .. folder .. bak);
            end
        end
    end
end

-- After an export, load the new file right away when it's for the job you're on:
-- LegacyAC: /la load (Name_JOB.xml), LuAshitacast: /lac load. GearSwap runs in Windower, so it can't be done from here.
function actions.reload_after_export(kind)
    local abbr = JOBS[ui.job];
    local on_job = player_call(function(p) return p:GetMainJob(); end, 0) == ui.job;
    if kind == 'gs' then
        msg('  In Windower, load it with: //gs reload');
        return;
    end
    if not on_job then
        msg('  You are not on ' .. abbr .. ' right now: it loads by itself when you change to ' .. abbr .. '.');
        return;
    end
    local cm = AshitaCore:GetChatManager();
    if kind == 'xml' then
        local okL, loaded = pcall(function() return AshitaCore:GetPluginManager():IsLoaded('LegacyAC'); end);
        if okL and loaded then
            cm:QueueCommand(1, '/la load');
            msg('  LegacyAC reloaded with the new XML.');
        else
            msg('  LegacyAC is not loaded. Load it with: /load legacyac');
        end
    elseif kind == 'lac' then
        cm:QueueCommand(1, '/lac load');
        msg('  LuAshitacast reloaded with the new profile.');
    end
end

-- Export buttons only ask; the popup (drawn with the window) does the export
local function ask_export(kind)
    ui.pending_export, ui.open_export_popup = kind, true;
end


----------------------------------------------------------------------------------------------------
-- Warp: Scroll of Instant Warp if it's in your inventory, otherwise equip the Warp Ring and use it
----------------------------------------------------------------------------------------------------
local timers = {};
local function after(seconds, fn) table.insert(timers, { at = os.time() + seconds, fn = fn }); end
local function run_timers()
    local now = os.time();
    for i = #timers, 1, -1 do
        if now >= timers[i].at then
            local t = table.remove(timers, i);
            pcall(t.fn);
        end
    end
end

-- Is an item with this name in one of these bags?
local function bag_has(name, bag_ids)
    local found = false;
    pcall(function()
        local inv = AshitaCore:GetMemoryManager():GetInventory();
        local res = AshitaCore:GetResourceManager();
        local key = name_key(name);
        for _, cid in ipairs(bag_ids) do
            for i = 0, (inv:GetContainerCountMax(cid) or 0) do
                local it = inv:GetContainerItem(cid, i);
                if it ~= nil and it.Id ~= 0 and it.Id ~= 65535 then
                    local r = res:GetItemById(it.Id);
                    if r and r.Name and name_key(r.Name[1] or '') == key then found = true; return; end
                end
            end
        end
    end);
    return found;
end

local function do_warp()
    local cm = AshitaCore:GetChatManager();
    if bag_has('Instant Warp', { 0 }) then
        cm:QueueCommand(1, '/item "Instant Warp" <me>');
        msg('Warping with a Scroll of Instant Warp.');
        return;
    end
    if bag_has('Warp Ring', { 0, 8, 10, 11, 12, 13, 14, 15, 16 }) then
        cm:QueueCommand(1, '/equip ring1 "Warp Ring"');
        msg('Warp Ring equipped - using it in 11 seconds (the ring needs to settle first).');
        after(11, function() cm:QueueCommand(1, '/item "Warp Ring" <me>'); end);
        return;
    end
    msg('No Scroll of Instant Warp in your inventory and no Warp Ring in Inventory/Wardrobes.');
end

----------------------------------------------------------------------------------------------------
-- Equip the current set in game (/equip commands)
----------------------------------------------------------------------------------------------------
local EQUIP_SLOT = { main = 'main', sub = 'sub', range = 'range', ammo = 'ammo', head = 'head', neck = 'neck',
    ear1 = 'ear1', ear2 = 'ear2', body = 'body', hands = 'hands', ring1 = 'ring1', ring2 = 'ring2',
    back = 'back', waist = 'waist', legs = 'legs', feet = 'feet' };

local function equip_current_set()
    if ui.result == nil or ui.desc == nil then return; end
    local cm = AshitaCore:GetChatManager();
    local count, skipped = 0, {};
    for _, def in ipairs(SLOTS) do
        local c = ui.result[def.key];
        if c then
            if EQUIP_BAGS[c.item.where] then
                cm:QueueCommand(1, string.format('/equip %s "%s"', EQUIP_SLOT[def.key], c.item.name));
                count = count + 1;
            else
                table.insert(skipped, c.item.name .. ' (' .. c.item.where .. ')');
            end
        end
    end
    msg(string.format('Equipping "%s": %d pieces.', ui.desc.name, count));
    if #skipped > 0 then msg('  Not equipped (move to Inventory/Wardrobe first): ' .. table.concat(skipped, ', ')); end
    msg('  Tip: if LegacyAC/an XML is loaded it may swap gear back. Use /la disable to preview, /la enable after.');
end

----------------------------------------------------------------------------------------------------
-- Lockstyle: shows the job's Lockstyle set on your character without wearing it (same packet as
-- LuAshitacast's gFunc.LockStyle). Pieces can be in any bag. Works with LegacyAC, LuAshitacast or nothing.
----------------------------------------------------------------------------------------------------
function look.picks(job_id)
    return ui.pins[JOBS[job_id] .. '|Lockstyle'] or {};
end

function look.apply(job_id, quiet)
    local picks, packet, count, missing = look.picks(job_id), {}, 0, {};
    for i = 1, 136 do packet[i] = 0; end
    packet[0x05 + 1], packet[0x06 + 1] = 3, 1;
    local ok, err = pcall(function()
        local inv = AshitaCore:GetMemoryManager():GetInventory();
        local res = AshitaCore:GetResourceManager();
        for _, def in ipairs(SLOTS) do
            local pin = picks[def.key];
            if look.slots[def.key] and type(pin) == 'table' and pin.name then
                local key, found = name_key(pin.name), false;
                for cid = 0, 16 do
                    for idx = 1, (inv:GetContainerCountMax(cid) or 0) do
                        local it = inv:GetContainerItem(cid, idx);
                        if it ~= nil and it.Id ~= 0 and it.Id ~= 65535 then
                            local r = res:GetItemById(it.Id);
                            if r and name_key(r.Name[1] or '') == key and bit.band(r.Slots or 0, def.mask) ~= 0 then
                                local at = 8 + count * 8 + 1;
                                packet[at], packet[at + 1], packet[at + 2] = idx, EQUIP_ID[def.key], cid;
                                packet[at + 4], packet[at + 5] = bit.band(it.Id, 0xFF), bit.rshift(it.Id, 8);
                                count, found = count + 1, true;
                                break;
                            end
                        end
                    end
                    if found then break; end
                end
                if not found then table.insert(missing, pin.name); end
            end
        end
        packet[0x04 + 1] = count;
        if count > 0 then
            AshitaCore:GetPacketManager():AddOutgoingPacket(0x53, packet);
            look.on = true;                                    -- ours: keep it through zoning (look.outgoing)
        end
    end);
    if not ok then msg('Lockstyle error: ' .. tostring(err)); return; end
    if count == 0 then
        if not quiet then msg(JOBS[job_id] .. ' has no Lockstyle set yet: pick pieces in the Lockstyle section (or import what you wear).'); end
        return;
    end
    if not quiet then msg(string.format('Lockstyle on: %d pieces (%s).', count, JOBS[job_id])); end
    if #missing > 0 then msg('  Lockstyle pieces not found in your bags: ' .. table.concat(missing, ', ')); end
end

-- Lockstyle turns off when you change job: put it back a few seconds after login / every job change
function look.watch()
    local now = os.time();
    if now == look.checked then return; end
    look.checked = now;
    local j = player_call(function(p) return p:GetMainJob(); end, 0);
    if type(j) ~= 'number' or j < 1 or j > #JOBS or j == look.job then return; end
    look.job = j;
    if next(look.picks(j)) ~= nil then
        after(5, function() if look.job == j then look.apply(j, true); end end);
    end
end

-- Zoning: the server keeps the lockstyle, but the game client doesn't know we set it, so right after every zone
-- it sends "lockstyle off" (0x53 mode 0). For 10 seconds after a zone-in that message is turned into
-- "keep it on" (mode 1), like LuAshitacast does, so the look never drops. Off by your own /lockstyle off = stays off.
function look.zoned()
    look.zone_until = os.clock() + 10;
    -- Fallback in case the server dropped it anyway: put it back once you're in (only while our lockstyle is on)
    after(8, function()
        local j = player_call(function(p) return p:GetMainJob(); end, 0);
        if look.on and type(j) == 'number' and j >= 1 and j <= #JOBS and next(look.picks(j)) ~= nil then look.apply(j, true); end
    end);
end

-- The client's own lockstyle messages (not ours: those are injected)
function look.outgoing(e)
    if e.id ~= 0x53 or e.injected then return; end
    local mode = e.data:byte(0x05 + 1);
    if mode == 0 then
        if look.on and look.zone_until and os.clock() < look.zone_until then
            ashita.bits.pack_be(e.data_modified_raw, 1, 5, 0, 8);    -- "off" after zoning -> "keep it on"
        else
            look.on = false;                                          -- you turned it off yourself
        end
    elseif mode == 3 or mode == 4 then
        look.on = false;                                              -- you set a lockstyle yourself: the client knows it
    end
end


----------------------------------------------------------------------------------------------------
-- UI: theme & helpers
----------------------------------------------------------------------------------------------------
local CATEGORY_ORDER = { 'Melee', 'Weaponskills', 'Precast', 'Magic', 'Abilities', 'Defense & Idle' };
local CATEGORY_OF = {
    Idle = 'Defense & Idle', Idle_Avatar = 'Defense & Idle', Resting = 'Defense & Idle', PDT = 'Defense & Idle',
    MDT = 'Defense & Idle', Movement = 'Defense & Idle', Enmity = 'Defense & Idle',
    Precast = 'Precast', Precast_Cure = 'Precast', Precast_Song = 'Precast',
    TH = 'Abilities', Waltz = 'Abilities', Preshot = 'Abilities', Midshot = 'Abilities', QuickDraw = 'Abilities',
    PhantomRoll = 'Abilities', BP_Delay = 'Abilities', BloodPact = 'Abilities',
    Meditate = 'Abilities', Berserk = 'Abilities', Warcry = 'Abilities', Sublimation = 'Abilities', SP = 'Abilities',
    Counterstance = 'Abilities', Chakra = 'Abilities', Boost = 'Abilities', Focus = 'Abilities',
    PetTank = 'Abilities', PetRanged = 'Abilities', Attachments = 'Abilities',
    Charm = 'Abilities', Reward = 'Abilities', CallBeast = 'Abilities', Ready = 'Abilities',
    Preshot_Gun = 'Abilities', Midshot_Gun = 'Abilities', Refresh = 'Defense & Idle',
    MightyStrikes = 'Abilities', DW = 'Defense & Idle',
    Jump = 'Abilities', HighJump = 'Abilities', Angon = 'Abilities', AncientCircle = 'Abilities', SpiritLink = 'Abilities', DragonBreaker = 'Abilities',
    Breath = 'Abilities', BreathPotency = 'Abilities', DesertBoots = 'Defense & Idle',
    PhalanxRcv = 'Abilities', Sentinel = 'Abilities', ShieldBash = 'Abilities', Rampart = 'Abilities', Cover = 'Abilities',
    Steps = 'Abilities', Samba = 'Abilities', Jig = 'Abilities', ViolentFlourish = 'Abilities',
    TrickAttack = 'Abilities', Flee = 'Abilities', NaSpells = 'Magic', RefreshSpell = 'Magic',
    Lockstyle = 'Lockstyle',
};
local function category(desc)
    if desc.kind == 'tp' then return 'Melee'; end
    if desc.kind == 'ws' then return 'Weaponskills'; end
    return CATEGORY_OF[desc.id] or 'Magic';
end

local function push_theme()
    local cols = {
        { ImGuiCol_WindowBg, C.bg }, { ImGuiCol_ChildBg, { 0, 0, 0, 0 } }, { ImGuiCol_PopupBg, { 0.075, 0.079, 0.092, 0.99 } },
        { ImGuiCol_Border, C.border }, { ImGuiCol_Text, C.text }, { ImGuiCol_TextDisabled, C.muted },
        { ImGuiCol_FrameBg, C.frame }, { ImGuiCol_FrameBgHovered, C.frame_hi }, { ImGuiCol_FrameBgActive, C.frame_hi },
        { ImGuiCol_Button, C.frame }, { ImGuiCol_ButtonHovered, C.frame_hi }, { ImGuiCol_ButtonActive, C.frame_hi },
        { ImGuiCol_Header, { 1, 1, 1, 0.06 } }, { ImGuiCol_HeaderHovered, { 1, 1, 1, 0.045 } },
        { ImGuiCol_HeaderActive, { 1, 1, 1, 0.09 } },
        { ImGuiCol_SliderGrab, C.gold }, { ImGuiCol_SliderGrabActive, C.gold }, { ImGuiCol_CheckMark, C.gold },
        { ImGuiCol_PlotHistogram, C.gold }, { ImGuiCol_Separator, C.line },
        { ImGuiCol_ScrollbarBg, { 0, 0, 0, 0 } }, { ImGuiCol_ScrollbarGrab, { 1, 1, 1, 0.08 } },
        { ImGuiCol_ScrollbarGrabHovered, { 1, 1, 1, 0.16 } }, { ImGuiCol_ScrollbarGrabActive, { 1, 1, 1, 0.22 } },
        { ImGuiCol_TableRowBg, { 0, 0, 0, 0 } },
    };
    for _, c in ipairs(cols) do imgui.PushStyleColor(c[1], c[2]); end
    local vars = {
        { ImGuiStyleVar_WindowRounding, 12 }, { ImGuiStyleVar_ChildRounding, 8 }, { ImGuiStyleVar_FrameRounding, 6 },
        { ImGuiStyleVar_GrabRounding, 6 }, { ImGuiStyleVar_PopupRounding, 8 }, { ImGuiStyleVar_ScrollbarRounding, 8 },
        { ImGuiStyleVar_WindowPadding, { 16, 14 } }, { ImGuiStyleVar_FramePadding, { 10, 6 } },
        { ImGuiStyleVar_ItemSpacing, { 8, 8 } }, { ImGuiStyleVar_WindowBorderSize, 1 }, { ImGuiStyleVar_ScrollbarSize, 8 },
    };
    for _, v in ipairs(vars) do imgui.PushStyleVar(v[1], v[2]); end
    return #cols, #vars;
end

local function accent_button(label, size, active)
    if active then
        imgui.PushStyleColor(ImGuiCol_Button, C.gold_bg);
        imgui.PushStyleColor(ImGuiCol_ButtonHovered, C.gold);
        imgui.PushStyleColor(ImGuiCol_ButtonActive, C.gold);
        imgui.PushStyleColor(ImGuiCol_Text, C.dark);
    end
    local clicked = imgui.Button(label, size);
    if active then imgui.PopStyleColor(4); end
    return clicked;
end

local function ghost_button(label, size)
    imgui.PushStyleColor(ImGuiCol_Button, { 0, 0, 0, 0 });
    imgui.PushStyleColor(ImGuiCol_Text, C.muted);
    local clicked = imgui.Button(label, size);
    imgui.PopStyleColor(2);
    return clicked;
end

local function title_text(text, scale, color)
    imgui.SetWindowFontScale(scale);
    imgui.TextColored(color or C.text, text);
    imgui.SetWindowFontScale(1.0);
end

-- Top 3 stats that make an item score, as a short line: "STR +5   Accuracy +10   Store TP +6"
local function stat_chips(item, w, n)
    local list = {};
    for k, v in pairs(item.stats) do
        if w[k] and v * w[k] > 0 then table.insert(list, { k = k, v = v, c = v * w[k] }); end
    end
    table.sort(list, function(a, b) return a.c > b.c; end);
    local parts = {};
    for i = 1, math.min(n or 3, #list) do table.insert(parts, label_of(list[i].k) .. ' ' .. fmt_num(list[i].v)); end
    return table.concat(parts, '   ');
end

local function item_tooltip(item)
    local w = ui.weights or {};
    local lines = { item.name, item.where .. (EQUIP_BAGS[item.where] and '' or '   (move to Inventory/Wardrobe to equip)'), '' };
    local function add_block(title, stats)
        local keys = {};
        for k in pairs(stats) do table.insert(keys, k); end
        if #keys == 0 then return; end
        table.sort(keys, function(a, b) return math.abs(w[a] or 0) > math.abs(w[b] or 0); end);
        table.insert(lines, title);
        for _, k in ipairs(keys) do
            table.insert(lines, string.format('   %-14s %s%s', label_of(k), fmt_num(stats[k]), w[k] and '' or '   (unused here)'));
        end
    end
    add_block('Base stats', item.base);
    add_block('Augments', item.aug);
    if #item.unknown > 0 then
        local ids = {};
        for _, id in ipairs(item.unknown) do table.insert(ids, tostring(id)); end
        table.insert(lines, 'Unrecognized augment IDs: ' .. table.concat(ids, ', '));
    end
    imgui.SetTooltip((table.concat(lines, '\n'):gsub('%%', '%%%%')));
end

local function set_pin(slot, value, no_save)
    ui.pins[ui.ctx] = ui.pins[ui.ctx] or {};
    ui.pins[ui.ctx][slot] = value;
    ui.dirty = true;
    if not no_save then settings.save(); end
end

local function select_job(i)
    if ui.job ~= i then ui.job, ui.set_idx, ui.dirty = i, 1, true; end
end

----------------------------------------------------------------------------------------------------
-- UI: full window
----------------------------------------------------------------------------------------------------
-- Score quality vs the Best-in-Slot reference: orange = BiS / very good, yellow = good, blue = medium
local TIER_ORANGE = { 1.00, 0.60, 0.20, 1 };
local TIER_YELLOW = { 0.98, 0.86, 0.35, 1 };
local TIER_BLUE   = { 0.45, 0.70, 1.00, 1 };

-- Score color from how close you are to Best in Slot:
-- white -> light blue -> blue -> light yellow -> yellow -> orange
local SCORE_STOPS = {
    { 0.00, { 0.92, 0.93, 0.95, 1 } },   -- white
    { 0.35, { 0.62, 0.80, 1.00, 1 } },   -- light blue
    { 0.55, { 0.35, 0.60, 1.00, 1 } },   -- blue
    { 0.70, { 1.00, 0.93, 0.55, 1 } },   -- light yellow
    { 0.85, { 0.98, 0.82, 0.25, 1 } },   -- yellow
    { 0.95, { 1.00, 0.58, 0.18, 1 } },   -- orange
};

local function tier(ratio)
    if ratio == nil then return C.muted; end
    if ratio <= SCORE_STOPS[1][1] then return SCORE_STOPS[1][2]; end
    for i = 2, #SCORE_STOPS do
        local a, b = SCORE_STOPS[i - 1], SCORE_STOPS[i];
        if ratio <= b[1] then
            local t = (ratio - a[1]) / (b[1] - a[1]);
            return {
                a[2][1] + (b[2][1] - a[2][1]) * t,
                a[2][2] + (b[2][2] - a[2][2]) * t,
                a[2][3] + (b[2][3] - a[2][3]) * t,
                1,
            };
        end
    end
    return SCORE_STOPS[#SCORE_STOPS][2];
end

local function set_ratio()
    if ui.bis == nil or (ui.bis.total or 0) <= 0 then return nil; end
    return math.max(0, (ui.total or 0) / ui.bis.total);
end

local function slot_ratio(key, score)
    local b = ui.bis and ui.bis.assign and ui.bis.assign[key];
    if b == nil or b.score <= 0 then return nil; end
    return math.max(0, score / b.score);
end

local function score_legend(lines)
    table.insert(lines, '');
    table.insert(lines, 'Color: white -> blue -> yellow -> orange as you get closer to Best in Slot.');
    table.insert(lines, 'Orange = Best in Slot or very close to it.');
end

local function owns(name)
    local k = name_key(name);
    for _, it in ipairs(owned) do if name_key(it.name) == k then return true; end end
    return false;
end

-- Width of a button that fits its label
local function text_w(text)
    local ok, a = pcall(imgui.CalcTextSize, text);
    if ok then
        if type(a) == 'number' then return a; end
        if type(a) == 'table' then return a.x or a[1] or (#text * 7); end
    end
    return #text * 7;
end
local function btn_w(text) return math.floor(text_w(text) + 26); end

local function u32(c) return imgui.GetColorU32(c); end

-- Thin edge around the current card in its tier color (a touch stronger for Best-in-Slot level pieces)
local function tier_frame(col, strong)
    local dl = imgui.GetWindowDrawList();
    local x, y = imgui.GetWindowPos();
    local w, h = imgui.GetWindowSize();
    -- A child window clips its left/right padding, which cut the frame down to two loose lines: draw on the full card
    dl:PushClipRect({ x, y }, { x + w, y + h }, false);
    dl:AddRect({ x + 0.5, y + 0.5 }, { x + w - 0.5, y + h - 0.5 }, u32({ col[1], col[2], col[3], strong and 0.75 or 0.22 }), 8, 0, 1);
    dl:PopClipRect();
end

-- Item icon on a soft dark tile (empty tile when there is no item)
local ICON = 36;
local function slot_icon(item, col)
    local dl = imgui.GetWindowDrawList();
    local x, y = imgui.GetCursorScreenPos();
    dl:AddRectFilled({ x, y }, { x + ICON, y + ICON }, u32({ 0, 0, 0, 0.28 }), 6);
    local ic = item and item_icon(item.id);
    if ic then dl:AddImage(ic.ptr, { x + 2, y + 2 }, { x + ICON - 2, y + ICON - 2 }); end
    if item then dl:AddRect({ x, y }, { x + ICON, y + ICON }, u32({ col[1], col[2], col[3], 0.35 }), 6, 0, 1); end
    imgui.Dummy({ ICON, ICON });
end

-- Hairline divider (plain, neutral; the name stays from the old gold version)
local function gold_line(dl, x1, y, x2)
    dl:AddRectFilled({ x1, y }, { x2, y + 1 }, u32(C.line));
end

-- Section title: small, quiet, uppercase - no line, just space around it
local function caption(title)
    imgui.Spacing();
    imgui.SetWindowFontScale(0.82);
    imgui.TextColored(C.muted, title);
    imgui.SetWindowFontScale(1.0);
end

-- Job roles (shown in the job button tooltip); the current job is solid gold
local ROLE = { WAR = 'Melee', MNK = 'Melee', THF = 'Melee', DRK = 'Melee', BST = 'Melee', SAM = 'Melee', NIN = 'Melee',
               DRG = 'Melee', DNC = 'Melee', BLU = 'Melee', PUP = 'Melee', PLD = 'Tank', RUN = 'Tank',
               WHM = 'Healer', SCH = 'Healer', BLM = 'Mage', SMN = 'Mage', RDM = 'Mage', GEO = 'Mage',
               BRD = 'Support', COR = 'Support', RNG = 'Ranged' };
local function job_button(i, abbr, size)
    if i == ui.job then return accent_button(abbr .. '##j', size, true); end
    -- Plain: neutral text, a soft hover; only the selected job is gold
    imgui.PushStyleColor(ImGuiCol_Button, { 1, 1, 1, 0.03 });
    imgui.PushStyleColor(ImGuiCol_ButtonHovered, { 1, 1, 1, 0.08 });
    imgui.PushStyleColor(ImGuiCol_ButtonActive, { 1, 1, 1, 0.12 });
    imgui.PushStyleColor(ImGuiCol_Text, { C.text[1], C.text[2], C.text[3], 0.78 });
    local clicked = imgui.Button(abbr .. '##j', size);
    imgui.PopStyleColor(4);
    return clicked;
end

local function draw_header()
    imgui.PushStyleColor(ImGuiCol_ChildBg, { 0, 0, 0, 0 });
    if imgui.BeginChild('ygo_header', { 0, 70 }, false, bit.bor(ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoScrollWithMouse)) then
        local dl = imgui.GetWindowDrawList();
        local x, y = imgui.GetWindowPos();
        local w, h = imgui.GetWindowSize();
        -- Flat: no fill or glow, one hairline under the header
        gold_line(dl, x, y + h - 1, x + w);

        -- CatsEyeXI logo, then the title and a single quiet info line
        local lx = 4;
        local lg = logo_texture();
        if lg then
            imgui.SetCursorPos({ 0, 7 });
            imgui.Image(lg.ptr, { 92, 56 });
            if imgui.IsItemHovered() then imgui.SetTooltip('Made for CatsEyeXI'); end
            lx = 106;
        end

        imgui.SetCursorPos({ lx, 12 });
        title_text('YUNA', 1.5, C.text);
        imgui.SameLine(0, 5);
        title_text('GEAROPT', 1.5, C.gold);
        imgui.SetCursorPos({ lx, 42 });
        imgui.SetWindowFontScale(0.9);
        imgui.TextColored(C.muted, string.format('%s      %d pieces      %d augmented      scanned %s', player_name(), #owned,
            ui.augmented, ui.last_scan));
        if not bis.done then
            imgui.SameLine(0, 0);
            imgui.TextColored(C.gold_dim, string.format('      building BiS list %d%%', math.floor(bis.next_id / BIS_LAST_ID * 100)));
        end
        imgui.SetWindowFontScale(1.0);

        -- LOCKSTYLE: gold like VIEW BIS SET, next to the scan info; solid gold while you're in it
        for i, d in ipairs(ui.sets) do
            if d.lockstyle then
                local in_look = i == ui.set_idx;
                local label = 'LOCKSTYLE  ' .. JOBS[ui.job];
                imgui.SameLine(0, 18);
                imgui.SetCursorPosY(37);
                if not in_look then
                    imgui.PushStyleColor(ImGuiCol_Button, { C.gold[1], C.gold[2], C.gold[3], 0.12 });
                    imgui.PushStyleColor(ImGuiCol_ButtonHovered, { C.gold[1], C.gold[2], C.gold[3], 0.22 });
                    imgui.PushStyleColor(ImGuiCol_ButtonActive, { C.gold[1], C.gold[2], C.gold[3], 0.32 });
                    imgui.PushStyleColor(ImGuiCol_Text, C.gold);
                end
                if accent_button(label .. '##ygo_look', { btn_w(label), 26 }, in_look) and not in_look then
                    ui.set_idx, ui.dirty = i, true;
                end
                if not in_look then imgui.PopStyleColor(4); end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip('Pick the look you want for ' .. JOBS[ui.job] .. ' (or IMPORT EQUIPPED).\nIt locks on by itself after login and every job change.');
                end
            end
        end

        local wwidth = imgui.GetWindowWidth();
        imgui.SetCursorPos({ wwidth - 92, 20 });
        if ghost_button('_##ygo_compact', { 32, 30 }) then s.compact = true; settings.save(); end
        if imgui.IsItemHovered() then imgui.SetTooltip('Lazy mode'); end
        imgui.SameLine(0, 4);
        if ghost_button('X##ygo_close', { 32, 30 }) then ui.open[1] = false; end
    end
    imgui.EndChild();
    imgui.PopStyleColor();
end

local function draw_sidebar()
    imgui.PushStyleColor(ImGuiCol_ChildBg, C.side);
    imgui.PushStyleVar(ImGuiStyleVar_ChildBorderSize, 0);
    if imgui.BeginChild('ygo_side', { 236, -60 }, true) then
        caption('JOB');
        for i, abbr in ipairs(JOBS) do
            if job_button(i, abbr, { 48, 28 }) then select_job(i); end
            if imgui.IsItemHovered() then imgui.SetTooltip(string.format('%s  Lv.%d   (%s)', abbr, job_level(i), ROLE[abbr] or '')); end
            if i % 4 ~= 0 then imgui.SameLine(0, 4); end
        end

        imgui.Spacing();
        -- (Lockstyle isn't a gear set: its button is in the header, next to the scan info)
        caption(string.format('%s SETS  (%d)', JOBS[ui.job], #ui.sets - 1));
        for _, cat in ipairs(CATEGORY_ORDER) do
            local first = true;
            local last_skill = nil;
            for i, d in ipairs(ui.sets) do
                if category(d) == cat then
                    if cat == 'Weaponskills' and d.ws and d.ws.skill and d.ws.skill ~= last_skill then
                        if first then imgui.Spacing(); imgui.TextColored(C.muted, cat:upper()); first = false; end
                        last_skill = d.ws.skill;
                        imgui.TextColored(C.gold_dim, '  ' .. (SKILL_NAMES[d.ws.skill] or ''));
                    end
                    if first then
                        imgui.Spacing();
                        imgui.TextColored(C.muted, cat:upper());
                        first = false;
                    end
                    local label = (d.kind == 'ws' and d.ws and d.id ~= 'WS') and d.ws.name or d.label:gsub('^WS %- ', '');
                    local sel = i == ui.set_idx;
                    local sx, sy = imgui.GetCursorScreenPos();
                    if sel then imgui.PushStyleColor(ImGuiCol_Text, C.gold); end
                    -- the row stops short of the right edge: the red x sits there
                    local ww = imgui.GetWindowWidth();
                    if imgui.Selectable('   ' .. label .. '##set' .. i, sel, 0, { ww - 58, 0 }) then
                        ui.set_idx, ui.dirty = i, true;
                    end
                    if sel then
                        imgui.PopStyleColor();
                        imgui.GetWindowDrawList():AddRectFilled({ sx, sy + 1 }, { sx + 3, sy + imgui.GetTextLineHeight() - 1 }, u32(C.gold), 1);
                    end
                    -- red x: removes the set from this job (and from its exports); "Restore removed sets" puts it back
                    -- drawn by hand: a square the height of the row, the x's two strokes centred in it
                    imgui.SameLine(ww - 48);
                    local bx, by = imgui.GetCursorScreenPos();
                    local bh = imgui.GetTextLineHeight();
                    local bw = bh + 4;
                    local clicked = imgui.InvisibleButton('##rmset' .. i, { bw, bh });
                    local hov = imgui.IsItemHovered();
                    local dl = imgui.GetWindowDrawList();
                    if hov then dl:AddRectFilled({ bx, by }, { bx + bw, by + bh }, u32({ C.red[1], C.red[2], C.red[3], 0.28 }), 3); end
                    local cx, cy, r = bx + bw / 2, by + bh / 2, bh * 0.26;
                    local col = u32({ C.red[1], C.red[2], C.red[3], hov and 1 or 0.85 });
                    dl:AddLine({ cx - r, cy - r }, { cx + r, cy + r }, col, 2);
                    dl:AddLine({ cx - r, cy + r }, { cx + r, cy - r }, col, 2);
                    if hov then imgui.SetTooltip('Remove ' .. label .. ' from ' .. JOBS[ui.job] .. ' (and from its exports)'); end
                    if clicked then
                        actions.remove_set(JOBS[ui.job], d.id);
                        ui.set_idx, ui.dirty = 1, true;
                        msg(string.format('%s: removed the %s set (it is left out of exports too). "Restore removed sets" puts it back.', JOBS[ui.job], d.label));
                    end
                end
            end
        end
        -- Only when sets were removed: a link to put them back (this job's own sets only)
        local nrem = #(s.set_removed[JOBS[ui.job]] or {});
        if nrem > 0 then
            imgui.Spacing();
            imgui.PushStyleColor(ImGuiCol_Text, C.gold_dim);
            if imgui.Selectable(string.format('   Restore removed sets (%d)##addset', nrem)) then imgui.OpenPopup('ygo_addset'); end
            imgui.PopStyleColor();
        end
        actions.draw_add_set();
    end
    imgui.EndChild();
    imgui.PopStyleVar();
    imgui.PopStyleColor();
end

function actions.draw_add_set()
    if not imgui.BeginPopup('ygo_addset') then return; end
    local abbr = JOBS[ui.job];
    imgui.TextColored(C.gold, 'Put back a removed ' .. abbr .. ' set');
    imgui.Separator();
    for _, id in ipairs(s.set_removed[abbr] or {}) do
        local def = data.sets[id];
        local label = (def and def.label) or (id:gsub('^ws:', 'WS - '));
        if imgui.Selectable(label .. '##rm_' .. id) then
            actions.add_set(abbr, id);
            ui.dirty = true;
            msg(string.format('%s: the %s set is back. Re-export to get it in your XML / LuAshitacast / GearSwap file.', abbr, label));
            imgui.CloseCurrentPopup();
        end
    end
    imgui.EndPopup();
end

local function draw_set_header()
    local d = ui.desc;
    -- The set name takes the set's quality color (no number): white -> blue -> yellow -> orange towards Best in Slot
    local col = ui.show_bis and TIER_ORANGE or (set_ratio() and tier(set_ratio()) or C.text);
    local hx, hy = imgui.GetCursorScreenPos();
    title_text(d.label, 1.35, col);
    if imgui.IsItemHovered() then
        local lines = { 'The color of the set name shows how close it is to Best in Slot.' };
        score_legend(lines);
        imgui.SetTooltip((table.concat(lines, '\n'):gsub('%%', '%%%%')));
    end
    imgui.SameLine();
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 5);
    imgui.TextColored(C.muted, '  XML set ');
    imgui.SameLine(0, 2);
    imgui.TextColored(C.gold_dim, d.name);
    gold_line(imgui.GetWindowDrawList(), hx, hy + 26, hx + imgui.GetWindowWidth() * 0.6, 0.45);

    -- Best in Slot toggle: gold so it stands out (not for Lockstyle, a look has no Best in Slot)
    if d.lockstyle then
        ui.show_bis = false;
    else
        imgui.SameLine(imgui.GetWindowWidth() - btn_w('VIEW BIS SET') - 12);
        local showing = ui.show_bis;            -- the click below flips show_bis; push/pop follow what was drawn
        if not showing then
            imgui.PushStyleColor(ImGuiCol_Button, { C.gold[1], C.gold[2], C.gold[3], 0.12 });
            imgui.PushStyleColor(ImGuiCol_ButtonHovered, { C.gold[1], C.gold[2], C.gold[3], 0.22 });
            imgui.PushStyleColor(ImGuiCol_ButtonActive, { C.gold[1], C.gold[2], C.gold[3], 0.32 });
            imgui.PushStyleColor(ImGuiCol_Text, C.gold);
        end
        if accent_button((showing and 'MY SET' or 'VIEW BIS SET') .. '##bisview', { btn_w('VIEW BIS SET'), 26 }, showing) then
            ui.show_bis = not ui.show_bis;
        end
        if not showing then imgui.PopStyleColor(4); end
        if imgui.IsItemHovered() then
            imgui.SetTooltip(ui.show_bis and 'Back to your own set.' or 'Show the Best in Slot set for this job and set,\nincluding pieces you do not own yet.');
        end
    end

    if d.kind == 'ws' and d.ws then
        local mods = {};
        for k, v in pairs(d.ws.mods or {}) do table.insert(mods, string.format('%s %d%%', k:upper(), math.floor(v * 100 + 0.5))); end
        imgui.TextColored(C.muted, string.format('%s   |   %d hit%s%s   |   %s', (d.ws.kind or 'physical'):upper(), d.ws.hits or 1,
            (d.ws.hits or 1) > 1 and 's' or '', d.ws.crit and '   |   CRIT' or '', table.concat(mods, ', ')));
    end
    local caps = {};
    for k, v in pairs(d.caps or {}) do table.insert(caps, string.format('%s %d', label_of(k), v)); end
    if #caps > 0 then table.sort(caps); imgui.TextColored(C.muted, 'Caps   ' .. table.concat(caps, '   ')); end

    -- Options row
    imgui.Spacing();
    local ign = { s.ignore_level };
    if imgui.Checkbox('Ignore level', ign) then s.ignore_level, ui.dirty = ign[1], true; end
    if d.kind == 'tp' then
        imgui.TextColored(C.muted, 'Dual Wield');
        imgui.SameLine();
        for i, label in ipairs(DW_MODES) do
            if accent_button(label .. '##dw', { 54, 24 }, s.dw_mode == i) then s.dw_mode, ui.dirty = i, true; end
            imgui.SameLine(0, 4);
        end
        local dw = dw_active(ui.job);
        imgui.TextColored(dw and C.green or C.muted, dw and '  active' or '  not used');
    end
end

local function draw_picker(def)
    if not imgui.BeginPopup('pick_' .. def.key) then return; end
    imgui.SetWindowFontScale(0.85);
    local pins = ui.pins[ui.ctx] or {};
    imgui.TextColored(C.gold, def.label:upper());
    imgui.SameLine();
    imgui.TextColored(C.muted, '  choose a piece');
    imgui.Separator();
    -- Search box: type part of a name to filter the list (cleared every time the menu opens)
    ui.search = ui.search or { '' };
    imgui.TextColored(C.gold_dim, 'Search');
    imgui.SameLine();
    imgui.PushItemWidth(-1);
    if imgui.IsWindowAppearing() then ui.search[1] = ''; imgui.SetKeyboardFocusHere(); end
    imgui.InputText('##pick_search_' .. def.key, ui.search, 64);
    imgui.PopItemWidth();
    local filter = (ui.search[1] or ''):lower();
    imgui.Separator();
    if imgui.Selectable('Auto  (let the optimizer choose)', pins[def.key] == nil) then set_pin(def.key, nil); imgui.CloseCurrentPopup(); end
    if imgui.Selectable('Leave empty  (no swap)', pins[def.key] == false) then set_pin(def.key, false); imgui.CloseCurrentPopup(); end
    imgui.Separator();
    local bp = ui.bis and ui.bis.assign and ui.bis.assign[def.key];
    if bp then
        local have = owns(bp.item.name);
        imgui.TextColored(C.muted, 'Best in Slot:');
        imgui.SameLine(0, 6);
        imgui.TextColored(TIER_ORANGE, bp.item.name);
        imgui.SameLine(0, 8);
        imgui.TextColored(have and C.green or C.muted, have and '(owned)' or '(not owned)');
        imgui.Separator();
    end
    local list = ui.full[def.key];
    if list == nil then                       -- a "not swapped" weapon slot: every weapon you own that fits it
        list = {};
        local lvl = job_level(ui.job);
        for idx, it in ipairs(owned) do
            if bit.band(it.slots, def.mask) ~= 0 and can_wear(it, ui.job, lvl, false) then
                table.insert(list, { idx = idx, item = it, score = 0 });
            end
        end
        table.sort(list, function(a, b) return a.item.name < b.item.name; end);
    end
    if filter ~= '' then
        local shown = {};
        for _, c in ipairs(list) do
            if c.item.name:lower():find(filter, 1, true) then table.insert(shown, c); end
        end
        list = shown;
    end
    if #list == 0 then
        imgui.TextColored(C.muted, filter ~= '' and 'No piece matches your search.' or 'No wearable piece for this slot.');
    else
        local h = math.min(#list * 26 + 8, 340);
        if imgui.BeginChild('pick_list_' .. def.key, { 470, h }, false) then
            imgui.SetWindowFontScale(0.85);
            local current = ui.result and ui.result[def.key];
            for i, c in ipairs(list) do
                local bis_piece = ui.bis and ui.bis.assign and ui.bis.assign[def.key];
                local is_bis = bis_piece ~= nil and c.score > 0 and name_key(bis_piece.item.name) == name_key(c.item.name);
                local label = string.format('%-26s   %s%s##p%d', c.item.name, c.item.where,
                    c.item.augmented and '   AUG' or '', i);
                local rc = c.score > 0 and tier(slot_ratio(def.key, c.score)) or C.muted;
                imgui.PushStyleColor(ImGuiCol_Text, rc);
                local picked = imgui.Selectable(label, current ~= nil and current.idx == c.idx);
                imgui.PopStyleColor();
                if is_bis then
                    imgui.SameLine(imgui.GetWindowWidth() - 46);
                    imgui.TextColored(TIER_ORANGE, 'BiS');
                end
                if picked then
                    set_pin(def.key, { name = c.item.name, where = c.item.where });
                    imgui.CloseCurrentPopup();
                end
                if imgui.IsItemHovered() then item_tooltip(c.item); end
            end
        end
        imgui.EndChild();
    end
    imgui.EndPopup();
end

-- Paper-doll cards: 4 x 4 like the in-game equipment screen, each with the item icon and a tier-colored frame
local CARD_H = 112;
local CARD_FLAGS = bit.bor(ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoScrollWithMouse);
local DOLL = { 'main', 'sub', 'range', 'ammo', 'head', 'neck', 'ear1', 'ear2',
               'body', 'hands', 'ring1', 'ring2', 'back', 'waist', 'legs', 'feet' };

-- Slight lift when the mouse is over a card
local function hover_shade()
    if not imgui.IsWindowHovered() then return; end
    local x, y = imgui.GetWindowPos();
    local w, h = imgui.GetWindowSize();
    imgui.GetWindowDrawList():AddRectFilled({ x, y }, { x + w, y + h }, u32({ 1, 1, 1, 0.035 }), 9);
end

local function draw_bis_card(def)
    local b = ui.bis and ui.bis.assign and ui.bis.assign[def.key];
    local have = b and owns(b.item.name);
    imgui.PushStyleColor(ImGuiCol_ChildBg, b and C.card or { C.card[1], C.card[2], C.card[3], 0.45 });
    imgui.PushStyleColor(ImGuiCol_Border, { 0, 0, 0, 0 });
    imgui.BeginChild('bcard_' .. def.key, { 0, CARD_H }, true, CARD_FLAGS);
    hover_shade();
    imgui.SetWindowFontScale(0.85);
    slot_icon(b and b.item, b and TIER_ORANGE or C.muted);
    imgui.SameLine(0, 8);
    imgui.BeginGroup();
    imgui.TextColored(C.muted, def.label:upper());
    imgui.SameLine();
    imgui.TextColored(TIER_ORANGE, 'BiS');
    if b then imgui.TextColored(have and C.green or C.muted, have and 'owned' or 'not owned'); end
    imgui.EndGroup();
    if b then
        imgui.TextColored(have and TIER_ORANGE or C.text, b.item.name);
        local chips = stat_chips(b.item, ui.weights or {}, 2);
        if text_w(chips) * 0.85 > imgui.GetWindowWidth() - 24 then chips = stat_chips(b.item, ui.weights or {}, 1); end
        imgui.TextColored({ 0.70, 0.74, 0.82, 1 }, chips ~= '' and chips or ' ');
    else
        imgui.TextColored(C.muted, ui.bis and 'Nothing better' or 'BiS loading...');
    end
    if b then tier_frame(TIER_ORANGE, have); end
    imgui.EndChild();
    if b and imgui.IsItemHovered() and next(b.item.stats or {}) ~= nil then item_tooltip(b.item); end
    imgui.PopStyleColor(2);
end

local function draw_card(def, max_score)
    if ui.show_bis then draw_bis_card(def); return; end
    local c = ui.result and ui.result[def.key];
    local pin = (ui.pins[ui.ctx] or {})[def.key];
    local r = c and slot_ratio(def.key, c.score);
    local col = c and tier(r) or C.muted;
    imgui.PushStyleColor(ImGuiCol_ChildBg, c and C.card or { C.card[1], C.card[2], C.card[3], 0.45 });
    imgui.PushStyleColor(ImGuiCol_Border, { 0, 0, 0, 0 });
    imgui.BeginChild('card_' .. def.key, { 0, CARD_H }, true, CARD_FLAGS);
    hover_shade();
    imgui.SetWindowFontScale(0.85);
    slot_icon(c and c.item, col);
    imgui.SameLine(0, 8);
    imgui.BeginGroup();
    imgui.TextColored(C.muted, def.label:upper());
    -- Tags go on the bag line, which has room for them (next to the slot name they ran into the arrow)
    if c then imgui.TextColored(EQUIP_BAGS[c.item.where] and C.muted or C.red, c.item.where); end
    if pin ~= nil then
        imgui.SameLine(); imgui.TextColored(C.gold, 'PIN');
    elseif c and ui.forced and ui.forced[def.key] then
        imgui.SameLine(); imgui.TextColored(C.green, 'PREF');
    end
    if c and c.item.augmented then imgui.SameLine(); imgui.TextColored(C.aug, 'AUG'); end
    imgui.EndGroup();
    -- Outside the group: inside one, SameLine's offset counts from the group's left edge and the arrow ends up off the card
    imgui.SameLine(imgui.GetWindowWidth() - 34);
    if imgui.ArrowButton('##arrow_' .. def.key, ImGuiDir_Down) then imgui.OpenPopup('pick_' .. def.key); end
    if imgui.IsItemHovered() then imgui.SetTooltip('Choose a different piece'); end
    draw_picker(def);

    if c then
        imgui.Text(c.item.name);
        -- Two stats when they fit on the card, otherwise only the most important one
        local chips = stat_chips(c.item, ui.weights or {}, 2);
        if text_w(chips) * 0.85 > imgui.GetWindowWidth() - 24 then chips = stat_chips(c.item, ui.weights or {}, 1); end
        imgui.TextColored({ 0.70, 0.74, 0.82, 1 }, chips);
        imgui.PushStyleColor(ImGuiCol_PlotHistogram, col);
        imgui.ProgressBar(r and math.min(1, r) or (max_score > 0 and math.max(0, c.score / max_score) or 0), { -1, 2 }, '');
        imgui.PopStyleColor();
        tier_frame(col, r ~= nil and r >= 0.95);
    else
        local extra = pin == nil and ui.desc.fixed and not ui.desc.fixed[def.key];   -- a free slot in a fixed set
        imgui.TextColored(C.muted, extra and 'Empty - add a piece with the arrow' or (pin == false and 'Left empty' or 'Nothing useful'));
    end
    imgui.EndChild();
    if c and imgui.IsItemHovered() and not imgui.IsPopupOpen('pick_' .. def.key) then item_tooltip(c.item); end
    imgui.PopStyleColor(2);
end

-- A slot this set doesn't swap (e.g. weapons when weapon swaps are off): a dim placeholder keeps the doll shape
local function draw_unused(def)
    imgui.PushStyleColor(ImGuiCol_ChildBg, { C.card[1], C.card[2], C.card[3], 0.25 });
    imgui.PushStyleColor(ImGuiCol_Border, { 0, 0, 0, 0 });
    imgui.BeginChild('unused_' .. def.key, { 0, CARD_H }, true, CARD_FLAGS);
    imgui.SetWindowFontScale(0.85);
    slot_icon(nil, C.muted);
    imgui.SameLine(0, 8);
    imgui.BeginGroup();
    imgui.TextColored({ C.muted[1], C.muted[2], C.muted[3], 0.6 }, def.label:upper());
    imgui.TextColored({ C.muted[1], C.muted[2], C.muted[3], 0.6 }, 'not swapped');
    imgui.EndGroup();
    -- Weapon slots: pick a weapon for this set with the arrow (outside the group, like the normal cards)
    if (def.weapon or def.ranged) and not ui.show_bis and ui.desc and not ui.desc.info then
        imgui.SameLine(imgui.GetWindowWidth() - 34);
        if imgui.ArrowButton('##arrow_' .. def.key, ImGuiDir_Down) then imgui.OpenPopup('pick_' .. def.key); end
        if imgui.IsItemHovered() then imgui.SetTooltip('Choose a weapon for this set\n(Auto = not swapped)'); end
        draw_picker(def);
    end
    imgui.EndChild();
    imgui.PopStyleColor(2);
end

local function draw_totals()
    if not (ui.result and ui.weights) then return; end
    local totals = set_totals(ui.result, ui.weights);
    local keys = {};
    for k in pairs(totals) do table.insert(keys, k); end
    table.sort(keys, function(a, b) return math.abs(ui.weights[a]) > math.abs(ui.weights[b]); end);
    caption('SET TOTALS');
    if #keys == 0 then imgui.TextColored(C.muted, '-'); return; end
    local caps = ui.desc.caps or {};
    imgui.PushStyleColor(ImGuiCol_ChildBg, C.card);
    local rows = math.ceil(math.min(#keys, 20) / 4);
    if imgui.BeginChild('ygo_totals', { 0, rows * 24 + 16 }, true, ImGuiWindowFlags_NoScrollbar) then
        if imgui.BeginTable('ygo_totals_t', 4, ImGuiTableFlags_SizingStretchSame) then
            for i = 1, math.min(#keys, 20) do
                local k, v = keys[i], totals[keys[i]];
                imgui.TableNextColumn();
                imgui.TextColored(C.muted, label_of(k));
                imgui.SameLine();
                if caps[k] then
                    local at_cap = (caps[k] >= 0 and v >= caps[k]) or (caps[k] < 0 and v <= caps[k]);
                    imgui.TextColored(at_cap and C.gold or C.green, string.format('%s/%d', fmt_num(v), caps[k]));
                else
                    imgui.TextColored(((v > 0) == (ui.weights[k] > 0)) and C.green or C.red, fmt_num(v));
                end
            end
            imgui.EndTable();
        end
    end
    imgui.EndChild();
    imgui.PopStyleColor();
end

-- The job's dual-wield pair, used instead of a set's weapons while subbing NIN or DNC.
-- Picked once per job (saved like other picks, key 'JOB|DWPAIR').
function actions.dw_pair(abbr)
    local p = ui.pins[abbr .. '|DWPAIR'];
    if type(p) ~= 'table' then return nil; end
    local pair = {};
    for _, k in ipairs({ 'main', 'sub' }) do
        if type(p[k]) == 'table' and p[k].name then pair[k] = p[k].name; end
    end
    return next(pair) and pair or nil;
end

function actions.draw_dw_pair()
    local d = ui.desc;
    if s.weapon_mode ~= 1 or d == nil or not d.weapons or d.lockstyle or d.info or ui.show_bis then return; end
    if not in_list(data.weapon_jobs, JOBS[ui.job]) then return; end      -- mage jobs only (WHM, BLM, SCH...)
    local abbr, key = JOBS[ui.job], JOBS[ui.job] .. '|DWPAIR';
    local pair = ui.pins[key] or {};
    imgui.TextColored(C.muted, '/NIN and /DNC weapons');
    if imgui.IsItemHovered() then
        imgui.SetTooltip('These weapons are locked if your sub is /NIN or /DNC to prevent TP Loss.');
    end
    for _, slot in ipairs({ { k = 'main', label = 'DW MAIN', mask = 0x0001 }, { k = 'sub', label = 'DW SUB', mask = 0x0002 } }) do
        imgui.SameLine(0, 12);
        local cur = type(pair[slot.k]) == 'table' and pair[slot.k].name or nil;
        imgui.TextColored(C.gold_dim, slot.label);
        imgui.SameLine(0, 6);
        if imgui.Button((cur or '(none)') .. '##dwp_' .. slot.k, { 190, 24 }) then
            ui.dw_search = { '' };
            imgui.OpenPopup('dwpick_' .. slot.k);
        end
        if imgui.BeginPopup('dwpick_' .. slot.k) then
            imgui.SetWindowFontScale(0.85);
            imgui.TextColored(C.gold, slot.label .. '  (/NIN and /DNC)');
            imgui.Separator();
            imgui.TextColored(C.gold_dim, 'Search');
            imgui.SameLine();
            imgui.PushItemWidth(-1);
            if imgui.IsWindowAppearing() then imgui.SetKeyboardFocusHere(); end
            ui.dw_search = ui.dw_search or { '' };
            imgui.InputText('##dwp_search_' .. slot.k, ui.dw_search, 64);
            imgui.PopItemWidth();
            local filter = (ui.dw_search[1] or ''):lower();
            imgui.Separator();
            if imgui.Selectable('None  (leave weapons alone with /NIN or /DNC)', cur == nil) then
                pair[slot.k] = nil; ui.pins[key] = pair; settings.save(); imgui.CloseCurrentPopup();
            end
            imgui.Separator();
            local list, lvl = {}, job_level(ui.job);
            for _, it in ipairs(owned) do
                if bit.band(it.slots, slot.mask) ~= 0 and can_wear(it, ui.job, lvl, false)
                        and (filter == '' or it.name:lower():find(filter, 1, true)) then
                    table.insert(list, it);
                end
            end
            table.sort(list, function(a, b) return a.name < b.name; end);
            if imgui.BeginChild('dwp_list_' .. slot.k, { 420, math.min(#list * 24 + 8, 300) }, false) then
                imgui.SetWindowFontScale(0.85);
                for i, it in ipairs(list) do
                    if imgui.Selectable(string.format('%-26s   %s##dwi%d', it.name, it.where, i), cur == it.name) then
                        pair[slot.k] = { name = it.name, where = it.where };
                        ui.pins[key] = pair; settings.save(); imgui.CloseCurrentPopup();
                    end
                    if imgui.IsItemHovered() then item_tooltip(it); end
                end
            end
            imgui.EndChild();
            imgui.EndPopup();
        end
    end
    imgui.Spacing();
end

local function draw_content()
    if imgui.BeginChild('ygo_content', { 0, -60 }, false) then
        if ui.desc == nil then
            imgui.TextColored(C.muted, 'No sets defined for this job in data.lua.');
        else
            draw_set_header();
            imgui.Spacing();
            if ui.desc.info then
                -- Not gear: a plain list (automaton attachments)
                caption('ATTACHMENTS (BiS)');
                imgui.PushStyleColor(ImGuiCol_ChildBg, C.card);
                if imgui.BeginChild('ygo_info', { 0, #ui.desc.info * 24 + 18 }, true, ImGuiWindowFlags_NoScrollbar) then
                    for i, name in ipairs(ui.desc.info) do
                        imgui.TextColored(C.gold_dim, string.format('%2d', i));
                        imgui.SameLine(0, 12);
                        imgui.Text(name);
                    end
                end
                imgui.EndChild();
                imgui.PopStyleColor();
                imgui.TextColored(C.muted, 'Attachments are chosen in the automaton menu. They are not gear, so they are not exported.');
            else
                local max_score = 0;
                for _, c in pairs(ui.result or {}) do max_score = math.max(max_score, c.score); end
                local active, by_key = {}, {};
                for _, def in ipairs(SLOTS) do by_key[def.key] = def; end
                for _, def in ipairs(active_slots(ui.desc, ui.show_bis)) do active[def.key] = def; end
                actions.draw_dw_pair();
                if imgui.BeginTable('ygo_cards', 4, ImGuiTableFlags_SizingStretchSame) then
                    for _, key in ipairs(DOLL) do
                        imgui.TableNextColumn();
                        if active[key] then draw_card(active[key], max_score); else draw_unused(by_key[key]); end
                    end
                    imgui.EndTable();
                end
                draw_totals();
            end
        end
    end
    imgui.EndChild();
end

local function copy_current_set(fmt)
    if ui.desc == nil then return; end
    local out, assign, name = {}, ui.result or {}, ui.desc.name;
    local covered = covered_slots(assign);
    if fmt == 'lac' then                       -- LuAshitacast: paste inside "local sets = { ... }"
        table.insert(out, string.format('    [%q] = {', name));
        for _, def in ipairs(SLOTS) do
            local c = assign[def.key];
            if covered[def.key] then table.insert(out, string.format("        %s = 'displaced',", LAC_SLOT[def.key]));
            elseif c then table.insert(out, string.format('        %s = %q,', LAC_SLOT[def.key], c.item.name)); end
        end
        table.insert(out, '    },');
    elseif fmt == 'gs' then                    -- GearSwap: paste inside get_sets()
        table.insert(out, string.format('    sets[%q] = {', name));
        for _, def in ipairs(SLOTS) do
            local c = assign[def.key];
            if covered[def.key] then table.insert(out, string.format('        %s = empty,', GS_SLOT[def.key]));
            elseif c then table.insert(out, string.format('        %s = %q,', GS_SLOT[def.key], gs_name(c.item.name))); end
        end
        table.insert(out, '    }');
    else
        set_xml_lines(out, '', name, assign);
    end
    imgui.SetClipboardText(table.concat(out, '\n'));
    local kind = (fmt == 'lac' and 'LuAshitacast') or (fmt == 'gs' and 'GearSwap') or 'XML';
    msg('Set "' .. name .. '" copied to clipboard (' .. kind .. ').');
end

-- Import what you're wearing into the open set: every slot the set uses gets your equipped piece as its pick
-- (an empty slot stays empty). Saved like any other pick, so exports and the lockstyle use it.
function actions.import_equipped()
    if ui.desc == nil or ui.desc.info then return; end
    scan();                                                    -- so pieces you just got are known
    local count = 0;
    local ok, err = pcall(function()
        local inv = AshitaCore:GetMemoryManager():GetInventory();
        local res = AshitaCore:GetResourceManager();
        for _, def in ipairs(active_slots(ui.desc)) do
            local pick = false;
            local e = inv:GetEquippedItem(EQUIP_ID[def.key]);
            local idx = e and bit.band(e.Index, 0x00FF) or 0;
            if idx ~= 0 then
                local cid = bit.rshift(bit.band(e.Index, 0xFF00), 8);
                local it = inv:GetContainerItem(cid, idx);
                local r = (it ~= nil and it.Id ~= 0 and it.Id ~= 65535) and res:GetItemById(it.Id) or nil;
                if r then
                    pick = { name = r.Name[1], where = CONTAINERS[cid] or 'Inventory' };
                    count = count + 1;
                end
            end
            set_pin(def.key, pick, true);
        end
    end);
    settings.save();
    if not ok then msg('Import error: ' .. tostring(err)); return; end
    msg(string.format('Imported %d equipped pieces into %s %s.', count, JOBS[ui.job], ui.desc.label));
    if ui.desc.lockstyle and ui.job == main_job() then look.apply(ui.job, false); end
end

-- /ygo augcheck: every augmented piece you own and what the addon reads from it, so a missing or misread
-- augment can be found and fixed. Chat shows the problems; the full list goes to augment_check.txt.
function actions.augment_report()
    local n = scan();
    local lines, problems, augmented = {}, {}, 0;
    table.insert(lines, string.format('YunaGearOpt %s augment check for %s, %s (%d pieces scanned)', addon.version, player_name(),
        os.date('%Y-%m-%d %H:%M'), n));
    table.insert(lines, 'Each line: item [bag] -> augment stats the addon reads | UNKNOWN = augment ids it does not recognise yet');
    table.insert(lines, '');
    local list = {};
    for _, it in ipairs(owned) do
        if it.augmented or #it.unknown > 0 then table.insert(list, it); end
    end
    table.sort(list, function(a, b) return a.name < b.name; end);
    for _, it in ipairs(list) do
        augmented = augmented + 1;
        local parts = {};
        for k, v in pairs(it.aug or {}) do table.insert(parts, label_of(k) .. ' ' .. fmt_num(v)); end
        table.sort(parts);
        local line = string.format('%s [%s] -> %s', it.name, it.where, #parts > 0 and table.concat(parts, ', ') or '(none read)');
        if #it.unknown > 0 then
            local ids = {};
            for _, id in ipairs(it.unknown) do table.insert(ids, tostring(id)); end
            line = line .. ' | UNKNOWN: ' .. table.concat(ids, ', ');
            table.insert(problems, it.name .. ' (unknown augment ' .. table.concat(ids, ', ') .. ')');
        end
        table.insert(lines, line);
    end
    local path = base_path() .. 'augment_check.txt';
    local ok = write_file(path, table.concat(lines, '\n') .. '\n');
    msg(string.format('Augment check: %d augmented pieces, %d with augments the addon does not recognise.', augmented, #problems));
    for i, p in ipairs(problems) do
        if i > 10 then msg(string.format('  ...and %d more (see the file)', #problems - 10)); break; end
        msg('  ' .. p);
    end
    if ok then msg('  Full list saved to addons\\yunagearopt\\augment_check.txt - send it to Yunas if anything looks wrong.'); end
end

-- "Before you export" window: recommends a backup and lists exactly which files will be replaced
local function draw_export_confirm()
    local id = 'Before you export###ygo_export';
    if ui.open_export_popup then
        imgui.OpenPopup(id);
        ui.open_export_popup = false;
    end
    if not imgui.BeginPopupModal(id, nil, ImGuiWindowFlags_AlwaysAutoResize) then return; end
    local kind = ui.pending_export or 'xml';
    local e = EXPORTS[kind];
    title_text('Recommendation: back up your current files first', 1.1, C.gold);
    imgui.Spacing();
    imgui.Text(string.format('Exporting the %s %s will write these files:', JOBS[ui.job], e.label));
    for _, t in ipairs(export_targets(kind)) do
        local exists = file_exists(t[1] .. t[2]);
        imgui.TextColored(exists and C.red or C.muted, '   ' .. t[3]);
        imgui.SameLine();
        imgui.TextColored(exists and C.red or C.green, exists and '  (already there - will be replaced)' or '  (new file)');
    end
    if kind == 'gs' then
        imgui.TextColored(C.muted, 'Your Windower GearSwap folder is not touched: you copy the file there yourself.');
    end
    imgui.Spacing();
    imgui.TextColored(C.muted, 'BACK UP & EXPORT keeps a copy of each file as NAME_backup_<date> in the same folder.');
    imgui.Spacing();
    local lx, ly = imgui.GetCursorScreenPos();
    gold_line(imgui.GetWindowDrawList(), lx, ly, lx + 420, 0.5);
    imgui.Spacing();
    local b1, b2, b3 = 'BACK UP & EXPORT', 'EXPORT WITHOUT BACKUP', 'CANCEL';
    local function finish() ui.pending_export = nil; imgui.CloseCurrentPopup(); end
    if accent_button(b1 .. '##ygo_bk', { btn_w(b1), 32 }, true) then backup_targets(kind); e.run(); actions.reload_after_export(kind); finish(); end
    imgui.SameLine(0, 8);
    if imgui.Button(b2 .. '##ygo_nobk', { btn_w(b2), 32 }) then e.run(); actions.reload_after_export(kind); finish(); end
    imgui.SameLine(0, 8);
    if ghost_button(b3 .. '##ygo_cancel', { btn_w(b3), 32 }) then finish(); end
    imgui.EndPopup();
end

local function draw_footer()
    local dl = imgui.GetWindowDrawList();
    local wx = imgui.GetWindowPos();
    local _, y = imgui.GetCursorScreenPos();
    local w = imgui.GetWindowWidth();
    y = y + 4;
    gold_line(dl, wx + 16, y, wx + w - 16);
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 11);
    imgui.SetCursorPosX(imgui.GetCursorPosX() + 8);
    if imgui.Button('Rescan', { btn_w('Rescan'), 34 }) then msg(string.format('Scanned %d pieces (%d augmented).', scan(), ui.augmented)); end
    imgui.SameLine();
    if imgui.Button('Copy set', { btn_w('Copy set'), 34 }) then imgui.OpenPopup('ygo_copyfmt'); end
    if imgui.IsItemHovered() then imgui.SetTooltip('Copy this set to the clipboard as XML, LuAshitacast or GearSwap'); end
    if imgui.BeginPopup('ygo_copyfmt') then
        imgui.TextColored(C.muted, 'Copy as');
        if imgui.Selectable('XML (LegacyAC)') then copy_current_set('xml'); end
        if imgui.Selectable('LuAshitacast (.lua)') then copy_current_set('lac'); end
        if imgui.Selectable('GearSwap (.lua)') then copy_current_set('gs'); end
        imgui.EndPopup();
    end
    imgui.SameLine();
    if ui.desc and ui.desc.lockstyle then
        if imgui.Button('APPLY LOCKSTYLE', { btn_w('APPLY LOCKSTYLE'), 34 }) then
            if ui.job == main_job() then look.apply(ui.job, false);
            else msg('Change to ' .. JOBS[ui.job] .. ' to lock this look on (it goes on by itself when you do).'); end
        end
        if imgui.IsItemHovered() then imgui.SetTooltip('Locks this look on your character (/ygo lockstyle).\nIt also goes back on by itself after login and every job change.'); end
    else
        if imgui.Button('EQUIP IN GAME', { btn_w('EQUIP IN GAME'), 34 }) then equip_current_set(); end
        if imgui.IsItemHovered() then imgui.SetTooltip('Puts this set on your character right now (/equip),\nso you can see it. Weapons in the set reset TP.'); end
    end
    imgui.SameLine();
    if imgui.Button('IMPORT EQUIPPED', { btn_w('IMPORT EQUIPPED'), 34 }) then actions.import_equipped(); end
    if imgui.IsItemHovered() then
        imgui.SetTooltip('Puts the gear you are wearing right now into this set (' .. (ui.desc and ui.desc.label or '') .. ').\n'
            .. 'Each slot the set uses gets your equipped piece; an empty slot stays empty.\nReset picks undoes it.');
    end
    local pins = ui.pins[ui.ctx] or {};
    if next(pins) ~= nil then
        imgui.SameLine();
        if imgui.Button('Reset picks', { btn_w('Reset picks'), 34 }) then ui.pins[ui.ctx] = nil; ui.dirty = true; settings.save(); end
    end
    local l1, l2, l3 = 'EXPORT XML', 'EXPORT LAC', 'EXPORT GEARSWAP';
    local w1, w2, w3 = btn_w(l1), btn_w(l2), btn_w(l3);
    imgui.SameLine(imgui.GetWindowWidth() - (w1 + w2 + w3 + 16 + 14));
    -- Exports: gold text on a soft gold tint, a little brighter on hover (three solid gold blocks were too loud)
    local function export_button(label, size)
        imgui.PushStyleColor(ImGuiCol_Button, { C.gold[1], C.gold[2], C.gold[3], 0.10 });
        imgui.PushStyleColor(ImGuiCol_ButtonHovered, { C.gold[1], C.gold[2], C.gold[3], 0.20 });
        imgui.PushStyleColor(ImGuiCol_ButtonActive, { C.gold[1], C.gold[2], C.gold[3], 0.30 });
        imgui.PushStyleColor(ImGuiCol_Text, C.gold);
        local clicked = imgui.Button(label, size);
        imgui.PopStyleColor(4);
        return clicked;
    end
    if export_button(l1, { w1, 34 }) then ask_export('xml'); end
    if imgui.IsItemHovered() then imgui.SetTooltip('LegacyAC (Ashita): every ' .. JOBS[ui.job] .. ' set + rules\n-> config\\LegacyAC\\Name_' .. JOBS[ui.job] .. '.xml'); end
    imgui.SameLine(0, 8);
    if export_button(l2, { w2, 34 }) then ask_export('lac'); end
    if imgui.IsItemHovered() then imgui.SetTooltip('LuAshitacast (Ashita): every ' .. JOBS[ui.job] .. ' set + rules\n-> config\\addons\\luashitacast\\Name_ID\\' .. JOBS[ui.job] .. '.lua\n(an existing profile is backed up first)'); end
    imgui.SameLine(0, 8);
    if export_button(l3, { w3, 34 }) then ask_export('gs'); end
    if imgui.IsItemHovered() then imgui.SetTooltip('GearSwap (Windower): every ' .. JOBS[ui.job] .. ' set + rules\n-> copy to Windower\\addons\\GearSwap\\data\\Name_' .. JOBS[ui.job] .. '.lua'); end
end

local function draw_full()
    imgui.SetNextWindowSize({ 1180, 860 }, ImGuiCond_FirstUseEver);
    imgui.SetNextWindowSizeConstraints({ 1120, 600 }, { 4000, 4000 });
    if imgui.Begin('YunaGearOpt##main', ui.open, bit.bor(ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoCollapse)) then
        draw_header();
        imgui.Spacing();
        draw_sidebar();
        imgui.SameLine(0, 12);
        draw_content();
        draw_footer();
    end
    imgui.End();
end

----------------------------------------------------------------------------------------------------
-- UI: compact window
----------------------------------------------------------------------------------------------------
local function draw_lazy()
    imgui.SetNextWindowSize({ 360, 0 }, ImGuiCond_Always);
    if imgui.Begin('YunaGearOpt##lazy', ui.open, bit.bor(ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoCollapse,
            ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoScrollbar)) then
        title_text('YUNA', 1.15, C.text);
        imgui.SameLine(0, 4);
        title_text('GEAROPT', 1.15, C.gold);
        imgui.SameLine(0, 8);
        imgui.TextColored(C.muted, 'lazy mode');
        imgui.SameLine(imgui.GetWindowWidth() - 76);
        if ghost_button('[ ]##ygo_expand', { 30, 24 }) then s.compact = false; settings.save(); end
        if imgui.IsItemHovered() then imgui.SetTooltip('Full mode'); end
        imgui.SameLine(0, 2);
        if ghost_button('X##ygo_lclose', { 30, 24 }) then ui.open[1] = false; end

        -- Step 1: job + set
        imgui.TextColored(C.gold_dim, '1  PICK A SET');
        imgui.SameLine();
        imgui.PushItemWidth(70);
        if imgui.BeginCombo('##ljob', JOBS[ui.job]) then
            for i, abbr in ipairs(JOBS) do
                if imgui.Selectable(abbr, i == ui.job) then select_job(i); end
            end
            imgui.EndCombo();
        end
        imgui.PopItemWidth();

        -- Quick buttons for the job's non-WS sets, then a WS dropdown
        local n = 0;
        for i, d in ipairs(ui.sets) do
            if d.kind ~= 'ws' then
                if n % 4 ~= 0 then imgui.SameLine(0, 4); end
                local label = d.name:gsub('_', ' ');
                if accent_button(label .. '##q' .. i, { 80, 26 }, i == ui.set_idx) then ui.set_idx, ui.dirty = i, true; end
                if imgui.IsItemHovered() then imgui.SetTooltip(d.label); end
                n = n + 1;
            end
        end
        local ws_label = (ui.desc and ui.desc.kind == 'ws') and ui.desc.label:gsub('^WS %- ', '') or 'Weaponskill...';
        imgui.PushItemWidth(-1);
        if imgui.BeginCombo('##lws', ws_label) then
            -- Search box for the weaponskill list (cleared every time it opens)
            ui.ws_search = ui.ws_search or { '' };
            if imgui.IsWindowAppearing() then ui.ws_search[1] = ''; imgui.SetKeyboardFocusHere(); end
            imgui.InputText('##lws_search', ui.ws_search, 64);
            local wf = (ui.ws_search[1] or ''):lower();
            imgui.Separator();
            for i, d in ipairs(ui.sets) do
                if d.kind == 'ws' and (wf == '' or d.label:lower():find(wf, 1, true)) then
                    if imgui.Selectable(d.label:gsub('^WS %- ', '') .. '##lw' .. i, i == ui.set_idx) then ui.set_idx, ui.dirty = i, true; end
                end
            end
            imgui.EndCombo();
        end
        imgui.PopItemWidth();

        -- Step 2: the auto set
        imgui.Spacing();
        imgui.TextColored(C.gold_dim, '2  AUTO GEAR SET');
        imgui.SameLine();
        imgui.TextColored(C.muted, ui.desc and ('  ' .. ui.desc.name) or '');
        imgui.PushStyleColor(ImGuiCol_ChildBg, C.card);
        local slots = ui.desc and active_slots(ui.desc) or {};
        if imgui.BeginChild('ygo_lazy_set', { 0, #slots * 19 + 14 }, true, ImGuiWindowFlags_NoScrollbar) then
            imgui.SetWindowFontScale(0.85);
            for _, def in ipairs(slots) do
                local c = ui.result and ui.result[def.key];
                imgui.TextColored(C.gold_dim, def.label);
                imgui.SameLine(64);
                if c then
                    imgui.TextColored(EQUIP_BAGS[c.item.where] and C.text or C.red, c.item.name);
                    if imgui.IsItemHovered() then item_tooltip(c.item); end
                    if c.item.augmented then imgui.SameLine(); imgui.TextColored(C.aug, 'AUG'); end
                else
                    imgui.TextColored(C.muted, '-');
                end
            end
        end
        imgui.EndChild();
        imgui.PopStyleColor();

        do
            -- Set quality as a color bar only (no number)
            local ratio = set_ratio();
            imgui.PushStyleColor(ImGuiCol_PlotHistogram, tier(ratio));
            imgui.ProgressBar(ratio and math.min(1, ratio) or 0, { -1, 4 }, '');
            imgui.PopStyleColor();
            if imgui.IsItemHovered() then
                local lines = { 'Your set compared with the best gear in the game for this set.' };
                score_legend(lines);
                imgui.SetTooltip((table.concat(lines, '\n'):gsub('%%', '%%%%')));
            end
        end

        -- Step 3: actions
        imgui.Spacing();
        imgui.TextColored(C.gold_dim, '3  GO');
        if accent_button('EQUIP IN GAME', { -1, 32 }, true) then equip_current_set(); end
        if imgui.IsItemHovered() then imgui.SetTooltip('Put this set on right now so you can see it.'); end
        imgui.TextColored(C.muted, 'Export every set for this job:');
        local bw = math.floor((imgui.GetWindowWidth() - 28 - 12) / 3);
        if imgui.Button('XML##lx', { bw, 30 }) then ask_export('xml'); end
        if imgui.IsItemHovered() then imgui.SetTooltip('LegacyAC (Ashita)'); end
        imgui.SameLine(0, 6);
        if imgui.Button('LAC##ll', { bw, 30 }) then ask_export('lac'); end
        if imgui.IsItemHovered() then imgui.SetTooltip('LuAshitacast (Ashita)'); end
        imgui.SameLine(0, 6);
        if imgui.Button('GEARSWAP##lg', { bw, 30 }) then ask_export('gs'); end
        if imgui.IsItemHovered() then imgui.SetTooltip('GearSwap (Windower)'); end
    end
    imgui.End();
end

local NOTICE_TEXT = 'YunaGearOpt builds your sets by reading item descriptions and augment data, '
    .. 'so some items or stats may not always be 100% accurate.';
local NOTICE_TEXT_2 = 'Always double-check the results, and use the pieces you know are most valuable for your sets.';

local function draw_notice()
    if not ui.notice then return; end
    local cx, cy = 640, 360;
    pcall(function()
        local io = imgui.GetIO();
        cx, cy = io.DisplaySize.x / 2, io.DisplaySize.y / 2;
    end);
    imgui.SetNextWindowPos({ cx, cy }, ImGuiCond_Appearing, { 0.5, 0.5 });
    imgui.SetNextWindowFocus();
    imgui.PushStyleColor(ImGuiCol_Border, C.gold);
    if imgui.Begin('YunaGearOpt##notice', { true }, bit.bor(ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoCollapse,
            ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoScrollbar)) then
        title_text('YUNA', 1.15, C.text);
        imgui.SameLine(0, 4);
        title_text('GEAROPT', 1.15, C.gold);
        imgui.Spacing();
        imgui.Separator();
        imgui.Spacing();
        title_text('Heads up!', 1.15, C.gold);
        imgui.Spacing();
        imgui.PushTextWrapPos(imgui.GetCursorPosX() + 380);
        imgui.TextColored(C.text, NOTICE_TEXT);
        imgui.Spacing();
        imgui.TextColored(C.text, NOTICE_TEXT_2);
        imgui.PopTextWrapPos();
        imgui.Spacing();
        local hide = { s.hide_notice };
        if imgui.Checkbox("Don't show this again", hide) then s.hide_notice = hide[1]; settings.save(); end
        imgui.Spacing();
        if accent_button('Got it', { 380, 30 }, true) then ui.notice = false; end
    end
    imgui.End();
    imgui.PopStyleColor();
end

local function draw_ui()
    if not ui.open[1] or data == nil then return; end
    if not bis.done then bis_step(); end
    if ui.dirty then recompute(); end
    local nc, nv = push_theme();
    if s.compact then draw_lazy(); else draw_full(); end
    draw_notice();
    draw_export_confirm();
    imgui.PopStyleVar(nv);
    imgui.PopStyleColor(nc);
end

----------------------------------------------------------------------------------------------------
-- Events
----------------------------------------------------------------------------------------------------
settings.register('settings', 'ygo_settings_update', function(e)
    if e ~= nil then
        s = e;
        s.picks = actions.plain(s.picks or {});
        s.set_removed = actions.plain(s.set_removed or {});
        s.set_added = actions.plain(s.set_added or {});
        actions.fix_weapon_mode();
        ui.pins, ui.dirty = s.picks, true;
    end
end);

ashita.events.register('load', 'ygo_load', function() load_data(); end);
ashita.events.register('unload', 'ygo_unload', function() settings.save(); end);
ashita.events.register('d3d_present', 'ygo_present', function() run_timers(); look.watch(); draw_ui(); end);

-- Phalanx received for LegacyAC (logic from phalanx.lua): XML rules can't see an incoming Phalanx, so when one
-- starts on you the addon locks the PhalanxRcv set on with /la set for a few seconds. Only for jobs whose
-- exported XML has that set, and only while LegacyAC is loaded. (LuAshitacast / GearSwap exports do this themselves.)
local function phalanx_for_legacyac(e)
    local prc = data and data.phalanx_received;
    if prc == nil then return; end
    local job = JOBS[main_job()];
    if not (',' .. (s.xml_phalanx or '') .. ','):find(',' .. job .. ',', 1, true) then return; end
    local okL, loaded = pcall(function() return AshitaCore:GetPluginManager():IsLoaded('LegacyAC'); end);
    if not (okL and loaded) then return; end
    local single, party = {}, {};
    for _, id in ipairs(prc.single or {}) do single[id] = true; end
    for _, id in ipairs(prc.party or {}) do party[id] = true; end

    local raw, pos, max = e.data_raw, 40, e.size * 8;
    local function bits(n)
        if pos + n >= max then max = 0; return 0; end
        local v = ashita.bits.unpack_be(raw, 0, pos, n);
        pos = pos + n;
        return v;
    end
    local actor = bits(32);
    local targets = bits(6);
    pos = pos + 4;
    bits(4); bits(32); bits(32);                           -- action type, id, recast
    local me = GetPlayerEntity();
    local my_id = me and me.ServerId or 0;
    local pm = AshitaCore:GetMemoryManager():GetParty();
    local function in_party(id)
        for i = 0, 5 do if pm:GetMemberServerId(i) == id then return true; end end
        return false;
    end
    for _ = 1, targets do
        local target = bits(32);
        local count = bits(4);
        for _ = 1, count do
            bits(5); bits(12); bits(7); bits(3);            -- reaction, animation, effect, knockback
            local param = bits(17);
            local message = bits(10);
            bits(31);
            if bits(1) == 1 then bits(10); bits(17); bits(10); end
            if bits(1) == 1 then bits(10); bits(14); bits(10); end
            if message == 3 or message == 327 then
                local hold = nil;
                if single[param] and target == my_id then hold = prc.single_time or 5;
                elseif party[param] and in_party(actor) then hold = prc.party_time or 8; end
                if hold then
                    AshitaCore:GetChatManager():QueueCommand(1, string.format('/la set %s %d', prc.set, hold));
                    return;
                end
            end
        end
    end
end

ashita.events.register('packet_in', 'ygo_phalanx', function(e)
    if e.id == 0x28 then pcall(phalanx_for_legacyac, e);
    elseif e.id == 0x0A then pcall(look.zoned); end           -- 0x0A = you entered a zone
end);

ashita.events.register('packet_out', 'ygo_lockstyle_out', function(e)
    if e.id == 0x53 then pcall(look.outgoing, e); end
end);

ashita.events.register('command', 'ygo_command', function(e)
    local args = e.command:args();
    if #args == 0 then return; end
    -- Accepts /ygo, //ygo, /yunagearopt and //yunagearopt
    local cmd = args[1]:lower():gsub('^/+', '');
    if cmd ~= 'yunagearopt' and cmd ~= 'ygo' then return; end
    e.blocked = true;
    local sub = (args[2] or ''):lower();
    if sub == '' then
        ui.open[1] = not ui.open[1];
        if ui.open[1] then ui.job, ui.set_idx = main_job(), 1; scan(); ui.notice = not s.hide_notice; end
    elseif sub == 'notice' then
        s.hide_notice = false;
        ui.open[1], ui.notice = true, true;
        if #owned == 0 then scan(); end
    elseif sub == 'compact' or sub == 'lazy' then
        if not ui.open[1] then ui.notice = not s.hide_notice; end
        s.compact = not s.compact;
        ui.open[1] = true;
        if #owned == 0 then scan(); end
    elseif sub == 'scan' then
        msg(string.format('Scanned %d pieces (%d augmented).', scan(), ui.augmented));
    elseif sub == 'export' or sub == 'xml' then
        if #owned == 0 then scan(); end
        ui.job, ui.dirty, ui.open[1] = main_job(), true, true;
        ask_export('xml');            -- same confirmation window as the buttons
    elseif sub == 'warp' then
        do_warp();
    elseif sub == 'lockstyle' or sub == 'ls' then
        look.apply(main_job(), false);
    elseif sub == 'augcheck' or sub == 'augments' then
        actions.augment_report();
    elseif sub == 'lac' then
        if #owned == 0 then scan(); end
        ui.job, ui.dirty, ui.open[1] = main_job(), true, true;
        ask_export('lac');            -- same confirmation window as the buttons
    elseif sub == 'gs' or sub == 'gearswap' then
        if #owned == 0 then scan(); end
        ui.job, ui.dirty, ui.open[1] = main_job(), true, true;
        ask_export('gs');            -- same confirmation window as the buttons
    elseif sub == 'equip' then
        if #owned == 0 then scan(); end
        if args[3] then
            ui.job = main_job();
            ui.sets = build_sets(ui.job);
            for i, d in ipairs(ui.sets) do
                if d.name:lower() == args[3]:lower() then ui.set_idx = i; end
            end
            ui.dirty = true;
        end
        recompute();
        equip_current_set();
    elseif sub == 'reload' then
        base_cache = {};
        bis_reset();
        if load_data() then scan(); msg('Data reloaded.'); end
    elseif sub == 'debug' and args[3] then
        local name = table.concat(args, ' ', 3):lower();
        local found = false;
        local function dump(t)
            local p = {};
            for k, v in pairs(t) do table.insert(p, label_of(k) .. ' ' .. fmt_num(v)); end
            table.sort(p);
            return #p > 0 and table.concat(p, ', ') or 'none';
        end
        for _, item in ipairs(owned) do
            if item.name:lower() == name then
                found = true;
                local hex = {};
                if item.rd then for i = 0, 11 do table.insert(hex, string.format('%02X', item.rd(i))); end end
                msg(string.format('%s (%s)', item.name, item.where));
                local jl = {};
                for j = 1, #JOBS do if bit.band(item.jobs, bit.lshift(1, j)) ~= 0 then table.insert(jl, JOBS[j]); end end
                msg('  Jobs (game data): ' .. (#jl > 0 and table.concat(jl, ' ') or 'none') .. string.format('  [mask 0x%X]', item.jobs));
                msg('  Description: ' .. (item.desc or ''):gsub('[\r\n]', ' '));
                msg('  Base: ' .. dump(item.base));
                msg('  Augments: ' .. dump(item.aug));
                if #item.unknown > 0 then
                    local ids = {};
                    for _, id in ipairs(item.unknown) do table.insert(ids, tostring(id)); end
                    msg('  Unrecognized augment IDs: ' .. table.concat(ids, ', '));
                end
                msg('  Raw: ' .. (#hex > 0 and table.concat(hex, ' ') or 'n/a'));
            end
        end
        if not found then msg('Item not found in your bags: ' .. name); end
    else
        msg('Commands: /ygo or //ygo | /ygo lazy | /ygo xml | /ygo lac | /ygo gs | /ygo equip [SetName] | /ygo scan | /ygo export | /ygo reload | /ygo debug <item name>');
    end
    settings.save();
end);
