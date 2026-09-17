extends CanvasLayer
## HUD basico: barras HP/MP/EXP enlazadas al jugador, nombre de la zona,
## tracker de mision activa y panel de inventario (tecla I).
## Lee al jugador del grupo "player" cada frame; los cambios de HP/items
## se reflejan en el mismo frame (requisito 3.3 / 4.1 gameplay).

var _inventory_open := false
var _inventory_seen_version := -1

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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_I:
			_inventory_open = not _inventory_open
			inventory_panel.visible = _inventory_open
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _inventory_open else Input.MOUSE_MODE_CAPTURED
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
