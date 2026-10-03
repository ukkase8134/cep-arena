extends Control
## Dedicated presentation for each arcade family, independent of authoritative physics.
const FONT=preload('res://assets/Rubik.ttf')
const C=[Color('80f5cd'),Color('ff846b'),Color('b6a1ff'),Color('78caff')]
const SOCCER=preload('res://assets/licensed/sports-pack/ball_soccer1.png')
const BASKET=preload('res://assets/licensed/sports-pack/ball_basket1.png')
const BOWLING=preload('res://assets/licensed/sports-pack/ball_bowling1.png')
const GOLF=preload('res://assets/licensed/sports-pack/ball_golf.png')
const METEOR=preload('res://assets/licensed/space-shooter-remastered/meteorBrown_big1.png')
const TANKS=[preload('res://assets/licensed/top-down-tanks-remastered/tank_green.png'),preload('res://assets/licensed/top-down-tanks-remastered/tank_red.png'),preload('res://assets/licensed/top-down-tanks-remastered/tank_sand.png'),preload('res://assets/licensed/top-down-tanks-remastered/tank_blue.png')]
const CRATE=preload('res://assets/licensed/top-down-tanks-remastered/crateWood.png')
var state: Dictionary={}
var t=0.0
var field: Rect2

func _ready() -> void:
	var shader=Shader.new()
	shader.code="shader_type canvas_item; uniform vec4 bounds=vec4(0.0,0.0,1.0,1.0); void fragment(){ if(SCREEN_UV.x<bounds.x || SCREEN_UV.y<bounds.y || SCREEN_UV.x>bounds.z || SCREEN_UV.y>bounds.w) discard; }"
	var clip=ShaderMaterial.new();clip.shader=shader;material=clip
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(dt: float) -> void:
	t+=dt
	var width=minf(size.x*0.76,(size.y-270)*1.8)
	field=Rect2(Vector2((size.x-width)/2,158),Vector2(width,size.y-276))
	if size.x>0 and size.y>0: material.set_shader_parameter("bounds",Vector4((field.position.x-12)/size.x,(field.position.y-12)/size.y,(field.end.x+12)/size.x,(field.end.y+12)/size.y))
	queue_redraw()

func _box(rect: Rect2, color: Color, radius=14, border=Color.TRANSPARENT) -> void:
	var b=StyleBoxFlat.new();b.bg_color=color;b.set_corner_radius_all(radius)
	if border.a>0: b.set_border_width_all(2);b.border_color=border
	draw_style_box(b,rect)

func _text(pos: Vector2, value: String, font_size=18, color=Color('f4f6ff')) -> void:
	draw_string(FONT,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func world(p: Vector2) -> Vector2:
	var scale_value=Vector2.ONE*field.size.y*0.5 if state.game in [10,13] else field.size*0.5
	return field.get_center()+p*scale_value

func _sprite(tex: Texture2D, pos: Vector2, dimensions: Vector2, angle=0.0, tint=Color.WHITE) -> void:
	draw_set_transform(pos,angle);draw_texture_rect(tex,Rect2(-dimensions/2,dimensions),false,tint);draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if state.is_empty(): return
	var width=minf(size.x*0.76,(size.y-270)*1.8)
	field=Rect2(Vector2((size.x-width)/2,158),Vector2(width,size.y-276))
	draw_rect(Rect2(Vector2.ZERO,size),Color('10182b'))
	for i in range(12): draw_line(Vector2(i*160-100,0),Vector2(i*160+300,size.y),Color(0.4,0.55,0.8,0.025),24,true)
	var g: int=state.game
	match g:
		7,9,10,13: _arena()
		8,14,27: _space_tanks()
		11: _artillery()
		12,28,31: _objectives()
		15,17: _platforms()
		16,18: _runners()
		19: _frog()
		20: _pong()
		21: _football()
		22,23: _throwing()
		24: _golf()
		25: _snakes()
		26: _bricks()
		29: _memory()
		30: _reaction()
	if g in [7,8,9,10,12,13,14,21,24,27,28,31]:
		for fx in state.fx:
			var pos=world(fx.p);var a=clampf(fx.life*2,0,1)
			draw_arc(pos,10+(0.5-fx.life)*85,0,TAU,36,Color(C[maxi(0,fx.owner)%4],a),3,true)
			for k in range(6):
				var end=pos+Vector2.from_angle(k*TAU/6+t)*(15+(0.5-fx.life)*65)
				draw_circle(end,2+a*2,Color('ffcf70',a))

func _court(color: Color, grid=false) -> void:
	_box(field.grow(8),Color('273751'),22)
	_box(field,color,16,Color('4b6380'))
	if grid:
		for x in range(13): draw_line(field.position+Vector2(field.size.x*x/12,0),field.position+Vector2(field.size.x*x/12,field.size.y),Color(1,1,1,0.035),1,true)
		for y in range(9): draw_line(field.position+Vector2(0,field.size.y*y/8),field.position+Vector2(field.size.x,field.size.y*y/8),Color(1,1,1,0.035),1,true)

func _person(pos: Vector2, i: int, face: float, attack=0.0, guard=0.0, sword=false) -> void:
	var color: Color=C[i]
	draw_ellipse_shadow(pos+Vector2(0,17),Vector2(23,8))
	draw_set_transform(pos,face+PI/2)
	_box(Rect2(-14,-4,28,26),color.darkened(0.25),10)
	draw_circle(Vector2(0,-10),16,Color('f4cfac'))
	_box(Rect2(-16,-20,32,8),color,3)
	draw_circle(Vector2(-5,-10),2,Color('172238'));draw_circle(Vector2(5,-10),2,Color('172238'))
	var reach=8+attack*65
	for sign_value in [-1,1]:
		var hand=Vector2(sign_value*(20 if guard<=0 else 12),-6-reach)
		draw_circle(hand+Vector2(1,2),9,Color('091226'));draw_circle(hand,8,color)
	if sword:
		draw_line(Vector2(20,-10),Vector2(20,-51-reach),Color('f3e9cd'),6,true)
		draw_line(Vector2(10,-15),Vector2(30,-15),Color('ffcf70'),5,true)
	draw_set_transform(Vector2.ZERO)
	if attack>0: draw_arc(pos,48,face-0.8,face+0.8,20,Color(color,attack*3),6,true)
	if guard>0: draw_arc(pos,34,0,TAU,40,Color('78caff'),3,true)
	_text(pos+Vector2(-8,39),'P%d'%(i+1),13,color)

func _side(pos: Vector2, i: int, facing=1.0, duck=false) -> void:
	var color: Color=C[i]
	draw_ellipse_shadow(pos+Vector2(0,26),Vector2(18,5))
	var base=pos+Vector2(0,10 if duck else 0)
	var stride=sin(t*13+i)*5
	for sign_value in [-1,1]:
		draw_line(base+Vector2(sign_value*6,14),pos+Vector2(sign_value*8+stride*sign_value,25),color.darkened(0.3),6,true)
	_box(Rect2(base+Vector2(-11,-1),Vector2(22,17 if duck else 22)),color,7)
	draw_circle(base+Vector2(0,-13),13,Color("f4cfac"))
	_box(Rect2(base+Vector2(-13,-22),Vector2(26,7)),color,3)
	draw_circle(base+Vector2(facing*6,-14),2.5,Color("17243a"))
	draw_line(base+Vector2(facing*10,4),base+Vector2(facing*19,10),Color("f4cfac"),5,true)

func draw_ellipse_shadow(pos: Vector2, dimensions: Vector2) -> void:
	draw_set_transform(pos,0,dimensions);draw_circle(Vector2.ZERO,1,Color(0,0,0,0.24));draw_set_transform(Vector2.ZERO)

func _health(pos: Vector2, value: float, color: Color) -> void:
	_box(Rect2(pos+Vector2(-25,-39),Vector2(50,6)),Color('091226'),3)
	_box(Rect2(pos+Vector2(-25,-39),Vector2(50*clampf(value/100,0,1),6)),color,3)

func _arena() -> void:
	var g: int=state.game
	_court(Color('30344b') if g==9 else Color('513d48'),true)
	var center=field.get_center();var radius=field.size.y*0.47
	if g in [10,13]:
		draw_circle(center,radius,Color('c3a67e') if g==10 else Color('243955'))
		var r=radius*state.get('ring_radius',0.94) if g==10 else radius*0.3
		draw_arc(center,r,0,TAU,90,Color('ffcf70'),6,true)
		if g==13:
			_text(center+Vector2(-28,6),'TAÇ',22,Color('ffcf70'))
	else:
		var inset=field.grow(-20)
		for color in [Color('ffcf70'),Color('ff846b')]:
			draw_rect(inset,color,false,3);inset=inset.grow(-8)
		for corner in [field.position,field.end,Vector2(field.end.x,field.position.y),Vector2(field.position.x,field.end.y)]: draw_circle(corner,15,Color('ffcf70'))
		_text(center+Vector2(-43,7),'CEP ARENA',15,Color(1,1,1,0.15))
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i];var pos=world(p.p)
		_person(pos,i,p.face,p.attack,p.guard,g==9)
		if g in [7,9]: _health(pos,p.hp,C[i])
		if p.combo>1 and p.attack>0: _text(pos+Vector2(22,-12),'%d×'%p.combo,19,Color('ffcf70'))

func _ship(pos: Vector2, p: Dictionary, i: int) -> void:
	draw_set_transform(pos,p.face)
	draw_colored_polygon(PackedVector2Array([Vector2(23,0),Vector2(-17,-16),Vector2(-9,0),Vector2(-17,16)]),C[i])
	draw_colored_polygon(PackedVector2Array([Vector2(10,0),Vector2(-5,-6),Vector2(-5,6)]),Color('eef9ff'))
	if p.v.length()>0.05: draw_colored_polygon(PackedVector2Array([Vector2(-13,-5),Vector2(-28-sin(t*30)*5,0),Vector2(-13,5)]),Color('ffcf70'))
	draw_set_transform(Vector2.ZERO)
	if p.guard>0: draw_arc(pos,31,0,TAU,36,Color('78caff'),3,true)
	_text(pos+Vector2(-8,35),'P%d'%(i+1),12,C[i])

func _space_tanks() -> void:
	_court(Color('566654') if state.game==8 else Color('121f3c'),state.game==8)
	if state.game!=8:
		for n in range(55):
			var pos=field.position+Vector2(fmod(n*137.5,field.size.x),fmod(n*87.6,field.size.y))
			draw_circle(pos,1+n%2,Color(0.8,0.9,1,0.3))
	for wall in state.walls:
		var a=world(wall.position);var b=world(wall.end)
		_box(Rect2(a,b-a),Color('a6a68b'),7,Color('d0cbbb'))
		for x in range(int((b.x-a.x)/30)): _sprite(CRATE,a+Vector2(x*30+17,(b.y-a.y)/2),Vector2(28,28))
	for h in state.hazards: _sprite(METEOR,world(h.p),Vector2.ONE*(h.size*field.size.y),t*0.2+h.p.x)
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i];var pos=world(p.p)
		if state.game==8:
			draw_ellipse_shadow(pos+Vector2(0,10),Vector2(28,14));_sprite(TANKS[i],pos,Vector2(58,58),p.face+PI/2)
			if p.guard>0: draw_arc(pos,35,0,TAU,40,Color('78caff'),3,true)
			_health(pos,p.hp,C[i]);_text(pos+Vector2(-8,42),'P%d'%(i+1),13,C[i])
		else: _ship(pos,p,i);_health(pos,p.hp,C[i])
	for shot in state.shots:
		var pos=world(shot.p)
		draw_line(pos-shot.v.normalized()*19,pos,C[shot.owner],5,true);draw_circle(pos,4,Color('fff1b8'))

func _artillery() -> void:
	_court(Color('274357'))
	for n in range(6):
		var x=field.position.x+n*field.size.x/5
		draw_colored_polygon(PackedVector2Array([Vector2(maxf(field.position.x,x-110),field.end.y-80),Vector2(x,field.position.y+70+n%3*40),Vector2(minf(field.end.x,x+150),field.end.y-80)]),Color('35515e'))
	var ground=field.end.y-55
	_box(Rect2(field.position.x,ground,field.size.x,55),Color('b38c60'),8)
	_text(field.position+Vector2(20,30),'RÜZGÂR  '+('→' if state.wind>0 else '←')+'  %.2f'%abs(state.wind),16,Color('d4e1ed'))
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i];var pos=Vector2(world(p.p).x,ground)
		_sprite(TANKS[i],pos+Vector2(0,-12),Vector2(55,55),PI/2)
		var dir=Vector2(cos(p.aim)*p.sign,-sin(p.aim))
		draw_line(pos+Vector2(0,-12),pos+Vector2(0,-12)+dir*38,C[i],9,true)
		_health(pos+Vector2(0,-12),p.hp,C[i]);_meter(pos+Vector2(-28,25),56,p.charge,C[i])
	for shot in state.shots:
		var pos=Vector2(world(shot.p).x,ground-shot.p.y*field.size.y*0.65)
		draw_circle(pos,7,Color('ffcf70'));draw_line(pos-Vector2(shot.v.x,-shot.v.y)*15,pos,C[shot.owner],3,true)
	for fx in state.fx:
		if fx.kind=='blast': draw_arc(Vector2(world(fx.p).x,ground),20+(0.5-fx.life)*90,PI,TAU,32,Color('ff846b',fx.life*2),8,true)

func _meter(pos: Vector2, width: float, value: float, color: Color) -> void:
	_box(Rect2(pos,Vector2(width,8)),Color('0b1428'),4)
	_box(Rect2(pos,Vector2(width*clampf(value,0,1),8)),color,4)

func _objectives() -> void:
	_court(Color('314b49') if state.game!=31 else Color('1a2b42'),true)
	if state.game==31:
		for y in range(15):
			for x in range(15):
				var owner: int=state.tiles[y*15+x]
				var rect=Rect2(field.position+Vector2(x,y)*field.size/15,field.size/15-Vector2.ONE)
				_box(rect,Color(C[owner],0.6) if owner>=0 else Color('24334c'),3)
	for i in range(state.players.size()):
		var pos=world(state.bases[i]);draw_circle(pos,29,Color(C[i],0.17));draw_arc(pos,28,0,TAU,40,C[i],3,true)
		_text(pos+Vector2(-8,5),'%d'%(i+1),16,C[i])
	if state.game==12:
		for flag in state.flags:
			var pos=world(flag.p);draw_line(pos,pos+Vector2(0,-33),Color('f4f6ff'),3,true)
			draw_colored_polygon(PackedVector2Array([pos+Vector2(2,-33),pos+Vector2(24,-25),pos+Vector2(2,-17)]),C[flag.owner])
	elif state.game==28:
		for item in state.items:
			var pos=world(item);draw_circle(pos,10,Color('ffcf70'));draw_circle(pos,5,Color('ad782d'))
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i];var pos=world(p.p)
		_person(pos,i,p.face,0,p.guard)
		if state.game==28: _text(pos+Vector2(20,0),'%d/5'%p.bag,14,Color('ffcf70'))

func _lane(i: int) -> Rect2:
	var count=state.players.size();var w=field.size.x/count
	return Rect2(field.position+Vector2(i*w+4,0),Vector2(w-8,field.size.y))

func _platforms() -> void:
	_court(Color('263c53'))
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i];var lane=_lane(i)
		_box(lane,Color('20324c'),10)
		var camera=maxf(0,p.p.y-0.55)
		var unit=lane.size.y*0.55
		for platform in state.platforms:
			var y=lane.end.y-30-(platform.p.y-camera)*unit
			if y<lane.position.y+18 or y>lane.end.y: continue
			var x=platform.p.x+(sin(state.time*1.5+platform.p.y)*0.16 if platform.moving else 0.0)
			var width=platform.width*lane.size.x*0.46
			_box(Rect2(lane.get_center().x+x*lane.size.x*0.45-width/2,y,width,11),Color('ffcf70') if platform.moving else C[i],5)
		var pos=Vector2(lane.get_center().x+p.p.x*lane.size.x*0.45,lane.end.y-58-(p.p.y-camera)*unit)
		_side(pos,i,sign(p.v.x) if abs(p.v.x)>0.02 else 1.0)
		if state.game==17:
			var lava=maxf(-0.35,state.time*0.06-0.6)
			var y=clampf(lane.end.y-30-(lava-camera)*unit,lane.position.y,lane.end.y)
			_box(Rect2(lane.position.x,y,lane.size.x,lane.end.y-y),Color('dc5c3f'),5)
			for n in range(8): draw_circle(Vector2(lane.position.x+n*lane.size.x/7,y+sin(t*3+n)*5),7,Color('ffcf70'))
		_text(lane.position+Vector2(12,25),'P%d  %.1fm'%[i+1,p.best*10],14,C[i])

func _runners() -> void:
	_court(Color('293d52'))
	var rows=state.players.size();var h=field.size.y/rows
	for i in range(rows):
		var p: Dictionary=state.players[i];var lane=Rect2(field.position+Vector2(0,i*h+5),Vector2(field.size.x,h-10))
		_box(lane,Color('1c3045'),10)
		var ground=lane.end.y-20;draw_line(Vector2(lane.position.x+15,ground),Vector2(lane.end.x-15,ground),C[i],3,true)
		var pos=Vector2(lane.position.x+lane.size.x*0.26,ground-28-p.p.y*75)
		_side(pos,i,1.0,p.guard>0)
		if state.game==16:
			for hazard in state.hazards:
				var x=pos.x+(hazard.x-p.progress)*180
				if x<lane.position.x+10 or x>lane.end.x-15: continue
				_box(Rect2(x-12,ground-67 if hazard.high else ground-28,24,30 if hazard.high else 28),Color('ff846b') if hazard.high else Color('ffcf70'),5)
			_text(lane.position+Vector2(10,21),'P%d  %dm'%[i+1,p.progress*10],13,C[i])
		else:
			var period=maxf(1,2.1-state.time*0.009);var phase=fmod(state.time,period)/period
			var x=pos.x+(1.0-phase)*lane.size.x*0.65
			draw_line(Vector2(x,ground-40),Vector2(x,ground),Color('ffcf70'),7,true)
			_text(lane.position+Vector2(10,21),'P%d  SERİ %d'%[i+1,p.combo],13,C[i])

func _frog() -> void:
	_court(Color('385842'))
	for row in range(9):
		var y=field.end.y-(row+0.5)*field.size.y/9
		if row in [1,2,3,5,6,7]:
			draw_rect(Rect2(field.position.x,y-field.size.y/18,field.size.x,field.size.y/9),Color('28384a') if row<4 else Color('2c6080'))
		if row in [1,2,3]: draw_line(Vector2(field.position.x,y),Vector2(field.end.x,y),Color(1,1,1,0.12),2,true)
	for hazard in state.hazards:
		var pos=Vector2(world(Vector2(hazard.p.x,0)).x,field.end.y-(hazard.p.y+0.5)*field.size.y/9)
		var w=hazard.size*field.size.x
		_box(Rect2(pos-Vector2(w/2,15),Vector2(w,30)),Color('ffcf70') if hazard.p.y<4 else Color('9e795b'),6)
		if hazard.p.y<4: _box(Rect2(pos-Vector2(w*0.18,10),Vector2(w*0.36,20)),Color('355169'),3)
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i];var pos=Vector2(world(p.p).x,field.end.y-((0.8-p.p.y)/0.2+0.5)*field.size.y/9)
		draw_circle(pos,16,C[i]);draw_circle(pos+Vector2(-8,-10),7,C[i]);draw_circle(pos+Vector2(8,-10),7,C[i]);draw_circle(pos+Vector2(-8,-12),3,Color('fff'));draw_circle(pos+Vector2(8,-12),3,Color('fff'))
		_text(pos+Vector2(-4,6),str(i+1),12,Color('14213a'))

func _pong() -> void:
	_court(Color('285c63'))
	draw_line(Vector2(field.get_center().x,field.position.y),Vector2(field.get_center().x,field.end.y),Color(1,1,1,0.3),2,true)
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i];var pos=world(p.p)
		_box(Rect2(pos-Vector2(52,7) if i<2 else pos-Vector2(7,44),Vector2(104,14) if i<2 else Vector2(14,88)),C[i],7)
		if p.boost>0: draw_circle(pos,25,Color(C[i],0.2))
	var ball=world(state.puck);draw_circle(ball+Vector2(2,3),10,Color(0,0,0,0.2));draw_circle(ball,9,Color('fff5dc'))

func _football() -> void:
	_court(Color('3b6b4b'))
	for n in range(8):
		if n%2==0: draw_rect(Rect2(field.position+Vector2(n*field.size.x/8,0),Vector2(field.size.x/8,field.size.y)),Color(0.05,0.25,0.12,0.14))
	draw_rect(field.grow(-10),Color(1,1,1,0.5),false,2)
	draw_line(Vector2(field.get_center().x,field.position.y+10),Vector2(field.get_center().x,field.end.y-10),Color(1,1,1,0.5),2,true)
	draw_arc(field.get_center(),field.size.y*0.18,0,TAU,50,Color(1,1,1,0.5),2,true)
	for sign_value in [-1,1]:
		var goal=world(Vector2(sign_value*0.98,-0.27));_box(Rect2(goal-Vector2(12,0),Vector2(24,field.size.y*0.27)),C[0 if sign_value<0 else 1],3)
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i];var pos=world(p.p)
		_person(pos,i,p.face);draw_arc(pos,23,0,TAU,30,C[i%2],3,true)
	_sprite(SOCCER,world(state.puck),Vector2(27,27),t*state.puck_v.length())

func _throwing() -> void:
	_court(Color('29374d'))
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i];var lane=_lane(i)
		_box(lane,Color('906746') if state.game==23 else Color('523f39'),10)
		_text(lane.position+Vector2(12,24),'P%d'%(i+1),16,C[i])
		var map=func(v: Vector2):return lane.get_center()+Vector2(v.x*lane.size.x*0.42,(-v.y if state.game==22 else v.y)*lane.size.y*0.41)
		if state.game==22:
			var hoop: Vector2=map.call(Vector2(0.55,0.6))
			_box(Rect2(hoop+Vector2(13,-40),Vector2(8,80)),Color('e9e8e1'),2)
			draw_arc(hoop,21,0,TAU,36,Color('ff846b'),4,true)
			for n in range(5): draw_line(hoop+Vector2(-17+n*8,0),hoop+Vector2(-12+n*6,30),Color(1,1,1,0.3),1,true)
			_side(map.call(Vector2(-0.6,0)),i)
			_meter(lane.position+Vector2(15,lane.size.y-28),lane.size.x-30,p.charge,C[i])
			_text(lane.position+Vector2(15,lane.size.y-38),'GÜÇ  ·  BAS / BIRAK',10,Color('ffdfb0'))
		else:
			for n in range(6): draw_line(lane.position+Vector2(20+n*(lane.size.x-40)/5,35),lane.position+Vector2(20+n*(lane.size.x-40)/5,lane.size.y-50),Color(0.3,0.2,0.1,0.14),1,true)
			for pin in p.pins:
				if pin.up:
					var pos: Vector2=map.call(pin.p);draw_circle(pos,6,Color('fff3d3'));_box(Rect2(pos+Vector2(-4,-14),Vector2(8,13)),Color('fff3d3'),3);draw_line(pos+Vector2(-4,-5),pos+Vector2(4,-5),Color('ff846b'),3,true)
			var pos: Vector2=map.call(Vector2(p.aim,0.75));_sprite(BOWLING,pos,Vector2(29,29))
			draw_line(pos,pos+Vector2(p.aim*25,-50),Color(C[i],0.5),2,true)
			_meter(lane.position+Vector2(15,lane.size.y-23),lane.size.x-30,p.charge,C[i])
		for ball in state.balls:
			if ball.owner==i: _sprite(BASKET if state.game==22 else BOWLING,map.call(ball.p),Vector2(25,25),t*2)

func _golf() -> void:
	_court(Color('427a56'),true)
	for w in state.walls: _box(Rect2(world(w.position),world(w.end)-world(w.position)),Color('ccbb8c'),7,Color('ede0b9'))
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i];var cup=world(Vector2(0.73,[-0.65,0.62,-0.4][p.hole%3]))
		draw_circle(cup,10,Color('182d27'));draw_line(cup,cup+Vector2(0,-28),Color('fff'),2,true)
		draw_colored_polygon(PackedVector2Array([cup+Vector2(1,-28),cup+Vector2(18,-22),cup+Vector2(1,-16)]),C[i])
		var pos=world(p.p);_sprite(GOLF,pos,Vector2(20,20),0,C[i])
		if p.v.length()<0.04: draw_line(pos,pos+Vector2.from_angle(p.face)*(30+p.charge*85),C[i],3,true)
		_text(pos+Vector2(12,18),'P%d · %d'%[i+1,p.strokes],12,C[i])

func _snakes() -> void:
	_court(Color('253e3a'),true)
	var cell=field.size/15
	for food in state.items:
		var pos=field.position+(Vector2(food)+Vector2.ONE*0.5)*cell;draw_circle(pos,9,Color('ff846b'));draw_line(pos+Vector2(0,-9),pos+Vector2(4,-15),Color('80f5cd'),3,true)
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i]
		for n in range(p.snake.size()-1,-1,-1):
			var pos=field.position+Vector2(p.snake[n])*cell
			_box(Rect2(pos+Vector2(2,2),cell-Vector2(4,4)),C[i].darkened(minf(0.45,n*0.035)),8)
			if n==0:
				draw_circle(pos+cell*Vector2(0.35,0.35),3,Color('15213c'));draw_circle(pos+cell*Vector2(0.65,0.35),3,Color('15213c'))

func _bricks() -> void:
	_court(Color('20354c'))
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i];var lane=_lane(i);_box(lane,Color('142238'),10)
		var map=func(v: Vector2):return lane.get_center()+v*lane.size*0.47
		for brick in p.bricks:
			if brick.hp>0:
				var pos: Vector2=map.call(brick.p)
				_box(Rect2(pos-Vector2(lane.size.x*0.075,13),Vector2(lane.size.x*0.15,26)),C[i].lightened(0.25) if brick.hp==2 else C[i],4)
		var pos: Vector2=map.call(Vector2(p.p.x,0.82));_box(Rect2(pos-Vector2(lane.size.x*0.1,6),Vector2(lane.size.x*0.2,12)),Color('fff0cf'),5)
		draw_circle(map.call(p.ball),7,Color('ffcf70'));_text(lane.position+Vector2(9,lane.size.y-12),'P%d'%(i+1),13,C[i])

func _memory() -> void:
	_court(Color('272942'))
	var showing=state.get('memory_show',true)
	var active=int(fmod(state.time,9)/0.6)
	_text(field.position+Vector2(20,31),'DİZİYİ İZLE' if showing else 'ŞİMDİ SENİN SIRAN',21,Color('ffcf70'))
	var directions=['→','↓','←','↑']
	for n in range(state.sequence.size()):
		var pos=field.position+Vector2(65+n*67,65)
		_box(Rect2(pos,Vector2(54,52)),Color('ffcf70') if showing and active==n else Color('34415e'),12)
		_text(pos+Vector2(16,34),directions[state.sequence[n]] if showing else '?',28,Color('14213a') if showing and active==n else Color('c6cee1'))
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i];var lane=_lane(i);var center=Vector2(lane.get_center().x,field.position.y+field.size.y*0.68)
		for n in range(4):
			var pos=center+Vector2.from_angle(n*TAU/4)*43
			_box(Rect2(pos-Vector2(23,23),Vector2(46,46)),C[n].darkened(0.15),10)
			_text(pos+Vector2(-10,9),directions[n],26,Color('16243e'))
		_text(center+Vector2(-28,87),'P%d  %d / %d'%[i+1,p.memory_index,state.sequence.size()],14,C[i])
		if p.memory_done: _text(center+Vector2(-25,-68),'TAMAM' if p.hurt<=0 else 'HATA',13,C[i])

func _reaction() -> void:
	_court(Color('27374d'))
	var green=state.signal==1;var center=field.get_center()+Vector2(0,-70)
	draw_circle(center,55,Color('80f5cd') if green else Color('ff846b'));draw_circle(center,66,Color(0.5,0.96,0.8,0.1) if green else Color(1,0.5,0.4,0.1))
	_text(center+Vector2(-33,7),'ŞİMDİ!' if green else 'BEKLE',20,Color('16243e'))
	for i in range(state.players.size()):
		var p: Dictionary=state.players[i];var lane=_lane(i);var pos=Vector2(lane.get_center().x,field.end.y-75)
		draw_circle(pos,34,C[i] if p.reaction>=0 else Color('34435d'));_text(pos+Vector2(-12,7),'P%d'%(i+1),16,Color('16243e') if p.reaction>=0 else C[i])
		if p.reaction>=0: _text(pos+Vector2(-28,56),'%d ms'%int(p.reaction*1000),16,C[i])
		elif p.reacted: _text(pos+Vector2(-33,56),'ERKEN!',15,Color('ff846b'))
