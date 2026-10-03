extends Node
const Sim=preload("res://scripts/simulation.gd")
const View3D=preload("res://scripts/arena_3d.gd")
const View2D=preload("res://scripts/arena_2d.gd")
const Controls=preload("res://scripts/controls.gd")
const Haptics=preload("res://scripts/haptics.gd")
const VERSION="1.0.0"
const DEFAULT_PORT=28742
const INK=Color("0b1428")
const PANEL=Color("14213a")
const MUTED=Color("9aa9c5")
const WHITE=Color("f4f6ff")
const MINT=Color("80f5cd")
var ui: Control
var visual: Control
var sim=Sim.new()
var screen="menu"
var mode="solo"
var selected=0
var player_count=4
var difficulty=1
var tournament=false
var rounds: Array = []
var round_index=0
var standings: Array = []
var names: Dictionary = {}
var roster: Array = []
var connected=false
var connecting=false
var player_name="Oyuncu"
var ip_address="192.168.1.10"
var port=DEFAULT_PORT
var message=""
var pads: Control
var arena: Control
var game_title: Label
var clock_label: Label
var scores: Array = []
var hint: Label
var target_chip: PanelContainer
var inputs: Dictionary = {}
var input_times: Dictionary = {}
var packet_clock=0.0
var client_input_clock=0.0
var connect_clock=0.0
var last_event=0
var sound=true
var sfx: AudioStreamPlayer
var stats={"matches":0,"wins":0,"best":0}
var args: Dictionary = {}
var demo=false
var auto_clock=0.0
var network_frames=0
var smoke_started=false
var smoke_rounds=0
var device_slots: Array = [-1]
var rumble_enabled=true
var rumble_strength=0.65
var pad_layout=0
var deadzone=0.18
var primary_source=0
var controller_message=""
var vibration_state: Dictionary = {}
var haptics: Node

func _ready() -> void:
	Input.set_ignore_joypad_on_unfocused_application(false)
	for argument in OS.get_cmdline_user_args():
		var parts=argument.trim_prefix("--").split("=",true,1)
		args[parts[0]]=parts[1] if parts.size()>1 else "true"
	port=int(args.get("port",DEFAULT_PORT))
	_load_settings()
	var canvas=CanvasLayer.new()
	add_child(canvas)
	visual=Control.new()
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(visual)
	ui=Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui)
	var theme=Theme.new()
	var font=FontVariation.new()
	font.base_font=load("res://assets/Rubik.ttf")
	font.variation_opentype={"wght":450}
	theme.default_font=font
	theme.default_font_size=18
	theme.set_color("font_color","Label",WHITE)
	theme.set_color("font_color","Button",WHITE)
	theme.set_stylebox("normal","Button",_style(PANEL,12))
	theme.set_stylebox("hover","Button",_style(Color("253957"),12,MINT))
	theme.set_stylebox("pressed","Button",_style(Color("304963"),12))
	theme.set_stylebox("focus","Button",_style(Color(0,0,0,0),12,MINT))
	theme.set_stylebox("normal","LineEdit",_style(Color("1b2b48"),10))
	theme.set_color("font_color","LineEdit",WHITE)
	theme.set_color("font_placeholder_color","LineEdit",MUTED)
	theme.set_color("font_color","CheckButton",WHITE)
	ui.theme=theme
	sfx=AudioStreamPlayer.new()
	add_child(sfx)
	haptics=Haptics.new()
	add_child(haptics)
	Input.joy_connection_changed.connect(_controller_changed)
	multiplayer.peer_disconnected.connect(_peer_left)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_lost)
	_show_menu()
	if args.has("demo"):
		demo=true
		selected=clampi(int(args.demo),0,5)
		_start_offline()
	elif args.has("smoke-host"):
		player_name="QA Host"
		player_count=4
		_host()
	elif args.has("smoke-client"):
		player_name="QA Client"
		ip_address="127.0.0.1"
		_join()
	if args.has("capture"):
		await get_tree().create_timer(2.5).timeout
		await RenderingServer.frame_post_draw
		var img=get_viewport().get_texture().get_image()
		var err=img.save_png(args.capture)
		print("CAPTURE ",args.capture," ",err)
		get_tree().quit(0 if err==OK else 1)
	elif args.has("rumble-test"):
		await get_tree().create_timer(1.0).timeout
		for device in Input.get_connected_joypads():
			haptics.pulse(device,0.55,0.4,0.65)
			print("EXPORTED_RUMBLE_SENT ",device)

func _style(color: Color, radius=16, border=Color(0,0,0,0)) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1 if border.a>0 else 0)
	style.border_color=border
	style.content_margin_left=18
	style.content_margin_right=18
	style.content_margin_top=12
	style.content_margin_bottom=12
	return style

func _label(text_value: String, size_value=18, color=WHITE) -> Label:
	var label=Label.new()
	label.text=text_value
	label.add_theme_font_size_override("font_size",size_value)
	label.add_theme_color_override("font_color",color)
	if size_value>=23:
		var bold=FontVariation.new()
		bold.base_font=load("res://assets/Rubik.ttf")
		bold.variation_opentype={"wght":650}
		label.add_theme_font_override("font",bold)
	return label

func _button(text_value: String, callback: Callable, accent=false) -> Button:
	var button=Button.new()
	button.text=text_value
	button.custom_minimum_size=Vector2(0,44)
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	if accent:
		button.add_theme_stylebox_override("normal",_style(MINT,12))
		button.add_theme_stylebox_override("hover",_style(MINT.lightened(0.12),12))
		button.add_theme_stylebox_override("pressed",_style(MINT.darkened(0.15),12))
		button.add_theme_color_override("font_color",INK)
		button.add_theme_color_override("font_hover_color",INK)
		button.add_theme_color_override("font_pressed_color",INK)
	button.pressed.connect(func(): _play_sound("tap"); callback.call())
	return button

func _clear() -> void:
	for child in ui.get_children(): child.free()
	for child in visual.get_children(): child.free()
	arena=null
	pads=null
	scores.clear()
	var background=ColorRect.new()
	background.color=INK
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.add_child(background)

func _page() -> VBoxContainer:
	var margin=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,28)
	ui.add_child(margin)
	var box=VBoxContainer.new()
	box.add_theme_constant_override("separation",16)
	margin.add_child(box)
	return box

func _spacer(parent: Container, vertical=false) -> Control:
	var spacer=Control.new()
	if vertical: spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL
	else: spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)
	return spacer

func _header(parent: VBoxContainer, subtitle: String) -> void:
	var bar=HBoxContainer.new()
	bar.add_theme_constant_override("separation",12)
	parent.add_child(bar)
	var icon=TextureRect.new()
	icon.texture=load("res://assets/icon.svg")
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.custom_minimum_size=Vector2(43,43)
	bar.add_child(icon)
	bar.add_child(_label("CEP ARENA",24))
	bar.add_child(_label("  /  "+subtitle,15,MUTED))
	_spacer(bar)
	bar.add_child(_label("2–4 OYUNCU",13,MINT))
	bar.add_child(_button("Ayarlar",_settings))

func _show_menu() -> void:
	screen="menu"
	_clear()
	var box=_page()
	_header(box,"Birlikte oyna. Daha çok gül.")
	var body=HBoxContainer.new()
	body.add_theme_constant_override("separation",28)
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	box.add_child(body)
	var left=VBoxContainer.new()
	left.custom_minimum_size.x=330
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio=0.43
	left.add_theme_constant_override("separation",10)
	body.add_child(left)
	left.add_child(_label("KÜÇÜK OYUNLAR. BÜYÜK REKABET.",12,MINT))
	left.add_child(_label("Arkadaşlarını\narenaya çağır.",37))
	var text=_label("Altı mini oyun. Dört renk.\nHer turda yeni bir şampiyon.",16,MUTED)
	left.add_child(text)
	var choice=HBoxContainer.new()
	choice.add_theme_constant_override("separation",8)
	left.add_child(choice)
	for n in [2,3,4]:
		var button=_button("%d kişi"%n,func():player_count=n;_show_menu(),player_count==n)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		choice.add_child(button)
	var selected_box=PanelContainer.new()
	selected_box.add_theme_stylebox_override("panel",_style(PANEL,16))
	left.add_child(selected_box)
	var selected_v=VBoxContainer.new()
	selected_box.add_child(selected_v)
	selected_v.add_child(_label("SIRADAKİ OYUN",11,MUTED))
	selected_v.add_child(_label(Sim.GAMES[selected].name,23,Color(Sim.GAMES[selected].color)))
	var quick=_button("Botlarla oyna  →",func():mode="solo";_start_offline(),true)
	quick.custom_minimum_size.y=52
	left.add_child(quick)
	left.add_child(_button("Gamepad ile birlikte oyna",_local_setup))
	var small=CheckButton.new()
	small.text="3 turluk turnuva"
	small.add_theme_font_size_override("font_size",15)
	small.button_pressed=tournament
	small.toggled.connect(func(value):tournament=value)
	left.add_child(small)
	_spacer(left,true)
	var grid=GridContainer.new()
	grid.columns=3
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.size_flags_stretch_ratio=1.0
	body.add_child(grid)
	for i in range(6): grid.add_child(_game_card(i))
	var footer=HBoxContainer.new()
	footer.add_theme_constant_override("separation",12)
	box.add_child(footer)
	footer.add_child(_button("+  LAN odası kur",_host))
	footer.add_child(_button("↗  Odaya katıl",_join_dialog))
	_spacer(footer)
	var footer_label=_label(message if not message.is_empty() else "Çevrimdışı hazır  ·  Wi-Fi / Radmin ile LAN",13,MUTED)
	footer_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	footer_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	footer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_child(footer_label)

func _game_card(index: int) -> Control:
	var card=PanelContainer.new()
	card.custom_minimum_size=Vector2(212,216)
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.size_flags_vertical=Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",_style(Color("192942") if index==selected else PANEL,16,Color(Sim.GAMES[index].color) if index==selected else Color("25314b")))
	var content=VBoxContainer.new()
	content.add_theme_constant_override("separation",10)
	card.add_child(content)
	var art=TextureRect.new()
	art.texture=load("res://assets/game%d.svg"%index)
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size=Vector2(0,100)
	art.size_flags_vertical=Control.SIZE_EXPAND_FILL
	content.add_child(art)
	content.add_child(_label(Sim.GAMES[index].tag,10,Color(Sim.GAMES[index].color)))
	content.add_child(_label(Sim.GAMES[index].name,18))
	var choose=_button("Seçildi  ✓" if index==selected else "Oyunu seç  →",func():selected=index;_show_menu())
	choose.custom_minimum_size.y=34
	choose.add_theme_font_size_override("font_size",13)
	content.add_child(choose)
	return card

func _modal(title: String) -> VBoxContainer:
	var shade=ColorRect.new()
	shade.color=Color(0.01,0.02,0.06,0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(shade)
	var center=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel=PanelContainer.new()
	panel.custom_minimum_size.x=510
	panel.add_theme_stylebox_override("panel",_style(PANEL,22,Color("354769")))
	center.add_child(panel)
	var scroll=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(0,minf(600,get_viewport().get_visible_rect().size.y-96))
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var content=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.set_meta("shade",shade)
	content.add_theme_constant_override("separation",14)
	scroll.add_child(content)
	content.add_child(_label(title,28))
	var close=_button("Kapat",func():shade.queue_free())
	content.add_child(close)
	content.move_child(close,0)
	return content

func _settings() -> void:
	var content=_modal("Oyun ayarları")
	content.add_child(_label("Oyuncu adın",14,MUTED))
	var edit=LineEdit.new()
	edit.text=player_name
	edit.max_length=20
	edit.custom_minimum_size.y=45
	edit.text_changed.connect(func(value):player_name=value.strip_edges();_save_settings())
	content.add_child(edit)
	var audio=CheckButton.new()
	audio.text="Oyun sesleri"
	audio.button_pressed=sound
	audio.toggled.connect(func(value):sound=value;_save_settings())
	content.add_child(audio)
	content.add_child(_label("Bot seviyesi",14,MUTED))
	var levels=HBoxContainer.new()
	content.add_child(levels)
	for i in range(3):
		levels.add_child(_button(["Rahat","Normal","Zorlu"][i],func():difficulty=i;_save_settings();content.get_meta("shade").queue_free();_settings(),difficulty==i))
	if OS.get_name()!="Android":
		content.add_child(_button("Tam ekranı değiştir",_fullscreen))
	content.add_child(_button("Gamepad ve titreşim ayarları",_controller_settings))
	content.add_child(_label("Klavye: WASD / Oklar  ·  Hamle: Boşluk / Sağ tık\nGamepad: sol çubuk / yön tuşları + A / × / R1\nTelefonda: joystick + şimşek veya gamepad.",14,MUTED))
	content.add_child(_label("%d maç  ·  %d galibiyet  ·  v%s"%[stats.matches,stats.wins,VERSION],13,MINT))

func _fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _local_setup() -> void:
	var content=_modal("Aynı cihazda birlikte oyna")
	content.add_child(_label("Bir klavye / dokunmatik oyuncusu ve her gamepad\nayrı bir oyuncudur. En fazla dört kişi oynayabilir.",16,MUTED))
	var sources: Array = []
	var keyboard=CheckButton.new()
	keyboard.text="P1 · Dokunmatik" if OS.get_name()=="Android" else "P1 · Klavye + mouse (tek oyuncu)"
	keyboard.button_pressed=true
	content.add_child(keyboard)
	for device in Input.get_connected_joypads():
		var check=CheckButton.new()
		check.text="Gamepad %d · %s"%[device+1,Input.get_joy_name(device)]
		check.button_pressed=sources.size()<3
		content.add_child(check)
		sources.append({"id":device,"check":check})
	if sources.is_empty(): content.add_child(_label("Henüz gamepad bağlı değil. USB veya Bluetooth ile bağla.\nTek başınaysan diğer oyuncuları botlar tamamlar.",14,MUTED))
	content.add_child(_button("Kontrolcüleri yeniden tara",func():content.get_meta("shade").queue_free();_local_setup()))
	content.add_child(_button("Birlikte oyna  →",func():
		device_slots=[]
		if keyboard.button_pressed: device_slots.append(-1)
		for source in sources:
			if source.check.button_pressed and device_slots.size()<4: device_slots.append(source.id)
		if device_slots.is_empty(): device_slots=[-1]
		player_count=maxi(2,device_slots.size())
		mode="local"
		_start_offline(),true))

func _controller_settings() -> void:
	var content=_modal("Gamepad ve titreşim")
	var devices=Input.get_connected_joypads()
	content.add_child(_label("Algılanan gamepad: %d"%devices.size(),16,MINT))
	for device in devices: content.add_child(_label("%d · %s"%[device+1,Input.get_joy_name(device)],14,MUTED))
	content.add_child(_label("Tuş gösterimi",14,MUTED))
	var source=OptionButton.new()
	source.add_item("Otomatik · klavye/dokunmatik + ilk gamepad")
	source.add_item("Klavye / mouse / dokunmatik")
	for device in devices: source.add_item("Gamepad · "+Input.get_joy_name(device))
	source.selected=mini(primary_source,source.item_count-1)
	source.item_selected.connect(func(index):primary_source=index;_save_settings())
	content.add_child(source)
	var layout=OptionButton.new()
	for name_value in ["Otomatik algıla","Xbox / Xbox 360 · A","PlayStation / PS4 · ×"]: layout.add_item(name_value)
	layout.selected=pad_layout
	layout.item_selected.connect(func(index):pad_layout=index;_save_settings())
	content.add_child(layout)
	var vibration=CheckButton.new()
	vibration.text="Titreşim / rumble"
	vibration.button_pressed=rumble_enabled
	vibration.toggled.connect(func(enabled):rumble_enabled=enabled;_save_settings())
	content.add_child(vibration)
	var strength_label=_label("Titreşim gücü: %d%%"%int(rumble_strength*100),14,MUTED)
	content.add_child(strength_label)
	var strength=HSlider.new()
	strength.min_value=0
	strength.max_value=100
	strength.value=rumble_strength*100
	strength.custom_minimum_size.y=26
	strength.value_changed.connect(func(value):rumble_strength=value/100;strength_label.text="Titreşim gücü: %d%%"%int(value);_save_settings())
	content.add_child(strength)
	var dead_label=_label("Çubuk ölü bölgesi: %d%%"%int(deadzone*100),14,MUTED)
	content.add_child(dead_label)
	var dead=HSlider.new()
	dead.min_value=5
	dead.max_value=40
	dead.value=deadzone*100
	dead.custom_minimum_size.y=26
	dead.value_changed.connect(func(value):deadzone=value/100;dead_label.text="Çubuk ölü bölgesi: %d%%"%int(value);_save_settings())
	content.add_child(dead)
	content.add_child(_button("Titreşimi test et",func():
		for device in Input.get_connected_joypads():
			if rumble_enabled: haptics.pulse(device,rumble_strength*0.5,rumble_strength,0.45)))
	content.add_child(_label("Sol çubuk / yön tuşları: hareket\nA / × veya RB / R1: hamle\nTitreşim, kontrolcünün ve Android sürücüsünün\ndesteklediği cihazlarda çalışır.",14,MUTED))

func _controller_changed(device: int, is_connected: bool) -> void:
	controller_message=("Gamepad bağlandı: "+Input.get_joy_name(device)) if is_connected else "Gamepad bağlantısı kesildi"
	print("CONTROLLER ",device," CONNECTED ",is_connected)
	if not is_connected and mode!="local" and device in device_slots:
		device_slots=[-1]
		if pads!=null: pads.devices=[-1]
	if screen=="menu": message=controller_message;_show_menu()

func _rumble_slot(slot: int, weak: float, strong: float, duration: float) -> void:
	if not rumble_enabled or pads==null: return
	var index=pads.slots.find(slot)
	if index>=0 and index<pads.devices.size() and pads.devices[index]>=0:
		haptics.pulse(pads.devices[index],weak*rumble_strength,strong*rumble_strength,duration)

func _action_label() -> String:
	if pad_layout==2: return "× / R1"
	if pad_layout==1: return "A / RB"
	if not device_slots.is_empty() and device_slots[0]>=0:
		var name_value=Input.get_joy_name(device_slots[0]).to_lower()
		return "× / R1" if "ps4" in name_value or "sony" in name_value or "dual" in name_value or "playstation" in name_value else "A / RB"
	return "Boşluk / Sağ tık / Şimşek"

func _primary_device() -> int:
	var devices=Input.get_connected_joypads()
	if primary_source==1 or devices.is_empty(): return -1
	return devices[clampi(primary_source-2,0,devices.size()-1)]

func _join_dialog() -> void:
	var content=_modal("Arkadaşının odasına katıl")
	content.add_child(_label("Aynı Wi-Fi veya aynı Radmin ağına bağlan.\nOdayı açan kişinin IP adresini yaz.",16,MUTED))
	var name_edit=LineEdit.new()
	name_edit.text=player_name
	name_edit.placeholder_text="Oyuncu adı"
	name_edit.max_length=20
	name_edit.custom_minimum_size.y=48
	content.add_child(name_edit)
	var address=LineEdit.new()
	address.text=ip_address
	address.placeholder_text="192.168.1.10 veya Radmin IP'si"
	address.custom_minimum_size.y=48
	content.add_child(address)
	content.add_child(_button("Odaya katıl  →",func():player_name=name_edit.text.strip_edges();ip_address=address.text.strip_edges();_join(),true))
	content.add_child(_label("Port: %d / UDP"%port,12,MUTED))

func _disconnect() -> void:
	if connected or connecting:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	connected=false
	connecting=false
	names.clear()
	inputs.clear()
	input_times.clear()

func _leave() -> void:
	for device in Input.get_connected_joypads(): haptics.stop(device)
	_disconnect()
	message=""
	_show_menu()

func _host() -> void:
	_disconnect()
	var peer=ENetMultiplayerPeer.new()
	var err=peer.create_server(port,3,3)
	if err!=OK:
		message="Oda açılamadı. Port kullanımda olabilir."
		_show_menu()
		return
	multiplayer.multiplayer_peer=peer
	connected=true
	mode="lan"
	names[1]=_safe_name(player_name)
	_show_lobby()

func _join() -> void:
	_disconnect()
	if not ip_address.is_valid_ip_address() or port<1024 or port>65535:
		message="Geçerli bir IP adresi yaz."
		_show_menu()
		return
	var peer=ENetMultiplayerPeer.new()
	var err=peer.create_client(ip_address,port,3)
	if err!=OK:
		message="Bağlantı başlatılamadı. IP adresini kontrol et."
		_show_menu()
		return
	multiplayer.multiplayer_peer=peer
	connecting=true
	connect_clock=0
	mode="lan"
	_clear()
	screen="connecting"
	var content=_page()
	_header(content,"Bağlanıyor")
	_spacer(content,true)
	content.add_child(_label("Arkadaşının odası aranıyor…",32))
	content.add_child(_label(ip_address+"  ·  Aynı ağa bağlı olduğunuzdan emin olun.",18,MUTED))
	content.add_child(_button("Vazgeç",_leave))
	_spacer(content,true)

func _safe_name(value: String) -> String:
	var clean=value.strip_edges().replace("\n"," ").replace("\r"," ").substr(0,20)
	return "Oyuncu" if clean.is_empty() else clean

func _connected_ok() -> void:
	connecting=false
	connected=true
	register.rpc_id(1,_safe_name(player_name),VERSION)

@rpc("any_peer","call_remote","reliable")
func register(value: String, version: String) -> void:
	if not connected or not multiplayer.is_server(): return
	var peer_id=multiplayer.get_remote_sender_id()
	if screen!="lobby" or names.size()>=4 or version!=VERSION:
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		return
	names[peer_id]=_safe_name(value)
	player_count=maxi(player_count,names.size())
	_sync_lobby()
	print("REGISTERED ",peer_id," ",names[peer_id])

func _sync_lobby() -> void:
	set_lobby.rpc(names,player_count,selected,tournament)

@rpc("authority","call_local","reliable")
func set_lobby(new_names: Dictionary, count: int, game: int, cup: bool) -> void:
	names=new_names
	player_count=count
	selected=game
	tournament=cup
	_show_lobby()

func _show_lobby() -> void:
	screen="lobby"
	_clear()
	var box=_page()
	_header(box,"LAN oyun odası")
	box.add_child(_label("Ekip tamam mı?",40))
	var host=multiplayer.is_server()
	var addresses: Array = []
	if host:
		for address in IP.get_local_addresses():
			if address.is_valid_ip_address() and not ":" in address and not address.begins_with("127.") and not address.begins_with("169.254."): addresses.append(address)
	box.add_child(_label("Arkadaşlarına bu IP'yi gönder: "+", ".join(addresses) if host else "Odaya bağlandın. Oda sahibi oyunu başlatacak.",17,MINT))
	box.add_child(_label("Wi-Fi / LAN / Radmin  ·  UDP %d  ·  %d kişi bağlı"%[port,names.size()],13,MUTED))
	var players=HBoxContainer.new()
	players.add_theme_constant_override("separation",16)
	players.size_flags_vertical=Control.SIZE_EXPAND_FILL
	box.add_child(players)
	var ids: Array = names.keys()
	ids.sort()
	for i in range(player_count):
		var panel=PanelContainer.new()
		panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel",_style(PANEL,20,Sim.COLORS[i]))
		players.add_child(panel)
		var v=VBoxContainer.new()
		panel.add_child(v)
		_spacer(v,true)
		v.add_child(_label("P%d"%(i+1),52,Sim.COLORS[i]))
		v.add_child(_label(names[ids[i]] if i<ids.size() else "Arena Botu",22))
		v.add_child(_label("HAZIR" if i<ids.size() else "BOT İLE TAMAMLANIR",11,MUTED))
		_spacer(v,true)
	var choices=HBoxContainer.new()
	choices.add_theme_constant_override("separation",12)
	box.add_child(choices)
	var games=OptionButton.new()
	games.custom_minimum_size=Vector2(260,48)
	for item in Sim.GAMES: games.add_item(item.name)
	games.selected=selected
	games.disabled=not host
	games.item_selected.connect(func(index):selected=index;_sync_lobby())
	choices.add_child(games)
	for n in [2,3,4]:
		var button=_button("%d kişi"%n,func():player_count=n;_sync_lobby(),player_count==n)
		button.disabled=not host or n<names.size()
		choices.add_child(button)
	var cup=CheckButton.new()
	cup.text="3 turluk turnuva"
	cup.button_pressed=tournament
	cup.disabled=not host
	cup.toggled.connect(func(value):tournament=value;_sync_lobby())
	choices.add_child(cup)
	var footer=HBoxContainer.new()
	footer.add_theme_constant_override("separation",14)
	box.add_child(footer)
	footer.add_child(_button("Odadan ayrıl",_leave))
	_spacer(footer)
	var start=_button("Oyunu başlat  →" if host else "Oda sahibi bekleniyor…",_start_network,true)
	start.disabled=not host
	footer.add_child(start)

func _connection_failed() -> void:
	_disconnect()
	message="Oda bulunamadı. IP, ağ ve güvenlik duvarını kontrol et."
	_show_menu()
	if args.has("smoke-client"): get_tree().quit(1)

func _server_lost() -> void:
	_disconnect()
	message="Oda sahibi bağlantıyı kapattı."
	_show_menu()

func _peer_left(peer_id: int) -> void:
	if not connected or not multiplayer.is_server(): return
	names.erase(peer_id)
	if screen=="lobby": _sync_lobby()
	elif screen in ["play","result"]:
		for p in sim.state.get("players",[]):
			if p.peer==peer_id: p.bot=true; p.name="Arena Botu"
		for p in roster:
			if p.peer==peer_id: p.bot=true; p.name="Arena Botu"
		print("DISCONNECTED_BOT_REPLACED ",peer_id)

func _make_rounds() -> void:
	rounds=[selected]
	if tournament:
		var options: Array = range(6)
		options.erase(selected)
		options.shuffle()
		rounds.append(options[0])
		rounds.append(options[1])
	round_index=0
	standings=[]
	for i in range(player_count): standings.append(0)

func _start_offline() -> void:
	_disconnect()
	_make_rounds()
	roster=[]
	if mode!="local": device_slots=[_primary_device()]
	for i in range(player_count): roster.append({"name":_safe_name(player_name) if i==0 else ("Oyuncu %d"%(i+1) if mode=="local" and i<device_slots.size() else "Arena Botu %d"%i),"peer":1 if i==0 else -i,"bot":i>=device_slots.size()})
	_begin_round()

func _start_network() -> void:
	if not connected or not multiplayer.is_server(): return
	_make_rounds()
	device_slots=[_primary_device()]
	roster=[]
	var ids: Array = names.keys()
	ids.sort()
	for i in range(player_count): roster.append({"name":names[ids[i]] if i<ids.size() else "Arena Botu %d"%(i+1),"peer":ids[i] if i<ids.size() else -i-1,"bot":i>=ids.size()})
	_begin_round()

func _begin_round() -> void:
	var seed_value=randi()
	if connected:
		multiplayer.multiplayer_peer.refuse_new_connections=true
		begin_match.rpc(rounds[round_index],roster,seed_value,round_index,rounds.size())
	else: begin_match(rounds[round_index],roster,seed_value,round_index,rounds.size())

@rpc("authority","call_local","reliable")
func begin_match(game: int, new_roster: Array, seed_value: int, index: int, total: int) -> void:
	selected=game
	roster=new_roster
	round_index=index
	if connected and not multiplayer.is_server(): rounds.resize(total)
	sim.difficulty=difficulty
	sim.begin(game,roster,seed_value,2.0 if args.has("smoke-host") else -1.0)
	inputs.clear()
	input_times.clear()
	last_event=0
	vibration_state.clear()
	if connected and not multiplayer.is_server(): device_slots=[_primary_device()]
	_show_game()
	print("MATCH_STARTED ",game," PLAYERS ",roster.size())

func _show_game() -> void:
	screen="play"
	_clear()
	if selected<3:
		arena=View3D.new()
		visual.add_child(arena)
		arena.setup(selected,roster.size())
	else:
		arena=View2D.new()
		visual.add_child(arena)
		arena.state=sim.state
	pads=Controls.new()
	pads.local_mode=mode=="local"
	pads.slots=[]
	pads.devices=device_slots.duplicate()
	pads.deadzone=deadzone
	pads.hybrid=mode!="local" and primary_source==0
	for i in range(roster.size()):
		if (not connected and not roster[i].bot) or (connected and roster[i].peer==multiplayer.get_unique_id()): pads.slots.append(i)
	ui.add_child(pads)
	var page=_page()
	var bar=HBoxContainer.new()
	bar.add_theme_constant_override("separation",16)
	page.add_child(bar)
	bar.add_child(_button("←  Çık",_leave))
	game_title=_label(Sim.GAMES[selected].name,26)
	bar.add_child(game_title)
	bar.add_child(_label("TUR %d / %d"%[round_index+1,rounds.size()],12,MUTED))
	_spacer(bar)
	clock_label=_label("00:45",28,MINT)
	bar.add_child(clock_label)
	var score_row=HBoxContainer.new()
	score_row.add_theme_constant_override("separation",10)
	page.add_child(score_row)
	for i in range(roster.size()):
		var panel=PanelContainer.new()
		panel.add_theme_stylebox_override("panel",_style(Color(0.05,0.08,0.15,0.88),10,Color(Sim.COLORS[i],0.45)))
		panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		score_row.add_child(panel)
		var label=_label("",15,Sim.COLORS[i])
		panel.add_child(label)
		scores.append(label)
	_spacer(page,true)
	var instructions=_label(Sim.GAMES[selected].rule,14,MUTED)
	instructions.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	instructions.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	page.add_child(instructions)
	hint=_label("Hareket: sol çubuk / WASD / Joystick  ·  Hamle: A / × / Boşluk",12,MUTED)
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(hint)
	if selected==1:
		target_chip=PanelContainer.new()
		target_chip.position=Vector2(500,160)
		target_chip.custom_minimum_size=Vector2(280,52)
		ui.add_child(target_chip)
		target_chip.add_child(_label("",20,INK))
	var countdown=_label("",72,WHITE)
	countdown.name="Countdown"
	countdown.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	countdown.grow_horizontal=Control.GROW_DIRECTION_BOTH
	countdown.grow_vertical=Control.GROW_DIRECTION_BOTH
	ui.add_child(countdown)

func _physics_process(dt: float) -> void:
	auto_clock+=dt
	if connecting:
		connect_clock+=dt
		if connect_clock>10: _connection_failed()
	if args.has("smoke-host") and screen=="lobby" and names.size()==4 and not smoke_started:
		smoke_started=true
		_start_network()
	if args.has("exit-after") and auto_clock>float(args["exit-after"]):
		print("SMOKE_CLIENT_FRAMES ",network_frames)
		get_tree().quit(0 if network_frames>10 else 1)
	if screen!="play" or pads==null: return
	var local_inputs: Dictionary = {}
	for n in range(pads.slots.size()):
		local_inputs[pads.slots[n]]=pads.read(n)
		if selected<3: local_inputs[pads.slots[n]].axis=local_inputs[pads.slots[n]].axis.rotated(-atan2(9.0,12.0))
		if demo or args.has("smoke-host") or args.has("smoke-client"):
			local_inputs[pads.slots[n]]={"axis":Vector2(sin(auto_clock*2),cos(auto_clock*1.5)),"action":fmod(auto_clock,2.5)<0.15}
	if connected and not multiplayer.is_server():
		client_input_clock+=dt
		if client_input_clock>=0.04 and not local_inputs.is_empty():
			client_input_clock=0
			var input: Dictionary = local_inputs.values()[0]
			submit_input.rpc_id(1,input.axis,input.action)
	else:
		inputs.merge(local_inputs,true)
		for slot in input_times.keys():
			if Time.get_ticks_msec()-input_times[slot]>450: inputs[slot]={"axis":Vector2.ZERO,"action":false}
		# Three seconds to read the rule, with movement paused on every device.
		if not sim.state.has("countdown"): sim.state.countdown=0.0 if args.has("smoke-host") or demo else 3.0
		if sim.state.countdown>0: sim.state.countdown=maxf(0,sim.state.countdown-dt)
		else: sim.step(dt,inputs)
		packet_clock+=dt
		if connected and packet_clock>=0.05:
			packet_clock=0
			receive_snapshot.rpc(var_to_bytes(sim.state).compress(FileAccess.COMPRESSION_DEFLATE))
		if sim.state.phase=="result": _finish_round()

@rpc("any_peer","call_remote","unreliable_ordered",1)
func submit_input(axis: Vector2, action: bool) -> void:
	if not connected or not multiplayer.is_server() or screen!="play": return
	if not is_finite(axis.x) or not is_finite(axis.y): return
	var sender=multiplayer.get_remote_sender_id()
	for i in range(roster.size()):
		if roster[i].peer==sender and not roster[i].bot:
			inputs[i]={"axis":axis.limit_length(1),"action":action}
			input_times[i]=Time.get_ticks_msec()

@rpc("authority","call_remote","unreliable_ordered",2)
func receive_snapshot(packet: PackedByteArray) -> void:
	if screen!="play": return
	var decoded=bytes_to_var(packet.decompress_dynamic(65536,FileAccess.COMPRESSION_DEFLATE))
	if not decoded is Dictionary: return
	if decoded.get("seed",-1)!=sim.state.get("seed",-2): return
	sim.state=decoded
	network_frames+=1

func _process(dt: float) -> void:
	if screen!="play" or sim.state.is_empty() or arena==null: return
	if selected<3: arena.update_state(sim.state,dt)
	else: arena.state=sim.state
	var remaining: int = maxi(0,int(ceil(sim.state.duration-sim.state.time)))
	clock_label.text="%02d:%02d"%[remaining/60,remaining%60]
	for i in range(scores.size()):
		var p: Dictionary = sim.state.players[i]
		scores[i].text="P%d  %s  ·  %d"%[i+1,p.name,int(p.score)]
		if pads!=null and i in pads.slots:
			var old: Dictionary = vibration_state.get(i,{"score":p.score,"hurt":p.hurt,"boost":p.boost})
			if p.hurt>old.hurt: _rumble_slot(i,0.55,1.0,0.3)
			elif p.boost>old.boost:
				if selected==4: _rumble_slot(i,0.45,0.65,0.38)
				elif selected==2: _rumble_slot(i,0.65,0.25,0.13)
				elif selected==5: _rumble_slot(i,0.35,0.5,0.22)
				else: _rumble_slot(i,0.5,0.35,0.15)
			elif selected==3 and p.score>old.score: _rumble_slot(i,0.8,0.7,0.4)
			elif selected==0 and p.score>old.score: _rumble_slot(i,0.45,0.2,0.12)
			vibration_state[i]={"score":p.score,"hurt":p.hurt,"boost":p.boost}
	var countdown=ui.get_node_or_null("Countdown")
	if countdown!=null:
		countdown.text=str(int(ceil(sim.state.get("countdown",0)))) if sim.state.get("countdown",0)>0 else ""
	if selected==1 and target_chip!=null:
		var color: Color = Sim.TILES[int(sim.state.target)]
		target_chip.add_theme_stylebox_override("panel",_style(color,12))
		var seconds=4.0-fmod(sim.state.time,6)
		target_chip.get_child(0).text=(["YEŞİLE","MERCANA","MORA","SARIYA"][int(sim.state.target)]+" KOŞ!  "+str(int(ceil(seconds))) if seconds>0 else "GÜVENDE KAL!")
	if sim.state.event!=last_event:
		last_event=sim.state.event
		_play_sound("score")
	if pads!=null and not pads.slots.is_empty():
		var p: Dictionary = sim.state.players[pads.slots[0]]
		hint.text="HAMLE HAZIR  ·  "+_action_label() if p.cool<=0 else "Hamle %.1f sn sonra hazır"%p.cool

func _finish_round() -> void:
	var order=sim.rankings()
	var awards=[5,3,2,1]
	var tied_rank=0
	for position in range(order.size()):
		if position>0 and abs(sim.state.players[order[position]].score-sim.state.players[order[position-1]].score)>0.01: tied_rank=position
		standings[order[position]]+=awards[tied_rank]
	if connected: show_results.rpc(sim.state,standings,round_index,rounds.size())
	else: show_results(sim.state,standings,round_index,rounds.size())
	if args.has("smoke-host"):
		smoke_rounds+=1
		print("SMOKE_ROUND_PASS ",selected," SCORES ",sim.state.players.map(func(p):return p.score))
		if smoke_rounds<6:
			await get_tree().create_timer(0.4).timeout
			selected=smoke_rounds
			rounds=[selected]
			round_index=0
			_begin_round()
		else:
			print("NETWORK_SMOKE_PASS 6 GAMES")
			await get_tree().create_timer(0.5).timeout
			get_tree().quit(0)

@rpc("authority","call_local","reliable")
func show_results(value: Dictionary, totals: Array, index: int, total: int) -> void:
	sim.state=value
	standings=totals
	round_index=index
	screen="result"
	_play_sound("finish")
	stats.matches+=1
	var order=sim.rankings()
	if pads!=null:
		for slot in pads.slots:
			var won=abs(sim.state.players[slot].score-sim.state.players[order[0]].score)<0.01
			_rumble_slot(slot,0.75 if won else 0.3,0.85 if won else 0.4,0.65 if won else 0.28)
	for winner in order:
		if abs(sim.state.players[winner].score-sim.state.players[order[0]].score)<0.01 and roster[winner].peer==(multiplayer.get_unique_id() if connected else 1): stats.wins+=1
	_save_settings()
	_clear()
	var box=_page()
	_header(box,"Sonuçlar")
	var winners: Array = []
	for winner in order:
		if abs(sim.state.players[winner].score-sim.state.players[order[0]].score)<0.01: winners.append(sim.state.players[winner].name)
	box.add_child(_label("Tur berabere!" if winners.size()>1 else "Turun yıldızı: "+winners[0],38,MINT))
	box.add_child(_label(Sim.GAMES[selected].name+"  ·  Tur %d / %d"%[index+1,total],17,MUTED))
	var rankings=HBoxContainer.new()
	rankings.add_theme_constant_override("separation",14)
	rankings.size_flags_vertical=Control.SIZE_EXPAND_FILL
	box.add_child(rankings)
	var final_cup: bool = total>1 and index+1==total
	var display_order=order.duplicate()
	if final_cup: display_order.sort_custom(func(a,b):return standings[a]>standings[b])
	var same_rank=0
	for rank in range(display_order.size()):
		var i: int = display_order[rank]
		if rank>0:
			var previous: int = display_order[rank-1]
			if (standings[i]!=standings[previous] if final_cup else abs(sim.state.players[i].score-sim.state.players[previous].score)>0.01): same_rank=rank
		var panel=PanelContainer.new()
		panel.add_theme_stylebox_override("panel",_style(PANEL,20,Sim.COLORS[i]))
		panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		rankings.add_child(panel)
		var v=VBoxContainer.new()
		panel.add_child(v)
		_spacer(v,true)
		v.add_child(_label("#%d"%(same_rank+1),50,Sim.COLORS[i]))
		v.add_child(_label(sim.state.players[i].name,21))
		v.add_child(_label("%d puan"%int(sim.state.players[i].score),24,WHITE))
		if total>1: v.add_child(_label("Turnuva: %d yıldız"%standings[i],16,MINT))
		_spacer(v,true)
	if final_cup:
		var champions: Array = []
		for i in display_order:
			if standings[i]==standings[display_order[0]]: champions.append(sim.state.players[i].name)
		box.add_child(_label("TURNUVA ŞAMPİYONU: "+", ".join(champions),23,MINT))
	var footer=HBoxContainer.new()
	footer.add_theme_constant_override("separation",14)
	box.add_child(footer)
	footer.add_child(_button("Ana menü",_leave))
	_spacer(footer)
	var host: bool = not connected or multiplayer.is_server()
	if index+1<total:
		var next=_button("Sonraki tur  →" if host else "Sonraki tur bekleniyor…",func():round_index+=1;_begin_round(),true)
		next.disabled=not host
		footer.add_child(next)
	else:
		var again=_button("Odaya dön" if connected else "Tekrar oyna  →",func():
			if connected:
				multiplayer.multiplayer_peer.refuse_new_connections=false
				_sync_lobby()
			else: _start_offline(),true)
		again.disabled=not host
		footer.add_child(again)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_F11: _fullscreen()
		elif event.keycode==KEY_ESCAPE:
			var children=ui.get_children()
			children.reverse()
			for child in children:
				if child is ColorRect:
					child.queue_free()
					return
			if screen in ["play","lobby","result","connecting"]: _leave()

func _play_sound(which: String) -> void:
	if not sound or DisplayServer.get_name()=="headless" or args.has("capture"): return
	sfx.stream=load("res://assets/%s.wav"%which)
	sfx.play()

func _load_settings() -> void:
	var config=ConfigFile.new()
	if config.load("user://settings.cfg")!=OK: return
	player_name=_safe_name(str(config.get_value("player","name","Oyuncu")))
	sound=bool(config.get_value("audio","enabled",true))
	difficulty=clampi(int(config.get_value("bots","difficulty",1)),0,2)
	rumble_enabled=bool(config.get_value("gamepad","rumble",true))
	rumble_strength=clampf(float(config.get_value("gamepad","strength",0.65)),0,1)
	pad_layout=clampi(int(config.get_value("gamepad","layout",0)),0,2)
	deadzone=clampf(float(config.get_value("gamepad","deadzone",0.18)),0.05,0.4)
	primary_source=maxi(0,int(config.get_value("gamepad","source",0)))
	stats.matches=maxi(0,int(config.get_value("stats","matches",0)))
	stats.wins=maxi(0,int(config.get_value("stats","wins",0)))

func _save_settings() -> void:
	if args.has("smoke-host") or args.has("smoke-client") or args.has("demo"): return
	var config=ConfigFile.new()
	config.set_value("player","name",player_name)
	config.set_value("audio","enabled",sound)
	config.set_value("bots","difficulty",difficulty)
	config.set_value("gamepad","rumble",rumble_enabled)
	config.set_value("gamepad","strength",rumble_strength)
	config.set_value("gamepad","layout",pad_layout)
	config.set_value("gamepad","deadzone",deadzone)
	config.set_value("gamepad","source",primary_source)
	config.set_value("stats","matches",stats.matches)
	config.set_value("stats","wins",stats.wins)
	config.save("user://settings.cfg")

func _exit_tree() -> void:
	if sfx!=null:
		sfx.stop()
		sfx.stream=null
	for device in Input.get_connected_joypads(): Input.stop_joy_vibration(device)
