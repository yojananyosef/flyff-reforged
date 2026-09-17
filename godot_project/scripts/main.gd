extends Node3D
## Escena principal: registra la zona inicial y muestra su nombre.
## La carga de `zones.json`/`dialogues.json` vive en el autoload GameData;
## aqui solo se verifica que la zona actual sea `ironhold` (requisito 3.4).


func _ready() -> void:
	var game_data := get_node_or_null("/root/GameData")
	if game_data == null:
		push_error("[Main] autoload GameData no encontrado")
		return
	print("[Main] arranque OK. Zona: %s (%s)" % [game_data.current_zone_id, game_data.get_zone_display_name()])
	if game_data.current_zone_id != "ironhold":
		push_warning("[Main] zona actual no es 'ironhold': " + str(game_data.current_zone_id))
