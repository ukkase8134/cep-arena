extends Control
var state: Dictionary = {}
var t := 0.0
const Sim = preload("res://scripts/simulation.gd")
const Bomber = preload("res://scripts/bomber_rules.gd")
const FONT=preload("res://assets/Rubik.ttf")
const BOMBER_SHEET=preload("res://assets/licensed/godot-bomber/charwalk.png")
const EXPLOSION=preload("res://assets/licensed/godot-bomber/explosion.png")
const SHIELD=preload("res://assets/licensed/space-shooter-remastered/shield1.png")
var ships: Array=[]
var meteor: Texture2D
var feedback: Array=[]
var previous: Array=[]
var puck_trail: Array=[]
var trail_clock=0.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for color in ["green","red","orange","blue"]: ships.append(load("res://assets/licensed/space-shooter-remastered/playerShip1_%s.png"%color))
	meteor=load("res://assets/licensed/space-shooter-remastered/meteorBrown_big1.png")

func _process(dt: float) -> void:
	t+=dt
	if not state.is_empty():
		if previous.size()==state.players.size():
			for i in range(state.players.size()):
				var p: Dictionary=state.players[i]
				var old: Dictionary=previous[i]
				if p.hurt>old.hurt: feedback.append({"p":p.p,"slot":i,"life":0.55,"label":"Darbe!","color":Color("ff846b")})
				elif state.game!=4 and p.score-old.score>=0.9: feedback.append({"p":p.p,"slot":i,"life":0.6,"label":"+%d"%int(p.score-old.score),"color":Sim.COLORS[i]})
		previous=[]
		for p in state.players: previous.append({"score":p.score,"hurt":p.hurt})
		if state.game==3:
			trail_clock+=dt
			if trail_clock>0.025:
				trail_clock=0
				puck_trail.append(state.puck)
				if puck_trail.size()>12: puck_trail.pop_front()
	for item in feedback: item.life-=dt
	feedback=feedback.filter(func(f):return f.life>0)
	queue_redraw()

func at(p: Vector2) -> Vector2:
	return size/2+p*Vector2(minf(size.x*0.29,size.y*0.44),size.y*0.36)

func _draw() -> void:
	if state.is_empty(): return
	var game: int = state.game
	draw_rect(Rect2(Vector2.ZERO,size),Color("091226"))
	for i in range(50):
		var star=Vector2(fmod(i*137.3,size.x),fmod(i*91.7+t*(5 if game==4 else 1),size.y))
		draw_circle(star,1+(i%3)*0.4,Color(0.7,0.8,1,0.12))
	if game==3: _hockey()
	elif game==4: _race()
	elif game==5: _meteors()
	elif game==6: _bomber()
	for item in feedback:
		var pos=at(item.p) if game in [3,5] else (_bomb_pos(Bomber.cell(item.p)) if game==6 else _race_pos(item.slot,item.p))
		var color: Color=item.color
		color.a=minf(1,item.life*3)
		draw_arc(pos,20+(0.6-item.life)*75,0,TAU,40,color,2,true)
		draw_string(FONT,pos+Vector2(-18,-30-(0.6-item.life)*50),item.label,HORIZONTAL_ALIGNMENT_LEFT,-1,20,color)

func _hockey() -> void:
	var radius: float = minf(size.x*0.29,size.y*0.36)
	var center=size/2
	draw_circle(center,radius,Color("121f38"))
	for i in range(7): draw_arc(center,radius+9+i*3,0,TAU,100,Color(0.3,0.65,0.9,0.08-i*0.008),2,true)
	draw_arc(center,radius,0,TAU,100,Color("2a4261"),3,true)
	draw_arc(center,radius*0.3,0,TAU,64,Color("2a4261"),2,true)
	draw_line(center+Vector2(-radius,0),center+Vector2(radius,0),Color("243b55"),2,true)
	draw_line(center+Vector2(0,-radius),center+Vector2(0,radius),Color("243b55"),2,true)
	for i in range(state.players.size()):
		var angle=TAU*float(i)/state.players.size()-PI/2
		draw_arc(center,radius,angle-0.33,angle+0.33,24,Color(Sim.COLORS[i],0.14),24,true)
		draw_arc(center,radius,angle-0.33,angle+0.33,24,Sim.COLORS[i],6,true)
		var p: Dictionary = state.players[i]
		var pos=center+p.p*radius
		draw_circle(pos+Vector2(0,5),22,Color(0,0,0,0.25))
		draw_circle(pos,20,Sim.COLORS[i])
		draw_arc(pos,14,0,TAU,30,Color("ffffff"),2,true)
		if p.boost>0: draw_arc(pos,26,0,TAU,36,Color(Sim.COLORS[i],0.7),3,true)
		_number(pos,i)
	var puck=center+state.puck*radius
	for i in range(puck_trail.size()): draw_circle(center+puck_trail[i]*radius,3+i*0.4,Color(0.5,0.8,1,float(i)/puck_trail.size()*0.25))
	draw_circle(puck,17,Color(0.5,0.8,1,0.1))
	draw_circle(puck,10,Color("f2f5ff"))
	draw_circle(puck+Vector2(-2,-2),3,Color("80f5cd"))

func _race() -> void:
	var left: float = size.x*0.22
	var width: float = size.x*0.56
	var top := 142.0
	var height: float = size.y-252
	var lane: float = width/state.players.size()
	for i in range(state.players.size()):
		var p: Dictionary = state.players[i]
		var x=left+i*lane
		var color: Color = Sim.COLORS[i]
		draw_style_box(_box(Color("13213b")),Rect2(x+5,top,lane-10,height))
		draw_line(Vector2(x+5,top+10),Vector2(x+5,top+height-10),Color(color,0.45),2,true)
		for line in range(12):
			var line_y=top+fposmod(line*60+p.progress*80,height)
			draw_line(Vector2(x+lane/2,line_y),Vector2(x+lane/2,line_y+24),Color(0.7,0.8,1,0.09),2,true)
		for hazard in state.hazards:
			var distance: float = hazard.p.y-p.progress
			if distance < -1 or distance > 5: continue
			var pos=Vector2(x+lane/2+hazard.p.x*lane*0.4,top+height*0.75-distance*height/5.5)
			if pos.y<top+25 or pos.y>top+height-20: continue
			_sprite(meteor,pos,Vector2(hazard.size*lane*0.9,26),t*0.2)
		var pos=Vector2(x+lane/2+p.p.x*lane*0.4,top+height*0.75)
		var flame=45 if p.boost>0 else 24
		draw_colored_polygon(PackedVector2Array([pos+Vector2(-8,22),pos+Vector2(8,22),pos+Vector2(0,22+flame+5*sin(t*30))]),Color("ffcf70"))
		_sprite(ships[i],pos,Vector2(48,48))
		if p.hurt>0: draw_arc(pos,28,0,TAU,32,Color("ff846b"),2,true)
		draw_string(FONT,Vector2(x+15,top+28),"P%d"%(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
		draw_string(FONT,Vector2(x+15,top+height-15),"%dm"%int(p.progress*10),HORIZONTAL_ALIGNMENT_LEFT,-1,19,color)

func _race_pos(slot: int, p: Vector2) -> Vector2:
	var lane=size.x*0.56/state.players.size()
	return Vector2(size.x*0.22+(slot+0.5)*lane+p.x*lane*0.4,142+(size.y-252)*0.75)

func _meteors() -> void:
	var corner=at(Vector2(-1,-1))
	var dimensions=at(Vector2(1,1))-corner
	draw_style_box(_box(Color("101e34")),Rect2(corner,dimensions))
	for x in range(9):
		draw_line(at(Vector2(-1+x*0.25,-1)),at(Vector2(-1+x*0.25,1)),Color(0.4,0.7,1,0.05),1,true)
	for y in range(9):
		draw_line(at(Vector2(-1,-1+y*0.25)),at(Vector2(1,-1+y*0.25)),Color(0.4,0.7,1,0.05),1,true)
	for hazard in state.hazards:
		var pos=at(hazard.p)
		var trail: Vector2 = hazard.v.normalized()*32
		draw_line(pos-trail,pos,Color(1,0.53,0.42,0.3),hazard.size*150,true)
		_sprite(meteor,pos,Vector2.ONE*hazard.size*minf(size.y*0.36,size.x*0.29)*2.2,t+hazard.p.x)
	for i in range(state.players.size()):
		var p: Dictionary = state.players[i]
		var pos=at(p.p)
		var color: Color = Sim.COLORS[i]
		draw_circle(pos+Vector2(0,5),18,Color(0,0,0,0.25))
		_sprite(ships[i],pos,Vector2(40,40),p.v.angle()+PI/2 if p.v.length()>0.05 else 0)
		if p.boost>0:
			draw_arc(pos,29,0,TAU,40,Color(color,0.85),3,true)
			_sprite(SHIELD,pos,Vector2(68,68),t)
		if p.hurt>0: draw_arc(pos,24,0,TAU,40,Color("ff846b"),2,true)
		_number(pos+Vector2(0,28),i)

func _box(color: Color) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(12)
	return style

func _number(pos: Vector2, i: int) -> void:
	draw_string(FONT,pos+Vector2(-5,5),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("f4f6ff"))

func _sprite(texture: Texture2D, pos: Vector2, dimensions: Vector2, angle=0.0, tint=Color.WHITE) -> void:
	draw_set_transform(pos,angle)
	draw_texture_rect(texture,Rect2(-dimensions/2,dimensions),false,tint)
	draw_set_transform(Vector2.ZERO)

func _bomb_pos(cell: Vector2i) -> Vector2:
	var tile=minf(size.y*0.62,size.x*0.46)/9
	return size/2+Vector2(0,20)+(Vector2(cell)-Vector2(4,4))*tile

func _bomber() -> void:
	var tile=minf(size.y*0.62,size.x*0.46)/9
	for x in range(9):
		for y in range(9):
			var cell=Vector2i(x,y)
			var pos=_bomb_pos(cell)
			var rect=Rect2(pos-Vector2.ONE*(tile/2-1),Vector2.ONE*(tile-2))
			draw_style_box(_box(Color("20344c") if (x+y)%2==0 else Color("1a2c42")),rect)
			if cell in state.walls:
				draw_style_box(_box(Color("567084")),rect.grow(-2))
				draw_line(pos+Vector2(-tile*0.3,-tile*0.3),pos+Vector2(tile*0.3,-tile*0.3),Color("9bb2c2"),3,true)
			elif cell in state.crates:
				draw_style_box(_box(Color("a66f44")),rect.grow(-3))
				for slope in [-1,1]: draw_line(pos+Vector2(-tile*0.28,-tile*0.28*slope),pos+Vector2(tile*0.28,tile*0.28*slope),Color("d5a66b"),4,true)
	for flame in state.flames:
		var pos=_bomb_pos(flame.cell)
		draw_circle(pos,tile*0.48,Color(1,0.55,0.2,minf(0.8,flame.life*3)))
		_sprite(EXPLOSION,pos,Vector2.ONE*tile*0.9)
	for bomb in state.bombs:
		var pos=_bomb_pos(bomb.cell)
		var pulse=1+sin(t*(9+(2-bomb.timer)*9))*0.08
		draw_circle(pos+Vector2(0,3),tile*0.24,Color(0,0,0,0.3))
		draw_circle(pos,tile*0.22*pulse,Color("111827"))
		draw_arc(pos,tile*0.25,0,TAU,32,Sim.COLORS[bomb.owner],2,true)
		draw_line(pos+Vector2(0,-tile*0.2),pos+Vector2(6,-tile*0.32),Color("ffcf70"),3,true)
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i]
		var pos=_bomb_pos(Vector2i.ZERO)+(p.p+Vector2(0.8,0.8))/0.2*tile
		draw_circle(pos+Vector2(0,6),tile*0.3,Color(0,0,0,0.3))
		var frame=int(t*8)%4 if p.v.length()>0.05 else 0
		var direction=3 if abs(p.v.x)>abs(p.v.y) and p.v.x>0 else (1 if abs(p.v.x)>abs(p.v.y) else (2 if p.v.y<0 else 0))
		draw_texture_rect_region(BOMBER_SHEET,Rect2(pos-Vector2.ONE*tile*0.4,Vector2.ONE*tile*0.8),Rect2(direction*48,frame*48,48,48),Color(Sim.COLORS[i],0.45 if p.hurt>0 and int(t*12)%2==0 else 1))
		_number(pos+Vector2(0,tile*0.42),i)
