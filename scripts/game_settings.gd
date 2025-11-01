@tool
extends Node
class_name GameSettings

## Game settings system with automatic persistence
## Manages video, audio, controls, and gameplay settings

signal setting_changed(setting_name: String, value)

@export_group("Video")

## V-Sync: Vertical synchronization (limits FPS to monitor refresh rate)
## Enabled: Removes screen tearing, caps FPS to monitor refresh
## Disabled: Unlimited FPS, better for high refresh rate monitors (144Hz+)
@export var vsync_enabled: bool = true:
	set(value):
		vsync_enabled = value
		_apply_vsync()
		setting_changed.emit("vsync_enabled", value)

## Max FPS: Maximum frames per second limit (0 = unlimited)
## 0: Unlimited (best for performance)
## 60: Standard for 60Hz monitors
## 144/165/240: For high refresh rate monitors
@export_range(0, 500, 1) var max_fps: int = 0:
	set(value):
		max_fps = value
		_apply_max_fps()
		setting_changed.emit("max_fps", value)

## Fullscreen: Window display mode
## Enabled: Exclusive fullscreen (better performance)
## Disabled: Windowed mode (faster alt-tab)
@export var fullscreen: bool = false:
	set(value):
		fullscreen = value
		_apply_fullscreen()
		setting_changed.emit("fullscreen", value)

## Resolution: Window/screen resolution
## Common resolutions: 1920x1080 (Full HD), 2560x1440 (2K), 3840x2160 (4K)
## Lower resolution = higher FPS
@export var resolution: Vector2i = Vector2i(1920, 1080):
	set(value):
		resolution = value
		_apply_resolution()
		setting_changed.emit("resolution", value)

@export_group("Audio")

## Master Volume: Overall game volume (0.0-1.0)
## Controls all audio output
@export_range(0.0, 1.0, 0.01) var master_volume: float = 0.8:
	set(value):
		master_volume = value
		_apply_volume("Master", value)
		setting_changed.emit("master_volume", value)

## Music Volume: Background music volume (0.0-1.0)
## Controls only the "Music" audio bus
@export_range(0.0, 1.0, 0.01) var music_volume: float = 0.7:
	set(value):
		music_volume = value
		_apply_volume("Music", value)
		setting_changed.emit("music_volume", value)

## SFX Volume: Sound effects volume (0.0-1.0)
## Controls only the "SFX" audio bus (action sounds, UI, ambient)
@export_range(0.0, 1.0, 0.01) var sfx_volume: float = 0.8:
	set(value):
		sfx_volume = value
		_apply_volume("SFX", value)
		setting_changed.emit("sfx_volume", value)

@export_group("Controls")

## Mouse Sensitivity: Mouse look speed (0.05-2.0)
## 0.1-0.2: Slow (precision aiming)
## 0.3-0.5: Medium (balanced)
## 0.6-1.0+: Fast (quick turns)
@export_range(0.05, 2.0, 0.01) var mouse_sensitivity: float = 0.3:
	set(value):
		mouse_sensitivity = value
		_apply_mouse_sensitivity()
		setting_changed.emit("mouse_sensitivity", value)

## Invert Y Axis: Inverts vertical look direction
## Enabled: Flight simulator style (mouse up = look down)
## Disabled: Standard FPS style (mouse up = look up)
@export var invert_y_axis: bool = false:
	set(value):
		invert_y_axis = value
		_apply_invert_y()
		setting_changed.emit("invert_y_axis", value)

## Player Reference: Drag your player node here
## Required for mouse sensitivity, invert Y, and FOV settings
## Player must have set_mouse_sensitivity() and set_invert_y() methods
@export var player_reference: Node3D = null

@export_group("Gameplay")

## Field of View: Camera FOV in degrees (60-120)
## 60-70: Cinematic, realistic
## 75-90: Standard FPS
## 90-110: Competitive, wider peripheral vision
## Higher FOV = renders more = lower FPS
@export_range(60, 120, 1) var field_of_view: int = 85:
	set(value):
		field_of_view = value
		_apply_fov()
		setting_changed.emit("field_of_view", value)

@export_group("System")

## Auto Save: Automatically save settings when changed
## Enabled: Saves to user://game_settings.cfg
## Disabled: Only saves when manually calling save_settings()
@export var auto_save: bool = true

## Load on Ready: Load saved settings on initialization
## Enabled: Loads settings from file automatically
## Disabled: Uses default Inspector values
@export var load_on_ready: bool = true

var _settings_path: String = "user://game_settings.cfg"


func _ready():
	if Engine.is_editor_hint():
		return
	
	if load_on_ready:
		load_settings()
	else:
		_apply_all_settings()
	
	print("GameSettings: Initialized")


func _apply_all_settings():
	_apply_vsync()
	_apply_max_fps()
	_apply_fullscreen()
	_apply_resolution()
	_apply_volume("Master", master_volume)
	_apply_volume("Music", music_volume)
	_apply_volume("SFX", sfx_volume)
	_apply_mouse_sensitivity()
	_apply_invert_y()
	_apply_fov()


func _apply_vsync():
	if vsync_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	if auto_save and not Engine.is_editor_hint():
		save_settings()


func _apply_max_fps():
	Engine.max_fps = max_fps
	
	if auto_save and not Engine.is_editor_hint():
		save_settings()


func _apply_fullscreen():
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	if auto_save and not Engine.is_editor_hint():
		save_settings()


func _apply_resolution():
	if not fullscreen:
		DisplayServer.window_set_size(resolution)
		# Center window
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size - resolution) / 2
		DisplayServer.window_set_position(window_pos)
	
	if auto_save and not Engine.is_editor_hint():
		save_settings()


func _apply_volume(bus_name: String, volume: float):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		if volume <= 0.0:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			var db = 20 * log(volume) / log(10)
			AudioServer.set_bus_volume_db(bus_idx, db)
	else:
		push_warning("GameSettings: Audio bus not found: ", bus_name)
	
	if auto_save and not Engine.is_editor_hint():
		save_settings()


func _apply_mouse_sensitivity():
	if player_reference and player_reference.has_method("set_mouse_sensitivity"):
		player_reference.set_mouse_sensitivity(mouse_sensitivity)
	elif player_reference:
		for child in player_reference.get_children():
			if child.has_method("set_mouse_sensitivity"):
				child.set_mouse_sensitivity(mouse_sensitivity)
				break
	
	if auto_save and not Engine.is_editor_hint():
		save_settings()


func _apply_invert_y():
	if player_reference and player_reference.has_method("set_invert_y"):
		player_reference.set_invert_y(invert_y_axis)
	elif player_reference:
		for child in player_reference.get_children():
			if child.has_method("set_invert_y"):
				child.set_invert_y(invert_y_axis)
				break
	
	if auto_save and not Engine.is_editor_hint():
		save_settings()


func _apply_fov():
	if player_reference:
		var camera = _get_player_camera()
		if camera:
			camera.fov = field_of_view
	
	if auto_save and not Engine.is_editor_hint():
		save_settings()


func _get_player_camera() -> Camera3D:
	if not player_reference:
		return null
	
	if player_reference.has_method("get_camera"):
		return player_reference.get_camera()
	
	for child in player_reference.get_children():
		if child is Camera3D:
			return child
		if child is CharacterBody3D:
			for subchild in child.get_children():
				if subchild is Camera3D:
					return subchild
	
	return null


func save_settings():
	var config = ConfigFile.new()
	
	config.set_value("video", "vsync_enabled", vsync_enabled)
	config.set_value("video", "max_fps", max_fps)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "resolution_x", resolution.x)
	config.set_value("video", "resolution_y", resolution.y)
	
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("controls", "invert_y_axis", invert_y_axis)
	
	config.set_value("gameplay", "field_of_view", field_of_view)
	
	var error = config.save(_settings_path)
	if error == OK:
		print("GameSettings: Settings saved to ", _settings_path)
	else:
		push_error("GameSettings: Failed to save settings - Error code: ", error)


func load_settings():
	var config = ConfigFile.new()
	var error = config.load(_settings_path)
	
	if error != OK:
		print("GameSettings: No saved settings found, using defaults")
		_apply_all_settings()
		save_settings()
		return
	
	vsync_enabled = config.get_value("video", "vsync_enabled", vsync_enabled)
	max_fps = config.get_value("video", "max_fps", max_fps)
	fullscreen = config.get_value("video", "fullscreen", fullscreen)
	var res_x = config.get_value("video", "resolution_x", resolution.x)
	var res_y = config.get_value("video", "resolution_y", resolution.y)
	resolution = Vector2i(res_x, res_y)
	
	master_volume = config.get_value("audio", "master_volume", master_volume)
	music_volume = config.get_value("audio", "music_volume", music_volume)
	sfx_volume = config.get_value("audio", "sfx_volume", sfx_volume)
	
	mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", mouse_sensitivity)
	invert_y_axis = config.get_value("controls", "invert_y_axis", invert_y_axis)
	
	field_of_view = config.get_value("gameplay", "field_of_view", field_of_view)
	
	print("GameSettings: Settings loaded from ", _settings_path)
	_apply_all_settings()


func reset_to_defaults():
	vsync_enabled = true
	max_fps = 0
	fullscreen = false
	resolution = Vector2i(1920, 1080)
	master_volume = 0.8
	music_volume = 0.7
	sfx_volume = 0.8
	mouse_sensitivity = 0.3
	invert_y_axis = false
	field_of_view = 85
	
	_apply_all_settings()
	
	if auto_save:
		save_settings()
	
	print("GameSettings: Settings reset to defaults")


# Public getters
func get_vsync_enabled() -> bool:
	return vsync_enabled

func get_max_fps() -> int:
	return max_fps

func get_fullscreen() -> bool:
	return fullscreen

func get_resolution() -> Vector2i:
	return resolution

func get_master_volume() -> float:
	return master_volume

func get_music_volume() -> float:
	return music_volume

func get_sfx_volume() -> float:
	return sfx_volume

func get_mouse_sensitivity() -> float:
	return mouse_sensitivity

func get_invert_y_axis() -> bool:
	return invert_y_axis

func get_field_of_view() -> int:
	return field_of_view
