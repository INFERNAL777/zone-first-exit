extends CharacterBody3D

signal defeated

var health := 100
var speed := 1.7
var attack_timer := 0.0
var player_ref: Node3D
var body_mesh: MeshInstance3D
var hit_flash := 0.0

func _ready() -> void:
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.38
    capsule.height = 1.8
    var collider := CollisionShape3D.new()
    collider.shape = capsule
    add_child(collider)

    body_mesh = MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = 0.38
    mesh.height = 1.8
    body_mesh.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.42, 0.24, 0.16)
    mat.roughness = 0.9
    body_mesh.material_override = mat
    add_child(body_mesh)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.22
    head_mesh.height = 0.44
    head.mesh = head_mesh
    head.position.y = 1.0
    var head_mat := StandardMaterial3D.new()
    head_mat.albedo_color = Color(0.56, 0.42, 0.32)
    head.material_override = head_mat
    add_child(head)

    player_ref = get_parent().get_node_or_null("Player")

func _physics_process(delta: float) -> void:
    attack_timer = maxf(0.0, attack_timer - delta)
    hit_flash = maxf(0.0, hit_flash - delta)
    if not is_instance_valid(player_ref):
        return

    var offset: Vector3 = player_ref.global_position - global_position
    var distance := offset.length()
    if distance < 13.0 and distance > 1.5:
        var dir := offset.normalized()
        velocity.x = dir.x * speed
        velocity.z = dir.z * speed
        look_at(Vector3(player_ref.global_position.x, global_position.y, player_ref.global_position.z))
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * delta)

    if not is_on_floor():
        velocity.y -= 18.0 * delta
    else:
        velocity.y = -0.1
    move_and_slide()

    if distance < 2.1 and attack_timer <= 0.0:
        attack_timer = 1.2
        if player_ref.has_method("take_damage"):
            player_ref.take_damage(8)

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        defeated.emit()
        queue_free()
