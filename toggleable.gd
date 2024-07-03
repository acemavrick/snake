extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("toggled", _on_toggle)

func _on_toggle(on):
	text = "ON" if on else "OFF"
