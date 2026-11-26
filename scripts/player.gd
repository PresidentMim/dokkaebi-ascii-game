extends CharacterBody3D
## Player: small dokkaebi-like character (traditional Korean hat).
## Movement comes from the virtual joystick (game.gd copies
## joystick.output into joystick_vector) or WASD / arrow keys.
## Visuals are built here from Godot primitives - no external assets.

@export var speed: float = 6.0
@export var dash_speed: float = 14.0

var joystick_vector: Vector2 = Vector2.ZERO
var game_ref: Node = null

var dash_timer: float = 0.0
var dash_cooldown: float = 0.0
var attack_timer: float = 0.0
var _staff_pivot: Node3D = null


func _mat(color: Color, emission: Color = Color(0, 0, 0), energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m


func _ready() -> void:
	# Body (capsule).
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.45
	body_mesh.height = 1.2
	body.mesh = body_mesh
	body.material_override = _mat(Color(0.88, 0.86, 0.78))
	body.position = Vector3(0, 0.95, 0)
	add_child(body)
	# Head.
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.38
	head_mesh.height = 0.76
	head.mesh = head_mesh
	head.material_override = _mat(Color(0.92, 0.9, 0.82))
	head.position = Vector3(0, 1.78, 0)
	add_child(head)
	# Traditional hat: wide flat brim + tall top (gat).
	var brim := MeshInstance3D.new()
	var brim_mesh := CylinderMesh.new()
	brim_mesh.top_radius = 0.85
	brim_mesh.bottom_radius = 0.85
	brim_mesh.height = 0.06
	brim.mesh = brim_mesh
	brim.material_override = _mat(Color(0.14, 0.14, 0.16))
	brim.position = Vector3(0, 2.08, 0)
	add_child(brim)
	var hat_top := MeshInstance3D.new()
	var hat_mesh := CylinderMesh.new()
	hat_mesh.top_radius = 0.32
	hat_mesh.bottom_radius = 0.48
	hat_mesh.height = 0.38
	hat_top.mesh = hat_mesh
	hat_top.material_override = _mat(Color(0.18, 0.18, 0.2))
	hat_top.position = Vector3(0, 2.28, 0)
	add_child(hat_top)
	# Eyes (front is local -Z).
	for sx in [-0.14, 0.14]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.06
		eye_mesh.height = 0.12
		eye.mesh = eye_mesh
		eye.material_override = _mat(Color(0.02, 0.02, 0.02))
		eye.position = Vector3(sx, 1.82, -0.33)
		add_child(eye)
	# Red sash.
	var sash := MeshInstance3D.new()
	var sash_mesh := BoxMesh.new()
	sash_mesh.size = Vector3(0.95, 0.14, 0.95)
	sash.mesh = sash_mesh
	sash.material_override = _mat(Color(0.7, 0.15, 0.15))
	sash.position = Vector3(0, 1.05, 0)
	add_child(sash)
	# Staff on a pivot, so an attack can swing it.
	_staff_pivot = Node3D.new()
	_staff_pivot.position = Vector3(0.6, 1.1, 0)
	add_child(_staff_pivot)
	var staff := MeshInstance3D.new()
	var staff_mesh := CylinderMesh.new()
	staff_mesh.top_radius = 0.05
	staff_mesh.bottom_radius = 0.05
	staff_mesh.height = 1.6
	staff.mesh = staff_mesh
	staff.material_override = _mat(Color(0.45, 0.3, 0.15))
	staff.position = Vector3(0, 0.2, 0)
	_staff_pivot.add_child(staff)
	var staff_tip := MeshInstance3D.new()
	var tip_mesh := SphereMesh.new()
	tip_mesh.radius = 0.12
	tip_mesh.height = 0.24
	staff_tip.mesh = tip_mesh
	staff_tip.material_override = _mat(Color(1.0, 0.55, 0.1), Color(1.0, 0.45, 0.05), 2.0)
	staff_tip.position = Vector3(0, 1.0, 0)
	_staff_pivot.add_child(staff_tip)


func _physics_process(delta: float) -> void:
	if game_ref != null and game_ref.game_over:
		velocity = Vector3.ZERO
		return
	var input_vec: Vector2 = joystick_vector
	if input_vec == Vector2.ZERO:
		input_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := Vector3(input_vec.x, 0.0, input_vec.y)
	if dir.length() > 1.0:
		dir = dir.normalized()
	if dash_cooldown > 0.0:
		dash_cooldown -= delta
	if dash_timer > 0.0:
		dash_timer -= delta
	if attack_timer > 0.0:
		attack_timer -= delta
	var cur_speed: float = dash_speed if dash_timer > 0.0 else speed
	velocity.x = dir.x * cur_speed
	velocity.z = dir.z * cur_speed
	velocity.y -= 20.0 * delta
	move_and_slide()
	# Stay inside the fenced field.
	global_position.x = clamp(global_position.x, -23.0, 23.0)
	global_position.z = clamp(global_position.z, -23.0, 23.0)
	if global_position.y < 0.0:
		global_position.y = 0.0
	if dir.length() > 0.1:
		var target_yaw: float = atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 10.0)
	# Staff swing animation while attacking.
	if _staff_pivot != null:
		if attack_timer > 0.0:
			_staff_pivot.rotation.x = -1.2 * (attack_timer / 0.3)
		else:
			_staff_pivot.rotation.x = 0.0


func try_dash() -> bool:
	if dash_cooldown > 0.0:
		return false
	dash_timer = 0.25
	dash_cooldown = 3.0
	return true


func try_attack() -> void:
	attack_timer = 0.3
