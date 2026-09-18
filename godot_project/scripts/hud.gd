extends CanvasLayer
## HUD basico: barras HP/MP/EXP enlazadas al jugador, nombre de la zona,
## tracker de mision activa y panel de inventario (tecla I).
## Lee al jugador del grupo "player" cada frame; los cambios de HP/items
## se reflejan en el mismo frame (requisito 3.3 / 4.1 gameplay).

var _inventory_open := false
var _inventory_seen_version := -1
var _skill_slots: Dictionary = {}  # skill_id -> {"bar": .., "name": .., "key": ..}

@onready var hp_bar: ProgressBar = $Panel/HPBar
@onready var hp_label: Label = $Panel/HPLabel
@onready var mp_bar: ProgressBar = $Panel/MPBar
@onready var mp_label: Label = $Panel/MPLabel
@onready var exp_bar: ProgressBar = $Panel/EXPBar
@onready var exp_label: Label = $Panel/EXPLabel
@onready var zone_label: Label = $Panel/ZoneLabel
@onready var quest_label: Label = $Panel/QuestLabel
@onready var inventory_panel: Control = $InventoryPanel
@onready var inventory_list: ItemList = $InventoryPanel/InventoryList


func _ready() -> void:
	var game_data := get_node_or_null("/root/GameData")
	if game_data != null:
		zone_label.text = str(game_data.get_zone_display_name())
		print("[HUD] zona mostrada: " + zone_label.text)
	inventory_panel.visible = false
	_build_skill_bar(game_data)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_I:
			_inventory_open = not _inventory_open
			inventory_panel.visible = _inventory_open
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _inventory_open else Input.MOUSE_MODE_CAPTURED
			var audio = get_node_or_null("/root/AudioManager")
			if audio != null:
				audio.play_sfx("ui_open" if _inventory_open else "ui_close")
			if _inventory_open:
				_rebuild_inventory()


func _process(_delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p = players[0]
	_sync_bar(hp_bar, hp_label, p.hp, p.max_hp)
	_sync_bar(mp_bar, mp_label, p.mp, p.max_mp)
	_sync_bar(exp_bar, exp_label, p.exp, p.max_exp)
	_sync_quest()
	_sync_skills(p)
	if _inventory_open and p.inventory_version != _inventory_seen_version:
		_rebuild_inventory()


func _sync_bar(bar: ProgressBar, label: Label, value: float, max_value: float) -> void:
	bar.max_value = max_value
	bar.value = value
	label.text = "%d / %d" % [int(value), int(max_value)]


func _sync_quest() -> void:
	var quest_mgr := get_node_or_null("/root/QuestManager")
	if quest_mgr == null:
		return
	var active_id: String = quest_mgr.first_active()
	if active_id.is_empty():
		quest_label.text = "Sin misión activa (habla con Maren, E)"
		return
	var prog: Array = quest_mgr.progress(active_id)
	var game_data := get_node_or_null("/root/GameData")
	var title: String = active_id
	if game_data != null:
		title = str(game_data.quests.get(active_id, {}).get("title", active_id))
	if prog.size() == 2:
		quest_label.text = "%s  %d/%d" % [title, prog[0], prog[1]]
	else:
		quest_label.text = title


func _rebuild_inventory() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p = players[0]
	var game_data := get_node_or_null("/root/GameData")
	inventory_list.clear()
	for item_id in p.inventory.keys():
		var count: int = p.inventory[item_id]
		var name := str(item_id)
		if game_data != null:
			name = game_data.get_item_name(str(item_id))
		inventory_list.add_item("%s x%d" % [name, count])
	_inventory_seen_version = p.inventory_version


func _build_skill_bar(game_data) -> void:
	if game_data == null:
		return
	var bar := HBoxContainer.new()
	bar.name = "SkillBar"
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = -190.0
	bar.offset_right = 190.0
	bar.offset_top = -64.0
	bar.offset_bottom = -8.0
	bar.add_theme_constant_override("separation", 8)
	add_child(bar)
	var ids: Array = game_data.skills.keys()
	ids.sort()
	var key := 1
	for sid in ids:
		var sk: Dictionary = game_data.skills[sid]
		var slot := VBoxContainer.new()
		slot.custom_minimum_size = Vector2(120, 56)
		var key_label := Label.new()
		key_label.text = "[%d] %s" % [key, str(sk.get("name", sid))]
		var cd := ProgressBar.new()
		cd.custom_minimum_size = Vector2(120, 10)
		cd.show_percentage = false
		cd.max_value = 1.0
		cd.value = 0.0
		slot.add_child(key_label)
		slot.add_child(cd)
		bar.add_child(slot)
		_skill_slots[str(sid)] = {"bar": cd, "label": key_label, "key": key,
			"name": str(sk.get("name", sid)),
			"level_required": int(sk.get("level_required", 99)),
			"mp_cost": float(sk.get("mp_cost", 0))}
		key += 1
	print("[HUD] barra de skills: %d slots" % _skill_slots.size())


func _sync_skills(p) -> void:
	for sid in _skill_slots:
		var slot: Dictionary = _skill_slots[sid]
		var bar: ProgressBar = slot["bar"]
		var label: Label = slot["label"]
		var state: Array = p.skill_state(sid)
		var cd_max: float = p.skill_cooldown_max(sid)
		bar.max_value = maxf(cd_max, 0.01)
		bar.value = float(state[1])
		var txt := "[%d] %s" % [int(slot["key"]), str(slot["name"])]
		if state[0] == "locked":
			txt += " (Nv %d)" % int(slot["level_required"])
		elif state[0] == "cooldown":
			txt += " (%.0fs)" % float(state[1])
		elif state[0] == "no_mana":
			txt += " (MP)"
		elif sid == "skill_002" and p.bulwark_time > 0.0:
			txt += " (ACTIVO)"
		label.text = txt
