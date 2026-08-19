class_name WeatherProfile
extends Resource

## The weather in an area. Drop one on a WeatherZone or on an AreaData.

@export var id: StringName = &""

@export_group("Rain")
@export_range(0.0, 1.0, 0.01) var rain_density: float = 0.0
@export var rain_speed: float = 320.0
## Degrees off vertical. Negative leans left.
@export_range(-45.0, 45.0, 1.0) var rain_slant: float = -10.0
@export var rain_color: Color = Color(0.70, 0.76, 0.85, 0.45)
## Ticked, drops burst where they land.
@export var splashes: bool = true

@export_group("Fog")
@export_range(0.0, 1.0, 0.01) var fog_alpha: float = 0.0
@export var fog_color: Color = Color(0.55, 0.58, 0.62, 1.0)
@export var fog_drift: float = 6.0

@export_group("Wind")
@export_range(0.0, 1.0, 0.01) var wind_volume: float = 0.0

@export_group("Sound")
@export var ambience: AudioStream
@export_range(0.0, 1.0, 0.01) var ambience_volume: float = 0.5
