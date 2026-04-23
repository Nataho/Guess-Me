extends Control

# nodes
@onready var bg: ColorRect = $bg
@onready var guess_grid: GridContainer = $grid_pivot/guess_grid; @onready var grid_pivot: Control = $grid_pivot
@onready var word: Label = $word_pivot/word; @onready var word_pivot: Control = $word_pivot
@onready var again_button: Button = $button_pivot/again; @onready var button_pivot: Control = $button_pivot

var grid:Array[Letter] = []
var word_length = 5
var guesses = 6

var attempt: int = 0 
var letter_position: int = 0 

var grid_target_pos = Vector2(0,0)
var word_target_pos = Vector2(0,0)
var button_target_pos = Vector2(0,720)

var has_word:bool = false
var first_start:bool = true
var can_type:bool = false
var is_online = false

var hidden_positions := {}

func _reset_positions():
	if first_start:
		grid_pivot.global_position = hidden_positions["center"]
		button_pivot.global_position = hidden_positions["top"]
		word_pivot.global_position = hidden_positions["bottom"]
		first_start = false
	grid_target_pos = hidden_positions["center"]
	button_target_pos = hidden_positions["top"]
	word_target_pos = hidden_positions["bottom"]
	
	_start_game()

func _start_game():
	again_button.release_focus()
	if has_word:
			# 1. Reset game state counters
			attempt = 0
			letter_position = 0
			has_word = false
			can_type = false
			
			# 2. Clear the physical nodes from the scene
			# We use a reverse loop to safely delete nodes
			for i in range(guess_grid.get_child_count() - 1, -1, -1):
				var child = guess_grid.get_child(i)
				guess_grid.remove_child(child)
				child.queue_free()
			
			# 3. Clear the internal tracking array
			grid.clear()
	
	is_online = true
	DictionaryApi.get_random_word(word_length)
	var our_word:String = await DictionaryApi.random_word_found
	Letter.set_word(our_word)
	word.text = our_word.to_upper()
	has_word = true
	
	# 2. Build the grid
	_create_grid()
	
	# 3. Wait for the engine to calculate UI sizes
	await get_tree().process_frame
	
	grid_target_pos = _get_screen_center()
	can_type = true

func _ready() -> void:
	hidden_positions = {
		"center": $targets/center.global_position,
		"top": $targets/hid_top.global_position,
		"mid_top": $targets/mid_top.global_position,
		"mid_bottom": $targets/mid_bottom.global_position,
		"bottom": $targets/hid_bottom.global_position,
		"left": $targets/hid_left.global_position,
		"right": $targets/hid_right.global_position,
	}
	_connect_signals()
	_reset_positions()
	
	#_start_game()

func _connect_signals():
	again_button.pressed.connect(_reset_positions)

func _get_screen_center() -> Vector2:
	return get_viewport_rect().size / 2

func _physics_process(delta: float) -> void:
	### Smooth movement to the calculated targets
	#if !has_word: return
	grid_pivot.global_position = grid_pivot.global_position.lerp(grid_target_pos, 5 * delta)
	word_pivot.global_position = word_pivot.global_position.lerp(word_target_pos, 5 * delta)
	button_pivot.global_position = button_pivot.global_position.lerp(button_target_pos, 5 * delta)

func _create_grid():
	for child in guess_grid.get_children():
		child.queue_free()
	grid.clear()
	
	guess_grid.columns = word_length
	
	for y in range(guesses):
		await get_tree().create_timer(0.1).timeout
		for x in range(word_length):
			#await get_tree().create_timer(0.01).timeout
			var letter_obj = Letter.create(x) 
			grid.append(letter_obj)
			guess_grid.add_child(letter_obj)
			
	alter_grid_pivot()

func alter_grid_pivot():
	guess_grid.force_update_transform()
	guess_grid.pivot_offset = guess_grid.size / 2

func _unhandled_input(event):
	if !can_type: return
	if event is InputEventKey and event.pressed:
		
		if event.keycode == KEY_BACKSPACE:
			if letter_position > 0:
				letter_position -= 1
				_get_current_tile()._display_letter("") 
			return

		if event.keycode == KEY_ENTER:
			if letter_position == word_length:
				_submit_row()
			return

		if event.unicode > 31: 
			if letter_position < word_length:
				var typed_char = char(event.unicode)
				if _get_current_tile().type(typed_char):
					letter_position += 1

func _get_current_tile() -> Letter:
	var index = (attempt * word_length) + letter_position
	if index < grid.size():
		return grid[index]
	return null

func _get_current_word_attempt() -> String:
	var output:String = ""
	for x in range(word_length):
		var pos = (attempt * word_length) + x
		output += grid[pos].get_letter()
	return output

func _throw_error(text:String):
	$error.text = text
	$error.show()
	await get_tree().create_timer(5).timeout
	$error.hide()

func _submit_row():
	if is_online:
		print("validating")
		var my_word = _get_current_word_attempt()
		print("my_word: " ,my_word)
		DictionaryApi.check_valid_word(my_word)
		var is_valid = await DictionaryApi.word_validated
		print("validated")
		if !is_valid:
			_throw_error("Not a valid word!")
			return
	
	for i in range(word_length):
		var index = (attempt * word_length) + i
		grid[index].submit()
		await get_tree().create_timer(0.05).timeout
	
	if attempt < guesses - 1:
		attempt += 1
		letter_position = 0
		
	else:
		await get_tree().create_timer(1).timeout
		var screen_center = _get_screen_center()
		grid_target_pos = hidden_positions["right"]
		word_target_pos = hidden_positions["mid_top"] + Vector2(0,100)
		button_target_pos = hidden_positions["mid_bottom"]
		print("Game Over!")
		print("the word was: ", Letter.word)
