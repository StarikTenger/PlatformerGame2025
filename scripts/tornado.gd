extends Area2D

var lift_acceleration := 5000.0
var direction := Vector2.UP

@onready var death_sound_player: AudioStreamPlayer2D = $CollisionShape2D/AudioStreamPlayer2D
@onready var loop_player: AudioStreamPlayer2D = $CollisionShape2D/AudioStreamPlayer2D_LOOP

func _ready():
	# Play the death sound first
	death_sound_player.play()
	# Connect the death sound finished signal to start the loop
	death_sound_player.finished.connect(_on_death_sound_finished)

func _on_death_sound_finished():
	# Start the looping sound when death sound finishes
	loop_player.play()

func _physics_process(delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("liftable"):
			body.velocity.y -= lift_acceleration * delta
