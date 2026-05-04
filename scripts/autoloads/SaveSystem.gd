extends Node

const SAVE_DIR: String = "user://profiles/"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_profile(profile_name: String, data: Dictionary) -> void:
	var path := SAVE_DIR + profile_name + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))

func load_profile(profile_name: String) -> Dictionary:
	var path := SAVE_DIR + profile_name + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var result: Variant = JSON.parse_string(file.get_as_text())
	return result if result is Dictionary else {}

func get_profiles() -> Array[String]:
	var profiles: Array[String] = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				profiles.append(file_name.trim_suffix(".json"))
			file_name = dir.get_next()
	return profiles

func profile_exists(profile_name: String) -> bool:
	return FileAccess.file_exists(SAVE_DIR + profile_name + ".json")

func delete_profile(profile_name: String) -> void:
	DirAccess.remove_absolute(SAVE_DIR + profile_name + ".json")
