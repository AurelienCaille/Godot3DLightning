@tool
#Lightning generator, used to generate lightning bolts
#The lightning bolt is a series of lines that are drawn 
#between the Position3D and random ray collisions
extends Marker3D
class_name LighningGeneratorBolt

@export var exceptions = [] #List of exceptions to the raycast # (Array, NodePath)
@export var max_ray_length: float = 10.0 #Maximum length of the ray
@export var min_ray_count: int = 1 #Minimum number of rays to be cast
@export var max_ray_count: int = 10 #Maximum number of rays to be cast
@export var ray_length_variance: float = 0.5 #Variance of the ray length
@export var lighnting_subdivisions: int = 10 #Number of subdivisions for the lightning bolt
@export var bolt_position_max_delta: float = 0.5 #Maximum delta of the bolt position before collision update

var raycasts : Array = [] #List of raycasts
var collision_positions : Array = [] #List of collision positions
var lightning_paths : Array = [] #List of lightning paths

@onready var previous_translation : Vector3 = global_transform.origin #Previous position of the bolt
var translation_delta : Vector3 = Vector3() #Delta of the bolt position

#Create raycasts
func _ray_setup() -> void:
	for i in max_ray_count:
		var new_ray = RayCast3D.new()
		raycasts.append(new_ray)
		collision_positions.append(Vector3.ZERO)
		new_ray.enabled = true
		for object_path in exceptions:
			var object = get_node(object_path)
			if object is PhysicsBody3D:
				new_ray.add_exception(object)
		add_child(new_ray)

#Add exceptions to the raycasts, for runtime use
func _ray_add_exception(object : PhysicsBody3D) -> void:
	for ray in raycasts:
		if is_instance_valid(object):
			ray.add_exception(object)

#Randomly generate the ray lengths
func _cast_rays() -> void:
	for ray in raycasts:
		ray.target_position = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		ray.target_position = ray.target_position.normalized()
		ray.target_position *= max_ray_length
		ray.force_raycast_update()
		

#Update the lighning collision positions
func _update_collisions() -> void:
	for i in raycasts.size():
		collision_positions[i] = raycasts[i].get_collision_point()

#Setup the visual lightning paths
func _setup_lightning() -> void:
	for i in raycasts.size():
		var new_lightning = Lightning3DBranched.new(7, 1.6, 3, 0.4, 0.6)
		lightning_paths.append(new_lightning)
		new_lightning.visible = false
		add_child(new_lightning)

#Update the lightning paths
func _update_lightning() -> void:
	for i in raycasts.size():
		if collision_positions[i] != Vector3.ZERO or collision_positions[i] != null:
			lightning_paths[i].visible = true
			lightning_paths[i].set_end_from_global(collision_positions[i])
		else:
			lightning_paths[i].visible = false
		lightning_paths[i].visible = true
		

#Setup everything when Node is ready
func _ready() -> void:
	randomize()
	_cast_rays()
	_ray_setup()
	_setup_lightning()
	_update_collisions()

#Update the bolt position and collision positions
func _physics_process(_delta):
	translation_delta = global_transform.origin - previous_translation
	if translation_delta.length() > bolt_position_max_delta:
		_cast_rays()
		_update_collisions()
		previous_translation = global_transform.origin

func _process(_delta):
	_update_lightning()







