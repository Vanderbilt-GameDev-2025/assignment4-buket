extends Node3D

var wave_height = 0.2
var color_strength = 10.0  # Starting value for water_color_strength

func _ready():
	var mat = $MeshInstance3D.mesh.surface_get_material(0) as ShaderMaterial
	if mat:
		mat.set_shader_parameter("height_scale", wave_height)
		mat.set_shader_parameter("water_color_strength", color_strength)

func _input(event):
	if event.is_action_pressed("ui_up"):
		wave_height += 0.05
		print("Up pressed -> wave_height:", wave_height)
	elif event.is_action_pressed("ui_down"):
		wave_height = max(0.0, wave_height - 0.05)
		print("Down pressed -> wave_height:", wave_height)

	if event.is_action_pressed("ui_right"):
		# Increase color_strength up to, say, 50 for dramatic effect
		color_strength = min(50.0, color_strength + 1.0)
		print("Right pressed -> water_color_strength:", color_strength)
	elif event.is_action_pressed("ui_left"):
		color_strength = max(0.0, color_strength - 1.0)
		print("Left pressed -> water_color_strength:", color_strength)

func _process(delta):
	var mat = $MeshInstance3D.mesh.surface_get_material(0) as ShaderMaterial
	if mat:
		mat.set_shader_parameter("height_scale", wave_height)
		mat.set_shader_parameter("water_color_strength", color_strength)
