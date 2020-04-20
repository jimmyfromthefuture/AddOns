--[[--------------------------------------------------------------------
	Plexus
	Compact party and raid unit frames.
	Copyright (c) 2006-2009 Kyle Smith (Pastamancer)
	Copyright (c) 2009-2018 Phanx <addons@phanx.net>
	All rights reserved. See the accompanying LICENSE file for details.
------------------------------------------------------------------------
	PlexusLocale-deDE.lua
	German localization
	Contributors: Alakabaster, derwanderer, Firuzz, kaybe, kunda, Leialyn, ole510
----------------------------------------------------------------------]]

if GetLocale() ~= "deDE" then return end

local _, Plexus = ...
local L = { }
Plexus.L = L

------------------------------------------------------------------------
--	PlexusCore

-- PlexusCore
L["Debugging"] = "Debuggen"
L["Debugging messages help developers or testers see what is happening inside Plexus in real time. Regular users should leave debugging turned off except when troubleshooting a problem for a bug report."] = "Debug-Nachrichten helfen Entwicklern und Testern zu sehen, was aktuell innerhalb von Grid passiert. Normale Bentzer sollten Debug-Nachrichten ausgeschaltet lassen, es sei denn, sie wollen ein Problem oder einen Fehler berichten."
L["Enable debugging messages for the %s module."] = "Debug-Nachrichten für das Modul %s aktivieren"
L["General"] = "Allgemein"
L["Module debugging menu."] = "Debug-Menü."
L["Open Plexus's options in their own window, instead of the Interface Options window, when typing /plexus or right-clicking on the minimap icon, DataBroker icon, or layout tab."] = "Die Optionen von Plexus in einem alleinstehenden Fenster anzeigen, anstatt in den Interface-Optionen. Das Fenster wird angezeigt, wenn du '/grid' in den Chat eingibst mit der rechten Maustaste auf das Minikartensymbol, DataBroker-Symbol oder Grid-Reiter klickst."
L["Output Frame"] = "Ausgabefenster"
L["Right-Click for more options."] = "Rechtsklick für Optionen."
L["Show debugging messages in this frame."] = "Debug-Nachrichten in diesem Fenster anzeigen"
L["Show minimap icon"] = "Minikartenbutton anzeigen"
L["Show the Plexus icon on the minimap. Note that some DataBroker display addons may hide the icon regardless of this setting."] = "Das Grid-Icon an der Minimap anzeigen. Beachte: Einige DataBroker-Addons können das Icon dennoch verstecken, unabhängig von dieser Einstellung."
L["Standalone options"] = "Alleinstehenden Optionen"
L["Toggle debugging for %s."] = "Aktiviere das Debuggen für %s."

------------------------------------------------------------------------
--	PlexusFrame

-- PlexusFrame
L["Adjust the font outline."] = "Den Schriftumriss anpassen."
L["Adjust the font settings"] = "Die Schriftart anpassen"
L["Adjust the font size."] = "Die Schriftgröße anpassen."
L["Adjust the height of each unit's frame."] = "Die Höhe von jedem Einheitenfenster anpassen."
L["Adjust the size of the border indicators."] = "Die Randbreite der Indikatoren anpassen."
L["Adjust the size of the center icon."] = "Die Größe des Symbols im Zentrum anpassen."
L["Adjust the size of the center icon's border."] = "Die Randbreite des Symbols im Zentrum anpassen."
L["Adjust the size of the corner indicators."] = "Die Größe der Eckenindikatoren anpassen."
L["Adjust the texture of each unit's frame."] = "Die Textur von jedem Einheitenfenster anpassen."
L["Adjust the width of each unit's frame."] = "Die Breite von jedem Einheitenfenster anpassen."
L["Always"] = "Immer"
L["Bar Options"] = "Leistenoptionen"
L["Border"] = "Rand"
L["Border Size"] = "Randbreite"
L["Bottom Left Corner"] = "Untere linke Ecke"
L["Bottom Right Corner"] = "Untere rechte Ecke"
L["Center Icon"] = "Symbol im Zentrum"
L["Center Text"] = "Text im Zentrum 1"
L["Center Text 2"] = "Text im Zentrum 2"
L["Center Text Length"] = "Länge des mittleren Textes"
L["Color the healing bar using the active status color instead of the health bar color."] = "Färbt die Heilleiste mit der Farbe des aktiven Status, anstelle der Heilleistenfarbe"
L["Corner Size"] = "Eckengröße"
L["Darken the text color to match the inverted bar."] = "Text abdunkeln, um der invertierten Leiste zu entsprechen."
L["Enable %s"] = "%s aktivieren"
L["Enable %s indicator"] = "Indikator: %s"
L["Enable Mouseover Highlight"] = "Mausberührungshervorhebung"
L["Enable right-click menu"] = "Rechtsklick-Menü einschalten"
L["Font"] = "Schriftart"
L["Font Outline"] = "Schriftumriss"
L["Font Shadow"] = "Schriftschatten"
L["Font Size"] = "Schriftgröße"
L["Frame"] = "Rahmen"
L["Frame Alpha"] = "Rahmentransparenz"
L["Frame Height"] = "Rahmenhöhe"
L["Frame Texture"] = "Rahmentextur"
L["Frame Width"] = "Rahmenbreite"
L["Healing Bar"] = "Heilleiste"
L["Healing Bar Opacity"] = "Heilleistendeckkraft"
L["Healing Bar Uses Status Color"] = "Heilleiste benutzt Statusfarbe"
L["Health Bar"] = "Gesundheitsleiste"
L["Health Bar Color"] = "Gesundheitsleistenfarbe"
L["Horizontal"] = "Horizontal"
L["Icon Border Size"] = "Symbolrandbreite"
L["Icon Cooldown Frame"] = "Symbol Cooldown-Rahmen"
L["Icon Options"] = "Symboloptionen"
L["Icon Size"] = "Symbolgröße"
L["Icon Stack Text"] = "Symbolstapeltext"
--[[Translation missing --]]
L["Indicator Bottom"] = "Indicator Bottom"
--[[Translation missing --]]
L["Indicator Bottom Left Corner"] = "Indicator Bottom Left Corner"
--[[Translation missing --]]
L["Indicator Bottom Right Corner"] = "Indicator Bottom Right Corner"
--[[Translation missing --]]
L["Indicator Left"] = "Indicator Left"
--[[Translation missing --]]
L["Indicator Right"] = "Indicator Right"
--[[Translation missing --]]
L["Indicator Top"] = "Indicator Top"
--[[Translation missing --]]
L["Indicator Top Left Corner"] = "Indicator Top Left Corner"
--[[Translation missing --]]
L["Indicator Top Right Corner"] = "Indicator Top Right Corner"
L["Indicators"] = "Indikatoren"
L["Invert Bar Color"] = "Leistenfarbe invertieren"
L["Invert Text Color"] = "Textfarbe invertieren"
L["Make the healing bar use the status color instead of the health bar color."] = "Die Heilungsleiste verwendet die Statusfarbe statt der Lebensbalkenfarbe"
L["Never"] = "Nie"
L["None"] = "Kein Umriss"
L["Number of characters to show on Center Text indicator."] = "Anzahl der Buchstaben der Indikatoren 'Text im Zentrum 1/2'."
L["OOC"] = "Außerhalb des Kampfes"
L["Options for %s indicator."] = "Optionen für den Indikator: %s."
L["Options for assigning statuses to indicators."] = "Optionen für die Status-Indikatorzuordnung."
L["Options for PlexusFrame."] = "Optionen für den Grid-Rahmen."
L["Options related to bar indicators."] = "Optionen für Leistenindikatoren."
L["Options related to icon indicators."] = "Optionen für Symbolindikatoren."
L["Options related to text indicators."] = "Optionen für Textindikatoren."
L["Orientation of Frame"] = "Ausrichtung der Statusleiste"
L["Orientation of Text"] = "Ausrichtung des Texts"
L["Set frame orientation."] = "Ausrichtung der Statusleiste festlegen."
L["Set frame text orientation."] = "Textausrichtung festlegen."
L["Sets the opacity of the healing bar."] = "Verändert die Deckkraft der Heilleiste."
L["Show the standard unit menu when right-clicking on a frame."] = "Zeige das standardmäßige Einheitenmenü bei Rechtsklick auf einen Rahmen."
L["Show Tooltip"] = "Tooltip anzeigen"
L["Show unit tooltip.  Choose 'Always', 'Never', or 'OOC'."] = "Einheiten-Tooltip anzeigen. Wähle 'Außerhalb des Kampfes', 'Immer' oder 'Nie'."
L["Statuses"] = "Status"
L["Swap foreground/background colors on bars."] = "Tauscht die Vordergrund-/Hintergrundfarbe der Leisten."
L["Text Options"] = "Textoptionen"
L["Thick"] = "Dick"
L["Thin"] = "Dünn"
L["Throttle Updates"] = "Aktualisierung drosseln"
L["Throttle updates on group changes. This option may cause delays in updating frames, so you should only enable it if you're experiencing temporary freezes or lockups when people join or leave your group."] = [=[Drosselt die Aktualisiersrate bei Gruppenänderungen auf 0,1 Sekunden (Standard: sofort).
ACHTUNG:
Diese Option kann Verzögerungen bei der Rahmenaktualisierung verursachen. Deshalb sollte man diese Option nur aktivieren, wenn man temporäre Lags oder 'Hänger' hat, wenn Spieler der Gruppe beitreten oder sie verlassen.]=]
L["Toggle center icon's cooldown frame."] = "Cooldown-Rahmen für Symbol im Zentrum ein-/ausblenden."
L["Toggle center icon's stack count text."] = "Stack-Text für Symbol im Zentrum ein-/ausblenden."
L["Toggle mouseover highlight."] = "Rahmen Hervorhebung (Mouseover Highlight) ein-/ausschalten."
L["Toggle status display."] = "Aktiviert die Anzeige dieses Status."
L["Toggle the %s indicator."] = "Aktiviert den Indikator: %s."
L["Toggle the font drop shadow effect."] = "Schriftschatten ein-/ausschalten."
L["Top Left Corner"] = "Obere linke Ecke"
L["Top Right Corner"] = "Obere rechte Ecke"
L["Vertical"] = "Vertikal"

------------------------------------------------------------------------
--	PlexusLayout

-- PlexusLayout
--[[Translation missing --]]
L["10 Player Raid Layout"] = "10 Player Raid Layout"
--[[Translation missing --]]
L["25 Player Raid Layout"] = "25 Player Raid Layout"
--[[Translation missing --]]
L["40 Player Raid Layout"] = "40 Player Raid Layout"
--[[Translation missing --]]
L["Adjust background color and alpha."] = "Adjust background color and alpha."
--[[Translation missing --]]
L["Adjust border color and alpha."] = "Adjust border color and alpha."
--[[Translation missing --]]
L["Adjust frame padding."] = "Adjust frame padding."
--[[Translation missing --]]
L["Adjust frame spacing."] = "Adjust frame spacing."
--[[Translation missing --]]
L["Adjust Plexus scale."] = "Adjust Plexus scale."
--[[Translation missing --]]
L["Adjust the extra spacing inside the layout frame, around the unit frames."] = "Adjust the extra spacing inside the layout frame, around the unit frames."
--[[Translation missing --]]
L["Adjust the spacing between individual unit frames."] = "Adjust the spacing between individual unit frames."
L["Advanced"] = "Fortgeschritten"
--[[Translation missing --]]
L["Advanced options."] = "Advanced options."
--[[Translation missing --]]
L["Allows mouse click through the Plexus Frame."] = "Allows mouse click through the Grid Plexus."
--[[Translation missing --]]
L["Alt-Click to permanantly hide this tab."] = "Alt-Click to permanantly hide this tab."
--[[Translation missing --]]
L["Always hide wrong zone groups"] = "Always hide wrong zone groups"
--[[Translation missing --]]
L["Arena Layout"] = "Arena Layout"
--[[Translation missing --]]
L["Background color"] = "Background color"
--[[Translation missing --]]
L["Background Texture"] = "Background Texture"
--[[Translation missing --]]
L["Battleground Layout"] = "Battleground Layout"
L["Beast"] = "Tier"
--[[Translation missing --]]
L["Border color"] = "Border color"
--[[Translation missing --]]
L["Border Inset"] = "Border Inset"
--[[Translation missing --]]
L["Border Size"] = "Border Size"
--[[Translation missing --]]
L["Border Texture"] = "Border Texture"
L["Bottom"] = "Unterseite"
--[[Translation missing --]]
L["Bottom Left"] = "Bottom Left"
--[[Translation missing --]]
L["Bottom Right"] = "Bottom Right"
--[[Translation missing --]]
L["By Creature Type"] = "By Creature Type"
--[[Translation missing --]]
L["By Owner Class"] = "By Owner Class"
--[[Translation missing --]]
L["ByGroup Layout Options"] = "ByGroup Layout Options"
--[[Translation missing --]]
L["Center"] = "Center"
--[[Translation missing --]]
L["Choose the layout border texture."] = "Choose the layout border texture."
--[[Translation missing --]]
L["Clamped to screen"] = "Clamped to screen"
--[[Translation missing --]]
L["Class colors"] = "Class colors"
--[[Translation missing --]]
L["Click through the Plexus Frame"] = "Click through the Plexus Frame"
--[[Translation missing --]]
L["Color for %s."] = "Color for %s."
--[[Translation missing --]]
L["Color of pet unit creature types."] = "Color of pet unit creature types."
--[[Translation missing --]]
L["Color of player unit classes."] = "Color of player unit classes."
--[[Translation missing --]]
L["Color of unknown units or pets."] = "Color of unknown units or pets."
--[[Translation missing --]]
L["Color options for class and pets."] = "Color options for class and pets."
L["Colors"] = "Farben"
--[[Translation missing --]]
L["Creature type colors"] = "Creature type colors"
L["Demon"] = "Dämon"
--[[Translation missing --]]
L["Drag this tab to move Plexus."] = "Drag this tab to move Plexus."
--[[Translation missing --]]
L["Dragonkin"] = "Dragonkin"
--[[Translation missing --]]
L["Elemental"] = "Elemental"
--[[Translation missing --]]
L["Fallback colors"] = "Fallback colors"
--[[Translation missing --]]
L["Flexible Raid Layout"] = "Flexible Raid Layout"
--[[Translation missing --]]
L["Frame lock"] = "Frame lock"
--[[Translation missing --]]
L["Frame Spacing"] = "Frame Spacing"
--[[Translation missing --]]
L["Group Anchor"] = "Group Anchor"
--[[Translation missing --]]
L["Hide when in mythic raid instance"] = "Hide when in mythic raid instance"
--[[Translation missing --]]
L["Hide when in raid instance"] = "Hide when in raid instance"
--[[Translation missing --]]
L["Horizontal groups"] = "Horizontal groups"
--[[Translation missing --]]
L["Humanoid"] = "Humanoid"
--[[Translation missing --]]
L["Layout"] = "Layout"
--[[Translation missing --]]
L["Layout Anchor"] = "Layout Anchor"
--[[Translation missing --]]
L["Layout Background"] = "Layout Background"
--[[Translation missing --]]
L["Layout Padding"] = "Layout Padding"
--[[Translation missing --]]
L["Layouts"] = "Layouts"
--[[Translation missing --]]
L["Left"] = "Left"
--[[Translation missing --]]
L["Lock Plexus to hide this tab."] = "Lock Plexus to hide this tab."
--[[Translation missing --]]
L["Locks/unlocks the Plexus for movement."] = "Locks/unlocks the Plexus for movement."
--[[Translation missing --]]
L["Not specified"] = "Not specified"
--[[Translation missing --]]
L["Options for PlexusLayout."] = "Options for PlexusLayout."
L["Padding"] = "Polsterung"
--[[Translation missing --]]
L["Party Layout"] = "Party Layout"
--[[Translation missing --]]
L["Pet color"] = "Pet color"
--[[Translation missing --]]
L["Pet coloring"] = "Pet coloring"
--[[Translation missing --]]
L["Reset Position"] = "Reset Position"
--[[Translation missing --]]
L["Resets the layout frame's position and anchor."] = "Resets the layout frame's position and anchor."
L["Right"] = "Richtig"
L["Scale"] = "Rahmen"
--[[Translation missing --]]
L["Select which layout to use when in a 10 player raid."] = "Select which layout to use when in a 10 player raid."
--[[Translation missing --]]
L["Select which layout to use when in a 25 player raid."] = "Select which layout to use when in a 25 player raid."
--[[Translation missing --]]
L["Select which layout to use when in a 40 player raid."] = "Select which layout to use when in a 40 player raid."
--[[Translation missing --]]
L["Select which layout to use when in a battleground."] = "Select which layout to use when in a battleground."
--[[Translation missing --]]
L["Select which layout to use when in a flexible raid."] = "Select which layout to use when in a flexible raid."
--[[Translation missing --]]
L["Select which layout to use when in a party."] = "Select which layout to use when in a party."
--[[Translation missing --]]
L["Select which layout to use when in an arena."] = "Select which layout to use when in an arena."
--[[Translation missing --]]
L["Select which layout to use when not in a party."] = "Select which layout to use when not in a party."
--[[Translation missing --]]
L["Set the color of pet units."] = "Set the color of pet units."
--[[Translation missing --]]
L["Set the coloring strategy of pet units."] = "Set the coloring strategy of pet units."
--[[Translation missing --]]
L["Sets where groups are anchored relative to the layout frame."] = "Sets where groups are anchored relative to the layout frame."
--[[Translation missing --]]
L["Sets where Plexus is anchored relative to the screen."] = "Sets where Plexus is anchored relative to the screen."
--[[Translation missing --]]
L["Show a tab for dragging when Plexus is unlocked."] = "Show a tab for dragging when Plexus is unlocked."
--[[Translation missing --]]
L["Show all groups"] = "Show all groups"
--[[Translation missing --]]
L["Show Frame"] = "Show Frame"
--[[Translation missing --]]
L["Show groups with all players in wrong zone."] = "Show groups with all players in wrong zone."
--[[Translation missing --]]
L["Show groups with all players offline."] = "Show groups with all players offline."
--[[Translation missing --]]
L["Show Offline"] = "Show Offline"
--[[Translation missing --]]
L["Show tab"] = "Show tab"
--[[Translation missing --]]
L["Solo Layout"] = "Solo Layout"
L["Spacing"] = "Abstand"
--[[Translation missing --]]
L["Switch between horizontal/vertical groups."] = "Switch between horizontal/vertical groups."
--[[Translation missing --]]
L["The color of unknown pets."] = "The color of unknown pets."
--[[Translation missing --]]
L["The color of unknown units."] = "The color of unknown units."
--[[Translation missing --]]
L["Toggle whether to permit movement out of screen."] = "Toggle whether to permit movement out of screen."
L["Top"] = "oben"
--[[Translation missing --]]
L["Top Left"] = "Top Left"
--[[Translation missing --]]
L["Top Right"] = "Top Right"
--[[Translation missing --]]
L["Undead"] = "Undead"
--[[Translation missing --]]
L["Unknown Pet"] = "Unknown Pet"
--[[Translation missing --]]
L["Unknown Unit"] = "Unknown Unit"
--[[Translation missing --]]
L["Use the 40 Player Raid layout when in a raid group outside of a raid instance, instead of choosing a layout based on the current Raid Difficulty setting."] = "Use the 40 Player Raid layout when in a raid group outside of a raid instance, instead of choosing a layout based on the current Raid Difficulty setting."
--[[Translation missing --]]
L["Using Fallback color"] = "Using Fallback color"
--[[Translation missing --]]
L["World Raid as 40 Player"] = "World Raid as 40 Player"
--[[Translation missing --]]
L["Wrong Zone"] = "Wrong Zone"

------------------------------------------------------------------------
--	PlexusLayoutLayouts

-- PlexusLayoutLayouts
L["By Class 10"] = "10er nach Klasse"
L["By Class 10 w/Pets"] = "10er nach Klasse mit Begleitern"
L["By Class 25"] = "25er nach Klasse"
L["By Class 25 w/Pets"] = "25er nach Klasse mit Begleitern"
L["By Class 40"] = "40er nach Klasse"
L["By Class 40 w/Pets"] = "40er nach Klasse mit Begleitern"
L["By Group 10"] = "10er nach Gruppe"
L["By Group 10 w/Pets"] = "10er nach Gruppe mit Begleitern"
L["By Group 15"] = "15er nach Gruppe"
L["By Group 15 w/Pets"] = "15er nach Gruppe mit Begleitern"
L["By Group 25"] = "25er nach Gruppe"
L["By Group 25 w/Pets"] = "25er nach Gruppe mit Begleitern"
L["By Group 25 w/Tanks"] = "25er nach Gruppe mit Tanks"
L["By Group 40"] = "40er nach Gruppe"
L["By Group 40 w/Pets"] = "40er nach Gruppe mit Begleitern"
L["By Group 5"] = "5er nach Gruppe"
L["By Group 5 w/Pets"] = "5er nach Gruppe mit Begleitern"
L["None"] = "Ausblenden"

------------------------------------------------------------------------
--	PlexusLDB

-- PlexusLDB
L["Click to toggle the frame lock."] = "Linksklick, um Grid zu entsperren."

------------------------------------------------------------------------
--	PlexusStatus

-- PlexusStatus
L["Color"] = "Farbe"
L["Color for %s"] = "Farbe für %s"
L["Enable"] = "Aktivieren"
L["Opacity"] = "Deckkraft"
L["Options for %s."] = "Optionen für %s."
L["Priority"] = "Priorität"
L["Priority for %s"] = "Priorität für %s"
L["Range filter"] = "Entfernungsfilter"
L["Reset class colors"] = "Klassenfarben zurücksetzen"
L["Reset class colors to defaults."] = "Klassenfarben auf Standard zurücksetzen."
L["Show status only if the unit is in range."] = "Zeigen Sie den Status nur, wenn die Einheit in Reichweite befindet."
L["Status"] = "Status"
L["Status: %s"] = "Status: %s"
L["Text"] = "Text"
L["Text to display on text indicators"] = "Text, der in einem Textindikator angezeigt wird"

------------------------------------------------------------------------
--	PlexusStatusAbsorbs

-- PlexusStatusAbsorbs
L["Absorbs"] = "Absorptionen"
L["Only show total absorbs greater than this percent of the unit's maximum health."] = "Nur Absorptionen anzeigen, die größer sind als dieser Prozentsatz der maximalen Gesundheit einer Einheit."

------------------------------------------------------------------------
--	PlexusStatusAggro

-- PlexusStatusAggro
L["Aggro"] = "Aggro"
L["Aggro alert"] = "Aggro-Alarm"
L["Aggro color"] = "Aggro Farbe"
L["Color for Aggro."] = "Farbe für 'Aggro'."
L["Color for High Threat."] = "Farbe für 'Hohe Bedrohung'."
L["Color for Tanking."] = "Farbe für 'Tanken'."
L["High"] = "Hoch"
L["High Threat color"] = "Farbe bei hoher Bedrohung"
L["Show detailed threat levels instead of simple aggro status."] = "Zeigt mehrere Bedrohungsstufen."
L["Tank"] = "Tank"
L["Tanking color"] = "Tanken Farbe"
L["Threat"] = "Bedrohung"

------------------------------------------------------------------------
--	PlexusStatusAuras

-- PlexusStatusAuras
L["%s colors"] = "%s Farben"
L["%s colors and threshold values."] = "%s Farben und Schwellenwerte"
L["%s is high when it is at or above this value."] = "%s ist hoch wenn der Wert gleich oder höher ist."
L["%s is low when it is at or below this value."] = "%s ist niedrig wenn der Wert gleich oder niedriger ist."
L["(De)buff name"] = "(De)buff-Name"
L["<buff name>"] = "<Buffname>"
L["<debuff name>"] = "<Debuffname>"
L["Add Buff"] = "Neuen Buff hinzufügen"
L["Add Debuff"] = "Neuen Debuff hinzufügen"
L["Auras"] = "Auren"
L["Buff: %s"] = "Buff: %s"
L["Change what information is shown by the status color and text."] = "Ändere welche Informationen für die Statusfarbe und den Statustext angezeigt werden."
L["Change what information is shown by the status color."] = "Ändere welche Information für die Statusfarbe angezeigt wird."
L["Change what information is shown by the status text."] = "Ändere welche Information für den Statustext angezeigt wird."
L["Class Filter"] = "Klassenfilter"
L["Color"] = "Farbe"
L["Color to use when the %s is above the high count threshold values."] = "Farbe, welche genutzt wird wenn %s über dem hohem Schwellenwert liegt."
L["Color to use when the %s is between the low and high count threshold values."] = "Farbe, welche genutzt wird, wenn %s zwischen dem niedrigen und der hohem Schwellenwert liegt."
L["Color when %s is below the low threshold value."] = "Farbe, welche genutzt wird, wenn %s unter dem niedrigen Schwellenwert liegt"
L["Create a new buff status."] = "Fügt einen neuen Buff-Status hinzu."
L["Create a new debuff status."] = "Fügt einen neuen Debuff-Status hinzu."
L["Curse"] = "Fluch"
L["Debuff type: %s"] = "Debufftyp: %s"
L["Debuff: %s"] = "Debuff: %s"
L["Disease"] = "Krankheit"
L["Display status only if the buff is not active."] = "Zeigt den Status nur an, wenn der Buff nicht aktiv ist."
L["Display status only if the buff was cast by you."] = "Zeigt den Status nur an, wenn Du ihn gezaubert hast."
L["Ghost"] = "Geistererscheinung"
L["High color"] = "Farbe für \"Hoch\""
L["High threshold"] = "Hoher Schwellwert"
L["Low color"] = "Farbe für \"Niedrig\""
L["Low threshold"] = "Niedriger Schwellwert"
L["Magic"] = "Magie"
L["Middle color"] = "Farbe für \"Mittig\""
L["Pet"] = "Begleiter"
L["Poison"] = "Gift"
L["Present or missing"] = "Vorhanden oder fehlend"
L["Refresh interval"] = "Aktualisierungsintervall"
L["Remove %s from the menu"] = "Entfernt %s vom Menü"
L["Remove an existing buff or debuff status."] = "Löscht einen vorhandenen Buff oder Debuff."
L["Remove Aura"] = "Debuff/Buff löschen"
L["Show advanced options"] = "Erweiterte Optionen zeigen"
L[ [=[Show advanced options for buff and debuff statuses.

Beginning users may wish to leave this disabled until you are more familiar with Plexus, to avoid being overwhelmed by complicated options menus.]=] ] = [=[Zeigt erweiterte Einstellungen für Buff- und Debuff-Status

Beginner sollten diese Option deaktiviert lassen, solange sie noch keine Erfahrung mit Grid gemacht haben, um zu vielen und/oder komplizierten Menüs aus dem Weg zu gehen.]=]
L["Show duration"] = "Dauer anzeigen"
L["Show if mine"] = "Zeigen wenn es meiner ist"
L["Show if missing"] = "Zeigen wenn es fehlt"
L["Show on %s players."] = "Zeigt den Status für die Klasse: %s."
L["Show on pets and vehicles."] = "Auf Begleitern und Fahrzeugen anzeigen"
L["Show status for the selected classes."] = "Zeigt den Status für die ausgwählte Klasse."
L["Show the time left to tenths of a second, instead of only whole seconds."] = "Zeige die verbleibende Zeit in Zehntelsekunden, anstelle von ganzen Sekunden "
L["Show the time remaining, for use with the center icon cooldown."] = "Zeigt die Dauer im Cooldown-Rahmen (Symbol im Zentrum)."
L["Show time left to tenths"] = "Verbleibende Zeit in Zehntelsekunden anzeigen"
L["Stack count"] = "Stapelanzahl"
L["Status Information"] = "Statusinformation"
L["Text"] = "Text"
L["Time in seconds between each refresh of the status time left."] = "Zeit in Sekunden zwischen jeder Aktualisierung des Status Zeit verbleiben."
L["Time left"] = "Verbleibende Zeit"

------------------------------------------------------------------------
--	PlexusStatusHeals

-- PlexusStatusHeals
L["Heals"] = "Heilungen"
L["Ignore heals cast by you."] = "Ignoriert Heilungen die von Dir gezaubert werden."
L["Ignore Self"] = "Sich selbst ignorieren"
L["Incoming heals"] = "Eingehende Heilungen"
L["Minimum Value"] = "Mindestwert"
L["Only show incoming heals greater than this amount."] = "Nur eingehende Heilungen anzeigen, die grösser als dieser Wert sind."

------------------------------------------------------------------------
--	PlexusStatusHealth

-- PlexusStatusHealth
L["Color deficit based on class."] = "Färbt das Defizit nach Klassenfarbe."
L["Color health based on class."] = "Färbt den Gesundheitsbalken in Klassenfarbe."
L["DEAD"] = "TOT"
L["Death warning"] = "Todeswarnung"
L["FD"] = "TG"
L["Feign Death warning"] = "Warnung wenn totgestellt"
L["Health"] = "Gesundheit"
L["Health deficit"] = "Gesundheitsdefizit"
L["Health threshold"] = "Gesundheitsgrenzwert"
L["Low HP"] = "Wenig HP"
L["Low HP threshold"] = "Wenig-HP-Grenzwert"
L["Low HP warning"] = "Wenig-HP-Warnung"
L["Offline"] = "Offline"
L["Offline warning"] = "Offlinewarnung"
L["Only show deficit above % damage."] = "Zeigt Defizit bei mehr als % Schaden."
L["Set the HP % for the low HP warning."] = "Setzt den % Grenzwert für die Wenig-HP-Warnung."
L["Show dead as full health"] = "Zeige Tote mit voller Gesundheit an"
L["Treat dead units as being full health."] = "Behandle Tote als hätten sie volle Gesundheit."
L["Unit health"] = "Gesundheit"
L["Use class color"] = "Benutze Klassenfarbe"

------------------------------------------------------------------------
--	PlexusStatusMana

-- PlexusStatusMana
--[[Translation missing --]]
L["Color by class"] = "Color by class"
L["Low Mana"] = "Wenig Mana"
L["Low Mana warning"] = "Wenig-Mana-Warnung"
L["Mana"] = "Mana"
L["Mana threshold"] = "Mana Grenzwert"
--[[Translation missing --]]
L["Out of Range"] = "Out of Range"
--[[Translation missing --]]
L["Range"] = "Range"
--[[Translation missing --]]
L["Range check frequency"] = "Range check frequency"
--[[Translation missing --]]
L["Seconds between range checks"] = "Seconds between range checks"
L["Set the percentage for the low mana warning."] = "Setzt den % Grenzwert für die Wenig-Mana-Warnung."
--[[Translation missing --]]
L["Unit Name"] = "Unit Name"

------------------------------------------------------------------------
--	PlexusStatusName

-- PlexusStatusName
L["Color by class"] = "Nach Klasse einfärben"
L["Unit Name"] = "Namen"

------------------------------------------------------------------------
--	PlexusStatusRange

-- PlexusStatusRange
L["Out of Range"] = "Außer Reichweite"
L["Range"] = "Entfernung"
L["Range check frequency"] = "Häufigkeit der Reichweitenmessung"
L["Seconds between range checks"] = "Sekunden zwischen den Reichweitenmessungen"

------------------------------------------------------------------------
--	PlexusStatusReadyCheck

-- PlexusStatusReadyCheck
L["?"] = "?"
L["AFK"] = "AFK"
L["AFK color"] = "AFK Farbe"
L["Color for AFK."] = "Farbe für 'AFK'."
L["Color for Not Ready."] = "Farbe für 'Nicht bereit'."
L["Color for Ready."] = "Farbe für 'Bereit'."
L["Color for Waiting."] = "Farbe für 'Warten'."
L["Delay"] = "Verzögerung"
L["Not Ready color"] = "Nicht bereit Farbe"
L["R"] = "OK"
L["Ready Check"] = "Bereitschaftscheck"
L["Ready color"] = "Bereit Farbe"
L["Set the delay until ready check results are cleared."] = "Zeit, bis die Bereitschaftscheck-Ergebnisse gelöscht werden."
L["Waiting color"] = "Warten Farbe"
L["X"] = "X"

------------------------------------------------------------------------
--	PlexusStatusResurrect

-- PlexusStatusResurrect
L["Casting color"] = "Farbe: Wirken"
L["Pending color"] = "Farbe: Abwarten"
L["RES"] = "REZ"
L["Resurrection"] = "Wiederbelebung"
L["Show the status until the resurrection is accepted or expires, instead of only while it is being cast."] = "Zeigen den Status bis die Wiederbelebung akzeptiert wurde oder abgelaufen ist, anstatt es nur währen des zauberns zu tun."
L["Show until used"] = "Zeige bis benutzt"
L["Use this color for resurrections that are currently being cast."] = "Nutze diese Farbe für die Wiederbelebungen, die zur Zeit gezaubert werden."
L["Use this color for resurrections that have finished casting and are waiting to be accepted."] = "Nutze diese Farbe für Wiederbelebungen die fertige gezaubert wurden und darauf warten angenommen zuwerden."

------------------------------------------------------------------------
--	PlexusStatusTarget

-- PlexusStatusTarget
L["Target"] = "Ziel"
L["Your Target"] = "Dein Ziel"

------------------------------------------------------------------------
--	PlexusStatusVehicle

-- PlexusStatusVehicle
L["Driving"] = "Fährt"
L["In Vehicle"] = "In Fahrzeug"

------------------------------------------------------------------------
--	PlexusStatusVoiceComm

-- PlexusStatusVoiceComm
L["Talking"] = "Redet"
L["Voice Chat"] = "Sprachchat"

