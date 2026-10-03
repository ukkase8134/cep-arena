extends Control
var state: Dictionary = {}
var t := 0.0
const Sim = preload("res://scripts/simulation.gd")

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(dt: float) -> void:
	t+=dt
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

func _hockey() -> void:
	var radius: float = minf(size.x*0.29,size.y*0.36)
	var center=size/2
	draw_circle(center,radius,Color("121f38"))
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
	draw_circle(puck,17,Color(0.5,0.8,1,0.1))
	draw_circle(puck,10,Color("f2f5ff"))
	draw_circle(puck+Vector2(-2,-2),3,Color("80f5cd"))

func _race() -> void:
	var left: float = size.x*0.23
	var width: float = size.x*0.54
	var top := 128.0
	var track_h: float = (size.y-220)/state.players.size()
	for i in range(state.players.size()):
		var p: Dictionary = state.players[i]
		var y=top+i*track_h
		draw_style_box(_box(Color("13213b")),Rect2(left,y,width,track_h-12))
		for line in range(12):
			var line_x=left+fmod(line*70-p.progress*90,width)
			draw_line(Vector2(line_x,y+track_h/2),Vector2(line_x+22,y+track_h/2),Color(0.7,0.8,1,0.08),2,true)
		for hazard in state.hazards:
			var distance: float = hazard.p.y-p.progress
			if distance < -1 or distance > 5: continue
			var pos=Vector2(left+width*0.2+distance*width/5.5,y+track_h*0.44+hazard.p.x*track_h*0.38)
			draw_style_box(_box(Color("ff846b")),Rect2(pos-Vector2(8,hazard.size*track_h*0.4),Vector2(16,hazard.size*track_h*0.8)))
		var pos=Vector2(left+width*0.2,y+track_h*0.44+p.p.x*track_h*0.38)
		var color: Color = Sim.COLORS[i]
		var flame=24 if p.boost>0 else 12
		draw_colored_polygon(PackedVector2Array([pos+Vector2(-14,-7),pos+Vector2(-14,7),pos+Vector2(-14-flame-5*sin(t*30),0)]),Color("ffcf70"))
		draw_colored_polygon(PackedVector2Array([pos+Vector2(23,0),pos+Vector2(-15,-14),pos+Vector2(-8,0),pos+Vector2(-15,14)]),color)
		draw_circle(pos+Vector2(3,0),4,Color("f4f6ff"))
		if p.hurt>0: draw_arc(pos,28,0,TAU,32,Color("ff846b"),2,true)
		draw_string(ThemeDB.fallback_font,Vector2(left-65,y+track_h*0.5),"P%d"%(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,22,color)
		draw_string(ThemeDB.fallback_font,Vector2(left+width+16,y+track_h*0.5),"%dm"%int(p.progress*10),HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)

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
		draw_circle(pos,hazard.size*minf(size.y*0.36,size.x*0.29),Color("ff846b"))
		draw_circle(pos+Vector2(-3,-3),hazard.size*80,Color("ffcf70"))
	for i in range(state.players.size()):
		var p: Dictionary = state.players[i]
		var pos=at(p.p)
		var color: Color = Sim.COLORS[i]
		draw_circle(pos+Vector2(0,5),18,Color(0,0,0,0.25))
		draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-19),pos+Vector2(-15,13),pos+Vector2(0,6),pos+Vector2(15,13)]),color)
		if p.boost>0: draw_arc(pos,29,0,TAU,40,Color(color,0.85),3,true)
		if p.hurt>0: draw_arc(pos,24,0,TAU,40,Color("ff846b"),2,true)
		_number(pos+Vector2(0,28),i)

func _box(color: Color) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(12)
	return style

func _number(pos: Vector2, i: int) -> void:
	draw_string(ThemeDB.fallback_font,pos+Vector2(-4,5),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("10192b"))
