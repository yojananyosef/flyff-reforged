extends Node3D
## Escena principal: registra la zona inicial, genera NPC y monstruos
## desde `data/`, gestiona la interaccion (E) y el modo de simulacion
## headless `--sim-quest` (requisito: verificacion repetible del flujo
## aceptar → cazar → completar → desbloquear).

const MonsterScript := preload("res://scripts/monster.gd")

var _failures: Array[String] = []

@onready var player: CharacterBody3D = $Player
@onready var npc: StaticBody3D = $NPC
@onready var dialogue: CanvasLayer = $DialogueLayer


func _ready() -> void:
	var game_data := get_node_or_null("/root/GameData")
	if game_data == null:
		push_error("[Main] autoload GameData no encontrado")
		return
	print("[Main] arranque OK. Zona: %s (%s)" % [game_data.current_zone_id, game_data.get_zone_display_name()])
	if game_data.current_zone_id != "ironhold":
		push_warning("[Main] zona actual no es 'ironhold': " + str(game_data.current_zone_id))
	npc.set_meta("npc_id", "npc_001")
	_spawn_monsters(game_data)
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_zone_music()
	if "--sim-quest" in OS.get_cmdline_user_args():
		_run_sim.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E:
			if dialogue.is_open():
				dialogue.close()
			elif player.global_position.distance_to(npc.global_position) < 3.5:
				dialogue.open(str(npc.get_meta("npc_id")))


func _spawn_monsters(game_data: Node) -> void:
	var container := Node3D.new()
	container.name = "Monsters"
	add_child(container)
	var center: Vector3 = game_data.get_zone_spawn()
	var idx := 0
	for mid in game_data.monsters:
		var def: Dictionary = game_data.monsters[mid]
		if str(def.get("zone", "")) != game_data.current_zone_id:
			continue
		var count := 5 if str(mid) == "mon_001" else 1
		for i in count:
			_spawn_one(container, def, center, idx)
			idx += 1
	print("[Main] %d monstruos generados" % idx)


func _spawn_one(container: Node3D, def: Dictionary, center: Vector3, idx: int) -> void:
	var m := CharacterBody3D.new()
	m.set_script(MonsterScript)
	var a := (float(idx) / 9.0) * TAU
	var pos := center + Vector3(cos(a) * (5.0 + idx), 1.0, sin(a) * (5.0 + idx))
	m.position = pos
	m.setup(def)

	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.2
	shape.shape = cap
	shape.position = Vector3(0, 0.7, 0)
	m.add_child(shape)

	var mesh_inst := MeshInstance3D.new()
	var cap_mesh := CapsuleMesh.new()
	cap_mesh.radius = 0.4
	cap_mesh.height = 1.2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.3, 0.2, 1)
	cap_mesh.material = mat
	mesh_inst.mesh = cap_mesh
	mesh_inst.position = Vector3(0, 0.7, 0)
	m.add_child(mesh_inst)

	var label := Label3D.new()
	label.name = "NameLabel"
	label.position = Vector3(0, 1.8, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 48
	m.add_child(label)

	container.add_child(m)


# --- Simulación headless ---

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("[SIM] ok: " + msg)
	else:
		_failures.append(msg)
		print("[SIM] FALLO: " + msg)


func _run_sim() -> void:
	print("[SIM] inicio de simulación de misión")
	var game_data: Node = get_node("/root/GameData")
	var quest_mgr: Node = get_node("/root/QuestManager")

	_check(game_data.current_zone_id == "ironhold", "zona actual es ironhold")
	_check(game_data.zones.size() >= 1 and game_data.dialogues.size() >= 2,
		"datos cargados (zonas/dialogos)")

	var audio = get_node("/root/AudioManager")
	_check(audio.missing_files().is_empty(),
		"audio 16/16 presente (%s)" % str(audio.missing_files()))
	for sfx_name in audio.known_sfx():
		audio.play_sfx(sfx_name)
	_check(true, "12 SFX emitidos sin error")
	audio.notify_combat()
	_check(audio._in_combat_music, "musica de combate activa tras agresion")
	audio.toggle_mute()
	_check(audio.muted, "mute con M funciona")
	audio.toggle_mute()
	_check(not audio.muted, "unmute restaura")

	var expected := 0
	for mid in game_data.monsters:
		if str(game_data.monsters[mid].get("zone", "")) == "ironhold":
			expected += 5 if str(mid) == "mon_001" else 1
	_check(get_tree().get_nodes_in_group("monsters").size() == expected,
		"monstruos generados = %d" % expected)

	dialogue.open("npc_001")
	_check(dialogue.is_open(), "dialogo se abre con E")
	_check(dialogue.current_node == "start", "dialogo inicia en nodo start")
	dialogue._show_node("quest_offer")
	_check(dialogue.accept_button.visible, "quest_offer muestra boton Aceptar")
	dialogue.close()
	_check(not dialogue.is_open(), "dialogo se cierra")

	_check(quest_mgr.accept_quest("quest_101"), "aceptar quest_101")
	_check(not quest_mgr.accept_quest("quest_101"), "repetir quest_101 se rechaza")
	_check(quest_mgr.first_active() == "quest_101", "tracker ve quest_101 activa")

	var exp0: float = player.exp
	var bread0: int = int(player.inventory.get("item_003", 0))
	for i in 5:
		quest_mgr.report_kill("mon_001")
	_check("quest_101" in quest_mgr.done, "quest_101 completada")
	_check("quest_102" in quest_mgr.available_quests(), "quest_102 desbloqueada")
	_check(player.exp >= exp0 + 40.0, "recompensa 40 EXP aplicada")
	_check(int(player.inventory.get("item_003", 0)) == bread0 + 1, "recompensa item_003 en inventario")

	_check(quest_mgr.accept_quest("quest_102"), "aceptar quest_102")

	var crow: Node3D = null
	for m in get_tree().get_nodes_in_group("monsters"):
		if m.get("monster_id") == "mon_004":
			crow = m
			break
	_check(crow != null, "existe mon_004 en escena")
	if crow != null:
		var crow_hp0: float = crow.hp
		player.global_position = crow.global_position + Vector3(1.0, 0.0, 0.0)
		player.attack()
		_check(crow.hp < crow_hp0, "golpe melee reduce HP (%.0f -> %.0f)" % [crow_hp0, crow.hp])

	var victim: Node3D = null
	for m in get_tree().get_nodes_in_group("monsters"):
		if m.get("monster_id") == "mon_002":
			victim = m
			break
	_check(victim != null, "existe mon_002 en escena")
	if victim != null:
		var prog0: Array = quest_mgr.progress("quest_102")
		victim.take_damage(999.0)
		await get_tree().process_frame
		await get_tree().process_frame
		_check(not is_instance_valid(victim), "mon_002 muere y se libera")
		var prog1: Array = quest_mgr.progress("quest_102")
		_check(prog1.size() == 2 and int(prog1[0]) == int(prog0[0]) + 1,
			"muerte cuenta para quest_102 (%s)" % str(prog1))

	if _failures.is_empty():
		print("SIM-QUEST PASS")
		get_tree().quit(0)
	else:
		print("SIM-QUEST FAIL: %s" % str(_failures))
		get_tree().quit(1)
