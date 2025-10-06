extends Node

# Persistent music player - survives scene changes
# This should be set as AutoLoad in Project Settings

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

# Configure your background music here
const BACKGROUND_MUSIC = preload("res://sounds/music/platformer_game_soundtrack-001.ogg")  # Change this to your music file
const MENU_VOLUME_DB = -15.0  # Volume in menus (faded down 4-6 dB from original -10)
const GAMEPLAY_VOLUME_DB = -20.0  # Volume during gameplay (even quieter)

var current_volume_db: float = MENU_VOLUME_DB
var target_volume_db: float = MENU_VOLUME_DB
var is_in_gameplay: bool = false

func _ready():
	# Set up the music player
	add_child(music_player)
	music_player.stream = BACKGROUND_MUSIC
	music_player.volume_db = current_volume_db
	music_player.autoplay = false  # We'll start it manually
	
	# Add audio effects for better sound processing
	_setup_audio_effects()
	
	# Make it loop
	if BACKGROUND_MUSIC:
		# Note: You need to set the loop property in the .ogg.import file
		# Or we can connect the finished signal to restart
		music_player.finished.connect(_on_music_finished)
	
	# Start playing
	play_music()
	print("Persistent music player initialized")

func _setup_audio_effects():
	# Create a dedicated music bus for better control
	AudioServer.add_bus(1)
	AudioServer.set_bus_name(1, "Music")
	AudioServer.set_bus_send(1, "Master")
	
	# Set the music player to use the music bus
	music_player.bus = "Music"
	
	# Add a mild low-pass filter for atmospheric sound
	var lowpass_effect = AudioEffectLowPassFilter.new()
	lowpass_effect.cutoff_hz = 8000.0  # Mild low-pass at 8kHz
	lowpass_effect.resonance = 0.7     # Slight resonance for smoothness
	AudioServer.add_bus_effect(1, lowpass_effect)
	
	# Add EQ for background music (more atmospheric settings)
	var eq_effect = AudioEffectEQ10.new()
	
	# Adjust EQ for more atmospheric, less intrusive sound
	eq_effect.set_band_gain_db(0, -3.0)   # 31 Hz - reduce low rumble more
	eq_effect.set_band_gain_db(1, -2.0)   # 62 Hz - reduction
	eq_effect.set_band_gain_db(2, -1.0)   # 125 Hz - slight reduction
	eq_effect.set_band_gain_db(3, 0.5)    # 250 Hz - slight boost for warmth
	eq_effect.set_band_gain_db(4, 1.0)    # 500 Hz - boost for presence
	eq_effect.set_band_gain_db(5, -0.5)   # 1 kHz - slight reduction
	eq_effect.set_band_gain_db(6, -2.5)   # 2 kHz - reduce harsh frequencies more
	eq_effect.set_band_gain_db(7, -3.0)   # 4 kHz - significant reduction for atmosphere
	eq_effect.set_band_gain_db(8, -2.5)   # 8 kHz - reduction (works with low-pass)
	eq_effect.set_band_gain_db(9, -4.0)   # 16 kHz - significant reduction (atmospheric)
	
	AudioServer.add_bus_effect(1, eq_effect)

func _process(delta):
	# Auto-detect gameplay vs menu based on current scene
	_auto_detect_game_state()
	
	# Smooth volume transitions
	if abs(current_volume_db - target_volume_db) > 0.1:
		current_volume_db = lerp(current_volume_db, target_volume_db, delta * 2.0)
		music_player.volume_db = current_volume_db

func _auto_detect_game_state():
	# Check current scene to determine if we're in gameplay or menu
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_name = current_scene.name.to_lower()
		var scene_path = current_scene.scene_file_path.to_lower()
		
		# Check if we're in a level (gameplay)
		var was_in_gameplay = is_in_gameplay
		is_in_gameplay = ("level" in scene_name or "level" in scene_path) and not ("manager" in scene_name or "manager" in scene_path)
		
		# Update volume target if state changed
		if was_in_gameplay != is_in_gameplay:
			if is_in_gameplay:
				target_volume_db = GAMEPLAY_VOLUME_DB
			else:
				target_volume_db = MENU_VOLUME_DB

func play_music():
	if not music_player.playing:
		music_player.play()
		print("Background music started")

func stop_music():
	if music_player.playing:
		music_player.stop()
		print("Background music stopped")

func pause_music():
	if music_player.playing:
		music_player.stream_paused = true
		print("Background music paused")

func resume_music():
	if music_player.stream_paused:
		music_player.stream_paused = false
		print("Background music resumed")

func set_volume(volume_db: float):
	target_volume_db = volume_db

func set_menu_mode():
	# Switch to menu volume (louder)
	is_in_gameplay = false
	target_volume_db = MENU_VOLUME_DB
	print("Music: Switched to menu mode")

func set_gameplay_mode():
	# Switch to gameplay volume (quieter)
	is_in_gameplay = true
	target_volume_db = GAMEPLAY_VOLUME_DB
	print("Music: Switched to gameplay mode")

func _on_music_finished():
	# Restart the music when it finishes (manual looping)
	music_player.play()
	print("Background music looped")
