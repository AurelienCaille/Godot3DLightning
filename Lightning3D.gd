tool

extends Path

export(String, "Plane", "Curved") var lightning_mode = "Plane"
export var bake : bool = false setget set_bake
export var lightning_material : Material = preload("res://Lightning3D.tres")
export var lightning_curved_material : Material = preload("res://Lightning3DCurved.tres")
export var meshs : Array
export var width : float = 0.5 setget set_width
export var n_points : int = 4.0

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
		
		
	match lightning_mode:
		"Plane":
			create_planes_meshs()
		
		"Curved":
			create_curved_meshs()
			
	
	
func create_curved_meshs():
	"""
	"""
	
	#prend n points sur la courbe à équidistance
	#récupère les points à d distance du point
	#trace le meshs avec l'ensemble de points
	var curve_length : float = curve.get_baked_length()
	var points = []
	
	for i in range(n_points):
		var distance_along_curve = curve_length / float(n_points) * float(i)
		var point : Vector3 = curve.interpolate_baked(distance_along_curve)
		var point_up : Vector3 = curve.interpolate_baked_up_vector(distance_along_curve)
		var point_down : Vector3
		
		point_up = point_up.normalized() * width / 2.0
		
		points.append([point, point_up])


	var array_mesh = ArrayMesh.new()
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)

	# PoolVectorXXArrays for mesh construction.
	var verts = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()
	var indices = PoolIntArray()

	#######################################
	## Insert code here to generate mesh ##
	#######################################
	for i in range(points.size()-1):
		var point_info = points[i]
		var point_next_info = points[i+1]
		
		var point : Vector3 = point_info[0]
		var point_up : Vector3 = point_info[1]
		
		var point_next : Vector3 = point_next_info[0]
		var point_next_up : Vector3 = point_next_info[1]
		
		var p1 = point + point_up
		var p2 = point - point_up
		var p3 = point_next + point_next_up
		var p4 = point_next - point_next_up
		
		verts.append_array(PoolVector3Array([p1, p2, p3]))
		verts.append_array(PoolVector3Array([p3, p2, p4]))
		
	var colors := []
	for i in range(verts.size()):
		colors.append(Color.red)
		uvs.append(Vector2(1.0/verts.size()*float(i), 1.0/verts.size()*float(i)))
	arr[Mesh.ARRAY_COLOR] = PoolColorArray(colors)

	# Assign arrays to mesh array.
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	#arr[Mesh.ARRAY_NORMAL] = normals
	#arr[Mesh.ARRAY_INDEX] = indices

	# Create mesh surface from mesh array.
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr) # No blendshapes or compression used.
	ResourceSaver.save("res://sphere.tres", array_mesh, 32)
	
	# Create a visual instance (for 3D).
	var instance = VisualServer.instance_create()
	# Set the scenario from the world, this ensures it
	# appears with the same objects as the scene.
	var world = get_world()
	var scenario = world.scenario
	VisualServer.instance_set_scenario(instance, scenario)
	# Add a mesh to it.
	# Remember, keep the reference.

	var mesh = array_mesh
	meshs.append(mesh)
	
	VisualServer.instance_set_base(instance, mesh)
	VisualServer.mesh_surface_set_material(mesh, 0, lightning_curved_material.get_rid())
	
	



func create_planes_meshs():
	for index_point in curve.get_point_count():
		if index_point +1 == curve.get_point_count():
			return
		
		var origin : Vector3 = curve.get_point_position(index_point)
		var extremity : Vector3 = curve.get_point_position(index_point+1)
		
		create_plane_mesh(origin, extremity)
		
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
