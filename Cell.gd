class_name Cell extends Sprite2D

var border: bool = false;
var added_to_pattern: bool = false;

var potential: float = 0.86;
var from = "";

@onready var label = %Label;
@onready var fromUp = %FromUp;
@onready var fromRight = %FromRight;
@onready var fromDown = %FromDown;
@onready var fromLeft = %FromLeft;
@onready var fromSeed = %FromSeed;

func _process(delta: float) -> void:
	if Global.show_potential_label:
		label.text = "%1.2f" % potential;
	else:
		label.text = "";
		
	if border:
		self_modulate = Color.from_hsv(0.0, 0.0, 0.0);
	elif Global.show_potential_color:
		if added_to_pattern:
			self_modulate = Color.from_hsv(0.0, 1.0, 1.0);
		else:
			self_modulate = Color.from_hsv(potential * 240/360, 1.0, 1.0);
	else:
		self_modulate = Color.from_hsv(1.0, 0.0, 1.0);
		
	match from:
		"up":
			fromUp.visible = true;
		"right":
			fromRight.visible = true;
		"down":
			fromDown.visible = true;
		"left":
			fromLeft.visible = true;
		"seed":
			fromSeed.visible = true;
