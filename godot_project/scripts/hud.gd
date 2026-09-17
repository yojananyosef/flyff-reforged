extends CanvasLayer
## HUD basico: barras HP/MP/EXP enlazadas al jugador + nombre de la zona.
## Lee al jugador del grupo "player" cada frame; si el HP cambia, la barra
## y el texto se actualizan en el mismo frame (requisito 3.3).

@onready var hp_bar: ProgressBar = $Panel/HPBar
@onready var hp_label: Label = $Panel/HPLabel
@onready var mp_bar: ProgressBar = $Panel/MPBar
@onready var mp_label: Label = $Panel/MPLabel
@onready var exp_bar: ProgressBar = $Panel/EXPBar
@onready var exp_label: Label = $Panel/EXPLabel
@onready var zone_label: Label = $Panel/ZoneLabel


func _ready() -> void:
	var game_data := get_node_or_null("/root/GameData")
	if game_data != null:
		zone_label.text = str(game_data.get_zone_display_name())
		print("[HUD] zona mostrada: " + zone_label.text)


func _process(_delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p = players[0]
	_sync_bar(hp_bar, hp_label, p.hp, p.max_hp)
	_sync_bar(mp_bar, mp_label, p.mp, p.max_mp)
	_sync_bar(exp_bar, exp_label, p.exp, p.max_exp)


func _sync_bar(bar: ProgressBar, label: Label, value: float, max_value: float) -> void:
	bar.max_value = max_value
	bar.value = value
	label.text = "%d / %d" % [int(value), int(max_value)]
