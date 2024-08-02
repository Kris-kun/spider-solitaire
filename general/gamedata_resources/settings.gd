class_name Settings
extends Resource

const SAVEFILE_DIRECTORY := "user://conf"
const SAVEFILE_PATH := SAVEFILE_DIRECTORY + "/settings.tres"

## Do not save this variable "permanently" anywhere.
## This variable point to another object when settings are changed
## Always use Settings.global or only save it temporarily inside a function for ease of use
static var global: Settings

@export var animation_time_multiplier := 1.0


static func _static_init() -> void:
	if exists():
		global = Settings.load()
	if global == null:
		global = Settings.new()


static func save() -> void:
	DirAccess.make_dir_absolute(SAVEFILE_DIRECTORY)
	ResourceSaver.save(global, SAVEFILE_PATH)


static func load() -> Settings:
	var settings := SafeResourceLoader.load(SAVEFILE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Settings
	
	if settings == null:
		print("Could not load settings file")
		return null
	
	return settings


static func delete() -> void:
	if exists():
		DirAccess.remove_absolute(SAVEFILE_PATH)


static func exists() -> bool:
	return ResourceLoader.exists(SAVEFILE_PATH)
