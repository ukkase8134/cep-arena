extends Control
## Independent touch IDs allow four people to use one screen at the same time.
var slots: Array = [0]
var local_mode := false
var touches: Dictionary = {}
var action_touches: Dictionary = {}
var pointer := false
var pointer_pos := Vector2.ZERO
var devices: Array = [-1]
var deadzone := 0.18
var show_touch := true
var hybrid := false

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func centers(n: int) -> Array:
	var left: bool = n%2==0
	var top: bool = local_mode and slots.size()>2 and n>=2
	var x: float = 95 if left else size.x-95
	var y: float = 125 if top else size.y-100
	return [Vector2(x,y),Vector2(x+(155 if left else -155),y)]

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not event.pressed:
			touches.erase(event.index)
			action_touches.erase(event.index)
		else:
			for n in range(slots.size()):
				var c=centers(n)
				if event.position.distance_to(c[0])<78:
					touches[event.index]={"n":n,"p":event.position}
				elif event.position.distance_to(c[1])<55:
					action_touches[event.index]=n
	elif event is InputEventScreenDrag:
		if touches.has(event.index): touches[event.index].p=event.position
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		pointer=event.pressed
		pointer_pos=event.position
	elif event is InputEventMouseMotion:
		pointer_pos=event.position

func read(n: int) -> Dictionary:
	var axis=Vector2.ZERO
	var pressed := false
	var device: int = devices[n] if n<devices.size() else -1
	if device>=0:
		axis=Vector2(Input.get_joy_axis(device,JOY_AXIS_LEFT_X),Input.get_joy_axis(device,JOY_AXIS_LEFT_Y))
		var magnitude=axis.length()
		axis=Vector2.ZERO if magnitude<deadzone else axis.normalized()*clampf((magnitude-deadzone)/(1.0-deadzone),0,1)
		var digital=Vector2(float(Input.is_joy_button_pressed(device,JOY_BUTTON_DPAD_RIGHT))-float(Input.is_joy_button_pressed(device,JOY_BUTTON_DPAD_LEFT)),float(Input.is_joy_button_pressed(device,JOY_BUTTON_DPAD_DOWN))-float(Input.is_joy_button_pressed(device,JOY_BUTTON_DPAD_UP)))
		if digital.length()>0: axis=digital
		pressed=Input.is_joy_button_pressed(device,JOY_BUTTON_A) or Input.is_joy_button_pressed(device,JOY_BUTTON_RIGHT_SHOULDER)
		if not hybrid: return {"axis":axis.limit_length(1.0),"action":pressed}
	var keyboard_axis=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if keyboard_axis.length()>axis.length(): axis=keyboard_axis
	pressed=pressed or Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_ENTER) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var c=centers(n)
	for touch in touches.values():
		if touch.n==n: axis=(touch.p-c[0])/55.0
	for action_slot in action_touches.values():
		if action_slot==n: pressed=true
	if pointer:
		if pointer_pos.distance_to(c[0])<92: axis=(pointer_pos-c[0])/55.0
		if pointer_pos.distance_to(c[1])<55: pressed=true
	return {"axis":axis.limit_length(1.0),"action":pressed}

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	for n in range(slots.size()):
		if n<devices.size() and devices[n]>=0: continue
		if not show_touch: continue
		var c=centers(n)
		var color: Color = preload("res://scripts/simulation.gd").COLORS[slots[n]%4]
		var input=read(n)
		draw_circle(c[0],66,Color(0.03,0.05,0.1,0.58))
		draw_arc(c[0],66,0,TAU,64,Color(color,0.55),2,true)
		draw_circle(c[0],46,Color(color,0.07))
		draw_circle(c[0]+input.axis*42,23,Color(color,0.78))
		draw_circle(c[1],43,Color(color,0.85 if input.action else 0.14))
		draw_arc(c[1],43,0,TAU,48,Color(color,0.7),2,true)
		draw_line(c[1]+Vector2(-9,5),c[1]+Vector2(0,-13),color,4,true)
		draw_line(c[1]+Vector2(0,-13),c[1]+Vector2(0,14),color,4,true)
		draw_line(c[1]+Vector2(0,14),c[1]+Vector2(10,-4),color,4,true)
		if local_mode:
			draw_string(ThemeDB.fallback_font,c[0]+Vector2(-22,89),"P%d"%(slots[n]+1),HORIZONTAL_ALIGNMENT_LEFT,-1,16,color)
