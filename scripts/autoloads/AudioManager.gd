extends Node

const SFX_POOL_SIZE: int = 8

## Bestanden die (nog) ontbreken worden stil overgeslagen; zie boodschappenlijst.md.
const SFX_PATHS: Dictionary = {
	"coin":      "res://assets/audio/sfx/coin.ogg",
	"punch":     "res://assets/audio/sfx/punch.ogg",
	"powerup":   "res://assets/audio/sfx/powerup.ogg",
	"footstep":  "res://assets/audio/sfx/footstep_wood_001.ogg",
	"jump":      "res://assets/audio/sfx/jump.ogg",
	"hurt":      "res://assets/audio/sfx/hurt.ogg",
	"enemy_die": "res://assets/audio/sfx/enemy_die.ogg",
	"level_win": "res://assets/audio/sfx/level_win.ogg",
	"game_over": "res://assets/audio/sfx/game_over.ogg",
}

const MUSIC_PATHS: Dictionary = {
	"world1": "res://assets/audio/music/Living Voyage.mp3",
}

const SETTINGS_PATH := "user://settings.json"

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}
var _current_music: String = ""

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)

	_load_settings()

## Maakt de bus aan als die nog niet bestaat, i.p.v. te leunen op een
## project-brede default_bus_layout.tres (die bleek fragiel bij het openen
## van het project in de editor).
func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")

func play_music_by_name(music_name: String) -> void:
	if _current_music == music_name and _music_player.playing:
		return
	var stream := _load_music(music_name)
	if stream == null:
		return
	_current_music = music_name
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_music_player.stream = stream
	_music_player.play()

func play_music(stream: AudioStream) -> void:
	if _music_player.stream == stream and _music_player.playing:
		return
	_current_music = ""
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	_current_music = ""
	_music_player.stop()

func play_sfx_by_name(sfx_name: String) -> void:
	var stream := _load_sfx(sfx_name)
	if stream != null:
		play_sfx(stream)

func play_sfx(stream: AudioStream) -> void:
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return

func _load_sfx(sfx_name: String) -> AudioStream:
	if _sfx_cache.has(sfx_name):
		return _sfx_cache[sfx_name]
	var path: String = SFX_PATHS.get(sfx_name, "")
	var stream: AudioStream = null
	if path != "" and ResourceLoader.exists(path):
		stream = load(path)
	_sfx_cache[sfx_name] = stream
	return stream

func _load_music(music_name: String) -> AudioStream:
	if _music_cache.has(music_name):
		return _music_cache[music_name]
	var path: String = MUSIC_PATHS.get(music_name, "")
	var stream: AudioStream = null
	if path != "" and ResourceLoader.exists(path):
		stream = load(path)
	_music_cache[music_name] = stream
	return stream

## Los van spelprofielen: geladen bij het opstarten, vóór er een profiel gekozen is.
func set_bus_volume(bus_name: String, linear: float) -> void:
	_apply_bus_volume(bus_name, linear)
	_save_settings()

func set_bus_mute(bus_name: String, muted: bool) -> void:
	_apply_bus_mute(bus_name, muted)
	_save_settings()

func _apply_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0, 1.0)))

func _apply_bus_mute(bus_name: String, muted: bool) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted)

func get_bus_volume(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	return db_to_linear(AudioServer.get_bus_volume_db(idx)) if idx >= 0 else 1.0

func get_bus_mute(bus_name: String) -> bool:
	var idx := AudioServer.get_bus_index(bus_name)
	return AudioServer.is_bus_mute(idx) if idx >= 0 else false

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not (data is Dictionary):
		return
	var d: Dictionary = data
	if d.has("music_volume"):
		_apply_bus_volume("Music", d["music_volume"])
	if d.has("sfx_volume"):
		_apply_bus_volume("SFX", d["sfx_volume"])
	if d.has("music_muted"):
		_apply_bus_mute("Music", d["music_muted"])
	if d.has("sfx_muted"):
		_apply_bus_mute("SFX", d["sfx_muted"])

func _save_settings() -> void:
	var data := {
		"music_volume": get_bus_volume("Music"),
		"sfx_volume":   get_bus_volume("SFX"),
		"music_muted":  get_bus_mute("Music"),
		"sfx_muted":    get_bus_mute("SFX"),
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
