extends CanvasLayer
## Panel de dialogo: muestra nodos de `dialogues.json`, navega opciones
## via `next` y ofrece aceptar la primera mision disponible del NPC en el
## nodo `quest_offer`. Abierto con E junto al NPC; E o Cerrar lo cierra.

var npc_id: String = ""
var dialogue_id: String = ""
var current_node: String = ""

@onready var panel: Control = $Panel
@onready var speaker_label: Label = $Panel/SpeakerLabel
@onready var text_label: Label = $Panel/TextLabel
@onready var options_box: VBoxContainer = $Panel/OptionsBox
@onready var accept_button: Button = $Panel/AcceptButton
@onready var close_button: Button = $Panel/CloseButton


func _ready() -> void:
	visible = false
	accept_button.pressed.connect(_on_accept)
	close_button.pressed.connect(close)


func is_open() -> bool:
	return visible


func open(p_npc_id: String) -> void:
	var game_data := get_node_or_null("/root/GameData")
	if game_data == null:
		return
	var npc: Dictionary = game_data.npcs.get(p_npc_id, {})
	if npc.is_empty():
		return
	npc_id = p_npc_id
	dialogue_id = str(npc.get("dialogue_id", ""))
	speaker_label.text = str(npc.get("name", npc_id))
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_node("start")
	print("[Dialogue] abierto con %s" % npc_id)


func close() -> void:
	visible = false
	npc_id = ""
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _show_node(node_id: String) -> void:
	var game_data: Node = get_node("/root/GameData")
	var dlg: Dictionary = game_data.get_dialogue(dialogue_id)
	var node := _find_node(dlg, node_id)
	if node.is_empty():
		close()
		return
	current_node = node_id
	text_label.text = str(node.get("text", ""))
	for child in options_box.get_children():
		child.queue_free()
	for opt in node.get("options", []):
		var btn := Button.new()
		btn.text = str(opt.get("text", "..."))
		btn.pressed.connect(_on_option.bind(str(opt.get("next", ""))))
		options_box.add_child(btn)
	_refresh_accept(game_data)


func _find_node(dlg: Dictionary, node_id: String) -> Dictionary:
	for n in dlg.get("nodes", []):
		if str(n.get("node_id")) == node_id:
			return n
	return {}


func _refresh_accept(game_data: Node) -> void:
	var quest_mgr := get_node_or_null("/root/QuestManager")
	var show := false
	var label := "Aceptar misión"
	if quest_mgr != null and current_node == "quest_offer":
		var avail: Array = quest_mgr.npc_available_quests(npc_id)
		if not avail.is_empty():
			show = true
			var q: Dictionary = game_data.quests.get(avail[0], {})
			label = "Aceptar: %s" % str(q.get("title", avail[0]))
	accept_button.visible = show
	accept_button.text = label


func _on_option(next_id: String) -> void:
	_show_node(next_id)


func _on_accept() -> void:
	var quest_mgr := get_node_or_null("/root/QuestManager")
	if quest_mgr == null:
		return
	var avail: Array = quest_mgr.npc_available_quests(npc_id)
	if avail.is_empty():
		return
	if quest_mgr.accept_quest(str(avail[0])):
		_refresh_accept(get_node("/root/GameData"))
