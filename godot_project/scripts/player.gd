extends CharacterBody3D
## Jugador en tercera persona: WASD relativo a la camara, salto con Espacio,
## camara orbital con raton via CamPivot (yaw) + SpringArm3D (pitch),
## ataque melee con clic, inventario, EXP/niveles y respawn.
## Pertenece al grupo "player" para que HUD y monstruos lo encuentren.

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003
@export var attack_range: float = 2.5
@export var base_attack: float = 5.0
@export var base_defense: float = 1.0
@export var mp_regen: float = 3.0
@export var use_cooldown_max: float = 3.0  # enfriamiento compartido de consumibles

## Cooldowns/duraciones por skill (skills.json no trae tiempos; ver design).
const SKILL_TIMES := {
	"skill_001": {"cd": 4.0, "range": 3.0},
	"skill_002": {"cd": 20.0, "duration": 5.0},
	"skill_003": {"cd": 15.0},
}
const EMBER_POWER_BONUS := 0.0  # el poder viene de skills.json (12)

var level: int = 1
var max_hp: float = 100.0
var hp: float = 100.0
var max_mp: float = 50.0
var mp: float = 50.0
var exp: float = 0.0
var max_exp: float = 100.0

var inventory: Dictionary = {"item_001": 1, "item_002": 1, "item_003": 3}
var inventory_version: int = 0
var gold: int = 30
var equipment: Dictionary = {"weapon": "", "armor": ""}

var cooldown_left: Dictionary = {"skill_001": 0.0, "skill_002": 0.0, "skill_003": 0.0}
var bulwark_time: float = 0.0
var use_cooldown: float = 0.0

@onready var cam_pivot: Node3D = $CamPivot
@onready var spring: SpringArm3D = $CamPivot/SpringArm3D
@onready var body_mesh: MeshInstance3D = $MeshInstance3D


static func phys_damage(atk: float, power: float, defense: float) -> float:
	## Formula unica de dano fisico.
	return maxf(1.0, atk + power - defense)


func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		spring.rotate_x(-event.relative.y * mouse_sensitivity)
		spring.rotation.x = clampf(spring.rotation.x, -1.2, 0.6)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				attack()
	elif event is InputEventKey and event.pressed and not event.echo:
		# Gancho de prueba: F1 inflige 10 de dano para ver el HUD (tarea 3.3).
		if event.physical_keycode == KEY_F1:
			take_damage(10.0)
		elif event.physical_keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.physical_keycode == KEY_1:
			cast_skill("skill_001")
		elif event.physical_keycode == KEY_2:
			cast_skill("skill_002")
		elif event.physical_keycode == KEY_3:
			cast_skill("skill_003")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	mp = clampf(mp + mp_regen * delta, 0.0, max_mp)
	for sid in cooldown_left:
		cooldown_left[sid] = maxf(0.0, float(cooldown_left[sid]) - delta)
	use_cooldown = maxf(0.0, use_cooldown - delta)
	if bulwark_time > 0.0:
		bulwark_time -= delta
		if bulwark_time <= 0.0:
			bulwark_time = 0.0
			_refresh_bulwark_tint()
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	var dir: Vector3 = Vector3.ZERO
	if input_dir.length() > 0.01:
		var yaw := cam_pivot.global_rotation.y
		dir = (Basis(Vector3.UP, yaw) * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
		# Gira solo la malla visible: el cuerpo (CharacterBody3D) no rota
		# porque CamPivot/Camera cuelgan de el y la camara orbitaria sola
		# al pulsar A/D (bug: parecia que se movia la camara y no el pj).
		body_mesh.rotation.y = lerp_angle(body_mesh.rotation.y, atan2(dir.x, dir.z) - rotation.y, 10.0 * delta)

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if input_dir.length() < 0.01 and is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, speed * 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 10.0 * delta)
	move_and_slide()


func attack() -> void:
	## Golpe basico al monstruo mas cercano (formula fisica, poder 0).
	_audio().play_sfx("swing")
	var best: Node3D = _nearest_monster(attack_range)
	if best != null and best.has_method("take_damage"):
		var dmg := phys_damage(attack_stat(), 0.0, best.get("defense"))
		best.take_damage(dmg)
		_audio().play_sfx("hit")
		_audio().notify_combat()
		print("[Player] golpe a %s (%.0f dmg)" % [best.get("monster_id"), dmg])


func take_damage(amount: float) -> void:
	## Dano directo (debug/caidas): no aplica defensa ni Bulwark.
	hp = clampf(hp - amount, 0.0, max_hp)
	if hp <= 0.0:
		_audio().play_sting("sting_death")
		_respawn()
	else:
		_audio().play_sfx("player_hurt")
		_audio().notify_combat()


func take_mob_damage(mob_attack: float) -> void:
	## Dano de monstruo con formula + Bulwark.
	var dmg := phys_damage(mob_attack, 0.0, defense_stat())
	if bulwark_time > 0.0:
		dmg *= 0.5
	hp = clampf(hp - dmg, 0.0, max_hp)
	if hp <= 0.0:
		_audio().play_sting("sting_death")
		_respawn()
	else:
		_audio().play_sfx("player_hurt")
		_audio().notify_combat()


func heal(amount: float) -> void:
	hp = clampf(hp + amount, 0.0, max_hp)


func add_exp(amount: float) -> void:
	exp += amount
	while exp >= max_exp:
		exp -= max_exp
		var known_before := known_skills()
		level += 1
		max_exp *= 1.5
		hp = max_hp
		_audio().play_sfx("level_up")
		print("[Player] nivel %d!" % level)
		for sk in known_skills():
			if not known_before.has(sk):
				print("[Player] habilidad aprendida: %s" % skill_name(sk))


func add_item(item_id: String, count: int = 1) -> void:
	inventory[item_id] = int(inventory.get(item_id, 0)) + count
	inventory_version += 1


func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)


func item_def(item_id: String) -> Dictionary:
	var game_data = get_node_or_null("/root/GameData")
	if game_data == null:
		return {}
	return game_data.items.get(item_id, {})


func attack_stat() -> float:
	var bonus := 0.0
	var w := str(equipment.get("weapon", ""))
	if w != "":
		bonus = float(item_def(w).get("attack_bonus", 0))
	return base_attack + bonus


func defense_stat() -> float:
	var bonus := 0.0
	var a := str(equipment.get("armor", ""))
	if a != "":
		bonus = float(item_def(a).get("defense_bonus", 0))
	return base_defense + bonus


func buy(item_id: String) -> bool:
	var def := item_def(item_id)
	if def.is_empty():
		return false
	var price := int(def.get("price", 0))
	if price <= 0 or gold < price:
		return false
	gold -= price
	add_item(item_id, 1)
	_audio().play_sfx("reward")
	print("[Shop] comprado %s por %d (oro %d)" % [item_id, price, gold])
	return true


func sell(item_id: String) -> bool:
	var def := item_def(item_id)
	if def.is_empty() or str(def.get("type", "")) == "quest":
		return false
	if int(inventory.get(item_id, 0)) <= 0:
		return false
	if equipment.get("weapon") == item_id or equipment.get("armor") == item_id:
		return false
	inventory[item_id] = int(inventory[item_id]) - 1
	if int(inventory[item_id]) <= 0:
		inventory.erase(item_id)
	gold += maxi(1, int(def.get("price", 0)) / 2)
	inventory_version += 1
	_audio().play_sfx("ui_click")
	print("[Shop] vendido %s (oro %d)" % [item_id, gold])
	return true


func equip(item_id: String) -> bool:
	var def := item_def(item_id)
	var slot := ""
	if str(def.get("type", "")) == "weapon":
		slot = "weapon"
	elif str(def.get("type", "")) == "armor":
		slot = "armor"
	else:
		return false
	if int(inventory.get(item_id, 0)) <= 0:
		return false
	unequip(slot)
	inventory[item_id] = int(inventory[item_id]) - 1
	if int(inventory[item_id]) <= 0:
		inventory.erase(item_id)
	equipment[slot] = item_id
	inventory_version += 1
	_audio().play_sfx("ui_click")
	print("[Equipo] %s en %s" % [item_id, slot])
	return true


func unequip(slot: String) -> bool:
	var current := str(equipment.get(slot, ""))
	if current == "":
		return false
	equipment[slot] = ""
	add_item(current, 1)
	_audio().play_sfx("ui_click")
	print("[Equipo] %s desequipado" % current)
	return true


func use_item(item_id: String) -> bool:
	## Usa un consumible: exige unidad, efecto aplicable y cooldown libre.
	var def := item_def(item_id)
	if str(def.get("type", "")) != "consumable":
		return false
	if int(inventory.get(item_id, 0)) <= 0:
		return false
	if use_cooldown > 0.0:
		return false
	var fx: Dictionary = def.get("use_effect", {})
	var need_hp := float(fx.get("hp", 0.0)) > 0.0 and hp < max_hp
	var need_mp := float(fx.get("mp", 0.0)) > 0.0 and mp < max_mp
	if not need_hp and not need_mp:
		return false
	inventory[item_id] = int(inventory[item_id]) - 1
	if int(inventory[item_id]) <= 0:
		inventory.erase(item_id)
	heal(float(fx.get("hp", 0.0)))
	mp = clampf(mp + float(fx.get("mp", 0.0)), 0.0, max_mp)
	use_cooldown = use_cooldown_max
	inventory_version += 1
	_audio().play_sfx("heal")
	print("[Uso] %s (HP %.0f/%.0f MP %.0f/%.0f)" % [item_id, hp, max_hp, mp, max_mp])
	return true


func _respawn() -> void:
	var game_data := get_node_or_null("/root/GameData")
	if game_data != null:
		global_position = game_data.get_zone_spawn()
	hp = max_hp
	mp = max_mp
	velocity = Vector3.ZERO
	print("[Player] resucitado en el punto de spawn")


# --- Skills ---

func skill_def(skill_id: String) -> Dictionary:
	var game_data = get_node_or_null("/root/GameData")
	if game_data == null:
		return {}
	return game_data.skills.get(skill_id, {})


func skill_name(skill_id: String) -> String:
	return str(skill_def(skill_id).get("name", skill_id))


func known_skills() -> Array:
	var out := []
	var game_data = get_node_or_null("/root/GameData")
	if game_data == null:
		return out
	for sid in game_data.skills:
		if level >= int(game_data.skills[sid].get("level_required", 99)):
			out.append(str(sid))
	out.sort()
	return out


func skill_state(skill_id: String) -> Array:
	## [estado, restante]: locked / cooldown / no_mana / ready.
	var def := skill_def(skill_id)
	if def.is_empty() or not known_skills().has(skill_id):
		return ["locked", 0.0]
	if float(cooldown_left.get(skill_id, 0.0)) > 0.0:
		return ["cooldown", float(cooldown_left[skill_id])]
	if mp < float(def.get("mp_cost", 0)):
		return ["no_mana", 0.0]
	return ["ready", 0.0]


func skill_cooldown_max(skill_id: String) -> float:
	return float(SKILL_TIMES.get(skill_id, {}).get("cd", 1.0))


func cast_skill(skill_id: String) -> bool:
	var def := skill_def(skill_id)
	if def.is_empty():
		return false
	if skill_state(skill_id)[0] != "ready":
		return false
	var cost := float(def.get("mp_cost", 0))
	if skill_id == "skill_001":
		var target: Node3D = _nearest_monster(float(SKILL_TIMES["skill_001"]["range"]))
		if target == null:
			return false  # whiff: no consume nada
		mp -= cost
		cooldown_left[skill_id] = skill_cooldown_max(skill_id)
		var dmg := phys_damage(attack_stat(), float(def.get("power", 0)) + EMBER_POWER_BONUS,
			target.get("defense"))
		target.take_damage(dmg)
		_audio().play_sfx("swing")
		_audio().play_sfx("hit")
		_audio().notify_combat()
		print("[Player] Ember Slash a %s (%.0f dmg)" % [target.get("monster_id"), dmg])
	elif skill_id == "skill_002":
		mp -= cost
		cooldown_left[skill_id] = skill_cooldown_max(skill_id)
		bulwark_time = float(SKILL_TIMES["skill_002"]["duration"])
		_refresh_bulwark_tint()
		_audio().play_sfx("quest_accept")
		print("[Player] Bulwark Stance activo (%.0f s)" % bulwark_time)
	elif skill_id == "skill_003":
		mp -= cost
		cooldown_left[skill_id] = skill_cooldown_max(skill_id)
		heal(max_hp * 0.3)
		_audio().play_sfx("heal")
		print("[Player] Field Bandage (+%.0f HP)" % (max_hp * 0.3))
	return true


func _nearest_monster(max_range: float) -> Node3D:
	var best = null
	var best_d := max_range
	for m in get_tree().get_nodes_in_group("monsters"):
		var d: float = global_position.distance_to(m.global_position)
		if d < best_d:
			best_d = d
			best = m
	return best


func _refresh_bulwark_tint() -> void:
	if body_mesh == null:
		return
	if bulwark_time > 0.0:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.6, 1.0, 0.45)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		body_mesh.material_override = mat
	else:
		body_mesh.material_override = null


func _audio():
	return get_node_or_null("/root/AudioManager")
