extends Node
## Autoload GameData: carga los JSON de `data/` y expone la zona actual.
##
## Busca los datos en `res://../data/` (layout del repo: `godot_project/`
## junto a `data/`) con repliegue a `res://data/` (datos copiados dentro
## del proyecto, p. ej. al exportar).

const DATA_FILES := ["zones.json", "dialogues.json", "items.json",
	"monsters.json", "npcs.json", "quests.json", "skills.json"]

const FALLBACK_ZONE := {
	"id": "ironhold",
	"display_name": "Ironhold",
	"original_asset_dir": "WdMadrigal",
	"description": "Walled barley town on the edge of the fen.",
	"level_range": [1, 5],
	"npcs": [],
	"monsters": [],
	"spawn_point": [0, 1, 0],
}

var zones: Dictionary = {}
var dialogues: Dictionary = {}
var items: Dictionary = {}
var monsters: Dictionary = {}
var npcs: Dictionary = {}
var quests: Dictionary = {}
var skills: Dictionary = {}
var current_zone_id: String = "ironhold"
var _build: Dictionary = {}


func build_tag() -> String:
	## Sello del export web (`data/build.json`, solo staging) o "dev".
	return str(_build.get("tag", "dev"))


func _ready() -> void:
	zones = _load_dict("zones.json")
	dialogues = _load_dict("dialogues.json")
	items = _load_dict("items.json")
	monsters = _load_dict("monsters.json")
	npcs = _load_dict("npcs.json")
	quests = _load_dict("quests.json")
	skills = _load_dict("skills.json")
	_build = _load_build()
	if not zones.has(current_zone_id):
		if zones.is_empty():
			zones[current_zone_id] = FALLBACK_ZONE
		else:
			current_zone_id = str(zones.keys()[0])
	print("[GameData] zona actual: %s (%s)" % [current_zone_id, get_zone_display_name()])


func get_current_zone() -> Dictionary:
	return zones.get(current_zone_id, FALLBACK_ZONE)


func get_zone_display_name() -> String:
	return str(get_current_zone().get("display_name", current_zone_id))


func get_zone_spawn() -> Vector3:
	var sp: Array = get_current_zone().get("spawn_point", [0, 1, 0])
	return Vector3(float(sp[0]), float(sp[1]), float(sp[2]))


func get_dialogue(dialogue_id: String) -> Dictionary:
	return dialogues.get(dialogue_id, {})


func get_item_name(item_id: String) -> String:
	return str(items.get(item_id, {}).get("name", item_id))


static var _ui_warned := false

func ui_texture(filename: String):
	## Textura UI del cliente o null (repliegue elegante sin setup).
	var path := "res://textures/ui/" + filename
	# ResourceLoader (no FileAccess): en exportados la textura va remapeada.
	if not ResourceLoader.exists(path):
		if not _ui_warned:
			_ui_warned = true
			push_warning("[GameData] sin texturas UI: ejecuta setup_ui_textures.py")
		return null
	return load(path)


func _candidate_paths(filename: String) -> Array[String]:
	return ["res://../data/" + filename, "res://data/" + filename]


func _load_build() -> Dictionary:
	for path in _candidate_paths("build.json"):
		if not FileAccess.file_exists(path):
			continue
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			return parsed
	return {}


func _load_dict(filename: String) -> Dictionary:
	for path in _candidate_paths(filename):
		if not FileAccess.file_exists(path):
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_warning("[GameData] no se pudo abrir " + path)
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed == null:
			push_warning("[GameData] JSON invalido en " + path)
			continue
		var out: Dictionary = {}
		if parsed is Array:
			for row in parsed:
				if row is Dictionary and row.has("id"):
					out[str(row["id"])] = row
		elif parsed is Dictionary:
			out = parsed
		print("[GameData] cargado %s (%d entradas)" % [path, out.size()])
		return out
	push_warning("[GameData] no encontrado: " + filename)
	return {}
