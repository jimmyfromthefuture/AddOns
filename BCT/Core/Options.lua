local BCT = LibStub("AceAddon-3.0"):GetAddon("BCT")
local SM = LibStub:GetLibrary("LibSharedMedia-3.0")
local fonts = SM:List("font")

local buffTypeArr = {
	[BCT.CONSUMABLE] = "auras_visible",
	[BCT.WORLDBUFF] = "auras_visible",
	[BCT.PLAYERBUFF] = "auras_visible",
	[BCT.ENCHANT] = "auras_enchants",
	[BCT.GOODDEBUFF] = "auras_debuffs",
	[BCT.SPECIAL] = "auras_hidden",
	[BCT.HOLIDAY] = "auras_visible",
}

local GetAuraSelect = {
	type = "select",
	order = 2,
	name = "Name",
	desc = "...",
	width = "double",
	values = function()
		local filters = {}
		local arr = BCT.session.db.auras[buffTypeArr[BCT.session.state.aurasTypeSelected]]
		
		for k, v in pairs(arr) do
			if v[6] == BCT.session.state.aurasTypeSelected then
				if BCT.session.state.aurasTypeSelected == BCT.SPECIAL or 
				BCT.session.state.aurasTypeSelected == BCT.PLAYERBUFF then
					filters[k] = arr[k][1]
				else
					filters[k] = arr[k][1] .. " (" .. k .. ")"
				end
			end
		end
		
		return filters
	end, 
	get = function()
		if BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected] == nil then
			for k, v in pairs(BCT.session.db.auras[buffTypeArr[BCT.session.state.aurasTypeSelected]]) do
				if v[6] == BCT.session.state.aurasTypeSelected then
					BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected] = k
					return k
				end
			end
		end
		return BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected]
	end, 
	set = function(_, value)
		BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected] = value
	end,
}

local GetAuraAdd = {
	order = 3, 
	name = "Add ID",
	desc = "...",
	type = 'input',
	get = function(info) return "" end,
	set = function(info, value)
		local arr = BCT.session.db.auras[buffTypeArr[BCT.session.state.aurasTypeSelected]]
		if BCT.session.state.aurasTypeSelected == BCT.ENCHANT then
			arr[tonumber(value)] = {"", "", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.ENCHANT, BCT.BUFF}
		else
			if GetSpellInfo(tonumber(value)) then
				local found = BCT.FindAura(GetSpellInfo(tonumber(value)))
					if found then
					print("BCT: Aura already exists.")
				else
					arr[tonumber(value)] = {GetSpellInfo(tonumber(value)), GetSpellInfo(tonumber(value)), BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.session.state.aurasTypeSelected, BCT.BUFF}
				end
			end
		end
	end,
}

local GetListName = {
	order = 4,
	type = "input",
	name = "List Name",
	desc = "...",
	get = function(info) return BCT.session.db.auras[buffTypeArr[BCT.session.state.aurasTypeSelected]][BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected]][1] end,
	set = function(info, value) 
		local arr = BCT.session.db.auras[buffTypeArr[BCT.session.state.aurasTypeSelected]]
		arr[BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected]][1] = value
	end,
}

local GetDisplayName = {
	order = 5,
	type = "input",
	name = "Display Name",
	desc = "...",
	get = function(info) return BCT.session.db.auras[buffTypeArr[BCT.session.state.aurasTypeSelected]][BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected]][2] end,
	set = function(info, value) 
		local arr = BCT.session.db.auras[buffTypeArr[BCT.session.state.aurasTypeSelected]]
		arr[BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected]][2] = value
	end,
}

local GetTracked = {
	order = 6,
	type = "toggle",
	name = "Display",
	desc = "...",
	width = "normal",
	get = function(info) return BCT.session.db.auras[buffTypeArr[BCT.session.state.aurasTypeSelected]][BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected]][3] end,
	set = function(info, value) 
		local arr = BCT.session.db.auras[buffTypeArr[BCT.session.state.aurasTypeSelected]]
		arr[BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected]][3] = value
	end,
}

local GetBlacklisted = {
	order = 7,
	type = "toggle",
	name = "Blacklist",
	desc = "...",
	width = "full",
	get = function(info) return BCT.session.db.auras[buffTypeArr[BCT.session.state.aurasTypeSelected]][BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected]][5] end,
	set = function(info, value) 
		local arr = BCT.session.db.auras[buffTypeArr[BCT.session.state.aurasTypeSelected]]
		arr[BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected]][5] = value
		BCT.SetInCombatBlacklistingMacro()
	end,
}

local GetRemoveSpell = {
	order = 8,
	name = "Remove",
	desc = "...",
	type = 'execute',
	func = function()
		local arr = BCT.session.db.auras[buffTypeArr[BCT.session.state.aurasTypeSelected]]
		arr[BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected]] = nil
		for k, v in pairs(arr) do
			if v[6] == BCT.session.state.aurasTypeSelected then
				BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected] = k
			end
		end
	end,
}

local GetCounts = {
	order = 7,
	type = "toggle",
	name = "Count towards cap",
	desc = "...",
	width = "full",
	get = function(info) return BCT.session.db.auras[buffTypeArr[BCT.session.state.aurasTypeSelected]][BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected]][4] end,
	set = function(info, value)
		local arr = BCT.session.db.auras[buffTypeArr[BCT.session.state.aurasTypeSelected]]
		arr[BCT.session.state.aurasSelected[BCT.session.state.aurasTypeSelected]][4] = value
		BCT.Refresh()
	end,
}

local consGroupArgs = {
	auraSelect = GetAuraSelect,
	auraAdd = GetAuraAdd,
	listName = GetListName,
	displayName = GetDisplayName,
	tracked = GetTracked,
	blacklisted = GetBlacklisted,
	removeSpell = GetRemoveSpell,
}

local buffGroupArgs = {
	auraSelect = GetAuraSelect,
	auraAdd = GetAuraAdd,
	displayName = GetDisplayName,
	tracked = GetTracked,
	blacklisted = GetBlacklisted,
	removeSpell = GetRemoveSpell,
}

local debuffGroupArgs = {
	auraSelect = GetAuraSelect,
	auraAdd = GetAuraAdd,
	displayName = GetDisplayName,
	tracked = GetTracked,
	removeSpell = GetRemoveSpell,
}

local enchantGroupArgs = {
	auraSelect = GetAuraSelect,
	auraAdd = GetAuraAdd,
	listName = GetListName,
	counts = GetCounts,
	removeSpell = GetRemoveSpell,
}

local hiddenGroupArgs = {
	auraSelect = GetAuraSelect,
	counts = GetCounts,
}

local groups = {
	[BCT.CONSUMABLE] = consGroupArgs,
	[BCT.WORLDBUFF] = buffGroupArgs,
	[BCT.PLAYERBUFF] = buffGroupArgs,
	[BCT.GOODDEBUFF] = debuffGroupArgs,
	[BCT.ENCHANT] = enchantGroupArgs,
	[BCT.SPECIAL] = hiddenGroupArgs,
	[BCT.HOLIDAY] = buffGroupArgs,
}

local function GetOptionsTable()
	local optionsTbl = {
		type = "group",
		name = "BCT",
		args = {
			General = {
				name = "General",
				desc = "General Settings",
				type = "group",
				order = 1,
				args = {
					intro = {
						name = "BCT",
						type = "description",
						order = 1,
					},	
				}, 	
			},
			Setup = {
				order = 2,
				type = "group",
				name = "Setup",
				desc = "",
				args = {
					setupHeader = {
						name = "Window",
						type = "header",
						order = 0,
					},	
					locked = {
						order = 1,
						type = "toggle",
						name = "Lock",
						desc = "...",
						width = "full",
						get = function(info) return BCT.session.db.window.lock end,
						set = function(info, value) 
							BCT.session.db.window.lock = not BCT.session.db.window.lock
							BCT.UpdateFrameState()
						end,
					},
					show = {
						order = 2,
						type = "toggle",
						name = "Show",
						desc = "...",
						width = "full",
						get = function(info) return BCT.session.db.window.show end,
						set = function(info, value) 
							BCT.session.db.window.show = not BCT.session.db.window.show
							BCT.UpdateFrameState()
						end,
					},
					reset = {
						name = "Reset",
						desc = "Resets Window Position",
						type = 'execute',
						order = 3,					
						width = .6,					
						func = function()
							BCT.Window:SetUserPlaced(false)
							BCT.Window:SetPoint("CENTER", WorldFrame, "CENTER", 0,0)
							C_UI.Reload()
						end,
						confirmText = "Resets Window Position",
						confirm = true
					},
					mouseover = {
						name = "Mouseover viewing",
						desc = "Enables mouseover viewing",
						type = 'toggle',
						order = 4,					
						width = "full",			
						get = function(info) return BCT.session.db.window.mouseover end,
						set = function(info, value) 
							BCT.session.db.window.mouseover = not BCT.session.db.window.mouseover
							BCT.UpdateFrameState()
						end,
					},
					enchants = {
						name = "Show Enchants",
						desc = "",
						type = 'toggle',
						order = 5,					
						width = "full",			
						get = function(info) return BCT.session.db.window.enchants end,
						set = function(info, value) 
							BCT.session.db.window.enchants = not BCT.session.db.window.enchants
							BCT.UpdateFrameState()
						end,
					},
					nextfive = {
						name = "Show Five Next",
						desc = "",
						type = 'toggle',
						order = 6,					
						width = "full",			
						get = function(info) return BCT.session.db.window.nextfive end,
						set = function(info, value) 
							BCT.session.db.window.nextfive = not BCT.session.db.window.nextfive
						end,
					},
					profileTxt = {
						name = "Show Current Profile",
						desc = "",
						type = 'toggle',
						order = 7,					
						width = "full",			
						get = function(info) return BCT.session.db.window.profileTxt end,
						set = function(info, value) 
							BCT.session.db.window.profileTxt = not BCT.session.db.window.profileTxt
						end,
					},
					grouplines = {
						name = "Group tracking lines",
						desc = "",
						type = 'toggle',
						order = 7,					
						width = "full",			
						get = function(info) return BCT.session.db.window.group_lines end,
						set = function(info, value) 
							BCT.session.db.window.group_lines = not BCT.session.db.window.group_lines
						end,
					},
					font = {
						type = "select",
						order = 8,
						name = "Font",
						desc = "...",
						values = fonts,
						get = function()
							for info, value in next, fonts do
								if value == BCT.session.db.window.font then
									return info
								end
							end
						end, 
						set = function(_, value)
							BCT.session.db.window.font = fonts[value]
							BCT.UpdateFont()
						end,
					},
					font_size = {
						order = 9,
						type = "input",
						name = "Size",
						desc = "...",
						width = .6,		
						get = function(info) return tostring(BCT.session.db.window.font_size) end,
						set = function(info, value) 
							local inp = tonumber(value)
							if 'number' == type(inp) and inp > 0 then
								BCT.session.db.window.font_size = inp
								BCT.UpdateFont()
							else
								print("BCT: You must input a positive number higher than 0")
							end
						end,
					},
					loadingHeader = {
						name = "Loading",
						type = "header",
						order = 10,
					},	
					groupState = {
						name = "Group Type",
						desc = "Group Type",
						type = 'multiselect',
						order = 11,					
						values = {
							["Solo"] = "Solo",
							["Group"] = "Group",
							["Raid"] = "Raid",
						},	
						get = function(_, value) return BCT.session.db.loading.groupState[value] end, 
						set = function(_, value, state) 
							BCT.session.db.loading.groupState[value] = state
							BCT.UpdateFrameState()
						end,
					},
					instanceState = {
						name = "Instance Type",
						desc = "Instance Type",
						type = 'multiselect',
						order = 11,					
						values = {
							[0] = "Outside",
							[5] = "5 Man instances",
							[10] = "10 Man Instance",
							[20] = "20 Man Instance",
							[40] = "40 Man Instance",
						},	
						get = function(_, value) return BCT.session.db.loading.instanceState[value] end, 
						set = function(_, value, state) 
							BCT.session.db.loading.instanceState[value] = state
							BCT.UpdateFrameState()
						end,
					},
				},
			},
			Blacklisting = {
				order = 2,
				type = "group",
				name = "Blacklisting",
				desc = "Blacklisting",
				args = {
					outofcombat = {
						name = "Out-of-combat",
						type = "header",
						order = 0,
					},	
					introo = {
						name = "Out-of-combat auto-removal will automatically remove any blacklisted buffs if enabled, and if the buffer is breached." ..
							"\n\nSet the buffer to 32 if you want to disallow blacklisted buffs permanently out-of-combat.",
						type = "description",
						order = 1,
					},	
					buffer = {
						name = "Buffer",
						type = "input",
						order = 2,
						desc = "...",
						width = .6,	
						get = function(info) return tostring(BCT.session.db.blacklisting.buffer) end,
						set = function(info, value) 
							local inp = tonumber(value)
							if 'number' == type(inp) and inp > 0 then
								BCT.session.db.blacklisting.buffer = inp
							else
								print("BCT: You must input a positive number higher than 0")
							end
						end,
					},	
					enableOut = {
						order = 3,
						type = "toggle",
						name = "Enable",
						desc = "...",
						width = "normal",
						get = function(info) return BCT.session.db.blacklisting.enabledOut end,
						set = function(info, value) 
							BCT.session.db.blacklisting.enabledOut = not BCT.session.db.blacklisting.enabledOut
							BCT.SetInCombatBlacklistingMacro()
						end,
					},
					announcer = {
						order = 4,
						type = "toggle",
						name = "Announce auto-removal",
						desc = "...",
						width = "full",
						get = function(info) return BCT.session.db.announcer.enabled end,
						set = function(info, value) 
							BCT.session.db.announcer.enabled = not BCT.session.db.announcer.enabled
						end,
					},
					font = {
						type = "select",
						order = 5,
						name = "Font",
						desc = "...",
						values = fonts,
						get = function()
							for info, value in next, fonts do
								if value == BCT.session.db.announcer.font then
									return info
								end
							end
						end, 
						set = function(_, value)
							BCT.session.db.announcer.font = fonts[value]
							BCT.UpdateFontAnnouncer()
						end,
					},
					font_size = {
						order = 6,
						type = "input",
						name = "Size",
						desc = "...",
						width = .6,		
						get = function(info) return tostring(BCT.session.db.announcer.font_size) end,
						set = function(info, value) 
							local inp = tonumber(value)
							if 'number' == type(inp) and inp > 0 then
								BCT.session.db.announcer.font_size = inp
								BCT.UpdateFontAnnouncer()
							else
								print("BCT: You must input a positive number higher than 0")
							end
						end,
					},
					incombat = {
						name = "In-combat",
						type = "header",
						order = 7,
					},	
					intro = {
						name = "Because of protected API in-combat auto-removal ONLY works through macro usage." ..
							"\n\nFurthermore it is not possible to remove unwanted buffs one by one, instead the macro will attempt to remove all blacklisted buffs when clicked." ..
							"\n\nTo enable in-combat auto-removal add the following line to one or more spell macros that you spam in combat:",
						type = "description",
						order = 8,
					},	
					macro = {
						name = "Macro",
						type = "input",
						order = 9,
						desc = "...",
						width = .6,	
						get = function(info) return "/click BCT" end,
						set = function(info, value) end,
					},	
					enableIn = {
						order = 10,
						type = "toggle",
						name = "Enable",
						desc = "...",
						width = "normal",
						get = function(info) return BCT.session.db.blacklisting.enabledIn end,
						set = function(info, value) 
							BCT.session.db.blacklisting.enabledIn = not BCT.session.db.blacklisting.enabledIn
							BCT.SetInCombatBlacklistingMacro()
						end,
					},
				},
			},
			Auras = {
				order = 4,
				type = "group",
				name = "Auras",
				desc = "Auras",
				args = {
					intro = {
						name = "All visible auras are automatically counted and does not have to be added. Only bother adding an aura if you want to blacklist or track it." ..
						"\n\nEnchants are only counted if added and toggled." ..
						"\n\nDebuffs are never counted but can be added for tracking.",
						type = "description",
						order = 0,
					},	
					auraType = {
						type = "select",
						order = 1,
						name = "Type",
						desc = "...",
						values = function()
							return BCT.AURAS
						end,
						get = function()
							return BCT.session.state.aurasTypeSelected
						end, 
						set = function(key, value)
							BCT.session.state.aurasTypeSelected = value
						end,
					},
					auraGroup = {
						order = 2,
						type = "group",
						name = " ",
						guiInline = true,
						args = groups[BCT.session.state.aurasTypeSelected]
					},	
				},
			},
			Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(BCT.db)
		},
	}

	return optionsTbl
end

LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("BCT", GetOptionsTable)
BCT.optionsFrames.BCT = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BCT", "BCT", nil, "General")
BCT.optionsFrames.Setup = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BCT", "Setup", "BCT", "Setup")
BCT.optionsFrames.Blacklisting = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BCT", "Blacklisting", "BCT", "Blacklisting")
BCT.optionsFrames.Auras = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BCT", "Auras", "BCT", "Auras")
BCT.optionsFrames.Profiles = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BCT", "Profiles", "BCT", "Profiles")