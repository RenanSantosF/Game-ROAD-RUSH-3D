class_name CharacterCatalog
extends RefCounted
## Lista de bichinhos jogáveis. "name" e "description" são chaves de tradução
## (veja scripts/autoload/localization.gd). "species" define o formato do modelo
## (chicken, duck, pig, cat) e "color"/"accent" as cores principais.

const DEFAULT_ID := "galinha"

const CHARACTERS := [
	{
		"id": "galinha",
		"name": "CHAR_GALINHA",
		"price": 0,
		"description": "CHAR_GALINHA_DESC",
		"species": "chicken",
		"color": Color(0.98, 0.98, 0.96),
		"accent": Color(0.92, 0.2, 0.2),
	},
	{
		"id": "pato",
		"name": "CHAR_PATO",
		"price": 300,
		"description": "CHAR_PATO_DESC",
		"species": "duck",
		"color": Color(1.0, 0.85, 0.2),
		"accent": Color(1.0, 0.55, 0.1),
	},
	{
		"id": "porco",
		"name": "CHAR_PORCO",
		"price": 800,
		"description": "CHAR_PORCO_DESC",
		"species": "pig",
		"color": Color(1.0, 0.68, 0.74),
		"accent": Color(0.92, 0.5, 0.58),
	},
	{
		"id": "gato",
		"name": "CHAR_GATO",
		"price": 1500,
		"description": "CHAR_GATO_DESC",
		"species": "cat",
		"color": Color(1.0, 0.6, 0.22),
		"accent": Color(0.8, 0.4, 0.1),
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
