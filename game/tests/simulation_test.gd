extends SceneTree
const Sim=preload("res://scripts/simulation.gd")
const Controls=preload("res://scripts/controls.gd")
var checks=0
var failures=0

func check(condition: bool, description: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL: ",description)

func roster(count: int, bots=false) -> Array:
	var players: Array = []
	for i in range(count): players.append({"name":"Test%d"%i,"peer":i+1,"bot":bots})
	return players

func _initialize() -> void:
	var sim=Sim.new()
	sim.begin(0,roster(2),47)
	sim.state.players[0].p=sim.state.items[0]
	sim.step(1.0/60,{})
	check(sim.state.players[0].score>=1,"Gem collection awards points")
	var p: Dictionary = sim.state.players[0]
	var before: Vector2 = p.p
	sim.step(0.1,{0:{"axis":Vector2(999,0),"action":true}})
	check(p.p.distance_to(before)<0.13,"Input magnitude is clamped")
	check(p.cool>0 and p.boost>0,"Dash activates and starts cooldown")
	var cool: float = p.cool
	sim.step(0.1,{0:{"axis":Vector2.ZERO,"action":true}})
	check(p.cool<cool,"Holding action cannot retrigger cooldown")
	sim.begin(1,roster(2),47)
	sim.state.time=4.1
	sim.state.cycle=0
	sim.state.target=3
	sim.state.players[0].p=Vector2(-0.75,-0.75)
	sim.step(0.01,{})
	check(sim.state.players[0].score<0,"Wrong color penalizes player")
	check(sim.state.players[0].hurt>0,"Color fall grants respawn protection")
	sim.begin(2,roster(2),47)
	sim.state.players[0].p=Vector2(0.5,0)
	sim.step(0.01,{})
	check(sim.state.players[0].score<0,"Beam collision penalizes player")
	sim.begin(2,roster(2),47)
	sim.state.players[0].p=Vector2(0.5,0)
	sim.step(0.01,{0:{"axis":Vector2.ZERO,"action":true}})
	check(sim.state.players[0].score>=0,"Jump avoids beam")
	sim.begin(3,roster(2),47)
	sim.state.puck=Vector2(0,0.93)
	sim.state.puck_v=Vector2(0,0.1)
	sim.state.last_hit=0
	sim.step(0.01,{})
	check(sim.state.players[0].score==2 and sim.state.players[1].score==-1,"Goal credits striker and charges goal owner")
	check(sim.state.puck==Vector2.ZERO,"Puck resets after goal")
	sim.begin(4,roster(2),47)
	sim.state.players[0].p.x=0
	sim.state.hazards=[{"p":Vector2(0,0.1),"size":0.2}]
	sim.step(0.05,{})
	check(sim.state.players[0].hurt>0,"Race obstacle slows ship")
	sim.begin(5,roster(2),47)
	sim.state.players[0].p=Vector2.ZERO
	sim.state.hazards=[{"p":Vector2.ZERO,"v":Vector2.ZERO,"size":0.05}]
	sim.step(0.01,{0:{"axis":Vector2.ZERO,"action":true}})
	check(sim.state.players[0].score>=0,"Shield protects from meteor")
	sim.state.players[0].boost=0
	sim.step(0.01,{})
	check(sim.state.players[0].score<0,"Unshielded meteor hurts")
	for count in [2,3,4]:
		for game in range(6):
			for difficulty in range(3):
				sim.difficulty=difficulty
				sim.begin(game,roster(count,true),1234+game,8.0)
				for tick in range(490): sim.step(1.0/60,{})
				check(sim.state.phase=="result","Game %d / %d players / level %d ends"%[game,count,difficulty])
				check(sim.rankings().size()==count,"Ranking has all players")
				for player in sim.state.players:
					check(is_finite(player.score) and is_finite(player.p.x) and is_finite(player.p.y),"Finite simulation state")
	var controls=Controls.new()
	controls.slots=[0,1,2]
	controls.devices=[-1,101,102]
	controls.size=Vector2(1280,720)
	var key=InputEventKey.new()
	key.physical_keycode=KEY_D
	key.keycode=KEY_D
	key.pressed=true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	check(controls.read(0).axis.x>0,"Keyboard drives its assigned player")
	check(controls.read(1).axis==Vector2.ZERO,"Keyboard never drives another player's gamepad")
	var release=key.duplicate()
	release.pressed=false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	controls.devices=[-1,-1]
	controls.slots=[0,1]
	controls.local_mode=true
	for i in range(2):
		var touch=InputEventScreenTouch.new()
		touch.index=i
		touch.position=controls.centers(i)[0]+Vector2(40 if i==0 else -40,0)
		touch.pressed=true
		controls._input(touch)
	check(controls.read(0).axis.x>0 and controls.read(1).axis.x<0,"Touch IDs remain independent")
	controls.free()
	print("SIMULATION_CHECKS ",checks," FAILURES ",failures)
	quit(0 if failures==0 else 1)
