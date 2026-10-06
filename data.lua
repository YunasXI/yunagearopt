--[[
    GearOpt data file - edit freely, then in game: /gearopt reload

    sets      : every set GearOpt can build. weights = score per point of a stat (per 1% for % stats).
                Negative weights reward negative values (e.g. DT -5% scores positively).
                caps   = stat caps; past the cap a stat is worth nothing (negative caps are floors).
                weapons= true lets mage jobs (weapon_jobs) swap main/sub in this set.
                range  = 'instrument' lets BRD put an instrument in the range slot.
    jobs      : which sets each job gets in its XML. 'WS' expands to a generic WS set plus one
                set per weaponskill listed for that job below.
    Stat keys : str dex vit agi int mnd chr hp mp def acc att racc ratt eva macc mab mdb meva
                stp da ta qa crit critdmg wsd wsacc haste dw sb dt pdt mdt tpb scb
                fc cure curect songct songrecast songdur cmp refresh regen enmity sird move th hmp hhp waltz
                drain enhdur enfdur mdmg mcrit mcritdmg ctp zanshin occult bdt curercv recycle bloodboon bpdelay2
                roll rolldur rolldelay rollaoe fencer meditate berserk warcry sublimation combatskill
                snapshot rapid counter kick ma perp bpdelay bpdmg mbb
                healing divine enhancing enfeebling elemental dark summoning ninjutsu
                singing string wind blue geomancy handbell
    (curect, songct, sird, perp, bpdelay are stored as the amount reduced: higher = better)
    range = 'any' lets a set swap the range slot (e.g. Opprimo for Phantom Roll); ammo is then left alone.
]]

local DEF = { dt = -50, pdt = -50, mdt = -50 };

return {
    dual_wield_jobs   = { 'NIN', 'DNC', 'THF' },
    dual_wield_weight = 5,
    weapon_jobs       = { 'WHM', 'BLM', 'SMN', 'SCH', 'GEO', 'BRD' },

    exclude   = { 'Aesir Mantle' },
    overrides = { ['Aesir Mantle'] = { da = 1 } },

    -- Preferred gear: always used in these sets when you own it (and the job can wear it).
    --   sets = set ids, jobs = limit to these jobs (optional),
    --   ws = 'single' / 'multi' / 'any' to target weaponskill sets by hit count,
    --   ws_stat = 'str' (or dex, vit...) to target every weaponskill that uses that stat.
    preferred = {
        { sets = { 'PhantomRoll' }, items = { "Luzaf's Ring" } },
        { sets = { 'Nuke', 'Nuke_MB' }, jobs = { 'SCH' }, items = { 'Coeus' } },
        { sets = { 'Nuke', 'Nuke_MB' }, jobs = { 'BLM', 'RDM', 'SCH', 'GEO', 'BLU' }, items = { 'Moepapa Pendant' } },
        { sets = { 'Meditate' },    items = { 'Pinnacle Dastanas' } },
        -- SAM: bow in the range slot (swapping range doesn't reset TP). "TP Bonus" has no number in
        -- the description, so it's forced for weaponskills instead of scored.
        { ws = 'any', jobs = { 'SAM' }, items = { "Kennan's Longbow" } },
        { sets = { 'Meditate' }, jobs = { 'SAM' }, items = { "Kennan's Longbow" } },
        { sets = { 'Berserk' },     items = { 'Pinnacle Celata' } },
        { sets = { 'Warcry' },      items = { 'Pinnacle Sabatons' } },
        { sets = { 'Sublimation' }, items = { 'Apogee Sabots' } },
        -- SCH Artifact + Relic head/body while Sublimation charges (+1 first; the piece whose
        -- description shows a Sublimation bonus wins if you own both for the same slot)
        { sets = { 'Sublimation' }, jobs = { 'SCH' },
          items = { 'Argute M.board +1', 'Argute M.board', 'Sch. M.board +1', "Scholar's M.board", "Scholar's Mortarboard",
                    'Argute Gown +1', 'Argute Gown', "Scholar's Gown +1", "Scholar's Gown" } },
        -- STR rings in every weaponskill with a STR modifier (ws_stat = WS that uses that stat)
        { ws_stat = 'str', items = { 'Ifrit Ring +1', 'Strigoi Ring' } },
        { ws = 'multi',  items = { 'Fotia Gorget' } },
        { ws = 'single', items = { 'Combatant Torque' } },
    },

    -- Stats to SET on specific items (corrects values the description doesn't show or words oddly).
    -- Other stats on the item are still read normally; this value replaces that one stat.
    stat_fix = {
        ['Brutal Earring +1'] = { da = 6 },
    },

    -- Stats to ignore on specific items (e.g. bonuses that only work in certain zones).
    -- The rest of the item's stats still count. Use the stat keys listed at the top.
    stat_remove = {
        ["Ares' Ring"] = { 'da' },     -- Double Attack +2% only in Lumoria
    },

    -- GearSwap export: CatsEyeXI renamed some items in its custom game files, but Windower/GearSwap
    -- still knows them by their ORIGINAL name. Map  ['Name in game'] = 'Original name'.
    gs_names = {
        ['Bagua Sash'] = 'Gishdubar Sash',
    },

    -- Jobs that also optimize the range slot in some sets (a ranged weapon there; ammo is left alone).
    -- Values: 'tp', 'ws' (set kinds) or set ids like 'Meditate'.
    job_range = {
        SAM = { 'tp', 'ws', 'Meditate' },
    },

    -- Items only these jobs may use (overrides the job list in the item's game data)
    job_restrict = {
        ['Kiryoku Nenju'] = { 'MNK' },
    },

    -- Items only used in these sets (e.g. movement gear stays out of idle/TP/etc.)
    set_restrict = {
        ['Kupo Suit'] = { 'Movement' },
    },

    -- Spell name filters used by the generated <midmagic> rules (wildcards * and | allowed)
    rules = {
        cure          = 'Cure*|Cura*',
        enfeebling_mnd = 'Slow*|Paralyze*|Silence|Addle*|Distract*|Frazzle*',
        elemental_dot = 'Burn|Frost|Choke|Rasp|Shock|Drown',
        song_debuff   = '*Requiem*|*Lullaby*|*Elegy*|*Threnody*|*Finale*|*Nocturne*',
        drain_aspir   = 'Drain*|Aspir*',
    },

    -- Elemental obis: worn on the waist when the spell element matches weather, day or a storm buff
    obis = {
        fire    = { obi = 'Karin Obi',  storm = 'Firestorm' },
        ice     = { obi = 'Hyorin Obi', storm = 'Hailstorm' },
        wind    = { obi = 'Furin Obi',  storm = 'Windstorm' },
        earth   = { obi = 'Dorin Obi',  storm = 'Sandstorm' },
        thunder = { obi = 'Rairin Obi', storm = 'Thunderstorm' },
        water   = { obi = 'Suirin Obi', storm = 'Rainstorm' },
        light   = { obi = 'Korin Obi',  storm = 'Aurorastorm' },
        dark    = { obi = 'Anrin Obi',  storm = 'Voidstorm' },
    },
    obi_all = 'Hachirin-no-Obi',     -- works for every element, used if you own it and lack the specific obi

    sets = {
        -- Melee
        TP          = { label = 'TP - Offense', kind = 'tp', caps = { haste = 25 },
                        weights = { combatskill = 0.9, stp = 5, da = 7, ta = 10, qa = 12, haste = 8, acc = 1.0, att = 0.5, str = 0.3, dex = 0.6, crit = 2, sb = 0.5, zanshin = 2 } },
        TP_Hybrid   = { label = 'TP - Hybrid (DT)', kind = 'tp', caps = { haste = 25, dt = -50, pdt = -50, mdt = -50 },
                        weights = { combatskill = 0.9, stp = 5, da = 7, ta = 10, qa = 12, haste = 8, acc = 1.0, att = 0.4, str = 0.2, dex = 0.5, crit = 1.5, zanshin = 2, dt = -6, pdt = -5, mdt = -2 } },
        TP_MNK      = { label = 'TP - Monk', kind = 'tp', name = 'TP', caps = { haste = 25 },
                        weights = { combatskill = 0.9, stp = 5, da = 7, ta = 10, qa = 12, haste = 8, acc = 1.0, att = 0.5, str = 0.3, dex = 0.6, crit = 2, ma = 3, kick = 3, counter = 1.5 } },
        -- Defensive / idle
        Idle        = { label = 'Idle', caps = DEF, weapons = true,
                        weights = { refresh = 30, regen = 12, dt = -6, pdt = -5, mdt = -3, mdb = 1, hp = 0.02, mp = 0.02 } },
        Idle_Avatar = { label = 'Idle - Avatar out', caps = DEF, weapons = true,
                        weights = { perp = 20, refresh = 25, summoning = 1, bloodboon = 1, dt = -3, pdt = -2, mdt = -2 } },
        Resting     = { label = 'Resting (MP)', weapons = true, weights = { hmp = 10, hhp = 2, refresh = 3 } },
        PDT         = { label = 'Physical defense', caps = DEF, weapons = true,
                        weights = { dt = -10, pdt = -10, bdt = -3, def = 0.1, hp = 0.05, eva = 0.3, curercv = 0.3 } },
        MDT         = { label = 'Magic defense', caps = DEF, weapons = true,
                        weights = { dt = -10, mdt = -10, mdb = 6, meva = 1, hp = 0.05 } },
        Movement    = { label = 'Movement speed', weights = { move = 20 } },
        -- Precast
        Precast      = { label = 'Precast - Fast Cast', caps = { fc = 80 }, weapons = true, weights = { fc = 10 } },
        Precast_Cure = { label = 'Precast - Cure', caps = { fc = 80, curect = 50 }, weapons = true, weights = { fc = 10, curect = 8 } },
        Precast_Song = { label = 'Precast - Songs', caps = { fc = 80, songct = 50 }, weapons = true, weights = { fc = 10, songct = 8 } },
        -- Midcast
        Cure          = { label = 'Cure potency', caps = { cure = 50 }, weapons = true,
                          weights = { cure = 12, mnd = 3, vit = 1, healing = 0.8, cmp = 0.5, enmity = -1, sird = 0.5 } },
        Healing       = { label = 'Healing magic skill', weapons = true, weights = { healing = 5, cmp = 0.5, sird = 1 } },
        Enhancing     = { label = 'Enhancing magic skill', weapons = true, weights = { enhancing = 5, enhdur = 2, cmp = 0.5, sird = 0.5, mnd = 0.3 } },
        Stoneskin     = { label = 'Stoneskin (MND)', weapons = true, weights = { mnd = 4, enhancing = 1.5 } },
        Enfeebling_MND = { label = 'Enfeebling - MND', weapons = true, weights = { mnd = 3, enfeebling = 3, macc = 3, enfdur = 1 } },
        Enfeebling_INT = { label = 'Enfeebling - INT', weapons = true, weights = { int = 3, enfeebling = 3, macc = 3, enfdur = 1 } },
        Divine        = { label = 'Divine magic', weapons = true, weights = { divine = 3, mnd = 2.5, mab = 5, macc = 2 } },
        Nuke          = { label = 'Elemental - Nuke', weapons = true, weights = { int = 2.5, mab = 10, macc = 1.5, elemental = 1.2, mbb = 5, mcrit = 3, mcritdmg = 2, mdmg = 1 } },
        Nuke_MB       = { label = 'Elemental - Magic Burst', caps = { mbb = 40 }, weapons = true,
                          weights = { mbb = 12, int = 2.5, mab = 9, macc = 1.5, elemental = 1, mcrit = 2, mcritdmg = 2, mdmg = 1 } },
        MagicAcc      = { label = 'Elemental - Accuracy', weapons = true, weights = { macc = 4, elemental = 3, int = 1.5 } },
        Dark          = { label = 'Dark - Stun/Bio/Absorb', weapons = true, weights = { dark = 3, macc = 4, int = 1 } },
        DrainAspir    = { label = 'Dark - Drain/Aspir', weapons = true, weights = { dark = 4, drain = 6, macc = 2, int = 0.5 } },
        Ninjutsu      = { label = 'Ninjutsu', weights = { ninjutsu = 4, int = 2, mab = 6, macc = 3 } },
        Songs_Buff    = { label = 'Songs - Buff', weapons = true, range = 'instrument',
                          weights = { singing = 3, string = 3, wind = 3, songdur = 3, chr = 0.5 } },
        Songs_Debuff  = { label = 'Songs - Debuff', weapons = true, range = 'instrument',
                          weights = { chr = 3, macc = 3, singing = 2, string = 2, wind = 2 } },
        BlueMagic     = { label = 'Blue magic skill', weights = { blue = 5, str = 0.5, dex = 0.5, mab = 1 } },
        Geomancy      = { label = 'Geomancy', weapons = true, weights = { geomancy = 5, handbell = 4, cmp = 0.5 } },
        BP_Delay      = { label = 'Blood Pact delay', caps = { bpdelay = 15, bpdelay2 = 15 }, weapons = true, weights = { bpdelay = 10, bpdelay2 = 10, summoning = 1 } },
        BloodPact     = { label = 'Blood Pact damage', weapons = true, weights = { bpdmg = 8, summoning = 3, bloodboon = 1 } },
        -- Utility
        Enmity      = { label = 'Enmity', caps = DEF, weights = { enmity = 6, hp = 0.05, dt = -2, pdt = -2, curercv = 0.3 } },
        TH          = { label = 'Treasure Hunter', weights = { th = 50, acc = 0.5, stp = 1 } },
        Waltz       = { label = 'Waltz potency', weights = { waltz = 10, chr = 1, vit = 1 } },
        Preshot     = { label = 'Ranged - Preshot', weights = { snapshot = 8, rapid = 6 } },
        Midshot     = { label = 'Ranged - Midshot', weights = { racc = 1.5, ratt = 1, agi = 1, stp = 3, crit = 2, recycle = 0.5 } },
        QuickDraw   = { label = 'Quick Draw', weights = { mab = 8, macc = 3, agi = 2, racc = 0.5 } },
        -- Fixed set: your exact pieces. Used ONLY for the weaponskills in ws_only, while the Mighty Strikes
        -- buff is active. Any piece you don't own is filled by the optimizer using the weights below.
        MightyStrikes = { label = 'Mighty Strikes (Upheaval / King\'s Justice)', buff = 'Mighty Strikes',
                          ws_only = { 'Upheaval', "King's Justice" },
                          weights = { critdmg = 6, str = 1.5, att = 1, acc = 0.5, wsd = 3 },
                          fixed = {
                              sub   = 'Brave Grip',
                              ammo  = "Fury's Edge",
                              head  = 'Hecatomb Cap +1',
                              body  = 'Reiki Osode',
                              hands = 'Hct. Mittens +1',
                              legs  = 'Jokushu Haidate',
                              feet  = 'Valk. Sabatons',
                              neck  = "Combatant's Torque",
                              waist = 'Fatality Belt',
                              ear1  = "Vulcan's Earring",
                              ear2  = 'Brutal Earring +1',
                              ring1 = 'Ifrit Ring +1',
                              ring2 = 'Strigoi Ring',
                              back  = 'Cerb. Mantle +1',
                          } },
        Meditate    = { label = 'Meditate', weights = { meditate = 10 } },
        Berserk     = { label = 'Berserk', weights = { berserk = 10 } },
        Warcry      = { label = 'Warcry', weights = { warcry = 10 } },
        Sublimation = { label = 'Sublimation', weights = { sublimation = 10 } },
        PhantomRoll = { label = 'Phantom Roll', range = 'any', weights = { roll = 10, rolldur = 2, rolldelay = 3, rollaoe = 6 } },
    },

    jobs = {
        WAR = { 'TP', 'TP_Hybrid', 'WS', 'Idle', 'PDT', 'MDT', 'Enmity', 'Movement', 'Berserk', 'Warcry', 'Meditate', 'MightyStrikes' },
        MNK = { 'TP_MNK', 'TP_Hybrid', 'WS', 'Idle', 'PDT', 'MDT', 'Waltz', 'Movement', 'Berserk', 'Warcry' },
        WHM = { 'Idle', 'Resting', 'Precast', 'Precast_Cure', 'Cure', 'Healing', 'Enhancing', 'Stoneskin', 'Enfeebling_MND', 'Divine', 'PDT', 'MDT', 'TP', 'WS', 'Sublimation' },
        BLM = { 'Idle', 'Resting', 'Precast', 'Nuke', 'Nuke_MB', 'MagicAcc', 'Dark', 'DrainAspir', 'Enfeebling_INT', 'Enhancing', 'Stoneskin', 'PDT', 'MDT' },
        RDM = { 'Idle', 'Resting', 'Precast', 'Precast_Cure', 'Cure', 'Enhancing', 'Stoneskin', 'Enfeebling_MND', 'Enfeebling_INT', 'Nuke', 'Nuke_MB', 'Dark', 'DrainAspir', 'TP', 'WS', 'PDT', 'MDT' },
        THF = { 'TP', 'TP_Hybrid', 'WS', 'TH', 'Idle', 'PDT', 'MDT', 'Preshot', 'Midshot', 'Movement', 'Berserk', 'Warcry' },
        PLD = { 'TP', 'TP_Hybrid', 'WS', 'Enmity', 'Idle', 'PDT', 'MDT', 'Precast', 'Cure', 'Enhancing', 'Divine', 'Berserk', 'Warcry', 'Meditate' },
        DRK = { 'TP', 'TP_Hybrid', 'WS', 'Idle', 'PDT', 'MDT', 'Precast', 'Dark', 'DrainAspir', 'Enfeebling_INT', 'Berserk', 'Warcry', 'Meditate' },
        BST = { 'TP', 'TP_Hybrid', 'WS', 'Idle', 'PDT', 'MDT', 'Berserk', 'Warcry' },
        BRD = { 'Idle', 'Resting', 'Precast', 'Precast_Song', 'Precast_Cure', 'Songs_Buff', 'Songs_Debuff', 'Cure', 'PDT', 'MDT', 'TP', 'WS' },
        RNG = { 'Preshot', 'Midshot', 'WS', 'Idle', 'PDT', 'MDT', 'TP', 'Berserk', 'Warcry' },
        SAM = { 'TP', 'TP_Hybrid', 'WS', 'Idle', 'PDT', 'MDT', 'Movement', 'Meditate', 'Berserk', 'Warcry' },
        NIN = { 'TP', 'TP_Hybrid', 'WS', 'Ninjutsu', 'Precast', 'Enmity', 'Idle', 'PDT', 'MDT', 'Movement', 'Berserk', 'Warcry' },
        DRG = { 'TP', 'TP_Hybrid', 'WS', 'Idle', 'PDT', 'MDT', 'Berserk', 'Warcry', 'Meditate' },
        SMN = { 'Idle', 'Idle_Avatar', 'Resting', 'Precast', 'BP_Delay', 'BloodPact', 'Cure', 'Enhancing', 'PDT', 'MDT' },
        BLU = { 'TP', 'TP_Hybrid', 'WS', 'BlueMagic', 'Precast', 'Cure', 'Nuke', 'Nuke_MB', 'Idle', 'PDT', 'MDT', 'Berserk', 'Warcry' },
        COR = { 'TP', 'TP_Hybrid', 'WS', 'Preshot', 'Midshot', 'QuickDraw', 'PhantomRoll', 'Idle', 'PDT', 'MDT', 'Berserk', 'Warcry' },
        PUP = { 'TP', 'TP_Hybrid', 'WS', 'Idle', 'PDT', 'MDT', 'Berserk', 'Warcry' },
        DNC = { 'TP', 'TP_Hybrid', 'WS', 'Waltz', 'Idle', 'PDT', 'MDT', 'Movement', 'Berserk', 'Warcry' },
        SCH = { 'Idle', 'Resting', 'Precast', 'Precast_Cure', 'Cure', 'Enhancing', 'Stoneskin', 'Enfeebling_MND', 'Enfeebling_INT', 'Nuke', 'Nuke_MB', 'MagicAcc', 'Dark', 'DrainAspir', 'PDT', 'MDT', 'Sublimation' },
        GEO = { 'Idle', 'Resting', 'Precast', 'Geomancy', 'Nuke', 'Nuke_MB', 'Enfeebling_INT', 'Cure', 'PDT', 'MDT' },
        RUN = { 'TP', 'TP_Hybrid', 'WS', 'Enmity', 'Idle', 'PDT', 'MDT', 'Enhancing', 'Precast', 'Berserk', 'Warcry' },
    },

    -- Weapon types whose weaponskills get a set in each job's XML (skill names as in the list below).
    job_weapons = {
        WAR = { 'Great Axe', 'Axe', 'Great Sword', 'Sword', 'Polearm' },
        MNK = { 'Hand-to-Hand', 'Staff' },
        WHM = { 'Club', 'Staff' },
        BLM = { 'Staff', 'Club' },
        RDM = { 'Sword', 'Dagger' },
        THF = { 'Dagger', 'Sword' },
        PLD = { 'Sword', 'Club', 'Great Sword' },
        DRK = { 'Great Sword', 'Scythe', 'Great Axe' },
        BST = { 'Axe', 'Scythe' },
        BRD = { 'Dagger', 'Sword' },
        RNG = { 'Archery', 'Marksmanship', 'Axe', 'Dagger' },
        SAM = { 'Great Katana', 'Polearm', 'Archery' },
        NIN = { 'Katana', 'Dagger' },
        DRG = { 'Polearm' },
        SMN = { 'Staff', 'Club' },
        BLU = { 'Sword', 'Club' },
        COR = { 'Marksmanship', 'Sword', 'Dagger' },
        PUP = { 'Hand-to-Hand' },
        DNC = { 'Dagger' },
        SCH = { 'Staff', 'Club' },
        GEO = { 'Club', 'Staff' },
        RUN = { 'Great Sword', 'Sword' },
    },

    -- Every player weaponskill, generated from LandSandBoat (scripts/actions/weaponskills + sql/weapon_skills.sql),
    -- the server software CatsEyeXI runs on. Pre-Adoulin modifier values. id = weaponskill id used in the XML rules.
    weaponskills = {
        -- Generic fallbacks used for the default 'WS' set
        { name = 'Generic: single hit (STR)', jobs = { '*' }, kind = 'physical', hits = 1, mods = { str = 0.60 } },
        { name = 'Generic: multi hit (STR)',  jobs = { '*' }, kind = 'physical', hits = 4, mods = { str = 0.50 } },
        { name = 'Generic: crit (DEX)',       jobs = { '*' }, kind = 'physical', hits = 3, crit = true, mods = { dex = 0.60 } },
        { name = 'Generic: ranged (AGI)',     jobs = { '*' }, kind = 'ranged', hits = 1, mods = { agi = 0.60 } },
        { name = 'Generic: magical (INT)',    jobs = { '*' }, kind = 'magical', hits = 1, mods = { int = 0.60 } },

        -- Hand-to-Hand
        { id = 11, name = 'Ascetic\'s Fury', skill = 1, jobs = { 'MNK' }, kind = 'physical', hits = 2, crit = true, mods = { str = 0.50, vit = 0.50 } },
        { id = 10, name = 'Final Heaven', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 2, mods = { vit = 0.60 } },
        { id = 12, name = 'Stringing Pummel', skill = 1, jobs = { 'PUP' }, kind = 'physical', hits = 6, crit = true, mods = { str = 0.32, vit = 0.32 } },
        { id = 14, name = 'Victory Smite', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 4, crit = true, mods = { str = 0.60 } },
        { id = 1, name = 'Combo', skill = 1, jobs = { 'WAR', 'MNK', 'THF', 'NIN', 'PUP', 'DNC' }, kind = 'physical', hits = 3, mods = { dex = 0.20, str = 0.20 } },
        { id = 2, name = 'Shoulder Tackle', skill = 1, jobs = { 'WAR', 'MNK', 'THF', 'NIN', 'PUP', 'DNC' }, kind = 'physical', hits = 2, mods = { vit = 0.30 } },
        { id = 3, name = 'One Inch Punch', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 2, mods = { vit = 0.40 } },
        { id = 4, name = 'Backhand Blow', skill = 1, jobs = { 'WAR', 'MNK', 'THF', 'NIN', 'PUP', 'DNC' }, kind = 'physical', hits = 2, crit = true, mods = { dex = 0.30, str = 0.30 } },
        { id = 5, name = 'Raging Fists', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 5, mods = { dex = 0.20, str = 0.20 } },
        { id = 6, name = 'Spinning Attack', skill = 1, jobs = { 'WAR', 'MNK', 'THF', 'NIN', 'PUP', 'DNC' }, kind = 'physical', hits = 2, mods = { str = 0.35 } },
        { id = 7, name = 'Howling Fist', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 2, mods = { str = 0.20, vit = 0.50 } },
        { id = 8, name = 'Dragon Kick', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 2, mods = { str = 0.50, vit = 0.50 } },
        { id = 9, name = 'Asuran Fists', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 8, mods = { str = 0.10, vit = 0.10 } },
        { id = 13, name = 'Tornado Kick', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 3, mods = { str = 0.32, vit = 0.32 } },
        { id = 15, name = 'Shijin Spiral', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 5, mods = { dex = 0.70 } },

        -- Dagger
        { id = 27, name = 'Mandalic Stab', skill = 2, jobs = { 'THF' }, kind = 'physical', hits = 1, mods = { dex = 0.30 } },
        { id = 26, name = 'Mercy Stroke', skill = 2, jobs = { 'WAR', 'RDM', 'THF', 'BST', 'BRD', 'RNG', 'NIN', 'COR', 'DNC' }, kind = 'physical', hits = 1, mods = { str = 0.60 } },
        { id = 28, name = 'Mordant Rime', skill = 2, jobs = { 'BRD' }, kind = 'physical', hits = 2, mods = { chr = 0.50, dex = 0.30 } },
        { id = 29, name = 'Pyrrhic Kleos', skill = 2, jobs = { 'DNC' }, kind = 'physical', hits = 4, mods = { dex = 0.30, str = 0.20 } },
        { id = 31, name = 'Rudra\'s Storm', skill = 2, jobs = { 'THF', 'BRD', 'DNC' }, kind = 'physical', hits = 1, mods = { dex = 0.60 } },
        { id = 16, name = 'Wasp Sting', skill = 2, jobs = { 'WAR', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'COR', 'PUP', 'DNC', 'SCH' }, kind = 'physical', hits = 1, mods = { dex = 1.00 } },
        { id = 19, name = 'Gust Slash', skill = 2, jobs = { 'WAR', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'COR', 'PUP', 'DNC', 'SCH' }, kind = 'magical', hits = 1, mods = { dex = 0.20, int = 0.20 } },
        { id = 18, name = 'Shadowstitch', skill = 2, jobs = { 'WAR', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'COR', 'PUP', 'DNC', 'SCH' }, kind = 'physical', hits = 1, mods = { chr = 0.30 } },
        { id = 17, name = 'Viper Bite', skill = 2, jobs = { 'RDM', 'THF', 'BRD', 'RNG', 'NIN', 'DNC' }, kind = 'physical', hits = 1, mods = { dex = 1.00 } },
        { id = 20, name = 'Cyclone', skill = 2, jobs = { 'RDM', 'THF', 'BRD', 'RNG', 'NIN', 'DNC' }, kind = 'magical', hits = 1, mods = { dex = 0.30, int = 0.25 } },
        { id = 21, name = 'Energy Steal', skill = 2, jobs = { 'WAR', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'COR', 'PUP', 'DNC', 'SCH' }, kind = 'physical', hits = 1, mods = {  } },
        { id = 22, name = 'Energy Drain', skill = 2, jobs = { 'RDM', 'THF', 'BRD', 'RNG', 'NIN', 'DNC' }, kind = 'physical', hits = 1, mods = {  } },
        { id = 23, name = 'Dancing Edge', skill = 2, jobs = { 'THF', 'DNC' }, kind = 'physical', hits = 5, mods = { chr = 0.40, dex = 0.30 } },
        { id = 24, name = 'Shark Bite', skill = 2, jobs = { 'THF', 'DNC' }, kind = 'physical', hits = 2, mods = { agi = 0.40, dex = 0.50 } },
        { id = 25, name = 'Evisceration', skill = 2, jobs = { 'WAR', 'RDM', 'THF', 'BST', 'BRD', 'RNG', 'NIN', 'COR', 'DNC' }, kind = 'physical', hits = 5, crit = true, mods = { dex = 0.30 } },
        { id = 30, name = 'Dagger weapon skill', skill = 2, jobs = { 'RDM', 'THF', 'BRD', 'RNG', 'NIN', 'DNC' }, kind = 'magical', hits = 1, mods = { dex = 0.28, int = 0.28 } },
        { id = 224, name = 'Exenterator', skill = 2, jobs = { 'WAR', 'RDM', 'THF', 'BST', 'BRD', 'RNG', 'NIN', 'COR', 'DNC' }, kind = 'physical', hits = 4, mods = { agi = 0.70 } },

        -- Sword
        { id = 45, name = 'Atonement', skill = 3, jobs = { 'PLD' }, kind = 'physical', hits = 2, mods = { str = 0.40, vit = 0.50 } },
        { id = 225, name = 'Chant du Cygne', skill = 3, jobs = { 'RDM', 'PLD', 'BLU' }, kind = 'physical', hits = 3, crit = true, mods = { dex = 0.60 } },
        { id = 44, name = 'Death Blossom', skill = 3, jobs = { 'RDM' }, kind = 'physical', hits = 3, mods = { mnd = 0.50, str = 0.30 } },
        { id = 46, name = 'Expiacion', skill = 3, jobs = { 'BLU' }, kind = 'physical', hits = 2, mods = { dex = 0.20, int = 0.30, str = 0.30 } },
        { id = 43, name = 'Knights of Round', skill = 3, jobs = { 'WAR', 'RDM', 'PLD', 'DRK', 'SAM', 'BLU', 'COR', 'RUN' }, kind = 'physical', hits = 1, mods = { mnd = 0.40, str = 0.40 } },
        { id = 32, name = 'Fast Blade', skill = 3, jobs = { 'WAR', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'RUN' }, kind = 'physical', hits = 2, mods = { dex = 0.20, str = 0.20 } },
        { id = 33, name = 'Burning Blade', skill = 3, jobs = { 'WAR', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'RUN' }, kind = 'magical', hits = 1, mods = { int = 0.20, str = 0.20 } },
        { id = 34, name = 'Red Lotus Blade', skill = 3, jobs = { 'WAR', 'RDM', 'PLD', 'DRK', 'BLU', 'RUN' }, kind = 'magical', hits = 1, mods = { int = 0.20, str = 0.30 } },
        { id = 35, name = 'Flat Blade', skill = 3, jobs = { 'WAR', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 36, name = 'Shining Blade', skill = 3, jobs = { 'WAR', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'RUN' }, kind = 'magical', hits = 1, mods = { mnd = 0.20, str = 0.20 } },
        { id = 37, name = 'Seraph Blade', skill = 3, jobs = { 'WAR', 'RDM', 'PLD', 'DRK', 'BLU', 'RUN' }, kind = 'magical', hits = 1, mods = { mnd = 0.30, str = 0.30 } },
        { id = 38, name = 'Circle Blade', skill = 3, jobs = { 'WAR', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.35 } },
        { id = 39, name = 'Spirits Within', skill = 3, jobs = { 'WAR', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'RUN' }, kind = 'physical', hits = 1, mods = {  } },
        { id = 40, name = 'Vorpal Blade', skill = 3, jobs = { 'WAR', 'RDM', 'PLD', 'DRK', 'BLU', 'RUN' }, kind = 'physical', hits = 4, crit = true, mods = { str = 0.30 } },
        { id = 41, name = 'Swift Blade', skill = 3, jobs = { 'PLD', 'RUN' }, kind = 'physical', hits = 3, mods = { mnd = 0.30, str = 0.30 } },
        { id = 42, name = 'Savage Blade', skill = 3, jobs = { 'WAR', 'RDM', 'PLD', 'DRK', 'BLU', 'COR', 'RUN' }, kind = 'physical', hits = 2, mods = { mnd = 0.50, str = 0.30 } },
        { id = 47, name = 'Sanguine Blade', skill = 3, jobs = { 'WAR', 'RDM', 'PLD', 'DRK', 'BLU', 'RUN' }, kind = 'magical', hits = 1, mods = { mnd = 0.50, str = 0.30 } },
        { id = 226, name = 'Requiescat', skill = 3, jobs = { 'WAR', 'RDM', 'PLD', 'DRK', 'SAM', 'BLU', 'COR', 'RUN' }, kind = 'physical', hits = 5, mods = { mnd = 0.70 } },

        -- Great Sword
        { id = 61, name = 'Dimidiation', skill = 4, jobs = { 'RUN' }, kind = 'physical', hits = 2, mods = { dex = 0.80 } },
        { id = 57, name = 'Scourge', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { chr = 0.40, mnd = 0.40, str = 0.40, vit = 0.40 } },
        { id = 59, name = 'Torcleaver', skill = 4, jobs = { 'PLD', 'DRK' }, kind = 'physical', hits = 1, mods = { vit = 0.60 } },
        { id = 48, name = 'Hard Slash', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 49, name = 'Power Slash', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 1, crit = true, mods = { str = 0.20, vit = 0.20 } },
        { id = 50, name = 'Frostbite', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'magical', hits = 1, mods = { int = 0.20, str = 0.20 } },
        { id = 51, name = 'Freezebite', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'magical', hits = 1, mods = { int = 0.20, str = 0.30 } },
        { id = 52, name = 'Shockwave', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { mnd = 0.30, str = 0.30 } },
        { id = 53, name = 'Crescent Moon', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.35 } },
        { id = 54, name = 'Sickle Moon', skill = 4, jobs = { 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 2, mods = { agi = 0.20, str = 0.20 } },
        { id = 55, name = 'Spinning Slash', skill = 4, jobs = { 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { int = 0.30, str = 0.30 } },
        { id = 56, name = 'Ground Strike', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { int = 0.50, str = 0.50 } },
        { id = 58, name = 'Herculean Slash', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'magical', hits = 1, mods = { vit = 0.60 } },
        { id = 60, name = 'Resolution', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 5, mods = { str = 0.70 } },

        -- Axe
        { id = 76, name = 'Cloudsplitter', skill = 5, jobs = { 'WAR', 'BST' }, kind = 'magical', hits = 1, mods = { mnd = 0.40, str = 0.40 } },
        { id = 73, name = 'Onslaught', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 1, mods = { dex = 0.60 } },
        { id = 74, name = 'Primal Rend', skill = 5, jobs = { 'BST' }, kind = 'magical', hits = 1, mods = { chr = 0.30, dex = 0.30 } },
        { id = 64, name = 'Raging Axe', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 2, mods = { str = 0.30 } },
        { id = 65, name = 'Smash Axe', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 66, name = 'Gale Axe', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 67, name = 'Avalanche Axe', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 68, name = 'Spinning Axe', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.35 } },
        { id = 69, name = 'Rampage', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 5, crit = true, mods = { str = 0.30 } },
        { id = 70, name = 'Calamity', skill = 5, jobs = { 'WAR', 'BST' }, kind = 'physical', hits = 1, mods = { str = 0.32, vit = 0.32 } },
        { id = 71, name = 'Mistral Axe', skill = 5, jobs = { 'WAR', 'BST' }, kind = 'physical', hits = 1, mods = { str = 0.50 } },
        { id = 72, name = 'Decimation', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 3, mods = { str = 0.50 } },
        { id = 75, name = 'Bora Axe', skill = 5, jobs = { 'WAR', 'BST' }, kind = 'physical', hits = 1, mods = { dex = 0.60 } },
        { id = 77, name = 'Ruinator', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 4, mods = { str = 0.70 } },

        -- Great Axe
        { id = 90, name = 'King\'s Justice', skill = 6, jobs = { 'WAR' }, kind = 'physical', hits = 3, mods = { str = 1.00 } },  -- CatsEyeXI: full STR
        { id = 89, name = 'Metatron Torment', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.60 } },
        { id = 92, name = 'Ukko\'s Fury', skill = 6, jobs = { 'WAR' }, kind = 'physical', hits = 2, crit = true, mods = { str = 0.60 } },
        { id = 80, name = 'Shield Break', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.20, vit = 0.20 } },
        { id = 81, name = 'Iron Tempest', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 82, name = 'Sturmwind', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 2, mods = { str = 0.30 } },
        { id = 83, name = 'Armor Break', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.20, vit = 0.20 } },
        { id = 84, name = 'Keen Edge', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, crit = true, mods = { str = 0.35 } },
        { id = 85, name = 'Weapon Break', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.32, vit = 0.32 } },
        { id = 86, name = 'Raging Rush', skill = 6, jobs = { 'WAR' }, kind = 'physical', hits = 3, crit = true, mods = { str = 0.35 } },
        { id = 87, name = 'Full Break', skill = 6, jobs = { 'WAR' }, kind = 'physical', hits = 1, mods = { str = 0.50, vit = 0.50 } },
        { id = 88, name = 'Steel Cyclone', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.50, vit = 0.50 } },
        { id = 91, name = 'Fell Cleave', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.60 } },
        { id = 93, name = 'Upheaval', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 4, mods = { str = 1.00 } },  -- CatsEyeXI: full STR

        -- Scythe
        { id = 105, name = 'Catastrophe', skill = 7, jobs = { 'WAR', 'DRK', 'BST' }, kind = 'physical', hits = 1, mods = { agi = 0.40, int = 0.40, str = 0.40 } },
        { id = 106, name = 'Insurgency', skill = 7, jobs = { 'DRK' }, kind = 'physical', hits = 4, mods = { int = 0.20, str = 0.20 } },
        { id = 108, name = 'Quietus', skill = 7, jobs = { 'DRK' }, kind = 'physical', hits = 1, mods = { mnd = 0.40, str = 0.40 } },
        { id = 96, name = 'Slice', skill = 7, jobs = { 'WAR', 'BLM', 'DRK', 'BST' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 97, name = 'Dark Harvest', skill = 7, jobs = { 'WAR', 'BLM', 'DRK', 'BST' }, kind = 'magical', hits = 1, mods = { int = 0.20, str = 0.20 } },
        { id = 98, name = 'Shadow of Death', skill = 7, jobs = { 'WAR', 'DRK' }, kind = 'magical', hits = 1, mods = { int = 0.30, str = 0.30 } },
        { id = 99, name = 'Nightmare Scythe', skill = 7, jobs = { 'WAR', 'BLM', 'DRK', 'BST' }, kind = 'physical', hits = 1, mods = { mnd = 0.30, str = 0.30 } },
        { id = 100, name = 'Spinning Scythe', skill = 7, jobs = { 'WAR', 'BLM', 'DRK', 'BST' }, kind = 'physical', hits = 1, mods = { mnd = 0.60, str = 0.30 } },
        { id = 101, name = 'Vorpal Scythe', skill = 7, jobs = { 'WAR', 'BLM', 'DRK', 'BST' }, kind = 'physical', hits = 1, crit = true, mods = { str = 0.35 } },
        { id = 102, name = 'Guillotine', skill = 7, jobs = { 'DRK' }, kind = 'physical', hits = 4, mods = { mnd = 0.25, str = 0.25 } },
        { id = 103, name = 'Cross Reaper', skill = 7, jobs = { 'DRK' }, kind = 'physical', hits = 2, mods = { mnd = 0.30, str = 0.30 } },
        { id = 104, name = 'Spiral Hell', skill = 7, jobs = { 'WAR', 'DRK', 'BST' }, kind = 'physical', hits = 1, mods = { int = 0.50, str = 0.50 } },
        { id = 107, name = 'Infernal Scythe', skill = 7, jobs = { 'WAR', 'BLM', 'DRK', 'BST' }, kind = 'magical', hits = 1, mods = { int = 0.30, str = 0.30 } },
        { id = 109, name = 'Entropy', skill = 7, jobs = { 'WAR', 'DRK', 'BST' }, kind = 'physical', hits = 4, mods = { int = 0.70 } },

        -- Polearm
        { id = 124, name = 'Camlann\'s Torment', skill = 8, jobs = { 'DRG' }, kind = 'physical', hits = 1, mods = { str = 0.60, vit = 0.60 } },
        { id = 122, name = 'Drakesbane', skill = 8, jobs = { 'DRG' }, kind = 'physical', hits = 4, crit = true, mods = { str = 0.50 } },
        { id = 121, name = 'Geirskogul', skill = 8, jobs = { 'WAR', 'SAM', 'DRG' }, kind = 'physical', hits = 1, mods = { agi = 0.60, dex = 0.80 } },
        { id = 112, name = 'Double Thrust', skill = 8, jobs = { 'WAR', 'PLD', 'SAM', 'DRG' }, kind = 'physical', hits = 2, mods = { dex = 0.30, str = 0.30 } },
        { id = 113, name = 'Thunder Thrust', skill = 8, jobs = { 'WAR', 'PLD', 'SAM', 'DRG' }, kind = 'magical', hits = 1, mods = { int = 0.20, str = 0.20 } },
        { id = 114, name = 'Raiden Thrust', skill = 8, jobs = { 'WAR', 'PLD', 'DRG' }, kind = 'magical', hits = 1, mods = { int = 0.30, str = 0.30 } },
        { id = 115, name = 'Leg Sweep', skill = 8, jobs = { 'WAR', 'PLD', 'SAM', 'DRG' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 116, name = 'Penta Thrust', skill = 8, jobs = { 'WAR', 'PLD', 'SAM', 'DRG' }, kind = 'physical', hits = 5, mods = { dex = 0.20, str = 0.20 } },
        { id = 117, name = 'Vorpal Thrust', skill = 8, jobs = { 'WAR', 'PLD', 'SAM', 'DRG' }, kind = 'physical', hits = 1, crit = true, mods = { agi = 0.20, str = 0.20 } },
        { id = 118, name = 'Skewer', skill = 8, jobs = { 'DRG' }, kind = 'physical', hits = 3, crit = true, mods = { str = 0.35 } },
        { id = 119, name = 'Wheeling Thrust', skill = 8, jobs = { 'DRG' }, kind = 'physical', hits = 1, mods = { str = 0.50 } },
        { id = 120, name = 'Impulse Drive', skill = 8, jobs = { 'WAR', 'SAM', 'DRG' }, kind = 'physical', hits = 2, mods = { str = 0.50 } },
        { id = 123, name = 'Sonic Thrust', skill = 8, jobs = { 'WAR', 'PLD', 'DRG' }, kind = 'physical', hits = 1, mods = { dex = 0.30, str = 0.30 } },
        { id = 125, name = 'Stardiver', skill = 8, jobs = { 'WAR', 'SAM', 'DRG' }, kind = 'physical', hits = 4, mods = { str = 0.70 } },

        -- Katana
        { id = 140, name = 'Blade: Hi', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 1, crit = true, mods = { agi = 0.60 } },
        { id = 138, name = 'Blade: Kamu', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 1, mods = { int = 0.50, str = 0.50 } },
        { id = 137, name = 'Blade: Metsu', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 1, mods = { dex = 0.60 } },
        { id = 128, name = 'Blade: Rin', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 1, crit = true, mods = { dex = 0.20, str = 0.20 } },
        { id = 129, name = 'Blade: Retsu', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 2, mods = { dex = 0.20, str = 0.20 } },
        { id = 130, name = 'Blade: Teki', skill = 9, jobs = { 'NIN' }, kind = 'hybrid', hits = 1, mods = { int = 0.20, str = 0.20 } },
        { id = 131, name = 'Blade: To', skill = 9, jobs = { 'NIN' }, kind = 'hybrid', hits = 1, mods = { int = 0.30, str = 0.30 } },
        { id = 132, name = 'Blade: Chi', skill = 9, jobs = { 'NIN' }, kind = 'hybrid', hits = 2, mods = { int = 0.20, str = 0.20 } },
        { id = 133, name = 'Blade: Ei', skill = 9, jobs = { 'NIN' }, kind = 'magical', hits = 1, mods = { int = 0.30, str = 0.30 } },
        { id = 134, name = 'Blade: Jin', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 3, crit = true, mods = { dex = 0.30, str = 0.30 } },
        { id = 135, name = 'Blade: Ten', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 1, mods = { dex = 0.30, str = 0.30 } },
        { id = 136, name = 'Blade: Ku', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 5, mods = { dex = 0.10, str = 0.10 } },
        { id = 139, name = 'Blade: Yu', skill = 9, jobs = { 'NIN' }, kind = 'magical', hits = 1, mods = { dex = 0.28, int = 0.28 } },
        { id = 141, name = 'Blade: Shun', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 5, mods = { dex = 0.70 } },

        -- Great Katana
        { id = 156, name = 'Tachi: Fudo', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 1, mods = { str = 0.60 } },
        { id = 153, name = 'Tachi: Kaiten', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 1, mods = { str = 0.60 } },
        { id = 154, name = 'Tachi: Rana', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 3, mods = { str = 0.35 } },
        { id = 158, name = 'Tachi: Suikawari', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 2, mods = { str = 0.60 } },
        { id = 144, name = 'Tachi: Enpi', skill = 10, jobs = { 'SAM', 'NIN' }, kind = 'physical', hits = 2, mods = { str = 0.30 } },
        { id = 145, name = 'Tachi: Hobaku', skill = 10, jobs = { 'SAM', 'NIN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 146, name = 'Tachi: Goten', skill = 10, jobs = { 'SAM', 'NIN' }, kind = 'hybrid', hits = 1, mods = { str = 0.30 } },
        { id = 147, name = 'Tachi: Kagero', skill = 10, jobs = { 'SAM', 'NIN' }, kind = 'hybrid', hits = 1, mods = { str = 0.50 } },
        { id = 148, name = 'Tachi: Jinpu', skill = 10, jobs = { 'SAM', 'NIN' }, kind = 'hybrid', hits = 2, mods = { str = 0.40 } },
        { id = 149, name = 'Tachi: Koki', skill = 10, jobs = { 'SAM', 'NIN' }, kind = 'hybrid', hits = 1, mods = { mnd = 0.30, str = 0.50 } },
        { id = 150, name = 'Tachi: Yukikaze', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 1, mods = { str = 0.75 } },
        { id = 151, name = 'Tachi: Gekko', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 1, mods = { str = 0.75 } },
        { id = 152, name = 'Tachi: Kasha', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 1, mods = { str = 0.75 } },
        { id = 155, name = 'Tachi: Ageha', skill = 10, jobs = { 'SAM', 'NIN' }, kind = 'physical', hits = 1, mods = { chr = 0.50, str = 0.40 } },
        { id = 157, name = 'Tachi: Shoha', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 2, mods = { str = 0.70 } },

        -- Club
        { id = 173, name = 'Dagan', skill = 11, jobs = { 'WHM' }, kind = 'physical', hits = 1, mods = {  } },
        { id = 171, name = 'Mystic Boon', skill = 11, jobs = { 'WHM' }, kind = 'physical', hits = 1, mods = { mnd = 0.50, str = 0.30 } },
        { id = 170, name = 'Randgrith', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'SMN', 'BLU', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 1, mods = { mnd = 0.40, str = 0.40 } },
        { id = 160, name = 'Shining Strike', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'PUP', 'SCH', 'GEO', 'RUN' }, kind = 'magical', hits = 1, mods = { mnd = 0.20, str = 0.20 } },
        { id = 161, name = 'Seraph Strike', skill = 11, jobs = { 'WAR', 'WHM', 'PLD', 'DRK', 'SAM', 'BLU', 'GEO' }, kind = 'magical', hits = 1, mods = { mnd = 0.30, str = 0.30 } },
        { id = 162, name = 'Brainshaker', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'PUP', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 163, name = 'Starlight', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'PUP', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 1, mods = {  } },
        { id = 164, name = 'Moonlight', skill = 11, jobs = { 'WAR', 'WHM', 'PLD', 'DRK', 'SAM', 'BLU', 'SCH', 'GEO' }, kind = 'physical', hits = 1, mods = {  } },
        { id = 165, name = 'Skullbreaker', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'PUP', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 166, name = 'True Strike', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'PUP', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 1, crit = true, mods = { str = 0.50 } },
        { id = 167, name = 'Judgment', skill = 11, jobs = { 'WAR', 'WHM', 'PLD', 'DRK', 'SAM', 'BLU', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 1, mods = { mnd = 0.32, str = 0.32 } },
        { id = 168, name = 'Hexa Strike', skill = 11, jobs = { 'WHM', 'GEO' }, kind = 'physical', hits = 6, crit = true, mods = { mnd = 0.20, str = 0.20 } },
        { id = 169, name = 'Black Halo', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'SMN', 'BLU', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 2, mods = { mnd = 0.50, str = 0.30 } },
        { id = 172, name = 'Flash Nova', skill = 11, jobs = { 'WAR', 'WHM', 'PLD', 'BLU', 'GEO' }, kind = 'magical', hits = 1, mods = { mnd = 0.30, str = 0.30 } },
        { id = 174, name = 'Realmrazer', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'SMN', 'BLU', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 7, mods = { mnd = 0.70 } },

        -- Staff
        { id = 187, name = 'Garland of Bliss', skill = 12, jobs = { 'SMN' }, kind = 'magical', hits = 1, mods = { mnd = 0.40, str = 0.30 } },
        { id = 185, name = 'Gate of Tartarus', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'physical', hits = 1, mods = { chr = 0.60 } },
        { id = 190, name = 'Myrkr', skill = 12, jobs = { 'BLM', 'SMN', 'SCH' }, kind = 'physical', hits = 1, mods = {  } },
        { id = 188, name = 'Omniscience', skill = 12, jobs = { 'SCH' }, kind = 'magical', hits = 1, mods = { mnd = 0.30 } },
        { id = 186, name = 'Vidohunir', skill = 12, jobs = { 'BLM' }, kind = 'magical', hits = 1, mods = { int = 0.30 } },
        { id = 176, name = 'Heavy Swing', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 177, name = 'Rock Crusher', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'magical', hits = 1, mods = { int = 0.20, str = 0.20 } },
        { id = 178, name = 'Earth Crusher', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'PLD', 'SCH', 'GEO' }, kind = 'magical', hits = 1, mods = { int = 0.30, str = 0.30 } },
        { id = 179, name = 'Starburst', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'magical', hits = 1, mods = { mnd = 0.40, str = 0.40 } },
        { id = 180, name = 'Sunburst', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'PLD', 'SCH', 'GEO' }, kind = 'magical', hits = 1, mods = { mnd = 0.40, str = 0.40 } },
        { id = 181, name = 'Shell Crusher', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'physical', hits = 1, mods = { str = 0.35 } },
        { id = 182, name = 'Full Swing', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'physical', hits = 1, mods = { str = 0.50 } },
        { id = 183, name = 'Spirit Taker', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'physical', hits = 1, mods = { int = 0.50, mnd = 0.50 } },
        { id = 184, name = 'Retribution', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'physical', hits = 1, mods = { mnd = 0.50, str = 0.30 } },
        { id = 189, name = 'Cataclysm', skill = 12, jobs = { 'MNK', 'PLD', 'SMN', 'GEO' }, kind = 'magical', hits = 1, mods = { int = 0.30, mnd = 0.30, str = 0.30 } },
        { id = 191, name = 'Shattersoul', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'physical', hits = 3, mods = { int = 0.70 } },

        -- Archery
        { id = 202, name = 'Jishnu\'s Radiance', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 3, crit = true, mods = { dex = 0.60 } },
        { id = 200, name = 'Namas Arrow', skill = 25, jobs = { 'RNG', 'SAM' }, kind = 'ranged', hits = 1, mods = { agi = 0.40, str = 0.40 } },
        { id = 192, name = 'Flaming Arrow', skill = 25, jobs = { 'RNG' }, kind = 'hybrid', hits = 1, mods = { agi = 0.25, str = 0.16 } },
        { id = 193, name = 'Piercing Arrow', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 1, mods = { agi = 0.25, str = 0.16 } },
        { id = 194, name = 'Dulling Arrow', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 1, crit = true, mods = { agi = 0.25, str = 0.16 } },
        { id = 196, name = 'Sidewinder', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 1, mods = { agi = 0.25, str = 0.16 } },
        { id = 197, name = 'Blast Arrow', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 1, mods = { agi = 0.25, str = 0.16 } },
        { id = 198, name = 'Arching Arrow', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 1, crit = true, mods = { agi = 0.25, str = 0.16 } },
        { id = 199, name = 'Empyreal Arrow', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 1, mods = { agi = 0.25, str = 0.16 } },
        { id = 201, name = 'Refulgent Arrow', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 2, mods = { str = 0.16 } },
        { id = 203, name = 'Apex Arrow', skill = 25, jobs = { 'RNG', 'SAM' }, kind = 'ranged', hits = 1, mods = { agi = 0.70 } },

        -- Marksmanship
        { id = 216, name = 'Coronach', skill = 26, jobs = { 'THF', 'RNG', 'COR' }, kind = 'ranged', hits = 1, mods = { agi = 0.40, dex = 0.40 } },
        { id = 218, name = 'Leaden Salute', skill = 26, jobs = { 'COR' }, kind = 'magical', hits = 1, mods = { agi = 0.30 } },
        { id = 217, name = 'Trueflight', skill = 26, jobs = { 'RNG' }, kind = 'magical', hits = 1, mods = { agi = 0.30 } },
        { id = 220, name = 'Wildfire', skill = 26, jobs = { 'RNG', 'COR' }, kind = 'magical', hits = 1, mods = { agi = 0.60 } },
        { id = 208, name = 'Hot Shot', skill = 26, jobs = { 'RNG', 'COR' }, kind = 'hybrid', hits = 1, mods = { agi = 0.30 } },
        { id = 209, name = 'Split Shot', skill = 26, jobs = { 'RNG', 'COR' }, kind = 'ranged', hits = 1, mods = { agi = 0.30 } },
        { id = 210, name = 'Sniper Shot', skill = 26, jobs = { 'RNG', 'COR' }, kind = 'ranged', hits = 1, mods = { agi = 0.30 } },
        { id = 212, name = 'Slug Shot', skill = 26, jobs = { 'RNG', 'COR' }, kind = 'ranged', hits = 1, mods = { agi = 0.30 } },
        { id = 213, name = 'Blast Shot', skill = 26, jobs = { 'RNG' }, kind = 'ranged', hits = 1, mods = { agi = 0.30 } },
        { id = 214, name = 'Heavy Shot', skill = 26, jobs = { 'RNG' }, kind = 'ranged', hits = 1, crit = true, mods = { agi = 0.30 } },
        { id = 215, name = 'Detonator', skill = 26, jobs = { 'RNG', 'COR' }, kind = 'ranged', hits = 1, mods = { agi = 0.30 } },
        { id = 219, name = 'Numbing Shot', skill = 26, jobs = { 'RNG', 'COR' }, kind = 'ranged', hits = 1, mods = { agi = 0.60 } },
        { id = 221, name = 'Last Stand', skill = 26, jobs = { 'THF', 'RNG', 'COR' }, kind = 'ranged', hits = 2, mods = { agi = 0.70 } },
    },
};
