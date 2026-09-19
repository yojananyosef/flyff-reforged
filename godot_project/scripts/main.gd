extends Node3D
## Escena principal: registra la zona inicial, genera NPC y monstruos
## desde `data/`, gestiona la interaccion (E) y el modo de simulacion
## headless `--sim-quest` (requisito: verificacion repetible del flujo
## aceptar → cazar → completar → desbloquear).

const MonsterScript := preload("res://scripts/monster.gd")

var _failures: Array[String] = []
var _terrain = null  # {n, step, ox, oz, hs} o null (repliegue al plano)

@onready var player = $Player
@onready var dialogue = $DialogueLayer
@onready var hud = $HUD


func _ready() -> void:
	var game_data := get_node_or_null("/root/GameData")
	if game_data == null:
		push_error("[Main] autoload GameData no encontrado")
		return
	print("[Main] arranque OK. Zona: %s (%s)" % [game_data.current_zone_id, game_data.get_zone_display_name()])
	if game_data.current_zone_id != "ironhold":
		push_warning("[Main] zona actual no es 'ironhold': " + str(game_data.current_zone_id))
	_load_terrain()
	var psy = ground_height(player.position.x, player.position.z)
	if psy != null:
		player.position.y = psy + 0.5
	npc_setup()
	_spawn_monsters(game_data)
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_zone_music()
	var save_mgr = get_node_or_null("/root/SaveManager")
	var sim_mode := "--sim-quest" in OS.get_cmdline_user_args()
	if save_mgr != null and not sim_mode and save_mgr.has_save():
		save_mgr.load_game()
	if sim_mode:
		_run_sim.call_deferred()
	if "--shot" in OS.get_cmdline_user_args():
		_take_shot.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E:
			if dialogue.is_open():
				dialogue.close()
			elif hud.is_shop_open():
				hud.close_shop()
			else:
				var npc = nearest_npc()
				if npc != null:
					dialogue.open(str(npc.get_meta("npc_id")))
		elif event.physical_keycode == KEY_F5:
			var save_mgr = get_node_or_null("/root/SaveManager")
			if save_mgr != null:
				save_mgr.save_game()
		elif event.physical_keycode == KEY_F8:
			var save_mgr8 = get_node_or_null("/root/SaveManager")
			if save_mgr8 != null:
				save_mgr8.new_game()


func npc_setup() -> void:
	$NPC.set_meta("npc_id", "npc_001")
	$NPC2.set_meta("npc_id", "npc_002")
	for npc in [$NPC, $NPC2]:
		var gy = ground_height(npc.position.x, npc.position.z)
		if gy != null:
			npc.position.y = gy


func _load_terrain() -> void:
	## Suelo real (visual .glb + HeightMap) si setup_terrain.py generó los
	## archivos; si no, se conserva el plano de la escena (repliegue).
	var jpath := "res://models/terrain_ironhold.json"
	var gpath := "res://models/terrain_ironhold.glb"
	if not FileAccess.file_exists(jpath):
		print("[Terreno] sin rejilla generada: plano de repliegue")
		return
	var spec = JSON.parse_string(FileAccess.get_file_as_string(jpath))
	if not (spec is Dictionary):
		push_warning("[Terreno] JSON inválido, plano de repliegue")
		return
	var n := int(spec.get("n", 0))
	var hs: Array = spec.get("heights", [])
	if n < 2 or hs.size() != n * n:
		push_warning("[Terreno] rejilla inválida, plano de repliegue")
		return
	var step: float = float(spec.get("tile_size", 128.0)) / 128.0
	var ox: float = spec.get("origin", [0, 0])[0]
	var oz: float = spec.get("origin", [0, 0])[1]
	_terrain = {"n": n, "step": step, "ox": ox, "oz": oz, "hs": hs,
		"tiles": spec.get("tiles", []), "grass": spec.get("grass", []),
		"trees": spec.get("trees", [])}
	var packed = null
	if ResourceLoader.exists(gpath):
		packed = load(gpath)
	if packed is PackedScene:
		var inst = (packed as PackedScene).instantiate()
		inst.name = "TerrainMesh"
		add_child(inst)
	else:
		add_child(_build_terrain_mesh(n, step, ox, oz, hs,
			_terrain["tiles"]))
	var body := StaticBody3D.new()
	body.name = "TerrainBody"
	body.position = Vector3(ox + (n - 1) * step / 2.0, 0.0, oz + (n - 1) * step / 2.0)
	var shape := HeightMapShape3D.new()
	shape.map_width = n
	shape.map_depth = n
	shape.map_data = PackedFloat32Array(hs)
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	add_child(body)
	$Ground.visible = false
	$Ground.get_node("CollisionShape3D").set_deferred("disabled", true)
	print("[Terreno] malla %dx%d + HeightMap (origen %.0f, %.0f)" % [n, n, ox, oz])
	_add_water(n, step, ox, oz, float(spec.get("water_y", 0.05)))
	_scatter_vegetation(spec)


func _add_water(n: int, step: float, ox: float, oz: float,
		water_y: float) -> void:
	## Lamina a la cota del spec (y=-14 en Ironhold: el campamento queda
	## seco y se encharcan las hoyas). El depth test la oculta bajo el
	## relieve emergido.
	var size := (n - 1) * step
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.55, 0.75, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.15
	plane.material = mat
	var inst := MeshInstance3D.new()
	inst.name = "Water"
	inst.mesh = plane
	inst.position = Vector3(ox + size / 2.0, water_y, oz + size / 2.0)
	add_child(inst)


func _scatter_vegetation(spec: Dictionary) -> void:
	## Hierba y arboles horneados por setup_terrain.py (verde pintado,
	## determinista). Sin puestos no crea nada (repliegue).
	var grass: Array = spec.get("grass", [])
	var trees: Array = spec.get("trees", [])
	if grass.is_empty() and trees.is_empty():
		return
	if not grass.is_empty():
		add_child(_multimesh(grass, _grass_mesh(), "Grass"))
	if not trees.is_empty():
		var xforms := _veg_transforms(trees)
		add_child(_multimesh_builder(xforms, _trunk_mesh(), "TreeTrunks",
			Vector3(0, 0.5, 0)))
		add_child(_multimesh_builder(xforms, _canopy_mesh(),
			"TreeCanopies", Vector3(0, 1.6, 0)))
	print("[Vegetacion] %d hierbas, %d arboles" % [grass.size(), trees.size()])


func _veg_transforms(spots: Array) -> Array:
	var out := []
	for i in spots.size():
		var s: Array = spots[i]
		var gy = ground_height(float(s[0]), float(s[1]))
		if gy == null:
			continue
		var yaw := fmod(float(i) * 2.39996, TAU)
		var org := Vector3(float(s[0]), float(gy) - 0.05, float(s[1]))
		out.append([Transform3D(Basis(Vector3.UP, yaw), org), float(s[2])])
	return out


func _multimesh(spots: Array, mesh: Mesh, node_name: String) -> MultiMeshInstance3D:
	return _multimesh_builder(_veg_transforms(spots), mesh, node_name)


func _multimesh_builder(xforms: Array, mesh: Mesh, node_name: String,
		offset := Vector3.ZERO) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		var t: Transform3D = xforms[i][0]
		var s: float = xforms[i][1]
		var b := Basis(t.basis.x * s, t.basis.y * s, t.basis.z * s)
		mm.set_instance_transform(i, Transform3D(b, t.origin + offset * s))
	var inst := MultiMeshInstance3D.new()
	inst.name = node_name
	inst.multimesh = mm
	return inst


func _grass_mesh() -> ArrayMesh:
	## Dos quads cruzados de ~0.5 m, verde sin sombrear.
	var v := PackedVector3Array([
		Vector3(-0.25, 0, 0), Vector3(0.25, 0, 0),
		Vector3(-0.25, 0.5, 0), Vector3(0.25, 0.5, 0),
		Vector3(0, 0, -0.25), Vector3(0, 0, 0.25),
		Vector3(0, 0.5, -0.25), Vector3(0, 0.5, 0.25)])
	var idx := PackedInt32Array([0, 1, 2, 1, 3, 2, 4, 5, 6, 5, 7, 6])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.55, 0.25)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, mat)
	return mesh


func _trunk_mesh() -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.08
	m.bottom_radius = 0.12
	m.height = 1.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.28, 0.15)
	mat.roughness = 1.0
	m.material = mat
	return m


func _canopy_mesh() -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = 0.9
	m.height = 1.8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.45, 0.2)
	mat.roughness = 1.0
	m.material = mat
	return m


func _terrain_uv(ix: int, iz: int, n: int, xs: Array, ys: Array,
		nx: int, ny: int) -> Vector2:
	## Cuadrante del tile con inset (igual que lnd_to_glb.py).
	if xs.is_empty():
		return Vector2(ix / float(n - 1), iz / float(n - 1))
	var inset := 0.5 / 256.0
	var tix := mini(ix / 128, nx - 1)
	var tiz := mini(iz / 128, ny - 1)
	var u := clampf((ix - tix * 128) / 128.0, inset, 1.0 - inset)
	var v := clampf((iz - tiz * 128) / 128.0, inset, 1.0 - inset)
	return Vector2((tix + u) / nx, (tiz + v) / ny)


func _build_terrain_mesh(n: int, step: float, ox: float, oz: float,
		hs: Array, tiles: Array) -> MeshInstance3D:
	## Visual de repliegue cuando el .glb no está importado (misma matemática
	## que lnd_to_glb.py): la colisión y el snap salen del JSON igualmente.
	## Con atlas generado usa la pintura; si no, verde plano.
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	verts.resize(n * n)
	normals.resize(n * n)
	uvs.resize(n * n)
	var xs := []
	var ys := []
	for t in tiles:
		if not xs.has(int(t[0])):
			xs.append(int(t[0]))
		if not ys.has(int(t[1])):
			ys.append(int(t[1]))
	xs.sort()
	ys.sort()
	var nx := maxi(xs.size(), 1)
	var ny := maxi(ys.size(), 1)

	var h := func(ix: int, iz: int) -> float:
		return float(hs[clampi(iz, 0, n - 1) * n + clampi(ix, 0, n - 1)])
	for iz in range(n):
		for ix in range(n):
			var dx: float = (h.call(ix + 1, iz) - h.call(ix - 1, iz)) / (2.0 * step)
			var dz: float = (h.call(ix, iz + 1) - h.call(ix, iz - 1)) / (2.0 * step)
			var inv := 1.0 / sqrt(dx * dx + 1.0 + dz * dz)
			verts[iz * n + ix] = Vector3(ox + ix * step, h.call(ix, iz), oz + iz * step)
			normals[iz * n + ix] = Vector3(-dx * inv, inv, -dz * inv)
			uvs[iz * n + ix] = _terrain_uv(ix, iz, n, xs, ys, nx, ny)
	var idx := PackedInt32Array()
	for iz in range(n - 1):
		for ix in range(n - 1):
			var a := iz * n + ix
			idx += PackedInt32Array([a, a + n, a + 1, a + 1, a + n, a + n + 1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := StandardMaterial3D.new()
	mat.roughness = 1.0
	if ResourceLoader.exists("res://models/terrain_ironhold_atlas.png"):
		mat.albedo_texture = load("res://models/terrain_ironhold_atlas.png")
		mat.albedo_color = Color(0.82, 0.82, 0.82)
	else:
		mat.albedo_color = Color(0.32, 0.38, 0.3)
	mesh.surface_set_material(0, mat)
	var inst := MeshInstance3D.new()
	inst.name = "TerrainMesh"
	inst.mesh = mesh
	return inst


func ground_height(x: float, z: float):
	## Altura bilineal o null sin terreno.
	if _terrain == null:
		return null
	var n: int = _terrain["n"]
	var fx: float = (x - _terrain["ox"]) / _terrain["step"]
	var fz: float = (z - _terrain["oz"]) / _terrain["step"]
	var x0 := clampi(int(floor(fx)), 0, n - 2)
	var z0 := clampi(int(floor(fz)), 0, n - 2)
	var tx: float = clampf(fx - x0, 0.0, 1.0)
	var tz: float = clampf(fz - z0, 0.0, 1.0)
	var hs: Array = _terrain["hs"]
	var h00: float = hs[z0 * n + x0]
	var h10: float = hs[z0 * n + x0 + 1]
	var h01: float = hs[(z0 + 1) * n + x0]
	var h11: float = hs[(z0 + 1) * n + x0 + 1]
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)


func nearest_npc():
	var best = null
	var best_d := 3.5
	for n in get_tree().get_nodes_in_group("npcs"):
		var d: float = player.global_position.distance_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n
	return best


func _spawn_monsters(game_data: Node) -> void:
	var container := Node3D.new()
	container.name = "Monsters"
	add_child(container)
	var center: Vector3 = game_data.get_zone_spawn()
	var idx := 0
	for mid in game_data.monsters:
		var def: Dictionary = game_data.monsters[mid]
		if str(def.get("zone", "")) != game_data.current_zone_id:
			continue
		var count := 5 if str(mid) == "mon_001" else 1
		for i in count:
			_spawn_one(container, def, center, idx)
			idx += 1
	print("[Main] %d monstruos generados" % idx)


func _spawn_one(container: Node3D, def: Dictionary, center: Vector3, idx: int) -> void:
	var m := CharacterBody3D.new()
	m.set_script(MonsterScript)
	# Capa 2: el jugador (capa 1) los atraviesa — con agro en enjambre lo
	# encerraban y no podía caminar. El contacto sigue por distancia y el
	# monstruo sí choca con el mundo y frena a 1.1 m.
	m.collision_layer = 2
	m.collision_mask = 1
	var a := (float(idx) / 9.0) * TAU
	var pos := center + Vector3(cos(a) * (5.0 + idx), 1.0, sin(a) * (5.0 + idx))
	m.position = pos
	var gy = ground_height(pos.x, pos.z)
	if gy != null:
		m.position.y = gy + 1.0
	m.setup(def)

	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.2
	shape.shape = cap
	shape.position = Vector3(0, 0.7, 0)
	m.add_child(shape)

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Body"
	var cap_mesh := CapsuleMesh.new()
	cap_mesh.radius = 0.4
	cap_mesh.height = 1.2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.3, 0.2, 1)
	cap_mesh.material = mat
	mesh_inst.mesh = cap_mesh
	mesh_inst.position = Vector3(0, 0.7, 0)
	m.add_child(mesh_inst)

	var label := Label3D.new()
	label.name = "NameLabel"
	label.position = Vector3(0, 1.8 + float(idx % 3) * 0.25, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 48
	m.add_child(label)

	container.add_child(m)


func _first_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n as MeshInstance3D
	for c in n.get_children():
		var r := _first_mesh(c)
		if r != null:
			return r
	return null


# --- Simulación headless ---
func _check(cond: bool, msg: String) -> void:
	if cond:
		print("[SIM] ok: " + msg)
	else:
		_failures.append(msg)
		print("[SIM] FALLO: " + msg)


func _run_sim() -> void:
	print("[SIM] inicio de simulación de misión")
	var game_data: Node = get_node("/root/GameData")
	var quest_mgr: Node = get_node("/root/QuestManager")

	_check(game_data.current_zone_id == "ironhold", "zona actual es ironhold")
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "raton libre por defecto")
	_check(game_data.zones.size() >= 1 and game_data.dialogues.size() >= 2,
		"datos cargados (zonas/dialogos)")

	var audio = get_node("/root/AudioManager")
	_check(audio.missing_files().is_empty(),
		"audio 16/16 presente (%s)" % str(audio.missing_files()))
	for sfx_name in audio.known_sfx():
		audio.play_sfx(sfx_name)
	_check(true, "%d SFX emitidos sin error" % audio.known_sfx().size())
	audio.notify_combat()
	_check(audio._in_combat_music, "musica de combate activa tras agresion")
	audio.toggle_mute()
	_check(audio.muted, "mute con M funciona")
	audio.toggle_mute()
	_check(not audio.muted, "unmute restaura")

	var expected := 0
	for mid in game_data.monsters:
		if str(game_data.monsters[mid].get("zone", "")) == "ironhold":
			expected += 5 if str(mid) == "mon_001" else 1
	_check(get_tree().get_nodes_in_group("monsters").size() == expected,
		"monstruos generados = %d" % expected)

	# --- terreno (aethermere-lnd; el jugador cae al arrancar) ---
	_check(_terrain != null, "terreno cargado (malla + HeightMap)")
	if _terrain != null:
		for i in 60:
			await get_tree().physics_frame
		var gy0 = ground_height(player.global_position.x, player.global_position.z)
		_check(gy0 != null and absf(player.global_position.y - (gy0 - 0.1)) < 0.8,
			"jugador reposa en el suelo (y %.1f vs %.1f)" % [player.global_position.y, gy0])
		# Ladera del macizo este: colisión y muestreo coinciden (anti-espejo).
		var sgy = ground_height(100.0, -150.0)
		if sgy != null:
			player.global_position = Vector3(100.0, sgy + 5.0, -150.0)
			player.velocity = Vector3.ZERO
			for i in 60:
				await get_tree().physics_frame
			var sgy2 = ground_height(player.global_position.x, player.global_position.z)
			_check(sgy2 != null and absf(player.global_position.y - (sgy2 - 0.1)) < 1.0,
				"reposa en ladera (y %.1f vs %.1f)" % [player.global_position.y, sgy2])

	# --- color del terreno (aethermere-terrain-color) ---
	_check(get_node_or_null("Water") != null, "agua al nivel del mar")
	var tm = get_node_or_null("TerrainMesh")
	var tmi: MeshInstance3D = null
	if tm is MeshInstance3D:
		tmi = tm as MeshInstance3D
	elif tm != null:
		tmi = _first_mesh(tm)
	if tmi != null:
		var tmat = tmi.get_surface_override_material(0)
		if tmat == null:
			tmat = tmi.mesh.surface_get_material(0)
		var has_tex := tmat != null and tmat is StandardMaterial3D \
			and (tmat as StandardMaterial3D).albedo_texture != null
		if ResourceLoader.exists("res://models/terrain_ironhold_atlas.png"):
			_check(has_tex, "suelo con pintura del atlas")
		else:
			_check(not has_tex, "repliegue verde sin atlas")
	var gr = get_node_or_null("Grass")
	var trunks = get_node_or_null("TreeTrunks")
	var want_grass: Array = (_terrain as Dictionary).get("grass", []) \
		if _terrain != null else []
	if not want_grass.is_empty():
		var got := 0
		if gr != null:
			got = (gr as MultiMeshInstance3D).multimesh.instance_count
		_check(got > 0, "hierba instanciada (%d)" % got)
		_check(trunks != null, "arboles instanciados")
	else:
		_check(gr == null, "sin hierba sin puestos")

	# --- proteccion (aethermere-spawn-safe; gracia fresca de _ready) ---
	player.hp = player.max_hp
	_check(player.protect_t > 0.0, "gracia activa al aparecer (%.1f s)" % player.protect_t)
	var php: float = player.hp
	player.take_mob_damage(50.0)
	_check(is_equal_approx(player.hp, php), "inmune protegido (%.0f HP)" % player.hp)
	var guard: Node3D = null
	for m in get_tree().get_nodes_in_group("monsters"):
		if not m.get("_dead"):
			guard = m
			break
	if guard != null:
		guard.set("aggro_target", null)
		player.global_position = guard.global_position + Vector3(3.0, 0.0, 0.0)
		for i in 60:
			await get_tree().physics_frame
		_check(guard.get("aggro_target") == null, "sin agro a protegido")
		_check(is_equal_approx(player.hp, php), "sin dano por contacto protegido")
		player.attack()
		_check(player.protect_t <= 0.0, "atacar rompe la gracia")
	player.protect_t = 0.0

	dialogue.open("npc_001")
	_check(dialogue.is_open(), "dialogo se abre con E")
	_check(dialogue.current_node == "start", "dialogo inicia en nodo start")
	dialogue._show_node("quest_offer")
	_check(dialogue.accept_button.visible, "quest_offer muestra boton Aceptar")
	dialogue.close()
	_check(not dialogue.is_open(), "dialogo se cierra")

	_check(quest_mgr.accept_quest("quest_101"), "aceptar quest_101")
	_check(not quest_mgr.accept_quest("quest_101"), "repetir quest_101 se rechaza")
	_check(quest_mgr.first_active() == "quest_101", "tracker ve quest_101 activa")

	var exp0: float = player.exp
	var bread0: int = int(player.inventory.get("item_003", 0))
	for i in 5:
		quest_mgr.report_kill("mon_001")
	_check("quest_101" in quest_mgr.done, "quest_101 completada")
	_check("quest_102" in quest_mgr.available_quests(), "quest_102 desbloqueada")
	_check(player.exp >= exp0 + 40.0, "recompensa 40 EXP aplicada")
	_check(int(player.inventory.get("item_003", 0)) == bread0 + 1, "recompensa item_003 en inventario")

	_check(quest_mgr.accept_quest("quest_102"), "aceptar quest_102")

	var crow: Node3D = null
	for m in get_tree().get_nodes_in_group("monsters"):
		if m.get("monster_id") == "mon_004":
			crow = m
			break
	_check(crow != null, "existe mon_004 en escena")
	if crow != null:
		player.global_position = crow.global_position + Vector3(1.0, 0.0, 0.0)
		player.basic_cd = 0.0
		player.attack()
		_check(is_equal_approx(crow.hp, 20.0),
			"basico con formula: 25 - max(1,5-0) = 20 (%.0f)" % crow.hp)

	var victim: Node3D = null
	for m in get_tree().get_nodes_in_group("monsters"):
		if m.get("monster_id") == "mon_002":
			victim = m
			break
	_check(victim != null, "existe mon_002 en escena")
	if victim != null:
		var prog0: Array = quest_mgr.progress("quest_102")
		victim.take_damage(999.0)
		var waited := 0
		while is_instance_valid(victim) and waited < 400:
			await get_tree().process_frame
			waited += 1
		_check(not is_instance_valid(victim), "mon_002 muere y se libera")
		var prog1: Array = quest_mgr.progress("quest_102")
		_check(prog1.size() == 2 and int(prog1[0]) == int(prog0[0]) + 1,
			"muerte cuenta para quest_102 (%s)" % str(prog1))

	# --- skills ---
	_check(player.known_skills() == ["skill_001"], "nivel 1 solo conoce Ember")
	_check(not player.cast_skill("skill_002"), "Bulwark bloqueado a nivel 1")
	_check(not player.cast_skill("skill_999"), "skill inexistente se rechaza")
	player.mp = 0.0
	_check(player.skill_state("skill_001")[0] == "no_mana", "sin MP estado no_mana")
	_check(not player.cast_skill("skill_001"), "sin MP no se castea")
	player.mp = player.max_mp
	player.level = 3
	_check(player.known_skills().size() == 3, "nivel 3 conoce las 3 skills")

	var hare: Node3D = null
	for m in get_tree().get_nodes_in_group("monsters"):
		if m.get("monster_id") == "mon_001" and m.hp >= 30.0:
			hare = m
			break
	_check(hare != null, "existe liebre intacta para Ember")
	if hare != null:
		player.global_position = hare.global_position + Vector3(1.0, 0.0, 0.0)
		var mp0: float = player.mp
		_check(player.cast_skill("skill_001"), "Ember se lanza")
		_check(is_equal_approx(hare.hp, 13.0),
			"Ember con formula: 30 - max(1,5+12-0) = 13 (%.0f)" % hare.hp)
		_check(is_equal_approx(player.mp, mp0 - 5.0), "Ember cuesta 5 MP")
		_check(not player.cast_skill("skill_001"), "Ember en cooldown se rechaza")

	_check(player.cast_skill("skill_002"), "Bulwark se activa")
	_check(player.bulwark_time > 0.0, "buff Bulwark corriendo")
	var php0: float = player.hp
	player.take_mob_damage(10.0)
	_check(absf(player.hp - (php0 - 4.5)) < 0.01,
		"Bulwark mitiga: max(1,10-1)/2 = 4.5 (%.1f)" % (php0 - player.hp))

	_check(player.cast_skill("skill_003"), "Bandage se lanza")
	_check(absf(player.hp - minf(player.max_hp, php0 - 4.5 + 30.0)) < 0.01,
		"Bandage cura 30%% del max (%.0f HP)" % player.hp)
	_check(not player.cast_skill("skill_003"), "Bandage en cooldown se rechaza")

	# --- tienda y equipo ---
	var gold0: int = player.gold
	_check(gold0 >= 30, "oro inicial + botin >= 30 (%d)" % gold0)
	var bread: int = int(player.inventory.get("item_003", 0))
	_check(player.buy("item_003"), "comprar pan")
	_check(player.gold == gold0 - 4, "pan cuesta 4 (%d)" % player.gold)
	_check(int(player.inventory.get("item_003", 0)) == bread + 1, "pan en inventario")
	player.gold = 3
	_check(not player.buy("item_002"), "sin oro no hay compra")
	_check(not player.buy("item_XXX"), "item inexistente se rechaza")
	player.gold = gold0 - 4

	_check(player.sell("item_006"), "vender cuero de jabali")
	_check(player.gold == gold0 - 4 + 2, "venta a mitad: 5/2 = 2 (%d)" % player.gold)
	_check(not player.sell("item_010"), "objeto de mision no vendible")
	_check(not player.sell("item_XXX"), "vender inexistente se rechaza")

	_check(player.equip("item_001"), "equipar espada")
	_check(is_equal_approx(player.attack_stat(), 8.0), "ataque 5+3 = 8")
	_check(not player.sell("item_001"), "equipada no vendible")
	_check(player.equip("item_002"), "equipar tunica")
	_check(is_equal_approx(player.defense_stat(), 3.0), "defensa 1+2 = 3")
	_check(player.unequip("weapon"), "desequipar arma")
	_check(is_equal_approx(player.attack_stat(), 5.0), "ataque vuelve a 5")
	_check(player.equip("item_001"), "reequipar espada para cazar")

	# Pell: dialogo de mercader con boton Comerciar
	var pell_y = ground_height(-4, 2)
	player.global_position = Vector3(-4, (pell_y if pell_y != null else 0.0) + 1.0, 2)
	var near = nearest_npc()
	_check(near != null and str(near.get_meta("npc_id")) == "npc_002",
		"E junto a Pell lo elige")
	dialogue.open("npc_002")
	_check(dialogue.trade_button.visible, "mercader muestra Comerciar")
	dialogue.close()
	dialogue.open("npc_001")
	_check(not dialogue.trade_button.visible, "Maren no muestra Comerciar")
	dialogue.close()
	hud.open_shop()
	_check(hud.is_shop_open(), "tienda se abre")
	hud.close_shop()
	_check(not hud.is_shop_open(), "tienda se cierra")

	# --- cadena 103-110 (la 102 quedo en 1/3: se remata aqui) ---
	quest_mgr.report_kill("mon_002")
	quest_mgr.report_kill("mon_002")
	_check("quest_102" in quest_mgr.done, "quest_102 completada (3/3)")
	var chain := ["quest_103", "quest_104", "quest_105", "quest_106",
		"quest_107", "quest_108", "quest_109", "quest_110"]
	for qid in chain:
		_check(qid in quest_mgr.available_quests(), qid + " disponible en cadena")
		_check(quest_mgr.accept_quest(qid), "aceptada " + qid)
		var q: Dictionary = game_data.quests[qid]
		var need := int(q["target"]["count"])
		for i in need:
			quest_mgr.report_kill(str(q["target"]["monster_id"]))
		_check(qid in quest_mgr.done, qid + " completada")
	_check(quest_mgr.done.size() == 10, "10/10 misiones completadas")
	_check(quest_mgr.available_quests().is_empty(), "sin misiones pendientes")
	_check(player.level >= 5, "nivel >= 5 al cierre (es %d)" % player.level)

	# --- guardado ---
	var save_mgr = get_node("/root/SaveManager")
	_check(save_mgr.save_game(), "guardar partida")
	var gold_s: int = player.gold
	var done_s: int = quest_mgr.done.size()
	player.gold = 0
	quest_mgr.reset()
	_check(quest_mgr.done.is_empty(), "reset vacia misiones")
	_check(save_mgr.load_game(), "cargar partida")
	_check(player.gold == gold_s, "oro restaurado (%d)" % player.gold)
	_check(quest_mgr.done.size() == done_s, "misiones restauradas (%d)" % done_s)
	_check(int(player.inventory.get("item_003", 0)) > 0, "inventario restaurado")

	# --- consumibles ---
	player.hp = 50.0
	var bread_n: int = int(player.inventory.get("item_003", 0))
	_check(player.use_item("item_003"), "usar pan herido")
	_check(is_equal_approx(player.hp, 75.0), "pan +25 HP (%.0f)" % player.hp)
	_check(int(player.inventory.get("item_003", 0)) == bread_n - 1, "pan consumido")
	_check(not player.use_item("item_003"), "cooldown bloquea segundo pan")
	_check(not player.use_item("item_001"), "espada no usable")
	_check(not player.use_item("item_XXX"), "inexistente no usable")
	player.hp = player.max_hp
	player.mp = player.max_mp
	player.use_cooldown = 0.0
	_check(not player.use_item("item_003"), "a tope no se consume")
	_check(not player.use_item("item_004"), "tonico a MP lleno se rechaza")
	player.mp = 10.0
	player.use_cooldown = 0.0
	_check(player.use_item("item_004"), "usar tonico con MP bajo")
	_check(is_equal_approx(player.mp, 30.0), "tonico +20 MP (%.0f)" % player.mp)

	# --- movimiento (regresion WASD) ---
	var m0: Vector3 = player.global_position
	Input.action_press("move_forward")
	for i in 30:
		await get_tree().physics_frame
	var papw = player.get("_anim")
	if papw != null:
		_check(papw.current_animation == "walk", "walk al desplazarse")
	for i in 30:
		await get_tree().physics_frame
	Input.action_release("move_forward")
	var moved: float = m0.distance_to(player.global_position)
	_check(moved > 3.0, "WASD mueve al jugador (%.1f m en 1 s)" % moved)
	# El .glb mira a -Z: con MODEL_YAW (+PI) la malla encara la orden de
	# marcha. Se compara contra la dirección ordenada (no contra el
	# desplazamiento neto: en pendiente el cuerpo derrapa y no coincide).
	var pmodel: Node3D = player.get_node_or_null("Model")
	if pmodel != null:
		var cam_yaw: float = (player.get_node("CamPivot") as Node3D).global_rotation.y
		var cmd: Vector3 = Basis(Vector3.UP, cam_yaw) * Vector3(0.0, 0.0, -1.0)
		var want_march: float = atan2(cmd.x, cmd.z) + PI
		_check(absf(wrapf(pmodel.rotation.y - want_march, -PI, PI)) < 0.5,
			"avatar encara la marcha (sin moonwalk)")

	# --- animaciones (aethermere-anim) ---
	var modeled := 0
	var walked := 0
	for m in get_tree().get_nodes_in_group("monsters"):
		if str(m.get("model_name")) == "":
			continue
		modeled += 1
		if _is_locomotion(m):
			walked += 1
	if walked != modeled:
		# Un golpe a medio reproducir no es Marcha quieta: se deja
		# terminar (~1.4 s) y se recuenta una vez antes de fallar.
		for i in 120:
			await get_tree().physics_frame
		walked = 0
		for m in get_tree().get_nodes_in_group("monsters"):
			if str(m.get("model_name")) == "":
				continue
			if _is_locomotion(m):
				walked += 1
	_check(modeled >= 7, "monstruos con modelo en escena (%d)" % modeled)
	_check(walked == modeled, "locomocion en marcha (%d/%d)" % [walked, modeled])

	var hare2: Node3D = null
	for m in get_tree().get_nodes_in_group("monsters"):
		if m.get("monster_id") == "mon_001" and not m.get("_dead"):
			hare2 = m
			break
	_check(hare2 != null, "existe liebre viva para anim de ataque")
	if hare2 != null:
		player.hp = player.max_hp
		for i in 200:
			if is_instance_valid(hare2) and not hare2.get("_dead"):
				player.global_position = hare2.global_position + Vector3(1.0, 0.0, 0.0)
			await get_tree().physics_frame
		_check(bool(hare2.get("_attacked_anim")), "liebre reproduce atk al golpear")

	# --- avatar del jugador (aethermere-player-avatar) ---
	if ResourceLoader.exists("res://models/PlayerMvr.glb"):
		_check(player.get_node_or_null("Model") != null, "avatar montado")
		var pap = player.get("_anim")
		_check(pap != null and pap.is_playing(), "locomocion del avatar activa")
	else:
		_check(player.get_node_or_null("Model") == null, "repliegue a capsula sin modelo")

	# --- agro + target (aethermere-aggro-target) ---
	var wisp: Node3D = null
	for m in get_tree().get_nodes_in_group("monsters"):
		if m.get("monster_id") == "mon_003" and not m.get("_dead"):
			wisp = m
			break
	_check(wisp != null, "existe wisp vivo para agro por dano")
	if wisp != null:
		wisp.set("aggro_target", null)
		wisp.take_damage(1.0, player)
		_check(wisp.get("aggro_target") == player, "dano fija agro fuera de rango")

	var brute: Node3D = null
	for m in get_tree().get_nodes_in_group("monsters"):
		if m.get("monster_id") == "mon_005" and not m.get("_dead"):
			brute = m
			break
	_check(brute != null, "existe lobo vivo para agro")
	var calm: Node3D = null
	for m in get_tree().get_nodes_in_group("monsters"):
		if m.get("monster_id") == "mon_001" and not m.get("_dead"):
			calm = m
			break
	if calm != null:
		calm.set("aggro_target", null)
		player.global_position = calm.global_position + Vector3(4.0, 0.0, 0.0)
		for i in 60:
			await get_tree().physics_frame
		_check(calm.get("aggro_target") == null, "liebre mansa no agro a 4 m")
	if brute != null:
		brute.set("aggro_target", null)
		player.hp = player.max_hp
		player.protect_t = 0.0
		# Llano para cazar: el punto con menos pendiente en radio 30 m.
		var flat := Vector3(0, 0.5, 0)
		var best := 999.0
		for gx in range(-30, 31, 5):
			for gz in range(-30, 31, 5):
				var h0 = ground_height(gx, gz)
				var hx = ground_height(gx + 2, gz)
				var hz = ground_height(gx, gz + 2)
				if h0 == null or hx == null or hz == null:
					continue
				var sl = absf(hx - h0) / 2.0 + absf(hz - h0) / 2.0
				if sl < best:
					best = sl
					flat = Vector3(gx, h0 + 0.5, gz)
		brute.global_position = flat
		brute.velocity = Vector3.ZERO
		player.global_position = flat + Vector3(5.0, 0.5, 0.0)
		for i in 60:
			await get_tree().physics_frame
		_check(brute.get("aggro_target") == player, "proximidad 5m fija agro")
		var d0: float = brute.global_position.distance_to(player.global_position)
		for i in 60:
			await get_tree().physics_frame
		var d1: float = brute.global_position.distance_to(player.global_position)
		_check(d1 < d0 - 0.5, "persecucion acerca (%.1f -> %.1f)" % [d0, d1])
		player.global_position = brute.global_position + Vector3(30.0, 0.0, 0.0)
		for i in 30:
			await get_tree().physics_frame
		_check(brute.get("aggro_target") == null, "leash 14m suelta agro")

	var tgt1: Node3D = null
	var tgt2: Node3D = null
	for m in get_tree().get_nodes_in_group("monsters"):
		if m.get("monster_id") == "mon_001" and not m.get("_dead"):
			if tgt1 == null:
				tgt1 = m
			elif tgt2 == null:
				tgt2 = m
				break
	_check(tgt1 != null and tgt2 != null, "dos liebres vivas para target")
	if tgt1 != null and tgt2 != null:
		tgt1.set("hp", 30.0)
		tgt2.set("hp", 30.0)
		player.global_position = Vector3(0, 0.5, 0)
		tgt1.global_position = player.global_position + Vector3(2.0, 0.0, 0.0)
		tgt2.global_position = player.global_position + Vector3(1.0, 0.0, 0.0)
		player.target = tgt1
		player.basic_cd = 0.0
		player.attack()
		_check(is_equal_approx(tgt1.hp, 22.0) and is_equal_approx(tgt2.hp, 30.0),
			"basico pega al objetivo a 2m, no al cercano (%.0f/%.0f)" % [tgt1.hp, tgt2.hp])
		tgt1.global_position = player.global_position + Vector3(20.0, 0.0, 0.0)
		var thp0: float = tgt1.hp
		_check(not player.attack(tgt1), "objetivo lejos: solo se fija")
		_check(is_equal_approx(tgt1.hp, thp0), "sin dano fuera de rango")
		_check(player.target == tgt1, "objetivo lejano se conserva")
		tgt1.take_damage(999.0)
		var waited2 := 0
		while is_instance_valid(tgt1) and waited2 < 400:
			await get_tree().process_frame
			waited2 += 1
		for i in 5:
			await get_tree().physics_frame
		_check(player.target == null, "objetivo muerto se limpia")

	# --- melee (aethermere-melee) ---
	player.global_position = Vector3(0, 0.5, 0)
	player.hp = player.max_hp
	player.protect_t = 0.0
	if brute != null and is_instance_valid(brute) and not brute.get("_dead"):
		brute.set("aggro_target", null)
		brute.global_position = player.global_position + Vector3(4.0, 0.0, 0.0)
		for i in 120:
			await get_tree().physics_frame
		var dc: float = brute.global_position.distance_to(player.global_position)
		_check(dc >= 0.8, "frenada a >= 0.8 m (%.2f)" % dc)
		var to_b: Vector3 = player.global_position - brute.global_position
		var ang: float = absf(wrapf(atan2(to_b.x, to_b.z) - brute.rotation.y, -PI, PI))
		_check(ang < 0.5, "encarado al golpear (< %.2f rad)" % ang)
	else:
		_check(false, "lobo vivo para frenada")

	player.hp = player.max_hp
	player.global_position = Vector3(0, 0.5, 0)
	player._set_dest(Vector3(5.0, 0.5, 0.0))
	for i in 120:
		await get_tree().physics_frame
	var dd: float = Vector2(player.global_position.x - 5.0, player.global_position.z).length()
	_check(dd < 0.6, "click-mover llega (a %.2f m)" % dd)
	player._set_dest(Vector3(-5.0, 0.5, 0.0))
	Input.action_press("move_forward")
	for i in 10:
		await get_tree().physics_frame
	Input.action_release("move_forward")
	_check(not player.get("has_dest"), "WASD cancela destino")

	if brute != null and is_instance_valid(brute) and not brute.get("_dead"):
		brute.set("hp", 80.0)
		player.hp = player.max_hp
		player.protect_t = 0.0
		player.global_position = Vector3(0, 0.5, 0)
		brute.global_position = player.global_position + Vector3(6.0, 0.0, 0.0)
		brute.set("aggro_target", null)
		player.target = brute
		player.auto_attack = true
		var whp0: float = brute.hp
		for i in 240:
			if i == 120:
				player.hp = player.max_hp
			await get_tree().physics_frame
		_check(brute.hp < whp0, "auto-basicos bajan HP (%.0f -> %.0f)" % [whp0, brute.hp])
		player.auto_attack = false
		player.target = null
		brute.global_position = player.global_position + Vector3(2.0, 0.0, 0.0)
		player.basic_cd = 0.0
		var c0: float = brute.hp
		_check(player.attack(brute), "primer basico sale")
		_check(not player.attack(brute), "segundo inmediato se rechaza por cooldown")
		_check(is_equal_approx(brute.hp, c0 - 5.0), "solo un impacto (%.0f)" % brute.hp)
		if player.get("_anim") != null:
			_check(bool(player.get("_attacked_anim")), "avatar reproduce atk1 al golpear")
			_check(str(player.get("_anim").current_animation) == "atk1",
				"atk1 con prioridad sobre stand al golpear")
		var vis: Node3D = player.get_node_or_null("Model")
		# El .glb mira a -Z local: player.gd lo compensa con +PI; la
		# cápsula de repliegue (simétrica) no lleva compensación.
		var yaw_off := PI if vis != null else 0.0
		if vis == null:
			vis = player.get_node("MeshInstance3D") as Node3D
		if vis != null and is_instance_valid(brute):
			var tb: Vector3 = brute.global_position - player.global_position
			var want: float = atan2(tb.x, tb.z)
			_check(absf(wrapf(want - (vis.rotation.y - yaw_off), -PI, PI)) < 0.5,
				"avatar encara al golpear")
	else:
		_check(false, "lobo vivo para auto-ataque")

	if _failures.is_empty():
		print("SIM-QUEST PASS")
		get_tree().quit(0)
	else:
		print("SIM-QUEST FAIL: %s" % str(_failures))
		get_tree().quit(1)


func _is_locomotion(m: Node) -> bool:
	var ap = m.get("_anim")
	if ap == null or not ap.is_playing():
		return false
	var cur: String = ap.current_animation
	return cur in ["walk", "Walk", "stand", "Stand", "idle1", "Idle1"]


func _take_shot() -> void:
	## Gancho de prueba visual: prepara una escena opcional, espera ~2 s,
	## captura la vista y sale. Uso: `-- --shot path.png [dlg|shop|inv]`.
	var args := OS.get_cmdline_user_args()
	var mode := ""
	for a in args:
		if a in ["dlg", "shop", "inv"]:
			mode = a
	if mode == "dlg":
		player.global_position = Vector3(4, 0.5, 0.5)
		dialogue.open("npc_001")
	elif mode == "shop":
		hud.open_shop()
	elif mode == "inv":
		player.add_item("item_005", 2)
		hud._inventory_open = true
		hud.inventory_panel.visible = true
		hud._rebuild_inventory()
	for i in 120:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var path := "/tmp/aethermere_shot.png"
	var idx := args.find("--shot")
	if idx != -1 and args.size() > idx + 1 and not args[idx + 1].begins_with("--"):
		path = args[idx + 1]
	img.save_png(path)
	print("[SHOT] guardada en " + path)
	get_tree().quit(0)
