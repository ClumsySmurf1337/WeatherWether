extends GutTest

func test_card_enum_has_six_values() -> void:
	assert_eq(WeatherType.Card.keys().size(), 6)


func test_terrain_enum_has_fourteen_values() -> void:
	assert_eq(WeatherType.Terrain.keys().size(), 14)


func test_card_names() -> void:
	assert_eq(WeatherType.card_name(WeatherType.Card.RAIN), "Rain")
	assert_eq(WeatherType.card_name(WeatherType.Card.LIGHTNING), "Lightning")


func test_terrain_names_are_stable_tokens() -> void:
	assert_eq(WeatherType.terrain_name(WeatherType.Terrain.DRY_GRASS), "DRY_GRASS")
	assert_eq(WeatherType.terrain_name(WeatherType.Terrain.FOG_COVERED), "FOG_COVERED")


func test_is_walkable_matches_gdd_section_six() -> void:
	var expected: Dictionary = {
		WeatherType.Terrain.EMPTY: false,
		WeatherType.Terrain.DRY_GRASS: true,
		WeatherType.Terrain.WET_GRASS: true,
		WeatherType.Terrain.WATER: false,
		WeatherType.Terrain.ICE: true,
		WeatherType.Terrain.MUD: true,
		WeatherType.Terrain.SNOW: true,
		WeatherType.Terrain.SCORCHED: false,
		WeatherType.Terrain.STEAM: false,
		WeatherType.Terrain.PLANT: true,
		WeatherType.Terrain.STONE: false,
		WeatherType.Terrain.FOG_COVERED: false,
		WeatherType.Terrain.START: true,
		WeatherType.Terrain.GOAL: true,
	}
	assert_eq(expected.size(), 14)
	for terrain: WeatherType.Terrain in expected:
		assert_eq(
			WeatherType.is_walkable(terrain),
			expected[terrain],
			"walkable mismatch for %s" % WeatherType.terrain_name(terrain)
		)


func test_is_conductive_matches_gdd_section_six() -> void:
	var expected: Dictionary = {
		WeatherType.Terrain.EMPTY: false,
		WeatherType.Terrain.DRY_GRASS: false,
		WeatherType.Terrain.WET_GRASS: true,
		WeatherType.Terrain.WATER: true,
		WeatherType.Terrain.ICE: true,
		WeatherType.Terrain.MUD: true,
		WeatherType.Terrain.SNOW: false,
		WeatherType.Terrain.SCORCHED: false,
		WeatherType.Terrain.STEAM: false,
		WeatherType.Terrain.PLANT: false,
		WeatherType.Terrain.STONE: false,
		WeatherType.Terrain.FOG_COVERED: false,
		WeatherType.Terrain.START: false,
		WeatherType.Terrain.GOAL: false,
	}
	assert_eq(expected.size(), 14)
	for terrain: WeatherType.Terrain in expected:
		assert_eq(WeatherType.is_conductive(terrain), expected[terrain])


func test_is_death_tile_matches_gdd_section_six() -> void:
	var expected: Dictionary = {
		WeatherType.Terrain.EMPTY: true,
		WeatherType.Terrain.DRY_GRASS: false,
		WeatherType.Terrain.WET_GRASS: false,
		WeatherType.Terrain.WATER: true,
		WeatherType.Terrain.ICE: false,
		WeatherType.Terrain.MUD: false,
		WeatherType.Terrain.SNOW: false,
		WeatherType.Terrain.SCORCHED: true,
		WeatherType.Terrain.STEAM: true,
		WeatherType.Terrain.PLANT: false,
		WeatherType.Terrain.STONE: false,
		WeatherType.Terrain.FOG_COVERED: false,
		WeatherType.Terrain.START: false,
		WeatherType.Terrain.GOAL: false,
	}
	assert_eq(expected.size(), 14)
	for terrain: WeatherType.Terrain in expected:
		assert_eq(WeatherType.is_death_tile(terrain), expected[terrain])
