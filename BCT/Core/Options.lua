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
	desc = "Make sure you are adding a spell ID, NOT an item ID",
	get = function(info) return "" end,
	set = function(info, value)
		local arr = BCT.session.db.auras[BCT.session.state.aurasTypeSelected]
		local _, _, classId = UnitClass("player")
		if BCT.session.state.aurasTypeSelected == BCT.ENCHANT then
			arr[tonumber(value)] = {
				"", 
				"", 
				BCT.HIDE, 
				BCT.COUNT, 
				BCT.WHITELISTED, 
				BCT.ENCHANT, 
				BCT.UNLISTED
			}
		elseif BCT.session.state.aurasTypeSelected == BCT.DEBUFF then
			arr[tonumber(value)] = {
				GetSpellInfo(tonumber(value)), 
				GetSpellInfo(tonumber(value)), 
				BCT.HIDE, 
				BCT.COUNT, 
				BCT.WHITELISTED, 
				BCT.DEBUFF, 
				BCT.UNLISTED
			}
		else
			if GetSpellInfo(tonumber(value)) then
				local found = BCT.GetAura(GetSpellInfo(tonumber(value)))
				if found then
					print("BCT: Aura already exists.")
				elseif BCT.session.state.aurasSourceSelected == 0 then
					print("BCT: Choose a source.")
				else
					arr[tonumber(value)] = {
						GetSpellInfo(tonumber(value)), 
						GetSpellInfo(tonumber(value)), 
						BCT.HIDE, 
						BCT.COUNT, 
						BCT.WHITELISTED, 
						BCT.session.state.aurasSourceSelected, 
						BCT.UNLISTED, 
						(BCT.session.state.aurasSourceSelected == BCT.PERSONALS and classId or nil)
					}
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
		return BCT.session.db.auras[BCT.session.state.aurasTypeSelected][tonumber(info[#info-1])][6]
	end, 
	set = function(info, value) 
		local arr = BCT.session.db.auras[BCT.session.state.aurasTypeSelected]
		local _, _, classId = UnitClass("player")
		arr[tonumber(info[#info-1])][6] = value
		arr[tonumber(info[#info-1])][9] = (BCT.session.state.aurasSourceSelected == BCT.PERSONALS and classId or nil)
	end,
}

local GetListName = {
	order = 1,
	type = "input",
	name = "List Text",
	get = function(info) return BCT.session.db.auras[BCT.session.state.aurasTypeSelected][tonumber(info[#info-1])][1] end,
	set = function(info, value) 
		local arr = BCT.session.db.auras[BCT.session.state.aurasTypeSelected]
		arr[tonumber(info[#info-1])][1] = value
	end,
}

local GetAssigned = {
	order = 7,
	type = "toggle",
	name = "Assign",
	width = "normal",
	get = function(info) return BCT.session.db.auras[BCT.session.state.aurasTypeSelected][tonumber(info[#info-1])][7] end,
	set = function(info, value) 
		local arr = BCT.session.db.auras[BCT.session.state.aurasTypeSelected]
		arr[tonumber(info[#info-1])][7] = value
	end,
}

local GetDisplayName = {
	order = 2,
	type = "input",
	name = "Display Text",
	get = function(info) 
		local id = tonumber(info[#info-1])
		return BCT.session.db.auras[BCT.session.state.aurasTypeSelected][id][2] 
	end,
	set = function(info, value) 
		local arr = BCT.session.db.auras[BCT.session.state.aurasTypeSelected]
		arr[tonumber(info[#info-1])][2] = value
	end,
}

local GetTracked = {
	order = 6,
	type = "toggle",
	name = "Track",
	width = "full",
	get = function(info) return BCT.session.db.auras[BCT.session.state.aurasTypeSelected][tonumber(info[#info-1])][3] end,
	set = function(info, value) 
		local arr = BCT.session.db.auras[BCT.session.state.aurasTypeSelected]
		arr[tonumber(info[#info-1])][3] = value
	end,
}

local GetBlacklisted = {
	order = 7,
	type = "toggle",
	name = "Blacklist",
	width = "full",
	get = function(info) return BCT.session.db.auras[BCT.session.state.aurasTypeSelected][tonumber(info[#info-1])][5] end,
	set = function(info, value) 
		local arr = BCT.session.db.auras[BCT.session.state.aurasTypeSelected]
		arr[tonumber(info[#info-1])][5] = value
		BCT.SetInCombatBlacklistingMacro()
	end,
}

local GetReserved = {
	order = 8,
	type = "toggle",
	name = "Reserve",
	width = "full",
	get = function(info) return BCT.session.db.auras[BCT.session.state.aurasTypeSelected][tonumber(info[#info-1])][8] end,
	set = function(info, value) 
		local arr = BCT.session.db.auras[BCT.session.state.aurasTypeSelected]
		arr[tonumber(info[#info-1])][8] = value
		BCT.SetReservedBuffs()
	end,
}

local GetRemoveSpell = {
	order = 9,
	name = "Remove",
	type = 'execute',
	func = function(info)
		local arr = BCT.session.db.auras[BCT.session.state.aurasTypeSelected]
		arr[tonumber(info[#info-1])] = nil
	end,
}

local GetCounts = {
	order = 7,
	type = "toggle",
	name = "Count towards cap",
	width = "full",
	get = function(info) return BCT.session.db.auras[BCT.session.state.aurasTypeSelected][tonumber(info[#info-1])][4] end,
	set = function(info, value)
		local arr = BCT.session.db.auras[BCT.session.state.aurasTypeSelected]
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
	reserved = GetReserved,
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
	if not BCT.session.state.cleanedup then BCT.CleanUp() end

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
				name = "Settings",
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
							BCT.UpdateWindowState()
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
					enableWindow = {
						name = function()
							if BCT.session.db.window.enable then
								return "Hide"
							else
								return "Show"
							end
						end,
						type = 'execute',
						order = 3,	
						width = .6,					
						func = function()
							BCT.session.db.window.enable = not BCT.session.db.window.enable
							BCT.UpdateWindowState()
						end,
					},
					enableBCT = {
						name = function()
							if BCT.session.db.loading.enabled then
								return "Disable"
							else
								return "Enable"
							end
							BCT.UpdateWindowState()
						end,
						type = 'execute',
						order = 3,	
						width = .6,					
						func = function()
							BCT.session.db.loading.enabled = not BCT.session.db.loading.enabled
							BCT.UpdateWindowState()
						end,
					},
					txt = {
						order = 4,
						type = "group",
						name = "Frames",
						childGroups = "tab",
						args = {
							anchorGroup = {
								name = "Anchor",
								desc = "",
								type = 'group',
								order = 0,					
								args = {
									width = {
										order = 4,
										name = "Width",
										desc = "",
										type = "range",
										min = 1, max = 2140, step = 1,
										get = function(info) return BCT.session.db.window.anchor.width end,
										set = function(info, value) 
											BCT.session.db.window.anchor.width = tonumber(value)
											BCT.session.db.window.body.width = tonumber(value)
											BCT.UpdateWindowState()
										end,
									},
									height = {
										order = 5,
										name = "Height",
										desc = "",
										type = "range",
										min = 1, max = 1200, step = 1,
										get = function(info) return BCT.session.db.window.anchor.height end,
										set = function(info, value) 
											BCT.session.db.window.anchor.height = tonumber(value)
											BCT.session.db.window.body.height = tonumber(value)
											BCT.UpdateWindowState()
										end,
									},
									clickthrough = {
										name = "Click-through",
										desc = "Enabling will break Mouse Over",
										type = 'toggle',
										order = 6,					
										width = "normal",			
										get = function(info) return BCT.session.db.window.anchor.clickthrough end,
										set = function(info, value) 
											BCT.session.db.window.anchor.clickthrough = not BCT.session.db.window.anchor.clickthrough
											BCT.UpdateWindowState()
										end,
									},
								},
							},
							titleGroup = {
								name = "Title",
								desc = "",
								type = 'group',
								order = 1,					
								args = {
									Text = {
										name = "Text",
										type = "input",
										order = 11,
										width = "normal",	
										get = function(info) return BCT.session.db.window.anchor.value end,
										set = function(info, value) 
											BCT.session.db.window.anchor.value = value
											BCT.UpdateWindowState()
										end,
									},	
									counter = {
										type = "select",
										order = 12,
										name = "Counter",									
										values = {
											["None"] = "None",
											["3/32"] = "3/32",
											["3"] = "3",
										},	
										get = function(_, value) return BCT.session.db.window.anchor.counter end, 
										set = function(_, value) 
											BCT.session.db.window.anchor.counter = value
											BCT.UpdateWindowState()
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
									spacer = GetSpacer(10),
									xoff = {
										order = 8,
										name = "X Offset",
										desc = "",
										type = "range",
										min = -2140, max = 2140, step = 1,
										get = function(info) return BCT.session.db.window.anchor.x_offset end,
										set = function(info, value) 
											BCT.session.db.window.anchor.x_offset = tonumber(value)
											BCT.UpdateWindowState()
										end,
									},
									yoff = {
										order = 9,
										name = "Y Offset",
										desc = "",
										type = "range",
										min = -2140, max = 1200, step = 1,
										get = function(info) return BCT.session.db.window.anchor.y_offset end,
										set = function(info, value) 
											BCT.session.db.window.anchor.y_offset = tonumber(value)
											BCT.UpdateWindowState()
										end,
									},
								},
							},
							bodyGroup = {
								name = "Body",
								desc = "",
								type = 'group',
								order = 2,					
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
										desc = "Does not work with Click-through",
										type = 'toggle',
										order = 7,					
										width = "normal",			
										get = function(info) return BCT.session.db.window.body.mouseover end,
										set = function(info, value) 
											BCT.session.db.window.body.mouseover = not BCT.session.db.window.body.mouseover
											BCT.UpdateWindowState()
										end,
									},
									growup = {
										name = "Grow Up",
										desc = "",
										type = 'toggle',
										order = 8,					
										width = "normal",			
										get = function(info) return BCT.session.db.window.body.growup end,
										set = function(info, value) 
											BCT.session.db.window.body.growup = not BCT.session.db.window.body.growup
											BCT.UpdateWindowState()
										end,
									},
									grouplines = {
										name = "Group Tracking",
										desc = "",
										type = 'toggle',
										order = 9,					
										width = "normal",			
										get = function(info) return BCT.session.db.window.body.group_lines end,
										set = function(info, value) 
											BCT.session.db.window.body.group_lines = not BCT.session.db.window.body.group_lines
											BCT.UpdateWindowState()
										end,
									},
									xoff = {
										order = 4,
										name = "X Offset",
										desc = "",
										type = "range",
										min = -2140, max = 2140, step = 1,
										get = function(info) return BCT.session.db.window.body.x_offset end,
										set = function(info, value) 
											BCT.session.db.window.body.x_offset = tonumber(value)
											BCT.UpdateWindowState()
										end,
									},
									yoff = {
										order = 5,
										name = "Y Offset",
										desc = "",
										type = "range",
										min = -2140, max = 1200, step = 1,
										get = function(info) return BCT.session.db.window.body.y_offset end,
										set = function(info, value) 
											BCT.session.db.window.body.y_offset = tonumber(value)
											BCT.UpdateWindowState()
										end,
									},
									spacer = GetSpacer(6),
									text = {
										name = "Texts",
										desc = "",
										type = 'multiselect',
										order = 10,
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
							announcer = {
								order = 5,
								type = "group",
								name = "Announcer",
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
					raid = {
						order = 7,
						type = "group",
						name = "Direct Heal Indicator",
						args = {
							introo = {
								name = "Counts total and reserved raid member buffs. If a raid members values are at or above the set amounts a glow is applied to his raidframe.",
								type = "description",
								order = 0,
							},
							capAmnt = {
								name = "Buff Threshold",
								type = "input",
								desc = "Superseedes Reserve Glow",
								order = 2,
								width = .6,	
								get = function(info) return tostring(BCT.session.db.highlighter.cap) end,
								set = function(info, value) 
									local inp = tonumber(value)
									if 'number' == type(inp) and inp > 0 then
										BCT.session.db.highlighter.cap = inp
									else
										print("BCT: You must input a positive number higher than 0")
									end
								end,
							},	
							cap = {
								order = 3,
								type = "toggle",
								name = "Enable",
								width = "normal",
								get = function(info) return BCT.session.db.highlighter.enabledCap end,
								set = function(info, value) 
									BCT.session.db.highlighter.enabledCap = not BCT.session.db.highlighter.enabledCap
									if BCT.session.db.highlighter.enabledCap then
										BCT.RangeChecker()
										BCT.UpdateRaid(UnitName("player"))
										BCT.UpdateRaid()
										BCT.SetRangeTicker()
									else
										BCT.DisableGlow()
									end
								end,
							},
							colorCap = {
								order = 1,
								type = "color",
								name = "",
								width = 0.2,
								get = function() 
									local r = BCT.session.db.highlighter.glowColorCap[1]
									local g = BCT.session.db.highlighter.glowColorCap[2]
									local b = BCT.session.db.highlighter.glowColorCap[3]
									return r, g, b
								end,
								set = function(info,r,g,b,a) 
									BCT.session.db.highlighter.glowColorCap[1] = r
									BCT.session.db.highlighter.glowColorCap[2] = g
									BCT.session.db.highlighter.glowColorCap[3] = b
								end,
							},
							spacerOne = GetSpacer(4),
							glowAmnt = {
								name = "Reserved Slots",
								type = "input",
								desc = "Buffs such as absorbs and HoTs which share slots",
								order = 6,
								width = .6,	
								get = function(info) return tostring(BCT.session.db.highlighter.buffer) end,
								set = function(info, value) 
									local inp = tonumber(value)
									if 'number' == type(inp) and inp > 0 then
										BCT.session.db.highlighter.buffer = inp
									else
										print("BCT: You must input a positive number higher than 0")
									end
								end,
							},	
							glow = {
								order = 7,
								type = "toggle",
								name = "Enable",
								width = "normal",
								get = function(info) return BCT.session.db.highlighter.enabled end,
								set = function(info, value) 
									BCT.session.db.highlighter.enabled = not BCT.session.db.highlighter.enabled
									if BCT.session.db.highlighter.enabled then
										BCT.RangeChecker()
										BCT.UpdateRaid(UnitName("player"))
										BCT.UpdateRaid()
										BCT.SetRangeTicker()
									else
										BCT.DisableGlow()
									end
								end,
							},
							colorGlow = {
								order = 5,
								type = "color",
								name = "",
								width = 0.2,
								get = function() 
									local r = BCT.session.db.highlighter.glowColor[1]
									local g = BCT.session.db.highlighter.glowColor[2]
									local b = BCT.session.db.highlighter.glowColor[3]
									return r, g, b
								end,
								set = function(info,r,g,b,a) 
									BCT.session.db.highlighter.glowColor[1] = r
									BCT.session.db.highlighter.glowColor[2] = g
									BCT.session.db.highlighter.glowColor[3] = b
								end,
							},
							spacerTwo = GetSpacer(8),
							updateFreq = {
								order = 9,
								name = "Range Check Frequency",
								desc = "Seconds between range checks",
								type = "range",
								min = 0.1, max = 1, step = 0.1,
								get = function(info) return tonumber(BCT.session.db.highlighter.rangeCheckFreq) end,
								set = function(info, value) 
									local inp = tonumber(value)
									if 'number' == type(inp) and inp > 0 then
										BCT.session.db.highlighter.rangeCheckFreq = inp
										BCT.SetRangeTicker()
									else
										print("BCT: You must input a positive number higher than 0")
									end
								end,
							},
							spacerThree = GetSpacer(10),
							particles = {
								order = 11,
								name = "Particles",
								desc = "",
								type = "range",
								min = 1, max = 50, step = 1,
								get = function(info) return tonumber(BCT.session.db.highlighter.glowParticles) end,
								set = function(info, value) 
									local inp = tonumber(value)
									if 'number' == type(inp) and inp > 0 then
										BCT.session.db.highlighter.glowParticles = inp
									else
										print("BCT: You must input a positive number higher than 0")
									end
								end,
							},
							freq = {
								order = 12,
								name = "Frequency",
								desc = "Checks per second",
								type = "range",
								min = 0, max = 1, step = 0.05,
								get = function(info) return tonumber(BCT.session.db.highlighter.glowFrequency) end,
								set = function(info, value) 
									local inp = tonumber(value)
									if 'number' == type(inp) and inp > 0 then
										BCT.session.db.highlighter.glowFrequency = inp
									else
										print("BCT: You must input a positive number")
									end
								end,
							},
							--[[
							scale = {
								order = 11,
								name = "Scale",
								desc = "",
								type = "range",
								min = 1, max = 10, step = 1,
								get = function(info) return tonumber(BCT.session.db.highlighter.glowScale) end,
								set = function(info, value) 
									local inp = tonumber(value)
									if 'number' == type(inp) and inp > 0 then
										BCT.session.db.highlighter.glowScale = inp
									else
										print("BCT: You must input a positive number higher than 0")
									end
								end,
							},
							--]]
							length = {
								order = 13,
								name = "Length",
								desc = "",
								type = "range",
								min = 0, max = 20, step = 1,
								get = function(info) return tonumber(BCT.session.db.highlighter.glowLength) end,
								set = function(info, value) 
									local inp = tonumber(value)
									if 'number' == type(inp) and inp >= 0 then
										BCT.session.db.highlighter.glowLength = inp
									else
										print("BCT: You must input a positive number")
									end
								end,
							},
							thickness = {
								order = 14,
								name = "Thickness",
								desc = "",
								type = "range",
								min = 1, max = 10, step = 1,
								get = function(info) return tonumber(BCT.session.db.highlighter.glowThickness) end,
								set = function(info, value) 
									local inp = tonumber(value)
									if 'number' == type(inp) and inp > 0 then
										BCT.session.db.highlighter.glowThickness = inp
									else
										print("BCT: You must input a positive number")
									end
								end,
							},
							xoffset = {
								order = 15,
								name = "X Offset",
								desc = "",
								type = "range",
								min = -2140, max = 2140, step = 1,
								get = function(info) return tonumber(BCT.session.db.highlighter.glowxOffset) end,
								set = function(info, value) 
									local inp = tonumber(value)
									if 'number' == type(inp) then
										BCT.session.db.highlighter.glowxOffset = inp
									end
								end,
							},
							yoffset = {
								order = 16,
								name = "Y Offset",
								desc = "",
								type = "range",
								min = -2140, max = 2140, step = 1,
								get = function(info) return tonumber(BCT.session.db.highlighter.glowyOffset) end,
								set = function(info, value) 
									local inp = tonumber(value)
									if 'number' == type(inp) then
										BCT.session.db.highlighter.glowyOffset = inp
									end
								end,
							},
							border = {
								order = 17,
								type = "toggle",
								name = "Border",
								width = "double",
								get = function(info) return BCT.session.db.highlighter.glowBorder end,
								set = function(info, value) 
									BCT.session.db.highlighter.glowBorder = not BCT.session.db.highlighter.glowBorder
								end,
							},
						},
					},
					loading = {
						order = 8,
						type = "group",
						name = "Loading",
						args = {
							overall = {
								order = 1,
								type = "group",
								name = "Addon",
								desc = "Enable/Disable BCT",
								args = {
									State = {
										name = "Group Type",
										desc = "Group Type",
										type = 'multiselect',
										order = 1,					
										values = {
											["Solo"] = "Solo",
											["Group"] = "Group",
											["Raid"] = "Raid",
											["Battleground"] = "Battleground",
										},	
										get = function(_, value) return BCT.session.db.loading.groupState[value] end, 
										set = function(_, value, state) 
											BCT.session.db.loading.groupState[value] = state
											
											local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
											local groupState = (not IsInGroup()) and "Solo" or 
												((IsInGroup() and not IsInRaid()) and "Group" or "Raid")
											
											if BCT.session.db.loading.instanceState[tonumber(maxPlayers)] and
												BCT.session.db.loading.groupState[(instanceType == "pvp" and "Battleground" or groupState)] then
												BCT.session.db.loading.enabled = true
											else
												BCT.session.db.loading.enabled = false
											end
											
											BCT.SetInCombatBlacklistingMacro()
											BCT.UpdateWindowState()
										end,
									},
									instanceState = {
										name = "Instance Type",
										desc = "Instance Type",
										type = 'multiselect',
										order = 2,	
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
											
											local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
											local groupState = (not IsInGroup()) and "Solo" or 
												((IsInGroup() and not IsInRaid()) and "Group" or "Raid")
											
											if BCT.session.db.loading.instanceState[tonumber(maxPlayers)] and
												BCT.session.db.loading.groupState[(instanceType == "pvp" and "Battleground" or groupState)] then
												BCT.session.db.loading.enabled = true
											else
												BCT.session.db.loading.enabled = false
											end
											
											BCT.SetInCombatBlacklistingMacro()
											BCT.UpdateWindowState()
										end,
									},
								},
							},
							blacklisting = {
								order = 3,
								type = "group",
								name = "Blacklisting",
								desc = "Enable/Disable Blacklisting",
								args = {
									StateBlacklisting = {
										name = "Group Type",
										desc = "Group Type",
										type = 'multiselect',
										order = 4,					
										values = {
											["Solo"] = "Solo",
											["Group"] = "Group",
											["Raid"] = "Raid",
											["Battleground"] = "Battleground",
										},	
										get = function(_, value) return BCT.session.db.loading.groupStateBL[value] end, 
										set = function(_, value, state) 
											BCT.session.db.loading.groupStateBL[value] = state
											
											local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
											local groupState = (not IsInGroup()) and "Solo" or 
												((IsInGroup() and not IsInRaid()) and "Group" or "Raid")
											
											if BCT.session.db.loading.instanceStateBL[tonumber(maxPlayers)] and
												BCT.session.db.loading.groupStateBL[(instanceType == "pvp" and "Battleground" or groupState)] then
												BCT.session.db.loading.enabledBL = true
											else
												BCT.session.db.loading.enabledBL = false
											end
											
											BCT.SetInCombatBlacklistingMacro()
										end,
									},
									instanceStateBlacklisting = {
										name = "Instance Type",
										desc = "Instance Type",
										type = 'multiselect',
										order = 5,	
										values = {
											[0] = "Outside",
											[5] = "5 Man Instance",
											[10] = "10 Man Instance",
											[20] = "20 Man Instance",
											[40] = "40 Man Instance",
										},	
										get = function(_, value) return BCT.session.db.loading.instanceStateBL[value] end, 
										set = function(_, value, state) 
											BCT.session.db.loading.instanceStateBL[value] = state
											
											local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
											local groupState = (not IsInGroup()) and "Solo" or 
												((IsInGroup() and not IsInRaid()) and "Group" or "Raid")
											
											if BCT.session.db.loading.instanceStateBL[tonumber(maxPlayers)] and
												BCT.session.db.loading.groupStateBL[(instanceType == "pvp" and "Battleground" or groupState)] then
												BCT.session.db.loading.enabledBL = true
											else
												BCT.session.db.loading.enabledBL = false
											end
											
											BCT.SetInCombatBlacklistingMacro()
										end,
									},
								},
							},
							announcer = {
								order = 2,
								type = "group",
								name = "Announcements",
								desc = "Enable/Disable Announcements",
								args = {
									StateBlacklisting = {
										name = "Group Type",
										desc = "Group Type",
										type = 'multiselect',
										order = 4,					
										values = {
											["Solo"] = "Solo",
											["Group"] = "Group",
											["Raid"] = "Raid",
											["Battleground"] = "Battleground",
										},	
										get = function(_, value) return BCT.session.db.loading.groupStateAnn[value] end, 
										set = function(_, value, state) 
											BCT.session.db.loading.groupStateAnn[value] = state
											
											local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
											local groupState = (not IsInGroup()) and "Solo" or 
												((IsInGroup() and not IsInRaid()) and "Group" or "Raid")
											
											if BCT.session.db.loading.instanceStateAnn[tonumber(maxPlayers)] and
												BCT.session.db.loading.groupStateAnn[(instanceType == "pvp" and "Battleground" or groupState)] then
												BCT.session.db.loading.enabledAnn = true
											else
												BCT.session.db.loading.enabledAnn = false
											end
										end,
									},
									instanceStateBlacklisting = {
										name = "Instance Type",
										desc = "Instance Type",
										type = 'multiselect',
										order = 5,	
										values = {
											[0] = "Outside",
											[5] = "5 Man Instance",
											[10] = "10 Man Instance",
											[20] = "20 Man Instance",
											[40] = "40 Man Instance",
										},	
										get = function(_, value) return BCT.session.db.loading.instanceStateBL[value] end, 
										set = function(_, value, state) 
											BCT.session.db.loading.instanceStateBL[value] = state
											
											local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
											local groupState = (not IsInGroup()) and "Solo" or 
												((IsInGroup() and not IsInRaid()) and "Group" or "Raid")
											
											if BCT.session.db.loading.instanceStateBL[tonumber(maxPlayers)] and
												BCT.session.db.loading.groupStateBL[(instanceType == "pvp" and "Battleground" or groupState)] then
												BCT.session.db.loading.enabledBL = true
											else
												BCT.session.db.loading.enabledBL = false
											end
										end,
									},
								},
							},
							frames = {
								order = 4,
								type = "group",
								name = "Text Frames",
								desc = "Show/Hide Text Frames",
								args = {
									StateBlacklisting = {
										name = "Group Type",
										desc = "Group Type",
										type = 'multiselect',
										order = 4,
										values = {
											["Solo"] = "Solo",
											["Group"] = "Group",
											["Raid"] = "Raid",
											["Battleground"] = "Battleground",
										},	
										get = function(_, value) return BCT.session.db.loading.groupStateFrames[value] end, 
										set = function(_, value, state) 
											BCT.session.db.loading.groupStateFrames[value] = state
											
											local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
											local groupState = (not IsInGroup()) and "Solo" or 
												((IsInGroup() and not IsInRaid()) and "Group" or "Raid")
											
											if BCT.session.db.loading.instanceStateFrames[tonumber(maxPlayers)] and
												BCT.session.db.loading.groupStateFrames[(instanceType == "pvp" and "Battleground" or groupState)] then
												BCT.session.db.loading.enabledFrames = true
											else
												BCT.session.db.loading.enabledFrames = false
											end
											
											BCT.UpdateWindowState()
										end,
									},
									instanceStateBlacklisting = {
										name = "Instance Type",
										desc = "Instance Type",
										type = 'multiselect',
										order = 5,	
										values = {
											[0] = "Outside",
											[5] = "5 Man Instance",
											[10] = "10 Man Instance",
											[20] = "20 Man Instance",
											[40] = "40 Man Instance",
										},	
										get = function(_, value) return BCT.session.db.loading.instanceStateFrames[value] end, 
										set = function(_, value, state) 
											BCT.session.db.loading.instanceStateFrames[value] = state
											
											local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
											local groupState = (not IsInGroup()) and "Solo" or 
												((IsInGroup() and not IsInRaid()) and "Group" or "Raid")
											
											if BCT.session.db.loading.instanceStateFrames[tonumber(maxPlayers)] and
												BCT.session.db.loading.groupStateFrames[(instanceType == "pvp" and "Battleground" or groupState)] then
												BCT.session.db.loading.enabledFrames = true
											else
												BCT.session.db.loading.enabledFrames = false
											end
											
											BCT.UpdateWindowState()
										end,
									},
								},
							},
							highlightning = {
								order = 4,
								type = "group",
								name = "Direct Heal Indicator",
								desc = "Enable/Disable Direct Heal Indicator",
								args = {
									StateBlacklisting = {
										name = "Group Type",
										desc = "Group Type",
										type = 'multiselect',
										order = 4,
										values = {
											["Solo"] = "Solo",
											["Group"] = "Group",
											["Raid"] = "Raid",
											["Battleground"] = "Battleground",
										},	
										get = function(_, value) return BCT.session.db.loading.groupStateHl[value] end, 
										set = function(_, value, state) 
											BCT.session.db.loading.groupStateHl[value] = state
											
											local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
											local groupState = (not IsInGroup()) and "Solo" or 
												((IsInGroup() and not IsInRaid()) and "Group" or "Raid")
											
											if BCT.session.db.loading.instanceStateHl[tonumber(maxPlayers)] and
												BCT.session.db.loading.groupStateHl[(instanceType == "pvp" and "Battleground" or groupState)] then
												BCT.session.db.loading.enabledHl = true
											else
												BCT.session.db.loading.enabledHl = false
											end
											
											BCT.UpdateWindowState()
										end,
									},
									instanceStateBlacklisting = {
										name = "Instance Type",
										desc = "Instance Type",
										type = 'multiselect',
										order = 5,	
										values = {
											[0] = "Outside",
											[5] = "5 Man Instance",
											[10] = "10 Man Instance",
											[20] = "20 Man Instance",
											[40] = "40 Man Instance",
										},	
										get = function(_, value) return BCT.session.db.loading.instanceStateHl[value] end, 
										set = function(_, value, state) 
											BCT.session.db.loading.instanceStateHl[value] = state
											
											local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
											local groupState = (not IsInGroup()) and "Solo" or 
												((IsInGroup() and not IsInRaid()) and "Group" or "Raid")
											
											if BCT.session.db.loading.instanceStateHl[tonumber(maxPlayers)] and
												BCT.session.db.loading.groupStateHl[(instanceType == "pvp" and "Battleground" or groupState)] then
												BCT.session.db.loading.enabledHl = true
											else
												BCT.session.db.loading.enabledHl = false
											end
											
											BCT.UpdateWindowState()
										end,
									},
								},
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
						name = "All visible auras are automatically counted and does not have to be added. All ranks are treated alike. Auras and other permanent buffs can be tracked, but blacklisting them will not do anything." ..
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
						values = {
							[BCT.BUFF] = "Buffs",
							[BCT.DEBUFF] = "Debuffs",
							[BCT.ENCHANT] = "Enchants",
							[BCT.OTHER] = "Other",
						},
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
							elseif BCT.session.state.aurasTypeSelected == BCT.OTHER then
								return {
									[0] = "All",
									[BCT.TALENT] = "Talent",
									[BCT.CLASS] = "Class",
									[BCT.PROFESSION] = "Profession",
								}
							elseif BCT.session.state.aurasTypeSelected == BCT.ENCHANT then
								return {
									[0] = "All",
									--[BCT.HEAD] = "Head",
									--[BCT.SHOULDERS] = "Shoulders",
									--[BCT.LEGS] = "Legs",
									--[BCT.FEET] = "Feet",
									--[BCT.WRIST] = "Wrist",
									--[BCT.HANDS] = "Hands",
									--[BCT.BACK] = "Back",
									--[BCT.MH] = "Main Hand",
									--[BCT.OH] = "Off Hand",
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
							["reserved"] = "Reserved",
							["class"] = UnitClass("player"),
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
						get = function(info) return BCT.session.state.aurasSearch end,
						set = function(info, value) BCT.session.state.aurasSearch = value end,
					},	
					templates = {
						name = "Apply Blacklist",
						desc = "Will overwrite existing blacklist",
						type = 'select',
						order = 7,
						style = "dropdown",
						values = function() 
							local tmp = {}
							for k, v in pairs(BCT.templates) do
								tmp[k] = k
							end
							return tmp
						end,
						get = function(info, value)	return end, 
						set = function(info, value) 
							for k, v in pairs(BCT.session.db.auras[BCT.BUFF]) do
								v[5] = false
							end
							local keys = BCT.templates[value]
							for k, v in pairs(keys) do
								BCT.session.db.auras[BCT.BUFF][v][5] = true
							end
						end,
					},
					export = {
						name = "Export to String",
						desc = "Export blacklisted IDs",
						type = 'execute',
						order = 8,
						width = "normal",
						func = function()
							StaticPopupDialogs["BCT_EXPORT_TO_STRING"] = {
							text = "Export Blacklisting IDs",
							button1 = "Ok",
							OnShow = function(self)
								local tmp = ""
								for k, v in pairs(BCT.session.db.auras[BCT.BUFF]) do
									if v[5] == true then tmp = tmp .. "," .. k end
								end
								self.editBox:SetText(tmp)
							end,
							OnAccept = function()
							end,
							timeout = 0,
							hasEditBox = true,
							whileDead = true,
							hideOnEscape = true,
							}
						
							StaticPopup_Show ("BCT_EXPORT_TO_STRING")
						end,
					},
					import = {
						name = "Import from String",
						desc = "Will overwrite existing blacklisting",
						type = 'execute',
						order = 9,
						width = "normal",
						func = function()
							StaticPopupDialogs["BCT_IMPORT_FROM_STRING"] = {
							text = "Import Blacklisting IDs",
							button1 = "Ok",
							OnShow = function(self)
							end,
							OnAccept = function(self)
								local tmp = {}
								for word in string.gmatch(self.editBox:GetText(), '([^,]+)') do
									table.insert(tmp, tonumber(word))
								end
	
								for k, v in pairs(BCT.session.db.auras[BCT.BUFF]) do
									v[5] = false
								end
								
								for k, v in pairs(tmp) do
									if BCT.session.db.auras[BCT.BUFF][v] then
										BCT.session.db.auras[BCT.BUFF][v][5] = true
									else
										print("BCT: " .. (GetSpellInfo(v) or "N/A") .. " (" .. v .. ")" .. " missing in db.")
									end
								end
								InterfaceOptionsFrame_OpenToCategory(BCT.optionsFrames.Auras)
							end,
							timeout = 0,
							hasEditBox = true,
							whileDead = true,
							hideOnEscape = true,
							}
						
							StaticPopup_Show ("BCT_IMPORT_FROM_STRING")
						end,
					},
					counter = {
						name = function() return BCT.session.state.aurasCounter end,
						type = "description",
						order = 100,
					},	
				},
			},
			Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(BCT.db)
		},
	}

	local arr = BCT.session.db.auras[BCT.session.state.aurasTypeSelected]
	
	local _, _, classId = UnitClass("player")
	
	BCT.session.state.aurasCounter = 0
	
	local function getKeysSortedByValue(tbl, sortFunction)

		local keys = {}
		for key in pairs(tbl) do
			
			if floor(arr[key][6]) == BCT.session.state.aurasTypeSelected and
				(BCT.session.state.aurasSourceSelected ~= BCT.CONSUMABLE and true or arr[key][6] == BCT.CONSUMABLE) and
				(BCT.session.state.aurasSourceSelected ~= BCT.WORLDBUFF and true or arr[key][6] == BCT.WORLDBUFF) and
				(BCT.session.state.aurasSourceSelected ~= BCT.PLAYERBUFF and true or arr[key][6] == BCT.PLAYERBUFF) and
				(BCT.session.state.aurasSourceSelected ~= BCT.HOLIDAY and true or arr[key][6] == BCT.HOLIDAY) and
				(BCT.session.state.aurasSourceSelected ~= BCT.PERSONALS and true or arr[key][6] == BCT.PERSONALS) and

				(BCT.session.state.aurasSourceSelected ~= BCT.TALENT and true or arr[key][6] == BCT.TALENT) and
				(BCT.session.state.aurasSourceSelected ~= BCT.CLASS and true or arr[key][6] == BCT.CLASS) and
				(BCT.session.state.aurasSourceSelected ~= BCT.PROFESSION and true or arr[key][6] == BCT.PROFESSION) and
				
				(BCT.session.state.aurasSourceSelected ~= BCT.HEAD and true or arr[key][6] == BCT.HEAD) and
				(BCT.session.state.aurasSourceSelected ~= BCT.SHOULDERS and true or arr[key][6] == BCT.SHOULDERS) and
				(BCT.session.state.aurasSourceSelected ~= BCT.LEGS and true or arr[key][6] == BCT.LEGS) and
				(BCT.session.state.aurasSourceSelected ~= BCT.FEET and true or arr[key][6] == BCT.FEET) and
				(BCT.session.state.aurasSourceSelected ~= BCT.WRIST and true or arr[key][6] == BCT.WRIST) and
				(BCT.session.state.aurasSourceSelected ~= BCT.HANDS and true or arr[key][6] == BCT.HANDS) and
				(BCT.session.state.aurasSourceSelected ~= BCT.BACK and true or arr[key][6] == BCT.BACK) and
				(BCT.session.state.aurasSourceSelected ~= BCT.MH and true or arr[key][6] == BCT.MH) and
				(BCT.session.state.aurasSourceSelected ~= BCT.OH and true or arr[key][6] == BCT.OH) and
				
				(BCT.session.state.aurasFilter ~= "blacklisted" and true or arr[key][5]) and
				(BCT.session.state.aurasFilter ~= "tracked" and true or arr[key][3]) and
				(BCT.session.state.aurasFilter ~= "reserved" and true or arr[key][8]) and
				(BCT.session.state.aurasFilter ~= "class" and true or arr[key][9] == tonumber(classId))-- and
				
				--(arr[key][9] == nil and true or arr[key][9] == tonumber(classId))
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
		
		if BCT.session.state.aurasTypeSelected == BCT.OTHER or
			BCT.session.state.aurasTypeSelected == BCT.ENCHANT then spellIcon = nil end
			
		if not (BCT.session.state.aurasTypeSelected == BCT.OTHER or 
			spellType == BCT.PLAYERBUFF or
			spellType == BCT.PERSONALS) then
			spellName = spellName .. " (" .. key .. ")"
		end

		--local classColors = {
		--	[1] = "|cffC79C6E", -- Warrior	WARRIOR
		--	[2] = "|cffF58CBA", --Paladin	PALADIN
		--	[3] = "|cffA9D271", --Hunter	HUNTER
		--	[4] = "|cffFFF569", --Rogue	ROGUE
		--	[5] = "|cffFFFFFF", --Priest	PRIEST
		--	[7] = "|cff0070DE", --Shaman	SHAMAN
		--	[9] = "|cff40C7EB", --Mage	MAGE
		--	[9] = "|cff8787ED", -- Warlock	WARLOCK
		--	[11] = "|cffFF7D0A", --Druid	DRUID
		--}
		
		-- add class color
		--if spellType == BCT.TALENT and arr[key][9] ~= nil then
		--	spellName = classColors[arr[key][9]] .. spellName .. "|r"
		--end

		if string.match(spellName:lower(), BCT.session.state.aurasSearch) then
			optionsTbl.args.Auras.args[tostring(key)] = {
				order = i,
				type = "group",
				name = spellName,
				icon = spellIcon,
				args = groups[BCT.session.state.aurasTypeSelected]
			}
			BCT.session.state.aurasCounter = BCT.session.state.aurasCounter + 1
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
BCT.optionsFrames.Setup = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BCT", "General", "BCT", "Setup")
BCT.optionsFrames.Auras = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BCT", "Auras", "BCT", "Auras")
BCT.optionsFrames.Profiles = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BCT", "Profiles", "BCT", "Profiles")