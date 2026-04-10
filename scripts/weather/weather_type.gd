## Canonical weather card + terrain enums and pure helpers. No state.
## Terrain order matches `docs/GAME_DESIGN.md` §6 catalog (serialization-stable).
class_name WeatherType
extends RefCounted

enum Card { RAIN, SUN, FROST, WIND, LIGHTNING, FOG }

enum Terrain {
	EMPTY,
	DRY_GRASS,
	WET_GRASS,
	WATER,
	ICE,
	MUD,
	SNOW,
	SCORCHED,
	STEAM,
	PLANT,
	STONE,
	FOG_COVERED,
	START,
	GOAL,
}

static func card_name(card: Card) -> String:
	match card:
		Card.RAIN:
			return "Rain"
		Card.SUN:
			return "Sun"
		Card.FROST:
			return "Frost"
		Card.WIND:
			return "Wind"
		Card.LIGHTNING:
			return "Lightning"
		Card.FOG:
			return "Fog"
		_:
			return "Unknown"


static func terrain_name(terrain: Terrain) -> String:
	match terrain:
		Terrain.EMPTY:
			return "EMPTY"
		Terrain.DRY_GRASS:
			return "DRY_GRASS"
		Terrain.WET_GRASS:
			return "WET_GRASS"
		Terrain.WATER:
			return "WATER"
		Terrain.ICE:
			return "ICE"
		Terrain.MUD:
			return "MUD"
		Terrain.SNOW:
			return "SNOW"
		Terrain.SCORCHED:
			return "SCORCHED"
		Terrain.STEAM:
			return "STEAM"
		Terrain.PLANT:
			return "PLANT"
		Terrain.STONE:
			return "STONE"
		Terrain.FOG_COVERED:
			return "FOG_COVERED"
		Terrain.START:
			return "START"
		Terrain.GOAL:
			return "GOAL"
		_:
			return "Unknown"


## GDD §6 — walkable tiles for pathfinding / post-sequence walk.
static func is_walkable(terrain: Terrain) -> bool:
	match terrain:
		Terrain.DRY_GRASS, Terrain.WET_GRASS, Terrain.ICE, Terrain.MUD, Terrain.SNOW, Terrain.PLANT, Terrain.START, Terrain.GOAL:
			return true
		Terrain.EMPTY, Terrain.WATER, Terrain.SCORCHED, Terrain.STEAM, Terrain.STONE, Terrain.FOG_COVERED:
			return false
		_:
			return false


## GDD §6 — lightning flood-fill connectivity.
static func is_conductive(terrain: Terrain) -> bool:
	match terrain:
		Terrain.WET_GRASS, Terrain.WATER, Terrain.ICE, Terrain.MUD:
			return true
		_:
			return false


## GDD §6 — stepping onto these kills Sky during the walk phase.
static func is_death_tile(terrain: Terrain) -> bool:
	match terrain:
		Terrain.EMPTY, Terrain.WATER, Terrain.SCORCHED, Terrain.STEAM:
			return true
		_:
			return false
