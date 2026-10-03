extends Node
## Each physical pad can navigate the UI. Gameplay input remains per device.
signal moved
var ui_root: Control
var enabled: Callable
var back: Callable
var last_key=""
var held=Vector2.ZERO
var repeat_clock=0.0
var stick=Vector2.ZERO

func _ready() -> void:
	# Embedded option menus also receive the left-stick UI actions.
	for action in ["ui_left","ui_right","ui_up","ui_down"]:
		var motion=InputEventJoypadMotion.new()
		motion.device=-1
		motion.axis=JOY_AXIS_LEFT_X if action in ["ui_left","ui_right"] else JOY_AXIS_LEFT_Y
		motion.axis_value=-1 if action in ["ui_left","ui_up"] else 1
		InputMap.action_add_event(action,motion)
		InputMap.action_set_deadzone(action,0.5)

func scope() -> Control:
	if ui_root==null: return null
	var children=ui_root.get_children()
	children.reverse()
	for child in children:
		if child is ColorRect and not child.is_queued_for_deletion(): return child
	return ui_root if enabled.call() else null

func controls(node: Node, result: Array) -> void:
	if node.is_queued_for_deletion(): return
	if node is Control and node.is_visible_in_tree() and node.focus_mode==Control.FOCUS_ALL:
		if not node is BaseButton or not node.disabled: result.append(node)
		if node is OptionButton and not node.get_popup().window_input.is_connected(_popup_input): node.get_popup().window_input.connect(_popup_input)
	for child in node.get_children(): controls(child,result)

func capture_focus() -> void:
	var current=ui_root.get_viewport().gui_get_focus_owner()
	if current!=null: last_key=str(current.get_meta("nav_key",""))

func refresh(preferred: Control=null, remember=false) -> void:
	held=Vector2.ZERO
	stick=Vector2.ZERO
	call_deferred("_restore",preferred,remember)

func _restore(preferred, remember: bool) -> void:
	var area=scope()
	if area==null: return
	var options: Array=[]
	controls(area,options)
	if remember:
		for item in options:
			if not last_key.is_empty() and str(item.get_meta("nav_key",""))==last_key:
				item.grab_focus()
				return
	if is_instance_valid(preferred) and preferred in options: preferred.grab_focus()
	elif not options.is_empty(): options[0].grab_focus()

func open_option() -> OptionButton:
	var options: Array=[]
	if ui_root==null: return null
	controls(ui_root,options)
	for item in options:
		if item is OptionButton and item.get_popup().visible: return item
	return null

func _popup_input(event: InputEvent) -> void:
	if not event is InputEventJoypadButton and not event is InputEventJoypadMotion: return
	var option=open_option()
	if option!=null:
		if event is InputEventJoypadButton and event.pressed:
			if event.button_index in [JOY_BUTTON_B,JOY_BUTTON_START]:
				option.get_popup().hide();option.grab_focus();held=Vector2.ZERO
			elif event.button_index==JOY_BUTTON_A:
				var index=option.get_popup().get_focused_item()
				if index>=0:
					option.select(index)
					option.item_selected.emit(index)
				option.get_popup().hide();option.grab_focus();held=Vector2.ZERO
			elif event.button_index in [JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_UP]:
				held=Vector2.DOWN if event.button_index==JOY_BUTTON_DPAD_DOWN else Vector2.UP
				repeat_clock=0.38
		elif event is InputEventJoypadButton and not event.pressed and event.button_index in [JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_UP]: held=Vector2.ZERO
		elif event is InputEventJoypadMotion and event.axis==JOY_AXIS_LEFT_Y:
			var direction=Vector2(0,signf(event.axis_value)) if abs(event.axis_value)>0.55 else Vector2.ZERO
			if direction!=held:
				held=direction;repeat_clock=0.38
		option.get_popup().set_input_as_handled()
		get_viewport().set_input_as_handled()
		return

func _input(event: InputEvent) -> void:
	if open_option()!=null: return
	if event is InputEventJoypadButton:
		if event.button_index in [JOY_BUTTON_B,JOY_BUTTON_START] and event.pressed:
			back.call()
			get_viewport().set_input_as_handled()
			return
		if scope()==null: return
		var directions={JOY_BUTTON_DPAD_LEFT:Vector2.LEFT,JOY_BUTTON_DPAD_RIGHT:Vector2.RIGHT,JOY_BUTTON_DPAD_UP:Vector2.UP,JOY_BUTTON_DPAD_DOWN:Vector2.DOWN}
		if directions.has(event.button_index):
			held=directions[event.button_index] if event.pressed else Vector2.ZERO
			repeat_clock=0.38
			if event.pressed: move(held)
			get_viewport().set_input_as_handled()
		elif event.button_index==JOY_BUTTON_A:
			if event.pressed: activate()
			get_viewport().set_input_as_handled()
	elif event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y] and scope()!=null:
		if event.axis==JOY_AXIS_LEFT_X: stick.x=event.axis_value
		else: stick.y=event.axis_value
		var direction=Vector2.ZERO
		if stick.length()>0.55:
			direction=Vector2(signf(stick.x),0) if abs(stick.x)>abs(stick.y) else Vector2(0,signf(stick.y))
		if direction!=held:
			held=direction
			repeat_clock=0.38
			if held!=Vector2.ZERO: move(held)
		get_viewport().set_input_as_handled()

func _process(dt: float) -> void:
	if held==Vector2.ZERO or scope()==null: return
	repeat_clock-=dt
	if repeat_clock<=0:
		repeat_clock=0.16
		var option=open_option()
		if option!=null: _option_move(option,int(held.y))
		else: move(held)

func _option_move(option: OptionButton, delta: int) -> void:
	var index=option.get_popup().get_focused_item()
	for step in range(option.item_count):
		index=posmod(index+delta,option.item_count)
		if not option.is_item_disabled(index) and not option.is_item_separator(index):
			option.get_popup().set_focused_item(index)
			moved.emit()
			return

func move(direction: Vector2) -> void:
	var area=scope()
	if area==null: return
	var options: Array=[]
	controls(area,options)
	if options.is_empty(): return
	var current=ui_root.get_viewport().gui_get_focus_owner()
	if current not in options: options[0].grab_focus();return
	if current is Slider and direction.x!=0:
		current.value+=direction.x*maxf(current.step,1)
		return
	var origin: Vector2=current.get_global_rect().get_center()
	var best: Control=null
	var best_cost=INF
	for item in options:
		if item==current: continue
		var delta: Vector2=item.get_global_rect().get_center()-origin
		var ahead=delta.dot(direction)
		if ahead<=8: continue
		var lateral=abs(delta.cross(direction))
		var cost=ahead+lateral*2.8
		if cost<best_cost: best=item;best_cost=cost
	if best!=null:
		best.grab_focus()
		moved.emit()

func activate() -> void:
	var current=ui_root.get_viewport().gui_get_focus_owner()
	if current==null: refresh();return
	if current is OptionButton:
		held=Vector2.ZERO
		stick=Vector2.ZERO
		current.show_popup()
		current.get_popup().set_focused_item(current.selected)
	elif current is BaseButton and not current.disabled:
		if current.toggle_mode: current.button_pressed=not current.button_pressed
		current.pressed.emit()
	elif current is LineEdit: current.edit()
