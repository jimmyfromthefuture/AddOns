local BCT = LibStub("AceAddon-3.0"):GetAddon("BCT")

BCT.CONSUMABLE = 1
BCT.WORLDBUFF = 2
BCT.PLAYERBUFF = 3
BCT.HOLIDAY = 4
BCT.GOODDEBUFF = 5
BCT.ENCHANT = 6
BCT.SPECIAL = 7
BCT.AURAS = {
	[BCT.CONSUMABLE] = "Consumables",
	[BCT.WORLDBUFF] = "World Buffs",
	[BCT.PLAYERBUFF] = "Player Buffs",
	[BCT.ENCHANT] = "Enchants",
	[BCT.GOODDEBUFF] = "Debuffs",
	[BCT.SPECIAL] = "Special",
	[BCT.HOLIDAY] = "Holiday",
}
BCT.BLACKLISTED = true
BCT.WHITELISTED = false
BCT.SHOW = true
BCT.HIDE = false
BCT.BUFF = true
BCT.DEBUFF = false
BCT.COUNT = true
BCT.IGNORE = false

local auras_default = {
	["auras_visible"] = { -- ListName, DisplayName, Shown/Hidden, Count/Ignore, Blacklist/Whitelist, BuffType, Buff/Debuff
		-- Holiday
		[26522] = {GetSpellInfo(26522), "Lunar Fortune", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[6724] = {GetSpellInfo(6724), "Light of Elune", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[26393] = {GetSpellInfo(26393), "Elune's Blessing", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[27572] = {GetSpellInfo(27572), "Smitten", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[29332] = {GetSpellInfo(29332), "Fire-toasted Bun", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[24705] = {GetSpellInfo(24705), "Invocation of the Wickerman", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[27669] = {"Orgrimmar Gift of Friendship (Agi)", "Orgrimmar Gift of Friendship (Agi)", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[27671] = {"Undercity Gift of Friendship (Int)", "Undercity Gift of Friendship (Int)", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[27670] = {"Thunder Bluff Gift of Friendship (Stam)", "Thunder Bluff Gift of Friendship (Stam)", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[27665] = {"Ironforge Gift of Friendship (Stam)", "Ironforge Gift of Friendship (Stam)", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[27664] = {"Stormwind Gift of Friendship (Int)", "Stormwind Gift of Friendship (Int)", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[27666] = {"Darnassus Gift of Friendship (Agi)", "Darnassus Gift of Friendship (Agi)", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[27722] = {GetSpellInfo(27722), "Sweet Surprise", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[27721] = {GetSpellInfo(27721), "Very Berry Cream", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[27720] = {GetSpellInfo(27720), "Buttermilk Delight", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[27723] = {GetSpellInfo(27723), "Dark Desire", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[23768] = {GetSpellInfo(23768), "Sayge's Dark Fortune of Damage", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[23769] = {GetSpellInfo(23769), "Sayge's Dark Fortune of Resistance", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[23767] = {GetSpellInfo(23767), "Sayge's Dark Fortune of Armor", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[23738] = {GetSpellInfo(23738), "Sayge's Dark Fortune of Spirit", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[23766] = {GetSpellInfo(23766), "Sayge's Dark Fortune of Intelligence", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[23737] = {GetSpellInfo(23737), "Sayge's Dark Fortune of Stamina", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[23735] = {GetSpellInfo(23735), "Sayge's Dark Fortune of Strength", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		[23736] = {GetSpellInfo(23736), "Sayge's Dark Fortune of Agility", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.HOLIDAY, BCT.BUFF},
		-- Consumable
		[17626] = {"Flask of the Titans", "Flask of the Titans", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[17627] = {"Flask of Distilled Wisdom", "Flask of Distilled Wisdom", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[17628] = {"Flask of Supreme Power", "Flask of Supreme Power", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[16322] = {"Juju Flurry", "Juju Flurry", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[16329] = {"Juju Might", "Juju Might", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[16323] = {"Juju Power", "Juju Power", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[10667] = {"R.O.I.D.S.", "R.O.I.D.S.", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[10668] = {"Lung Juice Cocktail", "Lung Juice Cocktail", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[10669] = {"Ground Scorpok Assay", "Ground Scorpok Assay", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[10692] = {"Cerebral Cortex Compound", "Cerebral Cortex Compound", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[17538] = {"Elixir of the Mongoose", "Elixir of the Mongoose", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[17539] = {"Greater Arcane Elixir", "Greater Arcane Elixir", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[26276] = {"Elixir of Greater Firepower", "Elixir of Greater Firepower", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[21920] = {"Elixir of Frost Power", "Elixir of Frost Power", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[11474] = {"Elixir of Shadow Power", "Elixir of Shadow Power", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[24363] = {"Mageblood Potion", "Mageblood Potion", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[24382] = {"Spirit of Zanza", "Spirit of Zanza", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[24383] = {"Swiftness of Zanza", "Swiftness of Zanza", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[24417] = {"Sheen of Zanza", "Sheen of Zanza", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[17038] = {"Winterfall Firewater", "Winterfall Firewater", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[18192] = {"Grilled Squid", "Grilled Squid", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[18125] = {"Blessed Sunfruit", "Blessed Sunfruit", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[22730] = {"Runn Tum Tuber Surprise", "Runn Tum Tuber Surprise", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[18194] = {"Nightfin Soup", "Nightfin Soup", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[10256] = {"12 stam/spirit food", "12 stam/spirit food", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[25804] = {"Rumsey Rum Black Label", "Rumsey Rum Black Label", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[22790] = {"Kreeg's Stout Beatdown", "Kreeg's Stout Beatdown", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[22789] = {"Gordok Green Grog", "Gordok Green Grog", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[3593] = {"Elixir of Fortitude", "Elixir of Fortitude", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[3826] = {"Mighty Troll's Blood Potion", "Mighty Troll's Blood Potion", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[11348] = {"Elixir of Superior Defense", "Elixir of Superior Defense", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[12175] = {"Scroll of Protection IV", "Scroll of Protection IV", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[10310] = {"Scroll of Strength IV", "Scroll of Strength IV", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[10309] = {"Scroll of Agility IV", "Scroll of Agility IV", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[15233] = {"Crystal Ward", "Crystal Ward", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[11567] = {"Crystal Spire", "Crystal Spire", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[5665] = {"Bogling Root", "Bogling Root", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[12608] = {"Catseye Elixir", "Catseye Elixir", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[15852] = {"Dragonbreath Chili", "Dragonbreath Chili", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		[11405] = {"Elixir of Giants", "Elixir of Giants", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.CONSUMABLE, BCT.BUFF},
		-- World buffs
		[15366] = {GetSpellInfo(15366), "Songflower Serenade", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.WORLDBUFF, BCT.BUFF},
		[22888] = {GetSpellInfo(22888), "Rallying Cry of the Dragonslayer", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.WORLDBUFF, BCT.BUFF},
		[24425] = {GetSpellInfo(24425), "Spirit of Zandalar", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.WORLDBUFF, BCT.BUFF},
		[29534] = {GetSpellInfo(29534), "Traces of Silithyst", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.WORLDBUFF, BCT.BUFF},
		[16609] = {GetSpellInfo(16609), "Warchief's Blessing", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.WORLDBUFF, BCT.BUFF},
		[22817] = {GetSpellInfo(22817), "Fengus' Ferocity", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.WORLDBUFF, BCT.BUFF},
		[22820] = {GetSpellInfo(22820), "Slip'kik's Savvy", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.WORLDBUFF, BCT.BUFF},
		[22818] = {GetSpellInfo(22818), "Mol'dar's Moxie", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.WORLDBUFF, BCT.BUFF},
		[15288] = {GetSpellInfo(15288), "Fury of Ragnaros", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.WORLDBUFF, BCT.BUFF},
		[15123] = {GetSpellInfo(15123), "Resist Fire", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.WORLDBUFF, BCT.BUFF},
		[17175] = {GetSpellInfo(17175), "Resist Arcane", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.WORLDBUFF, BCT.BUFF},
		[16587] = {GetSpellInfo(16587), "Dark Whispers", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.WORLDBUFF, BCT.BUFF},
		[17150] = {GetSpellInfo(17150), "Arcane Might", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.WORLDBUFF, BCT.BUFF},
		-- Player buffs
		[9910] = {GetSpellInfo(9910), "Thorns", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[10157] = {GetSpellInfo(10157), "Arcane Intellect", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[23028] = {GetSpellInfo(23028), "Arcane Brilliance", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[10170] = {GetSpellInfo(10170), "Amplify Magic", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[10174] = {GetSpellInfo(10174), "Dampen Magic", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[10958] = {GetSpellInfo(10958), "Shadow Protection", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[27841] = {GetSpellInfo(27841), "Divine Spirit", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[27681] = {GetSpellInfo(27681), "Prayer of Spirit", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[6346] = {GetSpellInfo(6346), "Fear Ward", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[131] = {GetSpellInfo(131), "Water Breathing", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[546] = {GetSpellInfo(546), "Water Walking", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[5697] = {GetSpellInfo(5697), "Unending Breath", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[2970] = {GetSpellInfo(2970), "Detect Invisibility", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[11551] = {GetSpellInfo(11551), "Battle Shout", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[19838] = {GetSpellInfo(19838), "Blessing of Might", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[20217] = {GetSpellInfo(20217), "Blessing of Kings", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[1038] = {GetSpellInfo(1038), "Blessing of Salvation", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[19854] = {GetSpellInfo(19854), "Blessing of Wisdom", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[19979] = {GetSpellInfo(19979), "Blessing of Light", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[20914] = {GetSpellInfo(20914), "Blessing of Sanctuary", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[25916] = {GetSpellInfo(25916), "Greater Blessing of Might", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[25898] = {GetSpellInfo(25898), "Greater Blessing of Kings", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[25895] = {GetSpellInfo(25895), "Greater Blessing of Salvation", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[25918] = {GetSpellInfo(25918), "Greater Blessing of Wisdom", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[25890] = {GetSpellInfo(25890), "Greater Blessing of Light", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[25899] = {GetSpellInfo(25899), "Greater Blessing of Sanctuary", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[10929] = {GetSpellInfo(10929), "Renew", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[9841] = {GetSpellInfo(9841), "Rejuvenation", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[27637] = {GetSpellInfo(27637), "Regrowth", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[10901] = {GetSpellInfo(10901), "Power Word: Shield", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[9885] = {GetSpellInfo(9885), "Mark of the Wild", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[21850] = {GetSpellInfo(21850), "Gift of the Wild", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[552] = {GetSpellInfo(552), "Abolish Disease", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
		[14253] = {GetSpellInfo(14253), "Abolish Poison", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.PLAYERBUFF, BCT.BUFF},
	},
	["auras_enchants"] = {
		[1510] = {"Spirit +8", "Spirit +8", BCT.HIDE, BCT.IGNORE, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
		[1507] = {"Stamina +8", "Stamina +8", BCT.HIDE, BCT.IGNORE, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
		[1504] = {"Armor +125", "Armor +125", BCT.HIDE, BCT.IGNORE, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
		[2545] = {"Dodge +1%", "Dodge +1%", BCT.HIDE, BCT.IGNORE, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
		[1483] = {"Mana +150", "Mana +150", BCT.HIDE, BCT.IGNORE, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
		[1506] = {"Strength +8", "Strength +8", BCT.HIDE, BCT.IGNORE, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
		[1509] = {"Intellect +8", "Intellect +8", BCT.HIDE, BCT.IGNORE, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
		[1503] = {"HP +100", "HP +100", BCT.HIDE, BCT.IGNORE, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
		[2543] = {"Attack Speed +1%", "Attack Speed +1%", BCT.HIDE, BCT.IGNORE, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
		[1505] = {"+20 Fire Resistance", "+20 Fire Resistance", BCT.HIDE, BCT.IGNORE, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
		[1508] = {"Agility +8", "Agility +8", BCT.HIDE, BCT.IGNORE, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
		[2544] = {"Healing and Spell Damage +8", "Healing and Spell Damage +8", BCT.HIDE, BCT.IGNORE, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
		[464] = {"Mithril Spurs", "Mithril Spurs", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
		[1704] = {"Thorium Spike", "Thorium Spike", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
		[2506] = {"Elemental Sharpening Stone", "Elemental Sharpening Stone", BCT.HIDE, BCT.IGNORE, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
		[34] = {"Counterweight", "Counterweight", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF},
	},
	["auras_hidden"] = {
		[1] = {"Defensive State", "Defensive State", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.SPECIAL, BCT.BUFF},
		[2] = {"Stance", "Stance", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.SPECIAL, BCT.BUFF},
		[3] = {"Tracking", "Tracking", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.SPECIAL, BCT.BUFF},
		[4] = {"Predatory Strikes", "Predatory Strikes", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.SPECIAL, BCT.BUFF},
		[5] = {"Furor", "Furor", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.SPECIAL, BCT.BUFF},
		[6] = {"Heart of the Wild", "Heart of the Wild", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.SPECIAL, BCT.BUFF},
	},
	["auras_debuffs"] = {
		[8733] = {GetSpellInfo(8733), "Blessing of Blackfathom", BCT.HIDE, BCT.IGNORE, BCT.WHITELISTED, BCT.GOODDEBUFF, BCT.DEBUFF},
	},
}

local defaults = {
	profile = {
		window = {
			lock = false,
			show = true,
			font = "Expressway",
			font_size = 13,
			enchants = false,
			group_lines = false,
			mouseover = false,
			nextfive = false,
			profileTxt = false,
		},
		loading = {
			groupState = {
				["Solo"] = true,
				["Group"] = true,
				["Raid"] = true,
			},
			instanceState = {
				[0] = true,
				[5] = true,
				[10] = true,
				[20] = true,
				[40] = true,
			},
		},
		announcer = {
			enabled = false,
			font = "Expressway",
			font_size = 40,
		},
		blacklisting = {
			enabledOut = false,
			enabledIn = false,
			buffer = 2,
		},
		auras = auras_default
	}
}

-- Init Profile State
BCT.session = {}

function BCT:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("BCTDB", defaults, true)
	self.session.db = self.db.profile
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

function BCT:RefreshConfig()
	self.session.db = self.db.profile
	BCT.Refresh()
	BCT.UpdateFont()
	BCT.UpdateFontAnnouncer()
	BCT.UpdateFrameState()
	BCT.SetInCombatBlacklistingMacro()
	BCT.profileStr = BCT.db:GetCurrentProfile()
end

-- Events
BCT.Events = CreateFrame("Frame","BCTEvents",UIParent)

-- Init Session State
BCT.session.state = {
	aurasTypeSelected = 1,
	aurasSelected = {},
	CombatCache = false,
	DefensiveState = false,
	DefensiveStateTimestamp = 0,
}

BCT.items = {}
BCT.buffs = {}
BCT.hidden = {}
BCT.aurasSorted = {}
BCT.nextAura = "                 "
BCT.nextAuraId = 0
BCT.buffsTotal = 0
BCT.enchantsTotal = 0
BCT.hiddenTotal = 0
BCT.aurasMax = 0
BCT.enchantsPushed = 0
BCT.trackedStr = ""
BCT.enchantsStr = ""
BCT.buffStr = ""
BCT.nextFiveStr = ""
BCT.profileStr = ""
BCT.optionsFrames = {}
BCT.optionsTmp = {}