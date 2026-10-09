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
                sk_dagger sk_sword sk_gsword sk_axe sk_gaxe sk_scythe sk_polearm sk_katana sk_gkatana sk_club sk_staff sk_h2h  (weapon skill +N: counted
                like Combat Skill, only for the weapon types the job uses in job_weapons)
    (curect, songct, sird, perp, bpdelay are stored as the amount reduced: higher = better)
    range = 'any' lets a set swap the range slot (e.g. Opprimo for Phantom Roll); ammo is then left alone.
    ranged = 'job' / 'Archery' / 'Marksmanship' puts the job's BiS ranged weapon (ranged_weapons) on that set.
    pref_slots = { 'range', 'ammo' } makes those slots take only the pieces you list (never an automatic pick).
    info = { ... } makes a set a plain list instead of gear (used for the PUP automaton attachments).
    weapon_sets lists melee sets where a job also swaps main/sub, using only your own listed weapons.
]]

local DEF = { dt = -50, pdt = -50, mdt = -50 };

return {
    dual_wield_jobs   = { 'NIN', 'DNC', 'THF' },
    -- Jobs with no MP of their own: MP, Refresh, MP-healing and Conserve MP never count for them
    no_mp_jobs        = { 'WAR', 'MNK', 'THF', 'BST', 'RNG', 'SAM', 'NIN', 'DRG', 'COR', 'PUP', 'DNC' },
    dual_wield_weight = 5,
    weapon_jobs       = { 'WHM', 'BLM', 'SMN', 'SCH', 'GEO', 'BRD', 'RDM', 'BLU' },

    -- Melee sets where these jobs also swap main/sub. RDM and BLU swap to a staff for casting, so their
    -- melee sets must put the sword back. Only weapons from your BiS reference / preferred list are used
    -- here, never a random weapon.
    weapon_sets = {
        RDM = { 'TP', 'TP_Hybrid' },
        BLU = { 'TP', 'TP_Hybrid', 'PDT', 'MDT' },
    },

    -- BiS ranged weapon by job and weapon type. Put on in ranged weaponskills, Preshot / Midshot and Quick Draw,
    -- but only if you own it (it is never swapped for a different weapon, which would cancel the shot).
    ranged_weapons = {
        RNG = { Archery = 'Tonzoffun', Marksmanship = 'Annihilator' },
        COR = { Marksmanship = 'Death Penalty' },
    },

    -- Best in Slot reference: highest item level considered when building the BiS list.
    bis_level = 75,

    -- Extra items that may appear in the BiS list even if they aren't in a reference set or in your bags.
    bis_extra = { 'Love Torque', 'Prudence Torque', 'Justice Torque', 'Hope Torque', 'Fortitude Torque',
                  'Temp. Torque', 'Faith Torque' },

    -- Job abilities that put a set on: { ability name, set id }
    ja_sets = {
        'Meditate', 'Berserk', 'Warcry', 'Sublimation',
        'Chakra', 'Boost', 'Focus',
        'Jump', { 'High Jump', 'HighJump' }, 'Angon', { 'Ancient Circle', 'AncientCircle' },
        { 'Dragon Breaker', 'DragonBreaker' },
        -- DNC
        { 'Quickstep', 'Steps' }, { 'Box Step', 'Steps' }, { 'Stutter Step', 'Steps' }, { 'Feather Step', 'Steps' },
        { 'Drain Samba', 'Samba' }, { 'Drain Samba II', 'Samba' }, { 'Drain Samba III', 'Samba' },
        { 'Aspir Samba', 'Samba' }, { 'Aspir Samba II', 'Samba' }, { 'Haste Samba', 'Samba' },
        { 'Spectral Jig', 'Jig' }, { 'Chocobo Jig', 'Jig' }, { 'Chocobo Jig II', 'Jig' },
        { 'Violent Flourish', 'ViolentFlourish' },
        'Sentinel', { 'Shield Bash', 'ShieldBash' }, { 'Chivalry', 'ShieldBash' },
        'Rampart', 'Cover',
        { 'Trick Attack', 'TrickAttack' }, 'Flee',
    },
    -- Jobs whose Precast set (haste / fast cast) also covers Utsusemi while it is being cast
    utsusemi_precast = { DRG = true },

    -- Spells that wear their own midcast set, checked before the usual magic-skill rules: { name (* = wildcard), set }
    spell_sets = {
        'Flash', 'Reprisal', { 'Phalanx*', 'Phalanx' },
        -- BLU: each blue spell to its category set (any blue spell not listed here uses BlueMagic)
        { 'Poisona|Paralyna|Blindna|Silena|Stona|Viruna|Cursna|Erase', 'NaSpells' },
        { 'Refresh|Refresh II|Refresh III', 'RefreshSpell' },
        { 'Spectral Floe', 'SpectralFloe' }, { 'Battery Charge', 'BatteryCharge' },
        { 'Foot Kick|Power Attack|Sprout Smack|Wild Oats|Queasyshroom|Battle Dance|Head Butt|Feather Storm|Helldive|'
          .. 'Bludgeon|Claw Cyclone|Screwdriver|Grand Slam|Smite of Rage|Pinecone Bomb|Jet Stream|Uppercut|Terror Touch|'
          .. 'Mandibular Bite|Sickle Slash|Dimensional Death|Spiral Spin|Death Scissors|Seedspray|Body Slam|Hydro Shot|'
          .. 'Frenetic Rip|Spinal Cleave|Hysteric Barrage|Asuran Claws|Cannonball|Disseverment|Ram Charge|Vertical Cleave|'
          .. 'Goblin Rush|Vanity Dive|Whirl of Rage|Benthic Typhoon|Quad. Continuum|Empty Thrash|Delta Thrust|Heavy Strike|'
          .. 'Quadrastrike|Tourbillion|Amorphic Spikes|Barbed Crescent|Bilgestorm|Bloodrake|Glutinous Dart|Paralyzing Triad|'
          .. 'Thrashing Assault|Sinker Drill|Sweeping Gouge|Saurian Slide|Sub-zero Smash|Tail Slap|Frypan', 'BluPhys' },
        { 'Cursed Sphere|Blastbomb|Bomb Toss|Death Ray|Magic Hammer|Ice Break|Maelstrom|Corrosive Ooze|Firespit|'
          .. 'Regurgitation|Eyes On Me|Mysterious Light|Blitzstrahl|Acrid Stream|Leafstorm|Thermal Pulse|Charged Whisker|'
          .. 'Blazing Bound|Gates of Hades|Thunderbolt|Droning Whirlwind|Rending Deluge|Tem. Upheaval|Embalming Earth|'
          .. 'Foul Waters|Searing Tempest|Anvil Lightning|Entomb|Scouring Spate|Silent Storm|Tenebral Crush|Water Bomb|'
          .. 'Molting Plumage|Nectarous Deluge|Diffusion Ray|Rail Cannon|Uproot|Crashing Thunder|Polar Roar|Subduction|'
          .. 'Palling Salvo|Blinding Fulgor|Mind Blast|Sandspin|Dark Orb|Evryone. Grudge', 'BluMag' },
        { 'Sheep Song|Soporific|Blank Gaze|Chaotic Eye|Geist Wall|Jettatura|Sound Blast|Awful Eye|Stinking Gas|'
          .. 'Frightful Roar|Cold Wave|Light of Penance|Feather Tickle|Yawn|Filamented Hold|Infrasonics|Lowing|Venom Shell|'
          .. 'Mortal Ray|Dream Flower|Auroral Drape|Actinic Burst|Reaving Wind|Blistering Roar|Bad Breath|Cimicine Discharge|'
          .. 'Demoralizing Roar|Sudden Lunge|Cruel Joke|Absolute Terror|Temporal Shift|Blood Drain|Blood Saber|MP Drainkiss|'
          .. 'Digest|Osmosis', 'BluDebuff' },
    },
    -- Set put on first for every spell / every job ability, before that spell's or ability's own set (tanks)
    midcast_base = { PLD = 'SIR' },
    ability_base = { PLD = 'Enmity' },
    -- Phalanx cast on you by someone else: wear the PhalanxRcv set for a few seconds (from phalanx.lua):
    -- Phalanx II (107) aimed at you, or Phalanx (106) cast by a party member
    phalanx_received = { set = 'PhalanxRcv', single = { 107 }, party = { 106 }, single_time = 5, party_time = 8 },

    -- Artifact +1 (Tier 3) and Relic +1 (Rank 10) max augments on CatsEyeXI (bg-wiki: CatsEyeXI_Systems/
    -- Artifact_+1_Augments, CatsEyeXI_Content/Dynamis_Augments), and the Venture Battle upgrades (A3, bg-wiki:
    -- CatsEyeXI_Content/Ventures). Added to those pieces in the Best in Slot list.
    max_augments = {
        -- Artifact +1
        ["Wzd. Petasos +1"] = { stats = { hmp = 3, refresh = 1 } },   -- BLM
        ["Wzd. Coat +1"] = { stats = { mp = 18, macc = 5 } },   -- BLM
        ["Wzd. Gloves +1"] = { stats = { cmp = 5, mab = 5 } },   -- BLM
        ["Wzd. Tonban +1"] = { stats = { drain = 5, macc = 5 } },   -- BLM
        ["Wzd. Sabots +1"] = { stats = { mp = 39, hmp = 3 } },   -- BLM
        ["Magus Keffiyeh +1"] = { stats = { crit = 3, haste = 5 } },   -- BLU
        ["Magus Jubbah +1"] = { stats = { acc = 10, dw = 3 } },   -- BLU
        ["Mag. Bazubands +1"] = { stats = { da = 3, haste = 3 } },   -- BLU
        ["Magus Shalwar +1"] = { stats = { refresh = 1, regen = 3 } },   -- BLU
        ["Magus Charuqs +1"] = { stats = { blue = 5, mab = 10 } },   -- BLU
        ["Chl. Roundlet +1"] = { stats = { refresh = 1, regen = 3 } },   -- BRD
        ["Chl. Jstcorps +1"] = { stats = { singing = 5, wind = 6 } },   -- BRD
        ["Chl. Cuffs +1"] = { stats = { chr = 3, macc = 3 } },   -- BRD
        ["Chl. Slippers +1"] = { stats = { hhp = 3, hmp = 5 } },   -- BRD
        ["Bst. Helm +1"] = { stats = { haste = 5 } },   -- BST
        ["Bst. Jackcoat +1"] = { stats = { haste = 3 } },   -- BST
        ["Bst. Gloves +1"] = { stats = { da = 3, haste = 5 } },   -- BST
        ["Bst. Trousers +1"] = { stats = { haste = 5 } },   -- BST
        ["Bst. Gaiters +1"] = { stats = { haste = 5 } },   -- BST
        ["Cor. Tricorne +1"] = { stats = { racc = 6, regen = 2 } },   -- COR
        ["Corsair's Frac +1"] = { stats = { agi = 11, marksmanship = 3 } },   -- COR
        ["Corsair's Gants +1"] = { stats = { da = 3, haste = 3 } },   -- COR
        ["Cor. Culottes +1"] = { stats = { acc = 6, dw = 3 } },   -- COR
        ["Cor. Bottes +1"] = { stats = { rapid = 5, snapshot = 3 } },   -- COR
        ["Dancer's Tiara +1"] = { stats = { crit = 3, haste = 5 } },   -- DNC
        ["Dnc. Casaque +1"] = { stats = { waltz = 5 } },   -- DNC
        ["Dnc. Bangles +1"] = { stats = { dw = 3, haste = 3 } },   -- DNC
        ["Dancer's Tights +1"] = { stats = { str = 11, dex = 11 } },   -- DNC
        ["Dancer's Shoes +1"] = { stats = { da = 3, haste = 3 } },   -- DNC
        ["Drn. Armet +1"] = { stats = { crit = 3, haste = 5 } },   -- DRG
        ["Drn. Mail +1"] = { stats = { acc = 10, stp = 8 } },   -- DRG
        ["Drn. Fng. Gnt. +1"] = { stats = { da = 3, haste = 3 } },   -- DRG
        ["Drn. Brais +1"] = { stats = { haste = 3 } },   -- DRG
        ["Drn. Greaves +1"] = { stats = { haste = 3 } },   -- DRG
        ["Chs. Burgeonet +1"] = { stats = { crit = 3, haste = 5 } },   -- DRK
        ["Chs. Cuirass +1"] = { stats = { refresh = 1, regen = 3 } },   -- DRK
        ["Chs. Gauntlets +1"] = { stats = { haste = 5, stp = 5 } },   -- DRK
        ["Chs. Flanchard +1"] = { stats = { int = 5, drain = 5 } },   -- DRK
        ["Chs. Sollerets +1"] = { stats = { da = 3, haste = 3 } },   -- DRK
        ["Geomancy Galero"] = { stats = { cmp = 5, refresh = 1 } },   -- GEO
        ["Geomancy Tunic"] = { stats = { dt = -5, macc = 5 } },   -- GEO
        ["Geomancy Mitaines"] = { stats = { cmp = 3 } },   -- GEO
        ["Geomancy Pants"] = { stats = { int = 11, mnd = 11 } },   -- GEO
        ["Geomancy Sandals"] = { stats = { mp = 39, hmp = 5 } },   -- GEO
        ["Tpl. Crown +1"] = { stats = { crit = 3, haste = 5 } },   -- MNK
        ["Tpl. Cyclas +1"] = { stats = { ma = 2, stp = 5 } },   -- MNK
        ["Tpl. Gloves +1"] = { stats = { da = 3, haste = 3 } },   -- MNK
        ["Tpl. Hose +1"] = { stats = { str = 11, vit = 11 } },   -- MNK
        ["Tpl. Gaiters +1"] = { stats = { haste = 3, kick = 5 } },   -- MNK
        ["Nin. Hatsuburi +1"] = { stats = { crit = 3, haste = 5 } },   -- NIN
        ["Nin. Chainmail +1"] = { stats = { acc = 8, dw = 3 } },   -- NIN
        ["Nin. Tekko +1"] = { stats = { da = 3, haste = 3 } },   -- NIN
        ["Nin. Hakama +1"] = { stats = { eva = 5 } },   -- NIN
        ["Nin. Kyahan +1"] = { stats = { mab = 10, ninjutsu = 5 } },   -- NIN
        ["Glt. Coronet +1"] = { stats = { curercv = 5, dt = -3 } },   -- PLD
        ["Glt. Surcoat +1"] = { stats = { refresh = 1 } },   -- PLD
        ["Glt. Gauntlets +1"] = { stats = { mdt = -5 } },   -- PLD
        ["Glt. Leggings +1"] = { stats = { bdt = -5, mdb = 3 } },   -- PLD
        ["Puppetry Taj +1"] = { stats = { haste = 5 } },   -- PUP
        ["Pup. Tobe +1"] = { stats = { ma = 2, stp = 5 } },   -- PUP
        ["Pup. Dastanas +1"] = { stats = { da = 3, haste = 3 } },   -- PUP
        ["Pup. Churidars +1"] = { stats = { crit = 4, haste = 3 } },   -- PUP
        ["Wlk. Chapeau +1"] = { stats = { cmp = 5, mab = 6 } },   -- RDM
        ["Wlk. Tabard +1"] = { stats = { mp = 21, macc = 5 } },   -- RDM
        ["Wlk. Gloves +1"] = { stats = { da = 3, haste = 3 } },   -- RDM
        ["Wlk. Tights +1"] = { stats = { mp = 36, cure = 6 } },   -- RDM
        ["Wlk. Boots +1"] = { stats = { mp = 39, hmp = 3 } },   -- RDM
        ["Htr. Beret +1"] = { stats = { racc = 5, rapid = 3 } },   -- RNG
        ["Htr. Jerkin +1"] = { stats = { acc = 8, stp = 8 } },   -- RNG
        ["Htr. Bracers +1"] = { stats = { racc = 6 } },   -- RNG
        ["Htr. Braccae +1"] = { stats = { dex = 11, agi = 11 } },   -- RNG
        ["Htr. Socks +1"] = { stats = { da = 3, haste = 5 } },   -- RNG
        ["Runeist Bandeau"] = { stats = { enmity = 5, regen = 2 } },   -- RUN
        ["Runeist Coat"] = { stats = { mdt = -3 } },   -- RUN
        ["Runeist Mitons"] = { stats = { enmity = 3, sk_gsword = 5 } },   -- RUN
        ["Runeist Trousers"] = { stats = { vit = 11, mnd = 11 } },   -- RUN
        ["Runeist Bottes"] = { stats = { bdt = -3, enmity = 3 } },   -- RUN
        ["Myn. Kabuto +1"] = { stats = { crit = 3, haste = 5 } },   -- SAM
        ["Myn. Domaru +1"] = { stats = { regen = 3 } },   -- SAM
        ["Myn. Kote +1"] = { stats = { haste = 3, zanshin = 3 } },   -- SAM
        ["Myn. Haidate +1"] = { stats = { haste = 5, stp = 5 } },   -- SAM
        ["Myn. Sune-ate +1"] = { stats = { da = 3, haste = 3 } },   -- SAM
        ["Sch. M.Board +1"] = { stats = { mab = 5, mbb = 3 } },   -- SCH
        ["Scholar's Gown +1"] = { stats = { mab = 5, macc = 5 } },   -- SCH
        ["Sch. Bracers +1"] = { stats = { hmp = 3, refresh = 1 } },   -- SCH
        ["Scholar's Pants +1"] = { stats = { cmp = 5, cure = 6 } },   -- SCH
        ["Sch. Loafers +1"] = { stats = { drain = 5, macc = 5 } },   -- SCH
        ["Evk. Horn +1"] = { stats = { hmp = 4, refresh = 1 } },   -- SMN
        ["Evk. Doublet +1"] = { stats = { hmp = 3 } },   -- SMN
        ["Rog. Bonnet +1"] = { stats = { crit = 3, haste = 5 } },   -- THF
        ["Rog. Vest +1"] = { stats = { dw = 3, regen = 2 } },   -- THF
        ["Rog. Armlets +1"] = { stats = { haste = 3, th = 1 } },   -- THF
        ["Rog. Culottes +1"] = { stats = { racc = 8, ratt = 8 } },   -- THF
        ["Rog. Poulaines +1"] = { stats = { da = 3, haste = 3 } },   -- THF
        ["Ftr. Mask +1"] = { stats = { crit = 3, haste = 5 } },   -- WAR
        ["Ftr. Lorica +1"] = { stats = { enmity = 6, pdt = -3 } },   -- WAR
        ["Ftr. Mufflers +1"] = { stats = { enmity = 6, pdt = -3 } },   -- WAR
        ["Ftr. Cuisses +1"] = { stats = { enmity = 6, pdt = -3 } },   -- WAR
        ["Ftr. Calligae +1"] = { stats = { da = 3, stp = 6 } },   -- WAR
        ["Hlr. Cap +1"] = { stats = { hmp = 3, refresh = 1 } },   -- WHM
        ["Hlr. Bliaut +1"] = { stats = { mp = 18, dt = -5 } },   -- WHM
        ["Hlr. Mitts +1"] = { stats = { cmp = 5, cure = 3 } },   -- WHM
        ["Hlr. Pantaln. +1"] = { stats = { curect = 3, macc = 5 } },   -- WHM
        ["Hlr. Duckbills +1"] = { stats = { mp = 39, hmp = 3 } },   -- WHM
        -- Relic +1
        ["Src. Petasos +1"] = { stats = { int = 8, enmity = -5, mab = 6 } },   -- BLM
        ["Src. Coat +1"] = { stats = { int = 5, fc = 4, mab = 8 } },   -- BLM
        ["Src. Gloves +1"] = { stats = { int = 8, drain = 6, mbb = 6 } },   -- BLM
        ["Src. Tonban +1"] = { stats = { elemental = 8, mcrit = 8, mcritdmg = 8 } },   -- BLM
        ["Src. Sabots +1"] = { stats = { mab = 3, mbb = 3, mcrit = 8 } },   -- BLM
        ["Sorcerer's Belt"] = { stats = { mp = 10, elemental = 6, mab = 3 } },   -- BLM
        ["Mirage Keffiyeh +1"] = { stats = { att = 10, haste = 5, sk_sword = 6 } },   -- BLU
        ["Mirage Jubbah +1"] = { stats = { fc = 5, mab = 8, macc = 5 } },   -- BLU
        ["Mrg. Bazubands +1"] = { stats = { str = 6, vit = 6, acc = 8, att = 8, haste = 5 } },   -- BLU
        ["Mirage Shalwar +1"] = { stats = { str = 6, mnd = 6, haste = 3, meva = 6 } },   -- BLU
        ["Mirage Charuqs +1"] = { stats = { dt = -3, haste = 3 } },   -- BLU
        ["Mirage Mantle"] = { stats = { hp = 10, mp = 10, blue = 7, stp = 5 } },   -- BLU
        ["Brd. Roundlet +1"] = { stats = { refresh = 1, songct = 5, wind = 7 } },   -- BRD
        ["Brd. Jstcorps +1"] = { stats = { pdt = -4, singing = 7, songdur = 5 } },   -- BRD
        ["Brd. Cuffs +1"] = { stats = { fc = 3, mdt = -4, regen = 2 } },   -- BRD
        ["Brd. Cannions +1"] = { stats = { cure = 5, dt = -4, macc = 6 } },   -- BRD
        ["Brd. Slippers +1"] = { stats = { chr = 8, string = 8 } },   -- BRD
        ["Bard's Cape"] = { stats = { hp = 10, mp = 10, macc = 3, stp = 5 } },   -- BRD
        ["Mst. Helm +1"] = { stats = { att = 10, sk_axe = 8 } },   -- BST
        ["Mst. Jackcoat +1"] = { stats = { regen = 2 } },   -- BST
        ["Mst. Gloves +1"] = { stats = { haste = 3, stp = 5 } },   -- BST
        ["Mst. Trousers +1"] = { stats = { da = 3, haste = 5 } },   -- BST
        ["Mst. Gaiters +1"] = { stats = { mnd = 8, chr = 8, tpb = 200 } },   -- BST
        ["Monster Belt"] = { stats = { hp = 10, mp = 10 } },   -- BST
        ["Comm. Tricorne +1"] = { stats = { racc = 10, rolldelay = 5, sb = 6 } },   -- COR
        ["Comm. Frac +1"] = { stats = { mab = 10, macc = 10, mcrit = 3, rolldur = 5 } },   -- COR
        ["Comm. Gants +1"] = { stats = { agi = 6, mab = 5, macc = 5 } },   -- COR
        ["Comm. Trews +1"] = { stats = { att = 8, eva = 6, haste = 3, racc = 8 } },   -- COR
        ["Comm. Bottes +1"] = { stats = { haste = 3, rolldelay = 3 } },   -- COR
        ["Commodore Belt"] = { stats = { hp = 10, mp = 10, agi = 4, mab = 3 } },   -- COR
        ["Etoile Tiara +1"] = { stats = { haste = 5, sb = 10, sk_dagger = 8 } },   -- DNC
        ["Etoile Casaque +1"] = { stats = { haste = 4, sb = 8, stp = 6 } },   -- DNC
        ["Etoile Bangles +1"] = { stats = { counter = 4, dt = -4, eva = 8 } },   -- DNC
        ["Etoile Tights +1"] = { stats = { acc = 8, att = 8, sb = 5, stp = 5 } },   -- DNC
        ["Etoile Shoes +1"] = { stats = { str = 7, chr = 7, att = 12, ctp = 10 } },   -- DNC
        ["Etoile Cape"] = { stats = { hp = 10, att = 9, scb = 3 } },   -- DNC
        ["Wym. Armet +1"] = { stats = { att = 10, haste = 5 } },   -- DRG
        ["Wym. Mail +1"] = { stats = { str = 8, dex = 8, da = 3 } },   -- DRG
        ["Wym. Fng. Gnt. +1"] = { stats = { dt = -3, haste = 3 } },   -- DRG
        ["Wym. Brais +1"] = { stats = { dt = -3, haste = 3, stp = 5 } },   -- DRG
        ["Wym. Greaves +1"] = { stats = { acc = 8, att = 8, haste = 3 } },   -- DRG
        ["Wyrm Belt"] = { stats = { hp = 10, mp = 10 } },   -- DRG
        ["Abs. Burgeonet +1"] = { stats = { int = 8, fc = 5, refresh = 1 } },   -- DRK
        ["Abs. Cuirass +1"] = { stats = { att = 12, haste = 4, stp = 6 } },   -- DRK
        ["Abs. Gauntlets +1"] = { stats = { drain = 8, mab = 8, occult = 30 } },   -- DRK
        ["Abs. Flanchard +1"] = { stats = { acc = 10, att = 10, mdt = -5, stp = 4 } },   -- DRK
        ["Abs. Sollerets +1"] = { stats = { fc = 3, macc = 6, mbb = 10 } },   -- DRK
        ["Abyss Cape"] = { stats = { hp = 10, int = 5, att = 7 } },   -- DRK
        ["Bagua Galero +1"] = { stats = { mp = 30, mab = 10, refresh = 1 } },   -- GEO
        ["Bagua Tunic +1"] = { stats = { mp = 30, cure = 5, geomancy = 7 } },   -- GEO
        ["Bagua Mitaines +1"] = { stats = { dt = -4, fc = 3, mdb = 3 } },   -- GEO
        ["Bagua Pants +1"] = { stats = { mp = 8, int = 8, mnd = 8, handbell = 8 } },   -- GEO
        ["Bagua Sandals +1"] = { stats = { int = 6, mnd = 6, enmity = -5, pdt = -5 } },   -- GEO
        ["Bagua Sash"] = { stats = { mp = 10, cmp = 8 } },   -- GEO
        ["Mel. Crown +1"] = { stats = { acc = 8, crit = 4, eva = 10 } },   -- MNK
        ["Mel. Cyclas +1"] = { stats = { att = 12, pdt = -3, sb = 8 } },   -- MNK
        ["Mel. Gloves +1"] = { stats = { str = 6, vit = 6, acc = 6, att = 6, ctp = 6 } },   -- MNK
        ["Mel. Hose +1"] = { stats = { kick = 5, ma = 6, pdt = -4 } },   -- MNK
        ["Mel. Gaiters +1"] = { stats = { acc = 8, counter = 4, haste = 4 } },   -- MNK
        ["Melee Cape"] = { stats = { hp = 10, acc = 8, att = 8, counter = 3 } },   -- MNK
        ["Kog. Hatsuburi +1"] = { stats = { enmity = 8, haste = 5, sb = 10 } },   -- NIN
        ["Kog. Chainmail +1"] = { stats = { crit = 4, stp = 6 } },   -- NIN
        ["Kog. Tekko +1"] = { stats = { acc = 8, att = 8, dt = -4, eva = 6 } },   -- NIN
        ["Kog. Hakama +1"] = { stats = { dex = 6, agi = 6, counter = 6, dt = -5 } },   -- NIN
        ["Kog. Kyahan +1"] = { stats = { haste = 4, meva = 6 } },   -- NIN
        ["Koga Sarashi"] = { stats = { hp = 10, acc = 9, racc = 9 } },   -- NIN
        ["Vlr. Coronet +1"] = { stats = { vit = 10, fc = 5 } },   -- PLD
        ["Vlr. Surcoat +1"] = { stats = { str = 8, vit = 8, curercv = 5, dt = -4 } },   -- PLD
        ["Vlr. Gauntlets +1"] = { stats = { curercv = 5, haste = 3, stp = 5 } },   -- PLD
        ["Vlr. Breeches +1"] = { stats = { haste = 3, sk_gsword = 12 } },   -- PLD
        ["Vlr. Leggings +1"] = { stats = { vit = 12, enmity = 3 } },   -- PLD
        ["Valor Cape"] = { stats = { hp = 10 } },   -- PLD
        ["Pantin Taj +1"] = { stats = { att = 12, sk_h2h = 8 } },   -- PUP
        ["Pantin Tobe +1"] = { stats = { regen = 2 } },   -- PUP
        ["Pantin Dastanas +1"] = { stats = { str = 8, dex = 8, eva = 8 } },   -- PUP
        ["Ptn. Churidars +1"] = { stats = { haste = 4 } },   -- PUP
        ["Ptn. Babouches +1"] = { stats = { dt = -3, haste = 3 } },   -- PUP
        ["Pantin Cape"] = { stats = { hp = 10, mp = 10, eva = 7 } },   -- PUP
        ["Dls. Chapeau +1"] = { stats = { haste = 5, hmp = 5, mab = 7 } },   -- RDM
        ["Dls. Tabard +1"] = { stats = { elemental = 8, macc = 5, refresh = 1 } },   -- RDM
        ["Dls. Gloves +1"] = { stats = { enhdur = 8, fc = 3, mdt = -3 } },   -- RDM
        ["Dls. Tights +1"] = { stats = { str = 8, int = 8, haste = 5, mbb = 6 } },   -- RDM
        ["Dls. Boots +1"] = { stats = { drain = 6, fc = 4, macc = 4 } },   -- RDM
        ["Duelist's Belt"] = { stats = { mp = 10, enfdur = 5, enfeebling = 6 } },   -- RDM
        ["Sct. Beret +1"] = { stats = { acc = 12, archery = 8, racc = 7 } },   -- RNG
        ["Sct. Jerkin +1"] = { stats = { att = 10, marksmanship = 8, ratt = 10, stp = 6 } },   -- RNG
        ["Sct. Bracers +1"] = { stats = { agi = 4, ctp = 10, mab = 6, macc = 6 } },   -- RNG
        ["Sct. Braccae +1"] = { stats = { str = 8, mnd = 8, att = 9, rapid = 3 } },   -- RNG
        ["Sct. Socks +1"] = { stats = { str = 6, mnd = 6, ctp = 6, snapshot = 3 } },   -- RNG
        ["Scout's Belt"] = { stats = { hp = 10, enmity = -3, stp = 3 } },   -- RNG
        ["Fu. Bandeau +1"] = { stats = { curercv = 2, haste = 2, sk_gsword = 3 } },   -- RUN
        ["Futhark Coat +1"] = { stats = { dt = -5 } },   -- RUN
        ["Futhark Mitons +1"] = { stats = { str = 8, vit = 8, haste = 4, mdb = 4 } },   -- RUN
        ["Futhark Trousers +1"] = { stats = { acc = 8, haste = 4, stp = 5 } },   -- RUN
        ["Futhark Boots +1"] = { stats = { vit = 10, meva = 8 } },   -- RUN
        ["Futhark Cape"] = { stats = { hp = 10, mp = 10, mdb = 3 } },   -- RUN
        ["Sao. Kabuto +1"] = { stats = { haste = 5, sb = 10, sk_gkatana = 8 } },   -- SAM
        ["Sao. Domaru +1"] = { stats = { acc = 16, att = 10, crit = 4 } },   -- SAM
        ["Sao. Kote +1"] = { stats = { haste = 3, pdt = -3, stp = 4 } },   -- SAM
        ["Sao. Haidate +1"] = { stats = { haste = 4, pdt = -5, zanshin = 5 } },   -- SAM
        ["Sao. Sune-ate +1"] = { stats = { haste = 3, zanshin = 3 } },   -- SAM
        ["Sao. Koshi-ate"] = { stats = { hp = 10, ratt = 5, stp = 5 } },   -- SAM
        ["Argute M.Board +1"] = { stats = { mab = 6, refresh = 1 } },   -- SCH
        ["Argute Gown +1"] = { stats = { int = 8, mnd = 8, fc = 5 } },   -- SCH
        ["Argute Bracers +1"] = { stats = { enfdur = 10, fc = 3 } },   -- SCH
        ["Argute Pants +1"] = { stats = { drain = 7, mab = 5, macc = 10 } },   -- SCH
        ["Argute Loafers +1"] = { stats = { cmp = 6, cure = 4, fc = 4 } },   -- SCH
        ["Argute Belt"] = { stats = { mp = 10, enhdur = 5, macc = 4, mdmg = 4 } },   -- SCH
        ["Smn. Horn +1"] = { stats = { int = 8, mnd = 8, refresh = 1 } },   -- SMN
        ["Smn. Doublet +1"] = { stats = { mp = 30, fc = 3 } },   -- SMN
        ["Smn. Bracers +1"] = { stats = { dt = -3 } },   -- SMN
        ["Smn. Spats +1"] = { stats = { bloodboon = 8, summoning = 10 } },   -- SMN
        ["Smn. Pigaches +1"] = { stats = { cure = 6, fc = 5 } },   -- SMN
        ["Summoner's Cape"] = { stats = { mp = 10, bpdelay = 2 } },   -- SMN
        ["Asn. Bonnet +1"] = { stats = { agi = 8, haste = 5, sb = 10 } },   -- THF
        ["Asn. Vest +1"] = { stats = { acc = 12, att = 12, stp = 6, ta = 1 } },   -- THF
        ["Asn. Armlets +1"] = { stats = { acc = 8, att = 8, dt = -4, eva = 8 } },   -- THF
        ["Asn. Culottes +1"] = { stats = { eva = 6, haste = 4, sb = 4, stp = 4 } },   -- THF
        ["Asn. Poulaines +1"] = { stats = { eva = 6, haste = 3 } },   -- THF
        ["Assassin's Cape"] = { stats = { hp = 10, critdmg = 2, eva = 9 } },   -- THF
        ["War. Mask +1"] = { stats = { acc = 8, att = 8, da = 4, meva = 10 } },   -- WAR
        ["War. Lorica +1"] = { stats = { counter = 5, eva = 10, pdt = -4 } },   -- WAR
        ["War. Mufflers +1"] = { stats = { haste = 4 } },   -- WAR
        ["War. Cuisses +1"] = { stats = { acc = 10, att = 10, haste = 4, pdt = -4 } },   -- WAR
        ["War. Calligae +1"] = { stats = { acc = 8, att = 8, haste = 3 } },   -- WAR
        ["Warrior's Stone"] = { stats = { hp = 10, haste = 5 } },   -- WAR
        ["Clr. Cap +1"] = { stats = { curect = 5, healing = 5, hmp = 5 } },   -- WHM
        ["Clr. Bliaut +1"] = { stats = { mdb = 5, pdt = -5, refresh = 1 } },   -- WHM
        ["Clr. Mitts +1"] = { stats = { divine = 10, mdt = -4, meva = 6 } },   -- WHM
        ["Clr. Pantaln. +1"] = { stats = { cure = 6, dt = -4, enhancing = 10 } },   -- WHM
        ["Clr. Duckbills +1"] = { stats = { str = 5, mnd = 5, enhdur = 8, sk_club = 8 } },   -- WHM
        ["Cleric's Belt"] = { stats = { mp = 10, cure = 5, mdb = 3 } },   -- WHM
        -- Ventures A3
        ["Sinister Sickle"] = { stats = { int = 4 } },   -- BLM
        ["Hibernal Ring"] = { stats = { dex = 4, acc = 4, mab = 2 } },   -- BLM/BRD/SCH/GEO
        ["Beastly Girdle"] = { stats = { haste = 6 } },   -- BST/DRG/SMN/PUP
        ["Vesper Earring"] = { stats = { chr = 3, eva = 5 } },   -- BST/DRG/SMN/PUP
        ["Flamedancer Glaive"] = { stats = { str = 4, dex = 4, acc = 2 } },   -- DNC
        ["Zhulong Bell"] = { stats = { att = 3, mab = 3 } },   -- GEO
        ["Bagua Ring"] = { stats = { acc = 5 } },   -- GEO
        ["Wyrt Gorget"] = { stats = { acc = 3, att = 3 } },   -- MNK/WHM/RDM/THF/PLD/BST/BRD/DRG/SMN/BLU/COR/PUP/DNC/GEO/RUN
        ["Luminous Earring"] = { stats = { hp = 15, macc = 3, stp = 2 } },   -- MNK/RDM/THF/BST/BRD/NIN/BLU/COR/PUP/DNC/RUN
        ["Cullet Gloves"] = { stats = { agi = 5, haste = 2, macc = 4 } },   -- MNK/THF/BRD/RNG/NIN/COR/DNC
        ["Eldritch Sabatons"] = { stats = { int = 4, mnd = 4, mbb = 3, sk_sword = 3 } },   -- RDM/DRK/BLU/RUN
        ["Kennan's Longbow"] = { stats = { enmity = -5, racc = 3 } },   -- RNG/SAM
        ["Kyugutachi"] = { stats = { att = 12, ratt = 12 } },   -- SAM
        ["Enlightenment"] = { stats = { cure = 3, eva = 3 } },   -- SCH
        ["Liberty"] = { stats = { eva = 3, ratt = 3 } },   -- THF/RNG/NIN/COR
        ["Hailstone Hose"] = { stats = { agi = 4, haste = 2, macc = 4 } },   -- THF/RNG/NIN/COR
        ["Tigris Grip"] = { stats = { dex = 3, chr = 3 } },   -- WAR/MNK/WHM/BLM/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/SMN/BLU/COR/PUP/DNC/SCH/GEO/RUN
        ["Slippery Cape"] = { stats = { dex = 3, agi = 3 } },   -- WAR/THF/RNG/SAM/NIN/DNC
        ["Myrmeleo Ring"] = { stats = { enmity = 3, eva = 3 } },   -- WAR/MNK/WHM/BLM/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/SMN/BLU/COR/PUP/DNC/SCH/GEO/RUN
        ["Chivalric Emblem"] = { stats = { mnd = 3, acc = 3 } },   -- WAR/PLD/RUN
        ["Avarice"] = { stats = { str = 5, att = 12 } },   -- WAR/DRK/RUN
        ["Sprightly Feather"] = { stats = { att = 4, eva = 4 } },   -- WAR/MNK/WHM/BLM/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/SMN/BLU/COR/PUP/DNC/SCH/GEO/RUN
        ["Rikugame Nodowa"] = { stats = { hp = 30, dex = 2, acc = 8 } },   -- WAR/MNK/DRK/SAM/DRG/RUN
        ["Emberpearl Earring"] = { stats = { hp = 15, att = 3, wsacc = 2 } },   -- WAR/MNK/WHM/RDM/PLD/DRK/BST/RNG/SAM/DRG/BLU/COR/GEO/RUN
        ["Oathbreaker"] = { stats = { vit = 4, enmity = 3, refresh = 1 } },   -- WAR/PLD/NIN/RUN
        ["Shaarat'kor"] = { stats = { enmity = 6 } },   -- WAR/PLD/DRK/RUN
        ["Tellus Pendulum"] = { stats = { mp = 30, int = 4, mab = 2 } },   -- WHM/BLM/SMN/SCH/GEO
        ["Manaflow Sash"] = { stats = { enmity = -6, haste = 6 } },   -- WHM/BLM/SMN/SCH/GEO
        -- Dragonslaying (bg-wiki: CatsEyeXI_Content/Dragonslaying, Arfarvegr drop): top upgrade tier
        ["Soothing Sachet"] = { stats = { petacc = 5, petatk = 5, petdt = -3 } },   -- SMN
        -- Augment shown in game by the player (Scorpion harness +1: "Regen"+1, Phys. dmg. taken -3%)
        ["Scp. Harness +1"] = { stats = { regen = 1, pdt = -3 } },   -- THF and others
        -- SCNM legs, augmented: "Refresh +1" = a stronger Refresh spell when you cast it (not idle MP)
        ["Apogee Tonban"] = { stats = { refreshpot = 1 } },      -- WHM/BLM/RDM/SMN/BLU/SCH/GEO
        ["Pinnacle Cuisses"] = { stats = { refreshpot = 1 } },   -- WAR/PLD/DRK/BST/DRG/SAM/RUN
    },

    -- Adept Reforging (CatsEyeXI, bg-wiki: CatsEyeXI_Systems/Adept_Reforging): each piece's FULL augment
    -- (Tier 3, HQ only). Added to that piece's stats in the Best in Slot list, and only for its own job.
    adept_augments = {
        -- BLM
        ["Genie Tiara"] = { job = 'BLM', stats = { int = 8, enfdur = 10, fc = 3, macc = 5 } },
        ["Genie Weskit"] = { job = 'BLM', stats = { int = 6, cmp = 6, haste = 4, sk_staff = 15 } },
        ["Genie Manillas"] = { job = 'BLM', stats = { int = 8, cmp = 6, mcrit = 8, occult = 30 } },
        ["Genie Lappas"] = { job = 'BLM', stats = { enfdur = 10, haste = 5, macc = 5, sk_staff = 15 } },
        ["Genie Huaraches"] = { job = 'BLM', stats = { mnd = 8, dark = 10, drain = 6, enhancing = 6 } },
        -- BRD
        ["Sheikh Turban"] = { job = 'BRD', stats = { hp = 20, vit = 5, cmp = 2, cure = 5 } },
        ["Sheikh Manteel"] = { job = 'BRD', stats = { hp = 25, dex = 5, acc = 10, regen = 1 } },
        ["Sheikh Gages"] = { job = 'BRD', stats = { hp = 20, haste = 3, sk_sword = 8, stp = 2 } },
        ["Sheikh Seraweels"] = { job = 'BRD', stats = { hp = 25, haste = 5, pdt = -4, sb = 4 } },
        ["Sheikh Crackows"] = { job = 'BRD', stats = { hp = 20, acc = 5, sird = 10 } },
        -- BST
        ["Stout Bonnet"] = { job = 'BST', stats = { mnd = 8, mab = 8, macc = 8, regen = 1, scb = 4 } },
        ["Stout Jacket"] = { job = 'BST', stats = { cmp = 10, cure = 12, fc = 3 } },
        ["Stout Wristbands"] = { job = 'BST', stats = { dex = 8, att = 8, ctp = 8 } },
        ["Stout Kecks"] = { job = 'BST', stats = { dt = -3, refresh = 1 } },
        ["Stout Gamashes"] = { job = 'BST', stats = { hp = 20, mp = 20, counter = 4, haste = 3 } },
        -- DRG
        ["Dragon Mask +1"] = { job = 'DRG', stats = { mp = 30, haste = 4, pdt = -4, th = 1 } },
        ["Dragon Mail +1"] = { job = 'DRG', stats = { mp = 60, str = 8, dex = 8, acc = 15 } },
        ["Dragon F. Gnt. +1"] = { job = 'DRG', stats = { mp = 40, haste = 4 } },
        ["Dragon Cuisses +1"] = { job = 'DRG', stats = { mp = 50, cmp = 3, haste = 4 } },
        ["Drg. Greaves +1"] = { job = 'DRG', stats = { mp = 40, counter = 4, haste = 3 } },
        -- DRK
        ["Onyx Sallet"] = { job = 'DRK', stats = { str = 6, scb = 2, sk_gsword = 5, stp = 5 } },
        ["Plastron +1"] = { job = 'DRK', stats = { str = 3, ctp = 10, scb = 3, sk_scythe = 10 } },
        ["Onyx Gadlings"] = { job = 'DRK', stats = { att = 5, ctp = 5, scb = 3, sk_gsword = 5 } },
        ["Onyx Cuisses"] = { job = 'DRK', stats = { int = 4, mab = 8, scb = 3, sk_scythe = 8 } },
        ["Onyx Sollerets"] = { job = 'DRK', stats = { int = 6, att = 5, ctp = 4, sk_scythe = 5 } },
        -- GEO
        ["Tempest Bonnet"] = { job = 'GEO', stats = { dt = -3, eva = 8, sb = 5 } },
        ["Tempest Jacket"] = { job = 'GEO', stats = { dw = 3, mdt = -5, stp = 5 } },
        ["Tempest Wrists"] = { job = 'GEO', stats = { mnd = 8, fencer = 3, sk_club = 8 } },
        ["Tempest Kecks"] = { job = 'GEO', stats = { acc = 10, da = 3 } },
        ["Tempest Gamashes"] = { job = 'GEO', stats = { haste = 2, sk_club = 10 } },
        -- NIN
        ["Yasha Jinpachi +1"] = { job = 'NIN', stats = { enmity = 3, eva = 10, haste = 5, sird = 4 } },
        ["Yasha Samue +1"] = { job = 'NIN', stats = { int = 8, fc = 4, mab = 8, ninjutsu = 10 } },
        ["Yasha Tekko +1"] = { job = 'NIN', stats = { int = 8, haste = 3, mbb = 6, ninjutsu = 8 } },
        ["Yasha Hakama +1"] = { job = 'NIN', stats = { int = 8, enmity = 3, haste = 4, mab = 5 } },
        ["Ysh. Sune-Ate +1"] = { job = 'NIN', stats = { eva = 8, haste = 3, mdt = -4, sird = 6 } },
        -- PLD
        ["King's Armet"] = { job = 'PLD', stats = { hp = 25, vit = 8, haste = 5, sird = 8 } },
        ["King's Cuirass"] = { job = 'PLD', stats = { vit = 8, curercv = 4, fc = 4, sird = 10 } },
        ["King's Gauntlets"] = { job = 'PLD', stats = { hp = 20, vit = 8, pdt = -3, regen = 3 } },
        ["King's Cuisses"] = { job = 'PLD', stats = { hp = 30, def = 10, vit = 8, phalanxrcv = 3 } },
        ["King's Sabatons"] = { job = 'PLD', stats = { hp = 20, def = 8, vit = 8, curect = 6 } },
        -- RDM
        ["Wise Cap +1"] = { job = 'RDM', stats = { haste = 5, sk_dagger = 6 } },
        ["Chasuble +1"] = { job = 'RDM', stats = { str = 10, mnd = 10, acc = 8, att = 8, dw = 5, mdt = -4 } },
        ["Wise Gloves +1"] = { job = 'RDM', stats = { str = 5, int = 5, ctp = 8, haste = 3, sk_sword = 6 } },
        ["Wise Braconi +1"] = { job = 'RDM', stats = { acc = 8, att = 8, haste = 4, meva = 5, sb = 5, stp = 5 } },
        ["Wise Pigaches +1"] = { job = 'RDM', stats = { str = 5, agi = 5, archery = 15, phalanxrcv = 2, stp = 4 } },
        -- RUN
        ["Dux Visor"] = { job = 'RUN', stats = { hp = 30, mp = 30, haste = 3, mdt = -4 } },
        ["Dux Scale Mail"] = { job = 'RUN', stats = { hp = 50, mp = 50, acc = 10, haste = 3, pdt = -3 } },
        ["Dux Finger Gauntlets"] = { job = 'RUN', stats = { hp = 30, dex = 8, mnd = 8, da = 3 } },
        ["Dux Cuisses"] = { job = 'RUN', stats = { hp = 40, mp = 40, str = 8, acc = 10, att = 10 } },
        ["Dux Greaves"] = { job = 'RUN', stats = { hp = 30, mnd = 8, enhdur = 10, sird = 15 } },
        -- SAM
        ["Hmn. Jinpachi +1"] = { job = 'SAM', stats = { att = 10, counter = 4, haste = 4, zanshin = 5 } },
        ["Hmn. Domaru +1"] = { job = 'SAM', stats = { str = 6, att = 12, ctp = 6, scb = 3 } },
        ["Hachiman Kote +1"] = { job = 'SAM', stats = { acc = 8, att = 10, mab = 8, tpb = 100 } },
        ["Hmn. Hakama +1"] = { job = 'SAM', stats = { str = 6, agi = 8, ratt = 8, snapshot = 4 } },
        ["Hmn. Sune-Ate +1"] = { job = 'SAM', stats = { str = 4, agi = 8, archery = 6, sk_polearm = 10 } },
        -- THF
        ["Dragon Cap +1"] = { job = 'THF', stats = { agi = 6, sb = 6, sk_dagger = 8, th = 1 } },
        ["Dragon Harness +1"] = { job = 'THF', stats = { dex = 3, agi = 3, att = 12, scb = 4 } },
        ["Dragon Mittens +1"] = { job = 'THF', stats = { dex = 8, att = 8, haste = 3, meva = 6 } },
        ["Drn. Subligar +1"] = { job = 'THF', stats = { att = 10, eva = 8, haste = 3, waltz = 5 } },
        ["Drn. Leggings +1"] = { job = 'THF', stats = { acc = 8, att = 8, crit = 3, sb = 6 } },
        -- WAR
        ["Unicorn Cap +1"] = { job = 'WAR', stats = { hp = 24, counter = 4, enmity = 4, haste = 4 } },
        ["Ucn. Harness +1"] = { job = 'WAR', stats = { hp = 32, acc = 15, counter = 4, mdt = -4 } },
        ["Ucn. Mittens +1"] = { job = 'WAR', stats = { hp = 26, haste = 3, mdt = -4 } },
        ["Ucn. Subligar +1"] = { job = 'WAR', stats = { hp = 28, acc = 8, haste = 4, mdt = -4 } },
        ["Ucn. Leggings +1"] = { job = 'WAR', stats = { hp = 20, counter = 4, mdt = -4 } },
        -- WHM
        ["Blessed Bliaut +1"] = { job = 'WHM', stats = { mp = 40, dex = 5, att = 10 } },
        ["Blessed Mitts +1"] = { job = 'WHM', stats = { dex = 5, acc = 8, fc = 2 } },
        ["Bls. Trousers +1"] = { job = 'WHM', stats = { str = 5, att = 10, da = 2 } },
        ["Blessed Pumps +1"] = { job = 'WHM', stats = { str = 5 } },
    },

    exclude   = { 'Aesir Mantle', 'Bonewrk. Smock' },
    -- Items never used in one job's set (your own set and Best in Slot): job = { set id = { items } }
    set_exclude = {
        NIN = { TP = { 'Shukuyu Ring' } },
        THF = { TP = { 'Shukuyu Ring' }, Idle = { 'Jelly Ring', 'Succoring Ring', "Assassin's Cape" }, PDT = { 'Jelly Ring', 'Succoring Ring', "Assassin's Cape" },
                ['*'] = { 'White Tathlum' } },   -- '*' = every THF set
        PLD = { PDT = { 'Jelly Ring' }, Enmity = { 'Myrmeleo Ring', "Terra's Earring" }, Idle = { "Minerva's Ring" } },
    },
    overrides = { ['Aesir Mantle'] = { da = 1 } },

    -- Items whose normal and HQ (+1) versions don't work together: never both in one set, the better one stays
    -- (players reported Brutal Earring + Brutal Earring +1 don't stack)
    no_stack = { 'Brutal Earring' },

    -- Preferred gear: always used in these sets when you own it (and the job can wear it).
    --   sets = set ids, jobs = limit to these jobs (optional),
    --   ws = 'single' / 'multi' / 'any' to target weaponskill sets by hit count,
    --   ws_stat = 'str' (or dex, vit...) to target every weaponskill that uses that stat,
    --   ws_names = { 'Resolution', ... } to target only those weaponskills.
    preferred = {
        { sets = { 'PhantomRoll' }, items = { "Luzaf's Ring" } },
        { sets = { 'Nuke', 'Nuke_MB' }, jobs = { 'SCH' }, items = { 'Coeus' } },
        { sets = { 'Nuke', 'Nuke_MB' }, jobs = { 'BLM', 'RDM', 'SCH', 'GEO', 'BLU' }, items = { 'Moepapa Pendant' } },
        { sets = { 'Boost' }, jobs = { 'MNK' }, items = { 'Tpl. Gloves +1' } },
        { sets = { 'Meditate' },    jobs = { 'WAR', 'PLD', 'DRK', 'BST', 'DRG', 'SAM', 'RUN' }, items = { 'Pinnacle Dastanas' } },
        -- PLD: King's Cuisses raise Phalanx received (no stat for it in the server data, so it's forced)
        { sets = { 'PhalanxRcv', 'Phalanx' }, jobs = { 'PLD' }, items = { "King's Cuisses" } },
        -- SAM: bow in the range slot (swapping range doesn't reset TP). "TP Bonus" has no number in
        -- the description, so it's forced for weaponskills instead of scored.
        { ws = 'any', jobs = { 'SAM' }, items = { "Kennan's Longbow" } },
        { sets = { 'Meditate' }, jobs = { 'SAM' }, items = { "Kennan's Longbow" } },
        { sets = { 'Berserk' },     jobs = { 'WAR', 'PLD', 'DRK', 'BST', 'DRG', 'SAM', 'RUN' }, items = { 'Pinnacle Celata' } },
        { sets = { 'Warcry' },      jobs = { 'WAR', 'PLD', 'DRK', 'BST', 'DRG', 'SAM', 'RUN' }, items = { 'Pinnacle Sabatons' } },
        -- Apex jobs: Apex Hatsuburi (Berserk), Apex Kote (Meditate), Apex Sune-ate (Warcry)
        { sets = { 'Berserk' },  jobs = { 'MNK', 'THF', 'BRD', 'RNG', 'NIN', 'COR', 'PUP', 'DNC' }, items = { 'Apex Hatsuburi' } },
        { sets = { 'Meditate' }, jobs = { 'MNK', 'THF', 'BRD', 'RNG', 'NIN', 'COR', 'PUP', 'DNC' }, items = { 'Apex Kote' } },
        { sets = { 'Warcry' },   jobs = { 'MNK', 'THF', 'BRD', 'RNG', 'NIN', 'COR', 'PUP', 'DNC' }, items = { 'Apex Sune-ate' } },
        -- Apogee jobs: Apogee Petasos (Berserk), Apogee Cuffs (Meditate), Apogee Sabots (Warcry)
        { sets = { 'Berserk' },  jobs = { 'WHM', 'BLM', 'RDM', 'SMN', 'BLU', 'SCH', 'GEO' }, items = { 'Apogee Petasos' } },
        { sets = { 'Meditate' }, jobs = { 'WHM', 'BLM', 'RDM', 'SMN', 'BLU', 'SCH', 'GEO' }, items = { 'Apogee Cuffs' } },
        { sets = { 'Warcry' },   jobs = { 'WHM', 'BLM', 'RDM', 'SMN', 'BLU', 'SCH', 'GEO' }, items = { 'Apogee Sabots' } },
        { sets = { 'Sublimation' }, items = { 'Apogee Sabots' } },
        -- SCH Artifact + Relic head/body while Sublimation charges (+1 first; the piece whose
        -- description shows a Sublimation bonus wins if you own both for the same slot)
        { sets = { 'Sublimation' }, jobs = { 'SCH' },
          items = { 'Argute M.board +1', 'Argute M.board', 'Sch. M.board +1', "Scholar's M.board", "Scholar's Mortarboard",
                    'Argute Gown +1', 'Argute Gown', "Scholar's Gown +1", "Scholar's Gown" } },
        -- STR rings in every weaponskill with a STR modifier (ws_stat = WS that uses that stat)
        { ws_stat = 'str', items = { 'Ifrit Ring +1', 'Strigoi Ring' } },
        -- SCNM Apex: BRD song duration (legs) and song recast -10 (feet), COR Phantom Roll +1 (legs)
        { sets = { 'Songs_Buff' },   jobs = { 'BRD' }, items = { 'Apex Haidate' } },
        { sets = { 'Songs_Debuff' }, jobs = { 'BRD' }, items = { 'Apex Sune-Ate' } },
        { sets = { 'PhantomRoll' },  jobs = { 'COR' }, items = { 'Apex Haidate' } },
        -- SCNM legs augmented "Refresh +1" (stronger Refresh spell): worn when casting Refresh / Battery Charge
        { sets = { 'RefreshSpell' }, jobs = { 'RDM' }, items = { 'Apogee Tonban' } },
        -- RDM Phalanx (self-cast): Phalanx-received feet + Egeking
        { sets = { 'Phalanx' }, jobs = { 'RDM' }, items = { 'Wise Pigaches +1', 'Egeking' } },
        { sets = { 'RefreshSpell' }, jobs = { 'RUN' }, items = { 'Pinnacle Cuisses' } },
        { sets = { 'BatteryCharge' }, jobs = { 'BLU' }, items = { 'Apogee Tonban' } },
        -- Fotia only helps every hit on fTP-replicating weaponskills; on CatsEyeXI those are only these four
        -- (bg-wiki: CatsEyeXI_Systems/Weaponskills). Elsewhere it is scored by its stats like any neck.
        { ws_names = { 'Resolution', 'Stardiver', 'Blade: Shun', 'Last Stand' }, items = { 'Fotia Gorget' } },
        { ws = 'single', items = { "Combatant's Torque" } },
        -- NIN / THF TP: Ares's Ring (Shukuyu Ring is excluded there, see set_exclude)
        { sets = { 'TP' }, jobs = { 'NIN', 'THF' }, items = { "Ares's Ring" } },
        -- WHM: Yagrush for -na spells and Erase (makes them area of effect)
        { sets = { 'NaSpells' }, jobs = { 'WHM' }, items = { 'Yagrush' } },
        -- NIN weaponskill ammo (every other NIN set keeps Yoru Shuriken): DEX weaponskills / STR weaponskills
        { ws_stat = 'dex', jobs = { 'NIN' }, items = { 'Yetshila +1' } },
        { ws_stat = 'str', jobs = { 'NIN' }, items = { 'Cinderstone' } },
    },

    -- Stats to SET on specific items (corrects values the description doesn't show or words oddly).
    -- Other stats on the item are still read normally; this value replaces that one stat.
    stat_fix = {
        ['Brutal Earring +1'] = { da = 6 },
        ['Yetshila +1']       = { dex = 2, crit = 2, critdmg = 3 },
        ['Ultion Mantle']     = { counter = 2 },
        ['Bloodbead Gorget']  = { hp = 60, vit = 3, acc = 5, pdt = -2 },
        ['Inmicus Cuisses']   = { hp = 25, eva = -10, dt = -2, enmity = 3 },
        ['Oneiros Cluster']   = { haste = 1, att = -3 },
        -- Soil Earring = the NQ Terra's Earring
        ['Soil Earring']      = { pdt = -2 },
        ['Loquac. Earring']   = { mp = 30, fc = 2 },
        -- Level-scaled rings (2~5 by level): the value at the level cap (75)
        ['Rajas Ring']        = { str = 5, dex = 5, stp = 5, sb = 5 },
        ['Sattva Ring']       = { hp = 15, vit = 5, agi = 5, enmity = 3 },
        ['Tamas Ring']        = { int = 5, mnd = 5, mp = 15, enmity = -3 },
        -- Jailer torques (CatsEyeXI): one stat +5 and two weapon skills +7
        ['Love Torque']       = { dex = 5, sk_dagger = 7, sk_polearm = 7 },
        ['Prudence Torque']   = { int = 5, sk_gsword = 7, sk_club = 7 },
        ['Justice Torque']    = { str = 5, sk_scythe = 7, sk_gkatana = 7 },
        ['Hope Torque']       = { agi = 5, sk_katana = 7, archery = 7 },
        ['Fortitude Torque']  = { vit = 5, sk_sword = 7, sk_gaxe = 7 },
        ['Temp. Torque']      = { chr = 5, sk_axe = 7, sk_staff = 7 },
        ['Faith Torque']      = { mnd = 5, sk_h2h = 7, marksmanship = 7 },
    },

    -- Stats to ignore on specific items (e.g. bonuses that only work in certain zones).
    -- The rest of the item's stats still count. Use the stat keys listed at the top.
    stat_remove = {
        ["Ares's Ring"] = { 'da' },    -- Double Attack +2% only in Lumoria
    },

    -- GearSwap export: CatsEyeXI renamed some items in its custom game files, but Windower/GearSwap
    -- still knows them by their ORIGINAL name. Map  ['Name in game'] = 'Original name'.
    gs_names = {
        ['Bagua Sash'] = 'Gishdubar Sash',
    },

    -- Jobs that also optimize the range slot in some sets (a ranged weapon there; ammo is left alone).
    -- Values: 'tp', 'ws' (set kinds) or set ids like 'Meditate'.
    -- Jobs that keep ONE item in the range slot in every set (swapping it resets TP). The first one you own
    -- is used; if you own none, your best instrument for songs. The first name is shown as Best in Slot.
    keep_range = {
        BRD = { 'Gjallarhorn' },
    },
    -- Jobs that keep ONE ammo in every set except weaponskills (NIN: the shuriken). Weaponskills choose their own
    -- ammo (see the NIN rules in preferred). The first name is shown as Best in Slot.
    keep_ammo = {
        NIN = { 'Yoru Shuriken' },
    },

    job_range = {
        SAM = { 'tp', 'ws', 'Meditate' },
    },

    -- SCNM / Summit gear. The full 5-piece set grants "SP ability delay -5 min", so it is equipped
    -- when you use your 2-hour. Each job uses its own Summit family.
    summit = {
        Apogee   = { head = 'Apogee Petasos',  body = 'Apogee Coat',     hands = 'Apogee Cuffs',
                     legs = 'Apogee Tonban',   feet = 'Apogee Sabots' },
        Pinnacle = { head = 'Pinnacle Celata', body = 'Pinnacle Cuirass', hands = 'Pinnacle Dastanas',
                     legs = 'Pinnacle Cuisses', feet = 'Pinnacle Sabatons' },
        Apex     = { head = 'Apex Hatsuburi',  body = 'Apex Togi',       hands = 'Apex Kote',
                     legs = 'Apex Haidate',    feet = 'Apex Sune-Ate' },
    },
    -- Job -> { 2-hour ability, Summit family }
    sp_abilities = {
        WAR = { 'Mighty Strikes', 'Pinnacle' },   MNK = { 'Hundred Fists', 'Apex' },
        WHM = { 'Benediction', 'Apogee' },        BLM = { 'Manafont', 'Apogee' },
        RDM = { 'Chainspell', 'Apogee' },         THF = { 'Perfect Dodge', 'Apex' },
        PLD = { 'Invincible', 'Pinnacle' },       DRK = { 'Blood Weapon', 'Pinnacle' },
        BST = { 'Familiar', 'Pinnacle' },         BRD = { 'Soul Voice', 'Apex' },
        RNG = { 'Eagle Eye Shot', 'Apex' },       SAM = { 'Meikyo Shisui', 'Pinnacle' },
        NIN = { 'Mijin Gakure', 'Apex' },         DRG = { 'Call Wyvern', 'Pinnacle' },
        SMN = { 'Astral Flow', 'Apogee' },        BLU = { 'Azure Lore', 'Apogee' },
        COR = { 'Wild Card', 'Apex' },            PUP = { 'Overdrive', 'Apex' },
        DNC = { 'Trance', 'Apex' },               SCH = { 'Tabula Rasa', 'Apogee' },
        GEO = { 'Bolster', 'Apogee' },            RUN = { 'Elemental Sforzo', 'Pinnacle' },
    },

    -- Items only these jobs may use (overrides the job list in the item's game data)
    job_restrict = {
        ['Inmicus Cuisses'] = { 'WAR', 'PLD', 'DRK' },
        ['Kiryoku Nenju'] = { 'MNK' },
    },

    -- Items only used in these sets (e.g. movement gear stays out of idle/TP/etc.)
    set_restrict = {
        ['Kupo Suit'] = { 'Movement' },
    },

    -- Body pieces that also take up or hide other slots (CatsEyeXI 'rslot' + 'rslotlook': gear in a hidden slot never
    -- registers as worn, so a gear-swap addon re-equips it nonstop). The exports write those slots as
    -- 'displaced' / empty, so a profile never equips something there and knocks the piece back off
    -- (Kupo Suit in Movement over the Idle legs kept swapping on and off while running).
    covers = {
        -- covers head
        ['Black Cloak'] = { 'head' },
        ['C.C. Cloak +1'] = { 'head' },
        ['C.C. Cloak +2'] = { 'head' },
        ['Cloak'] = { 'head' },
        ['Cloak +1'] = { 'head' },
        ['Cmb.Cst. Cloak'] = { 'head' },
        ['Cohort Cloak'] = { 'head' },
        ['Cohort Cloak +1'] = { 'head' },
        ['Demons Cloak'] = { 'head' },
        ['Eerie Cloak'] = { 'head' },
        ['Eerie Cloak +1'] = { 'head' },
        ['High Mana Cloak'] = { 'head' },
        ['Ixion Cloak'] = { 'head' },
        ['Jurfu Cloak'] = { 'head' },
        ['Lugra Cloak'] = { 'head' },
        ['Lugra Cloak +1'] = { 'head' },
        ['Mana Cloak'] = { 'head' },
        ['R.K. Cloak +1'] = { 'head' },
        ['R.K. Cloak +2'] = { 'head' },
        ['Ramblers Cloak'] = { 'head' },
        ['Respite Cloak'] = { 'head' },
        ['Restorer Cloak'] = { 'head' },
        ['Royal Cloak'] = { 'head' },
        ['Ryl.Kgt. Cloak'] = { 'head' },
        ['Shamans Cloak'] = { 'head' },
        ['Silk Cloak'] = { 'head' },
        ['Silk Cloak +1'] = { 'head' },
        ['Twilight Cloak'] = { 'head' },
        ['Vampire Cloak'] = { 'head' },
        ['Vermillion Cloak'] = { 'head' },
        ['White Cloak'] = { 'head' },
        ['White Cloak +1'] = { 'head' },
        ['Wikyo Cloak'] = { 'head' },
        -- covers legs
        ['Behemoth Suit'] = { 'hands', 'legs', 'feet' },
        ['Behemoth Suit +1'] = { 'hands', 'legs', 'feet' },
        ['Korrigan Suit'] = { 'hands', 'legs', 'feet' },
        ['Kupo Suit'] = { 'hands', 'legs', 'feet' },   -- blocks legs, also hides hands/feet: gear there never registers
        ['Mandra. Suit'] = { 'hands', 'legs', 'feet' },
        ['Mandra. Suit +1'] = { 'hands', 'legs', 'feet' },
        ['Onca Suit'] = { 'hands', 'legs', 'feet' },
        ['Overalls'] = { 'legs' },
        ['Wyrmking Suit'] = { 'hands', 'legs', 'feet' },
        ['Wyrmking Suit +1'] = { 'hands', 'legs', 'feet' },
        -- covers hands
        ['Argent Coat'] = { 'hands' },
        ['Benedight Coat'] = { 'hands' },
        ['Decennial Coat'] = { 'hands' },
        ['Decennial Coat +1'] = { 'hands' },
        ['Esthetes Coat'] = { 'hands' },
        -- covers hands, feet
        ['Chocobo Suit'] = { 'hands', 'legs', 'feet' },
        ['Chocobo Suit +1'] = { 'hands', 'legs', 'feet' },
        ['G. Moogle Suit'] = { 'hands', 'legs', 'feet' },
        ['Goblin Suit'] = { 'hands', 'legs', 'feet' },
        -- covers head, hands
        ['Botulus Suit'] = { 'head', 'hands' },
        ['Botulus Suit +1'] = { 'head', 'hands' },
        -- covers hands, legs, feet
        ['Adenium Suit'] = { 'hands', 'legs', 'feet' },
        ['Bl. Chocobo Suit'] = { 'hands', 'legs', 'feet' },
        ['Moogle Suit'] = { 'hands', 'legs', 'feet' },
    },

    -- Spell name filters used by the generated <midmagic> rules (wildcards * and | allowed)
    rules = {
        cure          = 'Cure*|Cura*',
        enfeebling_mnd = 'Slow*|Paralyze*|Silence|Addle*|Distract*|Frazzle*',
        elemental_dot = 'Burn|Frost|Choke|Rasp|Shock|Drown',
        song_debuff   = '*Requiem*|*Lullaby*|*Elegy*|*Threnody*|*Finale*|*Nocturne*',
        drain_aspir   = 'Drain*|Aspir*',
        breath_spells = 'Dia*|Poison*|Poisonga*|Foot Kick|Barfire*',     -- spells that make the wyvern use a breath
        pet_breath    = 'Healing Breath*|Flame Breath|Frost Breath|Gust Breath|Hydro Breath|Lightning Breath|Sand Breath|Remove Breath',
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
        -- WHM -na spells and Erase: Healing gear, plus Yagrush in the main hand when you own it ("-na spells: area of effect")
        NaSpells      = { label = '-na spells / Erase (Yagrush)', weapons = true, weights = { healing = 5, cmp = 0.5, sird = 1 } },
        Enhancing     = { label = 'Enhancing magic skill', weapons = true, weights = { enhancing = 5, enhdur = 2, cmp = 0.5, sird = 0.5, mnd = 0.3 } },
        -- Casting Refresh / Refresh II: your Enhancing pieces + Refresh+ (SCNM legs)
        RefreshSpell  = { label = 'Refresh (spell)', weapons = true, weights = { enhancing = 5, enhdur = 2, cmp = 0.5, sird = 0.5, mnd = 0.3, refreshpot = 20 } },
        -- stoneskin = extra damage absorbed (Stone Gorget +30); 1 point is worth about 1 MND in the Stoneskin formula
        Stoneskin     = { label = 'Stoneskin (MND)', weapons = true, weights = { mnd = 4, enhancing = 1.5, stoneskin = 4 } },
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
        BloodPact     = { label = 'Blood Pact damage', weapons = true, weights = { bpdmg = 8, summoning = 3, bloodboon = 1, petatk = 1, petacc = 1 } },
        -- Utility
        Enmity      = { label = 'Enmity', caps = DEF, weights = { enmity = 6, hp = 0.05, dt = -2, pdt = -2, curercv = 0.3, enmloss = 1 } },
        -- Only the Treasure Hunter pieces: worn on top of TP gear with /th, every other slot keeps your TP piece
        TH          = { label = 'Treasure Hunter (only TH pieces)', weights = { th = 50 } },
        Waltz       = { label = 'Waltz potency', weights = { waltz = 10, chr = 1, vit = 1, waltzdelay = 3 } },
        -- DNC abilities (worn when you use them)
        Steps           = { label = 'Steps (accuracy)', weights = { stepacc = 3, acc = 2, stepfinish = 15, dex = 0.3 } },
        Samba           = { label = 'Samba (duration)', weights = { samba = 3, sambap = 10 } },
        Jig             = { label = 'Jig (duration)', weights = { jig = 10 } },
        ViolentFlourish = { label = 'Violent Flourish', weights = { vfmacc = 3, macc = 2, acc = 1, chr = 0.5 } },
        Preshot     = { label = 'Ranged - Preshot', ranged = 'job', weights = { snapshot = 8, rapid = 6 } },
        Preshot_Gun = { label = 'Ranged - Preshot (gun)', ranged = 'Marksmanship', weights = { snapshot = 8, rapid = 6 } },
        Midshot     = { label = 'Ranged - Midshot', ranged = 'job', weights = { racc = 1.5, ratt = 1, agi = 1, stp = 3, crit = 2, recycle = 0.5 } },
        Midshot_Gun = { label = 'Ranged - Midshot (gun)', ranged = 'Marksmanship', weights = { racc = 1.5, ratt = 1, agi = 1, stp = 3, crit = 2, recycle = 0.5 } },
        QuickDraw   = { label = 'Quick Draw', ranged = 'job', weights = { mab = 8, macc = 3, agi = 2, racc = 0.5 } },
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
        -- Worn on top of your TP set while the Counterstance buff is active (pieces from bis.lua)
        -- THF: only the Trick Attack piece (hands), worn on top of your TP gear while Trick Attack is up
        -- (also put on the moment you use Trick Attack, and kept on engaged or not while the buff is up)
        TrickAttack = { label = 'Trick Attack (buff active)', engaged_buff = 'Trick Attack', buff_any = true, weights = { taagi = 10 } },
        -- THF Flee: Rog. Poulaines +1 (Flee duration +15s) worn when you use Flee; plain Rogue's Poulaines if you lack the +1
        Flee        = { label = 'Flee (duration)', weights = {}, fixed = { feet = 'Rog. Poulaines +1' },
                        fallback = { feet = "Rogue's Poulaines" } },
        Counterstance = { label = 'Counterstance (buff active)', engaged_buff = 'Counterstance',
                          weights = { counter = 10, vit = 0.5, hp = 0.02, acc = 0.5, pdt = -3, dt = -3 } },
        -- MNK Chakra: your BiS pieces. If you don't own Genmei Kabuto, Genbu's Kabuto is used instead.
        Chakra      = { label = 'Chakra', weights = { vit = 2, hp = 0.05 },
                        -- a list = any of these spellings (long or shortened in-game name)
                        fixed = { head = 'Genmei Kabuto', body = 'Tpl. Cyclas +1',
                                  hands = 'Mel. Gloves +1', neck = 'Kiryoku Nenju' },
                        fallback = { head = "Genbu's Kabuto" } },
        -- MNK Focus: Temple Crown +1 enhances the Focus effect (long or shortened in-game name)
        Focus       = { label = 'Focus', weights = {}, fixed = { head = 'Tpl. Crown +1' } },
        Meditate    = { label = 'Meditate', weights = { meditate = 10 } },
        Berserk     = { label = 'Berserk', weights = { berserk = 10 } },
        Warcry      = { label = 'Warcry', weights = { warcry = 10 } },
        Sublimation = { label = 'Sublimation', weights = { sublimation = 10 } },
        PhantomRoll = { label = 'Phantom Roll', range = 'any', weights = { roll = 10, rolldur = 2, rolldelay = 3, rollaoe = 6 } },

        -- MNK: Temple Gloves +1 enhance Boost. Worn when you use Boost.
        Boost       = { label = 'Boost', weights = { boost = 10 } },

        -- BLU: blue magic categories (the gear comes from your BLU XML)
        BluPhys      = { label = 'Blue magic - Physical', weights = { blue = 3, str = 1.5, dex = 1.2, vit = 0.5, att = 1, acc = 1, da = 2, crit = 1 } },
        BluMag       = { label = 'Blue magic - Magical', weapons = true, weights = { blue = 2, int = 2, mab = 8, macc = 2, mbb = 3 } },
        BluDebuff    = { label = 'Blue magic - Debuff', weapons = true, weights = { macc = 4, blue = 3, int = 1, mnd = 0.5 } },
        SpectralFloe = { label = 'Spectral Floe', weapons = true, weights = { blue = 1, int = 2, mab = 8, macc = 1.5, mbb = 3 } },
        BatteryCharge = { label = 'Battery Charge', weapons = true, weights = { enhdur = 3, blue = 1, refresh = 2, cmp = 0.5, refreshpot = 20 } },
        -- Idle gear you switch on yourself with /refresh (MP recovery)
        Refresh      = { label = 'Idle - Refresh (toggle /refresh)', weapons = true, weights = { refresh = 30, hmp = 3, regen = 3, mp = 0.02 } },

        -- PUP: automaton sets. Pet stats can't be read from item text, so these are your exact pieces
        -- (a list = any of those names; anything you don't own is filled automatically).
        PetTank   = { label = 'Automaton - Tank (pet DT)', weights = { dt = -4, pdt = -4, hp = 0.05, vit = 0.5 },
                      fixed = { head = { 'Pantin Taj +1', 'Puppetry Taj +1' }, neck = "Shepherd's Chain",
                                ear1 = 'Ghillie Earring +1', ear2 = 'Ghillie Earring +1', body = 'Apex Togi',
                                hands = 'Pantin Dastanas +1', ring1 = 'Defending Ring +1', ring2 = 'Titanium Band',
                                back = { 'Oneiros Cappa', 'Pantin Cape' }, waist = 'Beastly Girdle', legs = "Enticer's Pants",
                                feet = 'Pup. Babouches +1' } },
        PetRanged = { label = 'Automaton - Ranged', weights = { agi = 0.5, racc = 0.5, ratt = 0.5 }, pref_slots = { 'range', 'ammo' },
                      fixed = { range = 'Animator +1', ammo = 'Bolt Stone', head = 'Puppetry Taj +1', neck = "Tinker's Collar",
                                ear1 = 'Ghillie Earring +1', ear2 = 'Ghillie Earring +1', body = 'Pantin Tobe +1',
                                hands = 'Venom Vambraces', back = 'Pantin Cape', legs = "Prince's Slops", feet = 'Ryuga Sune-Ate' } },
        -- Dragoon
        Jump        = { label = 'Jump', weights = { acc = 1.5, att = 1, str = 0.8, dex = 0.5, crit = 2, da = 2, ta = 3, haste = 1.5, stp = 1 } },
        HighJump    = { label = 'High Jump', weights = { acc = 1.5, att = 1, str = 0.8, dex = 0.5, crit = 2, da = 2, ta = 3, haste = 1.5, stp = 1 } },
        Angon       = { label = 'Angon', weights = {}, fixed = { ammo = 'Angon' } },
        DragonBreaker = { label = 'Dragon Breaker', weights = {}, fixed = { ammo = 'Fjoturangon' } },
        AncientCircle = { label = 'Ancient Circle', weights = {}, fixed = { legs = 'Drachen Brais' } },
        -- Worn on top of Precast when a spell makes the wyvern breathe / while it breathes
        Breath        = { label = 'Wyvern breath trigger (precast)', weights = {}, fixed = { head = 'Drachen Armet' } },
        BreathPotency = { label = 'Wyvern breath potency (pet skill)', weights = {}, fixed = { head = 'Wyrm Armet' } },
        -- Worn while running in earth weather
        DesertBoots   = { label = 'Desert Boots (running in earth weather)', weights = {}, fixed = { feet = 'Desert Boots' } },
        -- /dw toggle: your dual-wield weapons, worn on top of whatever set is active while the toggle is ON.
        -- Only the exact weapons listed here are ever used (never an auto-picked weapon).
        DW = { label = 'Dual wield weapons (/dw toggle)', weights = { dw = 1 },
               fixed_by_job = {
                   BLU = { main = 'Undulant Black', sub = 'Blurred Rod +1' },
                   WAR = { main = 'Brilliance',     sub = 'Blurred Rod +1' },
               } },
        -- PLD spells and abilities (sets from a PLD LuAshitacast profile)
        SIR        = { label = 'Spell interruption (midcast base)', weights = { sird = 6, hp = 0.05, dt = -3, pdt = -3, mdt = -2, enmity = 1 } },
        Flash      = { label = 'Flash', weights = { enmity = 6, hp = 0.05, sird = 1, dt = -2, pdt = -2 } },
        Reprisal   = { label = 'Reprisal', weights = { enmity = 4, sird = 3, hp = 0.08, dt = -2, pdt = -2 } },
        Phalanx    = { label = 'Phalanx (your own cast)', weapons = true, weights = { phalanx = 10, phalanxrcv = 10, enhancing = 1.5, sird = 1 } },
        -- Only the Phalanx-received pieces, worn on top of your gear for a few seconds
        PhalanxRcv = { label = 'Phalanx received (cast on you)', weights = { phalanxrcv = 10 } },
        -- Ability pieces, worn on top of the Enmity set when you use the ability
        Sentinel   = { label = 'Sentinel', weights = { sentinel = 10 } },
        ShieldBash = { label = 'Shield Bash / Chivalry', weights = { shieldbash = 10 } },
        Rampart    = { label = 'Rampart', weights = { rampart = 10 } },
        Cover      = { label = 'Cover', weights = { cover = 10, covermp = 1 } },
        -- Not gear: the attachments for the ranged automaton setup, shown as a list in the set window
        Attachments = { label = 'Automaton attachments (ranged setup)',
                        info = { 'Tension Spring III', 'Magniplug', 'Magniplug II', 'Drum Magazine', 'Scope III', 'Repeater',
                                 'Dynamo', 'Heatsink', 'Stealth Screen II', 'Optic Fiber II', 'Optic Fiber', 'Target Marker' } },
    },

    jobs = {
        WAR = { 'TP', 'TP_Hybrid', 'WS', 'Idle', 'PDT', 'MDT', 'Enmity', 'Movement', 'DW', 'Berserk', 'Warcry', 'Meditate', 'MightyStrikes', 'SP' },
        MNK = { 'TP_MNK', 'TP_Hybrid', 'WS', 'Idle', 'PDT', 'MDT', 'Waltz', 'Movement', 'Berserk', 'Warcry', 'SP', 'Counterstance', 'Chakra', 'Boost', 'Focus', 'Meditate' },
        WHM = { 'Idle', 'Resting', 'Precast', 'Precast_Cure', 'Cure', 'Healing', 'NaSpells', 'Enhancing', 'Stoneskin', 'Enfeebling_MND', 'Divine', 'PDT', 'MDT', 'TP', 'WS', 'Sublimation', 'SP', 'Movement', 'Berserk', 'Warcry', 'Meditate' },
        BLM = { 'Idle', 'Resting', 'Precast', 'Nuke', 'Nuke_MB', 'MagicAcc', 'Dark', 'DrainAspir', 'Enfeebling_INT', 'Enhancing', 'Stoneskin', 'PDT', 'MDT', 'SP', 'Movement', 'Berserk', 'Warcry', 'Meditate' },
        RDM = { 'Idle', 'Resting', 'Precast', 'Precast_Cure', 'Cure', 'Enhancing', 'RefreshSpell', 'Phalanx', 'Stoneskin', 'Enfeebling_MND', 'Enfeebling_INT', 'Nuke', 'Nuke_MB', 'Dark', 'DrainAspir', 'TP', 'TP_Hybrid', 'WS', 'PDT', 'MDT', 'SP', 'Movement', 'Berserk', 'Warcry', 'Meditate' },
        THF = { 'TP', 'TP_Hybrid', 'WS', 'TrickAttack', 'Flee', 'TH', 'Idle', 'PDT', 'MDT', 'Preshot', 'Midshot', 'Movement', 'Berserk', 'Warcry', 'SP', 'Meditate' },
        PLD = { 'TP', 'TP_Hybrid', 'WS', 'Enmity', 'Idle', 'PDT', 'MDT', 'Precast', 'Precast_Cure', 'Cure', 'SIR', 'Flash', 'Reprisal',
                'Phalanx', 'PhalanxRcv', 'Enhancing', 'Divine', 'Sentinel', 'ShieldBash', 'Rampart', 'Cover',
                'Berserk', 'Warcry', 'Meditate', 'SP', 'Movement' },
        DRK = { 'TP', 'TP_Hybrid', 'WS', 'Idle', 'PDT', 'MDT', 'Precast', 'Dark', 'DrainAspir', 'Enfeebling_INT', 'Berserk', 'Warcry', 'Meditate', 'SP', 'Movement' },
        BST = { 'TP', 'TP_Hybrid', 'WS', 'Idle', 'PDT', 'MDT', 'Berserk', 'Warcry', 'SP', 'Movement' },
        BRD = { 'Idle', 'Resting', 'Precast', 'Precast_Song', 'Precast_Cure', 'Songs_Buff', 'Songs_Debuff', 'Cure', 'PDT', 'MDT', 'TP', 'WS', 'SP', 'Movement', 'Berserk', 'Warcry', 'Meditate' },
        RNG = { 'Preshot', 'Preshot_Gun', 'Midshot', 'Midshot_Gun', 'WS', 'Idle', 'PDT', 'MDT', 'TP', 'Berserk', 'Warcry', 'SP', 'Movement', 'Meditate' },
        SAM = { 'TP', 'TP_Hybrid', 'WS', 'Idle', 'PDT', 'MDT', 'Movement', 'Meditate', 'Berserk', 'Warcry', 'SP' },
        NIN = { 'TP', 'TP_Hybrid', 'WS', 'Ninjutsu', 'Precast', 'Enmity', 'Idle', 'PDT', 'MDT', 'Movement', 'Berserk', 'Warcry', 'SP', 'Meditate' },
        DRG = { 'TP', 'TP_Hybrid', 'WS', 'Idle', 'PDT', 'MDT', 'Precast', 'Jump', 'HighJump', 'Angon', 'AncientCircle', 'DragonBreaker', 'Breath', 'BreathPotency', 'Berserk', 'Warcry', 'Meditate', 'SP', 'Movement', 'DesertBoots' },
        SMN = { 'Idle', 'Idle_Avatar', 'Resting', 'Precast', 'BP_Delay', 'BloodPact', 'Cure', 'Enhancing', 'PDT', 'MDT', 'SP', 'Movement', 'Berserk', 'Warcry', 'Meditate' },
        BLU = { 'TP', 'TP_Hybrid', 'WS', 'BluPhys', 'BluMag', 'BluDebuff', 'BlueMagic', 'SpectralFloe', 'BatteryCharge', 'Precast', 'Cure', 'Idle', 'Resting', 'Refresh', 'PDT', 'MDT', 'DW', 'Berserk', 'Warcry', 'SP', 'Movement', 'Meditate' },
        COR = { 'TP', 'TP_Hybrid', 'WS', 'Preshot', 'Midshot', 'QuickDraw', 'PhantomRoll', 'Idle', 'PDT', 'MDT', 'Berserk', 'Warcry', 'SP', 'Movement', 'Meditate' },
        PUP = { 'TP', 'TP_Hybrid', 'WS', 'Idle', 'PDT', 'MDT', 'Berserk', 'Warcry', 'SP', 'Movement', 'PetTank', 'PetRanged', 'Attachments', 'Meditate' },
        DNC = { 'TP', 'TP_Hybrid', 'WS', 'Waltz', 'Steps', 'Samba', 'Jig', 'ViolentFlourish', 'Idle', 'PDT', 'MDT', 'Movement', 'Berserk', 'Warcry', 'SP', 'Meditate' },
        SCH = { 'Idle', 'Resting', 'Precast', 'Precast_Cure', 'Cure', 'Enhancing', 'Stoneskin', 'Enfeebling_MND', 'Enfeebling_INT', 'Nuke', 'Nuke_MB', 'MagicAcc', 'Dark', 'DrainAspir', 'PDT', 'MDT', 'Sublimation', 'SP', 'Movement', 'Berserk', 'Warcry', 'Meditate' },
        GEO = { 'Idle', 'Resting', 'Precast', 'Geomancy', 'Nuke', 'Nuke_MB', 'Enfeebling_INT', 'Cure', 'PDT', 'MDT', 'SP', 'Movement', 'Berserk', 'Warcry', 'Meditate' },
        RUN = { 'TP', 'TP_Hybrid', 'WS', 'Enmity', 'Idle', 'PDT', 'MDT', 'Enhancing', 'RefreshSpell', 'Precast', 'Berserk', 'Warcry', 'SP', 'Movement' },
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
    -- the server software CatsEyeXI runs on. id = weaponskill id used in the XML rules.
    -- Stat modifiers are CatsEyeXI's own (many are customized), from bg-wiki: CatsEyeXI_Systems/Weaponskills.
    weaponskills = {
        -- Generic fallbacks used for the default 'WS' set
        { name = 'Generic: single hit (STR)', jobs = { '*' }, kind = 'physical', hits = 1, mods = { str = 0.60 } },
        { name = 'Generic: multi hit (STR)',  jobs = { '*' }, kind = 'physical', hits = 4, mods = { str = 0.50 } },
        { name = 'Generic: crit (DEX)',       jobs = { '*' }, kind = 'physical', hits = 3, crit = true, mods = { dex = 0.60 } },
        { name = 'Generic: ranged (AGI)',     jobs = { '*' }, kind = 'ranged', hits = 1, mods = { agi = 0.60 } },
        { name = 'Generic: magical (INT)',    jobs = { '*' }, kind = 'magical', hits = 1, mods = { int = 0.60 } },

        -- Hand-to-Hand
        { id = 11, name = 'Ascetic\'s Fury', skill = 1, jobs = { 'MNK' }, kind = 'physical', hits = 2, crit = true, mods = { str = 0.75, vit = 0.75 } },
        { id = 10, name = 'Final Heaven', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 2, mods = { vit = 0.80 } },
        { id = 12, name = 'Stringing Pummel', skill = 1, jobs = { 'PUP' }, kind = 'physical', hits = 6, crit = true, mods = { str = 0.75, vit = 0.75 } },
        { id = 14, name = 'Victory Smite', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 4, crit = true, mods = { str = 0.60 } },
        { id = 1, name = 'Combo', skill = 1, jobs = { 'WAR', 'MNK', 'THF', 'NIN', 'PUP', 'DNC' }, kind = 'physical', hits = 3, mods = { str = 0.20, dex = 0.20 } },
        { id = 2, name = 'Shoulder Tackle', skill = 1, jobs = { 'WAR', 'MNK', 'THF', 'NIN', 'PUP', 'DNC' }, kind = 'physical', hits = 2, mods = { vit = 0.30 } },
        { id = 3, name = 'One Inch Punch', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 2, mods = { vit = 0.40 } },
        { id = 4, name = 'Backhand Blow', skill = 1, jobs = { 'WAR', 'MNK', 'THF', 'NIN', 'PUP', 'DNC' }, kind = 'physical', hits = 2, crit = true, mods = { str = 0.30, dex = 0.30 } },
        { id = 5, name = 'Raging Fists', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 5, mods = { str = 0.20, dex = 0.20 } },
        { id = 6, name = 'Spinning Attack', skill = 1, jobs = { 'WAR', 'MNK', 'THF', 'NIN', 'PUP', 'DNC' }, kind = 'physical', hits = 2, mods = { str = 0.35 } },
        { id = 7, name = 'Howling Fist', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 2, mods = { str = 0.20, vit = 0.50 } },
        { id = 8, name = 'Dragon Kick', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 2, mods = { str = 0.50, vit = 0.50 } },
        { id = 9, name = 'Asuran Fists', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 8, mods = { str = 0.50, vit = 0.50 } },
        { id = 13, name = 'Tornado Kick', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 3, mods = { str = 0.60, vit = 0.60 } },
        { id = 15, name = 'Shijin Spiral', skill = 1, jobs = { 'MNK', 'PUP' }, kind = 'physical', hits = 5, mods = { dex = 0.95 } },

        -- Dagger
        { id = 27, name = 'Mandalic Stab', skill = 2, jobs = { 'THF' }, kind = 'physical', hits = 1, mods = { dex = 0.75 } },
        { id = 26, name = 'Mercy Stroke', skill = 2, jobs = { 'WAR', 'RDM', 'THF', 'BST', 'BRD', 'RNG', 'NIN', 'COR', 'DNC' }, kind = 'physical', hits = 1, mods = { str = 0.80 } },
        { id = 28, name = 'Mordant Rime', skill = 2, jobs = { 'BRD' }, kind = 'physical', hits = 2, mods = { dex = 0.95, chr = 0.95 } },
        { id = 29, name = 'Pyrrhic Kleos', skill = 2, jobs = { 'DNC' }, kind = 'physical', hits = 4, mods = { str = 0.80, dex = 0.80 } },
        { id = 31, name = 'Rudra\'s Storm', skill = 2, jobs = { 'THF', 'BRD', 'DNC' }, kind = 'physical', hits = 1, mods = { dex = 0.60 } },
        { id = 16, name = 'Wasp Sting', skill = 2, jobs = { 'WAR', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'COR', 'PUP', 'DNC', 'SCH' }, kind = 'physical', hits = 1, mods = { dex = 0.30 } },
        { id = 19, name = 'Gust Slash', skill = 2, jobs = { 'WAR', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'COR', 'PUP', 'DNC', 'SCH' }, kind = 'magical', hits = 1, mods = { dex = 0.20, int = 0.20 } },
        { id = 18, name = 'Shadowstitch', skill = 2, jobs = { 'WAR', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'COR', 'PUP', 'DNC', 'SCH' }, kind = 'physical', hits = 1, mods = { chr = 0.30 } },
        { id = 17, name = 'Viper Bite', skill = 2, jobs = { 'RDM', 'THF', 'BRD', 'RNG', 'NIN', 'DNC' }, kind = 'physical', hits = 1, mods = { dex = 0.60 } },
        { id = 20, name = 'Cyclone', skill = 2, jobs = { 'RDM', 'THF', 'BRD', 'RNG', 'NIN', 'DNC' }, kind = 'magical', hits = 1, mods = { dex = 0.30, int = 0.25 } },
        { id = 21, name = 'Energy Steal', skill = 2, jobs = { 'WAR', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'COR', 'PUP', 'DNC', 'SCH' }, kind = 'magical', hits = 1, mods = { mnd = 1.00 } },
        { id = 22, name = 'Energy Drain', skill = 2, jobs = { 'RDM', 'THF', 'BRD', 'RNG', 'NIN', 'DNC' }, kind = 'magical', hits = 1, mods = { mnd = 1.00 } },
        { id = 23, name = 'Dancing Edge', skill = 2, jobs = { 'THF', 'DNC' }, kind = 'physical', hits = 5, mods = { dex = 0.30, chr = 0.40 } },
        { id = 24, name = 'Shark Bite', skill = 2, jobs = { 'THF', 'DNC' }, kind = 'physical', hits = 2, mods = { dex = 0.60, agi = 0.60 } },
        { id = 25, name = 'Evisceration', skill = 2, jobs = { 'WAR', 'RDM', 'THF', 'BST', 'BRD', 'RNG', 'NIN', 'COR', 'DNC' }, kind = 'physical', hits = 5, crit = true, mods = { dex = 0.50 } },
        { id = 30, name = 'Dagger weapon skill', skill = 2, jobs = { 'RDM', 'THF', 'BRD', 'RNG', 'NIN', 'DNC' }, kind = 'magical', hits = 1, mods = { dex = 0.28, int = 0.28 } },
        { id = 224, name = 'Exenterator', skill = 2, jobs = { 'WAR', 'RDM', 'THF', 'BST', 'BRD', 'RNG', 'NIN', 'COR', 'DNC' }, kind = 'physical', hits = 4, mods = { agi = 0.95 } },

        -- Sword
        { id = 45, name = 'Atonement', skill = 3, jobs = { 'PLD' }, kind = 'physical', hits = 2, mods = { str = 0.40, vit = 0.50 } },
        { id = 225, name = 'Chant du Cygne', skill = 3, jobs = { 'RDM', 'PLD', 'BLU' }, kind = 'physical', hits = 3, crit = true, mods = { dex = 0.60 } },
        { id = 44, name = 'Death Blossom', skill = 3, jobs = { 'RDM' }, kind = 'physical', hits = 3, mods = { str = 0.50, mnd = 0.85 } },
        { id = 46, name = 'Expiacion', skill = 3, jobs = { 'BLU' }, kind = 'physical', hits = 2, mods = { str = 0.95, dex = 0.20, int = 0.95 } },
        { id = 43, name = 'Knights of Round', skill = 3, jobs = { 'WAR', 'RDM', 'PLD', 'DRK', 'SAM', 'BLU', 'COR', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.65, mnd = 0.65 } },
        { id = 32, name = 'Fast Blade', skill = 3, jobs = { 'WAR', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'RUN' }, kind = 'physical', hits = 2, mods = { str = 0.20, dex = 0.20 } },
        { id = 33, name = 'Burning Blade', skill = 3, jobs = { 'WAR', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'RUN' }, kind = 'magical', hits = 1, mods = { str = 0.20, int = 0.20 } },
        { id = 34, name = 'Red Lotus Blade', skill = 3, jobs = { 'WAR', 'RDM', 'PLD', 'DRK', 'BLU', 'RUN' }, kind = 'magical', hits = 1, mods = { str = 0.30, int = 0.20 } },
        { id = 35, name = 'Flat Blade', skill = 3, jobs = { 'WAR', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 36, name = 'Shining Blade', skill = 3, jobs = { 'WAR', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'RUN' }, kind = 'magical', hits = 1, mods = { str = 0.20, mnd = 0.20 } },
        { id = 37, name = 'Seraph Blade', skill = 3, jobs = { 'WAR', 'RDM', 'PLD', 'DRK', 'BLU', 'RUN' }, kind = 'magical', hits = 1, mods = { str = 0.30, mnd = 0.30 } },
        { id = 38, name = 'Circle Blade', skill = 3, jobs = { 'WAR', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 1.00 } },
        { id = 39, name = 'Spirits Within', skill = 3, jobs = { 'WAR', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'RUN' }, kind = 'physical', hits = 1, mods = {  } },
        { id = 40, name = 'Vorpal Blade', skill = 3, jobs = { 'WAR', 'RDM', 'PLD', 'DRK', 'BLU', 'RUN' }, kind = 'physical', hits = 4, crit = true, mods = { str = 0.30 } },
        { id = 41, name = 'Swift Blade', skill = 3, jobs = { 'PLD', 'RUN' }, kind = 'physical', hits = 3, mods = { str = 0.30, mnd = 0.30 } },
        { id = 42, name = 'Savage Blade', skill = 3, jobs = { 'WAR', 'RDM', 'PLD', 'DRK', 'BLU', 'COR', 'RUN' }, kind = 'physical', hits = 2, mods = { str = 0.80, mnd = 0.80 } },
        { id = 47, name = 'Sanguine Blade', skill = 3, jobs = { 'WAR', 'RDM', 'PLD', 'DRK', 'BLU', 'RUN' }, kind = 'magical', hits = 1, mods = { str = 0.30, mnd = 0.50 } },
        { id = 226, name = 'Requiescat', skill = 3, jobs = { 'WAR', 'RDM', 'PLD', 'DRK', 'SAM', 'BLU', 'COR', 'RUN', 'BRD' }, kind = 'physical', hits = 5, mods = { mnd = 0.85 } },

        -- Great Sword
        { id = 61, name = 'Dimidiation', skill = 4, jobs = { 'RUN' }, kind = 'physical', hits = 2, mods = { dex = 0.95 } },
        { id = 57, name = 'Scourge', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.50, vit = 0.50 } },
        { id = 59, name = 'Torcleaver', skill = 4, jobs = { 'PLD', 'DRK' }, kind = 'physical', hits = 1, mods = { vit = 0.60 } },
        { id = 48, name = 'Hard Slash', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 49, name = 'Power Slash', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 1, crit = true, mods = { str = 0.20, vit = 0.20 } },
        { id = 50, name = 'Frostbite', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'magical', hits = 1, mods = { str = 0.40, int = 0.40 } },
        { id = 51, name = 'Freezebite', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'magical', hits = 1, mods = { str = 0.50, int = 0.50 } },
        { id = 52, name = 'Shockwave', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30, mnd = 0.30 } },
        { id = 53, name = 'Crescent Moon', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.35 } },
        { id = 54, name = 'Sickle Moon', skill = 4, jobs = { 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 2, mods = { str = 0.20, agi = 0.20 } },
        { id = 55, name = 'Spinning Slash', skill = 4, jobs = { 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30, int = 0.30 } },
        { id = 56, name = 'Ground Strike', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.80, int = 0.80 } },
        { id = 58, name = 'Herculean Slash', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'magical', hits = 1, mods = { vit = 0.95 } },
        { id = 60, name = 'Resolution', skill = 4, jobs = { 'WAR', 'PLD', 'DRK', 'RUN' }, kind = 'physical', hits = 5, mods = { str = 0.75 } },

        -- Axe
        { id = 76, name = 'Cloudsplitter', skill = 5, jobs = { 'WAR', 'BST' }, kind = 'magical', hits = 1, mods = { mnd = 0.40, str = 0.40 } },
        { id = 73, name = 'Onslaught', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 1, mods = { dex = 0.90 } },
        { id = 74, name = 'Primal Rend', skill = 5, jobs = { 'BST' }, kind = 'magical', hits = 1, mods = { dex = 0.70, chr = 0.70 } },
        { id = 64, name = 'Raging Axe', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 2, mods = { str = 0.30 } },
        { id = 65, name = 'Smash Axe', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 1.00 } },
        { id = 66, name = 'Gale Axe', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 67, name = 'Avalanche Axe', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 68, name = 'Spinning Axe', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.35 } },
        { id = 69, name = 'Rampage', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 5, crit = true, mods = { str = 0.30 } },
        { id = 70, name = 'Calamity', skill = 5, jobs = { 'WAR', 'BST' }, kind = 'physical', hits = 1, mods = { str = 0.50, vit = 0.50 } },
        { id = 71, name = 'Mistral Axe', skill = 5, jobs = { 'WAR', 'BST' }, kind = 'physical', hits = 1, mods = { str = 0.50 } },
        { id = 72, name = 'Decimation', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 3, mods = { str = 0.50 } },
        { id = 75, name = 'Bora Axe', skill = 5, jobs = { 'WAR', 'BST' }, kind = 'physical', hits = 1, mods = { dex = 1.00 } },
        { id = 77, name = 'Ruinator', skill = 5, jobs = { 'WAR', 'DRK', 'BST', 'RNG', 'RUN' }, kind = 'physical', hits = 4, mods = { str = 0.75 } },

        -- Great Axe
        { id = 90, name = 'King\'s Justice', skill = 6, jobs = { 'WAR' }, kind = 'physical', hits = 3, mods = { str = 0.70 } },  -- CatsEyeXI: full STR
        { id = 89, name = 'Metatron Torment', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.80 } },
        { id = 92, name = 'Ukko\'s Fury', skill = 6, jobs = { 'WAR' }, kind = 'physical', hits = 2, crit = true, mods = { str = 0.60 } },
        { id = 80, name = 'Shield Break', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.20, vit = 0.20 } },
        { id = 81, name = 'Iron Tempest', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 82, name = 'Sturmwind', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 2, mods = { str = 0.30 } },
        { id = 83, name = 'Armor Break', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.20, vit = 0.20 } },
        { id = 84, name = 'Keen Edge', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, crit = true, mods = { str = 0.35 } },
        { id = 85, name = 'Weapon Break', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.32, vit = 0.32 } },
        { id = 86, name = 'Raging Rush', skill = 6, jobs = { 'WAR' }, kind = 'physical', hits = 3, crit = true, mods = { str = 0.50 } },
        { id = 87, name = 'Full Break', skill = 6, jobs = { 'WAR' }, kind = 'physical', hits = 1, mods = { str = 0.50, vit = 0.50 } },
        { id = 88, name = 'Steel Cyclone', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.60, vit = 0.60 } },
        { id = 91, name = 'Fell Cleave', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.60 } },
        { id = 93, name = 'Upheaval', skill = 6, jobs = { 'WAR', 'DRK', 'RUN' }, kind = 'physical', hits = 4, mods = { str = 0.75, vit = 0.75 } },  -- CatsEyeXI: full STR

        -- Scythe
        { id = 105, name = 'Catastrophe', skill = 7, jobs = { 'WAR', 'DRK', 'BST' }, kind = 'physical', hits = 1, mods = { str = 0.60, int = 0.60 } },
        { id = 106, name = 'Insurgency', skill = 7, jobs = { 'DRK' }, kind = 'physical', hits = 4, mods = { str = 0.30, int = 0.30 } },
        { id = 108, name = 'Quietus', skill = 7, jobs = { 'DRK' }, kind = 'physical', hits = 1, mods = { mnd = 0.40, str = 0.40 } },
        { id = 96, name = 'Slice', skill = 7, jobs = { 'WAR', 'BLM', 'DRK', 'BST' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 97, name = 'Dark Harvest', skill = 7, jobs = { 'WAR', 'BLM', 'DRK', 'BST' }, kind = 'magical', hits = 1, mods = { str = 0.20, int = 0.20 } },
        { id = 98, name = 'Shadow of Death', skill = 7, jobs = { 'WAR', 'DRK' }, kind = 'magical', hits = 1, mods = { str = 0.60, int = 0.60 } },
        { id = 99, name = 'Nightmare Scythe', skill = 7, jobs = { 'WAR', 'BLM', 'DRK', 'BST' }, kind = 'physical', hits = 1, mods = { str = 0.30, mnd = 0.30 } },
        { id = 100, name = 'Spinning Scythe', skill = 7, jobs = { 'WAR', 'BLM', 'DRK', 'BST' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 101, name = 'Vorpal Scythe', skill = 7, jobs = { 'WAR', 'BLM', 'DRK', 'BST' }, kind = 'physical', hits = 1, crit = true, mods = { str = 0.35 } },
        { id = 102, name = 'Guillotine', skill = 7, jobs = { 'DRK' }, kind = 'physical', hits = 4, mods = { str = 0.25, mnd = 0.25 } },
        { id = 103, name = 'Cross Reaper', skill = 7, jobs = { 'DRK' }, kind = 'physical', hits = 2, mods = { str = 0.50, mnd = 0.50 } },
        { id = 104, name = 'Spiral Hell', skill = 7, jobs = { 'WAR', 'DRK', 'BST' }, kind = 'physical', hits = 1, mods = { str = 0.65, int = 0.65 } },
        { id = 107, name = 'Infernal Scythe', skill = 7, jobs = { 'WAR', 'BLM', 'DRK', 'BST' }, kind = 'magical', hits = 1, mods = { str = 0.30, int = 0.70 } },
        { id = 109, name = 'Entropy', skill = 7, jobs = { 'WAR', 'DRK', 'BST' }, kind = 'physical', hits = 4, mods = { str = 0.25, int = 0.95 } },

        -- Polearm
        { id = 124, name = 'Camlann\'s Torment', skill = 8, jobs = { 'DRG' }, kind = 'physical', hits = 1, mods = { str = 0.60, vit = 0.60 } },
        { id = 122, name = 'Drakesbane', skill = 8, jobs = { 'DRG' }, kind = 'physical', hits = 4, crit = true, mods = { str = 0.60 } },
        { id = 121, name = 'Geirskogul', skill = 8, jobs = { 'WAR', 'SAM', 'DRG' }, kind = 'physical', hits = 1, mods = { dex = 0.80, agi = 0.40 } },
        { id = 112, name = 'Double Thrust', skill = 8, jobs = { 'WAR', 'PLD', 'SAM', 'DRG' }, kind = 'physical', hits = 2, mods = { str = 0.30 } },
        { id = 113, name = 'Thunder Thrust', skill = 8, jobs = { 'WAR', 'PLD', 'SAM', 'DRG' }, kind = 'magical', hits = 1, mods = { str = 0.20, int = 0.20 } },
        { id = 114, name = 'Raiden Thrust', skill = 8, jobs = { 'WAR', 'PLD', 'DRG' }, kind = 'magical', hits = 1, mods = { str = 0.30, int = 0.30 } },
        { id = 115, name = 'Leg Sweep', skill = 8, jobs = { 'WAR', 'PLD', 'SAM', 'DRG' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 116, name = 'Penta Thrust', skill = 8, jobs = { 'WAR', 'PLD', 'SAM', 'DRG' }, kind = 'physical', hits = 5, mods = { str = 0.20, dex = 0.20 } },
        { id = 117, name = 'Vorpal Thrust', skill = 8, jobs = { 'WAR', 'PLD', 'SAM', 'DRG' }, kind = 'physical', hits = 1, crit = true, mods = { str = 0.20, agi = 0.20 } },
        { id = 118, name = 'Skewer', skill = 8, jobs = { 'DRG' }, kind = 'physical', hits = 3, crit = true, mods = { str = 0.35 } },
        { id = 119, name = 'Wheeling Thrust', skill = 8, jobs = { 'DRG' }, kind = 'physical', hits = 1, mods = { str = 0.50 } },
        { id = 120, name = 'Impulse Drive', skill = 8, jobs = { 'WAR', 'SAM', 'DRG' }, kind = 'physical', hits = 2, mods = { str = 0.75 } },
        { id = 123, name = 'Sonic Thrust', skill = 8, jobs = { 'WAR', 'PLD', 'DRG' }, kind = 'physical', hits = 1, mods = { str = 0.30, dex = 0.30 } },
        { id = 125, name = 'Stardiver', skill = 8, jobs = { 'WAR', 'SAM', 'DRG' }, kind = 'physical', hits = 4, mods = { str = 0.75 } },

        -- Katana
        { id = 140, name = 'Blade: Hi', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 1, crit = true, mods = { agi = 0.60 } },
        { id = 138, name = 'Blade: Kamu', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 1, mods = { str = 0.80, int = 0.80 } },
        { id = 137, name = 'Blade: Metsu', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 1, mods = { dex = 0.85 } },
        { id = 128, name = 'Blade: Rin', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 1, crit = true, mods = { str = 0.20, dex = 0.20 } },
        { id = 129, name = 'Blade: Retsu', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 2, mods = { str = 0.20, dex = 0.20 } },
        { id = 130, name = 'Blade: Teki', skill = 9, jobs = { 'NIN' }, kind = 'hybrid', hits = 1, mods = { str = 0.20, int = 0.20 } },
        { id = 131, name = 'Blade: To', skill = 9, jobs = { 'NIN' }, kind = 'hybrid', hits = 1, mods = { str = 0.30, int = 0.30 } },
        { id = 132, name = 'Blade: Chi', skill = 9, jobs = { 'NIN' }, kind = 'hybrid', hits = 2, mods = { str = 0.20, int = 0.20 } },
        { id = 133, name = 'Blade: Ei', skill = 9, jobs = { 'NIN' }, kind = 'magical', hits = 1, mods = { str = 0.30, int = 0.30 } },
        { id = 134, name = 'Blade: Jin', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 3, crit = true, mods = { str = 0.50, dex = 0.50 } },
        { id = 135, name = 'Blade: Ten', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 1, mods = { str = 0.50, dex = 0.50 } },
        { id = 136, name = 'Blade: Ku', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 5, mods = { str = 0.50, dex = 0.50 } },
        { id = 139, name = 'Blade: Yu', skill = 9, jobs = { 'NIN' }, kind = 'magical', hits = 1, mods = { dex = 0.60, int = 0.60 } },
        { id = 141, name = 'Blade: Shun', skill = 9, jobs = { 'NIN' }, kind = 'physical', hits = 5, mods = { dex = 0.85 } },

        -- Great Katana
        { id = 156, name = 'Tachi: Fudo', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 1, mods = { str = 0.60 } },
        { id = 153, name = 'Tachi: Kaiten', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 1, mods = { str = 0.80 } },
        { id = 154, name = 'Tachi: Rana', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 3, mods = { str = 0.90 } },
        { id = 158, name = 'Tachi: Suikawari', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 2, mods = { str = 0.60 } },
        { id = 144, name = 'Tachi: Enpi', skill = 10, jobs = { 'SAM', 'NIN' }, kind = 'physical', hits = 2, mods = { str = 0.30 } },
        { id = 145, name = 'Tachi: Hobaku', skill = 10, jobs = { 'SAM', 'NIN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 146, name = 'Tachi: Goten', skill = 10, jobs = { 'SAM', 'NIN' }, kind = 'hybrid', hits = 1, mods = { str = 0.30 } },
        { id = 147, name = 'Tachi: Kagero', skill = 10, jobs = { 'SAM', 'NIN' }, kind = 'hybrid', hits = 1, mods = { str = 0.50 } },
        { id = 148, name = 'Tachi: Jinpu', skill = 10, jobs = { 'SAM', 'NIN' }, kind = 'hybrid', hits = 2, mods = { str = 0.40 } },
        { id = 149, name = 'Tachi: Koki', skill = 10, jobs = { 'SAM', 'NIN' }, kind = 'hybrid', hits = 1, mods = { str = 0.50, mnd = 0.30 } },
        { id = 150, name = 'Tachi: Yukikaze', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 1, mods = { str = 0.75 } },
        { id = 151, name = 'Tachi: Gekko', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 1, mods = { str = 0.95 } },
        { id = 152, name = 'Tachi: Kasha', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 1, mods = { str = 0.85 } },
        { id = 155, name = 'Tachi: Ageha', skill = 10, jobs = { 'SAM', 'NIN' }, kind = 'physical', hits = 1, mods = { str = 0.30, chr = 0.95 } },
        { id = 157, name = 'Tachi: Shoha', skill = 10, jobs = { 'SAM' }, kind = 'physical', hits = 2, mods = { str = 0.75 } },

        -- Club
        { id = 173, name = 'Dagan', skill = 11, jobs = { 'WHM' }, kind = 'physical', hits = 1, mods = {  } },
        { id = 171, name = 'Mystic Boon', skill = 11, jobs = { 'WHM' }, kind = 'physical', hits = 1, mods = { str = 0.95, mnd = 0.95 } },
        { id = 170, name = 'Randgrith', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'SMN', 'BLU', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.85, mnd = 0.85 } },
        { id = 160, name = 'Shining Strike', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'PUP', 'SCH', 'GEO', 'RUN' }, kind = 'magical', hits = 1, mods = { str = 0.20, mnd = 0.20 } },
        { id = 161, name = 'Seraph Strike', skill = 11, jobs = { 'WAR', 'WHM', 'PLD', 'DRK', 'SAM', 'BLU', 'GEO' }, kind = 'magical', hits = 1, mods = { str = 0.30, mnd = 0.30 } },
        { id = 162, name = 'Brainshaker', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'PUP', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 163, name = 'Starlight', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'PUP', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 1, mods = {  } },
        { id = 164, name = 'Moonlight', skill = 11, jobs = { 'WAR', 'WHM', 'PLD', 'DRK', 'SAM', 'BLU', 'SCH', 'GEO' }, kind = 'physical', hits = 1, mods = {  } },
        { id = 165, name = 'Skullbreaker', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'PUP', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 166, name = 'True Strike', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'PUP', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 1, crit = true, mods = { str = 1.00 } },
        { id = 167, name = 'Judgment', skill = 11, jobs = { 'WAR', 'WHM', 'PLD', 'DRK', 'SAM', 'BLU', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 1, mods = { str = 0.32, mnd = 0.32 } },
        { id = 168, name = 'Hexa Strike', skill = 11, jobs = { 'WHM', 'GEO' }, kind = 'physical', hits = 6, crit = true, mods = { str = 0.20, mnd = 0.20 } },
        { id = 169, name = 'Black Halo', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'SMN', 'BLU', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 2, mods = { str = 0.75, mnd = 0.75 } },
        { id = 172, name = 'Flash Nova', skill = 11, jobs = { 'WAR', 'WHM', 'PLD', 'BLU', 'GEO' }, kind = 'magical', hits = 1, mods = { str = 0.50, mnd = 0.50 } },
        { id = 174, name = 'Realmrazer', skill = 11, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'SMN', 'BLU', 'SCH', 'GEO', 'RUN' }, kind = 'physical', hits = 7, mods = { mnd = 0.85 } },

        -- Staff
        { id = 187, name = 'Garland of Bliss', skill = 12, jobs = { 'SMN' }, kind = 'magical', hits = 1, mods = { str = 0.30, mnd = 0.85 } },
        { id = 185, name = 'Gate of Tartarus', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'physical', hits = 1, mods = { chr = 0.90 } },
        { id = 190, name = 'Myrkr', skill = 12, jobs = { 'BLM', 'SMN', 'SCH' }, kind = 'physical', hits = 1, mods = {  } },
        { id = 188, name = 'Omniscience', skill = 12, jobs = { 'SCH' }, kind = 'magical', hits = 1, mods = { mnd = 0.85 } },
        { id = 186, name = 'Vidohunir', skill = 12, jobs = { 'BLM' }, kind = 'magical', hits = 1, mods = { int = 0.85 } },
        { id = 176, name = 'Heavy Swing', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'physical', hits = 1, mods = { str = 0.30 } },
        { id = 177, name = 'Rock Crusher', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'magical', hits = 1, mods = { str = 0.20, int = 0.20 } },
        { id = 178, name = 'Earth Crusher', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'PLD', 'SCH', 'GEO' }, kind = 'magical', hits = 1, mods = { str = 0.30, int = 0.30 } },
        { id = 179, name = 'Starburst', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'magical', hits = 1, mods = { mnd = 0.40, str = 0.40 } },
        { id = 180, name = 'Sunburst', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'PLD', 'SCH', 'GEO' }, kind = 'magical', hits = 1, mods = { str = 0.40, mnd = 0.40 } },
        { id = 181, name = 'Shell Crusher', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'physical', hits = 1, mods = { str = 0.35 } },
        { id = 182, name = 'Full Swing', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'physical', hits = 1, mods = { str = 0.50 } },
        { id = 183, name = 'Spirit Taker', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'physical', hits = 1, mods = { int = 0.50, mnd = 0.50 } },
        { id = 184, name = 'Retribution', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'physical', hits = 1, mods = { str = 0.90, mnd = 0.90 } },
        { id = 189, name = 'Cataclysm', skill = 12, jobs = { 'MNK', 'PLD', 'SMN', 'GEO' }, kind = 'magical', hits = 1, mods = { str = 0.30, mnd = 0.30 } },
        { id = 191, name = 'Shattersoul', skill = 12, jobs = { 'WAR', 'MNK', 'WHM', 'BLM', 'PLD', 'BRD', 'DRG', 'SMN', 'SCH', 'GEO' }, kind = 'physical', hits = 3, mods = { int = 0.95 } },

        -- Archery
        { id = 202, name = 'Jishnu\'s Radiance', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 3, crit = true, mods = { dex = 0.60 } },
        { id = 200, name = 'Namas Arrow', skill = 25, jobs = { 'RNG', 'SAM' }, kind = 'ranged', hits = 1, mods = { str = 0.50, agi = 0.50 } },
        { id = 192, name = 'Flaming Arrow', skill = 25, jobs = { 'RNG' }, kind = 'hybrid', hits = 1, mods = { str = 0.20, agi = 0.25 } },
        { id = 193, name = 'Piercing Arrow', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 1, mods = { str = 0.16, agi = 0.25 } },
        { id = 194, name = 'Dulling Arrow', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 1, crit = true, mods = { str = 0.16, agi = 0.25 } },
        { id = 196, name = 'Sidewinder', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 1, mods = { str = 0.16, agi = 0.25 } },
        { id = 197, name = 'Blast Arrow', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 1, mods = { str = 0.20, agi = 0.35 } },
        { id = 198, name = 'Arching Arrow', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 1, crit = true, mods = { str = 0.20, agi = 0.50 } },
        { id = 199, name = 'Empyreal Arrow', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 1, mods = { str = 0.60, agi = 0.60 } },
        { id = 201, name = 'Refulgent Arrow', skill = 25, jobs = { 'RNG' }, kind = 'ranged', hits = 2, mods = { str = 0.95 } },
        { id = 203, name = 'Apex Arrow', skill = 25, jobs = { 'RNG', 'SAM' }, kind = 'ranged', hits = 1, mods = { agi = 0.95 } },

        -- Marksmanship
        { id = 216, name = 'Coronach', skill = 26, jobs = { 'THF', 'RNG', 'COR' }, kind = 'ranged', hits = 1, mods = { dex = 0.50, agi = 0.50 } },
        { id = 218, name = 'Leaden Salute', skill = 26, jobs = { 'COR' }, kind = 'magical', hits = 1, mods = { agi = 0.95 } },
        { id = 217, name = 'Trueflight', skill = 26, jobs = { 'RNG' }, kind = 'magical', hits = 1, mods = { agi = 0.95 } },
        { id = 220, name = 'Wildfire', skill = 26, jobs = { 'RNG', 'COR' }, kind = 'magical', hits = 1, mods = { agi = 0.60 } },
        { id = 208, name = 'Hot Shot', skill = 26, jobs = { 'RNG', 'COR' }, kind = 'hybrid', hits = 1, mods = { str = 0.20, agi = 0.25 } },
        { id = 209, name = 'Split Shot', skill = 26, jobs = { 'RNG', 'COR' }, kind = 'ranged', hits = 1, mods = { agi = 0.30 } },
        { id = 210, name = 'Sniper Shot', skill = 26, jobs = { 'RNG', 'COR' }, kind = 'ranged', hits = 1, mods = { agi = 0.30 } },
        { id = 212, name = 'Slug Shot', skill = 26, jobs = { 'RNG', 'COR' }, kind = 'ranged', hits = 1, mods = { agi = 0.30 } },
        { id = 213, name = 'Blast Shot', skill = 26, jobs = { 'RNG' }, kind = 'ranged', hits = 1, mods = { agi = 0.55 } },
        { id = 214, name = 'Heavy Shot', skill = 26, jobs = { 'RNG' }, kind = 'ranged', hits = 1, crit = true, mods = { agi = 0.70 } },
        { id = 215, name = 'Detonator', skill = 26, jobs = { 'RNG', 'COR' }, kind = 'ranged', hits = 1, mods = { agi = 0.60 } },
        { id = 219, name = 'Numbing Shot', skill = 26, jobs = { 'RNG', 'COR' }, kind = 'ranged', hits = 1, mods = { agi = 0.80 } },
        { id = 221, name = 'Last Stand', skill = 26, jobs = { 'THF', 'RNG', 'COR' }, kind = 'ranged', hits = 2, mods = { agi = 0.87 } },
    },
};
