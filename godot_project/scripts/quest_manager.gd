extends Node
## Autoload QuestManager: estado de misiones (aceptar, progreso por muertes,
## completar con recompensas y desbloqueo). Lee definiciones de GameData.
## Aceptados repetidos se ignoran (retorna false).

signal quest_updated

var active: Dictionary = {}  # quest_id -> {"count": int}
var done: Array[String] = []


func available_quests() -> Array[String]:
	var out: Array[String] = []
	var game_data := get_node_or_null("/root/GameData")
	if game_data == null:
		return out
	for qid in game_data.quests:
		if active.has(qid) or done.has(qid):
			continue
		var q: Dictionary = game_data.quests[qid]
		var req = q.get("requires")
		if req == null or done.has(str(req)):
			out.append(str(qid))
	return out


func npc_available_quests(npc_id: String) -> Array[String]:
	var out: Array[String] = []
	var game_data := get_node_or_null("/root/GameData")
	if game_data == null:
		return out
	var npc: Dictionary = game_data.npcs.get(npc_id, {})
	for qid in npc.get("quests_available", []):
		if available_quests().has(str(qid)):
			out.append(str(qid))
	return out


func accept_quest(quest_id: String) -> bool:
	if active.has(quest_id) or done.has(quest_id):
		return false
	var game_data := get_node_or_null("/root/GameData")
	if game_data == null or not game_data.quests.has(quest_id):
		return false
	if not available_quests().has(quest_id):
		return false
	active[quest_id] = {"count": 0}
	print("[Quest] aceptada: %s" % quest_id)
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx("quest_accept")
	quest_updated.emit()
	return true


func report_kill(monster_id: String) -> void:
	var game_data := get_node_or_null("/root/GameData")
	if game_data == null:
		return
	var changed := false
	for qid in active.keys():
		var q: Dictionary = game_data.quests[qid]
		var tgt: Dictionary = q.get("target", {})
		if tgt.get("type") == "kill" and str(tgt.get("monster_id")) == monster_id:
			active[qid]["count"] += 1
			changed = true
			print("[Quest] %s progreso: %d/%d" % [qid, active[qid]["count"], int(tgt.get("count", 0))])
			if active[qid]["count"] >= int(tgt.get("count", 0)):
				_complete(qid)
	if changed:
		quest_updated.emit()


func progress(quest_id: String) -> Array:
	## Retorna [actual, requerido] o [] si no está activa.
	var game_data := get_node_or_null("/root/GameData")
	if not active.has(quest_id) or game_data == null:
		return []
	var q: Dictionary = game_data.quests.get(quest_id, {})
	return [int(active[quest_id]["count"]), int(q.get("target", {}).get("count", 0))]


func first_active() -> String:
	## Primera misión activa (para el tracker del HUD).
	if active.is_empty():
		return ""
	return str(active.keys()[0])


func reset() -> void:
	active.clear()
	done.clear()
	quest_updated.emit()


func _complete(quest_id: String) -> void:
	var game_data: Node = get_node("/root/GameData")
	var q: Dictionary = game_data.quests[quest_id]
	active.erase(quest_id)
	if bool(q.get("repeatable", false)):
		print("[Quest] contrato repetible: %s vuelve a estar disponible" % quest_id)
	else:
		done.append(quest_id)
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.add_exp(float(q.get("rewards", {}).get("exp", 0)))
		for item_id in q.get("rewards", {}).get("items", []):
			player.add_item(str(item_id), 1)
	print("[Quest] completada: %s (desbloquea %s)" % [quest_id, str(q.get("unlocks"))])
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx("reward")
		audio.play_sting("sting_quest")
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr != null:
		save_mgr.save_game()
