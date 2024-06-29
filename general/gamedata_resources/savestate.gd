class_name Savestate
extends Resource

const SAVEFILE_DIRECTORY := "user://saves"
const SAVEFILE_PATH := SAVEFILE_DIRECTORY + "/savegame.tres"

## values are the card types
@export var stockpile: Array[int]
## array of 10 tableau piles, each holding an array with every card [type + visible]
@export var tableau_piles: Array[TableauPile] = []
## values are the card colors
@export var completed_stacks: Array[int] = []

@export var mode: Gamestate.Mode


func save() -> void:
	DirAccess.make_dir_absolute(SAVEFILE_DIRECTORY)
	ResourceSaver.save(self, SAVEFILE_PATH)


static func load() -> Savestate:
	var savestate := SafeResourceLoader.load(SAVEFILE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Savestate
	
	if savestate == null:
		print("Could not load save file")
		return null
	
	return savestate


static func delete() -> void:
	if exists():
		DirAccess.remove_absolute(SAVEFILE_PATH)


static func exists() -> bool:
	return ResourceLoader.exists(SAVEFILE_PATH)
