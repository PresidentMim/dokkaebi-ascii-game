extends CharacterBody3D
## Enemy: a dark spirit. Walks toward the player and hurts on touch.
## Visuals are built here from Godot primitives - no external assets.

var speed: float = 2.2
var health: float = 30.0
var damage: float = 10.0
var attack_cooldown: float = 0.0
var player_ref: Node3D = null
var game_ref: Node = null
var _bob: float = 0.0
var _body: MeshInstance3D = null


func _mat(color: Color, emission: Color = Color(0, 0, 0), energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m


func _ready() -> void:
	_body = MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.55
	body_mesh.height = 1.1
	_body.mesh = body_mesh
	_body.material_override = _mat(Color(0.14, 0.05, 0.24))
	_body.position = Vector3(0, 0.75, 0)
	_body.scale = Vector3(1.0, 1.25, 1.0)
	add_child(_body)
	# Horns.
	for sx in [-0.3, 0.3]:
		var horn := MeshInstance3D.new()
		var horn_mesh := CylinderMesh.new()
		horn_mesh.top_radius = 0.0
		horn_mesh.bottom_radius = 0.12
		horn_mesh.height = 0.45
		horn.mesh = horn_mesh
		horn.material_override = _mat(Color(0.1, 0.04, 0.18))
		horn.position = Vector3(sx, 1.45, 0)
		horn.rotation.z = -0.35 * sign(sx)
		add_child(horn)
	# Glowing red eyes (front is local -Z).
	for sx in [-0.2, 0.2]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.09
		eye_mesh.height = 0.18
		eye.mesh = eye_mesh
		eye.material_override = _mat(Color(1.0, 0.1, 0.1), Color(1.0, 0.05, 0.05), 2.5)
		eye.position = Vector3(sx, 0.95, -0.45)
		add_child(eye)


func _physics_process(delta: float) -> void:
	if game_ref != null and game_ref.game_over:
		velocity = Vector3.ZERO
		return
	if player_ref == null:
		return
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	var to_player: Vector3 = player_ref.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	var dir: Vector3 = Vector3.ZERO
	if dist > 0.01:
		dir = to_player / dist
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y -= 20.0 * delta
	move_and_slide()
	if global_position.y < 0.0:
		global_position.y = 0.0
	if dir.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * 8.0)
	# Hovering bob.
	_bob += delta * 3.0
	if _body != null:
		_body.position.y = 0.75 + sin(_bob) * 0.08
	# Touch damage.
	if dist < 1.4 and attack_cooldown <= 0.0:
		attack_cooldown = 1.0
		global_position -= dir * 1.2
		if game_ref != null:
			game_ref.damage_player(damage)


func take_damage(amount: float) -> void:
	health -= amount
	if _body != null:
		_body.scale = Vector3(1.15, 1.4, 1.15)
	if health <= 0.0:
		die()


func die() -> void:
	if game_ref != null:
		game_ref.on_enemy_killed(self)
	queue_free()
