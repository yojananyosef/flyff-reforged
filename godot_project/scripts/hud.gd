extends CanvasLayer
## HUD basico: barras HP/MP/EXP enlazadas al jugador, nombre de la zona,
## tracker de mision activa y panel de inventario (tecla I).
## Lee al jugador del grupo "player" cada frame; los cambios de HP/items
## se reflejan en el mismo frame (requisito 3.3 / 4.1 gameplay).

var _inventory_open := false
var _inventory_seen_version := -1
var _skill_slots: Dictionary = {}  # skill_id -> {"bar": .., "name": .., "key": ..}
var _debug_on := false
var _debug_label: Label

const SHOP_STOCK := ["item_003", "item_004", "item_001", "item_002"]
var shop_open := false
var _inv_ids: Array = []
var _sell_ids: Array = []
var _shop_panel: Control
var _buy_list: ItemList
var _sell_list: ItemList
var _shop_gold: Label

@onready var title_label: Label = $InventoryPanel/Title

@onready var hp_bar: ProgressBar = $Panel/HPBar
@onready var hp_label: Label = $Panel/HPLabel
@onready var mp_bar: ProgressBar = $Panel/MPBar
@onready var mp_label: Label = $Panel/MPLabel
@onready var exp_bar: ProgressBar = $Panel/EXPBar
@onready var exp_label: Label = $Panel/EXPLabel
@onready var zone_label: Label = $Panel/ZoneLabel
@onready var quest_label: Label = $Panel/QuestLabel
@onready var hp_orb: TextureRect = $Panel/HPOrb
@onready var mp_orb: TextureRect = $Panel/MPOrb
@onready var exp_orb: TextureRect = $Panel/EXPOrb
@onready var inventory_panel: Control = $InventoryPanel
@onready var inv_bg: NinePatchRect = $InventoryPanel/Bg
@onready var inventory_list: ItemList = $InventoryPanel/InventoryList
@onready var equip_button: Button = $InventoryPanel/EquipButton
@onready var unequip_button: Button = $InventoryPanel/UnequipButton
@onready var equipped_label: Label = $InventoryPanel/EquippedLabel
@onready var use_button: Button = $InventoryPanel/UseButton


func _ready() -> void:
	var game_data := get_node_or_null("/root/GameData")
	if game_data != null:
		zone_label.text = str(game_data.get_zone_display_name())
		print("[HUD] zona mostrada: " + zone_label.text)
	inventory_panel.visible = false
	_build_skill_bar(game_data)
	_build_shop_panel()
	if game_data != null:
		_apply_skin(inv_bg, game_data.ui_texture("WndMessagebox.tga"))
		_apply_icon(hp_orb, game_data.ui_texture("BarRed.tga"))
		_apply_icon(mp_orb, game_data.ui_texture("BarSky.tga"))
		_apply_icon(exp_orb, game_data.ui_texture("BarGreen.tga"))
	_debug_label = Label.new()
	_debug_label.name = "DebugLabel"
	_debug_label.anchor_left = 1.0
	_debug_label.anchor_right = 1.0
	_debug_label.offset_left = -330.0
	_debug_label.offset_right = -10.0
	_debug_label.offset_top = 320.0
	_debug_label.offset_bottom = 480.0
	_debug_label.visible = false
	add_child(_debug_label)
	equip_button.pressed.connect(_on_equip_pressed)
	unequip_button.pressed.connect(_on_unequip_pressed)
	use_button.pressed.connect(_on_use_pressed)


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
		elif event.physical_keycode == KEY_F3:
			_debug_on = not _debug_on
			_debug_label.visible = _debug_on


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
	_sync_debug(p)
	if p.use_cooldown > 0.0:
		use_button.disabled = true
		use_button.text = "Usar (%.0fs)" % p.use_cooldown
	else:
		use_button.disabled = false
		use_button.text = "Usar"
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
	_inv_ids.clear()
	for item_id in p.inventory.keys():
		var count: int = p.inventory[item_id]
		var label := _equip_tag(p, str(item_id))
		var name := str(item_id)
		if game_data != null:
			name = game_data.get_item_name(str(item_id))
		inventory_list.add_item("%s x%d%s" % [name, count, label])
		_inv_ids.append(str(item_id))
	title_label.text = "Inventario (I) · Oro: %d" % p.gold
	equipped_label.text = "Arma: %s · Armadura: %s" % [
		_equipped_name(game_data, p, "weapon"), _equipped_name(game_data, p, "armor")]
	_inventory_seen_version = p.inventory_version


func _equip_tag(p, item_id: String) -> String:
	if str(p.equipment.get("weapon", "")) == item_id:
		return " [PUESTA]"
	if str(p.equipment.get("armor", "")) == item_id:
		return " [PUESTO]"
	return ""


func _equipped_name(game_data, p, slot: String) -> String:
	var id := str(p.equipment.get(slot, ""))
	if id == "":
		return "-"
	if game_data != null:
		return game_data.get_item_name(id)
	return id


func _on_equip_pressed() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty() or inventory_list.get_selected_items().is_empty():
		return
	var p = players[0]
	if p.equip(_inv_ids[inventory_list.get_selected_items()[0]]):
		_rebuild_inventory()


func _on_unequip_pressed() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p = players[0]
	if str(p.equipment.get("weapon", "")) != "":
		p.unequip("weapon")
	elif str(p.equipment.get("armor", "")) != "":
		p.unequip("armor")
	_rebuild_inventory()


func _on_use_pressed() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty() or inventory_list.get_selected_items().is_empty():
		return
	var p = players[0]
	if p.use_item(_inv_ids[inventory_list.get_selected_items()[0]]):
		_rebuild_inventory()


# --- Tienda ---

func _apply_skin(rect: NinePatchRect, tex) -> void:
	if tex != null:
		rect.texture = tex


func _apply_icon(icon: TextureRect, tex) -> void:
	if tex != null:
		icon.texture = tex
	else:
		icon.visible = false

func is_shop_open() -> bool:
	return shop_open


func open_shop() -> void:
	shop_open = true
	_shop_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh_shop()


func close_shop() -> void:
	shop_open = false
	_shop_panel.visible = false
	if not _inventory_open:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_shop_panel() -> void:
	var panel := Control.new()
	panel.name = "ShopPanel"
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260.0
	panel.offset_top = -160.0
	panel.offset_right = 260.0
	panel.offset_bottom = 160.0
	panel.visible = false
	add_child(panel)
	_shop_panel = panel
	var bg := NinePatchRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.patch_margin_left = 16.0
	bg.patch_margin_top = 16.0
	bg.patch_margin_right = 16.0
	bg.patch_margin_bottom = 16.0
	panel.add_child(bg)
	var game_data := get_node_or_null("/root/GameData")
	if game_data != null:
		_apply_skin(bg, game_data.ui_texture("WndMessagebox.tga"))
	_shop_gold = _shop_label(panel, "Oro: 0", 12, 8, 508, 30)
	_shop_label(panel, "Comprar", 12, 34, 250, 54)
	_shop_label(panel, "Vender (mitad)", 262, 34, 508, 54)
	_buy_list = _shop_list(panel, 12, 58, 238, 250)
	_sell_list = _shop_list(panel, 262, 58, 508, 250)
	var buy_btn := Button.new()
	buy_btn.text = "Comprar"
	buy_btn.offset_left = 12.0
	buy_btn.offset_top = 256.0
	buy_btn.offset_right = 238.0
	buy_btn.offset_bottom = 286.0
	buy_btn.pressed.connect(_on_buy_pressed)
	panel.add_child(buy_btn)
	var sell_btn := Button.new()
	sell_btn.text = "Vender"
	sell_btn.offset_left = 262.0
	sell_btn.offset_top = 256.0
	sell_btn.offset_right = 508.0
	sell_btn.offset_bottom = 286.0
	sell_btn.pressed.connect(_on_sell_pressed)
	panel.add_child(sell_btn)
	print("[HUD] tienda construida (%d stock)" % SHOP_STOCK.size())


func _shop_label(panel: Control, text: String, x0: float, y0: float, x1: float, y1: float) -> Label:
	var l := Label.new()
	l.text = text
	l.offset_left = x0
	l.offset_top = y0
	l.offset_right = x1
	l.offset_bottom = y1
	panel.add_child(l)
	return l


func _shop_list(panel: Control, x0: float, y0: float, x1: float, y1: float) -> ItemList:
	var l := ItemList.new()
	l.offset_left = x0
	l.offset_top = y0
	l.offset_right = x1
	l.offset_bottom = y1
	panel.add_child(l)
	return l


func _refresh_shop() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p = players[0]
	var game_data := get_node_or_null("/root/GameData")
	_shop_gold.text = "Pell Bryn · Oro: %d" % p.gold
	_buy_list.clear()
	for item_id in SHOP_STOCK:
		var price := 0
		var name := str(item_id)
		if game_data != null:
			price = int(game_data.items.get(item_id, {}).get("price", 0))
			name = game_data.get_item_name(str(item_id))
		_buy_list.add_item("%s — %d" % [name, price])
	_sell_list.clear()
	_sell_ids.clear()
	for item_id in p.inventory.keys():
		var def: Dictionary = p.item_def(str(item_id))
		if str(def.get("type", "")) == "quest":
			continue
		var name := str(item_id)
		if game_data != null:
			name = game_data.get_item_name(str(item_id))
		_sell_list.add_item("%s x%d — %d" % [name, int(p.inventory[item_id]),
			maxi(1, int(def.get("price", 0)) / 2)])
		_sell_ids.append(str(item_id))


func _on_buy_pressed() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty() or _buy_list.get_selected_items().is_empty():
		return
	var p = players[0]
	if p.buy(SHOP_STOCK[_buy_list.get_selected_items()[0]]):
		_refresh_shop()
		_rebuild_inventory()


func _on_sell_pressed() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty() or _sell_list.get_selected_items().is_empty():
		return
	var p = players[0]
	if p.sell(_sell_ids[_sell_list.get_selected_items()[0]]):
		_refresh_shop()
		_rebuild_inventory()


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


func _sync_debug(p) -> void:
	if not _debug_on:
		return
	var mouse_name := "visible"
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_name = "capturado"
	elif Input.mouse_mode == Input.MOUSE_MODE_CONFINED:
		mouse_name = "confinado"
	_debug_label.text = "FPS %d\nmouse: %s\nWASD: %.1f %.1f %.1f %.1f\nsalto: %.1f\nvel: %s\npos: %s\nsuelo: %s" % [
		Engine.get_frames_per_second(), mouse_name,
		Input.get_action_strength("move_forward"), Input.get_action_strength("move_back"),
		Input.get_action_strength("move_left"), Input.get_action_strength("move_right"),
		Input.get_action_strength("jump"),
		str(Vector2(p.velocity.x, p.velocity.z)), str(p.global_position),
		str(p.is_on_floor())]
