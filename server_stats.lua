--[[
    Base stats straight from the CatsEyeXI server database (catseyexi.com/api/item/<id>).
    Used instead of reading the item description, which misses or misreads some stats.
    Latent / conditional stats are not included (same as the description reader).
    Generated file: re-create it instead of editing by hand. Fix single items in data.lua (stat_fix).
]]
return {
    [10754] = { agi = 5, marksmanship = 3, sk_dagger = 3 }, -- Moepapa Ring
    [10755] = { sk_gkatana = 3, sk_gsword = 3, str = 5 }, -- Moepapa Annulet
    [10757] = { mnd = 5, sk_club = 3, sk_sword = 3 }, -- Tjukurrpa Annulet
    [10758] = { archery = 3, sk_polearm = 3, str = 5 }, -- Aifes Ring
    [10774] = { dt = -11, hp = 50 }, -- Defending Ring +1
    [10809] = { def = 1 }, -- Moogle Guard
    [10818] = { da = 1, def = 5, str = 5 }, -- Tjukurrpa Belt
    [10835] = { def = 4, dt = -3, elemental = 8, hp = 30, mbb = 5 }, -- Resonance Sash
    [10932] = { eva = 5, pdt = -2 }, -- Oneiros Torque
    [10940] = { enmity = -5, int = 8, mcritdmg = 5 }, -- Moepapa Pendant
    [10942] = { int = 6, mnd = 6 }, -- Aifes Medal
    [10944] = { acc = 2, da = 2 }, -- Portus Collar
    [10969] = { att = 15, da = 1, def = 12, mnd = 4, str = 4 }, -- Stormlord Shawl +1
    [10972] = { def = 14, vit = 5 }, -- Oneiros Cappa
    [10975] = { def = 17 }, -- Umbral Cape
    [10983] = { acc = 4, agi = 4, def = 7, stp = 2 }, -- Aifes Mantle
    [10984] = { agi = 3, def = 9, enmity = 3, mab = 3 }, -- Tjukurrpa Mantle
    [11001] = { chr = 4, def = 7, fc = 2, hp = -25, mnd = 4 }, -- Swith Cape +1
    [11057] = { acc = 3, eva = -5, racc = 3 }, -- Ghillie Earring +1
    [11283] = { def = 41, hmp = 6, hp = 20, mab = 6, macc = 6, mp = 20 }, -- Oracles Robe
    [11286] = { acc = 13, chr = 7, def = 52, enmity = 3, mdt = -5, mnd = 7, vit = 7 }, -- Avalon Breastplate
    [11291] = { blue = 15, def = 45, dex = 5, hhp = 1, hmp = 1, hp = 17, mp = 17, str = 5 }, -- Magus Jubbah +1
    [11293] = { acc = 12, def = 46, enmity = -3, mp = 20, refresh = 1 }, -- Mirage Jubbah +1
    [11294] = { agi = 5, def = 43, dex = 5, hp = 20, racc = 10, ratt = 5 }, -- Corsairs Frac +1
    [11296] = { acc = 10, def = 46, ratt = 10, str = 3 }, -- Comm. Frac +1
    [11299] = { acc = 12, def = 46, hp = 15, sb = 5 }, -- Pantin Tobe +1
    [11304] = { def = 39, hmp = 5, int = 3, mnd = 3, mp = 18 }, -- Scholars Gown +1
    [11307] = { def = 38, enhancing = 7, hp = 15, mdb = 5, mp = 15, sublimation = 1 }, -- Argute Gown
    [11308] = { def = 39, enhancing = 7, hp = 17, mdb = 6, mp = 17, sublimation = 1 }, -- Argute Gown +1
    [11354] = { acc = 12, def = 49, dex = 10, str = 10, ta = 1, vit = 10 }, -- Nocturnus Mail
    [11364] = { agi = 10, def = 30, eva = 5, zanshin = 1 }, -- Hachiryu Sune-ate
    [11366] = { def = 16, enfeebling = 3, enmity = -3, hmp = 3 }, -- Avocat Pigaches
    [11369] = { def = 14, elemental = 4, hmp = 3 }, -- Numerist Pumps
    [11377] = { def = 13, hmp = 2, hp = 15, mp = 25, wind = 5 }, -- Oracles Pigaches
    [11378] = { agi = 3, att = 4, def = 23, dex = 3, haste = 2, ratt = 4, sb = 2 }, -- Enkidus Leggings
    [11380] = { def = 18, enmity = 4, eva = 6, hp = 14, move = 19 }, -- Hermes Sandals +1
    [11381] = { acc = 3, def = 14, enmity = -5, hp = 18, mp = 18 }, -- Magus Charuqs +1
    [11383] = { agi = 4, att = 5, def = 17, enhdur = 25, enmity = -2, int = 4, mp = 15 }, -- Mirage Charuqs +1
    [11384] = { acc = 4, agi = 5, def = 12, hp = 15, racc = 4, str = 5 }, -- Cor. Bottes +1
    [11386] = { acc = 7, def = 17, dex = 3, enmity = -4, hp = 12, int = 3 }, -- Comm. Bottes +1
    [11387] = { acc = 5, def = 12, eva = 5, hp = 19, str = 5 }, -- Pup. Babouches +1
    [11392] = { def = 14 }, -- Koschei Crackows
    [11395] = { agi = 3, def = 11, enmity = -2, int = 3, mp = 20 }, -- Sch. Loafers +1
    [11396] = { acc = 3, def = 16, dex = 4, hp = 15 }, -- Etoile Shoes
    [11456] = { acc = 4, def = 20, eva = 4, haste = 3, hp = 30, vit = 7 }, -- Ryuga Sune-ate
    [11461] = { cmp = 4, def = 20, enmity = -5, macc = -4, mnd = 7, mp = 20 }, -- Aifes Pumps
    [11464] = { def = 24, int = 5, mnd = 5, mp = 25 }, -- Magus Keffiyeh +1
    [11466] = { blue = 5, def = 25, hp = 15, vit = 4 }, -- Mirage Keffiyeh +1
    [11467] = { agi = 4, def = 23, hp = 13, racc = 9, str = 4 }, -- Cor. Tricorne +1
    [11469] = { def = 25, hp = 12, ratt = 10 }, -- Comm. Tricorne +1
    [11470] = { def = 16, dex = 5, hp = 15, mnd = 5, vit = 5 }, -- Puppetry Taj +1
    [11472] = { agi = 4, def = 20, hp = 12, regen = 1, str = 4 }, -- Pantin Taj +1
    [11477] = { def = 16, enmity = -1, int = 5, mp = 20, sublimation = 1 }, -- Sch. M.Board +1
    [11480] = { def = 16, elemental = 7, hp = 10, mnd = 5, mp = 10 }, -- Argute M.Board
    [11481] = { def = 17, elemental = 7, hp = 12, mnd = 6, mp = 12 }, -- Argute M.Board +1
    [11482] = { chr = 1, def = 1 }, -- Eyepatch
    [11501] = { agi = 6, att = 8, da = 2, def = 24, dex = 6, str = 6 }, -- Nocturnus Helm
    [11508] = { acc = 5, ctp = 5, def = 10, sk_h2h = 5 }, -- Tokon Hachimaki
    [11513] = { acc = 5, ctp = 5, def = 10, sk_gaxe = 5 }, -- Senshin Hachimaki
    [11519] = { acc = 5, ctp = 5, def = 10, sk_staff = 5 }, -- Hakke Hachimaki
    [11523] = { acc = 5, att = 5, def = 25, eva = -12, haste = 4, stp = 3 }, -- Brisk Mask
    [11538] = {  }, -- Nexus Cape
    [11541] = { agi = 3, def = 8, ratt = 15 }, -- Fowlers Mantle +1
    [11543] = { def = 4, mab = 3, macc = 3, mp = 7 }, -- Hecates Cape
    [11544] = { def = 5, fc = 1, mp = 10 }, -- Veela Cape
    [11547] = { def = 5, hp = 20, mdt = -2, mp = 20 }, -- Colossuss Mantle
    [11551] = { def = 11, eva = -15, pdt = -4 }, -- Metallon Mantle
    [11559] = { counter = 2, def = 7 }, -- Ultion Mantle
    [11575] = { def = 7, enhdur = 3, int = 3, mnd = 3 }, -- Grapevine Cape
    [11580] = { cure = 3, enmity = -2, hp = 12 }, -- Fylgja Torque +1
    [11584] = { elemental = 5, int = 5 }, -- Lmg. Medallion +1
    [11585] = { enmity = -3, hp = 20, mp = 20 }, -- Beguiling Collar
    [11586] = { att = 8, counter = 1 }, -- Backlash Torque
    [11587] = { def = 2 }, -- Nyx Gorget
    [11591] = { da = 2, str = 3 }, -- Ravagers Gorget
    [11628] = { att = 3, str = 6 }, -- Strigoi Ring
    [11629] = { acc = 3, dex = 6 }, -- Zilant Ring
    [11630] = { enmity = 2, vit = 6 }, -- Corneus Ring
    [11631] = { agi = 6, racc = 3 }, -- Blobnag Ring
    [11632] = { macc = 1, mnd = 6 }, -- Karka Ring
    [11633] = { int = 6, mab = 1 }, -- Galdr Ring
    [11634] = { chr = 6, enmity = -2 }, -- Veela Ring
    [11643] = { def = 10, enmity = 4 }, -- Odium Ring
    [11644] = { acc = 2, def = 4, hp = 15, racc = 13 }, -- Ydalir Ring
    [11645] = { acc = 5, def = 5, hp = 18, racc = 14 }, -- Ydalir Ring +1
    [11654] = {  }, -- Puffin Ring
    [11655] = {  }, -- Noddy Ring
    [11672] = { dex = 4, scb = 400 }, -- Mujin Band
    [11673] = { att = 5 }, -- Demonry Ring
    [11680] = { pdt = -2, vit = 2 }, -- Soil Earring
    [11683] = { macc = 2, mnd = 2 }, -- Aqua Earring
    [11686] = { att = 3, str = 3 }, -- Vulcans Earring
    [11687] = { acc = 3, dex = 3 }, -- Jupiters Earring
    [11688] = { pdt = -3, vit = 3 }, -- Terras Earring
    [11689] = { agi = 3, racc = 3 }, -- Austers Earring
    [11690] = { int = 3, mbb = 3 }, -- Aquilos Earring
    [11691] = { macc = 3, mnd = 3 }, -- Neptunes Earring
    [11692] = { cure = 3, enmity = -3, hp = 20 }, -- Apollos Earring
    [11693] = { enmity = 3, hmp = 3, mp = 20 }, -- Plutos Earring
    [11738] = { def = 6, songct = 3 }, -- Aoidos Belt
    [11766] = { acc = 7, da = 1, def = 5, mnd = 7, str = 7 }, -- Visionary Obi +1
    [11773] = { def = 8, hp = 45, pdt = -2, str = 3 }, -- Oneiros Belt
    [11811] = { def = 7 }, -- Destrier Beret
    [11819] = { def = 23, enmity = 3, ratt = 10, snapshot = -3, str = 4 }, -- Oneiros Coif
    [11821] = { dark = 9, def = 29, hp = 14, int = 7, str = 7 }, -- Khthonios Helm
    [11919] = { dark = 9, elemental = 9, enfeebling = 9, macc = 6 }, -- Avesta Bangles
    [11923] = { acc = 5, def = 30, enmity = 3, hp = 30, mp = 30, pdt = -3 }, -- Tjukurrpa Gauntlets
    [11924] = { def = 25, dex = 5, haste = 3, mp = 25 }, -- Alucinor Mitts
    [12108] = { agi = 2, def = 33, haste = 3, hp = 20, mp = 10, str = 2, vit = 2 }, -- Pinnacle Celata
    [12112] = { acc = 4, att = 4, def = 31, dex = 2, stp = 2 }, -- Furia Helm
    [12128] = { agi = 3, def = 30, dex = 3, haste = 3, hp = 15, mp = 15 }, -- Apex Hatsuburi
    [12134] = { chr = 2, def = 19, fc = 2, macc = 2 }, -- Ebur Tam
    [12136] = { agi = 2, def = 26, haste = 3, hp = 10, mp = 20, str = 2, vit = 2 }, -- Apogee Petasos
    [12141] = { chr = 1, def = 19, enmity = -1, mp = 8 }, -- Ebon Beret
    [12144] = { chr = 5, def = 53, hp = 35, int = 3, mp = 15, vit = 3 }, -- Pinnacle Cuirass
    [12145] = { att = 6, da = 2, def = 48, dex = 3, str = 4 }, -- Furia Cuirass
    [12158] = { acc = 4, def = 45, dex = 2, eva = 4 }, -- Ebur Harness
    [12164] = { agi = 5, def = 47, eva = 5, hp = 25, mp = 25, str = 2, vit = 4 }, -- Apex Togi
    [12172] = { def = 43, hp = 15, int = 4, meva = 5, mnd = 5, mp = 35, vit = 2 }, -- Apogee Coat
    [12180] = { acc = 5, def = 25, haste = 1, hp = 20, mnd = 3, mp = 10, vit = 5 }, -- Pinnacle Dastanas
    [12200] = { chr = 4, def = 22, haste = 1, hp = 15, int = 4, mp = 15, racc = 8 }, -- Apex Kote
    [12208] = { def = 20, haste = 1, hp = 10, int = 4, macc = 3, mnd = 4, mp = 20 }, -- Apogee Cuffs
    [12216] = { def = 41, dex = 2, hp = 25, mp = 15, str = 4, vit = 2 }, -- Pinnacle Cuisses
    [12218] = { att = 6, da = 1, def = 38, hp = 7, str = 2 }, -- Ebur Cuisses
    [12228] = { acc = 2, agi = 2, def = 33, eva = 3 }, -- Ebon Brais
    [12236] = { agi = 2, def = 38, dex = 4, haste = 1, hp = 20, mnd = 2, mp = 20 }, -- Apex Haidate
    [12244] = { chr = 2, def = 36, haste = 1, hp = 15, int = 4, mp = 25, str = 2 }, -- Apogee Tonban
    [12252] = { chr = 2, def = 23, haste = 1, hp = 20, mp = 10, str = 5 }, -- Pinnacle Sabatons
    [12259] = { def = 22, enmity = 2, hp = 8, mdt = -2, mp = 8 }, -- Furia Sollerets
    [12261] = { acc = 2, att = 2, def = 20, hp = 6 }, -- Ebon Leggings
    [12268] = { agi = 2, def = 17, enmity = -1, racc = 4 }, -- Furia Socks
    [12272] = { def = 23, dex = 4, hp = 15, int = 3, mp = 15 }, -- Apex Sune-ate
    [12280] = { def = 17, dex = 3, hp = 10, mnd = 4, mp = 20 }, -- Apogee Sabots
    [12286] = { def = 19, enmity = -1, mnd = 2, mp = 10 }, -- Furia Clogs
    [12296] = { def = 24, eva = 10, pdt = -10 }, -- Genbus Shield
    [12434] = { def = 35, hp = 50, vit = 15 }, -- Genbus Kabuto
    [12519] = { def = 16, hp = 12, mnd = 5 }, -- Drachen Armet
    [12617] = { agi = 2, def = 43, regen = 1, str = -2, throwing = 10 }, -- War Shinobi Gi
    [12618] = { def = 43, enmity = 4, int = 3, sird = 10 }, -- Yasha Samue
    [12690] = { agi = 15, def = 26, hp = 50, racc = 10 }, -- Seiryus Kote
    [12818] = { def = 42, dex = 15, haste = 5 }, -- Byakkos Haidate
    [12946] = { def = 30, mnd = 15 }, -- Suzakus Sune-ate
    [12997] = { def = 12, enmity = -2, move = 18 }, -- Danzo Sune-ate
    [13079] = { def = 10, mnd = 3, mp = 5, str = -1 }, -- Darksteel Gorget
    [13087] = {  }, -- Jeweled Collar
    [13130] = { agi = 1, dex = 1, int = 1, mnd = 1, str = 1, vit = 1 }, -- Jeweled Collar +1
    [13177] = { def = 4 }, -- Stone Gorget
    [13186] = { def = 7, haste = 12, pdt = -5, sb = 5, str = 7 }, -- Black Belt
    [13212] = { def = 7, mp = 10, sird = 6 }, -- Tarutaru Sash
    [13254] = { def = 4, hp = 30, int = -5, str = 3, vit = 2 }, -- Jungle Belt
    [13281] = { acc = 7, def = -12, racc = 7 }, -- Snipers Ring +1
    [13301] = { def = 2, int = 1, mnd = 1 }, -- Vivian Ring
    [13302] = { def = 2, hp = 50, mp = -10 }, -- Bloodbead Ring
    [13303] = { mdt = 5, pdt = -5 }, -- Jelly Ring
    [13402] = { def = 2, str = 1, vit = 1 }, -- Cassie Earring
    [13406] = { att = 6, eva = -4, mdt = -2 }, -- Mermans Earring
    [13415] = { dex = 3 }, -- Pixie Earring
    [13422] = {  }, -- Sorcerers Earring
    [13460] = { acc = -11, def = 2, hp = 10, racc = 11 }, -- Behemoth Ring
    [13464] = { def = 2, hp = 10, mp = 10 }, -- Demons Ring
    [13504] = { acc = -8, mdt = -4, racc = 10 }, -- Mermans Ring
    [13553] = { haste = 1 }, -- Blitz Ring
    [13573] = { def = 6, enmity = 5, mab = 5 }, -- Searing Cape
    [13620] = { chr = 10, def = 6 }, -- Jesters Cape +1
    [13626] = { def = 7, mp = 20 }, -- Blue Cape +1
    [13627] = { chr = 4, def = 8, hp = 10, int = 4, mnd = 4, mp = 10 }, -- Prism Cape
    [13628] = { def = 5, dt = -3, mp = 8 }, -- Hexerei Cape
    [13651] = { def = 5, pdt = -5 }, -- Cheviot Cape
    [13652] = { def = 6, pdt = -6 }, -- Umbra Cape
    [13656] = { def = 9, enmity = -5, mp = 30 }, -- Errant Cape
    [13658] = { def = 15 }, -- Shadow Mantle
    [13690] = { att = 15, def = 7, str = 3 }, -- Foragers Mantle
    [13695] = { agi = 3, def = 8, dex = 3, str = 3 }, -- Commanders Cape
    [13734] = { acc = 12, def = 41, eva = 12, hp = 20 }, -- Scp. Harness +1
    [13761] = { def = 43, mdt = -4 }, -- Cor. Scale Mail +1
    [13765] = { def = 40, pdt = -4 }, -- Dst. Harness +1
    [13774] = { cure = 12, def = 41, mp = 18, refresh = 1 }, -- Aristocrats Coat
    [13781] = { def = 41, hp = 10, vit = 3 }, -- Myochin Domaru
    [13788] = { def = 46, mdb = 6, refresh = 1 }, -- Dalmatica +1
    [13802] = { def = 39, enmity = 4, pdt = -9 }, -- Arhats Gi +1
    [13859] = { def = 22, mdt = -2 }, -- Coral Visor +1
    [13863] = { def = 22, pdt = -2 }, -- Darksteel Cap +1
    [13877] = { def = 31, int = 4, mnd = 4 }, -- Zenith Crown +1
    [13909] = { def = 35, enfeebling = 11, hp = 22, mp = 22, regen = 1 }, -- Blood Mask
    [13915] = { acc = 10, eva = 10, racc = 10 }, -- Optical Hat
    [13928] = { def = 34, dex = 6, haste = -11, hp = 14, str = 12 }, -- Hecatomb Cap +1
    [13934] = { acc = 5, def = 20, hp = -25, str = 5 }, -- Shr.Znr.Kabuto
    [13935] = { acc = 6, def = 21, hp = -30, str = 6 }, -- Shr.Znr.Kabuto +1
    [13937] = { agi = 5, bdt = -6, def = 25, enmity = 2, sb = 4 }, -- Dragon Cap +1
    [13965] = { def = 16, dex = 4, mp = 12 }, -- Warlocks Gloves
    [13988] = { def = 13, mdt = -2 }, -- Mermans Bangles
    [13994] = { def = 15, pdt = -2 }, -- Dst. Mittens +1
    [14007] = { def = 24, mab = 6 }, -- Zenith Mitts +1
    [14059] = { dark = 11, def = 27, hp = 22, mp = 22, racc = 11, ratt = 11 }, -- Blood Fng. Gnt.
    [14077] = { def = 26, dex = 5, haste = -7, hp = 10, str = 8 }, -- Hct. Mittens +1
    [14085] = { def = 11, hp = 10, mp = 10 }, -- Serpentes Sabots
    [14094] = { def = 13, dex = 3, hp = 12 }, -- Rogues Poulaines
    [14110] = { def = 13, pdt = -2 }, -- Dst. Leggings +1
    [14123] = { chr = 2, def = 20, int = 2 }, -- Zenith Pumps
    [14124] = { chr = 3, def = 21, int = 3 }, -- Zenith Pumps +1
    [14161] = { agi = 4, def = 25, dex = 4, hp = 17, mp = 17 }, -- Blood Greaves
    [14162] = { acc = 3, da = 2, def = 15, haste = -4, str = 4 }, -- Agronas Leggings
    [14163] = { chr = 11, def = 26, dex = -6, hp = 22, str = -6, vit = 11 }, -- Kaiser Schuhs
    [14166] = { agi = 1, def = 11, hp = 10 }, -- Desert Boots
    [14181] = { def = 23, dex = 4, haste = -6, hp = 9, str = 7 }, -- Hct. Leggings +1
    [14188] = { att = 5, def = 24, haste = 3, hp = 27 }, -- Dusk Ledelsens +1
    [14200] = { agi = 6, def = 9, int = 3, mp = 30, str = -3 }, -- Wood M Ledelsens
    [14216] = { def = 28, divine = 15, enmity = -1, mp = 15, vit = 3 }, -- Healers Pantaln.
    [14227] = { def = 27, hp = 15 }, -- Drachen Brais
    [14230] = { def = 31, mdt = -3 }, -- Coral Cuisses +1
    [14234] = { def = 29, pdt = -3 }, -- Dst. Subligar +1
    [14248] = { chr = 5, def = 41, eva = -4, mnd = 5 }, -- Zenith Slacks +1
    [14280] = { def = 43, hp = 25, move = 12, mp = 25 }, -- Crimson Cuisses
    [14281] = { def = 44, hp = 27, move = 18, mp = 27 }, -- Blood Cuisses
    [14283] = { chr = 11, def = 46, dex = -6, eva = 11, hp = 42, str = -6, vit = 11 }, -- Kaiser Diechlings
    [14301] = { agi = -5, chr = 7, def = 38, dex = -5, enmity = -3, int = 7, mnd = 7, str = -5, vit = -5 }, -- Errant Slops
    [14302] = { agi = -6, chr = 8, def = 39, dex = -6, enmity = -4, int = 8, mnd = 8, str = -6, vit = -6 }, -- Mahatma Slops
    [14303] = { acc = 7, def = 30, hp = -35, str = 5 }, -- Shura Haidate
    [14309] = { att = 22, def = 43, dex = 9, haste = -14, hp = 17 }, -- Hct. Subligar +1
    [14317] = { att = 6, def = 32, enmity = 1, str = 2 }, -- Barone Cosciales
    [14367] = { bdt = -10, def = 52, hp = 40, int = 10, mnd = 10, mp = 40 }, -- Crm. Scale Mail
    [14368] = { bdt = -11, def = 53, hp = 42, int = 11, mnd = 11, mp = 42 }, -- Blood Scale Mail
    [14370] = { chr = 21, def = 66, dex = -11, hp = 62, str = -11, vit = 21 }, -- Kaiser Cuirass
    [14376] = { att = 2, def = 50 }, -- Rasetsu Samue
    [14379] = { acc = 11, def = 51, haste = -15, hp = 18, str = 13 }, -- Hct. Harness +1
    [14381] = { agi = -8, chr = 11, def = 43, dex = -8, enmity = -4, hmp = 6, int = 11, mnd = 11, str = -8, vit = -8 }, -- Mahatma Hpl.
    [14382] = { att = 16, def = 40, dt = 14, refresh = 1, str = 8 }, -- Plastron
    [14390] = { agi = 7, att = 12, bdt = -12, def = 45, dex = 7, sb = 12 }, -- Dragon Harness +1
    [14399] = { def = 2 }, -- Culinarians Apron
    [14403] = { def = 32, haste = 4, racc = 2 }, -- Rapparee Harness
    [14408] = { dark = 3, def = 27, elemental = 3, enfeebling = 3, enhancing = 3 }, -- Glamor Jupon
    [14415] = { chr = 8, def = 43, haste = 3, mp = 16, songct = 13 }, -- Sheikh Manteel
    [14417] = { att = 14, def = 46, enmity = 3, regen = 2 }, -- Conte Corazza
    [14421] = { cmp = 2, def = 36, elemental = 6, mab = 7 }, -- Genie Weskit
    [14436] = { def = 41, enmity = -5, mnd = 5 }, -- Blessed Bliaut
    [14439] = { def = 48, stp = 7, str = 9, wsacc = 10 }, -- Hmn. Domaru +1
    [14441] = { acc = 6, def = 44, enmity = -3, macc = 6, mp = 25 }, -- Chasuble +1
    [14474] = { acc = 5, def = 44, hp = 20, str = 6, vit = 6 }, -- Tpl. Cyclas +1
    [14475] = { def = 40, enfeebling = 12, enmity = -4, hmp = 5, mp = 35 }, -- Hlr. Bliaut +1
    [14477] = { def = 44, enfeebling = 15, hmp = 5, mp = 34, sird = 12 }, -- Wlk. Tabard +1
    [14482] = { chr = 10, def = 45, enmity = -3, hp = 20, string = 6, vit = 10 }, -- Chl. Jstcorps +1
    [14483] = { agi = 4, def = 45, hp = 20, racc = 10, vit = 4 }, -- Htr. Jerkin +1
    [14485] = { def = 46, dex = 5, dw = 5, hp = 15, vit = 5 }, -- Nin. Chainmail +1
    [14486] = { att = 7, def = 49, hp = 15, str = 6, vit = 6 }, -- Drn. Mail +1
    [14488] = { acc = 15, def = 49, hp = 28, mp = 28, ta = 1 }, -- Homam Corazza
    [14489] = { dark = 5, def = 41, haste = 3, healing = 5, macc = 5 }, -- Nashira Manteel
    [14501] = { def = 45, hhp = 6, regen = 1, vit = 6 }, -- Mel. Cyclas +1
    [14502] = { def = 43, enmity = -3, mp = 29, refresh = 1 }, -- Clr. Bliaut +1
    [14506] = { def = 56, dex = 3, enmity = 5, hp = 30 }, -- Vlr. Surcoat +1
    [14509] = { att = 20, def = 46, hp = 19 }, -- Brd. Jstcorps +1
    [14510] = { def = 46, dex = 5, enmity = -4, hp = 23, rapid = 5 }, -- Sct. Jerkin +1
    [14514] = { bpdelay = 4, def = 39, mp = 20 }, -- Smn. Doublet +1
    [14515] = { acc = 10, def = 43, enmity = -9, eva = 10, mp = 40 }, -- Hydra Doublet
    [14527] = { def = 40, eva = 7, hmp = 5, mab = 5, songct = 10 }, -- Yigit Gomlek
    [14530] = { acc = 10, crit = 1, def = 42, hhp = 2, hp = 20, racc = 10 }, -- Pln. Khazagand
    [14538] = { acc = 10, agi = 4, def = 50, dex = 4, eva = 10, mdt = -4, pdt = -4 }, -- Hydra Mail +1
    [14540] = { def = 43, eva = 9, mdt = -3, racc = 9, ratt = 9 }, -- Kyudogi +1
    [14546] = { att = 24, def = 55, refresh = 1, str = 12, vit = 12 }, -- Ares Cuirass
    [14550] = { acc = 10, agi = 8, att = 5, chr = 8, def = 40, dex = 8, eva = -10, racc = 10, ratt = 5 }, -- Skadis Cuirie
    [14554] = { acc = 12, def = 40, dex = 8, eva = 12, int = 8, stp = 6, str = 8 }, -- Usukane Haramaki
    [14558] = { chr = 12, def = 40, fc = 5, mnd = 12, refresh = 1 }, -- Marduks Jubbah
    [14562] = { acc = 5, att = 5, def = 38, int = 8, mab = 5, mnd = 8, refresh = 1, str = 8 }, -- Morrigans Robe
    [14568] = { att = 12, da = 2, def = 49, eva = 12, stp = 5, str = 5 }, -- Askar Korazin
    [14570] = { cmp = 5, def = 42, enmity = -5, haste = 4, hp = 42, mp = 42 }, -- Goliard Saio
    [14574] = { acc = 6, agi = -4, att = 26, chr = -4, def = 56, dex = -4, int = -4, mnd = -4, regen = 2, str = 11, vit = 11 }, -- Valk. Breastplate
    [14575] = { def = 38, enmity = -4, macc = 10, mdt = -3, pdt = 6 }, -- Shadow Coat
    [14580] = { def = 38, int = 1, mnd = 1, mp = 13 }, -- Scholars Gown
    [14632] = { def = 3, dex = -2, mnd = 5, str = 2 }, -- Aqua Ring
    [14642] = { agi = -1, chr = 5, def = 3, dex = -1, hp = 20, int = -1, mnd = -1, mp = -20, str = -1, vit = -1 }, -- Light Ring
    [14644] = { agi = 1, chr = 1, def = 3, dex = 1, hp = -20, int = 1, mnd = 1, mp = 20, str = 1, vit = 1 }, -- Dark Ring
    [14646] = {  }, -- Shadow Ring
    [14669] = { acc = 4, racc = 4 }, -- Jaeger Ring
    [14718] = { def = 1, enmity = 2, mp = 12 }, -- Hades Earring +1
    [14723] = { hp = 25 }, -- Pigeon Earring +1
    [14724] = { mab = 5 }, -- Moldavite Earring
    [14739] = { agi = 2, dw = 5, sk_sword = 5 }, -- Suppanomimi
    [14740] = { divine = 5, vit = 2 }, -- Knights Earring
    [14741] = { dark = 5, int = 2, sk_scythe = 5 }, -- Abyssal Earring
    [14743] = { sk_gkatana = 5, str = 2 }, -- Bushinomimi
    [14771] = { divine = 3 }, -- Divine Earring
    [14772] = { dark = 3 }, -- Dark Earring
    [14773] = { enhancing = 3 }, -- Augment. Earring
    [14774] = { enfeebling = 3 }, -- Enfeebling Earring
    [14780] = { string = 3 }, -- String Earring
    [14781] = { wind = 3 }, -- Wind Earring
    [14808] = { mab = 7 }, -- Novio Earring
    [14809] = { enmity = -7, eva = 7 }, -- Novia Earring
    [14812] = { fc = 2, mp = 30 }, -- Loquac. Earring
    [14813] = { da = 5, stp = 1 }, -- Brutal Earring
    [14825] = { att = 6, def = 25, haste = 4, hp = 22 }, -- Dusk Gloves +1
    [14829] = { att = 4, def = 20, mdt = -4, vit = 3 }, -- Gavial Fng.Gnt. +1
    [14839] = { agi = -5, def = 11, hp = 60, mnd = 1, vit = 6 }, -- River Gauntlets
    [14847] = { chr = 6, def = 20, mp = 14, songrecast = 4 }, -- Sheikh Gages
    [14853] = { def = 12, elemental = 6, mab = 3 }, -- Genie Manillas
    [14877] = { def = 19, enmity = -4, haste = 6, mnd = 8, mp = 18 }, -- Blessed Mitts +1
    [14878] = { def = 20, stp = 9, str = 5 }, -- Hachiman Kote +1
    [14881] = { acc = 4, def = 17, enmity = -3, mnd = 5, racc = 3 }, -- Wise Gloves +1
    [14888] = { chr = 6, cure = 3, def = 15, enhancing = 4, healing = 4, mnd = 6 }, -- Augurs Gloves
    [14891] = { boost = 55, def = 15, hp = 14, sb = 4, str = 6 }, -- Tpl. Gloves +1
    [14892] = { def = 14, enmity = -4, healing = 15, mnd = 7, mp = 15, str = 7 }, -- Hlr. Mitts +1
    [14899] = { chr = 7, def = 18, enmity = -1, hp = 14, singing = 10, vit = 7 }, -- Chl. Cuffs +1
    [14901] = { def = 21, dex = 7, enmity = 2, hp = 15, str = 7 }, -- Myn. Kote +1
    [14905] = { acc = 4, def = 20, enmity = 3, haste = 3, hp = 20, mp = 20 }, -- Homam Manopolas
    [14910] = { att = 18, def = 16, sb = 5 }, -- Mel. Gloves +1
    [14913] = { def = 18, enhancing = 15, int = 5, mdb = 2, mp = 23 }, -- Dls. Gloves +1
    [14918] = { def = 19, enmity = -4, eva = 5, hp = 16, wind = 5 }, -- Brd. Cuffs +1
    [14920] = { att = 12, def = 22, enmity = 1, hp = 20, meditate = 4 }, -- Sao. Kote +1
    [14923] = { bpdelay = 2, def = 16, mp = 30, summoning = 12 }, -- Smn. Bracers +1
    [14935] = { def = 17, eva = 4, int = 5, mab = 2, mnd = 5 }, -- Yigit Gages
    [14961] = { acc = 10, def = 20, str = 4, vit = 4 }, -- Ares Gauntlets
    [14969] = { acc = 10, counter = 2, def = 20, eva = 10, sb = 5 }, -- Usukane Gote
    [14973] = { chr = 6, def = 20, enmity = -4, mnd = 6, regen = 1 }, -- Marduks Dastanas
    [14977] = { acc = 5, att = 5, def = 21, mab = 5, macc = 5, mp = 25 }, -- Morrigans Cuffs
    [14984] = { att = 6, def = 17, dt = -2, eva = 6, mnd = 4, str = 4 }, -- Denali Wristbands
    [15009] = { def = 22, enmity = 4, hp = 20, mdb = 2 }, -- I.R. Dastanas
    [15015] = { acc = 5, def = 26, dex = 10, zanshin = 1 }, -- Hachiryu Kote
    [15019] = { def = 14, hp = 10, mp = 10 }, -- Serpentes Cuffs
    [15022] = { def = 18, enfeebling = 5, hmp = 2, hp = 15, mp = 25 }, -- Oracles Gloves
    [15026] = { def = 18, dex = 6, eva = 5, hp = 12, mnd = 6, mp = 12 }, -- Mrg. Bazubands +1
    [15027] = { def = 12, dex = 5, eva = 3, hp = 15, mnd = 5 }, -- Corsairs Gants +1
    [15029] = { agi = 3, def = 15, hp = 15, racc = 5, snapshot = 5 }, -- Comm. Gants +1
    [15030] = { agi = 5, def = 13, hp = 18, str = 5 }, -- Pup. Dastanas +1
    [15032] = { chr = 3, def = 19, dex = 3, haste = 3, hp = 25 }, -- Pantin Dastanas +1
    [15037] = { def = 14, enmity = -3, mnd = 5, mp = 20, sird = 20 }, -- Sch. Bracers +1
    [15040] = { def = 14, enfeebling = 7, enmity = -2, int = 3, mnd = 3, mp = 20 }, -- Argute Bracers
    [15041] = { def = 15, enfeebling = 7, enmity = -3, int = 4, mnd = 4, mp = 20 }, -- Argute Bracers +1
    [15042] = { def = 12, enmity = 2, str = 3 }, -- Gothic Gauntlets
    [15057] = { chr = 5, def = 18, enmity = -2, macc = 5, mnd = 5 }, -- Brictas Cuffs
    [15070] = { def = 40, mdt = -25 }, -- Aegis
    [15075] = { def = 23, elemental = 10, enfeebling = 5, enmity = -2, mp = 23 }, -- Sorcerers Petas.
    [15084] = { def = 22, hp = 20 }, -- Koga Hatsuburi
    [15085] = { def = 25, hp = 16, str = 4 }, -- Wyrm Armet
    [15087] = { att = 10, def = 50, enmity = 4, hp = 10 }, -- Warriors Lorica
    [15091] = { agi = 4, def = 45, fc = 10, healing = 10, mp = 24 }, -- Duelists Tabard
    [15092] = { agi = 4, crit = 1, def = 45, enmity = 3, hp = 22 }, -- Assassins Vest
    [15094] = { acc = 10, def = 49, hp = 20, mab = 10, mnd = 4 }, -- Abyss Cuirass
    [15099] = { acc = 12, att = 16, def = 46, racc = 8, ratt = 8 }, -- Koga Chainmail
    [15104] = { def = 16, enfeebling = 15, enmity = -3, mp = 20 }, -- Clerics Mitts
    [15107] = { chr = 5, def = 16, enmity = 3, hp = 7, th = 1 }, -- Assassins Armlets
    [15111] = { def = 18, enmity = -3, eva = 5, hp = 16, wind = 3 }, -- Bards Cuffs
    [15114] = { def = 18 }, -- Koga Tekko
    [15115] = { acc = 5, agi = 3, def = 19, hp = 16 }, -- Wyrm Fng.Gnt.
    [15137] = { chr = 5, def = 15, enmity = 2, hp = 15, ta = 1 }, -- Assassins Pouln.
    [15139] = { def = 17, enfeebling = 5, mp = 12 }, -- Abyss Sollerets
    [15140] = { def = 14, hp = 13, vit = 4 }, -- Monster Gaiters
    [15184] = { dex = 4, str = 3 }, -- Voyager Sallet
    [15185] = { att = 6, def = 11, hp = 15 }, -- Walkure Mask
    [15194] = { agi = 7, chr = 7, dex = 7, int = 7, mnd = 7, str = 7, vit = 7 }, -- Maats Cap
    [15198] = {  }, -- Sprout Beret
    [15223] = { acc = 7, def = 28, eva = -7, haste = 4, str = 4 }, -- Aces Helm
    [15226] = { def = 23, hhp = 1, hp = 16, mnd = 8 }, -- Tpl. Crown +1
    [15227] = { def = 21, enmity = -1, hmp = 1, mnd = 7, mp = 28 }, -- Hlr. Cap +1
    [15229] = { def = 24, elemental = 10, fc = 10, int = 5, mp = 25 }, -- Wlk. Chapeau +1
    [15230] = { def = 24, dex = 3, eva = 10, hp = 13, racc = 8 }, -- Rog. Bonnet +1
    [15236] = { def = 25, hp = 13, meditate = 4, mnd = 5, str = 5 }, -- Myn. Kabuto +1
    [15237] = { agi = 8, chr = 8, def = 22, eva = 8, hp = 10, ninjutsu = 5 }, -- Nin. Hatsuburi +1
    [15238] = { def = 25, hp = 12, mnd = 8, vit = 8 }, -- Drn. Armet +1
    [15239] = { def = 15, int = 6, mnd = 6, mp = 25, summoning = 5 }, -- Evk. Horn +1
    [15240] = { acc = 4, def = 26, haste = 3, hp = 22, macc = 4, mp = 22 }, -- Homam Zucchetto
    [15241] = { def = 19, enmity = -5, haste = 2, macc = 5, sird = 10 }, -- Nashira Turban
    [15245] = { def = 29, dex = 6, enmity = 1, warcry = 10 }, -- War. Mask +1
    [15249] = { def = 25, enfeebling = 15, hp = 14, mnd = 3, mp = 14, refresh = 1 }, -- Dls. Chapeau +1
    [15254] = { chr = 6, def = 20, enmity = -4, hp = 13, singing = 5 }, -- Brd. Roundlet +1
    [15255] = { def = 25, enmity = -4, hp = 15, mnd = 5, recycle = 25 }, -- Sct. Beret +1
    [15256] = { acc = 12, def = 26, enmity = 1, hp = 20, racc = 7 }, -- Sao. Kabuto +1
    [15258] = { att = 2, def = 26, hp = 16, str = 5 }, -- Wym. Armet +1
    [15270] = { haste = 5, hp = 30, mp = 30 }, -- Walahra Turban
    [15294] = { def = 6, dex = 5, enmity = 3, str = 5, vit = 5 }, -- Warwolf Belt
    [15295] = { def = 3, hhp = 2, hmp = 2, mp = 48 }, -- Hierarch Belt
    [15302] = { agi = 4, def = 6, eva = 10, hp = -40 }, -- Scouters Rope
    [15323] = { curect = 15, def = 14 }, -- Cure Clogs
    [15331] = { def = 15, enmity = -5, haste = 3, mnd = 4, mp = 20 }, -- Blessed Pumps +1
    [15332] = { def = 18, stp = 6, str = 3, wsacc = 3 }, -- Hmn. Sune-ate +1
    [15339] = { att = 8, def = 13, dt = 8, str = 3 }, -- Black Sollerets
    [15350] = { def = 20, fc = 3, hp = -30, int = 3, mnd = 3, mp = 30 }, -- Rostrum Pumps
    [15356] = { agi = 3, def = 15, int = 3, mnd = 3, mp = 16 }, -- Wlk. Boots +1
    [15357] = { def = 15, dex = 3, racc = 5 }, -- Rog. Poulaines +1
    [15363] = { att = 8, def = 18, enmity = 5, hp = 20, zanshin = 1 }, -- Myn. Sune-ate +1
    [15392] = { def = 36, stp = 3, wsacc = 6 }, -- Hachiman Hakama
    [15393] = { def = 33, enmity = -6, haste = 4, mnd = 7, mp = 30 }, -- Bls. Trousers +1
    [15394] = { def = 37, stp = 4, wsacc = 7 }, -- Hmn. Hakama +1
    [15397] = { acc = 2, def = 33, enmity = -5, macc = 3, mp = 20 }, -- Wise Braconi +1
    [15400] = { att = 14, def = 29, dt = 13, str = 4 }, -- Black Cuisses
    [15457] = { acc = 3, att = -5, haste = 4 }, -- Swift Belt
    [15458] = { att = 6, def = 6, haste = 6, sb = 6, sird = 6 }, -- Ninurtas Sash
    [15470] = { def = 2, macc = 1, mdb = 2 }, -- Gramary Cape
    [15471] = { dark = 5, elemental = 5, enhancing = 5, mp = 25 }, -- Merciful Cape
    [15472] = { divine = 5, enfeebling = 5, healing = 5, mp = 25 }, -- Altruistic Cape
    [15473] = { mp = 25, ninjutsu = 5, singing = 5, summoning = 5 }, -- Astute Cape
    [15476] = { att = -10, def = 7, racc = 20, ratt = -10 }, -- Jaeger Mantle
    [15478] = { def = 8, hhp = 5, mnd = 5, vit = 5 }, -- Melee Cape
    [15480] = { agi = 4, def = 7, dex = 4, enmity = 5 }, -- Assassins Cape
    [15481] = { def = 16, enmity = 3, hp = 40, vit = 6 }, -- Valor Cape
    [15482] = { acc = 7, chr = 7, def = 6, eva = 7 }, -- Bards Cape
    [15494] = { def = 5, eva = 3, hmp = 1 }, -- Invigorating Cape
    [15508] = { sk_gkatana = 7, sk_scythe = 7, str = 5 }, -- Justice Torque
    [15509] = { agi = 5, archery = 7, sk_katana = 7 }, -- Hope Torque
    [15510] = { int = 5, sk_club = 7, sk_gsword = 7 }, -- Prudence Torque
    [15511] = { sk_gaxe = 7, sk_sword = 7, vit = 5 }, -- Fortitude Torque
    [15512] = { marksmanship = 7, mnd = 5, sk_h2h = 7 }, -- Faith Torque
    [15513] = { chr = 5, sk_axe = 7, sk_staff = 7 }, -- Temp. Torque
    [15514] = { dex = 5, sk_dagger = 7, sk_polearm = 7 }, -- Love Torque
    [15515] = { acc = 10, racc = 10 }, -- Peacock Amulet
    [15540] = { att = 7, def = 2, regen = 1 }, -- Orochi Nodowa +1
    [15543] = { dex = 2, sb = 5, stp = 5, str = 2 }, -- Rajas Ring
    [15544] = { agi = 2, enmity = 3, hp = 15, vit = 2 }, -- Sattva Ring
    [15545] = { enmity = -3, int = 2, mnd = 2, mp = 15 }, -- Tamas Ring
    [15548] = { acc = 8, att = 8, def = -8, eva = -8 }, -- Marss Ring
    [15549] = { def = -8, eva = -8, racc = 8, ratt = 8 }, -- Bellonas Ring
    [15550] = { mdt = -8, pdt = 8 }, -- Minervas Ring
    [15562] = { counter = 3, def = 31, hp = 18, mnd = 4 }, -- Tpl. Hose +1
    [15565] = { def = 33, enhancing = 15, healing = 10, mnd = 5, mp = 18 }, -- Wlk. Tights +1
    [15566] = { agi = 4, def = 34, dex = 2, hp = 15 }, -- Rog. Culottes +1
    [15570] = { def = 31, dex = 8, enmity = -2, hp = 12, str = 8, wind = 8 }, -- Chl. Cannions +1
    [15571] = { agi = 5, def = 32, enmity = -3, hp = 15, mnd = 5 }, -- Htr. Braccae +1
    [15572] = { def = 40, hp = 15, stp = 4, str = 5, vit = 5 }, -- Myn. Haidate +1
    [15574] = { acc = 9, def = 32, hp = 15 }, -- Drn. Brais +1
    [15576] = { acc = 3, def = 35, fc = 5, haste = 3, hp = 26, mp = 26 }, -- Homam Cosciales
    [15577] = { def = 30, divine = 5, enfeebling = 5, haste = 2, macc = 3 }, -- Nashira Seraweels
    [15580] = { da = 1, def = 40, enmity = 4, str = 6 }, -- War. Cuisses +1
    [15581] = { agi = 5, def = 32, kick = 5, sb = 6 }, -- Mel. Hose +1
    [15582] = { def = 32, enmity = -3, healing = 15, mp = 17 }, -- Clr. Pantaln. +1
    [15583] = { def = 31, enmity = -3, int = 3, mp = 20 }, -- Src. Tonban +1
    [15585] = { def = 35, enmity = 5, hp = 25 }, -- Asn. Culottes +1
    [15589] = { def = 32, hp = 26, mp = 42 }, -- Brd. Cannions +1
    [15590] = { def = 33, enmity = -3, hp = 18, racc = 9 }, -- Sct. Braccae +1
    [15591] = { agi = 4, def = 41, enmity = 1, hp = 33 }, -- Sao. Haidate +1
    [15593] = { def = 33, dex = 6, hp = 13 }, -- Wym. Brais +1
    [15595] = { acc = 10, def = 32, enmity = -6, eva = 10, hmp = 1 }, -- Hydra Brais
    [15603] = { agi = 3, def = 24, hp = 22, str = 2 }, -- Sipahi Zerehs
    [15606] = { def = 30, eva = 6, hmp = 2, hp = 25, mp = 25 }, -- Yigit Seraweels
    [15617] = { def = 36, haste = 3, str = 4, vit = 4 }, -- Barb. Zerehs
    [15619] = { acc = 4, def = 40, hp = 30, mnd = 3, mp = 30 }, -- Princes Slops
    [15625] = { da = 2, def = 35, dex = 6, int = -3, mnd = -3, str = 6 }, -- Ares Flanchard
    [15629] = { acc = 4, att = 5, def = 28, haste = 2, racc = 4, ratt = 5, stp = 7 }, -- Skadis Chausses
    [15633] = { att = 10, def = 30, dex = 5, haste = 3, str = 5 }, -- Usukane Hizayoroi
    [15637] = { chr = 10, def = 32, enmity = -4, healing = 5, summoning = 5, wind = 5 }, -- Marduks Shalwar
    [15641] = { def = 27, enmity = -2, int = 10, mnd = 10, mp = 25, str = 3 }, -- Morrigans Slops
    [15649] = { def = 35, enmity = -4, mp = 28, pdt = -3 }, -- Goliard Trews
    [15656] = { acc = 6, att = 10, def = 41, hp = 27, int = 5, mnd = 5, mp = 27 }, -- Valkyries Cuishes
    [15658] = { def = 29, dt = 5, enmity = -3, mab = 5, macc = 5 }, -- Valkyries Trews
    [15661] = { acc = 6, def = 16, haste = 3, hp = 31, mp = 31, racc = 6 }, -- Homam Gambieras
    [15666] = { def = 16, dex = 5 }, -- Mel. Gaiters +1
    [15667] = { def = 16, enhancing = 10, enmity = -2, mnd = 6, mp = 18 }, -- Clr. Duckbills +1
    [15668] = { cmp = 5, def = 15, enmity = -2, int = 3, mp = 18 }, -- Src. Sabots +1
    [15669] = { def = 16, mab = 5, mnd = 5, mp = 15 }, -- Dls. Boots +1
    [15675] = { def = 17, enmity = -4, hp = 12, ratt = 12, vit = 5 }, -- Sct. Socks +1
    [15705] = { def = 14, hp = 22, mdb = 4, mp = 22 }, -- Ataractic Solea
    [15711] = { acc = 7, agi = 3, att = 7, def = 20, eva = -7, vit = 3 }, -- Ares Sollerets
    [15715] = { acc = 5, def = 16, eva = -5, move = 19, racc = 5, str = 3, vit = 3 }, -- Skadis Jambeaux
    [15719] = { acc = 7, att = 7, def = 22, enmity = 5, haste = 2, stp = 7 }, -- Usukane Sune-ate
    [15723] = { def = 20, enfeebling = 5, enmity = -4, mnd = 10, string = 5, summoning = 5 }, -- Marduks Crackows
    [15727] = { def = 18, enmity = -2, int = 3, mnd = 10, mp = 20, str = 3 }, -- Morrigans Pgch.
    [15733] = { agi = 3, def = 17, dt = -2, enmity = 2, mp = 30, str = 3 }, -- Askar Gambieras
    [15735] = { chr = 4, def = 19, dex = 4, eva = 5, hmp = 3, int = 4, macc = 2, mnd = 4 }, -- Goliard Clogs
    [15741] = { acc = 2, agi = 5, att = 9, def = 21, hp = 17, mp = 17 }, -- Valk. Sabatons
    [15742] = { chr = 5, def = 11, enmity = -2, macc = 2, mnd = 5, pdt = 1 }, -- Shadow Clogs
    [15743] = { chr = 6, def = 12, enmity = -3, macc = 3, mnd = 6, pdt = 2 }, -- Valkyries Clogs
    [15758] = { cmp = 3, def = 10, hp = 22, mab = 3, mp = 22 }, -- Cobra Crackows
    [15762] = {  }, -- Empress Band
    [15799] = { acc = 3, agi = 3, dex = 3, vit = 3 }, -- Iota Ring
    [15800] = { chr = 3, int = 3, macc = 3, mnd = 3 }, -- Omega Ring
    [15805] = { hmp = 1, mnd = 4, mp = 20 }, -- Star Ring
    [15806] = { hmp = 1, mnd = 5, mp = 20 }, -- Celestial Ring
    [15807] = { macc = 4 }, -- Balrahns Ring
    [15810] = {  }, -- Luzafs Ring
    [15814] = { wind = 3 }, -- Nereid Ring
    [15831] = {  }, -- Fenian Ring
    [15839] = { blue = 2, ninjutsu = 2 }, -- Antica Ring
    [15859] = { dt = -3, mp = 30 }, -- Succor Ring
    [15872] = { def = 4, hmp = 3, mnd = 6, mp = 40 }, -- Clerics Belt
    [15873] = { def = 4, hhp = 4, hmp = 4, int = 4, mnd = 4 }, -- Duelists Belt
    [15876] = { agi = 5, def = 4, racc = 7, ratt = 7 }, -- Scouts Belt
    [15879] = { acc = 7, def = 4, dex = 5, racc = 7 }, -- Sao. Koshi-ate
    [15884] = { acc = 8, def = 5, str = 3 }, -- Potent Belt
    [15887] = { def = 5, mdb = 2, sird = 8 }, -- Resolute Belt
    [15891] = { chr = 2, def = 4, int = 2, mnd = 2, mp = 15, sird = 6 }, -- Al Zahbi Sash
    [15912] = { bdt = -2, def = 5, hp = 15, mdt = -2, mp = 15 }, -- Lieutenants Sash
    [15917] = { att = 10, def = 6, dex = 6, hp = 15 }, -- Cuchulains Belt
    [15920] = { def = 4, racc = 8, ratt = 5, str = 4 }, -- Commodore Belt
    [15925] = { def = 6, int = 5, macc = 2, mdb = 2, mnd = 5, mp = 20 }, -- Argute Belt
    [15943] = { acc = 12, att = 4 }, -- Virtuoso Belt
    [15950] = { cmp = 5, def = 4, enmity = -4, mnd = 6 }, -- Pythia Sash +1
    [15954] = { att = 15 }, -- Fierce Belt
    [15955] = { acc = 4, def = 7, dex = 4 }, -- Fatality Belt
    [15961] = { eva = 5, string = 5, wind = 5 }, -- Musical Earring
    [15962] = { mbb = 5, mdb = 2, mnd = 2 }, -- Static Earring
    [15963] = { cmp = 5, hmp = 1, mp = 20, sird = 8 }, -- Magnetic Earring
    [15964] = { acc = 3, dex = 2, racc = 3 }, -- Hollow Earring
    [15965] = { att = 5, eva = 5, hp = 15 }, -- Ethereal Earring
    [15971] = { hmp = 1, mp = 15 }, -- Antivenom Earring
    [15990] = { chr = 2, dex = 2, enmity = -3 }, -- Delta Earring
    [15992] = { mnd = 3, mp = 22 }, -- Celestial Earring
    [16002] = { cure = 5, def = 1, waltz = 5 }, -- Roundel Earring
    [16006] = {  }, -- Brilliant Earring
    [16012] = { mnd = 3 }, -- Mamool JA Earring
    [16035] = { racc = 1 }, -- Altdorfs Earring
    [16036] = { ratt = 1 }, -- Wilhelms Earring
    [16053] = { enmity = 1, macc = 3 }, -- Incubus Earring +1
    [16054] = { drain = 3, hp = -5, mp = -5 }, -- Hirudinea Earring
    [16059] = {  }, -- Graiai Earring
    [16064] = { def = 21, enmity = -5, hmp = 1, mab = 2, mnd = 4 }, -- Yigit Turban
    [16084] = { acc = 12, att = 12, def = 28, eva = -12 }, -- Ares Mask
    [16092] = { acc = 7, agi = 3, def = 20, eva = 7, haste = 3, str = 3 }, -- Usukane Somen
    [16096] = { chr = 3, def = 17, divine = 7, enmity = -3, mnd = 3, singing = 7, summoning = 7 }, -- Marduks Tiara
    [16100] = { acc = 5, def = 15, int = 4, macc = 5, mnd = 4, mp = 20, str = 4 }, -- Morrigans Coron.
    [16106] = { def = 23, dex = 4, haste = 4, str = 4, vit = 4 }, -- Askar Zucchetto
    [16107] = { agi = 4, att = 3, def = 21, eva = 3, haste = 4, mnd = 4 }, -- Denali Bonnet
    [16108] = { chr = 5, def = 20, enmity = -4, hmp = 2, hp = 20, mnd = 5, mp = 20 }, -- Goliard Chapeau
    [16115] = { def = 18, enmity = -3, macc = 5, mp = 35, pdt = 3 }, -- Shadow Hat
    [16117] = { def = 40, dt = -5, haste = -5, hp = 30, vit = 4 }, -- Valhalla Helm
    [16128] = { def = 15, hp = -20, mp = 38 }, -- Wivre Hairpin
    [16140] = { def = 15, int = 4, mp = 15, sublimation = 1 }, -- Scholars M.Board
    [16146] = { def = 29, enmity = 5, hp = 20, mdb = 3 }, -- Iron Ram Sallet
    [16156] = { def = 19, elemental = 5, hmp = 2, hp = 15, mp = 25 }, -- Oracles Cap
    [16159] = { def = 23, enmity = -5, racc = 8, ratt = 8, snapshot = 3 }, -- Zhagos Barbut
    [16175] = { chr = 7, def = 15, mnd = 7, sird = 10 }, -- Muse Tariqah
    [16177] = { def = 16, enmity = -2, hmp = 5, mp = 20 }, -- Legion Scutum
    [16214] = { def = 9, mdb = 4, mp = 26 }, -- Lamia Mantle +1
    [16216] = { att = 15, def = 13, enmity = 4, str = 4 }, -- Cerb. Mantle +1
    [16241] = { acc = 5, def = 8, dex = 4, str = 4 }, -- Cuchulains Mantle
    [16244] = { acc = 7, def = 6, macc = 3, mp = 20 }, -- Mirage Mantle
    [16245] = { att = 15, def = 6, dex = 5 }, -- Pantin Cape
    [16246] = { def = 9, hp = 15, mp = 15 }, -- Viator Cape
    [16264] = { def = 5, hmp = 2, mp = 22 }, -- Beak Necklace +1
    [16275] = { acc = 9, dex = 4 }, -- Ancient Torque
    [16297] = {  }, -- Shepherds Chain
    [16302] = { hp = 60 }, -- Bloodbead Gorget
    [16341] = { acc = 7, att = -4, def = 40, eva = -8, str = 4, vit = 4 }, -- Aurum Cuisses
    [16342] = { def = 30, hmp = 2, hp = 15, mp = 25, summoning = 5 }, -- Oracles Braconi
    [16343] = { def = 40, dex = 4, sb = 5, stp = 5, str = 4 }, -- Enkidus Subligar
    [16344] = { acc = 5, agi = 5, def = 35, dex = 5, racc = 5 }, -- Oily Trousers
    [16345] = { agi = 5, def = 34, dex = 5, hp = 25, sird = 12, vit = 5 }, -- Magus Shalwar +1
    [16347] = { acc = 5, def = 32, hp = 15, macc = 5, mp = 15, str = 3 }, -- Mirage Shalwar +1
    [16356] = { att = 4, chr = 8, def = 28, mab = 4 }, -- Nimues Tights
    [16359] = { def = 28, enmity = -2, mnd = 3, mp = 25, vit = 3 }, -- Scholars Pants +1
    [16363] = { dark = 7, def = 28, enmity = -3, hp = 17, int = 6, mp = 17 }, -- Argute Pants +1
    [16368] = { def = 8 }, -- Herders Subligar
    [16376] = { acc = 12, def = 36, eva = -4, haste = -10, str = 5 }, -- Bahram Cuisses
    [16379] = { def = 33, dt = -2, enmity = 3, eva = -10, hp = 25 }, -- Inmicus Cuisses
    [16428] = { crit = 3, kick = 7 }, -- Afflictors
    [16480] = { th = 1 }, -- Thiefs Knife
    [16848] = {  }, -- Darksteel Lance
    [17006] = {  }, -- Drill Calamary
    [17185] = { enmity = -5, rapid = 5, str = 3 }, -- Siege Bow
    [17210] = { tpb = 1000 }, -- Martial Gun
    [17277] = { enmity = -1, mp = 30 }, -- Hedgehog Bomb
    [17325] = { racc = 3 }, -- Kabura Arrow
    [17341] = {  }, -- Silver Bullet
    [17454] = { cure = 5 }, -- Asklepios
    [17552] = { pdt = -20, vit = 5 }, -- Terras Staff
    [17567] = { hp = 20, int = 10, mnd = 10, mp = 20 }, -- Kirins Pole
    [17586] = { mp = 30 }, -- Mercurial Pole
    [17598] = { bloodboon = 5, mp = 30, perp = 3, summoning = 10 }, -- Bahamuts Staff
    [17626] = { dw = 5, sb = 10 }, -- Auric Dagger
    [17659] = { eva = 5 }, -- Seiryus Sword
    [17669] = { hp = 30, mab = 7, mp = 30, str = 8, vit = 8 }, -- Undulant Black
    [17694] = { mnd = 6, str = 1 }, -- Guespiere
    [17763] = {  }, -- Erlkings Blade
    [17771] = { dex = 2, str = -1 }, -- Anju
    [17793] = {  }, -- Senjuinrikio
    [17813] = {  }, -- Soboro Sukehiro
    [17834] = {  }, -- Mythic Harp +1
    [17857] = { dex = 4 }, -- Animator +1
    [17858] = { dex = 2 }, -- Turbo Animator
    [17925] = { racc = 7, ratt = 7 }, -- Fransisca
    [18115] = { acc = 2, stp = 1 }, -- Engetsuto
    [18121] = { da = 3, stp = 3 }, -- Valkyries Fork
    [18139] = { att = 12 }, -- Bomb Core
    [18140] = { int = 2, mp = 10 }, -- Phtm. Tathlum
    [18141] = { eva = 8, hp = 8, mp = 8 }, -- Ungur Boomerang
    [18148] = {  }, -- Acid Bolt
    [18217] = {  }, -- Rampager
    [18235] = { racc = 25 }, -- Corsair Bullet
    [18245] = { macc = 8 }, -- Aureole
    [18259] = {  }, -- Angon
    [18318] = { acc = 20 }, -- Amanomurakumo
    [18336] = { racc = 20, ratt = 10 }, -- Annihilator
    [18342] = { chr = 4, singing = 10, wind = 10 }, -- Gjallarhorn
    [18419] = { str = 2 }, -- Kugui
    [18498] = { pdt = -8, vit = 8 }, -- Balestarius
    [18593] = { chr = 10, hp = -10, int = 10, macc = 20, mnd = 10 }, -- Alkalurops
    [18595] = { acc = -4, att = 12, stp = 5, str = 5 }, -- Mekki Shakki
    [18596] = { mdb = 5 }, -- Kebbie
    [18598] = {  }, -- Prester
    [18603] = {  }, -- Majestas
    [18617] = {  }, -- Cracked Staff
    [18623] = { mdt = -5 }, -- Chtonic Staff
    [18633] = { agi = 5, chr = 5, cure = 10, dex = 5, hmp = 10, int = 5, mnd = 5, str = 5, vit = 5 }, -- Chatoyant Staff
    [18723] = {  }, -- Steel Bullet
    [18724] = {  }, -- Soultrapper 2000
    [18725] = {  }, -- H.S. Soul Plate
    [18816] = { cmp = 1, int = 2 }, -- Wizzan Grip
    [18852] = {  }, -- Octave Club
    [18904] = { acc = 15 }, -- Somnia Melodiam
    [18971] = {  }, -- Conqueror
    [18973] = {  }, -- Yagrush
    [18975] = {  }, -- Murgleis
    [18980] = {  }, -- Carnwenhan
    [18987] = {  }, -- Death Penalty
    [18991] = { berserk = 5 }, -- Conqueror
    [18993] = { macc = 10 }, -- Yagrush
    [18996] = { th = 1 }, -- Vajra
    [18997] = { enmity = 10, pdt = -10 }, -- Burtgang
    [19022] = { hp = 20, str = 3 }, -- Axe Grip
    [19027] = { crit = 3 }, -- Claymore Grip
    [19028] = { mp = 23, sird = 5 }, -- Magic Strap
    [19029] = { critdmg = 3 }, -- Brave Grip
    [19030] = { mcrit = 3 }, -- Wise Strap
    [19037] = {  }, -- Light Grip
    [19048] = { chr = 3, mnd = 3 }, -- Reign Grip
    [19162] = {  }, -- Dull Claymore
    [19213] = { enmity = -2, hp = 15, mp = 15, stp = 2 }, -- White Tathlum
    [19250] = { mab = 2 }, -- Witchstone
    [19282] = { dex = 10, fc = 10 }, -- Hochomasamune
    [19763] = { att = -3, haste = 1 }, -- Oneiros Cluster
    [19764] = { dex = 2 }, -- Demonry Core
    [19767] = { acc = 3, vit = 3 }, -- Oneiros Pebble
    [19780] = { hmp = 1, mnd = 1, mp = 15 }, -- Mana Ampulla
    [19790] = { dt = -5, enmity = 5, hp = 50, vit = 5 }, -- Oneiros Lance
    [20517] = { dex = 9, hp = 25, mp = 25 }, -- Terror Talons
    [20543] = { att = 5, dex = 3, eva = 5, sk_h2h = 3, stp = 3, str = 3 }, -- Maochinoli
    [20618] = { acc = 8, agi = 4, dex = 4, enmity = 4, eva = 5, hp = 15, ta = 1 }, -- Sandung
    [20632] = { acc = 12, agi = 8, racc = 12 }, -- Turbulence
    [20705] = { cure = 15, enmity = 5, mnd = 10 }, -- Brilliance
    [20720] = { acc = 8, enmity = -4, hp = 15, mab = 4, macc = 4, mnd = 4, mp = 15, str = 4 }, -- Egeking
    [20740] = { def = 15, dt = -5, enmity = 5, mnd = 3 }, -- Unbreakable
    [20872] = { sk_gaxe = 3, stp = 5, str = 3, vit = 3 }, -- Ixtab
    [21026] = { chr = 5 }, -- Flamedancer Glaive
    [21047] = { dex = 3, scb = 3, sk_gkatana = 3, str = 3 }, -- Azukinagamitsu
    [21054] = { agi = 12, archery = 15, hp = 20 }, -- Kyugutachi
    [21089] = { agi = 5, archery = 10, stp = 5, str = 5, tpb = 1000 }, -- Kennans Longbow
    [21094] = { acc = 12, int = 8, macc = 12, mnd = 8 }, -- Blurred Rod +1
    [21104] = {  }, -- Kraken Club +1
    [21125] = { cure = 10, int = 3, mab = 5, macc = 2, mnd = 3, sk_club = 3 }, -- Tamaxchi
    [21175] = { cmp = 8, enmity = -4, int = 8, mp = 40 }, -- Coeus
    [21253] = { agi = 3, enmity = -5, mab = 5, macc = 5, marksmanship = 3, mnd = 3, racc = 5 }, -- Atetepeyorg
    [21278] = { agi = 6, enmity = -4, hp = 15, mab = 5, macc = 5, mp = 15, racc = 8, rapid = 5, stp = 5 }, -- Deathlocke
    [21333] = { racc = 5, ratt = 5 }, -- Bismuth Bullet
    [21347] = { enmity = 1, hp = 25, vit = 2 }, -- Charitoni Sling
    [21379] = { crit = 2, critdmg = 3, dex = 2 }, -- Yetshila +1
    [21384] = { macc = 1, mnd = 1, mp = 20 }, -- Rimestone
    [21385] = { enmity = 2, hp = 20, str = 4 }, -- Cinderstone
    [21407] = { enmity = -4, hp = 15, mp = 15, string = 8 }, -- Terpander
    [21519] = { acc = 10, boost = 50, dex = 8, str = 8 }, -- Face Breakers
    [21611] = { acc = 15, mab = 15, mnd = 8, str = 8 }, -- Hepatizon Rapier +1
    [21659] = { acc = 10, int = 8, mp = 25, sk_gsword = 10, str = 8 }, -- Beryllium Sword
    [21815] = { acc = 10, mnd = 10, sk_scythe = 10, stp = 5, str = 10 }, -- Maliya Sickle
    [21915] = { int = 3 }, -- Stormblade
    [21965] = {  }, -- Zanmato
    [22086] = { acc = 10, att = 15, dt = -5, int = 8, mnd = 8, refresh = 1 }, -- Elegys Respite
    [22107] = { agi = 8, racc = 10, rapid = 3, ratt = 10, stp = 8, str = 8 }, -- Tonzoffun
    [22199] = { macc = 3, mp = 25 }, -- Omni Grip
    [22201] = { fc = 3, macc = 4 }, -- Reflexive Grip +1
    [22203] = { mdt = -4, meva = 8, refresh = 1 }, -- Longbeards Grip +1
    [22211] = { int = 2, mab = 4 }, -- Norns Grip +1
    [22280] = { da = 2, str = 4, vit = 6 }, -- Furys Edge
    [22500] = {  }, -- Fjoturangon
    [23992] = { mp = 10 }, -- Spire Earring
    [23993] = { def = 3, hp = 15 }, -- Kiryoku Nenju
    [23998] = { def = 14, mp = 15 }, -- Eminence Robe
    [25585] = { def = 1 }, -- Bl. Chocobo Cap
    [25603] = { def = 35, haste = 5, hp = 25, mab = 9, mp = 15, pdt = -5, vit = 8 }, -- Jumalik Helm
    [25629] = { att = 5, def = 38, haste = 4, hp = 75, pdt = -5, vit = 18 }, -- Genmei Kabuto
    [25630] = { acc = 5, def = 22, dex = 4, haste = 5, hp = 15, mdt = -2, str = 2 }, -- Dampening Tam
    [25631] = { att = 5, def = 28, dex = 5, haste = 4, hp = 25, sk_axe = 5 }, -- Tribal Wreath
    [25702] = { agi = 12, chr = 12, critdmg = 4, da = 4, def = 54, dex = 12, int = 12, mnd = 12, mp = 50, str = 12, vit = 12 }, -- Reiki Osode
    [25776] = { def = 1 }, -- Bl. Chocobo Suit
    [26015] = { agi = 5, archery = 8, chr = 5, dex = 5, int = 5, marksmanship = 8, mnd = 5, sk_axe = 8, sk_club = 8, sk_dagger = 8, sk_gaxe = 8, sk_gkatana = 8, sk_gsword = 8, sk_h2h = 8, sk_katana = 8, sk_polearm = 8, sk_scythe = 8, sk_staff = 8, sk_sword = 8, str = 5, vit = 5 }, -- Combatants Torque
    [26016] = { blue = 8, dark = 8, divine = 8, elemental = 8, enfeebling = 8, enhancing = 8, geomancy = 8, handbell = 8, healing = 8, ninjutsu = 8, singing = 8, string = 8, summoning = 8, wind = 8 }, -- Incanters Torque
    [26161] = { att = 5, dw = 3, meva = 3 }, -- Shukuyu Ring
    [26163] = { acc = 9, att = 9, def = -9, eva = -9 }, -- Aress Ring
    [26173] = { def = 9, eva = -9, racc = 9, ratt = 9 }, -- Enyos Ring
    [26188] = { bpdelay2 = 5, mp = 40, summoning = 10 }, -- Eidolon Ring
    [26219] = { cure = 2, enmity = -1, fc = 1 }, -- Najis Loop
    [26320] = { def = 6, geomancy = 5, mp = 25, singing = 5, summoning = 5 }, -- Kobo Obi
    [26324] = { att = 10, def = 7, dex = 6, enmity = 4, str = 6, vit = 5 }, -- Warwolf Belt +1
    [26421] = { agi = 8, def = 20, enmity = -10, hp = 35, racc = 12, stp = 5 }, -- Archers Shield
    [26490] = { def = 1 }, -- Ark Shield
    [26840] = { def = 43, geomancy = 10, hp = 15, mab = 5, mp = 15 }, -- Bagua Tunic
    [26877] = { acc = 25, agi = 36, chr = 28, crit = 3, def = 133, dex = 37, eva = 49, fc = 5, haste = 4, hp = 59, int = 28, macc = 25, mdb = 6, meva = 64, mnd = 28, mp = 44, racc = 25, str = 29, vit = 29 }, -- Foppish Tunica
    [26972] = { att = 20, cure = 9, def = 58, dex = 8, haste = 1, hp = 35, mp = 25 }, -- Jumalik Mail
    [26973] = { acc = 10, agi = 5, def = 45, dex = 5, eva = 5, haste = 2, hp = 40, mab = 10 }, -- Samnuha Coat
    [27133] = { agi = 18, crit = 4, def = 28, eva = 5, hp = 60, racc = 15, stp = 6 }, -- Kobo Kote
    [27135] = { acc = 6, def = 2 }, -- Slumber Ring
    [27136] = { acc = 8, def = 3 }, -- Somber Shroud
    [27194] = { def = 41, dex = 7, enhdur = 10, fc = 10, hp = 20, mp = 20, vit = 7 }, -- Futhark Trousers
    [27295] = { acc = -5, def = 42, eva = -5, haste = 6, hp = 35, stp = 2, str = 3 }, -- Samnuha Tights
    [27318] = { critdmg = 4, def = 44, dex = 18, haste = 5, stp = 5 }, -- Jokushu Haidate
    [27321] = { acc = 6, def = 2, stp = 2 }, -- Ghost Pendant
    [27323] = { att = 8, counter = 2, def = 40, haste = 3, mp = 38, sb = 4 }, -- Enticers Pants
    [27489] = { def = 32, fc = 5, haste = 3, mdb = 5, mnd = 18 }, -- Shukuyu Sune-ate
    [27493] = { cure = 4, def = 14, handbell = 5, mnd = 8, mp = 20, str = 3 }, -- Mediums Sabots
    [27510] = {  }, -- Fotia Gorget
    [27525] = { divine = 10 }, -- Jokushu Chain
    [27537] = { da = 6, stp = 2 }, -- Brutal Earring +1
    [27539] = { counter = 2, def = 3, pdt = -2 }, -- Genmei Earring
    [27556] = {  }, -- Echad Ring
    [27565] = { att = 3, str = 8 }, -- Ifrit Ring +1
    [27569] = { acc = 3, dex = 8 }, -- Ramuh Ring +1
    [27575] = { int = 8, mab = 3 }, -- Shiva Ring +1
    [27599] = { cure = 3, def = 8, enmity = -3, mnd = 6 }, -- Dew Silk Cape +1
    [27645] = { cure = 8, curect = 8, def = 30, eva = 12, pdt = -12 }, -- Genmei Shield
    [27738] = { def = 28, dex = 11, hp = 30, mp = 22, str = 5 }, -- Assailants Visor
    [27767] = { curect = 5, def = 25, int = 5, macc = 5, mp = 30, vit = 3 }, -- Erudite Cap
    [27779] = { da = 2, def = 36, haste = 4, hp = 25, str = 8 }, -- Conquerors Helm
    [27781] = { def = 20, fc = 3, haste = 6, mp = 25 }, -- Windfall Hat
    [27859] = {  }, -- Kengyu Happi
    [27886] = { acc = 12, def = 52, eva = 12, haste = 4, hp = 30, mnd = 5, mp = 30, stp = 4 }, -- Reverend Mail +1
    [28050] = { agi = 8, def = 20, haste = 4, hp = 15, stp = 2 }, -- Swift Gages
    [28062] = { def = 17, dex = 8, haste = 2, mab = 4, macc = 4, mdb = 2, mnd = 6, mp = 20 }, -- Ornate Gloves
    [28166] = { haste = 3, hp = 25, mab = 5, marksmanship = 5, ratt = 10 }, -- Hailstone Hose
    [28201] = { agi = 9, def = 35, dex = 2, eva = 11, haste = 2, ta = 2 }, -- Acrobats Breeches
    [28272] = { acc = 3, agi = 5, def = 14, dex = 5, haste = 1 }, -- Adsilio Boots +1
    [28305] = { def = 20, haste = 4, hp = 35, str = 5, ta = 1 }, -- Ruthless Greaves
    [28331] = { def = 18, hp = 10, int = 5, mab = 4, mp = 13 }, -- Ukuxkaj Boots
    [28349] = { agi = 2, enmity = -1, racc = 12 }, -- Crested Torque
    [28350] = { mdt = -4 }, -- Cloud Hairpin
    [28384] = { agi = 4, enmity = -2, racc = 8 }, -- Loxo Scarf
    [28385] = { att = 5, def = 10, stp = 3, vit = 4 }, -- Rikugame Nodowa
    [28387] = { str = 5, vit = 3 }, -- Tellus Pendulum
    [28388] = { chr = 5, mp = 25, sk_sword = 12, songdur = 10, str = 5, wind = 10 }, -- Timeless Ocarina
    [28419] = { def = 7 }, -- Hachirin-no-obi
    [28425] = { def = 4, mab = 4, macc = 4, mnd = 5, mp = 25 }, -- Salire Belt
    [28445] = { chr = 5, def = 5, drain = 5, int = 5, mab = 3, mp = 25 }, -- Charmers Sash
    [28457] = { acc = 5, def = 5, eva = 5, haste = 5 }, -- Bolt Stone
    [28459] = { agi = 5, att = 5, haste = 3, ratt = 5, sb = 8 }, -- Subtle Sash
    [28460] = { def = 5, hp = 35, vit = 8 }, -- Beastly Girdle
    [28462] = { att = 7, def = 7, haste = 7, sb = 7, sird = 7 }, -- Enlils Sash
    [28491] = { acc = 2 }, -- Wilder. Earring +1
    [28514] = { enmity = -3, mab = 5 }, -- Adepts Earring
    [28540] = {  }, -- Warp Ring
    [28548] = { dex = 2, geomancy = 5, mnd = 5, mp = 40 }, -- Bagua Ring
    [28575] = { fc = 2, int = 5, mp = 25 }, -- Hibernal Ring
    [28577] = { def = 5, enmity = 2, hp = 65, pdt = -2 }, -- Titanium Band
    [28586] = {  }, -- Craftmasters Ring
    [28612] = { mnd = 2, str = 2 }, -- Emberpearl Earring
    [28613] = { acc = 3, att = 4, sb = 2 }, -- Luminous Earring
    [28615] = { acc = 8, def = 5, fc = 4, mnd = 5, mp = 25 }, -- Manaflow Sash
    [28640] = { curect = 7, def = 7, mnd = 3, mp = 15 }, -- Hierarchs Mantle
    [28652] = { def = 1 }, -- Hatchling Shield
    [39053] = { att = 8, stp = 2, str = 3 }, -- Heartwood Grip
    [39056] = { acc = 3, mnd = 3 }, -- Sapphire Tathlum
    [39060] = { agi = 4, archery = 9, def = 6 }, -- Yumihei Mantle
    [39063] = {  }, -- Tinkers Collar
    [39100] = { def = 14, dex = 3, haste = 2 }, -- Venom Vambraces
    [39103] = { hp = 20, mnd = 2 }, -- Blight Ring
};
