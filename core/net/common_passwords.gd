class_name CommonPasswords
extends RefCounted
## Owner #105: the commonest passwords (lower case), never allowed as a password (PasswordRules.COMMON; the server's
## PasswordRules.COMMON is the same list: test_account_password_rules.gd), and the examples the game has ever shown. A
## refusal list, never shown to a child (like UsernameRules' blocked words), so test_costumes.gd's banned-name check of
## shipped strings leaves this file out (NEVER_SHOWN): some of the commonest passwords are characters' names.

const LIST: Array[String] = ["123456", "1234567", "12345678", "123456789", "1234567890", "0123456789", "654321",
	"987654321", "111111", "000000", "121212", "123123", "112233", "666666", "696969", "password", "password1",
	"password12", "password123", "passw0rd", "qwerty", "qwerty1", "qwerty123", "qwertyuiop", "asdfgh", "asdfghjkl", "zxcvbn",
	"zxcvbnm", "abc123", "abcdef", "abcdefg", "abcd1234", "iloveyou", "letmein", "welcome", "monkey", "dragon", "football",
	"baseball", "soccer", "princess", "sunshine", "superman", "batman", "pokemon", "starwars", "secret", "hello123", "admin",
	"admin123", "trustno1", "freedom", "master", "shadow", "michael", "ashley", "jessica", "charlie", "computer",
	"internet", "easycraft", "easycraft1", "gamer123", "player1",
	"moon7tiger", "moontiger", "moontiger7", "moon7tigre", "sea4lantern", "river5stone"]   # examples the game has shown
