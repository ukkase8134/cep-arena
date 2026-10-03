extends RefCounted
## Original authoritative rules for the arcade collection. No client can award itself points.
const COLORS=[Color('80f5cd'),Color('ff846b'),Color('b6a1ff'),Color('78caff')]
const DIRS=[Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]
var s: Dictionary
var rng: RandomNumberGenerator
var level=1

func begin(state: Dictionary, random: RandomNumberGenerator) -> void:
	s=state;rng=random
	s.shots=[];s.fx=[];s.walls=[];s.bases=[];s.flags=[];s.balls=[];s.platforms=[];s.tiles=[]
	s.signal=0;s.signal_clock=2.0+rng.randf()*2.0;s.signal_age=0.0;s.sequence=[rng.randi_range(0,3),rng.randi_range(0,3)];s.memory_cycle=0;s.wind=rng.randf_range(-0.18,0.18)
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i]
		p.face=(Vector2.ZERO-p.p).angle();p.hp=100.0;p.guard=0.0;p.stun=0.0;p.attack=0.0;p.combo=0;p.combo_time=0.0;p.impulse=Vector2.ZERO;p.secondary_held=false;p.secondary_cool=0.0;p.attack_buffer=0.0;p.charge=0.0;p.carry=-1;p.bag=0;p.jumps=0;p.ground=true;p.buffer=0.0;p.coyote=0.0;p.platform_target=0;p.best=0.0;p.aim=0.85;p.sign=1.0 if i%2==0 else -1.0;p.shots=0;p.pins=[];p.hole=0;p.strokes=0;p.golf_waypoint=0;p.snake=[];p.snake_dir=Vector2i.RIGHT;p.snake_time=0.0;p.memory_index=0;p.memory_done=false;p.memory_next=0.0;p.axis_held=false;p.reacted=false;p.reaction=-1.0
		s.bases.append(p.p.normalized()*0.83)
	match int(s.game):
		8:
			s.walls=[Rect2(-0.48,-0.22,0.2,0.44),Rect2(0.28,-0.22,0.2,0.44),Rect2(-0.1,-0.62,0.2,0.2),Rect2(-0.1,0.42,0.2,0.2)]
		11:
			for i in range(s.players.size()): s.players[i].p=Vector2(-0.82+i*1.64/(s.players.size()-1),0)
		12:
			for i in range(s.players.size()): s.flags.append({'p':s.bases[i],'owner':i,'carrier':-1})
		15,17:
			s.platforms.append({'p':Vector2(0,0),'width':0.95,'moving':false})
			for i in range(1,65): s.platforms.append({'p':Vector2(sin(i*1.1)*0.54,i*0.31),'width':0.43 if i%4 else 0.52,'moving':i%5==0})
			for p in s.players: p.p=Vector2(0,0);p.v=Vector2.ZERO
		16,18:
			for p in s.players: p.p=Vector2.ZERO;p.v=Vector2.ZERO
			if s.game==16:
				for i in range(100): s.hazards.append({'x':2.5+i*2.2,'high':i%3==2})
		19:
			for i in range(s.players.size()): s.players[i].p=Vector2(-0.6+i*0.4,0.8);s.players[i].cool=0.0
			for row in [1,2,3,5,6,7]:
				for j in range(3): s.hazards.append({'p':Vector2(-1+j*0.8,row),'v':Vector2((0.34+row*0.03)*(1 if row%2 else -1),0),'size':0.13 if row<4 else 0.24})
		20: s.puck=Vector2.ZERO;s.puck_v=Vector2(0.5,0.7);s.last_hit=-1
		21:
			s.puck=Vector2.ZERO;s.puck_v=Vector2.ZERO
			for i in range(s.players.size()): s.players[i].p=Vector2(-0.45 if i%2==0 else 0.45,-0.32 if i<2 else 0.32)
		22,23:
			for p in s.players: p.p=Vector2.ZERO;p.aim=0.0
			if s.game==23:
				for p in s.players: _reset_pins(p)
		24:
			for i in range(s.players.size()):
				s.players[i].p=Vector2(-0.73,-0.4+i*0.25);s.players[i].face=0.0
			s.walls=[Rect2(-0.24,-0.88,0.14,1.15),Rect2(0.22,-0.12,0.14,1.0)]
			s.cup=Vector2(0.73,-0.65)
		25:
			for i in range(s.players.size()):
				var head=Vector2i(3+i*3,3+i*3)
				s.players[i].snake=[head,head-Vector2i.RIGHT,head-Vector2i(2,0)];s.players[i].p=Vector2(head)/7-Vector2.ONE
			for i in range(8): s.items.append(Vector2i(rng.randi_range(1,13),rng.randi_range(1,13)))
		26:
			for p in s.players:
				p.p=Vector2.ZERO;p.ball=Vector2(0,0.72);p.ball_v=Vector2.ZERO;p.ball_held=true;p.bricks=[]
				for row in range(5):
					for col in range(5): p.bricks.append({'p':Vector2(-0.72+col*0.36,-0.72+row*0.2),'hp':2 if row<2 else 1})
		27:
			for i in range(12): s.hazards.append({'p':Vector2(rng.randf_range(-1,1),rng.randf_range(-1,1)),'v':Vector2.from_angle(rng.randf()*TAU)*0.16,'size':0.13})
		28:
			for i in range(16): s.items.append(Vector2(rng.randf_range(-0.65,0.65),rng.randf_range(-0.65,0.65)))
		31: s.tiles.resize(225);s.tiles.fill(-1)

func _reset_pins(p: Dictionary) -> void:
	p.pins=[];p.shots=0
	for row in range(4):
		for col in range(row+1): p.pins.append({'p':Vector2((col-row*0.5)*0.18,-0.65+row*0.15),'up':true})

func _intent(i: int, inputs: Dictionary) -> Dictionary:
	var p: Dictionary=s.players[i]
	var data: Dictionary=bot_input(i) if p.bot else inputs.get(i,{})
	var a: Vector2=data.get('axis',Vector2.ZERO)
	if not is_finite(a.x) or not is_finite(a.y): a=Vector2.ZERO
	a=a.limit_length(1)
	var held: bool=data.get('action',false)
	var secondary: bool=data.get('secondary',false)
	var result={'axis':a,'held':held,'press':held and not p.action_held,'release':not held and p.action_held,'second':secondary,'second_press':secondary and not p.secondary_held}
	p.action_held=held;p.secondary_held=secondary
	return result

func _move(p: Dictionary, axis: Vector2, speed: float, dt: float, bounds=true) -> void:
	if p.stun>0: axis*=0.15
	if axis.length()>0.05: p.face=axis.angle()
	p.v=axis*speed+p.impulse
	var next: Vector2=p.p+p.v*dt
	for c in range(2):
		var q: Vector2=p.p;q[c]=next[c]
		if not s.walls.any(func(w):return w.grow(0.055).has_point(q)): p.p=q
	if bounds: p.p=p.p.clamp(Vector2(-0.9,-0.85),Vector2(0.9,0.85))

func _fx(position: Vector2, owner: int, kind: String) -> void:
	s.fx.append({'p':position,'owner':owner,'kind':kind,'life':0.5});s.event+=1

func _damage(target: int, owner: int, amount: float, impulse=Vector2.ZERO) -> void:
	var p: Dictionary=s.players[target]
	if p.hurt>0 or p.guard>0: return
	p.hp-=amount;p.hurt=0.16;p.impulse+=impulse
	if owner>=0 and owner!=target: s.players[owner].score+=1
	_fx(p.p,owner,'hit')
	if p.hp<=0:
		if owner>=0 and owner!=target: s.players[owner].score+=5
		p.score-=2;p.hp=100.0;p.p=s.bases[target];p.hurt=1.2;p.impulse=Vector2.ZERO
		if s.game==11: p.p=Vector2(-0.82+target*1.64/(s.players.size()-1),0)

func _fire(p: Dictionary, owner: int, speed: float, kind: String, radius=0.025) -> void:
	var dir=Vector2.from_angle(p.face)
	s.shots.append({'p':p.p+dir*0.095,'v':dir*speed,'owner':owner,'life':2.4,'bounce':0,'kind':kind,'r':radius})
	p.attack=0.18;p.boost=0.14;_fx(p.p,owner,'shot')

func _projectiles(dt: float) -> void:
	for shot in s.shots:
		shot.life-=dt
		if shot.kind=='shell':
			shot.v+=Vector2(s.wind,-1.3)*dt;shot.p+=shot.v*dt
			if shot.p.y<=0 and shot.v.y<0:
				for i in range(s.players.size()):
					if abs(s.players[i].p.x-shot.p.x)<0.22: _damage(i,shot.owner,42)
				_fx(Vector2(shot.p.x,0),shot.owner,'blast');shot.life=0
			continue
		var next: Vector2=shot.p+shot.v*dt
		var wall_hit=false
		for w in s.walls:
			if w.has_point(next):
				wall_hit=true
				if not w.has_point(Vector2(shot.p.x,next.y)): shot.v.x=-shot.v.x
				else: shot.v.y=-shot.v.y
		if abs(next.x)>0.97: wall_hit=true;shot.v.x=-shot.v.x
		if abs(next.y)>0.92: wall_hit=true;shot.v.y=-shot.v.y
		if wall_hit:
			shot.bounce+=1
			if s.game!=8 or shot.bounce>1: shot.life=0
		else: shot.p=next
		if s.game==27: continue
		for i in range(s.players.size()):
			if i==shot.owner: continue
			if shot.p.distance_to(s.players[i].p)<0.07+shot.r:
				_damage(i,shot.owner,26 if s.game==8 else 20,shot.v.normalized()*0.24);shot.life=0;break
	s.shots=s.shots.filter(func(b):return b.life>0)

func step(state: Dictionary, dt: float, inputs: Dictionary, random: RandomNumberGenerator, difficulty: int) -> void:
	s=state;rng=random;level=difficulty
	for fx in s.fx: fx.life-=dt
	s.fx=s.fx.filter(func(f):return f.life>0)
	var intents: Array=[]
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i]
		for key in ['cool','boost','hurt','guard','stun','attack','combo_time','buffer','coyote','secondary_cool','attack_buffer']: p[key]=maxf(0,p[key]-dt)
		p.impulse=p.impulse.move_toward(Vector2.ZERO,dt*2)
		intents.append(_intent(i,inputs))
	match int(s.game):
		7,9,10,13: _combat(dt,intents)
		8,14: _shooting(dt,intents)
		11: _artillery(dt,intents)
		12,28,31: _objectives(dt,intents)
		15,17: _platform(dt,intents)
		16,18: _runner(dt,intents)
		19: _frog(dt,intents)
		20: _pong(dt,intents)
		21: _soccer(dt,intents)
		22,23: _throwing(dt,intents)
		24: _golf(dt,intents)
		25: _snake(dt,intents)
		26: _breakout(dt,intents)
		27: _asteroids(dt,intents)
		29: _memory(intents)
		30: _reaction(dt,intents)
	_projectiles(dt)

func _combat(dt: float, actions: Array) -> void:
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i];var a: Dictionary=actions[i]
		var speed=0.67 if s.game!=10 else 0.62
		if a.second:
			if s.game==7: p.guard=0.06;speed*=0.5
			elif s.game==10: speed*=0.4
		if a.second_press and s.game in [9,13] and p.secondary_cool<=0: p.guard=0.32;p.secondary_cool=0.75 if s.game==9 else 2.4
		_move(p,a.axis,speed,dt,s.game!=10)
		if a.press: p.attack_buffer=0.18
		if p.attack_buffer>0 and p.cool<=0 and p.stun<=0:
			p.attack_buffer=0.0
			p.combo=(p.combo%3)+1 if p.combo_time>0 else 1;p.combo_time=0.85;p.cool=0.42 if s.game==7 else 0.65;p.attack=0.24;p.boost=0.22
			for j in range(s.players.size()):
				if i==j: continue
				var q: Dictionary=s.players[j];var delta: Vector2=q.p-p.p
				var reach=0.31 if s.game==9 else 0.23
				if delta.length()>reach or Vector2.from_angle(p.face).dot(delta.normalized())<0.05: continue
				if q.guard>0:
					if s.game==9: p.stun=0.6;_fx(q.p,j,'parry')
					continue
				var push=1.35 if s.game in [10,13] else 0.45
				if actions[j].second and s.game==10: push*=0.25
				q.impulse+=delta.normalized()*push;q.last_attacker=i
				if s.game in [7,9]: _damage(j,i,18 if p.combo%3 else 32)
				else: q.hurt=0.2;_fx(q.p,i,'hit')
		if s.game==10:
			s.ring_radius=maxf(0.54,0.94-s.time*0.004)
			if p.p.length()>s.ring_radius:
				var owner=int(p.get('last_attacker',-1))
				if owner>=0 and owner!=i: s.players[owner].score+=4
				p.score-=2;p.p=s.bases[i].normalized()*(s.ring_radius*0.55);p.hurt=1;p.impulse=Vector2.ZERO;_fx(p.p,i,'fall')
		elif s.game==13 and p.p.length()<0.28:
			var contest=s.players.filter(func(q):return q.p.length()<0.28)
			if contest.size()==1: p.score+=dt*2
	_separate()

func _separate() -> void:
	for i in range(s.players.size()):
		for j in range(i+1,s.players.size()):
			var delta: Vector2=s.players[i].p-s.players[j].p
			if delta.length()<0.12:
				var push=delta.normalized()*(0.12-delta.length())*0.5 if delta.length()>0.001 else Vector2(0.01,0)
				s.players[i].p+=push;s.players[j].p-=push

func _shooting(dt: float, actions: Array) -> void:
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i];var a: Dictionary=actions[i]
		if a.second_press and p.secondary_cool<=0:
			p.guard=0.65 if s.game==8 else 0.25;p.boost=0.28;p.secondary_cool=3.0 if s.game==8 else 1.5
		_move(p,a.axis,0.5 if s.game==8 else (1.4 if p.guard>0 else 0.8),dt)
		if a.held and p.cool<=0:
			_fire(p,i,1.25 if s.game==8 else 1.8,'bullet' if s.game==8 else 'laser');p.cool=0.55 if s.game==8 else 0.22

func _artillery(dt: float, actions: Array) -> void:
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i];var a: Dictionary=actions[i]
		p.aim=clampf(p.aim-a.axis.x*dt,0.25,1.35)
		if a.second_press: p.sign=-p.sign
		if a.held and p.cool<=0: p.charge=minf(1,p.charge+dt*0.7)
		if a.release and p.charge>0 and p.cool<=0:
			var power=0.85+p.charge*0.85
			s.shots.append({'p':p.p+Vector2(0,0.06),'v':Vector2(cos(p.aim)*p.sign,sin(p.aim))*power,'owner':i,'life':5.0,'bounce':0,'kind':'shell','r':0.025})
			p.charge=0;p.cool=1.2;p.boost=0.15;_fx(p.p,i,'shot')

func _objectives(dt: float, actions: Array) -> void:
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i];var a: Dictionary=actions[i]
		if a.press and p.cool<=0:
			p.boost=0.35;p.cool=1.3
			if s.game==31:
				var c=_paint_cell(p.p)
				for x in range(maxi(0,c.x-2),mini(15,c.x+3)):
					for y in range(maxi(0,c.y-2),mini(15,c.y+3)): _paint_claim(Vector2i(x,y),i)
		if a.second_press:
			if s.game==31 and p.secondary_cool<=0: p.guard=0.7;p.secondary_cool=2.5
			elif s.game==28:
				for j in range(s.players.size()):
					if j!=i and s.players[j].bag>0 and p.bag<5 and p.p.distance_to(s.players[j].p)<0.2 and s.players[j].hurt<=0:
						s.players[j].bag-=1;p.bag+=1;s.players[j].hurt=0.6;_fx(p.p,i,'loot');break
			elif s.game==12 and p.carry>=0: s.flags[p.carry].carrier=-1;s.flags[p.carry].p=p.p;p.carry=-1
		_move(p,a.axis,1.2 if p.boost>0 else 0.7,dt)
		if s.game==28:
			for j in range(s.items.size()):
				if p.bag<5 and p.p.distance_to(s.items[j])<0.09: p.bag+=1;s.items[j]=Vector2(rng.randf_range(-0.65,0.65),rng.randf_range(-0.65,0.65))
			if p.bag>0 and p.p.distance_to(s.bases[i])<0.14: p.score+=p.bag;p.bag=0;_fx(p.p,i,'bank')
		elif s.game==12:
			for flag in s.flags:
				if flag.owner!=i and flag.carrier<0 and p.carry<0 and p.p.distance_to(flag.p)<0.12: flag.carrier=i;p.carry=flag.owner;p.hurt=0.45
			if p.carry>=0:
				s.flags[p.carry].p=p.p
				if p.p.distance_to(s.bases[i])<0.14 :
					p.score+=5;s.flags[p.carry].p=s.bases[p.carry];s.flags[p.carry].carrier=-1;p.carry=-1;_fx(p.p,i,'flag')
			for j in range(s.players.size()):
				if j!=i and p.carry>=0 and p.hurt<=0 and p.p.distance_to(s.players[j].p)<0.13:
					s.flags[p.carry].carrier=-1;s.flags[p.carry].p=s.bases[p.carry];p.carry=-1;p.hurt=0.8
		else:
			var c=_paint_cell(p.p)
			_paint_claim(c,i)
			if int(s.time)!=int(s.time-dt): p.score+=s.tiles.count(i)/25.0

func _paint_claim(cell: Vector2i, player: int) -> void:
	var owner: int=s.tiles[cell.y*15+cell.x]
	if owner>=0 and owner!=player and s.players[owner].guard>0 and Vector2(_paint_cell(s.players[owner].p)).distance_to(Vector2(cell))<2.5: return
	s.tiles[cell.y*15+cell.x]=player

func _paint_cell(pos: Vector2) -> Vector2i:
	return Vector2i(clampi(int((pos.x+0.95)/1.9*15),0,14),clampi(int((pos.y+0.9)/1.8*15),0,14))

func _jump(p: Dictionary, a: Dictionary, dt: float) -> void:
	if a.press: p.buffer=0.16
	if p.ground: p.coyote=0.12
	if p.buffer>0 and p.coyote>0:
		p.v.y=1.8;p.ground=false;p.coyote=0;p.buffer=0;p.boost=0.65;p.jumps+=1
	if not a.held and p.v.y>1.5: p.v.y=1.5
	p.v.y-=3.2*dt

func _platform(dt: float, actions: Array) -> void:
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i];var a: Dictionary=actions[i]
		_jump(p,a,dt)
		var old: Vector2=p.p
		p.v.x=move_toward(p.v.x,a.axis.x*0.95,dt*6)
		p.p+=p.v*dt;p.p.x=clampf(p.p.x,-0.88,0.88);p.ground=false
		for platform in s.platforms:
			var x: float=platform.p.x+(sin(s.time*1.5+platform.p.y)*0.16 if platform.moving else 0.0)
			if p.v.y<=0 and old.y>=platform.p.y-0.005 and p.p.y<=platform.p.y and abs(p.p.x-x)<platform.width/2+0.04:
				p.p.y=platform.p.y;p.v.y=0;p.ground=true;break
		p.best=maxf(p.best,p.p.y);p.score=p.best*10
		var floor_value=maxf(-0.35,s.time*0.06-0.6) if s.game==17 else p.best-1.8
		if p.p.y<floor_value:
			p.hurt=0.9
			var safe: Dictionary=s.platforms[0]
			for platform in s.platforms:
				if platform.p.y>floor_value+0.15: safe=platform;break
			p.p=Vector2(safe.p.x,safe.p.y);p.v=Vector2.ZERO;p.ground=true;p.best=maxf(0,p.best-0.5);_fx(p.p,i,'fall')

func _runner(dt: float, actions: Array) -> void:
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i];var a: Dictionary=actions[i]
		_jump(p,a,dt)
		p.p.y=maxf(0,p.p.y+p.v.y*dt)
		if p.p.y<=0: p.v.y=0;p.ground=true
		if s.game==16:
			p.progress+=dt*1.4;p.guard=0.06 if a.second and p.ground else 0.0
			for h in s.hazards:
				if abs(h.x-p.progress)<0.16 and p.hurt<=0 and ((h.high and p.guard<=0) or (not h.high and p.p.y<0.25)):
					p.progress=maxf(0,p.progress-0.6);p.hurt=1.0;_fx(Vector2(0,p.p.y),i,'hit')
			p.score=p.progress
		else:
			var period=maxf(1.0,2.1-s.time*0.009)
			if fmod(s.time,period)<dt:
				if p.p.y>0.18: p.combo+=1;p.score+=1+(1 if p.combo%5==0 else 0);_fx(p.p,i,'combo')
				else: p.combo=0;p.score-=1;p.hurt=0.5;_fx(p.p,i,'hit')

func _frog(dt: float, actions: Array) -> void:
	for h in s.hazards: h.p.x=wrapf(h.p.x+h.v.x*dt,-1.3,1.3)
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i];var a: Dictionary=actions[i]
		if a.axis.length()>0.4 and p.cool<=0:
			var direction: Vector2=Vector2(sign(a.axis.x),0) if abs(a.axis.x)>abs(a.axis.y) else Vector2(0,sign(a.axis.y))
			p.p+=direction*0.2;p.cool=0.11 if a.held else 0.2;p.boost=0.12
		p.p.x=clampf(p.p.x,-0.9,0.9);p.p.y=clampf(p.p.y,-0.85,0.8)
		var row=clampi(int(round((0.8-p.p.y)/0.2)),0,8)
		if row==8: p.score+=5;p.p=Vector2(-0.6+i*0.4,0.8);_fx(p.p,i,'goal');continue
		var matching=s.hazards.filter(func(h):return int(h.p.y)==row and abs(h.p.x-p.p.x)<h.size)
		var fail=row in [1,2,3] and not matching.is_empty()
		if row in [5,6,7]:
			if matching.is_empty(): fail=true
			else: p.p.x+=matching[0].v.x*dt
		if fail and p.hurt<=0: p.score-=2;p.hurt=0.75;p.p=Vector2(-0.6+i*0.4,0.8);_fx(p.p,i,'fall')

func _pong(dt: float, actions: Array) -> void:
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i];var a: Dictionary=actions[i]
		var axis: float=a.axis.x if i in [0,1] else a.axis.y
		p.progress=clampf(p.progress+axis*dt*1.3,-0.65,0.65)
		p.p=Vector2(p.progress,-0.82 if i==0 else 0.82) if i<2 else Vector2(-0.9 if i==2 else 0.9,p.progress)
		if a.press and p.cool<=0: p.boost=0.3;p.cool=1
		if s.puck.distance_to(p.p)<0.21:
			var normal=Vector2(0,1 if i==0 else -1) if i<2 else Vector2(1 if i==2 else -1,0)
			if s.puck_v.dot(normal)<0:
				s.puck_v=s.puck_v.bounce(normal)*1.02+Vector2(axis*0.28,0) if i<2 else s.puck_v.bounce(normal)*1.02+Vector2(0,axis*0.28)
				if p.boost>0: s.puck_v*=1.3
				s.last_hit=i;_fx(p.p,i,'hit')
	s.puck+=s.puck_v*dt;s.puck_v=s.puck_v.limit_length(1.9)
	var loser=-1
	if s.puck.y< -0.98: loser=0
	elif s.puck.y>0.98: loser=1
	elif s.puck.x< -1.03:
		if s.players.size()>2: loser=2
		else: s.puck.x=-1.02;s.puck_v.x=abs(s.puck_v.x)
	elif s.puck.x>1.03:
		if s.players.size()>3: loser=3
		else: s.puck.x=1.02;s.puck_v.x=-abs(s.puck_v.x)
	if loser>=0:
		s.players[loser].score-=1
		if s.last_hit>=0 and s.last_hit!=loser: s.players[s.last_hit].score+=2
		s.puck=Vector2.ZERO;s.puck_v=Vector2.from_angle(rng.randf()*TAU)*0.75;s.last_hit=-1;s.event+=1

func _soccer(dt: float, actions: Array) -> void:
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i];var a: Dictionary=actions[i]
		if a.second_press and p.cool<=0: p.boost=0.3;p.cool=0.8
		_move(p,a.axis,1.15 if p.boost>0 else 0.65,dt)
		if p.p.distance_to(s.puck)<0.14:
			var dir: Vector2=(s.puck-p.p).normalized()
			if dir==Vector2.ZERO: dir=Vector2(1 if i%2==0 else -1,0)
			s.puck=p.p+dir*0.145;s.puck_v=dir*(1.85 if a.held else 0.65)+p.v*0.3;s.last_hit=i
	s.puck+=s.puck_v*dt;s.puck_v*=pow(0.986,dt*60)
	if abs(s.puck.y)>0.86: s.puck.y=clampf(s.puck.y,-0.86,0.86);s.puck_v.y=-s.puck_v.y
	if abs(s.puck.x)>0.98:
		if abs(s.puck.y)<0.27:
			var team=0 if s.puck.x>0 else 1
			for i in range(s.players.size()):
				if i%2==team: s.players[i].score+=3
			s.puck=Vector2.ZERO;s.puck_v=Vector2.ZERO;_fx(Vector2.ZERO,team,'goal')
		else: s.puck.x=clampf(s.puck.x,-0.98,0.98);s.puck_v.x=-s.puck_v.x
	_separate()

func _throwing(dt: float, actions: Array) -> void:
	for ball in s.balls:
		ball.life-=dt;ball.p+=ball.v*dt
		if s.game==22: ball.v.y-=2.2*dt
		if s.game==23:
			var p: Dictionary=s.players[ball.owner]
			for pin in p.pins:
				if pin.up and pin.p.distance_to(ball.p)<0.15:
					pin.up=false;p.score+=1;ball.v.x*=0.6;_fx(pin.p,ball.owner,'pin')
					if ball.v.length()>1.4:
						var fallen: Array=[pin.p]
						while not fallen.is_empty():
							var at: Vector2=fallen.pop_front()
							for other in p.pins:
								if other.up and at.distance_to(other.p)<0.235: other.up=false;p.score+=1;fallen.append(other.p)
			if ball.p.y< -0.97: ball.life=0
		if s.game==22 and ball.p.y<0.6 and ball.v.y<0 and not ball.get('checked',false):
			ball.checked=true
			if abs(ball.p.x-0.55)<0.13:
				s.players[ball.owner].score+=3 if abs(ball.p.x-0.55)<0.05 else 2;_fx(ball.p,ball.owner,'goal')
	s.balls=s.balls.filter(func(b):return b.life>0)
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i];var a: Dictionary=actions[i]
		p.aim=clampf(p.aim+a.axis.x*dt*0.7,-0.65,0.65)
		if a.held and p.cool<=0: p.charge=minf(1,p.charge+dt*0.75)
		if a.release and p.charge>0 and p.cool<=0:
			var v=Vector2(0.9,1.3+p.charge*1.3) if s.game==22 else Vector2(p.aim*0.35,-0.75-p.charge*1.5)
			var position=Vector2(-0.6,0) if s.game==22 else Vector2(p.aim,0.75)
			s.balls.append({'p':position,'v':v,'owner':i,'life':2.7,'checked':false});p.cool=2.8;p.boost=0.15;p.charge=0;p.shots+=1
		if s.game==23 and p.cool<=0 and p.shots>0:
			if not p.pins.any(func(pin):return pin.up): p.score+=5;_reset_pins(p)
			elif p.shots>=2: _reset_pins(p)

func _golf(dt: float, actions: Array) -> void:
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i];var a: Dictionary=actions[i]
		if p.v.length()<0.035:
			p.v=Vector2.ZERO
			if a.axis.length()>0.3: p.face=a.axis.angle()
			if a.held: p.charge=minf(1,p.charge+dt*0.7)
			if a.release and p.charge>0: p.v=Vector2.from_angle(p.face)*(0.4+p.charge*1.8);p.charge=0;p.strokes+=1;p.boost=0.12
		var next: Vector2=p.p+p.v*dt
		for wall in s.walls:
			if wall.grow(0.035).has_point(next):
				if not wall.grow(0.035).has_point(Vector2(p.p.x,next.y)): p.v.x=-p.v.x*0.7
				else: p.v.y=-p.v.y*0.7
				next=p.p
		if abs(next.x)>0.9: p.v.x=-p.v.x*0.7
		if abs(next.y)>0.85: p.v.y=-p.v.y*0.7
		p.p=next.clamp(Vector2(-0.9,-0.85),Vector2(0.9,0.85));p.v*=pow(0.97,dt*60)
		var cup: Vector2=Vector2(0.73,[-0.65,0.62,-0.4][p.hole%3])
		if p.p.distance_to(cup)<0.07 and p.v.length()<0.5:
			p.score+=maxi(2,12-p.strokes);p.strokes=0;p.hole+=1;p.golf_waypoint=0;p.p=Vector2(-0.73,-0.4+i*0.25);p.v=Vector2.ZERO;_fx(cup,i,'goal')

func _snake(dt: float, actions: Array) -> void:
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i];var a: Dictionary=actions[i]
		if a.axis.length()>0.4:
			var d=Vector2i(int(sign(a.axis.x)),0) if abs(a.axis.x)>abs(a.axis.y) else Vector2i(0,int(sign(a.axis.y)))
			if d!=-p.snake_dir: p.snake_dir=d
		if a.press and p.cool<=0: p.boost=0.65;p.cool=1.5
		p.snake_time+=dt
		if p.snake_time<(0.085 if p.boost>0 else 0.16): continue
		p.snake_time=0
		var head: Vector2i=p.snake[0]+p.snake_dir
		var blocked=head.x<0 or head.y<0 or head.x>=15 or head.y>=15 or head in p.snake.slice(0,-1)
		for j in range(s.players.size()):
			if j!=i and head in s.players[j].snake: blocked=true
		if blocked:
			p.score-=2;head=Vector2i(2+i*3,2+i*3);p.snake=[head,head-Vector2i.RIGHT];p.snake_dir=Vector2i.RIGHT;p.hurt=0.5
		else:
			p.snake.push_front(head)
			if head in s.items:
				p.score+=1;s.items.erase(head)
				var free: Array=[]
				for x in range(15):
					for y in range(15):
						var c=Vector2i(x,y)
						if not s.players.any(func(q):return c in q.snake) and c not in s.items: free.append(c)
				if not free.is_empty(): s.items.append(free[rng.randi_range(0,free.size()-1)])
			else: p.snake.pop_back()
			if p.snake.size()>75: p.snake.pop_back()
		p.p=Vector2(head)/7-Vector2.ONE

func _breakout(dt: float, actions: Array) -> void:
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i];var a: Dictionary=actions[i]
		p.p.x=clampf(p.p.x+a.axis.x*dt*1.4,-0.72,0.72)
		if p.ball_held:
			p.ball=Vector2(p.p.x,0.72)
			if a.press: p.ball_held=false;p.ball_v=Vector2((0.25+i*0.075)*(1 if i%2==0 else -1),-0.9)
		else:
			p.ball+=p.ball_v*dt
			if abs(p.ball.x)>0.91: p.ball.x=clampf(p.ball.x,-0.9,0.9);p.ball_v.x=-p.ball_v.x
			if p.ball.y< -0.91: p.ball.y=-0.9;p.ball_v.y=abs(p.ball_v.y)
			if p.ball.y>0.72 and p.ball.y<0.84 and p.ball_v.y>0 and abs(p.ball.x-p.p.x)<0.22: p.ball_v=Vector2((p.ball.x-p.p.x)*2.4,-0.94).limit_length(1.4)
			for brick in p.bricks:
				if brick.hp>0 and abs(brick.p.x-p.ball.x)<0.16 and abs(brick.p.y-p.ball.y)<0.105:
					brick.hp-=1;p.score+=1;p.ball_v.y=-p.ball_v.y;p.ball.y=brick.p.y+sign(p.ball_v.y)*0.12;_fx(brick.p,i,'brick');break
			if p.ball.y>1.05: p.score-=1;p.ball_held=true;p.hurt=0.4
		if not p.bricks.any(func(b):return b.hp>0):
			p.score+=5
			for brick in p.bricks: brick.hp=1

func _asteroids(dt: float, actions: Array) -> void:
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i];var a: Dictionary=actions[i]
		p.face+=a.axis.x*dt*3
		p.v+=Vector2.from_angle(p.face)*maxf(0,-a.axis.y)*dt*0.9;p.v*=pow(0.99,dt*60);p.v=p.v.limit_length(0.8)
		p.p+=p.v*dt;p.p=Vector2(wrapf(p.p.x,-0.98,0.98),wrapf(p.p.y,-0.9,0.9))
		if a.held and p.cool<=0: _fire(p,i,1.8,'laser');p.cool=0.23
		if a.second_press and p.secondary_cool<=0: p.guard=0.7;p.secondary_cool=3.0
	var split: Array=[]
	for h in s.hazards:
		h.p+=h.v*dt;h.p=Vector2(wrapf(h.p.x,-1.05,1.05),wrapf(h.p.y,-1,1))
		for b in s.shots:
			if b.life>0 and b.p.distance_to(h.p)<h.size:
				s.players[b.owner].score+=2;b.life=0;h.dead=true;_fx(h.p,b.owner,'blast')
				if h.size>0.08:
					for sign_value in [-1,1]: split.append({'p':h.p,'v':h.v.rotated(sign_value*0.8)*1.6,'size':h.size*0.5})
				break
		for i in range(s.players.size()):
			if s.players[i].p.distance_to(h.p)<h.size+0.045 and s.players[i].guard<=0 and s.players[i].hurt<=0: s.players[i].score-=2;s.players[i].hurt=0.8;_fx(h.p,i,'hit')
	s.hazards=s.hazards.filter(func(h):return not h.get('dead',false));s.hazards.append_array(split)
	if s.hazards.size()<6 and int(s.time*2)!=int((s.time-dt)*2): s.hazards.append({'p':Vector2(0.98,rng.randf_range(-0.8,0.8)),'v':Vector2(-0.17,0.1),'size':0.13})

func _memory(actions: Array) -> void:
	var cycle=int(s.time/9)
	if cycle!=s.memory_cycle:
		s.memory_cycle=cycle;s.sequence.append(rng.randi_range(0,3))
		if s.sequence.size()>6: s.sequence=s.sequence.slice(-6)
		for p in s.players: p.memory_index=0;p.memory_done=false;p.axis_held=false
	s.memory_show=fmod(s.time,9)<float(s.sequence.size())*0.6+0.6
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i];var a: Dictionary=actions[i]
		var moving: bool=a.axis.length()>0.5
		if not s.memory_show and moving and not p.axis_held and not p.memory_done:
			var d=0 if a.axis.x>0.5 else (2 if a.axis.x< -0.5 else (1 if a.axis.y>0.5 else 3))
			if d==s.sequence[p.memory_index]:
				p.memory_index+=1;_fx(Vector2.ZERO,i,'correct')
				if p.memory_index>=s.sequence.size(): p.score+=s.sequence.size();p.memory_done=true
			else: p.score-=1;p.memory_done=true;p.hurt=0.5
		p.axis_held=moving

func _reaction(dt: float, actions: Array) -> void:
	s.signal_clock-=dt
	if s.signal==0 and s.signal_clock<=0: s.signal=1;s.signal_age=0.0;s.signal_clock=1.8;s.event+=1
	elif s.signal==1:
		s.signal_age+=dt
		if s.signal_clock<=0:
			s.signal=0;s.signal_clock=1.5+rng.randf()*2.5;s.signal_age=0
			for p in s.players: p.reacted=false;p.reaction=-1.0
	for i in range(s.players.size()):
		var p: Dictionary=s.players[i]
		if actions[i].press and not p.reacted:
			p.reacted=true
			if s.signal==0: p.score-=2;p.hurt=0.4
			else:
				var prior=s.players.filter(func(q):return q.reaction>=0).size()
				p.reaction=s.signal_age;p.score+=maxi(1,4-prior);p.boost=0.2;_fx(Vector2.ZERO,i,'react')

func bot_input(i: int) -> Dictionary:
	var p: Dictionary=s.players[i]
	var a=Vector2.ZERO;var fire=false;var second=false
	var nearest=i;var dist=INF
	for j in range(s.players.size()):
		if i!=j and p.p.distance_to(s.players[j].p)<dist: nearest=j;dist=p.p.distance_to(s.players[j].p)
	var q: Dictionary=s.players[nearest]
	match int(s.game):
		7,9,10,13:
			var target: Vector2=Vector2.ZERO if s.game==13 else q.p
			a=(target-p.p)*5;fire=dist<0.25;second=q.attack>0 and level>0
		8,14:
			a=(q.p-p.p).normalized()*(0.4 if dist<0.45 else 1.0)
			if s.game==8:
				for wall in s.walls:
					if wall.grow(0.1).has_point(p.p+a*0.18): a=Vector2(-a.y,a.x) if (q.p-p.p).dot(Vector2(-a.y,a.x))>0 else Vector2(a.y,-a.x)
			fire=true;second=p.hp<40
		11:
			var dx: float=q.p.x-p.p.x;p.sign=sign(dx);p.aim=0.8
			var target=clampf((sqrt(abs(dx)*1.3)-0.85)/0.85,0.1,0.85)
			fire=p.cool<=0 and p.charge<target
		12:
			var target: Vector2=s.bases[i]
			if p.carry>=0:
				var delta: Vector2=target-p.p
				if delta.length()>0.3: target=p.p+delta*0.5+Vector2(-delta.y,delta.x).normalized()*0.28
			else:
				var best=INF
				for flag in s.flags:
					if flag.owner!=i and flag.carrier<0 and p.p.distance_to(flag.p)<best: best=p.p.distance_to(flag.p);target=flag.p
			a=(target-p.p)*5;fire=true
		15,17:
			if p.ground:
				var best=INF
				for index in range(s.platforms.size()):
					var platform: Dictionary=s.platforms[index]
					if platform.p.y>p.p.y+0.1 and platform.p.y-p.p.y<0.5 and platform.p.y<best: best=platform.p.y;p.platform_target=index
			var chosen: Dictionary=s.platforms[p.platform_target]
			var x: float=chosen.p.x+(sin(s.time*1.5+chosen.p.y)*0.16 if chosen.moving else 0)
			a.x=clampf((x-p.p.x)*6,-1,1);fire=(p.ground and chosen.p.y>p.p.y+0.1) or p.v.y>0.25
		16:
			for h in s.hazards:
				if h.x-p.progress>0 and h.x-p.progress<0.6: fire=not h.high;second=h.high;break
		18:
			var period=maxf(1,2.1-s.time*0.009);fire=fmod(s.time,period)>period-0.3
		19:
			var row=int(round((0.8-p.p.y)/0.2))
			var next_row=row+1
			a=Vector2.UP
			if next_row in [1,2,3]:
				if s.hazards.any(func(h):return int(h.p.y)==next_row and abs(h.p.x+h.v.x*0.15-p.p.x)<0.2): a=Vector2.ZERO
			elif next_row in [5,6,7]:
				var logs=s.hazards.filter(func(h):return int(h.p.y)==next_row)
				logs.sort_custom(func(x,y):return abs(x.p.x+x.v.x*0.1-p.p.x)<abs(y.p.x+y.v.x*0.1-p.p.x))
				var target: float=logs[0].p.x+logs[0].v.x*0.1
				if abs(target-p.p.x)>0.17:
					var direction=Vector2.RIGHT if target>p.p.x else Vector2.LEFT
					if row<5 or s.hazards.any(func(h):return int(h.p.y)==row and abs(h.p.x-(p.p.x+direction.x*0.2))<h.size): a=direction
					else: a=Vector2.ZERO
		20:
			a=Vector2((s.puck.x-p.progress)*8,0) if i<2 else Vector2(0,(s.puck.y-p.progress)*8);fire=true
		21:
			a=(s.puck-Vector2(0.1 if i%2==0 else -0.1,0)-p.p)*5;fire=true;second=dist>0.5
		22: fire=p.cool<=0 and p.charge<0.44+[0.12,0.05,0.012][level]*sin(i*2+s.time*0.17)
		23: a.x=([0.3,0.12,0.02][level]*sin(i*2+s.time*0.2)-p.aim)*4;fire=p.cool<=0 and p.charge<0.85
		24:
			var route=[Vector2(-0.39,0.45),Vector2(0.07,0.45),Vector2(0.07,-0.42),Vector2(0.47,-0.42),Vector2(0.73,[-0.65,0.62,-0.4][p.hole%3])]
			var target: Vector2=route[mini(p.golf_waypoint,4)]
			if p.p.distance_to(target)<0.16 and p.golf_waypoint<4: p.golf_waypoint+=1;target=route[p.golf_waypoint]
			a=(target-p.p).normalized();fire=p.v.length()<0.035 and p.charge<clampf((p.p.distance_to(target)*1.8-0.4)/1.8,0.05,0.85)
		25:
			var head: Vector2i=p.snake[0];var choices: Array=[]
			for d in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
				var next: Vector2i=head+d
				if d!=-p.snake_dir and next.x>=0 and next.y>=0 and next.x<15 and next.y<15 and not s.players.any(func(v):return next in v.snake): choices.append(d)
			if not choices.is_empty():
				choices.sort_custom(func(x,y):return _food_dist(head+x)<_food_dist(head+y));a=Vector2(choices[0])
		26:
			var target: float=p.ball.x
			if p.ball_v.y>0:
				var arrival=maxf(0,(0.75-p.ball.y)/p.ball_v.y)
				target=pingpong(p.ball.x+p.ball_v.x*arrival+0.9,1.8)-0.9
			a.x=(target-p.p.x)*12;fire=p.ball_held
		27:
			var angle: float=(q.p-p.p).angle()
			if not s.hazards.is_empty(): angle=(s.hazards[0].p-p.p).angle()
			a=Vector2(clampf(wrapf(angle-p.face,-PI,PI)*2,-1,1),-0.45);fire=true;second=true
		28:
			var target: Vector2=s.bases[i]
			if p.bag<4:
				var near=INF
				for item in s.items:
					if p.p.distance_to(item)<near: near=p.p.distance_to(item);target=item
			a=(target-p.p)*5;fire=true;second=dist<0.18
		29:
			if not s.get('memory_show',true) and not p.memory_done and not p.axis_held and s.time>=p.memory_next:
				var d: int=s.sequence[p.memory_index]
				if rng.randf()<[0.1,0.03,0.0][level]: d=(d+1)%4
				a=DIRS[d];p.memory_next=s.time+[0.48,0.33,0.2][level]
		30: fire=s.signal==1 and s.signal_clock>0.1 and s.signal_age>[0.42,0.27,0.16][level]+i*0.012
		31: a=Vector2(cos(s.time*0.85+i*2),sin(s.time*0.71+i*2));fire=true;second=dist<0.2
	return {'axis':a.limit_length(1)*[0.7,0.9,1.0][level],'action':fire if s.game in [8,11,14,15,17,22,23,24,27] else fire and not p.action_held,'secondary':second and not p.secondary_held}

func _food_dist(cell: Vector2i) -> float:
	var result=INF
	for food in s.items: result=minf(result,Vector2(cell).distance_to(Vector2(food)))
	return result
