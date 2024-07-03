extends Button

@onready var loc = get_meta("page")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("pressed", _press)

func _press():
	%UI.setScene(loc)
