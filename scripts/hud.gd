extends Control

signal fire_pressed
signal reload_pressed
signal look_delta(delta: Vector2)
signal move_vector(value: Vector2)
signal pause_pressed

var left_touch_id := -1
var right_touch_id := -1
var left_origin := Vector2.ZERO
var move_value := Vector2.ZERO
var right_last := Vector2.ZERO
var joystick_base: ColorRect
var joystick_knob: ColorRect
var end_panel: ColorRect
var screen_size := Vector2.ZERO

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    screen_size = get_viewport_rect().size
    _build_controls()
    get_viewport().size_changed.connect(_on_resize)

func _on_resize() -> void:
    screen_size = get_viewport_rect().size
    _layout_controls()

func _build_controls() -> void:
    joystick_base = ColorRect.new()
    joystick_base.color = Color(0.12, 0.15, 0.14, 0.45)
    joystick_base.size = Vector2(142, 142)
    joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(joystick_base)

    joystick_knob = ColorRect.new()
    joystick_knob.color = Color(0.72, 0.76, 0.70, 0.62)
    joystick_knob.size = Vector2(58, 58)
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(joystick_knob)

    var fire := _make_button("FIRE", Vector2(104, 104))
    fire.pressed.connect(func(): fire_pressed.emit())
    fire.name = "FireButton"
    add_child(fire)

    var reload := _make_button("RELOAD", Vector2(94, 54))
    reload.pressed.connect(func(): reload_pressed.emit())
    reload.name = "ReloadButton"
    add_child(reload)

    var pause := _make_button("Ⅱ", Vector2(58, 52))
    pause.pressed.connect(func(): pause_pressed.emit())
    pause.name = "PauseButton"
    add_child(pause)

    var crosshair := Label.new()
    crosshair.text = "+"
    crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    crosshair.add_theme_font_size_override("font_size", 32)
    crosshair.add_theme_color_override("font_color", Color(0.95, 0.95, 0.85, 0.9))
    crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    crosshair.position = Vector2(-16, -22)
    crosshair.size = Vector2(32, 32)
    crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(crosshair)
    _layout_controls()

func _make_button(caption: String, button_size: Vector2) -> Button:
    var button := Button.new()
    button.text = caption
    button.size = button_size
    button.add_theme_font_size_override("font_size", 18 if caption == "FIRE" else 15)
    button.add_theme_color_override("font_color", Color(0.96, 0.96, 0.9))
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(0.12, 0.16, 0.15, 0.76)
    normal.border_color = Color(0.65, 0.68, 0.58, 0.8)
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(18)
    button.add_theme_stylebox_override("normal", normal)
    var pressed := normal.duplicate()
    pressed.bg_color = Color(0.34, 0.40, 0.30, 0.92)
    button.add_theme_stylebox_override("pressed", pressed)
    return button

func _layout_controls() -> void:
    if screen_size == Vector2.ZERO:
        return
    if is_instance_valid(joystick_base):
        joystick_base.position = Vector2(34, screen_size.y - 176)
        if left_touch_id == -1:
            joystick_knob.position = joystick_base.position + Vector2(42, 42)
    var fire = get_node_or_null("FireButton")
    if fire:
        fire.position = Vector2(screen_size.x - 138, screen_size.y - 150)
    var reload = get_node_or_null("ReloadButton")
    if reload:
        reload.position = Vector2(screen_size.x - 244, screen_size.y - 80)
    var pause = get_node_or_null("PauseButton")
    if pause:
        pause.position = Vector2(screen_size.x - 74, 18)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < screen_size.x * 0.42 and left_touch_id == -1:
                left_touch_id = event.index
                left_origin = joystick_base.position + Vector2(71, 71)
                _update_joystick(event.position)
            elif event.position.x >= screen_size.x * 0.42 and right_touch_id == -1:
                right_touch_id = event.index
                right_last = event.position
        else:
            if event.index == left_touch_id:
                left_touch_id = -1
                move_value = Vector2.ZERO
                move_vector.emit(move_value)
                joystick_knob.position = joystick_base.position + Vector2(42, 42)
            if event.index == right_touch_id:
                right_touch_id = -1
    elif event is InputEventScreenDrag:
        if event.index == left_touch_id:
            _update_joystick(event.position)
        elif event.index == right_touch_id:
            var delta: Vector2 = event.position - right_last
            right_last = event.position
            look_delta.emit(delta)

func _update_joystick(pos: Vector2) -> void:
    var offset: Vector2 = (pos - left_origin).limit_length(52.0)
    move_value = Vector2(offset.x / 52.0, offset.y / 52.0)
    move_vector.emit(move_value)
    joystick_knob.position = left_origin + offset - Vector2(29, 29)

func show_end_message(message: String) -> void:
    end_panel = ColorRect.new()
    end_panel.color = Color(0.02, 0.03, 0.025, 0.88)
    end_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    end_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(end_panel)
    var label := Label.new()
    label.text = message + "\n\nЗакройте и запустите игру заново,\nчтобы повторить попытку."
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    label.add_theme_font_size_override("font_size", 34)
    label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.82))
    end_panel.add_child(label)
