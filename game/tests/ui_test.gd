extends SceneTree
const Main=preload("res://scripts/main.gd")
var checks=0
var failures=0
var app: Node

func check(condition: bool, label: String) -> void:
	checks+=1
	if not condition: failures+=1;printerr("FAIL: ",label)

func frame() -> void:
	await process_frame
	await process_frame

func press(button: int) -> void:
	var event=InputEventJoypadButton.new()
	event.device=3;event.button_index=button;event.pressed=true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await frame()
	event.pressed=false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await frame()

func by_key(key: String) -> Control:
	var items: Array=[]
	app.navigation.controls(app.ui,items)
	for item in items:
		if str(item.get_meta("nav_key",""))==key: return item
	return null

func shades() -> int:
	var count=0
	for child in app.ui.get_children():
		if child is ColorRect and not child.is_queued_for_deletion(): count+=1
	return count

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.gui_embed_subwindows=true
	app=Main.new()
	app.args={"test-ui":"true"}
	root.add_child(app)
	await frame()
	var first=root.gui_get_focus_owner()
	check(first!=null and first.get_meta("nav_key")=="Botlarla oyna  →","Menu initially focuses Play")
	var motion=InputEventJoypadMotion.new()
	motion.device=3;motion.axis=JOY_AXIS_LEFT_X;motion.axis_value=0.9
	Input.parse_input_event(motion);Input.flush_buffered_events()
	await frame()
	check(root.gui_get_focus_owner()!=first,"Left stick moves visible menu focus")
	motion.axis_value=0
	Input.parse_input_event(motion);Input.flush_buffered_events()
	first.grab_focus()
	await press(JOY_BUTTON_DPAD_RIGHT)
	var choice=root.gui_get_focus_owner()
	check(choice!=null and choice!=first,"D-pad moves visible focus")
	var key=str(choice.get_meta("nav_key",""))
	if key.begins_with("game_"):
		await press(JOY_BUTTON_A)
		check(root.gui_get_focus_owner().get_meta("nav_key")==key,"Selecting a game preserves selection focus")
	var parent_focus=root.gui_get_focus_owner()
	app._settings()
	await frame()
	check(shades()==1,"Settings opens as one modal")
	var toggle=app.ui.find_children("*","CheckButton",true,false).back()
	toggle.grab_focus()
	var value=toggle.button_pressed
	await press(JOY_BUTTON_A)
	check(toggle.button_pressed!=value,"Gamepad A toggles a checkbox")
	app._controller_settings()
	await frame()
	var slider=app.ui.find_children("*","HSlider",true,false).front()
	slider.value=50
	slider.grab_focus()
	await press(JOY_BUTTON_DPAD_RIGHT)
	check(slider.value==51,"D-pad changes slider value")
	var option=app.ui.find_children("*","OptionButton",true,false).back()
	option.select(0)
	option.grab_focus()
	await press(JOY_BUTTON_A)
	check(option.get_popup().visible,"A opens the controller layout menu")
	await press(JOY_BUTTON_DPAD_DOWN)
	await press(JOY_BUTTON_A)
	check(not option.get_popup().visible and option.selected==1,"D-pad and A select a dropdown item")
	await press(JOY_BUTTON_A)
	await press(JOY_BUTTON_B)
	check(not option.get_popup().visible and shades()==2,"B closes a dropdown without closing its modal")
	await press(JOY_BUTTON_B)
	check(shades()==1,"B closes only the top modal")
	check(root.gui_get_focus_owner()==toggle,"Closing nested modal restores previous focus")
	await press(JOY_BUTTON_B)
	check(shades()==0,"B returns to the menu")
	check(root.gui_get_focus_owner()==parent_focus,"Closing settings restores original menu focus")
	app.category="Dövüş";app._show_menu()
	await frame()
	check(by_key("game_7")!=null and by_key("game_8")==null,"Category shows only fighting games")
	app._favorite(7)
	await frame()
	check(7 in app.favorites,"Favorite button records a game")
	app.favorites_only=true;app._show_menu()
	await frame()
	check(by_key("game_7")!=null and by_key("game_9")==null,"Favorites filter excludes unmarked games")
	app.favorites_only=false;app.category="Tümü";app.search_text="Tank";app._show_menu()
	await frame()
	check(by_key("game_8")!=null and by_key("game_11")!=null and by_key("game_0")==null,"Search finds both tank games")
	app.search_text="";app._show_menu()
	await frame()
	by_key("game_31").grab_focus()
	await press(JOY_BUTTON_A)
	check(app.selected==31,"Gamepad reaches the 32nd game and keeps its focus")
	by_key("Botlarla oyna  →").grab_focus()
	await press(JOY_BUTTON_A)
	check(app.screen=="play" and app.sim.state.game==31,"The 32nd game starts real rules")
	await press(JOY_BUTTON_B)
	by_key("game_6").grab_focus()
	await press(JOY_BUTTON_A)
	check(app.selected==6,"Seventh game is selectable by gamepad")
	by_key("Botlarla oyna  →").grab_focus()
	await press(JOY_BUTTON_A)
	check(app.screen=="play","Gamepad A starts a match")
	await press(JOY_BUTTON_START)
	check(app.screen=="menu","Start returns from gameplay to menu")
	by_key("Botlarla oyna  →").grab_focus()
	await press(JOY_BUTTON_A)
	app._system_back()
	await frame()
	check(app.screen=="menu","System Back returns from gameplay to menu")
	by_key("Botlarla oyna  →").grab_focus()
	await press(JOY_BUTTON_A)
	await press(JOY_BUTTON_B)
	check(app.screen=="menu" and not app.connected,"Gamepad B returns from match to main menu")
	app._settings()
	await frame()
	var escape=InputEventKey.new()
	escape.keycode=KEY_ESCAPE;escape.pressed=true
	Input.parse_input_event(escape);Input.flush_buffered_events()
	await frame()
	check(shades()==0,"Escape closes settings and keeps the app open")
	var exit_button=by_key("Çık")
	check(exit_button!=null,"Main menu has an Exit button")
	if OS.get_cmdline_user_args().has("--capture-ui"):
		app._controller_settings()
		await frame()
		app.ui.find_children("*","HSlider",true,false).front().grab_focus()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../qa/controller-menu.png")
		app._back()
		await frame()
	print("UI_CHECKS ",checks," FAILURES ",failures)
	if failures>0: quit(1);return
	# Exercise the actual Exit button and application shutdown as the final action.
	exit_button.grab_focus()
	await press(JOY_BUTTON_A)
	await create_timer(0.25).timeout
	printerr("FAIL: Main menu Exit did not close the app")
	quit(1)
