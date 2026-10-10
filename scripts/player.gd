extends CharacterBody3D

var health := 100
var ammo := 12
var reserve_ammo := 48
var mobile_move := Vector2.ZERO
var mouse_sensitivity := 0.0025
var gravity := 18.0
var fire_cooldown := 0.0
var reload_timer := 0.0

var camera: Camera3D
var pitch_pivot: Node3D
var ray: RayCast3D
var ammo_label: Label

func _ready() -> void:
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.38
    capsule.height = 1.8
    collider.shape = capsule
    add_child(collider)

    pitch_pivot = Node3D.new()
    pitch_pivot.position = Vector3(0, 0.58, 0)
    add_child(pitch_pivot)

    camera = Camera3D.new()
    camera.current = true
    camera.fov = 78
    pitch_pivot.add_child(camera)

    ray = RayCast3D.new()
    ray.target_position = Vector3(0, 0, -80)
    ray.enabled = true
    camera.add_child(ray)

    var gun := MeshInstance3D.new()
    var gun_mesh := BoxMesh.new()
    gun_mesh.size = Vector3(0.18, 0.16, 0.52)
    gun.mesh = gun_mesh
    gun.position = Vector3(0.32, -0.28, -0.55)
    var gun_mat := StandardMaterial3D.new()
    gun_mat.albedo_color = Color(0.10, 0.12, 0.12)
    gun.material_override = gun_mat
    camera.add_child(gun)

    var grip := MeshInstance3D.new()
    var grip_mesh := BoxMesh.new()
    grip_mesh.size = Vector3(0.12, 0.22, 0.15)
    grip.mesh = grip_mesh
    grip.position = Vector3(0.32, -0.42, -0.39)
    grip.material_override = gun_mat
    camera.add_child(grip)

    if not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    fire_cooldown = maxf(0.0, fire_cooldown - delta)
    reload_timer = maxf(0.0, reload_timer - delta)
    var input_dir := Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
    )
    if mobile_move.length() > 0.1:
        input_dir = mobile_move
    input_dir = input_dir.limit_length(1.0)
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    var speed := 5.0
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.1
    move_and_slide()

    if Input.is_action_just_pressed("shoot"):
        shoot()
    if Input.is_action_just_pressed("reload"):
        reload_weapon()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        apply_look(event.relative)
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func apply_look(delta: Vector2) -> void:
    rotate_y(-delta.x * mouse_sensitivity)
    pitch_pivot.rotate_x(-delta.y * mouse_sensitivity)
    pitch_pivot.rotation.x = clampf(pitch_pivot.rotation.x, deg_to_rad(-78), deg_to_rad(78))

func shoot() -> void:
    if fire_cooldown > 0.0 or reload_timer > 0.0:
        return
    if ammo <= 0:
        reload_weapon()
        return
    ammo -= 1
    fire_cooldown = 0.24
    ray.force_raycast_update()
    if ray.is_colliding():
        var target = ray.get_collider()
        if target and target.has_method("take_damage"):
            target.take_damage(34)

func reload_weapon() -> void:
    if reload_timer > 0.0 or ammo >= 12 or reserve_ammo <= 0:
        return
    reload_timer = 1.15
    await get_tree().create_timer(1.15).timeout
    var needed := 12 - ammo
    var amount := mini(needed, reserve_ammo)
    ammo += amount
    reserve_ammo -= amount

func take_damage(amount: int) -> void:
    health = maxi(0, health - amount)
    if health <= 0:
        var main = get_parent()
        if main.has_method("player_died"):
            main.player_died()
        queue_free()
