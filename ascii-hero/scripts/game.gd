extends Node
## ASCII Hero - main game controller (root node of main.tscn).
## Spawns shadow-imp enemies at the field edges, handles score / health,
## sword-slash attacks, camera follow, ASCII ground tiles + grass,
## and the Game Over / Restart flow. No ads, no IAP, no network.
##
## The ASCII look itself comes from shaders/ascii.gdshader: the whole
## 3D SubViewport is re-drawn as characters (12px cells, monotonic
## ramp " .:+*o%#M@", luminance boost pow(lum,0.65)*1.4). The ground
## tiles below exist so the ground has real brightness variation to
## turn into characters - a flat single-colour ground would render
## as one repeated character.

const EnemyScript: GDScript = preload("res://scripts/enemy.gd")
const FIELD_LIMIT: float = 23.0
const ATTACK_RANGE: float = 4.0
const ATTACK_DAMAGE: float = 35.0
const ATTACK_COOLDOWN: float = 0.45

var score: int = 0
var health: float = 100.0
var max_health: float = 100.0
var game_over: bool = false

var _spawn_timer: float = 1.0
var _attack_cooldown: float = 0.0
var _slash_effects: Array = []
var _time: float = 0.0
var _grass_base: Array = []
var _grass_phase: Array = []
var _grass_bent: Array = []

@onready var _player: CharacterBody3D = $SubViewport/World/Player
@onready var _world: Node3D = $SubViewport/World
@onready var _camera_rig: Node3D = $SubViewport/World/CameraRig
@onready var _enemies_node: Node3D = $SubViewport/World/Enemies
@onready var _tiles: MultiMeshInstance3D = $SubViewport/World/GroundTiles
@onready var _grass: MultiMeshInstance3D = $SubViewport/World/Grass
@onready var _hud: CanvasLayer = $HUD
@onready var _joystick: Control = $HUD/Controls/Joystick


func _ready() -> void:
	randomize()
	_player.game_ref = self
	_hud.attack_pressed.connect(_on_attack)
	_hud.restart_pressed.connect(_on_restart)
	_setup_fence()
	_setup_ground_tiles()
	_setup_grass()
	_setup_hero_light()
	_hud.update_score(score, 0)
	_hud.update_health(health, max_health)
	_hud.update_cooldown(0.0)


func _mat(color: Color, emission: Color = Color(0, 0, 0), energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m


func _setup_fence() -> void:
	var mat := _mat(Color(0.4, 0.3, 0.18))
	var walls: Array = [
		[Vector3(0, 0.6, -24.5), Vector3(50, 1.2, 0.6)],
		[Vector3(0, 0.6, 24.5), Vector3(50, 1.2, 0.6)],
		[Vector3(-24.5, 0.6, 0), Vector3(0.6, 1.2, 50)],
		[Vector3(24.5, 0.6, 0), Vector3(0.6, 1.2, 50)],
	]
	for w in walls:
		var wall := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = w[1]
		wall.mesh = mesh
		wall.material_override = mat
		wall.position = w[0]
		_world.add_child(wall)


func _setup_ground_tiles() -> void:
	# 24x24 ASCII ground tiles (2m each, covering the 48m field).
	# Per-instance colours give the shader real brightness steps to
	# turn into different characters: light/dark grass greens and
	# a few grey stone tiles, so the ground reads as
	# ". : + * #" instead of one flat character.
	var tile := BoxMesh.new()
	tile.size = Vector3(1.9, 0.06, 1.9)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = tile
	var per_side: int = 24
	mm.instance_count = per_side * per_side
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var i: int = 0
	for gx in range(per_side):
		for gz in range(per_side):
			var x: float = -23.0 + float(gx) * 2.0
			var z: float = -23.0 + float(gz) * 2.0
			var col: Color
			var roll: float = rng.randf()
			if roll < 0.14:
				# Stone tile - bright grey, reads as a dense character.
				col = Color(0.55, 0.55, 0.58)
			elif (gx + gz) % 2 == 0:
				col = Color(0.10, 0.48, 0.16)
			else:
				col = Color(0.06, 0.33, 0.10)
			mm.set_instance_transform(i, Transform3D(Basis(), Vector3(x, 0.03, z)))
			mm.set_instance_color(i, col)
			i += 1
	_tiles.multimesh = mm
	_tiles.material_override = _mat(Color.WHITE)


func _setup_grass() -> void:
	var mat := _mat(Color(0.12, 0.75, 0.25))
	var box := BoxMesh.new()
	box.size = Vector3(0.09, 1.1, 0.09)
	box.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box
	mm.instance_count = 600
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_grass_base.clear()
	_grass_phase.clear()
	_grass_bent.clear()
	for i in range(600):
		var x: float = rng.randf_range(-FIELD_LIMIT, FIELD_LIMIT)
		var z: float = rng.randf_range(-FIELD_LIMIT, FIELD_LIMIT)
		var sy: float = rng.randf_range(0.6, 1.5)
		var rot: float = rng.randf_range(0.0, TAU)
		var basis := Basis(Vector3.UP, rot).scaled(Vector3(1.0, sy, 1.0))
		var t := Transform3D(basis, Vector3(x, 0.5 * sy, z))
		mm.set_instance_transform(i, t)
		_grass_base.append(t)
		_grass_phase.append(rng.randf_range(0.0, TAU))
		_grass_bent.append(false)
	_grass.multimesh = mm
	_grass.material_override = mat


func _update_grass_sway(_delta: float) -> void:
	# Swaying grass, like the reference video: blades near the horse
	# bend away from it as it rides through, then spring back; blades
	# a little further out sway gently. Only instances near the horse
	# are rewritten each frame, so this stays cheap.
	if _grass.multimesh == null or _player == null:
		return
	var mm: MultiMesh = _grass.multimesh
	var hp: Vector3 = _player.global_position
	for i in range(_grass_base.size()):
		var base: Transform3D = _grass_base[i]
		var to_blade: Vector3 = base.origin - hp
		to_blade.y = 0.0
		var dist: float = to_blade.length()
		if dist < 4.5:
			# Bent away from the horse + ripple sway.
			var push: Vector3 = to_blade / maxf(dist, 0.01)
			var axis: Vector3 = Vector3.UP.cross(push).normalized()
			var angle: float = (1.0 - dist / 4.5) * 0.45 + sin(_time * 3.0 + _grass_phase[i]) * 0.12
			mm.set_instance_transform(i, Transform3D(Basis(axis, angle) * base.basis, base.origin))
			_grass_bent[i] = true
		elif dist < 9.0:
			# Gentle idle sway.
			var angle2: float = sin(_time * 1.8 + _grass_phase[i]) * 0.08
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.RIGHT, angle2) * base.basis, base.origin))
			_grass_bent[i] = true
		elif _grass_bent[i]:
			mm.set_instance_transform(i, base)
			_grass_bent[i] = false


func _setup_hero_light() -> void:
	# Warm light above the hero so the hero and the ground around
	# him stay bright enough for the ASCII ramp to show detail.
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.9, 0.7)
	light.light_energy = 1.4
	light.omni_range = 14.0
	light.position = Vector3(0, 4.5, 0)
	_player.add_child(light)


func _process(delta: float) -> void:
	_time += delta
	# Joystick + keyboard input.
	if _player != null:
		_player.joystick_vector = _joystick.output
	if Input.is_action_just_pressed("attack"):
		_on_attack()
	if Input.is_action_just_pressed("restart") and game_over:
		_on_restart()
	if game_over:
		return
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
	# Camera: smooth follow, Mobile Legends angled top-down view.
	if _player != null and _camera_rig != null:
		var target := Vector3(_player.global_position.x, 0.0, _player.global_position.z)
		_camera_rig.global_position = _camera_rig.global_position.lerp(target, delta * 5.0)
	_update_grass_sway(delta)
	# Difficulty ramps gently with score: more imps, faster spawns.
	var max_alive: int = mini(4 + score / 5, 12)
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _enemies_node.get_child_count() < max_alive:
		_spawn_enemy()
		_spawn_timer = maxf(0.9, 1.8 - float(score) * 0.02)
	# Sword-slash ring effects: expand and fade.
	for fx in _slash_effects.duplicate():
		fx["t"] += delta
		var s: float = 1.0 + fx["t"] * 14.0
		fx["node"].scale = Vector3(s, s, s)
		var mat: StandardMaterial3D = fx["node"].material_override as StandardMaterial3D
		if mat != null:
			var c: Color = mat.albedo_color
			c.a = maxf(0.0, 0.6 - fx["t"] * 1.6)
			mat.albedo_color = c
		if fx["t"] > 0.4:
			fx["node"].queue_free()
			_slash_effects.erase(fx)
	_hud.update_cooldown(_attack_cooldown)


func _spawn_enemy() -> void:
	var enemy: CharacterBody3D = EnemyScript.new()
	var side: int = randi() % 4
	var pos := Vector3.ZERO
	if side == 0:
		pos = Vector3(randf_range(-FIELD_LIMIT, FIELD_LIMIT), 0.0, -FIELD_LIMIT)
	elif side == 1:
		pos = Vector3(randf_range(-FIELD_LIMIT, FIELD_LIMIT), 0.0, FIELD_LIMIT)
	elif side == 2:
		pos = Vector3(-FIELD_LIMIT, 0.0, randf_range(-FIELD_LIMIT, FIELD_LIMIT))
	else:
		pos = Vector3(FIELD_LIMIT, 0.0, randf_range(-FIELD_LIMIT, FIELD_LIMIT))
	enemy.position = pos
	enemy.player_ref = _player
	enemy.game_ref = self
	enemy.speed = minf(2.0 + float(score) * 0.02 + randf() * 0.5, 4.0)
	_enemies_node.add_child(enemy)


func _nearest_enemy(max_dist: float) -> CharacterBody3D:
	var best: CharacterBody3D = null
	var best_dist: float = max_dist
	for child in _enemies_node.get_children():
		if child is CharacterBody3D:
			var d: float = child.global_position.distance_to(_player.global_position)
			if d < best_dist:
				best_dist = d
				best = child
	return best


func _on_attack() -> void:
	if game_over or _attack_cooldown > 0.0:
		return
	_attack_cooldown = ATTACK_COOLDOWN
	_player.try_attack()
	var target: CharacterBody3D = _nearest_enemy(ATTACK_RANGE)
	if target != null:
		target.take_damage(ATTACK_DAMAGE)
		var away: Vector3 = target.global_position - _player.global_position
		away.y = 0.0
		if away.length() > 0.01:
			target.global_position += away.normalized() * 0.8
	# Visible slash ring, even on a miss - the player must see the swing.
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.55
	mesh.outer_radius = 0.75
	mesh.rings = 24
	mesh.ring_segments = 12
	ring.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.3, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.2)
	mat.emission_energy_multiplier = 2.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = mat
	ring.position = _player.global_position + Vector3(0, 1.1, 0)
	_world.add_child(ring)
	_slash_effects.append({"node": ring, "t": 0.0})


func damage_player(amount: float) -> void:
	if game_over:
		return
	health -= amount
	_hud.update_health(health, max_health)
	if health <= 0.0:
		health = 0.0
		_game_over()


func on_enemy_killed(_enemy: CharacterBody3D) -> void:
	score += 1
	_hud.update_score(score, maxi(0, _enemies_node.get_child_count() - 1))


func _game_over() -> void:
	game_over = true
	_hud.show_game_over(score)


func _on_restart() -> void:
	get_tree().reload_current_scene()
