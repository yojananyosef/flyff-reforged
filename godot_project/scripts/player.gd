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
var target: Node3D = null  # objetivo fijado con clic (grupo "monsters")

## Marcha por clic + básicos automáticos (aethermere-melee).
const BASIC_CD_MAX := 0.9
var basic_cd: float = 0.0
var auto_attack := false
var has_dest := false
var move_dest := Vector3.ZERO
var _move_marker: MeshInstance3D = null
var _swing_tween: Tween = null
var _rmb_held := false  # freelook: cámara solo mientras se mantiene RMB

## Gracia al aparecer: 6 s sin agro ni daño; atacar la rompe (huir no).
const PROTECT_MAX := 6.0
var protect_t := 0.0

@onready var cam_pivot: Node3D = $CamPivot
@onready var spring: SpringArm3D = $CamPivot/SpringArm3D
@onready var body_mesh: MeshInstance3D = $MeshInstance3D


static func phys_damage(atk: float, power: float, defense: float) -> float:
	## Formula unica de dano fisico.
	return maxf(1.0, atk + power - defense)


func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	protect_t = PROTECT_MAX
	var ring := MeshInstance3D.new()
	ring.name = "MoveMarker"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.28
	torus.outer_radius = 0.42
	var mmat := StandardMaterial3D.new()
	mmat.albedo_color = Color(1.0, 0.85, 0.2)
	mmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	torus.material = mmat
	ring.mesh = torus
	ring.visible = false
	get_parent().add_child.call_deferred(ring)
	_move_marker = ring


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _rmb_held:
		cam_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		spring.rotate_x(-event.relative.y * mouse_sensitivity)
		spring.rotation.x = clampf(spring.rotation.x, -1.2, 0.6)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_rmb_held = mb.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mb.pressed \
				else Input.MOUSE_MODE_VISIBLE
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if _can_world_click():
				var hit := _click_hit()
				var picked: Node3D = hit.get("monster")
				if mb.double_click and picked != null:
					target = picked
					auto_attack = true
					print("[Player] auto-ataque: %s" % picked.get("display_name"))
				elif picked != null:
					target = picked
					print("[Player] objetivo: %s" % picked.get("display_name"))
					attack(picked)
				elif hit.get("ground") != null:
					_set_dest(hit["ground"])
					auto_attack = false
				else:
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
	basic_cd = maxf(0.0, basic_cd - delta)
	protect_t = maxf(0.0, protect_t - delta)
	if bulwark_time > 0.0:
		bulwark_time -= delta
		if bulwark_time <= 0.0:
			bulwark_time = 0.0
			_refresh_bulwark_tint()
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	if target != null and not is_instance_valid(target):
		target = null
		auto_attack = false

	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	var dir: Vector3 = Vector3.ZERO
	if input_dir.length() > 0.01:
		# El teclado manda y cancela la marcha por clic (no el auto-ataque,
		# que retoma al soltar las teclas).
		has_dest = false
		_hide_marker()
		var yaw := cam_pivot.global_rotation.y
		dir = (Basis(Vector3.UP, yaw) * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	elif has_dest:
		var to_d: Vector3 = move_dest - global_position
		to_d.y = 0.0
		if to_d.length() < 0.4:
			has_dest = false
			_hide_marker()
		else:
			dir = to_d.normalized()
	elif auto_attack and target != null and is_instance_valid(target):
		var to_t: Vector3 = target.global_position - global_position
		to_t.y = 0.0
		if to_t.length() > attack_range * 0.9:
			dir = to_t.normalized()
		else:
			attack()
	if dir.length() > 0.01:
		# Gira solo la malla visible: el cuerpo (CharacterBody3D) no rota
		# porque CamPivot/Camera cuelgan de el y la camara orbitaria sola
		# al pulsar A/D (bug: parecia que se movia la camara y no el pj).
		body_mesh.rotation.y = lerp_angle(body_mesh.rotation.y, atan2(dir.x, dir.z) - rotation.y, 10.0 * delta)

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if dir.length() < 0.01 and is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, speed * 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 10.0 * delta)
	move_and_slide()


func attack(only: Node3D = null) -> bool:
	## Golpe básico con ritmo (0.9 s) y gesto visible. Con `only` (clic a un
	## monstruo) exige rango y avisa si no llega; sin `only` prioriza el
	## objetivo fijado en rango y si no hay, el más cercano como antes.
	## Propaga atacante para el agro.
	if basic_cd > 0.0:
		return false
	protect_t = 0.0
	_audio().play_sfx("swing")
	var victim: Node3D = null
	if only != null:
		if not is_instance_valid(only) or not only.is_in_group("monsters"):
			return false
		if global_position.distance_to(only.global_position) > attack_range:
			print("[Player] objetivo fuera de alcance")
			return false
		victim = only
	else:
		victim = _target_in_range(attack_range)
		if victim == null:
			victim = _nearest_monster(attack_range)
	if victim == null:
		return false
	if victim.has_method("take_damage"):
		basic_cd = BASIC_CD_MAX
		_swing_fx()
		var dmg := phys_damage(attack_stat(), 0.0, victim.get("defense"))
		victim.take_damage(dmg, self)
		_audio().play_sfx("hit")
		_audio().notify_combat()
		print("[Player] golpe a %s (%.0f dmg)" % [victim.get("monster_id"), dmg])
		return true
	return false


func _swing_fx() -> void:
	if body_mesh == null:
		return
	if _swing_tween != null and _swing_tween.is_valid():
		_swing_tween.kill()
	body_mesh.scale = Vector3.ONE
	_swing_tween = create_tween()
	_swing_tween.tween_property(body_mesh, "scale", Vector3(1.25, 0.8, 1.25), 0.09)
	_swing_tween.tween_property(body_mesh, "scale", Vector3.ONE, 0.12)


func _target_in_range(max_range: float) -> Node3D:
	if target == null:
		return null
	if not is_instance_valid(target) or not target.is_in_group("monsters"):
		target = null
		return null
	if global_position.distance_to(target.global_position) > max_range:
		return null
	return target


func _can_world_click() -> bool:
	## Cursor libre por defecto: vale clicar salvo con UI abierta (los
	## Controles consumen sus clics antes de llegar aquí).
	var hud = get_tree().get_first_node_in_group("hud")
	if hud != null:
		if bool(hud.get("_inventory_open")):
			return false
		if hud.is_shop_open():
			return false
	var dlg = get_parent().get_node_or_null("DialogueLayer")
	if dlg != null and dlg.is_open():
		return false
	return true


func _click_hit() -> Dictionary:
	## Rayo de selección desde la posición del cursor hasta 100 m.
	var out := {"monster": null, "ground": null}
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return out
	var point := get_viewport().get_mouse_position()
	var origin := cam.project_ray_origin(point)
	var end := origin + cam.project_ray_normal(point) * 100.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var collider = hit.get("collider")
	if collider != null and (collider as Node).is_in_group("monsters"):
		out["monster"] = collider as Node3D
		return out
	if hit.has("position"):
		var p: Vector3 = hit["position"]
		var n: Vector3 = hit.get("normal", Vector3.UP)
		if n.y > 0.5 and absf(p.x) < 19.0 and absf(p.z) < 19.0:
			out["ground"] = p
	if out["monster"] == null:
		out["monster"] = _near_crosshair(cam, point)
	return out


func _near_crosshair(cam: Camera3D, point: Vector2) -> Node3D:
	## Tolerancia: el rayo exacto falla con bichos pequeños en movimiento;
	## se acepta el monstruo visible más cercano al cursor (140 px).
	var best: Node3D = null
	var best_d := 140.0
	for m in get_tree().get_nodes_in_group("monsters"):
		var n := m as Node3D
		if n == null or cam.is_position_behind(n.global_position):
			continue
		var d: float = cam.unproject_position(
			n.global_position + Vector3(0, 1.0, 0)).distance_to(point)
		if d < best_d:
			best_d = d
			best = n
	return best


func _set_dest(p: Vector3) -> void:
	has_dest = true
	move_dest = p
	if _move_marker != null and is_instance_valid(_move_marker):
		_move_marker.global_position = Vector3(p.x, 0.05, p.z)
		_move_marker.visible = true
	print("[Player] destino: (%.1f, %.1f)" % [p.x, p.z])


func _hide_marker() -> void:
	if _move_marker != null and is_instance_valid(_move_marker):
		_move_marker.visible = false


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
	## Dano de monstruo con formula + Bulwark. La gracia lo ignora.
	if protect_t > 0.0:
		return
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
	target = null
	auto_attack = false
	has_dest = false
	basic_cd = 0.0
	protect_t = PROTECT_MAX
	_rmb_held = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hide_marker()
	if body_mesh != null:
		body_mesh.scale = Vector3.ONE
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
	protect_t = 0.0
	var cost := float(def.get("mp_cost", 0))
	if skill_id == "skill_001":
		var foe: Node3D = _target_in_range(float(SKILL_TIMES["skill_001"]["range"]))
		if foe == null:
			foe = _nearest_monster(float(SKILL_TIMES["skill_001"]["range"]))
		if foe == null:
			return false  # whiff: no consume nada
		mp -= cost
		cooldown_left[skill_id] = skill_cooldown_max(skill_id)
		var dmg := phys_damage(attack_stat(), float(def.get("power", 0)) + EMBER_POWER_BONUS,
			foe.get("defense"))
		foe.take_damage(dmg, self)
		_audio().play_sfx("swing")
		_audio().play_sfx("hit")
		_audio().notify_combat()
		print("[Player] Ember Slash a %s (%.0f dmg)" % [foe.get("monster_id"), dmg])
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
