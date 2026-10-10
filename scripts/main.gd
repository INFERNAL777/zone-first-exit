extends Node2D

# Pixel-art, angled top-down exploration prototype. No dice rolls.
const TILE := 32.0
const BG := Color("#111613")
const DIRT := Color("#393a2d")
const DIRT2 := Color("#303329")
const STONE := Color("#55564a")
const STONE_DARK := Color("#30332e")
const TEXT := Color("#ded5bd")
const GOLD := Color("#e1c24c")
const RED := Color("#74372f")
const GREEN := Color("#81935b")

var player_pos := Vector2(0, 0)
var player_facing := Vector2(0, 1)
var move_input := Vector2.ZERO
var joy_origin := Vector2(62, 522)
var joy_touch := -1
var interact_touch := -1
var touch_start := Vector2.ZERO
var world_mode := "well"
var story := "Ты приходишь в себя на камнях. Под ногами хрустят чужие кости. Сверху тянет холодом."
var hunger_hours := 0.0
var hunger_level := 0
var aura_on := false
var has_climbed := false
var has_seen_tracks := false
var has_checked_house := false
var meat_found := false
var meat_eaten := false
var health := 100
var time_minutes := 0
var action_hint := "Найди выход из колодца"
var ui_font: Font
var last_action := ""
var move_speed := 88.0
var player_radius := 9.0
var map_obstacles: Array[Rect2] = []
var joystick_active := false
var pressed_buttons := {}
var screen_size := Vector2(360, 640)

func _ready() -> void:
	get_viewport().size_changed.connect(_on_resize)
	ui_font = ThemeDB.fallback_font
	_build_obstacles()
	queue_redraw()

func _on_resize() -> void:
	screen_size = get_viewport_rect().size
	queue_redraw()

func _build_obstacles() -> void:
	map_obstacles.clear()
	# Village is a compact exploration map with walls and trees.
	map_obstacles.append(Rect2(-170, -180, 95, 72))
	map_obstacles.append(Rect2(82, -115, 102, 78))
	map_obstacles.append(Rect2(-190, 72, 72, 108))
	map_obstacles.append(Rect2(112, 105, 88, 92))
	map_obstacles.append(Rect2(-45, -18, 46, 36))

func _process(delta: float) -> void:
	if move_input.length() > 0.08:
		var v := move_input.normalized()
		player_facing = v
		var speed := move_speed
		if Input.is_key_pressed(KEY_SHIFT):
			speed *= 1.45
		var candidate := player_pos + v * speed * delta
		if _can_move(candidate):
			player_pos = candidate
			elif _can_move(Vector2(candidate.x, player_pos.y)):
				player_pos.x = candidate.x
			elif _can_move(Vector2(player_pos.x, candidate.y)):
				player_pos.y = candidate.y
		time_minutes += int(delta * 0.4)
		if time_minutes >= 1440:
			time_minutes = 0
			hunger_hours += 24
		_update_hunger()
	queue_redraw()

func _can_move(p: Vector2) -> bool:
	if world_mode == "well":
		return p.x > -65 and p.x < 65 and p.y > -76 and p.y < 76
	if p.x < -235 or p.x > 235 or p.y < -235 or p.y > 235:
		return false
	for obstacle in map_obstacles:
		if obstacle.grow(-player_radius).has_point(p):
			return false
	return true

func _update_hunger() -> void:
	if hunger_hours >= 168:
		hunger_level = 4
	elif hunger_hours >= 120:
		hunger_level = 3
	elif hunger_hours >= 72:
		hunger_level = 2
	elif hunger_hours >= 24:
		hunger_level = 1

func _draw() -> void:
	screen_size = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen_size), BG)
	var scale_factor := min(screen_size.x / 360.0, screen_size.y / 640.0)
	var offset := Vector2((screen_size.x - 360.0 * scale_factor) * 0.5, (screen_size.y - 640.0 * scale_factor) * 0.5)
	draw_set_transform(offset, 0.0, Vector2(scale_factor, scale_factor))
	if world_mode == "well":
		_draw_well_world()
	else:
		_draw_village_world()
	_draw_player()
	_draw_hud()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _project(world: Vector2) -> Vector2:
	# Angled top-down projection: vertical map axis recedes into the distance.
	return Vector2(180.0 + (world.x - world.y) * 0.72 - player_pos.x * 0.72 + player_pos.y * 0.72,
				  306.0 + (world.x + world.y) * 0.34 - player_pos.x * 0.34 - player_pos.y * 0.34)

func _poly(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)

func _draw_well_world() -> void:
	# A stone-lined circular shaft seen from above at an angle.
	_poly(PackedVector2Array([Vector2(42,116),Vector2(318,116),Vector2(360,205),Vector2(360,405),Vector2(318,486),Vector2(42,486),Vector2(0,405),Vector2(0,205)]), Color("#222723"))
	_poly(PackedVector2Array([Vector2(67,141),Vector2(293,141),Vector2(333,215),Vector2(333,390),Vector2(293,460),Vector2(67,460),Vector2(27,390),Vector2(27,215)]), Color("#4b4d43"))
	_poly(PackedVector2Array([Vector2(85,157),Vector2(275,157),Vector2(308,222),Vector2(308,378),Vector2(275,441),Vector2(85,441),Vector2(52,378),Vector2(52,222)]), Color("#181d1a"))
	for row in range(8):
		var y := 170 + row * 33
		for col in range(6):
			var x := 59 + col * 42 + (row % 2) * 20
			if x < 300:
				draw_rect(Rect2(x, y, 29, 20), STONE_DARK if (row + col) % 3 == 0 else STONE)
				draw_rect(Rect2(x + 3, y + 3, 23, 2), Color("#666658"))
	# Ground at the bottom.
	_poly(PackedVector2Array([Vector2(55,290),Vector2(305,290),Vector2(327,350),Vector2(305,411),Vector2(55,411),Vector2(33,350)]), Color("#242822"))
	# Scattered bones and old cloth.
	draw_rect(Rect2(86,326,27,4), Color("#b2a88e"))
	draw_rect(Rect2(91,319,4,17), Color("#c2b79a"))
	draw_rect(Rect2(101,325,16,4), Color("#b2a88e"))
	draw_rect(Rect2(243,367,25,4), Color("#9f9479"))
	draw_rect(Rect2(253,359,4,17), Color("#b6a98b"))
	draw_rect(Rect2(105,374,34,7), RED)
	draw_rect(Rect2(116,368,8,17), Color("#3d2926"))
	# Rusted ladder/iron staples on the north wall.
	for i in range(5):
		draw_rect(Rect2(160,174 + i * 20,5,14), Color("#8b6543"))
		draw_rect(Rect2(191,174 + i * 20,5,14), Color("#8b6543"))
		draw_rect(Rect2(160,184 + i * 20,36,4), Color("#9a714a"))
	# Unsettling green glow appears only when aura vision is on.
	if aura_on:
		draw_rect(Rect2(211,306,24,34), Color("#3d5b3b"))
		draw_rect(Rect2(218,298,10,11), GREEN)
		draw_rect(Rect2(215,314,4,4), Color("#dce39b"))
		draw_rect(Rect2(227,314,4,4), Color("#dce39b"))
	# Edge of the shaft above the character.
	_poly(PackedVector2Array([Vector2(42,116),Vector2(318,116),Vector2(293,141),Vector2(67,141)]), Color("#68685a"))
	if not has_climbed:
		draw_rect(Rect2(167,118,28,5), Color("#9c8158"))

func _draw_village_world() -> void:
	# Dark, muddy village floor.
	draw_rect(Rect2(0,0,360,640), Color("#1b211c"))
	for y in range(-2, 18):
		for x in range(-2, 12):
			var p := _project(Vector2(x * 48.0, y * 48.0))
			if p.x > -45 and p.x < 405 and p.y > 65 and p.y < 530:
				var shade := DIRT if (x * 7 + y * 11) % 3 == 0 else DIRT2
				draw_rect(Rect2(p.x, p.y, 23, 9), shade)
	# Broken road.
	_poly(PackedVector2Array([_project(Vector2(-230,-30)),_project(Vector2(235,-30)),_project(Vector2(235,15)),_project(Vector2(-230,15))]), Color("#4a4535"))
	# Abandoned house, roof first, with a dark doorway.
	_draw_house(Vector2(-123,-128))
	_draw_house(Vector2(133,45))
	# Dead trees and undergrowth.
	for t in [Vector2(-195,-20),Vector2(195,-175),Vector2(-202,156),Vector2(188,176),Vector2(25,-205)]:
		_draw_tree(t)
	# Well exit/ladder behind player.
	_draw_well_marker(Vector2(0,0))
	# Tracks lead toward the hut.
	if has_seen_tracks:
		for i in range(6):
			var p := _project(Vector2(18 + i * 17, 28 + i * 14))
			draw_rect(Rect2(p.x,p.y,5,3), Color("#111510"))

func _draw_house(origin: Vector2) -> void:
	var p := _project(origin)
	# Shadow and walls in chunky pixel blocks.
	_poly(PackedVector2Array([p+Vector2(-49,6),p+Vector2(7,-18),p+Vector2(52,4),p+Vector2(-4,29)]), Color("#111511"))
	_poly(PackedVector2Array([p+Vector2(-43,-7),p+Vector2(0,-27),p+Vector2(41,-8),p+Vector2(-1,12)]), Color("#514638"))
	_poly(PackedVector2Array([p+Vector2(-43,-7),p+Vector2(-1,12),p+Vector2(-1,38),p+Vector2(-43,17)]), Color("#463c2e"))
	_poly(PackedVector2Array([p+Vector2(-1,12),p+Vector2(41,-8),p+Vector2(41,18),p+Vector2(-1,38)]), Color("#332e25"))
	draw_rect(Rect2(p.x-9,p.y+13,13,23), Color("#10120f"))
	draw_rect(Rect2(p.x-38,p.y-5,11,9), Color("#24251e"))
	if aura_on and (origin.x < 0 or has_checked_house):
		draw_rect(Rect2(p.x-5,p.y+2,7,8), Color("#566a43"))

func _draw_tree(pos: Vector2) -> void:
	var p := _project(pos)
	# A blocky dead tree with a long shadow.
	_poly(PackedVector2Array([p+Vector2(-3,0),p+Vector2(26,9),p+Vector2(4,20),p+Vector2(-24,10)]), Color("#111510"))
	draw_rect(Rect2(p.x-4,p.y-22,9,30), Color("#28271e"))
	draw_rect(Rect2(p.x-14,p.y-29,13,5), Color("#28271e"))
	draw_rect(Rect2(p.x+2,p.y-37,16,5), Color("#28271e"))
	draw_rect(Rect2(p.x-1,p.y-46,5,15), Color("#28271e"))

func _draw_well_marker(pos: Vector2) -> void:
	var p := _project(pos)
	draw_rect(Rect2(p.x-19,p.y-13,38,18), Color("#494a3f"))
	draw_rect(Rect2(p.x-15,p.y-9,30,10), Color("#0c100e"))
	draw_rect(Rect2(p.x-19,p.y-13,38,3), Color("#686758"))

func _draw_player() -> void:
	var p := Vector2(180.0 + player_pos.x, 306.0 + player_pos.y) if world_mode == "well" else Vector2(180,306)
	# Shadow, legs, dark skin, rough hair, yellow eyes; all pixel-aligned.
	draw_rect(Rect2(p.x-10,p.y+10,22,7), Color("#0e100d"))
	draw_rect(Rect2(p.x-7,p.y+2,5,11), Color("#080a09"))
	draw_rect(Rect2(p.x+3,p.y+2,5,11), Color("#080a09"))
	draw_rect(Rect2(p.x-9,p.y-12,19,17), Color("#080a09"))
	draw_rect(Rect2(p.x-8,p.y-22,17,13), Color("#090b0a"))
	draw_rect(Rect2(p.x-10,p.y-24,7,7), Color("#090b0a"))
	draw_rect(Rect2(p.x+6,p.y-25,7,8), Color("#090b0a"))
	if player_facing.y < -0.25:
		draw_rect(Rect2(p.x-5,p.y-19,3,3), GOLD)
		draw_rect(Rect2(p.x+3,p.y-19,3,3), GOLD)
	elif abs(player_facing.x) > 0.25:
		draw_rect(Rect2(p.x-1,p.y-18,4,3), GOLD)
	else:
		draw_rect(Rect2(p.x-5,p.y-17,3,3), GOLD)
		draw_rect(Rect2(p.x+3,p.y-17,3,3), GOLD)
	# Claws.
	draw_rect(Rect2(p.x-12,p.y-7,3,5), Color("#a9a18b"))
	draw_rect(Rect2(p.x+10,p.y-7,3,5), Color("#a9a18b"))

func _draw_hud() -> void:
	# Top status and current objective.
	draw_rect(Rect2(5,5,350,43), Color("#101310"))
	draw_rect(Rect2(5,5,3,43), GOLD)
	draw_string(ui_font, Vector2(14,20), "ГОРЕВИК  •  1995", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, TEXT)
	var hunger := ["СЫТ","ЛЁГКИЙ ГОЛОД","ГОЛОД","СИЛЬНЫЙ ГОЛОД","СРЫВ"][clampi(hunger_level,0,4)]
	draw_string(ui_font, Vector2(14,36), "ЗДОРОВЬЕ %d   %s" % [health,hunger], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, GOLD)
	draw_rect(Rect2(5,50,350,28), Color("#101310"))
	draw_string(ui_font, Vector2(12,68), action_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, TEXT)
	# Touch joystick.
	draw_circle(joy_origin, 34, Color(0.05,0.06,0.05,0.72))
	draw_arc(joy_origin, 34, 0, TAU, 32, Color("#777663"), 2.0)
	var knob := joy_origin + move_input * 18.0
	draw_circle(knob, 13, Color("#737365"))
	draw_circle(knob, 7, Color("#b2ac91"))
	# Touch action buttons.
	_draw_button(Vector2(286,512), "АУРА", aura_on)
	_draw_button(Vector2(286,570), "ДЕЙСТВИЕ", false)
	# Small location and controls hint.
	draw_string(ui_font, Vector2(9,605), "ДВИЖЕНИЕ", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#a29c87"))
	draw_string(ui_font, Vector2(219,625), "КАСАНИЕ — ДЕЙСТВИЕ", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#a29c87"))

func _draw_button(center: Vector2, label: String, active: bool) -> void:
	var color := Color("#586747") if active else Color("#282c26")
	draw_rect(Rect2(center.x-40,center.y-22,80,44), color)
	draw_rect(Rect2(center.x-40,center.y-22,80,44), Color("#8c896f"), false, 2.0)
	draw_string(ui_font, center+Vector2(0,4), label, HORIZONTAL_ALIGNMENT_CENTER, 80, 9, TEXT)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			move_input.y = -1
		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
			move_input.y = 1
		elif event.keycode == KEY_A or event.keycode == KEY_LEFT:
			move_input.x = -1
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			move_input.x = 1
		elif event.keycode == KEY_E or event.keycode == KEY_SPACE:
			_interact()
		elif event.keycode == KEY_Q:
			aura_on = not aura_on
		elif event.keycode == KEY_ESCAPE:
			story = "Пауза. В Колосовке даже тишина звучит подозрительно."
			queue_redraw()
	elif event is InputEventKey and not event.pressed:
		if event.keycode in [KEY_W,KEY_S,KEY_A,KEY_D,KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]:
			move_input = Vector2.ZERO
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
			var p := _to_game_coords(event.position)
			if p.x < 145 and p.y > 410:
				joy_touch = event.index
				joystick_active = true
				joy_origin = Vector2(62,522)
				_update_joystick(p)
			elif Rect2(246,488,80,48).has_point(p):
				aura_on = not aura_on
			elif Rect2(246,546,80,48).has_point(p):
				_interact()
			queue_redraw()
		elif event.index == joy_touch:
			joy_touch = -1
			joystick_active = false
			move_input = Vector2.ZERO
	elif event is InputEventScreenDrag:
		if event.index == joy_touch:
			_update_joystick(_to_game_coords(event.position))
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		var p := _to_game_coords(event.position)
		if p.x < 145 and p.y > 410:
			_update_joystick(p)
		elif Rect2(246,488,80,48).has_point(p):
			aura_on = not aura_on
		elif Rect2(246,546,80,48).has_point(p):
			_interact()
		queue_redraw()
	elif event is InputEventMouseButton and not event.pressed:
		move_input = Vector2.ZERO

func _to_game_coords(p: Vector2) -> Vector2:
	var sf := min(screen_size.x / 360.0, screen_size.y / 640.0)
	var off := Vector2((screen_size.x - 360.0 * sf) * 0.5, (screen_size.y - 640.0 * sf) * 0.5)
	return (p - off) / sf

func _update_joystick(p: Vector2) -> void:
	var delta := p - joy_origin
	move_input = (delta / 26.0).limit_length(1.0)

func _interact() -> void:
	if world_mode == "well":
		if abs(player_pos.x) < 38 and player_pos.y < -40:
			world_mode = "village"
			player_pos = Vector2(0, 80)
			has_climbed = true
			story = "Выбрался наружу. Колосовка мертва. Провалившиеся крыши, трава по пояс, ни одного дыма. Где-то за избами скребёт железо."
			action_hint = "Осмотри избу или иди по следам"
		else:
			if not meat_found:
				meat_found = true
				story = "Под камнями — кости и тёмные клочья мяса. В стене торчат железные скобы. Выход наверху, на северной стороне."
				action_hint = "Поднимись к скобам у верхней стены"
			else:
				story = "Холодные камни. Сгнившие останки. Скобы ведут вверх — надо подойти ближе к северной стене."
	else:
		var near_house := player_pos.distance_to(Vector2(-123,-128)) < 75 or player_pos.distance_to(Vector2(133,45)) < 75
		if near_house:
			has_checked_house = true
			story = "В избе пахнет золой и мокрой шерстью. На стене детский рисунок: колодец и жёлтые глаза. За печью что-то шуршит. Ты не один."
			action_hint = "Что-то прячется за печью"
		elif player_pos.distance_to(Vector2(45,60)) < 95:
			has_seen_tracks = true
			story = "В грязи — свежие следы сапог. Все ведут к избе. Ни один не возвращается. Между ними тянется борозда, будто волокли тяжёлый мешок."
			action_hint = "Следы свежие. Дождя не было."
		elif player_pos.distance_to(Vector2(0,0)) < 60:
			world_mode = "well"
			player_pos = Vector2.ZERO
			story = "Ты снова у колодца. Из глубины доносится скрежет железа."
			action_hint = "Найди выход из колодца"
		else:
			story = "Только грязь, трава и тишина. Где-то далеко хлопнула дверь. Звук был слишком близко."
			action_hint = "Исследуй деревню"
	queue_redraw()
