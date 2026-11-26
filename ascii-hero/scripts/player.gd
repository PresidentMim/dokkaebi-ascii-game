extends CharacterBody3D
## Player: ASCII superhero RIDING A WHITE HORSE.
## The horse is part of the hero - the rider sits on horseback and
## moves by galloping (animated legs, faster than walking), like the
## "Hair Physics Test" ASCII MMORPG reference video.
## Movement comes from the virtual joystick (game.gd copies
## joystick.output into joystick_vector) or WASD / arrow keys.
## Visuals are built here from Godot primitives - no external assets.
## The horse is WHITE / light-coloured on purpose: against the dark
## green grass it reads as a bright shape in the ASCII shader, while
## the rider keeps the blue suit, red cape and yellow lightning emblem.
## Colours are BRIGHT on purpose: the ASCII shader maps brightness
## to characters, so a dark hero would collapse to " " / ".".
## (Dokkaebi v1 lesson: 94% of cells fell in the blank/dot indices
## because the scene was too dark.)

@export var speed: float = 8.5

var joystick_vector: Vector2 = Vector2.ZERO
var game_ref: Node = null

var attack_timer: float = 0.0
var _horse_root: Node3D = null
var _leg_pivots: Array = []
var _tail: MeshInstance3D = null
var _cape: MeshInstance3D = null
var _sword_pivot: Node3D = null
var _gallop_phase: float = 0.0
var _anim_time: float = 0.0


func _mat(color: Color, emission: Color = Color(0, 0, 0), energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m


func _white() -> StandardMaterial3D:
	return _mat(Color(0.96, 0.96, 0.97), Color(0.7, 0.7, 0.72), 0.25)


func _ready() -> void:
	_horse_root = Node3D.new()
	add_child(_horse_root)
	_build_horse()
	_build_rider()


func _build_horse() -> void:
	var white := _white()
	var dark := _mat(Color(0.12, 0.1, 0.1))
	# Body: horizontal capsule (axis along Z, the forward direction).
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.42
	body_mesh.height = 1.5
	body.mesh = body_mesh
	body.material_override = white
	body.position = Vector3(0, 1.05, 0)
	body.rotation.x = PI * 0.5
	_horse_root.add_child(body)
	# Chest + rump spheres so the body reads as a full horse shape.
	for z in [-0.72, 0.72]:
		var round := MeshInstance3D.new()
		var rm := SphereMesh.new()
		rm.radius = 0.42
		rm.height = 0.84
		round.mesh = rm
		round.material_override = white
		round.position = Vector3(0, 1.05, z)
		_horse_root.add_child(round)
	# Neck, angled up-forward.
	var neck := MeshInstance3D.new()
	var neck_mesh := BoxMesh.new()
	neck_mesh.size = Vector3(0.34, 0.95, 0.42)
	neck.mesh = neck_mesh
	neck.material_override = white
	neck.position = Vector3(0, 1.55, -0.95)
	neck.rotation.x = -0.5
	_horse_root.add_child(neck)
	# Head.
	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.3, 0.36, 0.72)
	head.mesh = head_mesh
	head.material_override = white
	head.position = Vector3(0, 1.95, -1.28)
	head.rotation.x = -0.25
	_horse_root.add_child(head)
	# Muzzle (grey) at the front of the head.
	var muzzle := MeshInstance3D.new()
	var muzzle_mesh := BoxMesh.new()
	muzzle_mesh.size = Vector3(0.24, 0.24, 0.22)
	muzzle.mesh = muzzle_mesh
	muzzle.material_override = _mat(Color(0.6, 0.6, 0.62))
	muzzle.position = Vector3(0, 1.86, -1.62)
	_horse_root.add_child(muzzle)
	# Ears: two small cones.
	for sx in [-0.11, 0.11]:
		var ear := MeshInstance3D.new()
		var ear_mesh := CylinderMesh.new()
		ear_mesh.top_radius = 0.0
		ear_mesh.bottom_radius = 0.08
		ear_mesh.height = 0.26
		ear.mesh = ear_mesh
		ear.material_override = white
		ear.position = Vector3(sx, 2.22, -1.12)
		_horse_root.add_child(ear)
	# Eyes: dark, on the sides of the head.
	for sx in [-0.16, 0.16]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.06
		eye_mesh.height = 0.12
		eye.mesh = eye_mesh
		eye.material_override = _mat(Color(0.02, 0.02, 0.02))
		eye.position = Vector3(sx, 2.0, -1.45)
		_horse_root.add_child(eye)
	# Mane: dark boxes along the top of the neck.
	for m in [[1.98, -0.82], [1.82, -0.62], [1.66, -0.42]]:
		var mane := MeshInstance3D.new()
		var mane_mesh := BoxMesh.new()
		mane_mesh.size = Vector3(0.12, 0.28, 0.3)
		mane.mesh = mane_mesh
		mane.material_override = dark
		mane.position = Vector3(0, m[0], m[1])
		mane.rotation.x = -0.5
		_horse_root.add_child(mane)
	# Tail: dark, hangs at the rear and sways.
	_tail = MeshInstance3D.new()
	var tail_mesh := BoxMesh.new()
	tail_mesh.size = Vector3(0.14, 0.85, 0.14)
	_tail.mesh = tail_mesh
	_tail.material_override = dark
	_tail.position = Vector3(0, 0.85, 1.2)
	_tail.rotation.x = 0.25
	_horse_root.add_child(_tail)
	# Saddle + red blanket under the rider.
	var blanket := MeshInstance3D.new()
	var blanket_mesh := BoxMesh.new()
	blanket_mesh.size = Vector3(0.85, 0.08, 1.0)
	blanket.mesh = blanket_mesh
	blanket.material_override = _mat(Color(0.85, 0.1, 0.1))
	blanket.position = Vector3(0, 1.44, 0.1)
	_horse_root.add_child(blanket)
	var saddle := MeshInstance3D.new()
	var saddle_mesh := BoxMesh.new()
	saddle_mesh.size = Vector3(0.62, 0.14, 0.7)
	saddle.mesh = saddle_mesh
	saddle.material_override = _mat(Color(0.35, 0.2, 0.1))
	saddle.position = Vector3(0, 1.52, 0.1)
	_horse_root.add_child(saddle)
	# Legs: 4 pivots at the body corners. Each leg hangs down from
	# its pivot so a gallop swing (rotation.x) reads clearly.
	# Order: front-left, front-right, back-left, back-right.
	# Diagonal pairs swing together (FL+BR, FR+BL).
	for lx in [-0.25, 0.25]:
		for lz in [-0.55, 0.55]:
			var pivot := Node3D.new()
			pivot.position = Vector3(lx, 0.85, lz)
			_horse_root.add_child(pivot)
			var leg := MeshInstance3D.new()
			var leg_mesh := CylinderMesh.new()
			leg_mesh.top_radius = 0.09
			leg_mesh.bottom_radius = 0.07
			leg_mesh.height = 0.85
			leg.mesh = leg_mesh
			leg.material_override = white
			leg.position = Vector3(0, -0.42, 0)
			pivot.add_child(leg)
			var hoof := MeshInstance3D.new()
			var hoof_mesh := BoxMesh.new()
			hoof_mesh.size = Vector3(0.16, 0.1, 0.2)
			hoof.mesh = hoof_mesh
			hoof.material_override = dark
			hoof.position = Vector3(0, -0.86, 0)
			pivot.add_child(hoof)
			_leg_pivots.append(pivot)


func _build_rider() -> void:
	# Torso: blue suit, sitting on the saddle.
	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.32
	torso_mesh.height = 0.75
	torso.mesh = torso_mesh
	torso.material_override = _mat(Color(0.15, 0.35, 0.95))
	torso.position = Vector3(0, 2.0, 0.1)
	_horse_root.add_child(torso)
	# Yellow belt.
	var belt := MeshInstance3D.new()
	var belt_mesh := BoxMesh.new()
	belt_mesh.size = Vector3(0.68, 0.1, 0.68)
	belt.mesh = belt_mesh
	belt.material_override = _mat(Color(0.95, 0.8, 0.1), Color(0.9, 0.7, 0.05), 0.8)
	belt.position = Vector3(0, 1.95, 0.1)
	_horse_root.add_child(belt)
	# Lightning emblem on the chest (front is local -Z).
	var emblem := MeshInstance3D.new()
	var emblem_mesh := BoxMesh.new()
	emblem_mesh.size = Vector3(0.16, 0.3, 0.06)
	emblem.mesh = emblem_mesh
	emblem.material_override = _mat(Color(1.0, 0.85, 0.1), Color(1.0, 0.8, 0.05), 2.0)
	emblem.position = Vector3(0, 2.15, -0.24)
	emblem.rotation.z = 0.5
	_horse_root.add_child(emblem)
	# Head: blue mask.
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.28
	head_mesh.height = 0.56
	head.mesh = head_mesh
	head.material_override = _mat(Color(0.15, 0.35, 0.95))
	head.position = Vector3(0, 2.5, 0.1)
	_horse_root.add_child(head)
	# White eyes on the mask.
	for sx in [-0.1, 0.1]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.06
		eye_mesh.height = 0.12
		eye.mesh = eye_mesh
		eye.material_override = _mat(Color(1, 1, 1), Color(1, 1, 1), 1.5)
		eye.position = Vector3(sx, 2.53, -0.14)
		_horse_root.add_child(eye)
	# Red cape: flows back behind the rider, waves as he rides.
	_cape = MeshInstance3D.new()
	var cape_mesh := BoxMesh.new()
	cape_mesh.size = Vector3(0.7, 1.1, 0.05)
	_cape.mesh = cape_mesh
	_cape.material_override = _mat(Color(0.88, 0.08, 0.08), Color(0.7, 0.05, 0.05), 0.6)
	_cape.position = Vector3(0, 2.0, 0.48)
	_cape.rotation.x = 0.35
	_horse_root.add_child(_cape)
	# Rider legs straddling the horse.
	for sx in [-0.36, 0.36]:
		var rleg := MeshInstance3D.new()
		var rleg_mesh := BoxMesh.new()
		rleg_mesh.size = Vector3(0.18, 0.5, 0.2)
		rleg.mesh = rleg_mesh
		rleg.material_override = _mat(Color(0.15, 0.35, 0.95))
		rleg.position = Vector3(sx, 1.62, 0.1)
		rleg.rotation.z = -0.25 * sign(sx)
		_horse_root.add_child(rleg)
	# Left arm reaching forward to the reins.
	var arm := MeshInstance3D.new()
	var arm_mesh := CylinderMesh.new()
	arm_mesh.top_radius = 0.07
	arm_mesh.bottom_radius = 0.07
	arm_mesh.height = 0.55
	arm.mesh = arm_mesh
	arm.material_override = _mat(Color(0.15, 0.35, 0.95))
	arm.position = Vector3(-0.38, 2.15, -0.3)
	arm.rotation.x = -1.0
	_horse_root.add_child(arm)
	# Sword on a pivot at the rider's right hand, so an attack can
	# swing it from horseback.
	_sword_pivot = Node3D.new()
	_sword_pivot.position = Vector3(0.45, 2.1, -0.05)
	_horse_root.add_child(_sword_pivot)
	var blade := MeshInstance3D.new()
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.08, 1.35, 0.03)
	blade.mesh = blade_mesh
	blade.material_override = _mat(Color(0.92, 0.92, 0.98), Color(0.85, 0.85, 0.95), 0.9)
	blade.position = Vector3(0, 0.95, 0)
	_sword_pivot.add_child(blade)
	var guard := MeshInstance3D.new()
	var guard_mesh := BoxMesh.new()
	guard_mesh.size = Vector3(0.34, 0.07, 0.08)
	guard.mesh = guard_mesh
	guard.material_override = _mat(Color(0.95, 0.8, 0.1), Color(0.9, 0.7, 0.05), 0.8)
	guard.position = Vector3(0, 0.28, 0)
	_sword_pivot.add_child(guard)
	var hilt := MeshInstance3D.new()
	var hilt_mesh := CylinderMesh.new()
	hilt_mesh.top_radius = 0.05
	hilt_mesh.bottom_radius = 0.05
	hilt_mesh.height = 0.28
	hilt.mesh = hilt_mesh
	hilt.material_override = _mat(Color(0.3, 0.2, 0.1))
	hilt.position = Vector3(0, 0.12, 0)
	_sword_pivot.add_child(hilt)


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
	if attack_timer > 0.0:
		attack_timer -= delta
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
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
	# Gallop animation: legs swing in diagonal pairs, the whole
	# horse bobs, tail and cape flow. Faster when actually moving.
	_anim_time += delta
	var moving: float = clampf(Vector2(velocity.x, velocity.z).length() / speed, 0.0, 1.0)
	_gallop_phase += delta * (4.0 + 10.0 * moving)
	var swing: float = 0.55 * moving
	# Leg order in _leg_pivots: FL, BL, FR, BR. Diagonal pairs
	# (FL+BR, FR+BL) swing in phase.
	var phases: Array = [0.0, PI, PI, 0.0]
	for i in range(_leg_pivots.size()):
		var pivot: Node3D = _leg_pivots[i]
		var target: float = sin(_gallop_phase + phases[i]) * swing
		pivot.rotation.x = lerpf(pivot.rotation.x, target, delta * 18.0)
	if _horse_root != null:
		_horse_root.position.y = absf(sin(_gallop_phase)) * 0.09 * moving
	if _tail != null:
		_tail.rotation.z = sin(_anim_time * 2.2) * 0.18
		_tail.rotation.x = 0.25 + sin(_anim_time * 3.1) * 0.08
	if _cape != null:
		_cape.rotation.x = 0.35 + sin(_anim_time * 3.0) * 0.08 + moving * 0.25
	# Sword swing animation while attacking: the blade sweeps
	# forward-down across the front of the rider.
	if _sword_pivot != null:
		if attack_timer > 0.0:
			var f: float = attack_timer / 0.3
			_sword_pivot.rotation.x = -2.2 * f
			_sword_pivot.rotation.y = 1.2 * (1.0 - f)
		else:
			_sword_pivot.rotation.x = 0.0
			_sword_pivot.rotation.y = 0.0


func try_attack() -> void:
	attack_timer = 0.3
