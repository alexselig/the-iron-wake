extends RefCounted

## Central data for the "new" design pass (applied only when
## GameState.use_new_assets is true; see AdventureRoom._apply_new_polish).
##
## Per room (keyed by scene-file basename):
##   hide   : [node names]                -> sprite hidden, Area2D kept (invisible hotspot).
##            Used for placeholder overlays that clash with the painted background
##            (the scenery is already drawn into the art).
##   reskin : {node name: inventory icon} -> pickup item shown with its real inventory
##            icon, so the scene object matches what enters the inventory bar.
##   move   : {node name: Vector2}        -> reposition to remove overlaps / floating.
##   scale  : {node name: float}          -> multiply sprite scale.

static func get_ops() -> Dictionary:
	return {
		# Room 1 — Blackwake Harbor
		"main": {
			"hide": ["SteamValve", "WarningPlacard"],
			"reskin": {"SpyglassCrate": "spyglass"},
			"move": {
				"TibbitNPC": Vector2(238, 286),
				"PindleNPC": Vector2(410, 282),
			},
		},
		# Room 2 — Customs Shack
		"customs_shack": {
			"hide": ["PermitLedger", "InkPad", "SealPress"],
			"reskin": {"BlankForms": "blank_form"},
			"move": {"BlankForms": Vector2(188, 201)},
		},
		# Room 3 — Salvage Warehouse
		"salvage_warehouse": {
			"hide": ["LighthouseCrate"],
			"reskin": {
				"BlackShard": "black_shard",
				"AutomatonHand": "automaton_hand",
				"CopperWireCoil": "copper_wire",
				"BrokenGearProp": "broken_gear",
			},
			"move": {
				"AutomatonHand": Vector2(188, 232),
				"BlackShard": Vector2(238, 250),
			},
		},
		# Room 4 — Brass Bazaar
		"brass_bazaar": {
			"reskin": {"GuildBadge": "guild_badge", "FancyTeacup": "fancy_teacup"},
			"move": {"GuildBadge": Vector2(165, 300)},
		},
		# Room 5 — Tibbit's Workshop
		"tibbit_workshop": {
			"hide": ["LampOil"],
			"reskin": {
				"ClockSpring": "clock_spring",
				"Whistle": "whistle",
				"LensFrame": "lens_frame",
				"CoilLine": "coil_line",
			},
			"move": {
				"Whistle": Vector2(330, 218),
				"LensFrame": Vector2(388, 248),
				"ClockSpring": Vector2(452, 232),
				"CoilLine": Vector2(250, 250),
			},
		},
		# Room 6 — Harbor Cliffs
		"harbor_cliffs": {
			"hide": ["BoundaryStone1", "BoundaryStone2"],
			"reskin": {"LanternProp": "lantern"},
		},
		# Room 7 — Lighthouse Exterior
		"lighthouse_exterior": {
			"hide": ["BoundaryStones"],
			"reskin": {"ValvePin": "valve_pin", "SaltDeposits": "salt_paste"},
		},
		# Room 8 — Lighthouse Chamber
		"lighthouse_chamber": {
			"hide": ["WallMural"],
		},
		# Room 9 — Smuggler Path
		"smuggler_path": {
			"hide": ["CliffLift"],
			"reskin": {"SignalLantern": "lantern"},
		},
		# Room 10 — Brackmarsh
		"brackmarsh": {
			"hide": ["ReedSkiff", "StandingMirror1", "StandingMirror2", "StandingMirror3"],
			"reskin": {
				"BrassCurtainRod": "brass_curtain_rod",
				"ChapelHandMirror": "chapel_hand_mirror",
			},
		},
		# Room 11 — Relay Tower
		"relay_tower": {
			"hide": ["ToneForks"],
		},
		# Room 12 — Sunken Waystation
		"sunken_waystation": {
			"hide": ["TransitMapArch", "PumpMechanism", "VacuumLockers"],
		},
		# Room 13 — Ironwind Airdock
		"ironwind_airdock": {
			"hide": ["MooringWinch"],
		},
		# Room 14 — Fogwound Ruins
		"fogwound_ruins": {
			"hide": ["FallenStatue"],
			"reskin": {"CampNote": "message_strip"},
		},
		# Room 15 — Transit Vault
		"transit_vault": {
			"hide": ["ArchiveNode"],
		},
		# Room 16 — Cinderglass Valley
		"cinderglass_valley": {
			"hide": ["VentWheels", "TransitPlinth"],
			"reskin": {"GlassOutcrop": "reflective_cinderglass"},
		},
		# Room 17 — Mountain Breach
		"mountain_breach": {
			"reskin": {"ScaffoldPipe": "scaffold_pipe"},
		},
		# Room 18 — Undersea Transit
		"undersea_transit": {
			"hide": ["TransitCradle"],
		},
	}
