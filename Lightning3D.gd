tool

extends Path

class_name Lightning3D

export(String, "Plane", "Curved") var lightning_mode = "Plane"
export var bake : bool = false setget set_bake
export var lightning_material : Material = preload("res://Lightning3D.tres")
export var meshs : Array
export var width : float = 0.5 setget set_width

func _ready():
	connect("curve_changed", self, "_on_path_curve_changed")
		
	creates_meshs()


func set_bake(_bake):
	""" Used to force meshs creations """
	creates_meshs()
	
func set_width(new_width):
	width = new_width
	creates_meshs()
	
func creates_meshs():
	#Clean old meshs
	clean_meshs()
	print("plup")
	
	if not is_inside_tree():
		return
	
	if not is_visible_in_tree():
		return
	
	for index_point in curve.get_point_count():
		if index_point +1 == curve.get_point_count():
			return
		
		var origin : Vector3 = curve.get_point_position(index_point)
		var extremity : Vector3 = curve.get_point_position(index_point+1)
	
		match lightning_mode:
			"Plane":
				create_plane_mesh(origin, extremity)
			
			"Curved":
				pass
		
func clean_meshs():
	for mesh in meshs:
		VisualServer.mesh_clear(mesh.get_rid())
		mesh = null

	meshs = []
	
func create_plane_mesh(origin : Vector3, extremity: Vector3):
	var mesh_plane = PlaneMesh.new()
	var direction : Vector3 = extremity - origin
	var norm_direction : Vector3 = direction.normalized()
	var distance = direction.length()
	
	var mesh_size : Vector2 = Vector2(
		width,
		distance
	)
	
	mesh_plane.size = mesh_size

	# Create a visual instance (for 3D).
	var instance = VisualServer.instance_create()
	# Set the scenario from the world, this ensures it
	# appears with the same objects as the scene.
	var world = get_world()
	var scenario = world.scenario
	VisualServer.instance_set_scenario(instance, scenario)
	# Add a mesh to it.
	# Remember, keep the reference.

	var mesh = mesh_plane
	meshs.append(mesh)
	
	VisualServer.instance_set_base(instance, mesh)
	VisualServer.mesh_surface_set_material(mesh, 0, lightning_material.get_rid())
	# Move the mesh around.
	var position3D : Vector3 = origin + norm_direction * (mesh_size.y/2.0)
	var xform = Transform(Basis(), position3D + self.global_transform.origin)
	xform = xform.looking_at(extremity + self.global_transform.origin, Vector3.UP)
	
	VisualServer.instance_set_transform(instance, xform)


func _on_path_curve_changed():
	creates_meshs()


func _on_Lightning3D_visibility_changed():
	if visible:
		creates_meshs()
	else:
		clean_meshs()


func _on_Lightning3D_tree_exiting():
	clean_meshs()


func _on_Lightning3D_tree_entered():
	creates_meshs()
