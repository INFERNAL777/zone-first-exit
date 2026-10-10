extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const HUDScript = preload("res://scripts/hud.gd")

var player
var hud
var enemies_left := 3
var game_over := false
var status_label: Label

func _ready() -> void:
    _make_environment()
    _make_level()
    _make_player()
    _make_enemies()
    _make_hud()

func _make_environment() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.12, 0.17, 0.18)
    sky_mat.sky_horizon_color = Color(0.42, 0.43, 0.38)
    sky_mat.ground_bottom_color = Color(0.08, 0.09, 0.08)
    sky_mat.ground_horizon_color = Color(0.32, 0.31, 0.26)
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.55, 0.57, 0.52)
    env.ambient_light_energy = 0.7
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = env
    add_child(world)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 0.85
    sun.shadow_enabled = true
    add_child(sun)

func _make_level() -> void:
    _box("Ground", Vector3(0, -0.5, 0), Vector3(34, 1, 34), Color(0.26, 0.27, 0.23))
    _box("NorthWall", Vector3(0, 1.5, -17), Vector3(34, 3, 0.6), Color(0.30, 0.31, 0.28))
    _box("SouthWall", Vector3(0, 1.5, 17), Vector3(34, 3, 0.6), Color(0.30, 0.31, 0.28))
    _box("WestWall", Vector3(-17, 1.5, 0), Vector3(0.6, 3, 34), Color(0.30, 0.31, 0.28))
    _box("EastWall", Vector3(17, 1.5, 0), Vector3(0.6, 3, 34), Color(0.30, 0.31, 0.28))
    _box("ContainerA", Vector3(-7, 1.1, -5), Vector3(5, 2.2, 3), Color(0.30, 0.34, 0.29))
    _box("ContainerB", Vector3(7, 1.1, 4), Vector3(4.5, 2.2, 3), Color(0.37, 0.28, 0.22))
    _box("ConcreteCoverA", Vector3(1, 0.65, -3), Vector3(3.5, 1.3, 1.0), Color(0.43, 0.43, 0.38))
    _box("ConcreteCoverB", Vector3(-3, 0.65, 7), Vector3(3.5, 1.3, 1.0), Color(0.43, 0.43, 0.38))
    _box("ConcreteCoverC", Vector3(10, 0.65, -7), Vector3(2.5, 1.3, 1.0), Color(0.43, 0.43, 0.38))
    _box("ShedBack", Vector3(10, 2.1, -12), Vector3(9, 4.2, 0.5), Color(0.25, 0.28, 0.27))
    _box("ShedSide", Vector3(14.2, 2.1, -9.2), Vector3(0.5, 4.2, 6), Color(0.25, 0.28, 0.27))
    for i in range(7):
        var x := -11.0 + float(i) * 3.4
        _box("Debris%d" % i, Vector3(x, 0.18, 11.5), Vector3(1.0, 0.36, 0.7), Color(0.31, 0.29, 0.24))

func _box(node_name: String, pos: Vector3, size: Vector3, tint: Color) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = pos
    var mesh := MeshInstance3D.new()
    var box_mesh := BoxMesh.new()
    box_mesh.size = size
    mesh.mesh = box_mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.roughness = 0.95
    mesh.material_override = mat
    body.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    add_child(body)
    return body

func _make_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.set_script(PlayerScript)
    player.position = Vector3(0, 1.2, 12)
    add_child(player)

func _make_enemies() -> void:
    var positions := [Vector3(-9, 1, -1), Vector3(5, 1, -9), Vector3(10, 1, 7)]
    for i in range(positions.size()):
        var enemy := CharacterBody3D.new()
        enemy.name = "Enemy_%d" % (i + 1)
        enemy.set_script(EnemyScript)
        enemy.position = positions[i]
        enemy.set_meta("enemy_id", i + 1)
        add_child(enemy)
        enemy.defeated.connect(_on_enemy_defeated)

func _make_hud() -> void:
    hud = CanvasLayer.new()
    hud.name = "HUD"
    add_child(hud)
    var control := Control.new()
    control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    control.mouse_filter = Control.MOUSE_FILTER_PASS
    control.set_script(HUDScript)
    hud.add_child(control)
    control.fire_pressed.connect(_on_fire_pressed)
    control.reload_pressed.connect(_on_reload_pressed)
    control.look_delta.connect(_on_look_delta)
    control.move_vector.connect(_on_move_vector)
    control.pause_pressed.connect(_on_pause_pressed)
    status_label = Label.new()
    status_label.position = Vector2(18, 18)
    status_label.add_theme_font_size_override("font_size", 24)
    status_label.add_theme_color_override("font_color", Color(0.93, 0.93, 0.84))
    hud.add_child(status_label)
    _update_hud()

func _process(_delta: float) -> void:
    if not game_over:
        _update_hud()

func _update_hud() -> void:
    if is_instance_valid(status_label) and is_instance_valid(player):
        status_label.text = "ЗДОРОВЬЕ %d   ПАТРОНЫ %d/%d   ЦЕЛИ %d" % [player.health, player.ammo, player.reserve_ammo, enemies_left]

func _on_fire_pressed() -> void:
    if not game_over and is_instance_valid(player):
        player.shoot()

func _on_reload_pressed() -> void:
    if not game_over and is_instance_valid(player):
        player.reload_weapon()

func _on_look_delta(delta: Vector2) -> void:
    if is_instance_valid(player):
        player.apply_look(delta)

func _on_move_vector(value: Vector2) -> void:
    if is_instance_valid(player):
        player.mobile_move = value

func _on_pause_pressed() -> void:
    get_tree().paused = not get_tree().paused

func _on_enemy_defeated() -> void:
    enemies_left -= 1
    if enemies_left <= 0:
        game_over = true
        status_label.text = "ЗАДАНИЕ ВЫПОЛНЕНО! Все цели устранены."
        hud.get_child(0).show_end_message("ЗАДАНИЕ ВЫПОЛНЕНО")

func player_died() -> void:
    game_over = true
    status_label.text = "ВЫ ПОГИБЛИ — перезапустите игру."
    hud.get_child(0).show_end_message("ВЫ ПОГИБЛИ")
