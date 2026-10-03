extends SubViewportContainer
const Sim=preload("res://scripts/simulation.gd")
var viewport: SubViewport
var root: Node3D
var actors: Array = []
var gems: Array = []
var tiles: Array = []
var beam: Node3D
var preview := false
var time := 0.0
var game_id := 0
var animations: Array=[]
var bursts: Array=[]
var previous_gems: Array=[]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	stretch=true
	viewport=SubViewport.new()
	viewport.size=Vector2i(1280,720)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg=false
	add_child(viewport)
	root=Node3D.new()
	viewport.add_child(root)
	var environment=WorldEnvironment.new()
	var settings=Environment.new()
	settings.background_mode=Environment.BG_COLOR
	settings.background_color=Color("0b1428")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color=Color("bccbfd")
	settings.ambient_light_energy=0.4
	environment.environment=settings
	root.add_child(environment)
	var light=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-28,0)
	light.light_color=Color("ffebd7")
	light.light_energy=0.9
	light.shadow_enabled=true
	root.add_child(light)
	var camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=12.5
	camera.position=Vector3(9,12,12)
	root.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current=true
	_mesh(BoxMesh.new(),Vector3(24,0.15,24),Vector3(0,-0.65,0),Color("0e1930"))

func setup(id: int, count: int) -> void:
	game_id=id
	for i in range(8):
		var angle=i*TAU/8+PI/8
		var decor=_model("column-damaged" if i%3==0 else "column",Vector3(cos(angle)*6.5,-0.5,sin(angle)*6.5),1.6)
		decor.rotation.y=-angle
	for x in [-1,1]:
		for z in [-1,1]:
			_model("tree",Vector3(x*7.6,-0.6,z*5.3),1.5)
			var banner=_model("banner",Vector3(x*5.8,-0.4,z*3.2),1.25)
			banner.rotation.y=PI if z<0 else 0
	for x in range(-4,5):
		for z in range(-4,5):
			if id!=1 and (id!=2 or Vector2(x,z).length()<4.1):
				_mesh(BoxMesh.new(),Vector3(0.96,0.025,0.96),Vector3(x,0.005,z),Color("293c57") if (x+z)%2==0 else Color("243650"))
	_mesh(CylinderMesh.new() if id==2 else BoxMesh.new(),Vector3(9.6,0.42,9.6),Vector3(0,-0.25,0),Color("223451"))
	_mesh(BoxMesh.new(),Vector3(9.7,0.1,0.08),Vector3(0,-0.02,-4.82),Color("80f5cd"))
	_mesh(BoxMesh.new(),Vector3(9.7,0.1,0.08),Vector3(0,-0.02,4.82),Color("b6a1ff"))
	for i in range(count):
		var actor=Node3D.new()
		root.add_child(actor)
		actors.append(actor)
		var character=_model("character-soldier",Vector3.ZERO,1.05,actor)
		var animation=character.find_child("AnimationPlayer",true,false)
		animations.append(animation)
		if animation!=null:
			for animation_name in ["idle","walk","sprint"]:
				if animation.has_animation(animation_name): animation.get_animation(animation_name).loop_mode=Animation.LOOP_LINEAR
		var label=Label3D.new()
		label.text="P%d"%(i+1)
		label.font=load("res://assets/Rubik.ttf")
		label.font_size=64
		label.pixel_size=0.004
		label.position=Vector3(0,2.15,0)
		label.modulate=Sim.COLORS[i]
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		actor.add_child(label)
		var ring=TorusMesh.new()
		ring.inner_radius=0.37
		ring.outer_radius=0.43
		_mesh(ring,Vector3.ONE,Vector3(0,0.05,0),Sim.COLORS[i],actor)
	if id==0:
		for i in range(10):
			var crystal=SphereMesh.new()
			crystal.radial_segments=4
			crystal.rings=1
			var gem=_mesh(crystal,Vector3(0.42,0.68,0.42),Vector3.ZERO,Color("80f5cd"))
			gem.rotation_degrees=Vector3(0,45,0)
			gems.append(gem)
		for i in range(4):
			var angle=i*TAU/4+PI/4
			_mesh(BoxMesh.new(),Vector3(0.55,0.8,0.55),Vector3(cos(angle)*5.5,0.25,sin(angle)*5.5),Sim.COLORS[i].darkened(0.2))
	elif id==1:
		for i in range(36): tiles.append(_mesh(BoxMesh.new(),Vector3(1.43,0.18,1.43),Vector3(-3.75+(i%6)*1.5,0,-3.75+int(i/6)*1.5),Sim.TILES[(i+int(i/6))%4]))
	elif id==2:
		beam=Node3D.new()
		root.add_child(beam)
		_mesh(CylinderMesh.new(),Vector3(0.45,0.9,0.45),Vector3(0,0.45,0),Color("ffcf70"))
		_mesh(BoxMesh.new(),Vector3(9.1,0.14,0.15),Vector3(0,0.24,0),Color("ff846b"),beam)
		_mesh(BoxMesh.new(),Vector3(9.1,0.08,0.08),Vector3(0,0.36,0),Color("ffcf70"),beam)
		for i in range(24):
			var angle=i*TAU/24
			_mesh(BoxMesh.new(),Vector3(0.08,0.04,0.28),Vector3(cos(angle)*4.4,0.02,sin(angle)*4.4),Color("ffcf70"))
	_model("trophy",Vector3(0,-0.4,-6.5),1.5)

func _model(name_value: String, pos: Vector3, scale_value: float, parent: Node3D=null) -> Node3D:
	var model=load("res://assets/licensed/mini-arena/%s.glb"%name_value).instantiate()
	model.position=pos
	model.scale=Vector3.ONE*scale_value
	(root if parent==null else parent).add_child(model)
	return model

func _mesh(mesh: Mesh, scale_value: Vector3, pos: Vector3, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var instance=MeshInstance3D.new()
	instance.mesh=mesh
	instance.scale=scale_value
	instance.position=pos
	var material=StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=0.72
	instance.material_override=material
	(root if parent==null else parent).add_child(instance)
	return instance

func update_state(state: Dictionary, dt: float) -> void:
	if state.is_empty(): return
	time=state.time
	for i in range(mini(actors.size(),state.players.size())):
		var p: Dictionary = state.players[i]
		var jump: float = sin((1.0-p.boost/0.88)*PI)*1.0 if game_id==2 and p.boost>0 else 0.0
		var target=Vector3(p.p.x*5,jump,p.p.y*5)
		actors[i].position=actors[i].position.lerp(target,minf(1,dt*18))
		if p.v.length()>0.02: actors[i].rotation.y=lerp_angle(actors[i].rotation.y,atan2(p.v.x,p.v.y),dt*10)
		actors[i].scale=Vector3.ONE*(0.93+0.07*cos(time*25)) if p.hurt>0 else Vector3.ONE
		var animation=animations[i]
		if animation!=null:
			var desired="jump" if game_id==2 and p.boost>0 else ("sprint" if p.boost>0 else ("walk" if p.v.length()>0.05 else "idle"))
			if animation.current_animation!=desired: animation.play(desired,0.1)
	for i in range(gems.size()):
		if previous_gems.size()==gems.size() and previous_gems[i].distance_to(state.items[i])>0.1:
			var mesh=TorusMesh.new()
			mesh.inner_radius=0.2;mesh.outer_radius=0.28
			bursts.append({"node":_mesh(mesh,Vector3.ONE,Vector3(previous_gems[i].x*5,0.1,previous_gems[i].y*5),Color("80f5cd")),"life":0.45})
		gems[i].position=Vector3(state.items[i].x*5,0.65+sin(time*3+i)*0.13,state.items[i].y*5)
		gems[i].rotation.y=time*1.6+i
	previous_gems=state.items.duplicate() if game_id==0 else []
	for burst in bursts:
		burst.life-=dt
		burst.node.scale=Vector3.ONE*(1+(0.45-burst.life)*5)
		if burst.life<=0: burst.node.queue_free()
	bursts=bursts.filter(func(b):return b.life>0)
	for i in range(tiles.size()):
		var down: bool = fmod(time,6)>=4 and int(state.items[i])!=int(state.target)
		tiles[i].position.y=lerpf(tiles[i].position.y,-2.0 if down else 0.0,minf(1,dt*10))
	if beam!=null: beam.rotation.y=-Sim.beam_angle(time)
