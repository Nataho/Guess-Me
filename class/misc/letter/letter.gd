class_name Letter extends Panel
const FILE = preload("uid://4n4gp4skni5")

static var word = "godot"
const _alphabet:String = "abcdefghijklmnopqrstuvwxyz"

@export var _letter:String = "A"
@export var _is_blank:bool = true
@export var _letter_position = -1 #-1 for error 

@onready var text: RichTextLabel = $text

const _colors = {
	"absent": Color("484848ff"),
	"blank": Color("13005A"),
	"present": Color("1C82AD"),
	"correct": Color("03C988")
}

static func create(word_position = -1, letter = "", is_blank = true) -> Letter:
	var obj:Letter = FILE.instantiate()
	obj._letter = letter
	obj._is_blank = is_blank
	
	assert(word_position != -1, "word position must not be empty") 
	obj._letter_position = word_position
	return obj
	
static func set_word(new_word:String):
	word = new_word.to_lower()
	
func _ready() -> void:
	$Letter/AnimationPlayer.play("spawn")
	text.text = _letter.to_upper()
	if !_is_blank:
		_start_check()
	_display_color(_colors["blank"])
	
	#await get_tree().create_timer(1).timeout

func _start_check(): 
	if _letter.length() > 1:
		_letter = _letter[0]

func _display_letter(letter:String):
	_letter = letter
	text.text = letter.to_upper()

func _display_color(new_color: Color):
	var stylebox = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if stylebox:
		stylebox.bg_color = new_color
		add_theme_stylebox_override("panel", stylebox)
		$Letter.add_theme_stylebox_override("panel", stylebox)

func type(letter:String) -> bool:
	if letter.length() == 1 and letter.to_lower() in _alphabet: 
		_display_letter(letter)
		return true
	return false

func submit():
	var low_letter = _letter.to_lower()
	var final_color = _colors["absent"]
	
	if low_letter in word:
		final_color = _colors["present"]
		
	if _letter_position < word.length() and low_letter == word[_letter_position]:
		final_color = _colors["correct"]
	
	_display_color(final_color)
	$Letter/AnimationPlayer.play("spawn")

func get_letter() -> String:
	return _letter
	
