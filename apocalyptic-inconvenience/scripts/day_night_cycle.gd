extends Node3D

@export var day_duration_seconds := 100.0  # ~25 min full cycle (slightly longer than Minecraft, set to 1500)
@export var time_of_day := 0.3               # 0.0 = midnight, 0.25 = sunrise, 0.5 = noon, 0.75 = sunset

@onready var sun: DirectionalLight3D = $"../DirectionalLight3D"
@onready var world_env: WorldEnvironment = $"../WorldEnvironment"
@onready var sun_mesh: MeshInstance3D = $"../SunMesh"

# Sky colors
var sky_day_top := Color(0.22, 0.42, 0.72)       # richer desert blue
var sky_day_horizon := Color(0.78, 0.65, 0.42)   # warm tan/orange haze at horizon
var sky_night_top := Color(0.15, 0.22, 0.45)     # lighter, still cold blue
var sky_night_horizon := Color(0.22, 0.28, 0.52) # brighter night horizon, cold blue
var sky_sunset_top := Color(0.15, 0.1, 0.2)
var sky_sunset_horizon := Color(0.7, 0.3, 0.15)

# Sun colors
var sun_day_color := Color(1.0, 0.85, 0.6)       # warm golden-orange desert sun
var sun_sunset_color := Color(1.0, 0.5, 0.2)
var sun_night_color := Color(0.35, 0.4, 0.7)     # brighter cool moonlight

var sky_material: ProceduralSkyMaterial

const SUN_DISTANCE := 120.0

func _ready() -> void:
	sky_material = world_env.environment.sky.sky_material as ProceduralSkyMaterial

func _process(delta: float) -> void:
	time_of_day += delta / day_duration_seconds
	if time_of_day >= 1.0:
		time_of_day -= 1.0

	_update_sun()
	_update_sky()
	_update_fog()

func _update_sun() -> void:
	var sun_angle := (time_of_day - 0.25) * TAU
	sun.rotation_degrees = Vector3(rad_to_deg(sun_angle), -30.0, 0.0)

	var day_factor := _get_day_factor()
	sun.light_energy = lerpf(0.4, 1.2, day_factor)

	var sunset_factor := _get_sunset_factor()
	var base_color := sun_day_color.lerp(sun_night_color, 1.0 - day_factor)
	sun.light_color = base_color.lerp(sun_sunset_color, sunset_factor)

	# Position the visible sun mesh along the light direction
	var dir := sun.global_transform.basis.z
	sun_mesh.global_position = dir * SUN_DISTANCE
	sun_mesh.visible = day_factor > 0.05

func _update_sky() -> void:
	var day_factor := _get_day_factor()
	var sunset_factor := _get_sunset_factor()

	var top := sky_day_top.lerp(sky_night_top, 1.0 - day_factor)
	top = top.lerp(sky_sunset_top, sunset_factor)

	var horizon := sky_day_horizon.lerp(sky_night_horizon, 1.0 - day_factor)
	horizon = horizon.lerp(sky_sunset_horizon, sunset_factor)

	sky_material.sky_top_color = top
	sky_material.sky_horizon_color = horizon
	sky_material.ground_horizon_color = horizon
	sky_material.ground_bottom_color = top.darkened(0.5)

func _update_fog() -> void:
	var day_factor := _get_day_factor()
	var env := world_env.environment

	env.fog_light_color = sky_material.sky_horizon_color.darkened(0.2)
	env.fog_density = lerpf(0.015, 0.005, day_factor)
	env.volumetric_fog_density = lerpf(0.035, 0.015, day_factor)

# 1.0 = full day, 0.0 = full night
func _get_day_factor() -> float:
	var dist_from_noon := absf(time_of_day - 0.5)
	return clampf(1.0 - smoothstep(0.15, 0.3, dist_from_noon), 0.0, 1.0)

# 1.0 = peak sunset/sunrise, 0.0 = not sunset
func _get_sunset_factor() -> float:
	var sunrise_dist := absf(time_of_day - 0.25)
	var sunset_dist := absf(time_of_day - 0.75)
	var closest := minf(sunrise_dist, sunset_dist)
	return clampf(1.0 - smoothstep(0.0, 0.08, closest), 0.0, 1.0)
