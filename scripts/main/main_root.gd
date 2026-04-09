extends Node2D

@onready var grid_manager: GridManager = $GridManager
@onready var weather_system: WeatherSystem = $WeatherSystem

func _ready() -> void:
  weather_system.setup(grid_manager)
