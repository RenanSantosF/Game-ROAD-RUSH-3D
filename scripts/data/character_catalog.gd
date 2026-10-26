class_name CharacterCatalog
extends RefCounted
## Lista de personagens. Para criar um novo, copie um bloco e mude
## id (único), nome, preço e cores. "accessory" aceita:
## "cap", "ponytail", "antenna" ou "ears".

const DEFAULT_ID := "rui"

const CHARACTERS := [
	{
		"id": "rui",
		"name": "Rui",
		"price": 0,
		"description": "O corredor mais rápido do bairro.",
		"skin": Color(0.96, 0.78, 0.62),
		"shirt": Color(0.92, 0.27, 0.25),
		"pants": Color(0.2, 0.32, 0.62),
		"shoes": Color(0.97, 0.97, 0.97),
		"hair": Color(0.25, 0.16, 0.1),
		"accessory": "cap",
		"accent": Color(0.15, 0.45, 0.92),
	},
	{
		"id": "bia",
		"name": "Bia",
		"price": 300,
		"description": "Skatista e campeã de atletismo.",
		"skin": Color(0.72, 0.5, 0.36),
		"shirt": Color(0.6, 0.36, 0.88),
		"pants": Color(0.12, 0.6, 0.6),
		"shoes": Color(1.0, 0.45, 0.65),
		"hair": Color(0.18, 0.1, 0.07),
		"accessory": "ponytail",
		"accent": Color(1.0, 0.85, 0.2),
	},
	{
		"id": "bip",
		"name": "Robô Bip",
		"price": 800,
		"description": "Um robô curioso que adora moedas.",
		"skin": Color(0.72, 0.77, 0.82),
		"shirt": Color(0.3, 0.72, 0.92),
		"pants": Color(0.42, 0.45, 0.5),
		"shoes": Color(0.25, 0.27, 0.3),
		"hair": Color(0.72, 0.77, 0.82),
		"accessory": "antenna",
		"accent": Color(1.0, 0.3, 0.3),
	},
	{
		"id": "miau",
		"name": "Gato Miau",
		"price": 1500,
		"description": "Sete vidas? Aqui é só uma!",
		"skin": Color(1.0, 0.62, 0.22),
		"shirt": Color(0.3, 0.75, 0.35),
		"pants": Color(0.95, 0.95, 0.9),
		"shoes": Color(0.95, 0.4, 0.3),
		"hair": Color(1.0, 0.62, 0.22),
		"accessory": "ears",
		"accent": Color(1.0, 0.6, 0.7),
	},
]


static func count() -> int:
	return CHARACTERS.size()


static func get_by_index(index: int) -> Dictionary:
	return CHARACTERS[wrapi(index, 0, CHARACTERS.size())]


static func index_of(id: String) -> int:
	for i in CHARACTERS.size():
		if CHARACTERS[i]["id"] == id:
			return i
	return 0


static func get_by_id(id: String) -> Dictionary:
	return CHARACTERS[index_of(id)]
