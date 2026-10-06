--[[
    GearOpt stat definitions. Used to read item descriptions and to decode augments.
    Key: internal stat name used by data.lua weights.
]]

local M = {};

-- Text (lowercase, quotes removed) -> stat key. The longest matching phrase wins.
M.ALIAS = {
    -- Attributes / base
    ['str'] = 'str', ['dex'] = 'dex', ['vit'] = 'vit', ['agi'] = 'agi', ['int'] = 'int', ['mnd'] = 'mnd',
    ['chr'] = 'chr', ['cha'] = 'chr', ['hp'] = 'hp', ['mp'] = 'mp', ['def'] = 'def',
    -- Physical offense
    ['accuracy'] = 'acc', ['acc.'] = 'acc', ['acc'] = 'acc', ['attack'] = 'att', ['atk.'] = 'att', ['att.'] = 'att',
    ['ranged accuracy'] = 'racc', ['rng.acc.'] = 'racc', ['rng. acc.'] = 'racc', ['rang. acc.'] = 'racc', ['r.acc.'] = 'racc',
    ['ranged attack'] = 'ratt', ['rng.atk.'] = 'ratt', ['rng. atk.'] = 'ratt', ['rang. att.'] = 'ratt', ['r.atk.'] = 'ratt',
    ['store tp'] = 'stp', ['double attack'] = 'da', ['dbl.atk.'] = 'da', ['dbl. atk.'] = 'da',
    ['dbl. attack'] = 'da', ['dbl.attack'] = 'da', ['double atk.'] = 'da', ['dbl.att.'] = 'da', ['dbl. att.'] = 'da',
    ['triple atk'] = 'ta', ['trpl. atk.'] = 'ta', ['triple att.'] = 'ta',
    ['triple attack'] = 'ta', ['triple atk.'] = 'ta', ['quadruple attack'] = 'qa',
    ['critical hit rate'] = 'crit', ['crit. hit rate'] = 'crit', ['crit.hit rate'] = 'crit',
    ['critical hit damage'] = 'critdmg', ['crit. hit damage'] = 'critdmg', ['crit.hit damage'] = 'critdmg',
    ['weapon skill damage'] = 'wsd', ['weapon skill accuracy'] = 'wsacc', ['weapon skill acc.'] = 'wsacc',
    ['haste'] = 'haste', ['dual wield'] = 'dw', ['subtle blow'] = 'sb', ['subtle blow ii'] = 'sb',
    ['tp bonus'] = 'tpb', ['skillchain bonus'] = 'scb', ['skillchain damage'] = 'scb', ['sklchn.dmg.'] = 'scb',
    ['conserve tp'] = 'ctp', ['zanshin'] = 'zanshin', ['counter'] = 'counter', ['kick attacks'] = 'kick',
    ['martial arts'] = 'ma', ['occult acumen'] = 'occult',
    ['combat skill'] = 'combatskill', ['combat skills'] = 'combatskill', ['all combat skills'] = 'combatskill',
    -- Defense
    ['evasion'] = 'eva', ['eva.'] = 'eva', ['damage taken'] = 'dt', ['dmg. taken'] = 'dt',
    ['physical damage taken'] = 'pdt', ['phys. dmg. taken'] = 'pdt', ['physical dmg. taken'] = 'pdt',
    ['magic damage taken'] = 'mdt', ['magic dmg. taken'] = 'mdt', ['magical damage taken'] = 'mdt',
    ['breath damage taken'] = 'bdt', ['breath dmg. taken'] = 'bdt',
    ['magic def. bonus'] = 'mdb', ['magic defense bonus'] = 'mdb', ['mag.def.bns.'] = 'mdb', ['mag. def. bns.'] = 'mdb',
    ['magic evasion'] = 'meva', ['mag. evasion'] = 'meva', ['mag. eva.'] = 'meva',
    ['potency of cure effect received'] = 'curercv', ['cure potency received'] = 'curercv',
    ['movement speed'] = 'move', ['enmity'] = 'enmity',
    -- Magic
    ['magic accuracy'] = 'macc', ['mag. acc.'] = 'macc', ['mag. acc'] = 'macc', ['mag.acc.'] = 'macc', ['m.acc.'] = 'macc',
    ['magic atk. bonus'] = 'mab', ['magic attack bonus'] = 'mab', ['mag. atk. bns.'] = 'mab', ['mag.atk.bns.'] = 'mab',
    ['magic damage'] = 'mdmg', ['magic burst damage'] = 'mbb', ['magic burst dmg.'] = 'mbb',
    ['magic crit. hit rate'] = 'mcrit', ['magic critical hit rate'] = 'mcrit',
    ['mag. crit. hit dmg.'] = 'mcritdmg', ['magic crit. hit damage'] = 'mcritdmg',
    ['fast cast'] = 'fc', ['cure potency'] = 'cure', ['cure spellcasting time'] = 'curect',
    ['healing magic casting time'] = 'curect', ['healing magic spellcasting time'] = 'curect',
    ['song spellcasting time'] = 'songct', ['song recast delay'] = 'songrecast', ['song effect duration'] = 'songdur',
    ['song duration'] = 'songdur',
    ['conserve mp'] = 'cmp', ['refresh'] = 'refresh', ['regen'] = 'regen',
    ['spell interruption rate down'] = 'sird', ['spell interruption rate'] = 'sird',
    ['drain and aspir potency'] = 'drain',
    ['enhancing magic duration'] = 'enhdur', ['enh. mag. eff. dur.'] = 'enhdur', ['enhancing magic effect duration'] = 'enhdur',
    ['enfeebling magic duration'] = 'enfdur',
    ['healing magic skill'] = 'healing', ['divine magic skill'] = 'divine',
    ['enhancing magic skill'] = 'enhancing', ['enha.mag. skill'] = 'enhancing', ['enh. mag. skill'] = 'enhancing',
    ['enfeebling magic skill'] = 'enfeebling', ['enfb.mag. skill'] = 'enfeebling', ['enfb. mag. skill'] = 'enfeebling',
    ['elemental magic skill'] = 'elemental', ['elem. magic skill'] = 'elemental',
    ['dark magic skill'] = 'dark', ['summoning magic skill'] = 'summoning', ['ninjutsu skill'] = 'ninjutsu',
    ['singing skill'] = 'singing', ['string instrument skill'] = 'string', ['wind instrument skill'] = 'wind',
    ['blue magic skill'] = 'blue', ['geomancy skill'] = 'geomancy', ['handbell skill'] = 'handbell',
    ['mp recovered while healing'] = 'hmp', ['hp recovered while healing'] = 'hhp',
    -- Job specific
    ['treasure hunter'] = 'th', ['fencer'] = 'fencer',
    ['meditate'] = 'meditate', ['meditate duration'] = 'meditate', ['meditate effect duration'] = 'meditate',
    ['meditate eff. dur.'] = 'meditate', ['meditate eff dur'] = 'meditate',
    ['archery skill'] = 'archery', ['marksmanship skill'] = 'marksmanship', ['throwing skill'] = 'throwing',
    ['berserk'] = 'berserk', ['berserk duration'] = 'berserk', ['berserk effect duration'] = 'berserk',
    ['warcry'] = 'warcry', ['warcry duration'] = 'warcry', ['warcry effect duration'] = 'warcry',
    ['sublimation'] = 'sublimation', ['sublimation effect'] = 'sublimation',
    ['boost'] = 'boost', ['boost effect'] = 'boost', ['boost duration'] = 'boost', ['snapshot'] = 'snapshot', ['rapid shot'] = 'rapid', ['recycle'] = 'recycle',
    ['waltz potency'] = 'waltz', ['avatar perpetuation cost'] = 'perp', ['avatar perpetuation'] = 'perp',
    ['blood pact ability delay'] = 'bpdelay', ['blood pact ab. del. ii'] = 'bpdelay2', ['blood pact delay ii'] = 'bpdelay2',
    ['blood pact damage'] = 'bpdmg', ['blood boon'] = 'bloodboon',
    ['phantom roll'] = 'roll', ['phantom roll effect'] = 'roll', ['phantom roll duration'] = 'rolldur',
    ['phantom roll area of effect'] = 'rollaoe', ['phantom roll ability delay'] = 'rolldelay', ['phantom roll delay'] = 'rolldelay', ['p.roll delay'] = 'rolldelay',
};

-- Stats stored as "amount reduced" (positive = better): cast times, delays, perpetuation, interruption
M.ABS = { curect = true, songct = true, songrecast = true, bpdelay = true, bpdelay2 = true, perp = true, sird = true, rolldelay = true };

-- Server (LandSandBoat) modifier id -> stat key, used to build augments.lua
M.MOD = {
    [1] = 'def', [2] = 'hp', [5] = 'mp', [8] = 'str', [9] = 'dex', [10] = 'vit', [11] = 'agi', [12] = 'int', [13] = 'mnd', [14] = 'chr',
    [23] = 'att', [24] = 'ratt', [25] = 'acc', [26] = 'racc', [27] = 'enmity', [28] = 'mab', [29] = 'mdb', [30] = 'macc', [31] = 'meva',
    [48] = 'wsacc', [68] = 'eva', [71] = 'hmp', [72] = 'hhp', [73] = 'stp', [76] = 'move',
    [111] = 'divine', [112] = 'healing', [113] = 'enhancing', [114] = 'enfeebling', [115] = 'elemental', [116] = 'dark',
    [117] = 'summoning', [118] = 'ninjutsu', [119] = 'singing', [120] = 'string', [121] = 'wind', [122] = 'blue',
    [123] = 'geomancy', [124] = 'handbell', [126] = 'bpdmg',
    [160] = 'dt', [161] = 'pdt', [162] = 'bdt', [163] = 'mdt', [165] = 'crit', [168] = 'sird', [170] = 'fc', [173] = 'ma',
    [175] = 'scb', [190] = 'pdt', [259] = 'dw', [274] = 'mbb', [288] = 'da', [289] = 'sb', [291] = 'counter', [292] = 'kick',
    [296] = 'cmp', [302] = 'ta', [303] = 'th', [305] = 'recycle', [306] = 'zanshin', [311] = 'mdmg', [315] = 'drain',
    [345] = 'tpb', [357] = 'bpdelay', [359] = 'rapid', [365] = 'snapshot', [369] = 'refresh', [370] = 'regen',
    [371] = 'perp', [374] = 'cure', [260] = 'cure', [375] = 'curercv', [384] = 'haste', [421] = 'critdmg', [430] = 'qa',
    [454] = 'songdur', [455] = 'songct', [487] = 'mbb', [491] = 'waltz', [519] = 'curect', [541] = 'bpdelay2',
    [562] = 'mcrit', [563] = 'mcritdmg', [831] = 'mdt', [833] = 'songrecast', [840] = 'wsd', [841] = 'wsd',
    [890] = 'enhdur', [902] = 'occult', [913] = 'bloodboon', [944] = 'ctp', [973] = 'sb', [1151] = 'enfdur',
    [881] = 'roll', [882] = 'rolldur', [1076] = 'rolldelay',
    [94] = 'meditate', [483] = 'warcry', [948] = 'berserk', [954] = 'berserk', [401] = 'sublimation', [97] = 'boost',
};
-- Server stores these in 1/100 % units
M.DIV = { haste = 100, dt = 100, pdt = 100, mdt = 100, bdt = 100 };

M.LABELS = {
    str = 'STR', dex = 'DEX', vit = 'VIT', agi = 'AGI', int = 'INT', mnd = 'MND', chr = 'CHR', hp = 'HP', mp = 'MP', def = 'DEF',
    acc = 'Accuracy', att = 'Attack', racc = 'R.Acc', ratt = 'R.Atk', stp = 'Store TP', da = 'Dbl.Atk%', ta = 'Trpl.Atk%',
    qa = 'Quad.Atk%', crit = 'Crit%', critdmg = 'Crit.Dmg%', wsd = 'WS Dmg%', wsacc = 'WS Acc', haste = 'Haste%',
    dw = 'Dual Wield', sb = 'Subtle Blow', tpb = 'TP Bonus', scb = 'SC Dmg%', ctp = 'Conserve TP', zanshin = 'Zanshin',
    counter = 'Counter', kick = 'Kick Atk', ma = 'Martial Arts', occult = 'Occult Acumen',
    eva = 'Evasion', dt = 'DT%', pdt = 'PDT%', mdt = 'MDT%', bdt = 'BDT%', mdb = 'MDB', meva = 'M.Eva',
    curercv = 'Cure Rcvd%', move = 'Move%', enmity = 'Enmity',
    macc = 'M.Acc', mab = 'MAB', mdmg = 'M.Dmg', mbb = 'MB Dmg%', mcrit = 'M.Crit%', mcritdmg = 'M.Crit Dmg%',
    fc = 'Fast Cast%', cure = 'Cure Pot%', curect = 'Cure Cast-%', songct = 'Song Cast-%', songrecast = 'Song Recast-',
    songdur = 'Song Dur%', cmp = 'Conserve MP', refresh = 'Refresh', regen = 'Regen', sird = 'SIRD%', drain = 'Drain/Aspir%',
    enhdur = 'Enh.Dur%', enfdur = 'Enf.Dur%', healing = 'Healing', divine = 'Divine', enhancing = 'Enhancing',
    enfeebling = 'Enfeebling', elemental = 'Elemental', dark = 'Dark', summoning = 'Summoning', ninjutsu = 'Ninjutsu',
    singing = 'Singing', string = 'String', wind = 'Wind', blue = 'Blue Magic', geomancy = 'Geomancy', handbell = 'Handbell',
    hmp = 'MP Heal', hhp = 'HP Heal', th = 'Treasure Hunter', snapshot = 'Snapshot', rapid = 'Rapid Shot',
    recycle = 'Recycle', waltz = 'Waltz%', perp = 'Perpetuation-', bpdelay = 'BP Delay-', bpdelay2 = 'BP Delay II-',
    bpdmg = 'BP Dmg', bloodboon = 'Blood Boon', roll = 'Phantom Roll+', rolldur = 'Roll Duration', rolldelay = 'Roll Delay-', rollaoe = 'Roll Area',
    fencer = 'Fencer', combatskill = 'Combat Skill', archery = 'Archery', marksmanship = 'Marksmanship', throwing = 'Throwing', meditate = 'Meditate', berserk = 'Berserk', warcry = 'Warcry', sublimation = 'Sublimation', boost = 'Boost',
};

function M.normalize(chunk)
    local c = chunk:lower():gsub('"', ''):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '');
    local words = {};
    for w in c:gmatch('%S+') do words[#words + 1] = w; end
    for i = 1, #words do
        local key = M.ALIAS[table.concat(words, ' ', i)];
        if key then return key; end
    end
    return nil;
end

return M;
