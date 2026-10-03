extends RefCounted
const Arcade=preload("res://scripts/arcade_rules.gd")
var arcade=Arcade.new()
const Bomber=preload("res://scripts/bomber_rules.gd")
## The host runs all game rules. Clients send bounded input, never positions or scores.

const GAMES = preload("res://scripts/catalog.gd").GAMES
const COLORS = [Color("80f5cd"),Color("ff846b"),Color("b6a1ff"),Color("78caff")]
const TILES = [Color("80f5cd"),Color("ff846b"),Color("b6a1ff"),Color("ffcf70")]
var state: Dictionary = {}
var rng = RandomNumberGenerator.new()
var difficulty := 1

func begin(game_id: int, roster: Array, seed_value: int, duration := -1.0) -> void:
	rng.seed = seed_value
	state = {"game":game_id,"time":0.0,"duration":GAMES[game_id].duration if duration < 0 else duration,"phase":"play","players":[],"items":[],"hazards":[],"puck":Vector2.ZERO,"puck_v":Vector2(0.42,0.65),"last_hit":-1,"target":rng.randi_range(0,3),"cycle":-1,"seed":seed_value,"event":0}
	for i in range(roster.size()):
		var angle = TAU * float(i)/roster.size() - PI/2
		state.players.append({"name":roster[i].name,"peer":roster[i].peer,"bot":roster[i].bot,"p":Vector2(cos(angle),sin(angle))*0.57,"v":Vector2.ZERO,"score":0.0,"cool":0.0,"boost":0.0,"hurt":0.0,"progress":0.0,"action_held":false,"jump_buffer":0.0})
	if game_id == 0:
		for i in range(10): state.items.append(_point(0.78))
	elif game_id == 1:
		for i in range(36): state.items.append((i+i/6)%4)
	elif game_id == 4:
		for i in range(36): state.hazards.append({"p":Vector2(rng.randf_range(-0.78,0.78),3.0+i*2.1),"size":rng.randf_range(0.13,0.22)})
	elif game_id == 6:
		state.walls=[];state.crates=[];state.bombs=[];state.flames=[]
		for x in range(9):
			for y in range(9):
				var at=Vector2i(x,y)
				if x%2==1 and y%2==1: state.walls.append(at)
				elif not Bomber.SPAWNS.any(func(s):return abs(s.x-x)+abs(s.y-y)<=2) and rng.randf()<0.48: state.crates.append(at)
		for i in range(state.players.size()):
			state.players[i].p=Bomber.position(Bomber.SPAWNS[i])
			state.players[i].ai_clock=0.0
			state.players[i].ai_target=Bomber.SPAWNS[i]
			state.players[i].ai_action=false

	elif game_id>=7: arcade.begin(state,rng)

func _point(radius: float) -> Vector2:
	return Vector2(rng.randf_range(-radius,radius),rng.randf_range(-radius,radius))

func bot_input(i: int) -> Dictionary:
	if state.game>=7:
		arcade.s=state;arcade.rng=rng;arcade.level=difficulty
		return arcade.bot_input(i)
	if state.game==6: return _bomber_bot(i)
	var p: Dictionary = state.players[i]
	var target: Vector2 = Vector2.ZERO
	var action := false
	match int(state.game):
		0:
			var nearest := 9.0
			for gem in state.items:
				var distance: float = p.p.distance_to(gem)
				if distance < nearest:
					nearest = distance
					target = gem
			action = nearest > 0.25
		1:
			var nearest := 9.0
			for tile in range(36):
				if int(state.items[tile]) != int(state.target): continue
				var center = Vector2(-0.75+float(tile%6)*0.3,-0.75+float(tile/6)*0.3)
				var distance: float = p.p.distance_to(center)
				if distance < nearest:
					nearest = distance
					target = center
			action = fmod(state.time,6.0)>2.4 and nearest > 0.25
		2:
			target = Vector2(cos(i*TAU/4),sin(i*TAU/4))*0.66
			var angle: float = beam_angle(state.time+0.12)
			var difference: float = abs(wrapf(p.p.angle()-angle,-PI/2,PI/2))
			action = difference < (0.28 if difficulty > 0 else 0.15)
		3:
			var goal = _goal(i)
			target = goal.lerp(state.puck,0.62) if state.puck.dot(goal)>0.15 else state.puck
			action = p.p.distance_to(state.puck)<0.23
		4:
			target = Vector2(p.p.x,0)
			for hazard in state.hazards:
				if hazard.p.y-p.progress>0 and hazard.p.y-p.progress<2.0 and abs(hazard.p.x-p.p.x)<hazard.size+0.15:
					target.x = clampf(hazard.p.x + (0.4 if hazard.p.x < p.p.x else -0.4),-0.8,0.8)
					break
			action = true
		5:
			target = p.p*0.98
			for hazard in state.hazards:
				var future: Vector2 = hazard.p+hazard.v*(0.28 if difficulty>0 else 0.1)
				if future.distance_to(p.p)<0.25:
					target += (p.p-future).normalized()*0.5
					action = future.distance_to(p.p)<0.16
	var axis: Vector2 = (target-p.p)*5
	if difficulty == 0: axis *= 0.68
	if difficulty == 2: axis *= 1.1
	# Bots release their action between cooldowns, just as a human presses a button.
	return {"axis":axis.limit_length(1.0),"action":action and not p.action_held}

func step(dt: float, inputs: Dictionary) -> void:
	if state.is_empty() or state.phase != "play": return
	state.time += dt
	var game_id: int = state.game
	if game_id>=7:
		arcade.step(state,dt,inputs,rng,difficulty)
		if state.time>=state.duration: state.time=state.duration;state.phase="result"
		return
	if game_id==6:
		_step_bomber(dt,inputs)
		if state.time>=state.duration: state.time=state.duration;state.phase="result"
		return
	for i in range(state.players.size()):
		var p: Dictionary = state.players[i]
		var input: Dictionary = bot_input(i) if p.bot else inputs.get(i,{"axis":Vector2.ZERO,"action":false})
		var axis: Vector2 = input.get("axis",Vector2.ZERO)
		if not is_finite(axis.x) or not is_finite(axis.y): axis = Vector2.ZERO
		axis = axis.limit_length(1.0)
		p.cool = maxf(0,p.cool-dt)
		p.boost = maxf(0,p.boost-dt)
		p.hurt = maxf(0,p.hurt-dt)
		var pressed: bool = input.get("action",false)
		if game_id==2:
			p.jump_buffer=maxf(0,p.jump_buffer-dt)
			if pressed: p.jump_buffer=0.16
		if (pressed and not p.action_held or game_id==2 and p.jump_buffer>0) and p.cool <= 0:
			p.boost = 0.88 if game_id==2 else 0.55
			p.cool = 0.94 if game_id==2 else 2.3
			p.jump_buffer=0.0
			state.event += 1
		p.action_held = pressed
		var speed := 0.62 if p.boost <= 0 else 1.15
		if game_id == 2: speed = 0.58
		if game_id == 4:
			p.p.x = clampf(p.p.x+axis.x*dt*1.2,-0.84,0.84)
			p.progress += dt*(1.8 if p.boost <= 0 else 3.7)
			for hazard in state.hazards:
				if abs(hazard.p.y-p.progress)<0.22 and abs(hazard.p.x-p.p.x)<hazard.size+0.09 and p.hurt<=0:
					p.progress -= 1.15
					p.hurt = 1.0
			p.score = p.progress
		else:
			p.v = axis*speed
			p.p += p.v*dt
			p.p = Vector2(clampf(p.p.x,-0.88,0.88),clampf(p.p.y,-0.88,0.88))
			if game_id in [2,3] and p.p.length()>0.81: p.p=p.p.normalized()*0.81
			if game_id == 0:
				for j in range(state.items.size()):
					if p.p.distance_to(state.items[j])<0.115:
						p.score += 1
						state.items[j] = _point(0.78)
						state.event += 1
			elif game_id == 1:
				p.score += dt
				if fmod(state.time,6.0) >= 4.0 and p.hurt<=0:
					var tile_x = clampi(int(floor((p.p.x+0.9)/0.3)),0,5)
					var tile_y = clampi(int(floor((p.p.y+0.9)/0.3)),0,5)
					if int(state.items[tile_y*6+tile_x]) != int(state.target):
						_hit(p,3.0)
						p.p = _safe_tile()
			elif game_id == 2:
				p.score += dt
				var angle: float = beam_angle(state.time)
				var ray = Vector2(cos(angle),sin(angle))
				var jump_height=sin((1.0-p.boost/0.88)*PI) if p.boost>0 else 0.0
				if state.time>2.0 and p.p.length()>0.15 and abs(p.p.cross(ray))<0.06 and p.boost<0.82 and jump_height<0.18 and p.hurt<=0:
					_hit(p,3.0)
			elif game_id == 3:
				if p.p.distance_to(state.puck)<0.16:
					var away: Vector2 = (state.puck-p.p).normalized()
					if away == Vector2.ZERO: away = -_goal(i)
					state.puck_v = away*(1.65 if p.boost>0 else 0.95)+p.v*0.35
					state.puck = p.p+away*0.17
					state.last_hit = i
			elif game_id == 5:
				p.score += dt
				for hazard in state.hazards:
					if p.p.distance_to(hazard.p)<0.105+hazard.size and p.boost<=0 and p.hurt<=0:
						_hit(p,4.0)
	if game_id != 4:
		for i in range(state.players.size()):
			for j in range(i+1,state.players.size()):
				var a: Dictionary = state.players[i]
				var b: Dictionary = state.players[j]
				var difference: Vector2 = a.p-b.p
				var distance: float = difference.length()
				if distance<0.135:
					var push = difference.normalized()*(0.135-distance)*0.5 if distance>0.001 else Vector2(0.02,0)
					a.p += push
					b.p -= push
	if game_id == 1:
		var cycle: int = int(state.time/6.0)
		if cycle!=state.cycle:
			state.cycle=cycle
			state.target=rng.randi_range(0,3)
	elif game_id == 3:
		state.puck += state.puck_v*dt
		state.puck_v *= pow(0.993,dt*60)
		if state.puck_v.length()<0.35: state.puck_v=state.puck_v.normalized()*0.35
		if state.puck.length()>0.9:
			var goal_i = 0
			var best := -2.0
			for i in range(state.players.size()):
				var alignment: float = state.puck.normalized().dot(_goal(i))
				if alignment > best:
					best=alignment
					goal_i=i
			if best>0.94:
				state.players[goal_i].score-=1
				if state.last_hit>=0 and state.last_hit!=goal_i: state.players[state.last_hit].score+=2
				state.puck=Vector2.ZERO
				state.puck_v=_point(1).normalized()*0.65
				state.last_hit=-1
				state.event+=1
			else:
				state.puck=state.puck.normalized()*0.89
				state.puck_v=state.puck_v.bounce(state.puck.normalized())
	elif game_id == 5:
		if int(state.time*3)>int((state.time-dt)*3):
			var side: int = rng.randi_range(0,3)
			var position = _point(0.8)
			if side==0: position.x=-1.15
			elif side==1: position.x=1.15
			elif side==2: position.y=-1.15
			else: position.y=1.15
			state.hazards.append({"p":position,"v":(_point(0.6)-position).normalized()*(0.34+state.time*0.009),"size":rng.randf_range(0.035,0.075)})
		for hazard in state.hazards: hazard.p+=hazard.v*dt
		state.hazards=state.hazards.filter(func(h):return abs(h.p.x)<1.35 and abs(h.p.y)<1.35)
	if state.time>=state.duration:
		state.time=state.duration
		state.phase="result"

static func beam_angle(seconds: float) -> float:
	return maxf(0,seconds-2.0)*0.85+pow(maxf(0,seconds-2.0),2)*0.003

func _goal(i: int) -> Vector2:
	var angle = TAU*float(i)/state.players.size()-PI/2
	return Vector2(cos(angle),sin(angle))

func _safe_tile() -> Vector2:
	for tile in range(36):
		if int(state.items[tile])==int(state.target): return Vector2(-0.75+float(tile%6)*0.3,-0.75+float(tile/6)*0.3)
	return Vector2.ZERO

func _hit(p: Dictionary, penalty: float) -> void:
	p.score -= penalty
	p.hurt=1.15
	state.event+=1

func _bomber_bot(i: int) -> Dictionary:
	var p: Dictionary=state.players[i]
	if p.ai_clock>0: return _bomber_drive(p,p.ai_target,p.ai_action)
	var current=Bomber.cell(p.p)
	var danger: Array=[]
	var blocked: Array=state.walls+state.crates
	for bomb in state.bombs:
		blocked.append(bomb.cell)
		danger.append_array(Bomber.blast(bomb.cell,state.walls,state.crates))
	for flame in state.flames: danger.append(flame.cell)
	var goal=current
	var best_cost=INF
	var path: Array=[]
	if current in danger:
		for x in range(9):
			for y in range(9):
				var candidate=Vector2i(x,y)
				if candidate in danger or candidate in blocked: continue
				var route=Bomber.route(current,candidate,blocked)
				if route.size()>0 and route.size()<best_cost: best_cost=route.size();path=route
	else:
		for target in state.players:
			if target==p: continue
			var route=Bomber.route(current,Bomber.cell(target.p),blocked+danger)
			if route.size()>0 and route.size()<best_cost: best_cost=route.size();path=route
		if path.is_empty():
			for crate in state.crates:
				for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					var candidate: Vector2i=crate+direction
					if not Bomber.inside(candidate) or candidate in blocked or candidate in danger: continue
					var route=Bomber.route(current,candidate,blocked+danger)
					if route.size()>0 and route.size()<best_cost: best_cost=route.size();path=route
	if path.size()>1: goal=path[1]
	var useful=false
	var blast=Bomber.blast(current,state.walls,state.crates)
	for crate in state.crates:
		if crate in blast: useful=true
	for j in range(state.players.size()):
		if j!=i and Bomber.cell(state.players[j].p) in blast: useful=true
	# Never place a bomb without a reachable refuge outside its cross.
	var refuge=false
	if useful and p.cool<=0 and current not in danger:
		for x in range(9):
			for y in range(9):
				var at=Vector2i(x,y)
				if at in blast or at in blocked or at in danger: continue
				var route=Bomber.route(current,at,blocked+danger)
				if route.size()>1 and route.size()<7: refuge=true;break
			if refuge: break
	p.ai_clock=[0.3,0.18,0.12][difficulty];p.ai_target=goal;p.ai_action=useful and refuge
	return _bomber_drive(p,goal,p.ai_action)

func _bomber_drive(p: Dictionary, goal: Vector2i, action: bool) -> Dictionary:
	var current=Bomber.cell(p.p)
	var target=Bomber.position(goal)
	var center=Bomber.position(current)
	if goal.x!=current.x and abs(p.p.y-center.y)>0.02: target=Vector2(p.p.x,center.y)
	elif goal.y!=current.y and abs(p.p.x-center.x)>0.02: target=Vector2(center.x,p.p.y)
	return {"axis":((target-p.p)*8).limit_length(1)*[0.72,0.93,1.0][difficulty],"action":action and p.cool<=0 and not p.action_held}

func _bomber_open(position_value: Vector2, old: Vector2) -> bool:
	for at in state.walls+state.crates:
		var delta: Vector2=(position_value-Bomber.position(at)).abs()
		if delta.x<0.155 and delta.y<0.155: return false
	for bomb in state.bombs:
		if Bomber.cell(old)==bomb.cell: continue
		var center=Bomber.position(bomb.cell)
		if old.distance_to(center)<0.2 and position_value.distance_to(center)>=old.distance_to(center): continue
		var delta: Vector2=(position_value-Bomber.position(bomb.cell)).abs()
		if delta.x<0.145 and delta.y<0.145: return false
	return true

func _step_bomber(dt: float, inputs: Dictionary) -> void:
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i]
		p.cool=maxf(0,p.cool-dt);p.hurt=maxf(0,p.hurt-dt);p.boost=maxf(0,p.boost-dt)
		p.ai_clock=maxf(0,p.ai_clock-dt)
		var input: Dictionary=_bomber_bot(i) if p.bot else inputs.get(i,{})
		var axis: Vector2=input.get("axis",Vector2.ZERO)
		if not is_finite(axis.x) or not is_finite(axis.y): axis=Vector2.ZERO
		axis=axis.limit_length(1)
		p.v=axis*0.82
		for coordinate in range(2):
			var target: Vector2=p.p
			target[coordinate]=clampf(target[coordinate]+p.v[coordinate]*dt,-0.8,0.8)
			if _bomber_open(target,p.p): p.p=target
		var pressed: bool=input.get("action",false)
		var cell=Bomber.cell(p.p)
		if pressed and not p.action_held and p.cool<=0 and not state.bombs.any(func(b):return b.cell==cell) and state.bombs.filter(func(b):return b.owner==i).size()<2:
			state.bombs.append({"cell":cell,"owner":i,"timer":2.0})
			p.cool=2.4;p.boost=0.3;state.event+=1
		p.action_held=pressed
	for flame in state.flames: flame.life-=dt
	state.flames=state.flames.filter(func(f):return f.life>0)
	for bomb in state.bombs: bomb.timer-=dt
	var expired=state.bombs.filter(func(b):return b.timer<=0)
	for bomb in expired:
		state.bombs.erase(bomb)
		var blast=Bomber.blast(bomb.cell,state.walls,state.crates)
		for at in blast:
			state.flames.append({"cell":at,"owner":bomb.owner,"life":0.45})
			if at in state.crates: state.crates.erase(at);state.players[bomb.owner].score+=1
			for other in state.bombs:
				if other.cell==at: other.timer=minf(other.timer,0.01)
		state.event+=1
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i]
		if p.hurt>0: continue
		for flame in state.flames:
			if Bomber.cell(p.p)==flame.cell:
				p.score-=2;p.hurt=1.3;p.p=Bomber.position(Bomber.SPAWNS[i])
				if flame.owner!=i: state.players[flame.owner].score+=4
				state.event+=1
				break

func rankings() -> Array:
	var order: Array = range(state.players.size())
	order.sort_custom(func(a,b): return state.players[a].score>state.players[b].score)
	return order
