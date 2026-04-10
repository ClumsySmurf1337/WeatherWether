## Full GDD §5 interaction matrix coverage: 37 active + 47 none + area effects.
extends GutTest

const T := WeatherType.Terrain
const C := WeatherType.Card


func _make_grid(w: int, h: int, fill: int = T.DRY_GRASS) -> Array:
	var g: Array = []
	g.resize(w * h)
	for i in range(g.size()):
		g[i] = fill
	return g


func _at(grid: Array, pos: Vector2i, w: int) -> int:
	return grid[pos.y * w + pos.x]


# ===================================================================
# RAIN — 6 active transitions
# ===================================================================

func test_rain_dry_grass_to_wet_grass() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	var out := WeatherSystem.apply(g, 3, 3, C.RAIN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.WET_GRASS)

func test_rain_empty_to_water() -> void:
	var g := _make_grid(3, 3, T.EMPTY)
	var out := WeatherSystem.apply(g, 3, 3, C.RAIN, Vector2i(0, 0))
	assert_eq(_at(out, Vector2i(0, 0), 3), T.WATER)

func test_rain_scorched_to_mud() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.SCORCHED
	var out := WeatherSystem.apply(g, 3, 3, C.RAIN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.MUD)

func test_rain_fog_covered_to_wet_grass() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.FOG_COVERED
	var out := WeatherSystem.apply(g, 3, 3, C.RAIN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.WET_GRASS)

func test_rain_plant_stays_plant() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.PLANT
	var out := WeatherSystem.apply(g, 3, 3, C.RAIN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.PLANT)

func test_rain_snow_to_wet_grass() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.SNOW
	var out := WeatherSystem.apply(g, 3, 3, C.RAIN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.WET_GRASS)

func test_rain_no_effect_on_water() -> void:
	var g := _make_grid(3, 3, T.WATER)
	var out := WeatherSystem.apply(g, 3, 3, C.RAIN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.WATER)

func test_rain_no_effect_on_stone() -> void:
	var g := _make_grid(3, 3, T.STONE)
	var out := WeatherSystem.apply(g, 3, 3, C.RAIN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.STONE)


# ===================================================================
# SUN — 8 active transitions
# ===================================================================

func test_sun_water_to_steam() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.WATER
	var out := WeatherSystem.apply(g, 3, 3, C.SUN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.STEAM)

func test_sun_ice_to_water() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.ICE
	var out := WeatherSystem.apply(g, 3, 3, C.SUN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.WATER)

func test_sun_wet_grass_to_dry_grass() -> void:
	var g := _make_grid(3, 3, T.WET_GRASS)
	var out := WeatherSystem.apply(g, 3, 3, C.SUN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.DRY_GRASS)

func test_sun_dry_grass_to_scorched() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	var out := WeatherSystem.apply(g, 3, 3, C.SUN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.SCORCHED)

func test_sun_plant_to_dry_grass() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.PLANT
	var out := WeatherSystem.apply(g, 3, 3, C.SUN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.DRY_GRASS)

func test_sun_fog_covered_to_dry_grass() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.FOG_COVERED
	var out := WeatherSystem.apply(g, 3, 3, C.SUN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.DRY_GRASS)

func test_sun_mud_to_dry_grass() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.MUD
	var out := WeatherSystem.apply(g, 3, 3, C.SUN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.DRY_GRASS)

func test_sun_snow_to_wet_grass() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.SNOW
	var out := WeatherSystem.apply(g, 3, 3, C.SUN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.WET_GRASS)

func test_sun_no_effect_on_empty() -> void:
	var g := _make_grid(3, 3, T.EMPTY)
	var out := WeatherSystem.apply(g, 3, 3, C.SUN, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.EMPTY)


# ===================================================================
# FROST — 6 active transitions
# ===================================================================

func test_frost_water_to_ice() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.WATER
	var out := WeatherSystem.apply(g, 3, 3, C.FROST, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.ICE)

func test_frost_wet_grass_to_ice() -> void:
	var g := _make_grid(3, 3, T.WET_GRASS)
	var out := WeatherSystem.apply(g, 3, 3, C.FROST, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.ICE)

func test_frost_mud_to_ice() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.MUD
	var out := WeatherSystem.apply(g, 3, 3, C.FROST, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.ICE)

func test_frost_empty_to_snow() -> void:
	var g := _make_grid(3, 3, T.EMPTY)
	var out := WeatherSystem.apply(g, 3, 3, C.FROST, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.SNOW)

func test_frost_dry_grass_to_snow() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	var out := WeatherSystem.apply(g, 3, 3, C.FROST, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.SNOW)

func test_frost_plant_to_ice() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.PLANT
	var out := WeatherSystem.apply(g, 3, 3, C.FROST, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.ICE)

func test_frost_no_effect_on_ice() -> void:
	var g := _make_grid(3, 3, T.ICE)
	var out := WeatherSystem.apply(g, 3, 3, C.FROST, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.ICE)

func test_frost_no_effect_on_snow() -> void:
	var g := _make_grid(3, 3, T.SNOW)
	var out := WeatherSystem.apply(g, 3, 3, C.FROST, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.SNOW)


# ===================================================================
# WIND — 2 active transitions (per tile), area effect: 3-tile cross
# ===================================================================

func test_wind_fog_covered_to_dry_grass() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.FOG_COVERED
	var out := WeatherSystem.apply(g, 3, 3, C.WIND, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.DRY_GRASS)

func test_wind_steam_to_empty() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.STEAM
	var out := WeatherSystem.apply(g, 3, 3, C.WIND, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.EMPTY)

func test_wind_cross_clears_fog_in_all_five_tiles() -> void:
	var g := _make_grid(3, 3, T.FOG_COVERED)
	var out := WeatherSystem.apply(g, 3, 3, C.WIND, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.DRY_GRASS)
	assert_eq(_at(out, Vector2i(1, 0), 3), T.DRY_GRASS)
	assert_eq(_at(out, Vector2i(2, 1), 3), T.DRY_GRASS)
	assert_eq(_at(out, Vector2i(1, 2), 3), T.DRY_GRASS)
	assert_eq(_at(out, Vector2i(0, 1), 3), T.DRY_GRASS)
	# Corners untouched
	assert_eq(_at(out, Vector2i(0, 0), 3), T.FOG_COVERED)
	assert_eq(_at(out, Vector2i(2, 2), 3), T.FOG_COVERED)

func test_wind_at_corner_skips_out_of_bounds() -> void:
	var g := _make_grid(3, 3, T.FOG_COVERED)
	var out := WeatherSystem.apply(g, 3, 3, C.WIND, Vector2i(0, 0))
	assert_eq(_at(out, Vector2i(0, 0), 3), T.DRY_GRASS)
	assert_eq(_at(out, Vector2i(1, 0), 3), T.DRY_GRASS)
	assert_eq(_at(out, Vector2i(0, 1), 3), T.DRY_GRASS)
	# Diagonal and far tiles still fog
	assert_eq(_at(out, Vector2i(1, 1), 3), T.FOG_COVERED)

func test_wind_no_effect_on_dry_grass() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	var out := WeatherSystem.apply(g, 3, 3, C.WIND, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.DRY_GRASS)


# ===================================================================
# LIGHTNING — 6 active transitions + flood-fill chain
# ===================================================================

func test_lightning_dry_grass_to_scorched() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	var out := WeatherSystem.apply(g, 3, 3, C.LIGHTNING, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.SCORCHED)

func test_lightning_wet_grass_scorched_chain() -> void:
	var g := _make_grid(3, 3, T.WET_GRASS)
	var out := WeatherSystem.apply(g, 3, 3, C.LIGHTNING, Vector2i(1, 1))
	for y in range(3):
		for x in range(3):
			assert_eq(_at(out, Vector2i(x, y), 3), T.SCORCHED,
				"tile (%d,%d) should be SCORCHED" % [x, y])

func test_lightning_water_scorched_chain() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[0] = T.WATER
	g[1] = T.WATER
	g[2] = T.WATER
	var out := WeatherSystem.apply(g, 3, 3, C.LIGHTNING, Vector2i(0, 0))
	assert_eq(_at(out, Vector2i(0, 0), 3), T.SCORCHED)
	assert_eq(_at(out, Vector2i(1, 0), 3), T.SCORCHED)
	assert_eq(_at(out, Vector2i(2, 0), 3), T.SCORCHED)

func test_lightning_mud_scorched_chain() -> void:
	var g := _make_grid(1, 3, T.MUD)
	var out := WeatherSystem.apply(g, 1, 3, C.LIGHTNING, Vector2i(0, 0))
	for y in range(3):
		assert_eq(_at(out, Vector2i(0, y), 1), T.SCORCHED)

func test_lightning_plant_to_scorched() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.PLANT
	var out := WeatherSystem.apply(g, 3, 3, C.LIGHTNING, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.SCORCHED)

func test_lightning_ice_shatters_to_empty_no_chain() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[3] = T.ICE
	g[4] = T.ICE
	g[5] = T.ICE
	var out := WeatherSystem.apply(g, 3, 3, C.LIGHTNING, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.EMPTY)
	# Adjacent ICE NOT chained — only direct target shatters
	assert_eq(_at(out, Vector2i(0, 1), 3), T.ICE)
	assert_eq(_at(out, Vector2i(2, 1), 3), T.ICE)

func test_lightning_chain_large_connected_region() -> void:
	var w := 5
	var h := 1
	var g: Array = []
	g.resize(5)
	g[0] = T.WATER as int
	g[1] = T.MUD as int
	g[2] = T.WET_GRASS as int
	g[3] = T.ICE as int
	g[4] = T.DRY_GRASS as int
	var out := WeatherSystem.apply(g, w, h, C.LIGHTNING, Vector2i(0, 0))
	assert_eq(_at(out, Vector2i(0, 0), w), T.SCORCHED)
	assert_eq(_at(out, Vector2i(1, 0), w), T.SCORCHED)
	assert_eq(_at(out, Vector2i(2, 0), w), T.SCORCHED)
	# ICE in chain becomes EMPTY
	assert_eq(_at(out, Vector2i(3, 0), w), T.EMPTY)
	# DRY_GRASS not conductive — not part of chain
	assert_eq(_at(out, Vector2i(4, 0), w), T.DRY_GRASS)

func test_lightning_no_effect_on_stone() -> void:
	var g := _make_grid(3, 3, T.STONE)
	var out := WeatherSystem.apply(g, 3, 3, C.LIGHTNING, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.STONE)

func test_lightning_no_effect_on_empty() -> void:
	var g := _make_grid(3, 3, T.EMPTY)
	var out := WeatherSystem.apply(g, 3, 3, C.LIGHTNING, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.EMPTY)


# ===================================================================
# FOG — 9 eligible tile types covered, 3×3 area
# ===================================================================

func test_fog_covers_dry_grass() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	var out := WeatherSystem.apply(g, 3, 3, C.FOG, Vector2i(1, 1))
	for y in range(3):
		for x in range(3):
			assert_eq(_at(out, Vector2i(x, y), 3), T.FOG_COVERED)

func test_fog_covers_water() -> void:
	var g := _make_grid(3, 3, T.WATER)
	var out := WeatherSystem.apply(g, 3, 3, C.FOG, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.FOG_COVERED)

func test_fog_covers_ice() -> void:
	var g := _make_grid(1, 1, T.ICE)
	var out := WeatherSystem.apply(g, 1, 1, C.FOG, Vector2i(0, 0))
	assert_eq(out[0], T.FOG_COVERED)

func test_fog_covers_mud() -> void:
	var g := _make_grid(1, 1, T.MUD)
	var out := WeatherSystem.apply(g, 1, 1, C.FOG, Vector2i(0, 0))
	assert_eq(out[0], T.FOG_COVERED)

func test_fog_covers_snow() -> void:
	var g := _make_grid(1, 1, T.SNOW)
	var out := WeatherSystem.apply(g, 1, 1, C.FOG, Vector2i(0, 0))
	assert_eq(out[0], T.FOG_COVERED)

func test_fog_covers_scorched() -> void:
	var g := _make_grid(1, 1, T.SCORCHED)
	var out := WeatherSystem.apply(g, 1, 1, C.FOG, Vector2i(0, 0))
	assert_eq(out[0], T.FOG_COVERED)

func test_fog_covers_plant() -> void:
	var g := _make_grid(1, 1, T.PLANT)
	var out := WeatherSystem.apply(g, 1, 1, C.FOG, Vector2i(0, 0))
	assert_eq(out[0], T.FOG_COVERED)

func test_fog_covers_wet_grass() -> void:
	var g := _make_grid(1, 1, T.WET_GRASS)
	var out := WeatherSystem.apply(g, 1, 1, C.FOG, Vector2i(0, 0))
	assert_eq(out[0], T.FOG_COVERED)

func test_fog_covers_empty() -> void:
	var g := _make_grid(1, 1, T.EMPTY)
	var out := WeatherSystem.apply(g, 1, 1, C.FOG, Vector2i(0, 0))
	assert_eq(out[0], T.FOG_COVERED)

func test_fog_excludes_stone() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.STONE
	var out := WeatherSystem.apply(g, 3, 3, C.FOG, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.STONE)
	assert_eq(_at(out, Vector2i(0, 0), 3), T.FOG_COVERED)

func test_fog_excludes_start() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[0] = T.START
	var out := WeatherSystem.apply(g, 3, 3, C.FOG, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(0, 0), 3), T.START)

func test_fog_excludes_goal() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[8] = T.GOAL
	var out := WeatherSystem.apply(g, 3, 3, C.FOG, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(2, 2), 3), T.GOAL)

func test_fog_excludes_steam() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	g[4] = T.STEAM
	var out := WeatherSystem.apply(g, 3, 3, C.FOG, Vector2i(1, 1))
	assert_eq(_at(out, Vector2i(1, 1), 3), T.STEAM)

func test_fog_clips_at_board_edge() -> void:
	var g := _make_grid(2, 2, T.DRY_GRASS)
	var out := WeatherSystem.apply(g, 2, 2, C.FOG, Vector2i(0, 0))
	for i in range(4):
		assert_eq(out[i], T.FOG_COVERED)


# ===================================================================
# Pure function contract
# ===================================================================

func test_apply_does_not_mutate_input() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	var original := g.duplicate()
	var _out := WeatherSystem.apply(g, 3, 3, C.SUN, Vector2i(1, 1))
	assert_eq(g, original, "input grid must not be mutated")


# ===================================================================
# is_valid_placement
# ===================================================================

func test_valid_placement_on_dry_grass() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	assert_true(WeatherSystem.is_valid_placement(g, 3, 3, C.RAIN, Vector2i(1, 1)))

func test_invalid_placement_on_stone() -> void:
	var g := _make_grid(3, 3, T.STONE)
	assert_false(WeatherSystem.is_valid_placement(g, 3, 3, C.RAIN, Vector2i(1, 1)))

func test_invalid_placement_on_start() -> void:
	var g := _make_grid(3, 3, T.START)
	assert_false(WeatherSystem.is_valid_placement(g, 3, 3, C.FOG, Vector2i(1, 1)))

func test_invalid_placement_out_of_bounds() -> void:
	var g := _make_grid(3, 3, T.DRY_GRASS)
	assert_false(WeatherSystem.is_valid_placement(g, 3, 3, C.RAIN, Vector2i(5, 5)))
