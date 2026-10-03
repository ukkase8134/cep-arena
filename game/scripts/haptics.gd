extends Node
## One small Windows bridge handles all XInput motors. Android / PS4 use Godot.
var pipes: Dictionary = {}

func _ready() -> void:
	if OS.get_name()!="Windows" or DisplayServer.get_name()=="headless": return
	var source="res://native/CepHaptics.exe"
	if not FileAccess.file_exists(source): return
	var bytes=FileAccess.get_file_as_bytes(source)
	var context=HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	var digest=context.finish().hex_encode().substr(0,12)
	var target="user://CepHaptics-"+digest+".exe"
	if not FileAccess.file_exists(target):
		var file=FileAccess.open(target,FileAccess.WRITE)
		if file==null: return
		file.store_buffer(bytes)
		file.close()
	pipes=OS.execute_with_pipe(ProjectSettings.globalize_path(target),[str(OS.get_process_id())],false)
	if not pipes.has("stdio"): pipes={}
	else: print("XINPUT_BRIDGE_READY ",pipes.pid)

func pulse(device: int, weak: float, strong: float, duration: float) -> void:
	var info=Input.get_joy_info(device)
	if not pipes.is_empty() and info.has("xinput_index"):
		var index=int(info.xinput_index)
		if index>=0 and index<4:
			pipes.stdio.store_line("%d %d %d %d"%[index,int(clampf(strong,0,1)*65535),int(clampf(weak,0,1)*65535),clampi(int(duration*1000),1,2000)])
			pipes.stdio.flush()
			return
	Input.start_joy_vibration(device,weak,strong,duration)

func stop(device: int) -> void:
	Input.stop_joy_vibration(device)
	var info=Input.get_joy_info(device)
	if not pipes.is_empty() and info.has("xinput_index"):
		pipes.stdio.store_line("%d 0 0 0"%int(info.xinput_index))
		pipes.stdio.flush()

func _exit_tree() -> void:
	for device in Input.get_connected_joypads(): stop(device)
	if not pipes.is_empty():
		pipes.stdio.store_line("quit")
		pipes.stdio.flush()
		pipes.stdio.close()
		pipes.stderr.close()
		pipes={}
