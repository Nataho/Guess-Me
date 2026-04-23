extends HTTPRequest

# Signals to notify the main game when data is ready
signal word_validated(is_valid: bool)
signal random_word_found(word: String)
signal offline_set_ready(words: Array)

# Internal tracking for bulk requests
var _target_amount: int = 0
var _current_mode: String = ""

func _ready():
	# Connect the built-in signal to our internal handler
	request_completed.connect(_on_request_completed)

## 1. Validates if a single word exists (Dictionary API)
func check_valid_word(word: String):
	_current_mode = "VALIDATE"
	var url = "https://api.dictionaryapi.dev/api/v2/entries/en/" + word.to_lower()
	var error = request(url)
	
	if error != OK:
		push_error("Dictionary Request failed")

## 2. Gets one random word of a specific length (Datamuse API)
func get_random_word(length: int = 5):
	_current_mode = "RANDOM"
	var pattern = "?".repeat(length)
	var url = "https://api.datamuse.com/words?sp=" + pattern + "&max=100"
	var error = request(url)
	if error != OK:
		push_error("Random Word Request failed")
	else:
		print("Random Word Granted")

## 3. Gets a bulk list of words for "offline" use (Datamuse API)
func get_offline_set(length: int = 5, amount: int = 100):
	_current_mode = "SET"
	_target_amount = amount
	var pattern = "?".repeat(length)
	# We fetch more than needed (max=1000) so we can shuffle and get variety
	var url = "https://api.datamuse.com/words?sp=" + pattern + "&max=1000"
	var error = request(url)
	if error != OK:
		push_error("Offline Set Request failed")

## Internal Response Handler
func _on_request_completed(result, response_code, headers, body):
	var json_data = JSON.parse_string(body.get_string_from_utf8())
	
	match _current_mode:
		"VALIDATE":
			# Dictionary API returns 200 for valid, 404 for invalid
			word_validated.emit(response_code == 200)
			
		"RANDOM":
			if json_data is Array and json_data.size() > 0:
				var word = json_data.pick_random()["word"]
				random_word_found.emit(word)
				
		"SET":
			if json_data is Array:
				var words = []
				for entry in json_data:
					# Filter out words with spaces or hyphens (bad for Wordle)
					var w = entry["word"]
					if not (" " in w or "-" in w):
						words.append(w)
				
				words.shuffle()
				var final_set = words.slice(0, _target_amount)
				offline_set_ready.emit(final_set)
