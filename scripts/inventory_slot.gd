extends Button
## A drag stays inside the four weapon slots. Direct actions stay separate.
var controls: Node
var slot_index := 0
var dragged := false
func _ready() -> void:
	pressed.connect(func():
		if not dragged:controls.swap_slot(slot_index))
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:dragged=false
func _get_drag_data(_position: Vector2) -> Variant:
	if not is_instance_valid(controls) or not controls.inventory_open or controls.slots[slot_index].is_empty():return null
	dragged=true
	controls.swap_from=-1
	controls.refresh_slots()
	var preview:=PanelContainer.new()
	preview.theme=preload("res://scripts/visual_assets.gd").ui_theme()
	preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var title:=Label.new()
	title.text=str(controls.slots[slot_index]).capitalize()
	title.add_theme_font_size_override("font_size",12)
	preview.add_child(title)
	set_drag_preview(preview)
	return {"miro_inventory_owner":controls.get_instance_id(),"slot":slot_index}
func _can_drop_data(_position: Vector2,data: Variant) -> bool:
	return is_instance_valid(controls) and controls.inventory_open and data is Dictionary and int(data.get("miro_inventory_owner",0))==controls.get_instance_id() and int(data.get("slot",-1)) in range(4)
func _drop_data(_position: Vector2,data: Variant) -> void:
	if not _can_drop_data(Vector2.ZERO,data):return
	dragged=true
	controls.swap_from=-1
	controls.swap_slot(int(data.slot))
	controls.swap_slot(slot_index)
func _notification(what: int) -> void:
	if what==NOTIFICATION_DRAG_END:set_deferred("dragged",false)
