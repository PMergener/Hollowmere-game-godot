class_name AreaData
extends Resource

## The mood of a place. One per area scene, dropped on its root.

@export var id: StringName = &""
@export var display_name: String = "Hollowmere"

@export_group("Light")
## The colour everything is drowned in before the lamp reaches it. Near-black
## outdoors at night; a warmer brown underground. This is the single strongest
## lever on how a place feels.
@export var ambient_light: Color = Color(0.07, 0.08, 0.11, 1.0)
## Ticked, the area is roofed: no rain, no wind, no sky.
@export var indoors: bool = false

@export_group("Weather")
@export var weather: WeatherProfile

@export_group("Sound")
@export var ambience: AudioStream
@export_range(0.0, 1.0, 0.01) var ambience_volume: float = 0.5
## A low bed under everything. Used underground.
@export var drone: AudioStream
@export_range(0.0, 1.0, 0.01) var drone_volume: float = 0.0

@export_group("Map")
## Shown on the minimap. Leave empty for no map.
@export var minimap_texture: Texture2D
