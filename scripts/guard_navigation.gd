extends RefCounted
## Standing-height terrain graph shared by a floor's guards. Bodies and the player
## are excluded: crowd avoidance happens while following a route, not in the map.
var points: Array[Vector2] = []
var links: Array[Array] = []
var cells := {}
var world: World2D
var level: Node2D
var geometry_state: Array = []
var graph := AStar2D.new()
var body := RectangleShape2D.new()

func _init(owner_level: Node2D) -> void:
	level = owner_level
	geometry_state = signature(level)
	world = level.get_world_2d()
	body.size = Vector2(13.6, 23.6)
	var bounds := Vector2(1120, 756)
	if level.get("definition") != null:
		var size = level.definition.get("world_size", [1120,756])
		bounds = Vector2(size[0],size[1])
	for row in range(1, int(bounds.y / 28) + 1):
		for column in range(1, int(bounds.x / 14)):
			var point := Vector2(column * 14, row * 28 - 15)
			if clear_body(point) and ray(point + Vector2(0,14), point + Vector2(0,17)):
				cells[Vector2i(column,row)] = points.size()
				points.append(point)
				links.append([])
	for cell in cells:
		var id: int = cells[cell]
		for dx in [-1,1]:
			for dy in [-1,0,1]:
				var next: Vector2i = cell + Vector2i(dx,dy)
				if not cells.has(next): continue
				var other: int = cells[next]
				if walk_edge(points[id],points[other]):
					links[id].append({"id":other,"ladder":null})
	# Connect floor landings only through actual authored ladder shafts.
	for ladder in level.areas.get_children():
		if ladder.kind != "ladder": continue
		var top: float = ladder.position.y - ladder.area_size.y/2
		var bottom: float = ladder.position.y + ladder.area_size.y/2
		var landings: Array[int] = []
		for id in points.size():
			var p := points[id]
			if absf(p.x-ladder.position.x)>48 or absf(p.x-ladder.position.x)<14: continue
			if p.y < top-32 or p.y > bottom+16: continue
			# Keep only a landing with a clear horizontal entrance into the shaft.
			if not clear_line(p,Vector2(ladder.position.x,p.y)): continue
			landings.append(id)
		for a in landings:
			for b in landings:
				if a == b: continue
				if absf(points[a].y-points[b].y)<56 and (points[a].x-ladder.position.x)*(points[b].x-ladder.position.x)>=0: continue
				var shaft_a := Vector2(ladder.position.x,points[a].y)
				var shaft_b := Vector2(ladder.position.x,points[b].y)
				# One-way floors can be climbed; solid ceilings cannot.
				if ray(shaft_a,shaft_b): continue
				links[a].append({"id":b,"ladder":ladder})

	for id in points.size(): graph.add_point(id,points[id])
	for id in points.size():
		for edge in links[id]: graph.connect_points(id,edge.id,false)

static func signature(owner_level: Node2D) -> Array:
	var state: Array = [owner_level.get("door_open")]
	var gates := owner_level.get_node_or_null("Gates")
	if gates != null:
		for gate in gates.get_children(): state.append(gate.collision_layer)
	for trap in owner_level.get_tree().get_nodes_in_group("trapdoors"):
		if is_instance_valid(trap) and trap.level == owner_level: state.append(trap.is_open)
	return state

func ray(a: Vector2,b: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(a,b,1)
	query.hit_from_inside = true
	return not world.direct_space_state.intersect_ray(query).is_empty()

func clear_body(point: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = body
	query.transform = Transform2D(0,point+Vector2(0,3))
	query.collision_mask = 1
	return world.direct_space_state.intersect_shape(query,1).is_empty()

func clear_line(a: Vector2,b: Vector2) -> bool:
	var steps := maxi(1,ceili(a.distance_to(b)/6))
	for step in range(steps+1):
		if not clear_body(a.lerp(b,float(step)/steps)): return false
	return true

func walk_edge(a: Vector2,b: Vector2) -> bool:
	if absf(a.y-b.y)<1: return clear_line(a,b)
	# Exactly one tile of rise/fall, with full standing clearance over the lip.
	var high := minf(a.y,b.y)-2
	return clear_line(a,Vector2(a.x,high)) and clear_line(Vector2(a.x,high),Vector2(b.x,high)) and clear_line(Vector2(b.x,high),b)

func nearest(point: Vector2) -> int:
	var best := -1
	var score := INF
	for id in points.size():
		var p := points[id]
		var distance := p.distance_squared_to(point)
		if absf(p.y-point.y)>40: distance+=100000
		if distance<score:
			score=distance
			best=id
	return best if best>=0 and points[best].distance_to(point)<64 else -1

func route(start: Vector2,target: Vector2) -> Array[Dictionary]:
	var source := nearest(start)
	if source<0: return []
	var target_id := nearest(target)
	if target_id<0: return []
	var ids := graph.get_id_path(source,target_id,true)
	var path: Array[Dictionary] = []
	for i in range(1,ids.size()):
		var ladder = null
		for edge in links[ids[i-1]]:
			if edge.id==ids[i]:
				ladder=edge.ladder
				break
		path.append({"point":points[ids[i]],"ladder":ladder})
	return path

func search_goal(start: Vector2,side: float,identity: int) -> Vector2:
	# Spread searches along the current storey instead of drawing every guard to
	# the exact same last sighting. Routing still validates reachability.
	var best := start
	var distance := 0.0
	var reach := 180.0 + float(identity % 4)*56.0
	for p in points:
		if absf(p.y-start.y)>16 or (p.x-start.x)*side<56: continue
		var score := absf(p.x-start.x)
		if score<=reach and score>distance:
			distance=score
			best=p
	return best
