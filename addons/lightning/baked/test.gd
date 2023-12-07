extends Node3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass



func _on_CheckButton_toggled(button_pressed):
	if not button_pressed:
		$Lightning3D.hide()
	else:
		$Lightning3D.show()



func _on_add_button_pressed(extra_arg_0: int) -> void:
	for _i in range(extra_arg_0):
		var new_lightning = preload("res://addons/lightning/baked/Lightning3D.tscn").instantiate()
		new_lightning.curve = $Lightning3D.curve
		add_child(new_lightning)
