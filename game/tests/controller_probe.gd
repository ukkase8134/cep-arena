extends SceneTree
var elapsed=0.0
var next_pulse=1.0
var next_report=2.0
var pulses=0
var found=false
var duration=65.0
var observed: Dictionary = {}
var strong_test=false
var haptics: Node

func _initialize() -> void:
	Input.set_ignore_joypad_on_unfocused_application(false)
	DisplayServer.window_set_title("Cep Arena · Gamepad testi")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="): duration=float(arg.trim_prefix("--seconds="))
		if arg=="--strong": strong_test=true
	Input.joy_connection_changed.connect(func(device,connected):print("GAMEPAD_CONNECTION ",device," ",connected))
	Input.set_use_accumulated_input(false)
	haptics=preload("res://scripts/haptics.gd").new()
	root.add_child(haptics)

func _process(delta: float) -> bool:
	elapsed+=delta
	var devices=Input.get_connected_joypads()
	for device in devices:
		for button in range(16):
			var key="b%d:%d"%[device,button]
			var pressed=Input.is_joy_button_pressed(device,button)
			if pressed!=observed.get(key,false):
				observed[key]=pressed
				print("GAMEPAD_BUTTON id=",device," button=",button," pressed=",pressed)
		for axis in range(6):
			var key="a%d:%d"%[device,axis]
			var value=Input.get_joy_axis(device,axis)
			if abs(value-float(observed.get(key,0)))>0.3:
				observed[key]=value
				print("GAMEPAD_AXIS id=",device," axis=",axis," value=",value)
	if not devices.is_empty() and not found:
		found=true
		for device in devices:
			print("GAMEPAD_FOUND id=",device," name=",Input.get_joy_name(device)," known=",Input.is_joy_known(device)," vibration_supported=",Input.has_joy_vibration(device)," guid=",Input.get_joy_guid(device)," info=",Input.get_joy_info(device))
	if elapsed>=next_pulse:
		for device in devices:
			haptics.pulse(device,0.55 if strong_test else 0.12,0.4 if strong_test else 0.07,0.65 if strong_test else 0.18)
			print("RUMBLE_SENT id=",device," strong_test=",strong_test," t=",int(elapsed))
			pulses+=1
		next_pulse=elapsed+20.0
	if elapsed>=next_report:
		for device in devices:
			var axes=Vector2(Input.get_joy_axis(device,JOY_AXIS_LEFT_X),Input.get_joy_axis(device,JOY_AXIS_LEFT_Y))
			var buttons: Array = []
			for button in range(16):
				if Input.is_joy_button_pressed(device,button): buttons.append(button)
			print("INPUT_REPORT t=",int(elapsed)," id=",device," left_stick=",axes," buttons=",buttons)
		next_report=elapsed+5.0
	if elapsed>duration:
		for device in devices: haptics.stop(device)
		print("GAMEPAD_PROBE_COMPLETE devices=",devices.size()," pulses=",pulses)
		quit(0 if found else 1)
	return false
