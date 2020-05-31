local BCT = LibStub("AceAddon-3.0"):GetAddon("BCT")
local SM = LibStub:GetLibrary("LibSharedMedia-3.0")
local fonts = SM:List("font")

local function GetSpacer(n)
	return {
		order = n,
		type = "description",
		name = "",
	}
end

local GetAuraAdd = {
	order = 6, 
	name = "Add ID",
	type = 'input',
	get = function(info) return "" end,
	set = function(info, value)
		local arr = BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]]
		if BCT.session.state.aurasTypeSelected == BCT.ENCHANT then
			arr[tonumber(value)] = {"", "", BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.ENCHANT, BCT.UNLISTED}
		elseif BCT.session.state.aurasTypeSelected == BCT.DEBUFF then
			arr[tonumber(value)] = {GetSpellInfo(tonumber(value)), GetSpellInfo(tonumber(value)), BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.DEBUFF, BCT.UNLISTED}
		else
			if GetSpellInfo(tonumber(value)) then
				local found = BCT.GetAura(GetSpellInfo(tonumber(value)))
				if found then
					print("BCT: Aura already exists.")
				elseif BCT.session.state.aurasSourceSelected == 0 then
					print("BCT: Choose a source.")
				else
					arr[tonumber(value)] = {GetSpellInfo(tonumber(value)), GetSpellInfo(tonumber(value)), BCT.HIDE, BCT.COUNT, BCT.WHITELISTED, BCT.session.state.aurasSourceSelected, BCT.UNLISTED}
				end
			end
		end
	end,
}

local GetSource = {
	name = "Source",
	desc = "",
	type = 'select',
	order = 4,
	style = "dropdown",
	values = {
		[BCT.CONSUMABLE] = "Consumable",
		[BCT.WORLDBUFF] = "World",
		[BCT.PLAYERBUFF] = "Player",
		[BCT.HOLIDAY] = "Holiday",
		[BCT.PERSONALS] = "Personal",
	},
	get = function(info, value)
		return BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]][tonumber(info[#info-1])][6]
	end, 
	set = function(info, value) 
		local arr = BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]]
		arr[tonumber(info[#info-1])][6] = value
	end,
}

local GetListName = {
	order = 1,
	type = "input",
	name = "List Text",
	get = function(info) return BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]][tonumber(info[#info-1])][1] end,
	set = function(info, value) 
		local arr = BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]]
		arr[tonumber(info[#info-1])][1] = value
	end,
}

local GetAssigned = {
	order = 7,
	type = "toggle",
	name = "Assign",
	width = "normal",
	get = function(info) return BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]][tonumber(info[#info-1])][7] end,
	set = function(info, value) 
		local arr = BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]]
		arr[tonumber(info[#info-1])][7] = value
	end,
}

local GetDisplayName = {
	order = 2,
	type = "input",
	name = "Display Text",
	get = function(info) 
		local key = BCT.AURASMAP[BCT.session.state.aurasTypeSelected]
		local id = tonumber(info[#info-1])
		return BCT.session.db.auras[key][id][2] 
	end,
	set = function(info, value) 
		local arr = BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]]
		arr[tonumber(info[#info-1])][2] = value
	end,
}

local GetTracked = {
	order = 6,
	type = "toggle",
	name = "Track",
	width = "full",
	get = function(info) return BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]][tonumber(info[#info-1])][3] end,
	set = function(info, value) 
		local arr = BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]]
		arr[tonumber(info[#info-1])][3] = value
	end,
}

local GetBlacklisted = {
	order = 7,
	type = "toggle",
	name = "Blacklist",
	width = "full",
	get = function(info) return BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]][tonumber(info[#info-1])][5] end,
	set = function(info, value) 
		local arr = BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]]
		arr[tonumber(info[#info-1])][5] = value
		BCT.SetInCombatBlacklistingMacro()
	end,
}

local GetRemoveSpell = {
	order = 8,
	name = "Remove",
	type = 'execute',
	func = function(info)
		local arr = BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]]
		arr[tonumber(info[#info-1])] = nil
	end,
}

local GetCounts = {
	order = 7,
	type = "toggle",
	name = "Count towards cap",
	width = "full",
	get = function(info) return BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]][tonumber(info[#info-1])][4] end,
	set = function(info, value)
		local arr = BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]]
		arr[tonumber(info[#info-1])][4] = value
		BCT.Refresh()
	end,
}

local consGroupArgs = {
	listName = GetListName,
	displayName = GetDisplayName,
	tracked = GetTracked,
	removeSpell = GetRemoveSpell,
}

local buffGroupArgs = {
	displayName = GetDisplayName,
	spacer = GetSpacer(3),
	source = GetSource,
	tracked = GetTracked,
	blacklisted = GetBlacklisted,
	removeSpell = GetRemoveSpell,
--	assigned = GetAssigned,
}

local debuffGroupArgs = {
	displayName = GetDisplayName,
	tracked = GetTracked,
	space = GetSpacer(7),
	removeSpell = GetRemoveSpell,
}

local enchantGroupArgs = {
	listName = GetListName,
	counts = GetCounts,
	removeSpell = GetRemoveSpell,
}

local hiddenGroupArgs = {
	counts = GetCounts,
}

local groups = {
	[BCT.BUFF] = buffGroupArgs,
	[BCT.DEBUFF] = debuffGroupArgs,
	[BCT.ENCHANT] = enchantGroupArgs,
	[BCT.OTHER] = hiddenGroupArgs,
}

local function GetOptionsTable()
	BCT.CleanUp()

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
				name = "General",
				desc = "",
				childGroups = "tab",
				get = function(info) end,
				set = function(info, value) end,
				args = {
					lock = {
						order = 2,
						type = "execute",
						name = function()
							if BCT.session.db.window.lock then
								return "Toggle Anchor"
							else
								return "Hide Anchor"
							end
						end,
						width = "normal",
						func = function()
							BCT.session.db.window.lock = not BCT.session.db.window.lock
						end,
					},
					reset = {
						name = "Reposition Window",
						desc = "Resets Window Position",
						type = 'execute',
						order = 1,					
						width = "normal",					
						func = function()
							BCT.Anchor:SetUserPlaced(false)
							BCT.Anchor:SetPoint("CENTER", WorldFrame, "CENTER", 0,0)
							C_UI.Reload()
						end,
						confirmText = "Resets Window Position (Reloads UI)",
						confirm = true
					},
					enable = {
						name = function()
							if BCT.session.db.window.enable then
								return "Disable"
							else
								return "Enable"
							end
						end,
						type = 'execute',
						order = 3,	
						width = "normal",					
						func = function()
							BCT.session.db.window.enable = not BCT.session.db.window.enable
						end,
					},
					txt = {
						order = 4,
						type = "group",
						name = "General",
						args = {
							titleGroup = {
								name = "Anchor",
								desc = "",
								type = 'group',
								order = 1,					
								guiInline = true,
								args = {
									Text = {
										name = "Text",
										type = "input",
										order = 3,
										width = "normal",	
										get = function(info) return BCT.session.db.window.anchor.value end,
										set = function(info, value) 
											BCT.session.db.window.anchor.value = value
										end,
									},	
									counter = {
										type = "select",
										order = 4,
										name = "Counter",									
										values = {
											["None"] = "None",
											["3/32"] = "3/32",
											["3"] = "3",
										},	
										get = function(_, value) return BCT.session.db.window.anchor.counter end, 
										set = function(_, value) 
											BCT.session.db.window.anchor.counter = value
										end,
									},
									fontSize = {
										order = 1,
										name = "Font Size",
										desc = "",
										type = "range",
										min = 4, max = 32, step = 1,
										get = function(info) return tonumber(BCT.session.db.window.anchor.font_size) end,
										set = function(info, value) 
											local inp = tonumber(value)
											if 'number' == type(inp) and inp > 0 then
												BCT.session.db.window.anchor.font_size = inp
												BCT.UpdateFont()
											else
												print("BCT: You must input a positive number higher than 0")
											end
										end,
									},
									font = {
										type = "select",
										order = 2,
										name = "Font",
										values = fonts,
										get = function()
											for info, value in next, fonts do
												if value == BCT.session.db.window.anchor.font then
													return info
												end
											end
										end, 
										set = function(_, value)
											BCT.session.db.window.anchor.font = fonts[value]
											BCT.UpdateFont()
										end,
									},
									fontStyle = {
										type = "select",
										order = 3,
										name = "Font Outline",
										values = {
											["None"] = "None",
											["MONOCHROMEOUTLINE"] = "MONOCHROMEOUTLINE",
											["OUTLINE"] = "OUTLINE",
											["THICKOUTLINE"] = "THICKOUTLINE",
										},
										get = function() return BCT.session.db.window.anchor.font_style end,
										set = function(info, value) 
											BCT.session.db.window.anchor.font_style = value
											BCT.UpdateFont()
										end,
									},
								},
							},
							bodyGroup = {
								name = "Body",
								desc = "",
								type = 'group',
								order = 2,					
								guiInline = true,
								args = {
									fontSize = {
										order = 1,
										name = "Font Size",
										desc = "",
										type = "range",
										min = 4, max = 32, step = 1,
										get = function(info) return tonumber(BCT.session.db.window.body.font_size) end,
										set = function(info, value) 
											local inp = tonumber(value)
											if 'number' == type(inp) and inp > 0 then
												BCT.session.db.window.body.font_size = inp
												BCT.UpdateFont()
											else
												print("BCT: You must input a positive number higher than 0")
											end
										end,
									},
									font = {
										type = "select",
										order = 2,
										name = "Font",
										values = fonts,
										get = function()
											for info, value in next, fonts do
												if value == BCT.session.db.window.body.font then
													return info
												end
											end
										end, 
										set = function(_, value)
											BCT.session.db.window.body.font = fonts[value]
											BCT.UpdateFont()
										end,
									},
									fontStyle = {
										type = "select",
										order = 3,
										name = "Font Outline",
										values = {
											["None"] = "None",
											["MONOCHROMEOUTLINE"] = "MONOCHROMEOUTLINE",
											["OUTLINE"] = "OUTLINE",
											["THICKOUTLINE"] = "THICKOUTLINE",
										},
										get = function() return BCT.session.db.window.body.font_style end,
										set = function(info, value) 
											BCT.session.db.window.body.font_style = value
											BCT.UpdateFont()
										end,
									},
									mouseover = {
										name = "Mouse Over",
										desc = "",
										type = 'toggle',
										order = 4,					
										width = "normal",			
										get = function(info) return BCT.session.db.window.body.mouseover end,
										set = function(info, value) 
											BCT.session.db.window.body.mouseover = not BCT.session.db.window.body.mouseover
										end,
									},
									growup = {
										name = "Grow Up",
										desc = "",
										type = 'toggle',
										order = 5,					
										width = "normal",			
										get = function(info) return BCT.session.db.window.body.growup end,
										set = function(info, value) 
											BCT.session.db.window.body.growup = not BCT.session.db.window.body.growup
										end,
									},
									grouplines = {
										name = "Group Tracking",
										desc = "",
										type = 'toggle',
										order = 6,					
										width = "normal",			
										get = function(info) return BCT.session.db.window.body.group_lines end,
										set = function(info, value) 
											BCT.session.db.window.body.group_lines = not BCT.session.db.window.body.group_lines
										end,
									},
									xoff = {
										order = 7,
										name = "X Offset",
										desc = "",
										type = "range",
										min = -2140, max = 2140, step = 1,
										get = function(info) return BCT.session.db.window.body.x_offset end,
										set = function(info, value) 
											BCT.session.db.window.body.x_offset = tonumber(value)
										end,
									},
									yoff = {
										order = 8,
										name = "Y Offset",
										desc = "",
										type = "range",
										min = -2140, max = 2140, step = 1,
										get = function(info) return BCT.session.db.window.body.y_offset end,
										set = function(info, value) 
											BCT.session.db.window.body.y_offset = tonumber(value)
										end,
									},
								},
							},
							text = {
								name = "Body (Text)",
								desc = "",
								type = 'multiselect',
								order = 3,
								values = {
									["enchants"] = "Enchants",
									["buffs"] = "Buffs",
									["nextone"] = "Next",
									["tracking"] = "Tracking",
									["profile"] = "Profile",
								},	
								get = function(_, value) return BCT.session.db.window.text[value] end, 
								set = function(_, value, state) 
									BCT.session.db.window.text[value] = state
								end,
							},
						},
					},
					announce = {
						order = 5,
						type = "group",
						name = "Announcements",
						args = {
							announceBl = {
								name = "Blacklisted",
								desc = "Announce when blacklisted buffs are removed/lost",
								type = 'toggle',
								order = 4,					
								width = "normal",			
								get = function(info) return BCT.session.db.announcer.enabledBl end,
								set = function(info, value) 
									BCT.session.db.announcer.enabledBl = not BCT.session.db.announcer.enabledBl
								end,
							},
							announceTrck = {
								name = "Tracked",
								desc = "Announce when tracked buffs are removed/lost",
								type = 'toggle',
								order = 5,					
								width = "double",			
								get = function(info) return BCT.session.db.announcer.enabledTrck end,
								set = function(info, value) 
									BCT.session.db.announcer.enabledTrck = not BCT.session.db.announcer.enabledTrck
								end,
							},
							fontSize = {
								order = 1,
								name = "Font Size",
								desc = "",
								type = "range",
								min = 4, max = 60, step = 1,
								get = function(info) return tonumber(BCT.session.db.announcer.font_size) end,
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
							font = {
								type = "select",
								order = 2,
								name = "Font",
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
							fontStyle = {
								type = "select",
								order = 3,
								name = "Font Outline",
								values = {
									["None"] = "None",
									["MONOCHROMEOUTLINE"] = "MONOCHROMEOUTLINE",
									["OUTLINE"] = "OUTLINE",
									["THICKOUTLINE"] = "THICKOUTLINE",
								},
								get = function() return BCT.session.db.announcer.font_style end,
								set = function(info, value) 
									BCT.session.db.announcer.font_style = value
									BCT.UpdateFontAnnouncer()
								end,
							},
						},
					},
					blacklisting = {
						order = 6,
						type = "group",
						name = "Blacklisting",
						args = {
							outofcombat = {
								name = "Passive",
								type = "header",
								order = 0,
							},	
							introo = {
								name = "The passive auto-removal works out-of-combat ONLY.\n\nWhen the amount of buffs plus the buffer exceeds 32, one buff at a time will be removed until the buffer is no longer breached. \n\nSet the buffer to 32 if you want to disallow blacklisted buffs constantly out-of-combat.",
								type = "description",
								order = 1,
							},	
							buffer = {
								name = "Buffer",
								type = "input",
								order = 2,
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
								width = "double",
								get = function(info) return BCT.session.db.blacklisting.enabledOut end,
								set = function(info, value) 
									BCT.session.db.blacklisting.enabledOut = not BCT.session.db.blacklisting.enabledOut
									BCT.SetInCombatBlacklistingMacro()
								end,
							},
							incombat = {
								name = "Active",
								type = "header",
								order = 7,
							},	
							intro = {
								name = "The active auto-removal works both in-combat and out-of-combat.\n\nBefore combat is entered a chain of hidden buttons is created with a list of cancelaura lines. A macro which simulates a click on the first button of the chain can then be placed in an often used keybinding. \n\nDue to protected API the buttons cannot be changed during combat. Thus it is not possible to prioritize removal, meaning every use of the macro will attempt to remove all buffs marked for blacklisting.\n\nBeware that some spells and/or consumables have the same aura name (e.g. Nightfin Soup and Mageblood Potion) resulting in either mistaken removals or inaction. \n\nTo use in-combat auto-removal add the following line to one or more spell macros that you spam in combat:",
								type = "description",
								order = 8,
							},	
							macro = {
								name = "Macro",
								type = "input",
								order = 9,
								width = .6,	
								get = function(info) return "/click BCT" end,
								set = function(info, value) end,
							},	
							enableIn = {
								order = 10,
								type = "toggle",
								name = "Enable",
								width = "normal",
								get = function(info) return BCT.session.db.blacklisting.enabledIn end,
								set = function(info, value) 
									BCT.session.db.blacklisting.enabledIn = not BCT.session.db.blacklisting.enabledIn
									BCT.SetInCombatBlacklistingMacro()
								end,
							},
							spacer = GetSpacer(11),
							printer = {
								name = "Print",
								type = 'execute',
								order = 12,	
								width = .6,
								func = function()
									if BCT.session.db.blacklisting.enabledIn then
										print("--------------------------------")
										print(BCT.session.state.macros)
										print("--------------------------------")
									else
										print("BCT: Active blacklisting must be enabled to print macros.")
									end
								end,
							},
						},
					},
					loading = {
						order = 7,
						type = "group",
						name = "Loading",
						args = {
							State = {
								name = "Group Type",
								desc = "Group Type",
								type = 'multiselect',
								order = 18,					
								values = {
									["Solo"] = "Solo",
									["Group"] = "Group",
									["Raid"] = "Raid",
									["Battleground"] = "Battleground",
								},	
								get = function(_, value) return BCT.session.db.loading.groupState[value] end, 
								set = function(_, value, state) 
									BCT.session.db.loading.groupState[value] = state
								end,
							},
							instanceState = {
								name = "Instance Type",
								desc = "Instance Type",
								type = 'multiselect',
								order = 19,	
								values = {
									[0] = "Outside",
									[5] = "5 Man Instance",
									[10] = "10 Man Instance",
									[20] = "20 Man Instance",
									[40] = "40 Man Instance",
								},	
								get = function(_, value) return BCT.session.db.loading.instanceState[value] end, 
								set = function(_, value, state) 
									BCT.session.db.loading.instanceState[value] = state
								end,
							},
						},
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
					addId = GetAuraAdd,	
					auraType = {
						type = "select",
						order = 2,
						name = "Type",
						values = function()
							return BCT.AURAS
						end,
						get = function(key, value, state)
							return BCT.session.state.aurasTypeSelected
						end, 
						set = function(key, value)
							BCT.session.state.aurasSourceSelected = 0
							BCT.session.state.aurasTypeSelected = value
						end,
					},
					source = {
						name = "Source",
						desc = "",
						type = 'select',
						order = 3,
						style = "dropdown",
						values = function() 
							if BCT.session.state.aurasTypeSelected == BCT.BUFF then
								return {
									[0] = "All",
									[BCT.CONSUMABLE] = "Consumable",
									[BCT.WORLDBUFF] = "World",
									[BCT.PLAYERBUFF] = "Player",
									[BCT.HOLIDAY] = "Holiday",
									[BCT.PERSONALS] = "Personal",
								}
							else
								BCT.session.state.aurasSourceSelected = 0
								return {[0] = "All"}
							end
						end,
						get = function(_, value)
							return BCT.session.state.aurasSourceSelected
						end, 
						set = function(_, value) 
							BCT.session.state.aurasSourceSelected = value
						end,
					},
					filter = {
						name = "Filter",
						desc = "",
						type = 'select',
						order = 4,
						style = "dropdown",
						values = {
							["all"] = "All",
							["blacklisted"] = "Blacklisted",
							["tracked"] = "Tracked",
						},	
						get = function(_, value)
							return BCT.session.state.aurasFilter
						end, 
						set = function(_, value) 
							BCT.session.state.aurasFilter = value
						end,
					},
					search = {
						name = "Search",
						type = "input",
						order = 5,
						--width = .6,	
						get = function(info) return BCT.session.state.aurasSearch end,
						set = function(info, value) BCT.session.state.aurasSearch = value end,
					},	
				},
			},
			Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(BCT.db)
		},
	}
	
	local arr = BCT.session.db.auras[BCT.AURASMAP[BCT.session.state.aurasTypeSelected]]
	
	local function getKeysSortedByValue(tbl, sortFunction)

		local keys = {}
		for key in pairs(tbl) do
			
			if floor(arr[key][6]) == BCT.session.state.aurasTypeSelected and
				(BCT.session.state.aurasSourceSelected ~= BCT.CONSUMABLE and true or arr[key][6] == BCT.CONSUMABLE) and
				(BCT.session.state.aurasSourceSelected ~= BCT.WORLDBUFF and true or arr[key][6] == BCT.WORLDBUFF) and
				(BCT.session.state.aurasSourceSelected ~= BCT.PLAYERBUFF and true or arr[key][6] == BCT.PLAYERBUFF) and
				(BCT.session.state.aurasSourceSelected ~= BCT.HOLIDAY and true or arr[key][6] == BCT.HOLIDAY) and
				(BCT.session.state.aurasSourceSelected ~= BCT.PERSONALS and true or arr[key][6] == BCT.PERSONALS) and
				(BCT.session.state.aurasFilter ~= "blacklisted" and true or arr[key][5]) and
				(BCT.session.state.aurasFilter ~= "tracked" and true or arr[key][3])
				then

				table.insert(keys, key)
			end
		end

		table.sort(keys, function(a, b)
			return sortFunction(tbl[a][1], tbl[b][1])
		end)

		return keys
	end

	local sortedKeys = getKeysSortedByValue(arr, function(a, b) return a < b end)
	
	local i = 7
	for _, key in ipairs(sortedKeys) do

		local _, _, spellIcon = GetSpellInfo(key)
		local spellName = arr[key][1]
		local spellType = arr[key][6]
		
		if spellType == BCT.OTHER or
			spellType == BCT.ENCHANT then spellIcon = nil end
			
		if not (spellType == BCT.OTHER or 
			spellType == BCT.PLAYERBUFF or
			spellType == BCT.PERSONALS) then
			spellName = spellName .. " (" .. key .. ")"
		end
		
		if string.match(spellName:lower(), BCT.session.state.aurasSearch) then
			optionsTbl.args.Auras.args[tostring(key)] = {
				order = i,
				type = "group",
				name = spellName,
				icon = spellIcon,
				args = groups[BCT.session.state.aurasTypeSelected]
			}
			i = i + 1
		end
	end
	
	if i == 7 then
		optionsTbl.args.Auras.args[tostring(-1)] = {
			order = i,
			type = "group",
			name = " ",
			icon = nil,
			args = {}
		}
	end

	return optionsTbl
end

LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("BCT", GetOptionsTable)
BCT.optionsFrames.BCT = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BCT", "BCT", nil, "General")
BCT.optionsFrames.Setup = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BCT", "Setup", "BCT", "Setup")
BCT.optionsFrames.Auras = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BCT", "Auras", "BCT", "Auras")
BCT.optionsFrames.Profiles = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BCT", "Profiles", "BCT", "Profiles")