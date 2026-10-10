extends Control

const BG := Color("#101111")
const STONE := Color("#393b38")
const STONE_DARK := Color("#252725")
const STONE_LIGHT := Color("#55564d")
const RUST := Color("#653d32")
const BLOOD := Color("#572629")
const TEXT := Color("#d8d0b9")
const MUTED := Color("#938c7a")
const GOLD := Color("#e0c44f")
const GREEN := Color("#657f54")

var world_scene := "well"
var story := "Ты приходишь в себя на холодном камне. Над головой — чёрная дыра, далеко-далеко. Пахнет сыростью, землёй и старыми костями. Под пальцами что-то хрустит."
var time_minutes := 0
var hunger_stage := 0
var found_iron := false
var found_cloth := false
var seen_aura := false
var heard_scratching := false
var at_ledge := false
var reached_surface := false
var eaten := false
var discovered_tracks := false
var inspected_house := false
var endings := false
var story_label: Label
var status_label: Label
var buttons: Array[Button] = []
var choice_panel: VBoxContainer
var art_area: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	queue_redraw()
	_refresh_choices()

func _build_ui() -> void:
	art_area = Control.new()
	art_area.position = Vector2.ZERO
	art_area.size = Vector2(360, 255)
	art_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art_area)
	art_area.draw.connect(_draw_world)

	status_label = Label.new()
	status_label.position = Vector2(9, 255)
	status_label.size = Vector2(342, 22)
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", GOLD)
	status_label.text = "ГОРЕВИК  •  ПАМЯТЬ: ПУСТО"
	add_child(status_label)

	var panel := ColorRect.new()
	panel.position = Vector2(0, 278)
	panel.size = Vector2(360, 124)
	panel.color = Color("#171817")
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	story_label = Label.new()
	story_label.position = Vector2(10, 286)
	story_label.size = Vector2(340, 108)
	story_label.add_theme_font_size_override("font_size", 12)
	story_label.add_theme_color_override("font_color", TEXT)
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_child(story_label)

	choice_panel = VBoxContainer.new()
	choice_panel.position = Vector2(8, 407)
	choice_panel.size = Vector2(344, 225)
	choice_panel.add_theme_constant_override("separation", 3)
	add_child(choice_panel)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_draw_world()

func _draw_world() -> void:
	var c := art_area
	if not is_instance_valid(c):
		return
	# Background and deliberate low-resolution blocks create a pixel-art look.
	c.draw_rect(Rect2(0, 0, 360, 255), Color("#090b0b"))
	if reached_surface:
		_draw_surface(c)
	elif at_ledge:
		_draw_ledge(c)
	else:
		_draw_well(c)

func _draw_well(c: Control) -> void:
	c.draw_rect(Rect2(0, 0, 360, 255), Color("#090b0b"))
	# Well walls taper toward the distant opening.
	c.draw_colored_polygon(PackedVector2Array([Vector2(0,0),Vector2(88,0),Vector2(126,220),Vector2(0,255)]), Color("#292c2a"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(272,0),Vector2(360,0),Vector2(360,255),Vector2(234,220)]), Color("#30322e"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(88,0),Vector2(272,0),Vector2(234,220),Vector2(126,220)]), Color("#151817"))
	# Uneven old bricks.
	for y in range(8, 218, 22):
		var inset := int((y / 22) % 2) * 15
		for x in range(-15 + inset, 110, 34):
			c.draw_rect(Rect2(x, y, 30, 17), STONE)
			c.draw_rect(Rect2(x + 2, y + 2, 26, 2), STONE_LIGHT)
		for x in range(250 + inset, 380, 34):
			c.draw_rect(Rect2(x, y, 30, 17), STONE)
			c.draw_rect(Rect2(x + 2, y + 2, 26, 2), STONE_LIGHT)
	# Tiny unreachable opening above.
	c.draw_rect(Rect2(119, 0, 122, 8), Color("#1e2420"))
	c.draw_rect(Rect2(143, 8, 74, 5), Color("#3b4338"))
	c.draw_rect(Rect2(157, 13, 46, 5), Color("#4b5540"))
	# Damp streaks and roots.
	for i in range(7):
		var x := 18 + i * 12
		c.draw_rect(Rect2(x, 35 + (i % 3) * 14, 2, 34 + (i % 4) * 7), Color("#3e493c"))
	for i in range(6):
		var x := 278 + i * 12
		c.draw_rect(Rect2(x, 30 + (i % 4) * 11, 2, 29 + (i % 3) * 10), Color("#4a4839"))
	# Floor, bones, rags, and black stains.
	c.draw_colored_polygon(PackedVector2Array([Vector2(126,220),Vector2(234,220),Vector2(360,255),Vector2(0,255)]), Color("#202321"))
	c.draw_rect(Rect2(18, 234, 48, 7), BLOOD)
	c.draw_rect(Rect2(30, 228, 5, 15), Color("#b3a78c"))
	c.draw_rect(Rect2(36, 234, 21, 4), Color("#c5b99b"))
	c.draw_rect(Rect2(267, 229, 27, 5), Color("#9b8d72"))
	c.draw_rect(Rect2(281, 223, 5, 17), Color("#b7a98c"))
	c.draw_rect(Rect2(73, 243, 21, 4), Color("#383a34"))
	c.draw_rect(Rect2(86, 239, 4, 12), Color("#b4a486"))
	# Character: black skin, rough hair, yellow eyes.
	c.draw_rect(Rect2(166, 206, 27, 31), Color("#090a0a"))
	c.draw_rect(Rect2(170, 190, 19, 20), Color("#080909"))
	c.draw_rect(Rect2(168, 185, 5, 8), Color("#0b0c0b"))
	c.draw_rect(Rect2(185, 184, 5, 9), Color("#0b0c0b"))
	c.draw_rect(Rect2(172, 196, 4, 3), GOLD)
	c.draw_rect(Rect2(183, 196, 4, 3), GOLD)
	c.draw_rect(Rect2(173, 202, 12, 2), Color("#6d2c2b"))
	c.draw_rect(Rect2(160, 232, 8, 13), Color("#0a0b0a"))
	c.draw_rect(Rect2(190, 232, 8, 13), Color("#0a0b0a"))
	if seen_aura:
		c.draw_rect(Rect2(276, 190, 4, 20), Color("#8b9c5a"))
		c.draw_rect(Rect2(268, 195, 20, 5), Color("#526b46"))
		c.draw_rect(Rect2(271, 188, 14, 23), Color("#384d37"))
		c.draw_rect(Rect2(274, 193, 3, 3), Color("#d3db8b"))
		c.draw_rect(Rect2(281, 193, 3, 3), Color("#d3db8b"))
	if heard_scratching:
		c.draw_rect(Rect2(154, 22, 52, 3), Color("#756d4c"))
		c.draw_rect(Rect2(163, 29, 34, 3), Color("#756d4c"))

func _draw_ledge(c: Control) -> void:
	c.draw_rect(Rect2(0, 0, 360, 255), Color("#0c1110"))
	c.draw_rect(Rect2(0, 0, 360, 32), Color("#151b17"))
	# Vertical shaft and distant circle of grey sky.
	c.draw_rect(Rect2(106, 0, 148, 198), Color("#262a27"))
	c.draw_rect(Rect2(120, 0, 120, 188), Color("#101412"))
	c.draw_rect(Rect2(132, 0, 96, 14), Color("#59604f"))
	c.draw_rect(Rect2(148, 0, 64, 7), Color("#9a9a7e"))
	for y in range(20, 185, 26):
		c.draw_rect(Rect2(111, y, 14, 12), STONE)
		c.draw_rect(Rect2(235, y + 8, 14, 12), STONE)
	c.draw_rect(Rect2(0, 199, 360, 56), Color("#252823"))
	c.draw_rect(Rect2(0, 199, 360, 6), Color("#4a4a3d"))
	c.draw_rect(Rect2(145, 180, 70, 18), Color("#3e4037"))
	c.draw_rect(Rect2(165, 162, 28, 26), Color("#080909"))
	c.draw_rect(Rect2(169, 151, 20, 16), Color("#080909"))
	c.draw_rect(Rect2(171, 157, 4, 3), GOLD)
	c.draw_rect(Rect2(183, 157, 4, 3), GOLD)
	c.draw_rect(Rect2(124, 206, 40, 5), RUST)
	c.draw_rect(Rect2(128, 211, 6, 25), RUST)
	c.draw_rect(Rect2(132, 218, 25, 4), RUST)

func _draw_surface(c: Control) -> void:
	c.draw_rect(Rect2(0, 0, 360, 255), Color("#171d1a"))
	c.draw_rect(Rect2(0, 0, 360, 86), Color("#292f2b"))
	c.draw_rect(Rect2(0, 68, 360, 187), Color("#24251f"))
	# Dead trees and fog.
	for i in range(8):
		var x := i * 51 - 8
		c.draw_rect(Rect2(x, 35 + (i % 3) * 9, 7, 140), Color("#121714"))
		c.draw_rect(Rect2(x - 14, 47 + (i % 2) * 13, 24, 5), Color("#121714"))
		c.draw_rect(Rect2(x + 3, 58 + (i % 4) * 8, 28, 5), Color("#121714"))
	c.draw_rect(Rect2(0, 174, 360, 81), Color("#303028"))
	c.draw_rect(Rect2(0, 191, 360, 4), Color("#3c3c2d"))
	# Abandoned hut in the fog.
	c.draw_colored_polygon(PackedVector2Array([Vector2(207,104),Vector2(285,104),Vector2(305,133),Vector2(187,133)]), Color("#302d26"))
	c.draw_rect(Rect2(199, 132, 94, 53), Color("#3a342a"))
	c.draw_rect(Rect2(215, 144, 17, 18), Color("#101310"))
	c.draw_rect(Rect2(256, 151, 17, 34), Color("#171613"))
	c.draw_rect(Rect2(256, 151, 17, 3), RUST)
	c.draw_rect(Rect2(36, 201, 42, 7), Color("#141714"))
	c.draw_rect(Rect2(55, 194, 5, 20), Color("#151915"))
	c.draw_rect(Rect2(156, 215, 48, 4), Color("#121512"))
	c.draw_rect(Rect2(173, 210, 4, 14), Color("#121512"))
	# Player silhouette foreground.
	c.draw_rect(Rect2(163, 182, 29, 37), Color("#070808"))
	c.draw_rect(Rect2(168, 166, 19, 20), Color("#070808"))
	c.draw_rect(Rect2(171, 172, 4, 3), GOLD)
	c.draw_rect(Rect2(182, 172, 4, 3), GOLD)
	if seen_aura:
		c.draw_rect(Rect2(232, 123, 4, 18), Color("#8c9854"))
		c.draw_rect(Rect2(224, 128, 20, 4), Color("#536744"))
		c.draw_rect(Rect2(229, 119, 11, 27), Color("#3b5035"))

func _refresh_choices() -> void:
	if not is_instance_valid(choice_panel):
		return
	for child in choice_panel.get_children():
		child.queue_free()
	buttons.clear()
	story_label.text = story
	status_label.text = _status_text()
	var options: Array[Dictionary] = []
	if endings:
		options = [{"text":"Начать заново","action":"restart"}]
	elif reached_surface:
		options.append({"text":"Осмотреть заброшенную избу","action":"house"})
		options.append({"text":"Посмотреть на следы у дороги","action":"tracks"})
		options.append({"text":"Включить зрение аур","action":"aura"})
		options.append({"text":"Вернуться к колодцу","action":"return_well"})
	elif at_ledge:
		options.append({"text":"Выбраться наружу","action":"climb_out"})
		options.append({"text":"Осмотреть уступ и железные скобы","action":"ledge_inspect"})
		options.append({"text":"Посмотреть вниз, в темноту","action":"look_down"})
		options.append({"text":"Включить зрение аур","action":"aura"})
	else:
		options.append({"text":"Осмотреть останки","action":"remains"})
		options.append({"text":"Проверить стену колодца","action":"wall"})
		options.append({"text":"Прислушаться","action":"listen"})
		options.append({"text":"Включить зрение аур","action":"aura"})
		if found_iron:
			options.append({"text":"Попробовать подняться по скобам","action":"climb"})
		if found_cloth and not eaten:
			options.append({"text":"Съесть найденную плоть","action":"eat"})
	for option in options:
		var b := Button.new()
		b.text = str(option.text)
		b.custom_minimum_size = Vector2(344, 34)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 11)
		b.add_theme_color_override("font_color", TEXT)
		b.add_theme_color_override("font_hover_color", Color("#fff1b2"))
		b.add_theme_stylebox_override("normal", _button_style(Color("#252824"), Color("#4a4c40")))
		b.add_theme_stylebox_override("hover", _button_style(Color("#34392f"), GOLD))
		b.add_theme_stylebox_override("pressed", _button_style(Color("#171a17"), GOLD))
		b.pressed.connect(_choose.bind(str(option.action)))
		choice_panel.add_child(b)
		buttons.append(b)

func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(2)
	s.content_margin_left = 7
	s.content_margin_right = 5
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	return s

func _status_text() -> String:
	var hours := int(time_minutes / 60)
	var mins := time_minutes % 60
	var hunger := "СЫТ"
	if hunger_stage == 1:
		hunger = "ЛЁГКИЙ ГОЛОД"
	elif hunger_stage == 2:
		hunger = "ГОЛОД"
	elif hunger_stage == 3:
		hunger = "СИЛЬНЫЙ ГОЛОД"
	elif hunger_stage >= 4:
		hunger = "НЕТ КОНТРОЛЯ"
	return "ВРЕМЯ %02d:%02d  •  %s" % [hours % 24, mins, hunger]

func _advance(minutes: int = 15) -> void:
	time_minutes += minutes
	var days := int(time_minutes / 1440)
	if days >= 7:
		hunger_stage = 4
	elif days >= 5:
		hunger_stage = 3
	elif days >= 3:
		hunger_stage = 2
	elif days >= 1:
		hunger_stage = 1

func _choose(action: String) -> void:
	if action == "restart":
		get_tree().reload_current_scene()
		return
	if action == "remains":
		_advance(10)
		found_cloth = true
		story = "Под ногами — человеческие кости. Часть свежая на вид, но пахнет так, будто лежит тут лет двадцать. На рёбрах засохли тёмные клочья. В тряпье застрял кусок мяса. Рядом — череп с выбитыми зубами. Имена эти люди с собой не унесли."
	elif action == "wall":
		_advance(15)
		found_iron = true
		story = "Камни мокрые. В швах торчат старые железные скобы. Ржавые, но держатся крепко. Между ними болтаются корни. Выше — ещё скобы, почти до самого верха. Кто-то уже выбирался отсюда. Или пытался."
	elif action == "listen":
		_advance(10)
		heard_scratching = true
		story = "Сверху капает вода. Потом тишина. Потом скрежет. Будто кто-то тащит по камню железную цепь. Звук обрывается, когда ты замираешь. Слышать его снова не хочется."
	elif action == "aura":
		_advance(5)
		seen_aura = true
		if reached_surface:
			story = "Мир проступает сквозь серую мглу. У избы тянется слабая зеленоватая аура. Не живая, но и не совсем мёртвая. Она прячется за стеной. Пока не ясно, что это."
		else:
			story = "Темнота меняется. Камни остаются камнями. Останки — пустые, давно остывшие пятна. Но высоко над тобой, у края колодца, мерцает тусклая зеленоватая аура. Кто-то там есть. Или что-то."
	elif action == "climb":
		_advance(20)
		at_ledge = true
		world_scene = "ledge"
		story = "Скобы скрипят. Одна вырывается и падает вниз, звеня о камни. Ты замираешь, вцепившись когтями в шов кладки. Выше — уступ. До края ещё далеко. Сверху тянет холодным воздухом."
	elif action == "eat":
		_advance(20)
		eaten = true
		found_cloth = false
		hunger_stage = max(0, hunger_stage - 1)
		story = "Мясо сухое, с привкусом земли и старого железа. Ты жуёшь. Организм принимает пищу, но голод не исчезает. Это была мёртвая плоть. Тебе нужно нечто другое. Что-то, что ещё боится."
	elif action == "climb_out":
		_advance(25)
		at_ledge = false
		reached_surface = true
		world_scene = "village"
		story = "Ты выбираешься на поверхность. Воздух режет лёгкие, хотя дышать тебе, кажется, необязательно. Деревня мертва: провалившиеся крыши, чёрные окна, трава по пояс. На столбе висит табличка. Краска облезла: «КОЛОСОВКА». Дальше дорога уходит в лес."
	elif action == "ledge_inspect":
		_advance(10)
		story = "На уступе лежит обрывок верёвки и ржавая цепь. Верёвка сгнила насквозь. На камне кто-то нацарапал ножом: «НЕ СМОТРИ ЕМУ В ГЛАЗА». Буквы старые. Последняя царапина свежая."
	elif action == "look_down":
		_advance(5)
		world_scene = "ledge"
		story = "Дна почти не видно. Но ты различаешь то место, где очнулся. Там, среди костей, лежит что-то тёмное. Когда ты моргаешь, предмет уже не там. Может, просто тень."
	elif action == "house":
		_advance(20)
		inspected_house = true
		seen_aura = true
		story = "Дверь висит на одной петле. Внутри — печь, стол, перевёрнутая табуретка. На стене детский рисунок: чёрный колодец и жёлтые глаза. За печью шуршит что-то маленькое. Зеленоватая аура ползёт по полу, будто её тянут за нитку."
	elif action == "tracks":
		_advance(15)
		discovered_tracks = true
		story = "В грязи видны следы сапог. Несколько пар. Все идут от дороги к избе, но ни один не возвращается. Между ними — тонкая борозда, словно кто-то волочил тяжёлый мешок. Следы свежие. Дождя давно не было."
	elif action == "return_well":
		_advance(10)
		reached_surface = false
		at_ledge = true
		world_scene = "ledge"
		story = "Ты спускаешься на уступ. Внизу опять скребёт железо. На этот раз звук доносится не сверху, а из-под камней."
	_refresh_choices()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
