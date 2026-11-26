extends Node
## Dokkaebi ASCII - main game controller (root node of main.tscn).
## Spawns enemies, handles score / health / waves, firefly pickups,
## camera follow, grass + fence (built from primitives), and the
## ASCII on/off toggle. No ads, no IAP, no network.

const EnemyScript: GDScript = preload("res://scripts/enemy.gd")
const FIELD_LIMIT: float = 23.0
const ATTACK_RANGE: float = 3.6
const ATTACK_DAMAGE: float = 35.0
const BURST_RANGE: float = 6.0
const BURST_DAMAGE: float = 60.0

var score: int = 0
var health: float = 100.0
var max_health: float = 100.0
var wave: int = 1
var game_over: bool = false
var ascii_enabled: bool = true

var _spawn_timer: float = 1.0
var _attack_cooldown: float = 0.0
var _burst_cooldown: float = 0.0
var _pickups: Array = []
var _burst_effects: Array = []
var _time: float = 0.0

@onready var _player: CharacterBody3D = $SubViewport/World/Player
@onready var _world: Node3D = $SubViewport/World
@onready var _camera_rig: Node3D = $SubViewport/World/CameraRig
@onready var _enemies_node: Node3D = $SubViewport/World/Enemies
@onready var _pickups_node: Node3D = $SubViewport/World/Pickups
@onready var _grass: MultiMeshInstance3D = $SubViewport/World/Grass
@onready var _ascii_overlay: TextureRect = $ASCIIOverlay
@onready var _hud: CanvasLayer = $HUD
@onready var _joystick: Control = $HUD/Controls/Joystick


func _ready() -> void:
	randomize()
	_player.game_ref = self
	_hud.attack_pressed.connect(_on_attack)
	_hud.dash_pressed.connect(_on_dash)
	_hud.burst_pressed.connect(_on_burst)
	_hud.restart_pressed.connect(_on_restart)
	_hud.ascii_toggled.connect(_on_toggle_ascii)
	_setup_fence()
	_setup_grass()
	_setup_firefly_light()
	for i in range(8):
		_spawn_pickup()
	_hud.update_score(score, wave, 0)
	_hud.update_health(health, max_health)
	_hud.update_cooldowns(0.0, 0.0, 0.0)
	_hud.set_ascii_button(ascii_enabled)


func _mat(color: Color, emission: Color = Color(0, 0, 0), energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m


func _setup_fence() -> void:
	var mat := _mat(Color(0.25, 0.18, 0.1))
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


func _setup_grass() -> void:
	var mat := _mat(Color(0.1, 0.55, 0.18))
	var box := BoxMesh.new()
	box.size = Vector3(0.09, 1.1, 0.09)
	box.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box
	mm.instance_count = 600
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(600):
		var x: float = rng.randf_range(-FIELD_LIMIT, FIELD_LIMIT)
		var z: float = rng.randf_range(-FIELD_LIMIT, FIELD_LIMIT)
		var sy: float = rng.randf_range(0.6, 1.5)
		var rot: float = rng.randf_range(0.0, TAU)
		var basis := Basis(Vector3.UP, rot).scaled(Vector3(1.0, sy, 1.0))
		mm.set_instance_transform(i, Transform3D(basis, Vector3(x, 0.5 * sy, z)))
	_grass.multimesh = mm
	_grass.material_override = mat


func _setup_firefly_light() -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.55, 0.15)
	light.light_energy = 0.6
	light.omni_range = 22.0
	light.position = Vector3(0, 4, 0)
	_world.add_child(light)


func _spawn_pickup() -> void:
	var orb := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.28
	mesh.height = 0.56
	orb.mesh = mesh
	orb.material_override = _mat(Color(1.0, 0.55, 0.1), Color(1.0, 0.45, 0.05), 2.5)
	orb.position = Vector3(randf_range(-20.0, 20.0), 1.0, randf_range(-20.0, 20.0))
	_pickups_node.add_child(orb)
	_pickups.append(orb)


func _process(delta: float) -> void:
	_time += delta
	# Joystick + keyboard input.
	if _player != null:
		_player.joystick_vector = _joystick.output
	if Input.is_action_just_pressed("attack"):
		_on_attack()
	if Input.is_action_just_pressed("dash"):
		_on_dash()
	if Input.is_action_just_pressed("burst"):
		_on_burst()
	if Input.is_action_just_pressed("toggle_ascii"):
		_on_toggle_ascii()
	if Input.is_action_just_pressed("restart") and game_over:
		_on_restart()
	if game_over:
		return
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
	if _burst_cooldown > 0.0:
		_burst_cooldown -= delta
	# Camera: smooth follow, Mobile Legends angled top-down view.
	if _player != null and _camera_rig != null:
		var target := Vector3(_player.global_position.x, 0.0, _player.global_position.z)
		_camera_rig.global_position = _camera_rig.global_position.lerp(target, delta * 5.0)
	# Wave scales with score.
	wave = 1 + score / 150
	# Enemy spawning.
	_spawn_timer -= delta
	var max_alive: int = 3 + wave
	if _spawn_timer <= 0.0 and _enemies_node.get_child_count() < max_alive:
		_spawn_enemy()
		_spawn_timer = maxf(0.7, 2.0 - float(wave) * 0.15)
	# Firefly pickups: bob + collect.
	for orb in _pickups.duplicate():
		if not is_instance_valid(orb):
			_pickups.erase(orb)
			continue
		orb.position.y = 1.0 + sin(_time * 2.5 + orb.position.x) * 0.2
		orb.rotation.y += delta * 1.5
		if _player != null and orb.global_position.distance_to(_player.global_position) < 1.5:
			score += 10
			health = minf(max_health, health + 5.0)
			orb.position = Vector3(randf_range(-20.0, 20.0), 1.0, randf_range(-20.0, 20.0))
			_hud.update_score(score, wave, _enemies_node.get_child_count())
			_hud.update_health(health, max_health)
	# Burst ring effects.
	for fx in _burst_effects.duplicate():
		fx["t"] += delta
		var s: float = 1.0 + fx["t"] * 12.0
		fx["node"].scale = Vector3(s, s, s)
		if fx["t"] > 0.5:
			fx["node"].queue_free()
			_burst_effects.erase(fx)
	_hud.update_cooldowns(_attack_cooldown, _player.dash_cooldown, _burst_cooldown)


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
	enemy.speed = 2.0 + float(wave) * 0.2 + randf() * 0.5
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
	_attack_cooldown = 0.45
	_player.try_attack()
	var target: CharacterBody3D = _nearest_enemy(ATTACK_RANGE)
	if target != null:
		target.take_damage(ATTACK_DAMAGE)
		var away: Vector3 = target.global_position - _player.global_position
		away.y = 0.0
		if away.length() > 0.01:
			target.global_position += away.normalized() * 0.8


func _on_dash() -> void:
	if game_over:
		return
	_player.try_dash()


func _on_burst() -> void:
	if game_over or _burst_cooldown > 0.0:
		return
	_burst_cooldown = 8.0
	for child in _enemies_node.get_children():
		if child is CharacterBody3D:
			if child.global_position.distance_to(_player.global_position) <= BURST_RANGE:
				child.take_damage(BURST_DAMAGE)
	var ring := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.6
	mesh.height = 1.2
	ring.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.55, 0.1, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.45, 0.05)
	mat.emission_energy_multiplier = 2.0
	ring.material_override = mat
	ring.position = _player.global_position + Vector3(0, 1.0, 0)
	_world.add_child(ring)
	_burst_effects.append({"node": ring, "t": 0.0})


func damage_player(amount: float) -> void:
	if game_over:
		return
	health -= amount
	_hud.update_health(health, max_health)
	if health <= 0.0:
		health = 0.0
		_game_over()


func on_enemy_killed(_enemy: CharacterBody3D) -> void:
	score += 20
	_hud.update_score(score, wave, maxi(0, _enemies_node.get_child_count() - 1))


func _game_over() -> void:
	game_over = true
	_hud.show_game_over(score)


func _on_restart() -> void:
	get_tree().reload_current_scene()


func _on_toggle_ascii() -> void:
	ascii_enabled = not ascii_enabled
	var mat: ShaderMaterial = _ascii_overlay.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("ascii_enabled", ascii_enabled)
	_hud.set_ascii_button(ascii_enabled)
