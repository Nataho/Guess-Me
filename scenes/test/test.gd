extends Control

@onready var http_request = $HTTPRequest

func _ready():
	# Example: Check if "apple" is a valid word
	check_word("appla")
	print("phew")

func check_word(word: String):
	var url = "https://api.dictionaryapi.dev/api/v2/entries/en/" + word
	var error = http_request.request(url)
	
	if error != OK:
		print("An error occurred in the HTTP request.")

# This function runs when the API responds
func _on_http_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		print("Valid word! Definition: ", json[0]["meanings"][0]["definitions"][0]["definition"])
		# Logic to color your Wordle tiles green/yellow goes here
	elif response_code == 404:
		print("Not a real word. Try again!")
	else:
		print("API Error: ", response_code)
