extends CharacterBody3D
## Jugador en tercera persona: WASD relativo a la camara, salto con Espacio,
## camara orbital con raton via CamPivot (yaw) + SpringArm3D (pitch),
## ataque melee con clic, inventario, EXP/niveles y respawn.
## Pertenece al grupo "player" para que HUD y monstruos lo encuentren.

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003
@export var attack_damage: float = 14.0  # Ember Slash (12) + 2 base
@export var attack_range: float = 2.5

var level: int = 1
var max_hp: float = 100.0
var hp: float = 100.0
var max_mp: float = 50.0
var mp: float = 50.0
var exp: float = 0.0
var max_exp: float = 100.0

var inventory: Dictionary = {"item_001": 1, "item_002": 1, "item_003": 3}
var inventory_version: int = 0

@onready var cam_pivot: Node3D = $CamPivot
@onready var spring: SpringArm3D = $CamPivot/SpringArm3D


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


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
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
		# Gira el cuerpo hacia la direccion de marcha.
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 10.0 * delta)

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if input_dir.length() < 0.01 and is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, speed * 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 10.0 * delta)
	move_and_slide()


func attack() -> void:
	## Golpea al monstruo mas cercano en alcance.
	var best: Node3D = null
	var best_d := attack_range
	for m in get_tree().get_nodes_in_group("monsters"):
		var d: float = global_position.distance_to((m as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = m
	if best != null and best.has_method("take_damage"):
		best.take_damage(attack_damage)
		print("[Player] golpe a %s (%.0f dmg)" % [best.get("monster_id"), attack_damage])


func take_damage(amount: float) -> void:
	hp = clampf(hp - amount, 0.0, max_hp)
	if hp <= 0.0:
		_respawn()


func heal(amount: float) -> void:
	hp = clampf(hp + amount, 0.0, max_hp)


func add_exp(amount: float) -> void:
	exp += amount
	while exp >= max_exp:
		exp -= max_exp
		level += 1
		max_exp *= 1.5
		hp = max_hp
		print("[Player] nivel %d!" % level)


func add_item(item_id: String, count: int = 1) -> void:
	inventory[item_id] = int(inventory.get(item_id, 0)) + count
	inventory_version += 1


func _respawn() -> void:
	var game_data := get_node_or_null("/root/GameData")
	if game_data != null:
		global_position = game_data.get_zone_spawn()
	hp = max_hp
	mp = max_mp
	velocity = Vector3.ZERO
	print("[Player] resucitado en el punto de spawn")
