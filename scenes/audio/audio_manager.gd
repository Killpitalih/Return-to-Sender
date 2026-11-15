
extends Node

@onready var music: AudioStreamPlayer = $Music


# Plays a short sound effect.
# Each sound gets its own temporary player.
func play_sfx(
	sound: AudioStream,
	volume_db: float = -4.0,
	pitch: float = 1.0
) -> void:
	if sound == null:
		return

	var sound_player := AudioStreamPlayer.new()

	sound_player.stream = sound
	sound_player.bus = &"SFX"
	sound_player.volume_db = volume_db
	sound_player.pitch_scale = pitch

	add_child(sound_player)

	# Remove the temporary player after sound ends
	sound_player.finished.connect(sound_player.queue_free)

	sound_player.play()


# Useful when we add more levels with different music.
func play_music(track: AudioStream) -> void:
	if track == null:
		return

	if music.stream == track and music.playing:
		return

	music.stream = track
	music.play()
