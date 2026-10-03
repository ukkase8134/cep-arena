extends RefCounted
## Adapted for an authoritative grid from Godot's MIT Multiplayer Bomber demo.
## Original bomb.gd uses authority-only explosions and walls blocking hits.
## Copyright Godot Engine contributors. See assets/licensed/godot-bomber/LICENSE.md.
const SIZE=9
const CELL=0.2
const SPAWNS=[Vector2i(0,0),Vector2i(8,8),Vector2i(8,0),Vector2i(0,8)]

static func cell(position: Vector2) -> Vector2i:
	return Vector2i(clampi(int(floor((position.x+0.9)/CELL)),0,8),clampi(int(floor((position.y+0.9)/CELL)),0,8))

static func position(at: Vector2i) -> Vector2:
	return Vector2(at)*CELL+Vector2(-0.8,-0.8)

static func inside(at: Vector2i) -> bool:
	return at.x>=0 and at.x<SIZE and at.y>=0 and at.y<SIZE

static func blast(origin: Vector2i, walls: Array, crates: Array) -> Array:
	var cells: Array=[origin]
	for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		for distance in range(1,3):
			var at: Vector2i=origin+direction*distance
			if not inside(at) or at in walls: break
			cells.append(at)
			if at in crates: break
	return cells

static func route(start: Vector2i, goal: Vector2i, blocked: Array) -> Array:
	var queue: Array=[start]
	var previous: Dictionary={start:start}
	while not queue.is_empty():
		var current: Vector2i=queue.pop_front()
		if current==goal: break
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i=current+direction
			if not inside(next) or next in blocked or previous.has(next): continue
			previous[next]=current
			queue.append(next)
	if not previous.has(goal): return []
	var path: Array=[goal]
	while path[0]!=start: path.push_front(previous[path[0]])
	return path
