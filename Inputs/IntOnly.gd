extends LineEdit

signal value_updated(new_value);

var regex = RegEx.new();
var old_text = "";

func _ready():
	regex.compile("^[0-9]*$");

func _on_LineEdit_text_changed(new_text):
	if regex.search(new_text):
		text = new_text;
		old_text = new_text;
		value_updated.emit(int(text));
	
	else:
		text = old_text;
	
	set_caret_column(text.length());

func get_value():
	return(int(text));
