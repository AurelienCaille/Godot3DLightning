@tool
#Branched lightning generator, creates several simple lightnings 
extends Node3D
class_name Lightning3DBranched

enum UPDATE_MODE{
	ON_TIMEOUT,
	ON_PROCESS,
	ON_PHYSICS
}

@export var bias : float = 0.5 #Controls at what point the lightning will branch # (float, 0.0, 1.0)

@export var branches_to_end: bool = true #If true, the lightning will branch to the origin of the line

@export var origin: Vector3 = Vector3(0,0,0) #The origin point of the lightning

@export var end: Vector3 = Vector3(0,10,0) #The end point of the lightning

@export var lighnting_subdivisions : int = 10 #The number of subdivisions of the lightning # (int, 2, 100)

@export var max_branches : int = 5 #The maximum number of branches # (int, 0, 100)

@export var max_deviation : float = 1.0 #The maximum deviation of the lightning # (float, 0.0, 10.0)

@export var max_branch_deviation : float = 1.0 #The maximum deviation of the lightning's branches # (float, 0.0, 10.0)

@export var update_mode: UPDATE_MODE = UPDATE_MODE.ON_TIMEOUT #The update mode of the lightning

@export var update_timeout : float = 0.1 #The update timeout of the lightning # (float, 0.01, 10.0)

@export var maximum_update_delta : float = 1.0 #The maximum delta cumulative before update # (float, 0.01, 100.0 )

var lightnings : Dictionary = {}
var lightning_nodes : Array = []
var increments : float = 0.0
var timer : SceneTreeTimer = null
var cumulative_delta : float = 0.0


func _init(init_lightning_subdivisions = 10, 
	init_max_deviation = 1.0, 
	init_max_branches = 5,
	init_max_branch_deviation = 1.0,
	init_bias = 0.7, 
	init_update_mode = UPDATE_MODE.ON_PROCESS):
	self.lighnting_subdivisions = init_lightning_subdivisions
	self.max_deviation = init_max_deviation
	self.max_branches = init_max_branches
	self.max_branch_deviation = init_max_branch_deviation
	self.bias = init_bias
	self.update_mode = init_update_mode


func _setup_lightning():
	for _i in range(0, max_branches+1):
		var new_lightning = Lightning3DSimple.new()
		add_child(new_lightning)
		lightning_nodes.append(new_lightning)
	_update_lightning()
		#new_lightning.curve.get_baked_points()

func _update_lightning():
	for light in lightning_nodes:
		light.visible = false
	var i = 0
	lightning_nodes.shuffle()
	for key in lightnings.keys():
		if i > lightning_nodes.size():
			break
		var current = lightning_nodes[i]
		current.curve.clear_points()
		current.visible = true
		#lightnings[key].invert()
		for point in lightnings[key]:
			current.curve.add_point(point)
		i += 1
#Create a vector3 array to store the points of the path for lightning, adding randomness to the points
func _create_lightning_points(local_origin, local_end, local_deviation) -> Array:
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
			randf_range(-local_deviation, local_deviation),
			randf_range(-local_deviation, local_deviation), 
			randf_range(-local_deviation, local_deviation)
			)
		points.append(point)
	points.pop_back()
	points.append(local_end)
	return points

#Create branches for the lightning
func _create_branches(main_path) -> void:
	var branch_count : int = max_branches#ceil(randf_range(0, max_branches))
	var endpoint
	for i in range(0, branch_count):
		var start_index : int = clamp(randf_range(bias*(main_path.size()), main_path.size()), 0, main_path.size()-1)
		var local_end : Vector3 = Vector3(randf_range(-0.5,0.5), randf_range(-0.5,0.5), randf_range(-0.5,0.5))
		if branches_to_end:
			endpoint = end + Vector3(randf_range(-max_branch_deviation, max_branch_deviation), randf_range(-max_branch_deviation, max_branch_deviation), randf_range(-max_branch_deviation, max_branch_deviation))
		else:
			#endpoint = main_path[start_index]+local_end * (increments*lighnting_subdivisions)
			endpoint = main_path[start_index]+ (local_end * (increments * randf_range(lighnting_subdivisions*0.55,lighnting_subdivisions*0.95)))
		var branch_path : Array = _create_lightning_points(
			main_path[start_index],
			endpoint,
			max_branch_deviation)
		branch_path.reverse()
		lightnings[i] = branch_path

func _update() -> void:
	var main_path : Array = _create_lightning_points(end, origin, max_deviation)
	main_path.reverse()
	lightnings.clear()
	lightnings["main"] = main_path
	_create_branches(main_path)

func _timer_update() -> void:
	timer = get_tree().create_timer(update_timeout)
	timer.connect("timeout", Callable(self, "_timer_update"))
	_update()	
	
func _ready():
	if update_mode == UPDATE_MODE.ON_TIMEOUT:
		_timer_update()
	_setup_lightning()


func _process(delta):
	if update_mode == UPDATE_MODE.ON_PROCESS:
		cumulative_delta += delta
		if cumulative_delta > maximum_update_delta:
			cumulative_delta = 0.0
			_update()
	_update_lightning()

func _physics_process(delta):
	if update_mode == UPDATE_MODE.ON_PHYSICS:
		cumulative_delta += delta
		if cumulative_delta > maximum_update_delta:
			cumulative_delta = 0.0
			_update()

func set_origin(origin : Vector3):
	self.origin = origin
	_update()

func set_end(end : Vector3):
	self.end = end
	_update()

func set_origin_from_global(global_origin : Vector3):
	self.origin = to_local(global_origin)
	_update()

func set_end_from_global(global_end : Vector3):
	self.end = to_local(global_end)
	_update()

