addon.name    = 'yunagearopt';
addon.author  = 'Yunas';
addon.version = '4.2';
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

local C = {
    bg       = { 0.065, 0.070, 0.095, 0.97 },
    header   = { 0.105, 0.090, 0.060, 1.00 },
    card     = { 0.105, 0.115, 0.150, 1.00 },
    frame    = { 0.135, 0.145, 0.190, 1.00 },
    frame_hi = { 0.175, 0.185, 0.240, 1.00 },
    border   = { 0.960, 0.780, 0.360, 0.18 },
    gold     = { 0.960, 0.780, 0.360, 1.00 },
    gold_dim = { 0.960, 0.780, 0.360, 0.60 },
    gold_bg  = { 0.960, 0.780, 0.360, 0.85 },
    text     = { 0.930, 0.935, 0.950, 1.00 },
    muted    = { 0.550, 0.580, 0.650, 1.00 },
    aug      = { 0.720, 0.560, 1.000, 1.00 },
    green    = { 0.450, 0.900, 0.600, 1.00 },
    red      = { 1.000, 0.450, 0.450, 1.00 },
    dark     = { 0.060, 0.060, 0.070, 1.00 },
};

----------------------------------------------------------------------------------------------------
-- State
----------------------------------------------------------------------------------------------------
local defaults = T{ acc_bias = 1.0, ignore_level = false, dw_mode = 1, weapons = true, compact = false, hide_notice = false, excluded = T{} };
local s = settings.load(defaults);

local S, data, AUG = nil, nil, {};
local BIS_REF = {};   -- bis.lua: curated Best in Slot sets per job

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
    pins = {}, show_bis = false, dirty = true, last_scan = '--:--', augmented = 0,
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
    for name, sets in pairs(d.set_restrict or {}) do ui.set_restrict[name:lower()] = sets; end
    ui.stat_fix = {};
    for name, fix in pairs(d.stat_fix or {}) do ui.stat_fix[name:lower()] = fix; end
    ui.stat_remove = {};
    for name, keys in pairs(d.stat_remove or {}) do ui.stat_remove[name:lower()] = keys; end
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
-- Base stats for an item: overrides > parsed description, then stat_fix / stat_remove from data.lua
local function compute_base(id, name, desc)
    local lname = name:lower();
    local base = ui.overrides[lname];
    if base == nil then
        base = base_cache[id];
        if base == nil then base = parse_stats(desc); base_cache[id] = base; end
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
    return set;
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
                if next(base) ~= nil then
                    table.insert(bis.pool, {
                        id = id, name = name, where = 'BiS', desc = desc,
                        slots = r.Slots, jobs = r.Jobs or 0, level = r.Level or 0,
                        skill = r.Skill or 0, shield = r.ShieldSize or 0,
                        base = base, aug = {}, unknown = {}, augmented = false, stats = base,
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
    bis_allowed = nil;
end

----------------------------------------------------------------------------------------------------
-- Set descriptors per job
----------------------------------------------------------------------------------------------------
local function apply_acc_bias(w)
    for _, k in ipairs({ 'acc', 'racc', 'macc', 'wsacc', 'combatskill' }) do
        if w[k] then w[k] = w[k] * s.acc_bias; end
    end
    return w;
end

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
    for _, id in ipairs(data.jobs[abbr] or {}) do
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
                    fixed = def.fixed or (def.fixed_by_job and def.fixed_by_job[abbr]), fallback = def.fallback, buff = def.buff, engaged_buff = def.engaged_buff, ws_only = def.ws_only,
                    info = def.info,
                };
                local pref = {};
                if in_wset then pref.main, pref.sub = true, true; end          -- melee weapons only from your list
                for _, k in ipairs(def.pref_slots or {}) do pref[k] = true; end
                if next(pref) then entry.pref_slots = pref; end
                if def.ranged then attach_ranged(entry, def.ranged == 'job' and job_ranged_skill() or def.ranged); end
                if def.ranged == 'job' and abbr == 'RNG' then entry.label = entry.label .. ' (bow)'; end
                table.insert(list, entry);
            end
        end
    end
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
    w = apply_acc_bias(w);
    -- "Polearm skill +7" etc. count like Combat Skill, but only for the weapon types this job uses
    if w.combatskill and w.combatskill > 0 and S and S.SKILL_KEY then
        for _, sn in ipairs((data.job_weapons or {})[JOBS[job_id]] or {}) do
            local k = S.SKILL_KEY[sn];
            if k and w[k] == nil then w[k] = w.combatskill; end
        end
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

local function active_slots(desc)
    local list = {};
    if desc.info then return list; end                     -- an info panel (e.g. attachments) has no gear slots
    if desc.fixed then
        for _, def in ipairs(SLOTS) do
            if desc.fixed[def.key] then table.insert(list, def); end
        end
        return list;
    end
    for _, def in ipairs(SLOTS) do
        local use = true;
        if def.weapon then use = desc.weapons and s.weapons; end
        if def.ranged then use = (desc.range == 'instrument' or desc.range == 'any' or desc.range == 'both'); end
        if def.key == 'ammo' and desc.range ~= nil and desc.range ~= 'both' then use = false; end
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
        if ok and not rule.sets and not rule.ws and not rule.ws_stat then ok = false; end
        if ok then for _, n in ipairs(rule.items or {}) do table.insert(names, n); end end
    end
    return names;
end

-- pins: slot -> {name, where} (force a piece), false (force empty), nil (optimizer decides)
local function optimize(job_id, desc, pins, pool)
    local w, caps = weights_for(job_id, desc), desc.caps or {};
    local pure = pool ~= nil;                -- BiS mode: whole game, base stats, no picks/preferred/fixed
    local lvl, dw = pure and (data.bis_level or 75) or job_level(job_id), dw_active(job_id);
    local slots = active_slots(desc);
    pool = pool or owned;
    pins = pure and {} or (pins or {});
    if desc.fixed and not pure then
        local merged = {};
        for k, v in pairs(desc.fixed) do merged[k] = { name = v, alt = desc.fallback and desc.fallback[k] }; end
        for k, v in pairs(pins) do merged[k] = v; end
        pins = merged;
    end

    local full, cands = {}, {};
    for _, def in ipairs(slots) do
        local all, list = {}, {};
        for idx, item in ipairs(pool) do
            if bit.band(item.slots, def.mask) ~= 0 and can_wear(item, job_id, lvl, pure) then
                local c = { idx = idx, item = item, score = score_of(item.stats, w) };
                table.insert(all, c);
                if c.score > 0 and not is_excluded(item.name) and slot_candidate_ok(def, item, desc) then
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
    if desc.range_weapon then
        local merged = {};
        for k, v in pairs(curated or {}) do merged[k] = v; end
        merged.range = desc.range_weapon;
        curated = merged;
    end
    if not bis.done and curated == nil then return nil; end
    local key = JOBS[job_id] .. '|' .. desc.id .. '|' .. tostring(s.acc_bias) .. '|' .. tostring(dw_active(job_id)) .. '|' .. ui.last_scan;
    local hit = bis.cache[key];
    if hit == nil then
        -- Every item in the game (base stats) + your own pieces (with their augments):
        -- an augmented piece you own can beat the plain version, so BiS is never below your set.
        local pool = {};
        for _, it in ipairs(owned) do table.insert(pool, it); end
        for _, it in ipairs(bis.pool) do table.insert(pool, it); end
        local assign = {};
        if bis.done then assign = optimize(job_id, desc, nil, pool); end
        -- Your reference sets (bis.lua) win for every slot they list
        local w, caps = weights_for(job_id, desc), desc.caps or {};
        local active = {};
        for _, def in ipairs(active_slots(desc)) do active[def.key] = true; end
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
            for slot, c in pairs(assign) do if c.curated then listed[name_key(c.item.name)] = slot; end end
            for slot, c in pairs(assign) do
                local at = listed[name_key(c.item.name)];
                if not c.curated and at and at ~= slot then assign[slot] = nil; end
            end
        end
        -- Your explicit rules (data.lua: Fotia on multi-hit, STR rings, Boost gloves...) apply to the BiS view too
        local taken = {};
        for _, pname in ipairs(preferred_for(job_id, desc)) do
            local it = find_item_by_name(pname);
            if it and it.slots and it.slots ~= 0 then
                for _, def in ipairs(active_slots(desc)) do
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
    for _, def in ipairs(SLOTS) do
        local c = assign[def.key];
        if c then table.insert(out, string.format('%s    <%s>%s</%s>', ind, def.tag, xml_escape(c.item.name), def.tag)); end
    end
    table.insert(out, ind .. '</set>');
end

local function equip_set(name)
    return function(out, ind) table.insert(out, string.format('%s<equip set="%s" />', ind, xml_escape(name))); end;
end

-- branches: { { cond = 'attr="value"', body = fn }, ... }; default: fn or nil
-- Job abilities that wear their own set (data.ja_sets), limited to the sets this export contains
local function ja_list(built)
    local present = {};
    for _, b in ipairs(built) do present[b.desc.name] = true; end
    local list = {};
    for _, p in ipairs(data.ja_sets or {}) do
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
    local have = {};
    for _, item in ipairs(owned) do have[item.name:lower()] = item.where; end
    local result = {};
    for element, o in pairs(data.obis or {}) do
        local where = have[o.obi:lower()];
        local name = o.obi;
        if where == nil and data.obi_all then
            where = have[data.obi_all:lower()];
            name = data.obi_all;
        end
        if where then result[element] = { name = name, storm = o.storm, where = where }; end
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
    local out = {};
    local function add(line) table.insert(out, line); end

    add('<ashitacast>');
    add(string.format('    <!-- Generated by YunaGearOpt %s for %s (%s) on %s from the gear you own. -->',
        addon.version, player_name(), abbr, os.date('%Y-%m-%d %H:%M')));
    add('    <!-- Commands: /pdt /mdt /hybrid toggle defensive modes, /mb toggles magic burst, /th toggles Treasure Hunter. -->');
    add('    <!-- /warp: uses a Scroll of Instant Warp if you have one, otherwise equips and uses your Warp Ring. -->');
    add('    <!-- Any set can also be forced with: /la set SetName 60 -->');
    add('');
    add('    <sets>');
    for _, b in ipairs(built) do
        add(string.format('        <!-- %s -->', xml_escape(b.desc.label)));
        set_xml_lines(out, '        ', b.desc.name, b.assign);
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
    if #m > 0 then
        add('    <midmagic>');
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
    if #ja > 0 then add('    <jobability>'); emit_chain(out, '        ', ja, nil); add('    </jobability>'); add(''); end

    local pet_b = {};
    if have.BloodPact then table.insert(pet_b, { cond = attr('ad_type', 'bloodpactrage|bloodpactward'), body = equip_set('BloodPact') }); end
    if have.BreathPotency and R.pet_breath then table.insert(pet_b, { cond = attr('ad_name', R.pet_breath), body = equip_set('BreathPotency') }); end
    if #pet_b > 0 then
        add('    <petskill>');
        emit_chain(out, '        ', pet_b, nil);
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
    if install ~= '' then
        local dir = install:gsub('[\\/]+$', '') .. '\\config\\LegacyAC\\';
        local ok, bak = write_export(dir, fname, xml);
        if ok then table.insert(saved, 'config\\LegacyAC\\' .. fname); end
        if bak then table.insert(backups, 'config\\LegacyAC\\' .. bak); end
    end

    msg(string.format('%s XML exported: %d sets (also copied to clipboard).', abbr, count));
    for _, p in ipairs(saved) do msg('  Saved: ' .. p); end
    for _, b in ipairs(backups) do msg('  Your hand-made ' .. fname .. ' was kept as: ' .. b); end
    msg(string.format('  Load it in game with: /la load %s', fname));
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
    local o = {};
    local function add(line) table.insert(o, line); end

    add(string.format('-- Generated by YunaGearOpt %s for %s (%s) on %s from the gear you own.', addon.version, player_name(), abbr, os.date('%Y-%m-%d %H:%M')));
    add('-- Put this file in Windower/addons/GearSwap/data/ as ' .. player_name() .. '_' .. abbr .. '.lua');
    add('-- Commands: //gs c pdt | //gs c mdt | //gs c hybrid | //gs c mb | //gs c th | /warp');
    add('');
    add('function get_sets()');
    add('    sets = {}');
    add('');
    for _, b in ipairs(built) do
        add(string.format('    -- %s', b.desc.label));
        local parts = {};
        for _, def in ipairs(SLOTS) do
            local c = b.assign[def.key];
            if c then table.insert(parts, string.format('        %s = %q,', GS_SLOT[def.key], gs_name(c.item.name))); end
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
        if b.desc.engaged_buff then add(string.format('        { buff = %q, set = %q },', b.desc.engaged_buff, b.desc.name)); end
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
    local ms_line = {};
    for _, b in ipairs(built) do
        if b.desc.id == 'MightyStrikes' then
            for _, id in ipairs(ws_ids_for(b.desc.ws_only)) do table.insert(ms_line, string.format('[%d] = true', id)); end
        end
    end
    add('    -- Weaponskills that use the MightyStrikes set while Mighty Strikes is active');
    add('    ms_ws = { ' .. table.concat(ms_line, ', ') .. ' }');
    add('');
    add("    Mode, MB, TH, Moving, RefreshOn, DWOn = 'normal', false, false, false, false, false");
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
    if sets[name] then equip(sets[name]) return true end
    return false
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
        else eq('Idle')
        end
        if buffactive['Sublimation: Activated'] then eq('Sublimation') end
        if Moving then eq('Movement') end
        if Moving and world.weather_element == 'Earth' then eq('DesertBoots') end
    end
    if DWOn then eq('DW') end
end

-- Typing /warp runs the warp command
windower.raw_register_event('outgoing text', function(original)
    if original:lower():match('^/warp%s*$') then
        windower.send_command('gs c warp')
        return true
    end
    if original:lower():match('^/dw%s*$') then
        windower.send_command('gs c dw')
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
end

function midcast(spell)
    if spell.action_type == 'Ranged Attack' then eq(ranged_set('Midshot')) return end
    if spell.action_type ~= 'Magic' then return end
    local name, skill = spell.english, spell.skill
    if utsusemi_precast and name:match('^Utsusemi') and eq('Precast') then return end
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
    elseif matches(spell.english, rules.pet_breath) then eq('BreathPotency') end
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
    if c == 'pdt' or c == 'mdt' or c == 'hybrid' then
        Mode = (Mode == c) and 'normal' or c
        add_to_chat(158, 'Mode: ' .. Mode)
    elseif c == 'mb' then
        MB = not MB
        add_to_chat(158, 'Magic Burst: ' .. (MB and 'ON' or 'OFF'))
    elseif c == 'th' then
        TH = not TH
        add_to_chat(158, 'Treasure Hunter: ' .. (TH and 'ON' or 'OFF'))
    elseif c == 'refresh' then
        RefreshOn = not RefreshOn
        add_to_chat(158, 'Refresh idle: ' .. (RefreshOn and 'ON' or 'OFF'))
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
    local built = {};
    for _, desc in ipairs(build_sets(job_id)) do
        local assign = optimize(job_id, desc, ui.pins[abbr .. '|' .. desc.id] or {});
        if next(assign) ~= nil then table.insert(built, { desc = desc, assign = assign }); end
    end
    local R, obis = data.rules or {}, owned_obis();
    local o = {};
    local function add(line) table.insert(o, line); end

    add(string.format('-- Generated by YunaGearOpt %s for %s (%s) on %s from the gear you own.', addon.version, player_name(), abbr, os.date('%Y-%m-%d %H:%M')));
    add('-- LuAshitacast profile. Location: Ashita/config/addons/luashitacast/' .. player_name() .. '_' .. player_server_id() .. '/' .. abbr .. '.lua');
    add('-- Commands: /lac fwd pdt | /lac fwd mdt | /lac fwd hybrid | /lac fwd mb | /lac fwd th | /warp');
    add('');
    add('local profile = {};');
    add('');
    add('local sets = {');
    for _, b in ipairs(built) do
        add(string.format('    -- %s', b.desc.label));
        add(string.format('    [%q] = {', b.desc.name));
        for _, def in ipairs(SLOTS) do
            local c = b.assign[def.key];
            if c then add(string.format('        %s = %q,', LAC_SLOT[def.key], c.item.name)); end
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
        if b.desc.engaged_buff then add(string.format('    { buff = %q, set = %q },', b.desc.engaged_buff, b.desc.name)); end
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
    add([[
local Mode, MB, TH, RefreshOn, DWOn = 'normal', false, false, false, false;

local function matches(name, list)
    for _, p in ipairs(list or {}) do
        if name:match(p) then return true; end
    end
    return false;
end

local function eq(name)
    if sets[name] then gFunc.EquipSet(sets[name]); return true; end
    return false;
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

profile.OnLoad = function()
    gSettings.AllowAddSet = false;
    ashita.events.register('command', 'ygo_lac_warp', function(e)
        if e.command:lower():match('^/warp%s*$') then
            e.blocked = true;
            warp();
        elseif e.command:lower():match('^/dw%s*$') then
            e.blocked = true;
            AshitaCore:GetChatManager():QueueCommand(1, '/lac fwd dw');
        end
    end);
end

profile.OnUnload = function()
    ashita.events.unregister('command', 'ygo_lac_warp');
end

profile.HandleCommand = function(args)
    local c = (args[1] or ''):lower();
    if c == 'pdt' or c == 'mdt' or c == 'hybrid' then
        Mode = (Mode == c) and 'normal' or c;
        gFunc.Message('Mode: ' .. Mode);
    elseif c == 'mb' then
        MB = not MB;
        gFunc.Message('Magic Burst: ' .. (MB and 'ON' or 'OFF'));
    elseif c == 'th' then
        TH = not TH;
        gFunc.Message('Treasure Hunter: ' .. (TH and 'ON' or 'OFF'));
    elseif c == 'refresh' then
        RefreshOn = not RefreshOn;
        gFunc.Message('Refresh idle: ' .. (RefreshOn and 'ON' or 'OFF'));
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
        else eq('Idle');
        end
        if buff('Sublimation: Activated') then eq('Sublimation'); end
        if player.IsMoving and sets['Movement'] then eq('Movement'); end
        if player.IsMoving and sets['DesertBoots'] and gData.GetEnvironment().WeatherElement == 'Earth' then eq('DesertBoots'); end
    end
    if DWOn then eq('DW'); end
end

profile.HandleAbility = function()
    local action = gData.GetAction();
    local name, kind = action.Name or '', action.Type or '';
    if kind == 'Corsair Roll' or name == 'Double-Up' then eq('PhantomRoll');
    elseif kind == 'Quick Draw' then eq('QuickDraw');
    elseif kind:find('Blood Pact') then eq('BP_Delay');
    elseif name:find('Waltz') then eq('Waltz');
    elseif sp_map[name] then eq(sp_map[name]);
    elseif ja_map[name] then eq(ja_map[name]);
    end
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
    if utsusemi_precast and name:match('^Utsusemi') and eq('Precast') then return; end
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
    msg('  Load it in game with: /lac load');
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
    Preshot_Gun = 'Abilities', Midshot_Gun = 'Abilities', Refresh = 'Defense & Idle',
    MightyStrikes = 'Abilities', DW = 'Defense & Idle',
    Jump = 'Abilities', HighJump = 'Abilities', Angon = 'Abilities', AncientCircle = 'Abilities', DragonBreaker = 'Abilities',
    Breath = 'Abilities', BreathPotency = 'Abilities', DesertBoots = 'Defense & Idle',
};
local function category(desc)
    if desc.kind == 'tp' then return 'Melee'; end
    if desc.kind == 'ws' then return 'Weaponskills'; end
    return CATEGORY_OF[desc.id] or 'Magic';
end

local function push_theme()
    local cols = {
        { ImGuiCol_WindowBg, C.bg }, { ImGuiCol_ChildBg, { 0, 0, 0, 0 } }, { ImGuiCol_PopupBg, { 0.09, 0.10, 0.13, 0.98 } },
        { ImGuiCol_Border, C.border }, { ImGuiCol_Text, C.text }, { ImGuiCol_TextDisabled, C.muted },
        { ImGuiCol_FrameBg, C.frame }, { ImGuiCol_FrameBgHovered, C.frame_hi }, { ImGuiCol_FrameBgActive, C.frame_hi },
        { ImGuiCol_Button, C.frame }, { ImGuiCol_ButtonHovered, C.frame_hi }, { ImGuiCol_ButtonActive, C.gold_dim },
        { ImGuiCol_Header, { 0.96, 0.78, 0.36, 0.22 } }, { ImGuiCol_HeaderHovered, { 0.96, 0.78, 0.36, 0.14 } },
        { ImGuiCol_HeaderActive, { 0.96, 0.78, 0.36, 0.30 } },
        { ImGuiCol_SliderGrab, C.gold }, { ImGuiCol_SliderGrabActive, C.gold }, { ImGuiCol_CheckMark, C.gold },
        { ImGuiCol_PlotHistogram, C.gold }, { ImGuiCol_Separator, C.border },
        { ImGuiCol_ScrollbarBg, { 0, 0, 0, 0 } }, { ImGuiCol_ScrollbarGrab, C.frame_hi },
        { ImGuiCol_ScrollbarGrabHovered, C.gold_dim }, { ImGuiCol_TableRowBg, { 0, 0, 0, 0 } },
    };
    for _, c in ipairs(cols) do imgui.PushStyleColor(c[1], c[2]); end
    local vars = {
        { ImGuiStyleVar_WindowRounding, 12 }, { ImGuiStyleVar_ChildRounding, 9 }, { ImGuiStyleVar_FrameRounding, 7 },
        { ImGuiStyleVar_GrabRounding, 7 }, { ImGuiStyleVar_PopupRounding, 8 }, { ImGuiStyleVar_ScrollbarRounding, 8 },
        { ImGuiStyleVar_WindowPadding, { 14, 12 } }, { ImGuiStyleVar_FramePadding, { 10, 6 } },
        { ImGuiStyleVar_ItemSpacing, { 8, 7 } }, { ImGuiStyleVar_WindowBorderSize, 1 }, { ImGuiStyleVar_ScrollbarSize, 10 },
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

local function caption(title)
    imgui.Spacing();
    imgui.SetWindowFontScale(0.92);
    imgui.TextColored(C.gold_dim, title);
    imgui.SetWindowFontScale(1.0);
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

local function set_pin(slot, value)
    ui.pins[ui.ctx] = ui.pins[ui.ctx] or {};
    ui.pins[ui.ctx][slot] = value;
    ui.dirty = true;
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

local function draw_header()
    imgui.PushStyleColor(ImGuiCol_ChildBg, C.header);
    if imgui.BeginChild('ygo_header', { 0, 66 }, false, bit.bor(ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoScrollWithMouse)) then
        imgui.SetCursorPos({ 18, 10 });
        title_text('YUNA', 1.55, C.text);
        imgui.SameLine(0, 6);
        title_text('GEAROPT', 1.55, C.gold);
        imgui.SameLine(0, 12);
        imgui.SetCursorPosY(19);
        imgui.TextColored(C.muted, 'set builder  |  LegacyAC  /  LuAshitacast  /  GearSwap exporter');
        imgui.SetCursorPos({ 18, 41 });
        imgui.TextColored(C.muted, string.format('%d pieces   %d augmented   scanned %s   |   %s', #owned, ui.augmented,
            ui.last_scan, player_name()));
        if not bis.done then
            imgui.SameLine();
            imgui.TextColored(C.gold_dim, string.format('   |   building BiS list %d%%', math.floor(bis.next_id / BIS_LAST_ID * 100)));
        end

        local wwidth = imgui.GetWindowWidth();
        imgui.SetCursorPos({ wwidth - 92, 18 });
        if ghost_button('_##ygo_compact', { 32, 30 }) then s.compact = true; settings.save(); end
        if imgui.IsItemHovered() then imgui.SetTooltip('Lazy mode'); end
        imgui.SameLine(0, 4);
        if ghost_button('X##ygo_close', { 32, 30 }) then ui.open[1] = false; end
    end
    imgui.EndChild();
    imgui.PopStyleColor();
end

local function draw_sidebar()
    imgui.PushStyleColor(ImGuiCol_ChildBg, { 0.08, 0.085, 0.11, 1 });
    if imgui.BeginChild('ygo_side', { 236, -54 }, true) then
        caption('JOB');
        for i, abbr in ipairs(JOBS) do
            if accent_button(abbr .. '##j', { 48, 26 }, i == ui.job) then select_job(i); end
            if imgui.IsItemHovered() then imgui.SetTooltip(string.format('%s  Lv.%d', abbr, job_level(i))); end
            if i % 4 ~= 0 then imgui.SameLine(0, 4); end
        end

        imgui.Spacing();
        imgui.Separator();
        caption(string.format('%s SETS  (%d)', JOBS[ui.job], #ui.sets));
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
                    if imgui.Selectable('   ' .. label .. '##set' .. i, i == ui.set_idx) then
                        ui.set_idx, ui.dirty = i, true;
                    end
                end
            end
        end
    end
    imgui.EndChild();
    imgui.PopStyleColor();
end

local function draw_set_header()
    local d = ui.desc;
    title_text(d.label, 1.3, C.text);
    imgui.SameLine();
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4);
    imgui.TextColored(C.muted, '  XML set ');
    imgui.SameLine(0, 2);
    imgui.TextColored(C.gold, d.name);
    imgui.SameLine();
    local ratio = set_ratio();
    local col = tier(ratio);
    imgui.TextColored(C.muted, ui.show_bis and '   BiS score' or '   score');
    imgui.SameLine(0, 6);
    if ui.show_bis then
        imgui.TextColored(TIER_ORANGE, string.format('%.0f', (ui.bis and ui.bis.total) or 0));
    else
        imgui.TextColored(col, string.format('%.0f', ui.total or 0));
    end
    if imgui.IsItemHovered() then
        local lines = {
            'How good is this set?',
            '',
            string.format('Your set score:      %.0f', ui.total or 0),
            ui.bis and string.format('Best in Slot score:  %.0f', ui.bis.total or 0) or 'Best in Slot score:  still being calculated',
        };
        if ratio then table.insert(lines, string.format('You are at %d%% of the best possible set.', math.floor(ratio * 100 + 0.5))); end
        table.insert(lines, '');
        table.insert(lines, 'The score adds up every useful stat on your gear for this set.');
        table.insert(lines, 'BiS = the best gear for this job and set: every item in the game (Lv.' .. (data.bis_level or 75) .. ')');
        table.insert(lines, 'plus your own augmented pieces when they are better.');
        score_legend(lines);
        imgui.SetTooltip((table.concat(lines, '\n'):gsub('%%', '%%%%')));
    end

    imgui.SameLine(imgui.GetWindowWidth() - btn_w('VIEW BIS SET') - 12);
    if accent_button((ui.show_bis and 'MY SET' or 'VIEW BIS SET') .. '##bisview', { btn_w('VIEW BIS SET'), 24 }, ui.show_bis) then
        ui.show_bis = not ui.show_bis;
    end
    if imgui.IsItemHovered() then
        imgui.SetTooltip(ui.show_bis and 'Back to your own set.' or 'Show the Best in Slot set for this job and set,\nincluding pieces you do not own yet.');
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
    local bias = { s.acc_bias };
    imgui.PushItemWidth(150);
    if imgui.SliderFloat('Accuracy##acc', bias, 0.0, 3.0, '%.1fx') then s.acc_bias, ui.dirty = bias[1], true; end
    imgui.PopItemWidth();
    imgui.SameLine(0, 16);
    local ign = { s.ignore_level };
    if imgui.Checkbox('Ignore level', ign) then s.ignore_level, ui.dirty = ign[1], true; end
    if d.weapons then
        imgui.SameLine(0, 16);
        local wp = { s.weapons };
        if imgui.Checkbox('Swap weapons', wp) then s.weapons, ui.dirty = wp[1], true; end
    end
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
    local list = ui.full[def.key] or {};
    if #list == 0 then
        imgui.TextColored(C.muted, 'No wearable piece for this slot.');
    else
        local h = math.min(#list * 26 + 8, 340);
        if imgui.BeginChild('pick_list_' .. def.key, { 470, h }, false) then
            imgui.SetWindowFontScale(0.85);
            local current = ui.result and ui.result[def.key];
            for i, c in ipairs(list) do
                local bis_piece = ui.bis and ui.bis.assign and ui.bis.assign[def.key];
                local is_bis = bis_piece ~= nil and c.score > 0 and name_key(bis_piece.item.name) == name_key(c.item.name);
                local label = string.format('%-26s %6.0f   %s%s##p%d', c.item.name, c.score, c.item.where,
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

local function draw_bis_card(def)
    local b = ui.bis and ui.bis.assign and ui.bis.assign[def.key];
    imgui.PushStyleColor(ImGuiCol_ChildBg, b and C.card or { C.card[1], C.card[2], C.card[3], 0.45 });
    imgui.BeginChild('bcard_' .. def.key, { 0, 82 }, true, bit.bor(ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoScrollWithMouse));
    imgui.SetWindowFontScale(0.85);
    imgui.TextColored(C.gold_dim, def.label:upper());
    imgui.SameLine();
    imgui.TextColored(TIER_ORANGE, 'BiS');
    if b then
        local have = owns(b.item.name);
        imgui.TextColored(have and TIER_ORANGE or C.text, b.item.name);
        imgui.SameLine();
        imgui.TextColored(have and C.green or C.muted, have and '  owned' or '  not owned');
        local chips = stat_chips(b.item, ui.weights or {}, 3);
        imgui.TextColored({ 0.70, 0.74, 0.82, 1 }, chips ~= '' and chips or ' ');
    else
        imgui.TextColored(C.muted, ui.bis and 'Nothing better for this slot' or 'BiS loading...');
    end
    imgui.EndChild();
    if b and imgui.IsItemHovered() and next(b.item.stats or {}) ~= nil then item_tooltip(b.item); end
    imgui.PopStyleColor();
end

local function draw_card(def, max_score)
    if ui.show_bis then draw_bis_card(def); return; end
    local c = ui.result and ui.result[def.key];
    local pin = (ui.pins[ui.ctx] or {})[def.key];
    imgui.PushStyleColor(ImGuiCol_ChildBg, c and C.card or { C.card[1], C.card[2], C.card[3], 0.45 });
    imgui.BeginChild('card_' .. def.key, { 0, 82 }, true, bit.bor(ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoScrollWithMouse));
    imgui.SetWindowFontScale(0.85);
    imgui.TextColored(C.gold_dim, def.label:upper());
    if pin ~= nil then
        imgui.SameLine(); imgui.TextColored(C.gold, 'PINNED');
    elseif ui.forced and ui.forced[def.key] then
        imgui.SameLine(); imgui.TextColored(C.green, 'PREFERRED');
    end
    if c and c.item.augmented then imgui.SameLine(); imgui.TextColored(C.aug, 'AUG'); end
    imgui.SameLine(imgui.GetWindowWidth() - 34);
    if imgui.ArrowButton('##arrow_' .. def.key, ImGuiDir_Down) then imgui.OpenPopup('pick_' .. def.key); end
    if imgui.IsItemHovered() then imgui.SetTooltip('Choose a different piece'); end
    draw_picker(def);

    if c then
        imgui.Text(c.item.name);
        imgui.SameLine();
        imgui.TextColored(EQUIP_BAGS[c.item.where] and C.muted or C.red, '  ' .. c.item.where);
        imgui.TextColored({ 0.70, 0.74, 0.82, 1 }, stat_chips(c.item, ui.weights or {}, 3));
        local r = slot_ratio(def.key, c.score);
        imgui.PushStyleColor(ImGuiCol_PlotHistogram, (tier(r)));
        imgui.ProgressBar(r and math.min(1, r) or (max_score > 0 and math.max(0, c.score / max_score) or 0), { -1, 3 }, '');
        imgui.PopStyleColor();
    else
        imgui.TextColored(C.muted, pin == false and 'Left empty (no swap)' or 'No useful item found');
    end
    imgui.EndChild();
    if c and imgui.IsItemHovered() and not imgui.IsPopupOpen('pick_' .. def.key) then item_tooltip(c.item); end
    imgui.PopStyleColor();
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

local function draw_content()
    if imgui.BeginChild('ygo_content', { 0, -54 }, false) then
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
                if imgui.BeginTable('ygo_cards', 2, ImGuiTableFlags_SizingStretchSame) then
                    for _, def in ipairs(active_slots(ui.desc)) do
                        imgui.TableNextColumn();
                        draw_card(def, max_score);
                    end
                    imgui.EndTable();
                end
                draw_totals();
            end
        end
    end
    imgui.EndChild();
end

local function copy_current_set()
    if ui.desc == nil then return; end
    local out = {};
    set_xml_lines(out, '', ui.desc.name, ui.result or {});
    imgui.SetClipboardText(table.concat(out, '\n'));
    msg('Set "' .. ui.desc.name .. '" copied to clipboard.');
end

local function draw_footer()
    imgui.Separator();
    imgui.Spacing();
    if imgui.Button('Rescan', { 80, 34 }) then msg(string.format('Scanned %d pieces (%d augmented).', scan(), ui.augmented)); end
    imgui.SameLine();
    if imgui.Button('Copy set', { 90, 34 }) then copy_current_set(); end
    imgui.SameLine();
    if imgui.Button('EQUIP IN GAME', { 130, 34 }) then equip_current_set(); end
    if imgui.IsItemHovered() then imgui.SetTooltip('Puts this set on your character right now (/equip),\nso you can see it. Weapons in the set reset TP.'); end
    local pins = ui.pins[ui.ctx] or {};
    if next(pins) ~= nil then
        imgui.SameLine();
        if imgui.Button('Reset picks', { 100, 34 }) then ui.pins[ui.ctx] = {}; ui.dirty = true; end
    end
    local l1, l2, l3 = 'EXPORT XML', 'EXPORT LAC', 'EXPORT GEARSWAP';
    local w1, w2, w3 = btn_w(l1), btn_w(l2), btn_w(l3);
    imgui.SameLine(imgui.GetWindowWidth() - (w1 + w2 + w3 + 16 + 14));
    if accent_button(l1, { w1, 34 }, true) then export_full(); end
    if imgui.IsItemHovered() then imgui.SetTooltip('LegacyAC (Ashita): every ' .. JOBS[ui.job] .. ' set + rules\n-> config\\LegacyAC\\Name_' .. JOBS[ui.job] .. '.xml'); end
    imgui.SameLine(0, 8);
    if accent_button(l2, { w2, 34 }, true) then export_lac(); end
    if imgui.IsItemHovered() then imgui.SetTooltip('LuAshitacast (Ashita): every ' .. JOBS[ui.job] .. ' set + rules\n-> config\\addons\\luashitacast\\Name_ID\\' .. JOBS[ui.job] .. '.lua\n(an existing profile is backed up first)'); end
    imgui.SameLine(0, 8);
    if accent_button(l3, { w3, 34 }, true) then export_gearswap(); end
    if imgui.IsItemHovered() then imgui.SetTooltip('GearSwap (Windower): every ' .. JOBS[ui.job] .. ' set + rules\n-> copy to Windower\\addons\\GearSwap\\data\\Name_' .. JOBS[ui.job] .. '.lua'); end
end

local function draw_full()
    imgui.SetNextWindowSize({ 920, 860 }, ImGuiCond_FirstUseEver);
    imgui.SetNextWindowSizeConstraints({ 760, 520 }, { 4000, 4000 });
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
            for i, d in ipairs(ui.sets) do
                if d.kind == 'ws' then
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
            local ratio = set_ratio();
            local col = tier(ratio);
            imgui.TextColored(C.muted, 'score');
            imgui.SameLine(0, 6);
            imgui.TextColored(col, string.format('%.0f', ui.total or 0));
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
        if imgui.Button('XML##lx', { bw, 30 }) then export_full(); end
        if imgui.IsItemHovered() then imgui.SetTooltip('LegacyAC (Ashita)'); end
        imgui.SameLine(0, 6);
        if imgui.Button('LAC##ll', { bw, 30 }) then export_lac(); end
        if imgui.IsItemHovered() then imgui.SetTooltip('LuAshitacast (Ashita)'); end
        imgui.SameLine(0, 6);
        if imgui.Button('GEARSWAP##lg', { bw, 30 }) then export_gearswap(); end
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
    imgui.PopStyleVar(nv);
    imgui.PopStyleColor(nc);
end

----------------------------------------------------------------------------------------------------
-- Events
----------------------------------------------------------------------------------------------------
settings.register('settings', 'ygo_settings_update', function(e)
    if e ~= nil then s = e; ui.dirty = true; end
end);

ashita.events.register('load', 'ygo_load', function() load_data(); end);
ashita.events.register('unload', 'ygo_unload', function() settings.save(); end);
ashita.events.register('d3d_present', 'ygo_present', function() run_timers(); draw_ui(); end);

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
        ui.job = main_job();
        export_full();
    elseif sub == 'warp' then
        do_warp();
    elseif sub == 'lac' then
        if #owned == 0 then scan(); end
        ui.job = main_job();
        export_lac();
    elseif sub == 'gs' or sub == 'gearswap' then
        if #owned == 0 then scan(); end
        ui.job = main_job();
        export_gearswap();
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
