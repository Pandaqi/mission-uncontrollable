extends Sprite

var word = "NO"

func set_word(word):
	var cont = get_node("LetterContainer")
	var key_sprite = load("res://scenes/KeySprite.tscn")
	
	var word_len = word.length()
	var key_sprite_size = Vector2(32, 0)
	for j in (word_len):
		var letter = key_sprite.instance()
		
		letter.position = j*key_sprite_size
		letter.get_node("Label").set_text(word.substr(j,1))
		
		cont.add_child(letter)
	
	cont.position = -floor(0.5*word_len)*key_sprite_size
	
	self.word = word
