extends CharacterBody3D
## Monstruo placeholder: capsula con nombre, IA errante minima, HP, dano
## por contacto y muerte con EXP + drops. Definicion base en monsters.json.
## El spawner (main.gd) llama a `setup(monster_id)` tras instanciar.

var monster_id: String = ""
var display_name: String = "Monster"
var level: int = 1
var max_hp: float = 10.0
var hp: float = 10.0
var attack: float = 1.0
var defense: float = 0.0
var exp_value: float = 1.0
var drops: Array = []

var wander_speed: float = 1.5
var _dir: Vector3 = Vector3.ZERO
var _wander_timer: float = 0.0
var _touch_cooldown: float = 0.0

@onready var name_label: Label3D = $NameLabel


func setup(def: Dictionary) -> void:
	monster_id = str(def.get("id", "mon_000"))
	display_name = str(def.get("name", monster_id))
	level = int(def.get("level", 1))
	max_hp = float(def.get("hp", 10))
	hp = max_hp
	attack = float(def.get("attack", 1))
	defense = float(def.get("defense", 0))
	exp_value = float(def.get("exp", 1))
	drops = def.get("drops", [])


func _ready() -> void:
	add_to_group("monsters")
	_pick_direction()
	_refresh_label()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_direction()
	velocity.x = _dir.x * wander_speed
	velocity.z = _dir.z * wander_speed
	move_and_slide()

	_touch_cooldown -= delta
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null and _touch_cooldown <= 0.0:
		if global_position.distance_to(player.global_position) < 1.4:
			_touch_cooldown = 1.0
			if player.has_method("take_mob_damage"):
				player.take_mob_damage(attack)


func take_damage(amount: float) -> void:
	hp = clampf(hp - amount, 0.0, max_hp)
	_refresh_label()
	if hp <= 0.0:
		_die()
	else:
		var audio = get_node_or_null("/root/AudioManager")
		if audio != null:
			audio.play_sfx("monster_hurt")


func _die() -> void:
	var quest_mgr := get_node_or_null("/root/QuestManager")
	if quest_mgr != null:
		quest_mgr.report_kill(monster_id)
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		if player.has_method("add_exp"):
			player.add_exp(exp_value)
		if player.has_method("add_gold"):
			player.add_gold(int(level) * 2)
		if player.has_method("add_item"):
			for drop in drops:
				player.add_item(str(drop), 1)
	print("[Monster] %s muerto (%.0f EXP)" % [monster_id, exp_value])
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx("monster_die")
		if not drops.is_empty():
			audio.play_sfx("pickup")
	remove_from_group("monsters")
	queue_free()


func _pick_direction() -> void:
	var a := randf() * TAU
	_dir = Vector3(cos(a), 0.0, sin(a))
	_wander_timer = randf_range(2.0, 4.0)


func _refresh_label() -> void:
	if name_label != null:
		name_label.text = "%s  %d/%d" % [display_name, int(hp), int(max_hp)]
