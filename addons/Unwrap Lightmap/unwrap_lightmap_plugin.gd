@tool
extends EditorPlugin

var button: Button

func _enter_tree() -> void:
	button = Button.new()
	button.text = "Unwrap Scene Lightmaps"
	button.flat = true
	button.pressed.connect(_on_button_pressed)
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, button)

func _exit_tree() -> void:
	if button:
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, button)
		button.queue_free()

func _on_button_pressed() -> void:
	var root = get_editor_interface().get_edited_scene_root()
	if not root:
		push_warning("No active scene open to unwrap.")
		return
	
	var count = _process_node(root)
	print("Successfully unwrapped UV2 for ", count, " mesh(es).")

func _process_node(node: Node) -> int:
	var count = 0
	
	if node is MeshInstance3D and node.mesh:
		var array_mesh: ArrayMesh = null
		
		# if primitive mesh, convert to arraymesh
		if not (node.mesh is ArrayMesh):
			var new_mesh = ArrayMesh.new()
			for surface_idx in range(node.mesh.get_surface_count()):
				var arrays = node.mesh.surface_get_arrays(surface_idx)
				new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
				new_mesh.surface_set_material(surface_idx, node.mesh.surface_get_material(surface_idx))
			node.mesh = new_mesh
			array_mesh = new_mesh
		else:
			array_mesh = node.mesh as ArrayMesh

		if array_mesh:
			# duplicate if resource is read-only or shared from import
			if array_mesh.resource_path.contains(".godot/imported"):
				array_mesh = array_mesh.duplicate() as ArrayMesh
				node.mesh = array_mesh
				
			var err = array_mesh.lightmap_unwrap(node.global_transform, 0.05)
			if err == OK:
				count += 1
			else:
				push_warning("Failed to unwrap UV2 for node: ", node.name, " (Error code: ", err, ")")

	for child in node.get_children():
		count += _process_node(child)
		
	return count
