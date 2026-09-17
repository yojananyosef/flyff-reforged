extends CharacterBody3D
## Jugador en tercera persona: WASD relativo a la camara, salto con Espacio,
## camara orbital con raton via CamPivot (yaw) + SpringArm3D (pitch).
## Pertenece al grupo "player" para que el HUD lo encuentre.

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

var max_hp: float = 100.0
var hp: float = 100.0
var max_mp: float = 50.0
var mp: float = 50.0
var exp: float = 0.0
var max_exp: float = 100.0

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


func take_damage(amount: float) -> void:
	hp = clampf(hp - amount, 0.0, max_hp)


func heal(amount: float) -> void:
	hp = clampf(hp + amount, 0.0, max_hp)
