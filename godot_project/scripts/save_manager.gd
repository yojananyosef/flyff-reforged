extends Node
## Autoload SaveManager: una ranura local en `user://aethermere_save.json`.
## Guarda zona, posicion, stats, oro, inventario, equipo y misiones.
## Corrupto = aviso + partida nueva (el archivo se renombra a .bak).

const SAVE_PATH := "user://aethermere_save.json"
const SAVE_VERSION := 1


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	var game_data = get_node_or_null("/root/GameData")
	var quest_mgr = get_node_or_null("/root/QuestManager")
	if player == null or game_data == null or quest_mgr == null:
		push_warning("[Save] no se pudo guardar (nodos no listos)")
		return false
	var data := {
		"version": SAVE_VERSION,
		"zone": game_data.current_zone_id,
		"pos": [player.global_position.x, player.global_position.y, player.global_position.z],
		"level": player.level,
		"exp": player.exp,
		"max_exp": player.max_exp,
		"hp": player.hp,
		"max_hp": player.max_hp,
		"mp": player.mp,
		"max_mp": player.max_mp,
		"gold": player.gold,
		"inventory": player.inventory,
		"equipment": player.equipment,
		"quests_active": quest_mgr.active,
		"quests_done": quest_mgr.done,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("[Save] no se pudo escribir " + SAVE_PATH)
		return false
	file.store_string(JSON.stringify(data, "  "))
	print("[Save] partida guardada")
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary) or int(parsed.get("version", 0)) != SAVE_VERSION:
		push_warning("[Save] archivo corrupto o incompatible; se empieza de nuevo")
		_quarantine()
		return false
	var player = get_tree().get_first_node_in_group("player")
	var game_data = get_node_or_null("/root/GameData")
	var quest_mgr = get_node_or_null("/root/QuestManager")
	if player == null or game_data == null or quest_mgr == null:
		return false
	var d: Dictionary = parsed
	game_data.current_zone_id = str(d.get("zone", game_data.current_zone_id))
	var pos: Array = d.get("pos", [0, 1, 0])
	player.global_position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
	player.level = int(d.get("level", 1))
	player.exp = float(d.get("exp", 0.0))
	player.max_exp = float(d.get("max_exp", 100.0))
	player.hp = float(d.get("hp", player.max_hp))
	player.mp = float(d.get("mp", player.max_mp))
	player.gold = int(d.get("gold", 30))
	player.inventory = dict_int_values(d.get("inventory", {}))
	player.equipment = d.get("equipment", {"weapon": "", "armor": ""})
	player.inventory_version += 1
	quest_mgr.active = d.get("quests_active", {})
	var done: Array[String] = []
	for qid in d.get("quests_done", []):
		done.append(str(qid))
	quest_mgr.done = done
	quest_mgr.quest_updated.emit()
	print("[Save] partida cargada (zona %s, nivel %d)" % [game_data.current_zone_id, player.level])
	return true


func new_game() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var quest_mgr = get_node_or_null("/root/QuestManager")
	if quest_mgr != null and quest_mgr.has_method("reset"):
		quest_mgr.reset()
	print("[Save] nueva partida")
	get_tree().reload_current_scene()


func dict_int_values(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[str(k)] = int(d[k])
	return out


func _quarantine() -> void:
	var bak := SAVE_PATH + ".bak"
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH),
		ProjectSettings.globalize_path(bak))
