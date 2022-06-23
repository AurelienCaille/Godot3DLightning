#Branched lightning generator, creates several simple lightnings 
tool
extends Spatial
class_name Lightning3DBranched

enum UPDATE_MODE{
	ON_TIMEOUT,
	ON_PROCESS,
	ON_PHYSICS
}

export(float, 0.0, 1.0) var bias : float = 0.5 #Controls at what point the lightning will branch

export(Vector3) var origin : Vector3 = Vector3(0,0,0) #The origin point of the lightning

export(Vector3) var end : Vector3 = Vector3(0,0,1) #The end point of the lightning

export(int, 2, 100) var lighnting_subdivisions : int = 10 #The number of subdivisions of the lightning

export(int, 0, 100) var max_branches : int = 5 #The maximum number of branches

export(float, 0.0, 10.0) var max_deviation : float = 1.0 #The maximum deviation of the lightning

export(float, 0.0, 10.0) var max_branch_deviation : float = 1.0 #The maximum deviation of the lightning's branches

export(UPDATE_MODE) var update_mode : int = UPDATE_MODE.ON_TIMEOUT #The update mode of the lightning

export(float, 0.0, 10.0) var update_timeout : float = 0.1 #The update timeout of the lightning

export(float, 0.1, 100.0 ) var maximum_update_delta : float = 1.0 #The maximum delta cumulative before update

var lightnings : Dictionary = {}
var lightning_nodes : Array = []
var increments : float = 0.0
var timer : SceneTreeTimer = null
var cumulative_delta : float = 0.0

func _setup_lightning():
	for i in range(0, max_branches+1):
		var new_lightning = Lightning3DSimple.new()
		add_child(new_lightning)
		lightning_nodes.append(new_lightning)
	_update_lightning()
		#new_lightning.curve.get_baked_points()

func _update_lightning():
	for light in lightning_nodes:
		light.visible = false
	var i = 1
	for key in lightnings.keys():
		if i > lightning_nodes.size():
			break
		var current = lightning_nodes[i-1]
		current.curve.clear_points()
		current.visible = true
		lightnings[key].invert()
		for point in lightnings[key]:
			current.curve.add_point(point)
		i += 1
#Create a vector3 array to store the points of the path for lightning, adding randomness to the points
func create_lightning_points(local_origin, local_end, local_deviation) -> Array:
	var points : Array = []
	var point : Vector3 = local_origin
	var direction : Vector3 = local_origin.direction_to(local_end)
	var distance : float = local_origin.distance_to(local_end)
	increments = distance / lighnting_subdivisions
	points.append(point)
	point = point + direction * increments
	for _i in range(1, lighnting_subdivisions):
		point = point + direction * increments
		point += Vector3(
			rand_range(-local_deviation, local_deviation),
			rand_range(-local_deviation, local_deviation), 
			rand_range(-local_deviation, local_deviation)
			)
		points.append(point)
	points.pop_back()
	points.append(local_end)
	return points

#Create branches for the lightning
func create_branches(main_path) -> void:
	var branch_count : int = ceil(rand_range(0, max_branches))
	for i in range(0, branch_count):
		var local_end : Vector3 = Vector3(randf(), randf(), randf())
		var branch_path : Array = create_lightning_points(
			main_path[rand_range(0, main_path.size() - 1)], 
			local_end * (increments * rand_range(2,4)), 
			max_branch_deviation)
		lightnings[i] = branch_path

func _update() -> void:
	var main_path : Array = create_lightning_points(origin, end, max_deviation)
	lightnings["main"] = main_path
	create_branches(main_path)
	_update_lightning()
	
func _ready():
	if update_mode == UPDATE_MODE.ON_TIMEOUT:
		timer_update()
	_setup_lightning()

func timer_update() -> void:
	timer = get_tree().create_timer(update_timeout)
	timer.connect("timeout", self, "timer_update")
	_update()

func _process(delta):
	if update_mode == UPDATE_MODE.ON_PROCESS:
		cumulative_delta += delta
		if cumulative_delta > maximum_update_delta:
			cumulative_delta = 0.0
			_update()

func _physics_process(delta):
	if update_mode == UPDATE_MODE.ON_PHYSICS:
		cumulative_delta += delta
		if cumulative_delta > maximum_update_delta:
			cumulative_delta = 0.0
			_update()