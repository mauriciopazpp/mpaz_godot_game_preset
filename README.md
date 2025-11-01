# MPAZ Game Preset

Game settings system for Godot 4 with automatic persistence. Manage video, audio, controls, and gameplay settings with a simple, ready-to-use solution.

## Features

### Core Settings
- **Video**: V-Sync, Max FPS, Fullscreen, Resolution
- **Audio**: Master/Music/SFX volume with Audio Bus support
- **Controls**: Mouse sensitivity, Invert Y axis
- **Gameplay**: Field of View (FOV) configuration
- **Automatic Persistence**: Saves to `user://game_settings.cfg`
- **Signal System**: React to setting changes in real-time

### Quality of Life
- Automatic saving when settings change
- Load settings on game start
- Reset to defaults functionality
- Independent plugin (no dependencies)
- Works with any game genre

## How to Use

### Installation

1. Enable the plugin in `Project Settings > Plugins`
2. Add GameSettings to your main scene:
   - Create a Node in your scene
   - Attach script: `res://addons/mpaz_game_preset/scripts/game_settings.gd`
   - Or use the class directly: Add Node > Search "GameSettings"

### Configuration

Configure in the Inspector:

#### Node References
- **Player Reference**: Drag your player node here (required for mouse sensitivity, invert Y, and FOV)

#### Video Settings
- **Vsync Enabled**: Vertical synchronization (default: true)
- **Max FPS**: FPS limit, 0 = unlimited (default: 0)
- **Fullscreen**: Window mode (default: false)
- **Resolution**: Window resolution (default: 1920x1080)

#### Audio Settings
- **Master Volume**: Overall volume (default: 0.8)
- **Music Volume**: Music bus volume (default: 0.7)
- **SFX Volume**: Sound effects bus volume (default: 0.8)

#### Control Settings
- **Mouse Sensitivity**: Look speed (default: 0.3)
- **Invert Y Axis**: Flight sim style (default: false)

#### Gameplay Settings
- **Field of View**: Camera FOV in degrees (default: 85)

#### System Settings
- **Auto Save**: Save automatically on change (default: true)
- **Load on Ready**: Load settings at startup (default: true)

### Setting Up Audio Buses

For volume controls to work properly, create audio buses:

1. Go to **Audio > Manage Audio Buses**
2. Add buses:
   - `Music` (child of Master)
   - `SFX` (child of Master)
3. Set your AudioStreamPlayers to use the correct bus

### Player Integration

For mouse sensitivity and invert Y to work, add these methods to your player:

```gdscript
extends CharacterBody3D

var mouse_sensitivity: float = 0.3
var invert_y: bool = false

func set_mouse_sensitivity(value: float):
	mouse_sensitivity = value

func set_invert_y(value: bool):
	invert_y = value

func _input(event):
	if event is InputEventMouseMotion:
		var y_direction = -1.0 if invert_y else 1.0
		rotate_y(-event.relative.x * mouse_sensitivity * 0.001)
		camera.rotate_x(event.relative.y * mouse_sensitivity * 0.001 * y_direction)
```

## API Reference

### Manual Saving/Loading

```gdscript
# Get reference
var settings = $GameSettings

# Save manually
settings.save_settings()

# Load manually
settings.load_settings()

# Reset to defaults
settings.reset_to_defaults()
```

### Getting Values

```gdscript
var fps = settings.get_max_fps()
var volume = settings.get_master_volume()
var sensitivity = settings.get_mouse_sensitivity()
var fov = settings.get_field_of_view()
```

### Reacting to Changes

```gdscript
func _ready():
	$GameSettings.setting_changed.connect(_on_setting_changed)

func _on_setting_changed(setting_name: String, value):
	print("Setting changed: ", setting_name, " = ", value)
	
	match setting_name:
		"vsync_enabled":
			update_vsync_ui(value)
		"master_volume":
			update_volume_ui(value)
```

### Creating an Options Menu

Example of settings menu integration:

```gdscript
extends Control

@onready var settings = $"/root/Main/GameSettings"

func _ready():
	# Load current values into UI
	$VSync/CheckButton.button_pressed = settings.vsync_enabled
	$MaxFPS/SpinBox.value = settings.max_fps
	$MasterVolume/Slider.value = settings.master_volume * 100
	$MouseSens/Slider.value = settings.mouse_sensitivity * 100
	
	# Connect UI changes to settings
	$VSync/CheckButton.toggled.connect(func(enabled): settings.vsync_enabled = enabled)
	$MaxFPS/SpinBox.value_changed.connect(func(value): settings.max_fps = value)
	$MasterVolume/Slider.value_changed.connect(func(value): settings.master_volume = value / 100.0)
	$MouseSens/Slider.value_changed.connect(func(value): settings.mouse_sensitivity = value / 100.0)
```

## Settings Reference

### Video Settings

| Setting | Type | Range | Default | Description |
|---------|------|-------|---------|-------------|
| vsync_enabled | bool | - | true | Vertical synchronization |
| max_fps | int | 0-500 | 0 | FPS limit (0 = unlimited) |
| fullscreen | bool | - | false | Fullscreen mode |
| resolution | Vector2i | - | 1920x1080 | Window resolution |

### Audio Settings

| Setting | Type | Range | Default | Description |
|---------|------|-------|---------|-------------|
| master_volume | float | 0.0-1.0 | 0.8 | Master volume |
| music_volume | float | 0.0-1.0 | 0.7 | Music bus volume |
| sfx_volume | float | 0.0-1.0 | 0.8 | SFX bus volume |

### Control Settings

| Setting | Type | Range | Default | Description |
|---------|------|-------|---------|-------------|
| mouse_sensitivity | float | 0.05-2.0 | 0.3 | Mouse look speed |
| invert_y_axis | bool | - | false | Invert vertical look |

### Gameplay Settings

| Setting | Type | Range | Default | Description |
|---------|------|-------|---------|-------------|
| field_of_view | int | 60-120 | 85 | Camera FOV in degrees |

## Configuration File

Settings are saved to: `user://game_settings.cfg`

Example file structure:

```ini
[video]
vsync_enabled=true
max_fps=0
fullscreen=false
resolution_x=1920
resolution_y=1080

[audio]
master_volume=0.8
music_volume=0.7
sfx_volume=0.8

[controls]
mouse_sensitivity=0.3
invert_y_axis=false

[gameplay]
field_of_view=85
```

## Performance Tips

### High Performance (200+ FPS)
```gdscript
settings.vsync_enabled = false
settings.max_fps = 0
```

### Battery Saving
```gdscript
settings.vsync_enabled = true
settings.max_fps = 60
```

### High Refresh Rate Monitors (144Hz+)
```gdscript
settings.vsync_enabled = false
settings.max_fps = 144  # or 165, 240
```

## Recommended Settings by Game Type

### Competitive FPS
- V-Sync: OFF
- Max FPS: 0 (unlimited)
- Mouse Sensitivity: 0.2-0.4
- FOV: 90-110

### Single-Player
- V-Sync: ON
- Max FPS: 60
- Mouse Sensitivity: 0.3-0.5
- FOV: 80-90

### Casual Games
- V-Sync: ON
- Max FPS: 60
- Fullscreen: OFF
- FOV: 75-85

## Troubleshooting

### V-Sync Not Disabling
- Check if GPU driver is forcing V-Sync
- Try setting `max_fps = 0` for unlimited FPS

### Volume Not Working
- Create Audio Buses: Master, Music, SFX
- Ensure AudioStreamPlayers are on the correct bus
- Check that bus names match exactly

### Mouse Sensitivity Not Applying
- Drag player to `player_reference` in Inspector
- Add `set_mouse_sensitivity()` method to your player script
- See "Player Integration" section above

### FOV Not Changing
- Ensure player has a Camera3D child
- Player must be in scene tree when FOV is applied
- Camera must be accessible via `get_camera()` or as direct child

### Settings Not Persisting
- Enable `auto_save` in System settings
- Manually call `save_settings()` if auto-save is off
- Check write permissions for `user://` directory

## Compatibility

- **Godot**: 4.x
- **Game Types**: All (FPS, RPG, Platformer, Racing, etc.)
- **Platforms**: All platforms supported by Godot

## Technical Details

### APIs Used
- `DisplayServer` - Window management (vsync, fullscreen, resolution)
- `Engine.max_fps` - FPS limiting
- `AudioServer` - Volume control via bus system
- `ConfigFile` - Settings persistence

### Architecture
- **Class Name**: GameSettings
- **Extends**: Node
- **Signal**: `setting_changed(setting_name: String, value)`
- **Persistence**: ConfigFile (.cfg format)

## Credits

- Author: Mauricio Paz
- Instagram: @mauricio.paz.p
- LinkedIn: https://www.linkedin.com/in/m-paz/
