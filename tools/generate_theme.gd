extends SceneTree
## Regénère le thème global de l'interface à partir de scripts/ui/ui_style.gd :
## godot --headless --path . -s res://tools/generate_theme.gd

const THEME_PATH := "res://resources/ui/theme.tres"


func _initialize() -> void:
	var error := ResourceSaver.save(UiStyle.build_theme(), THEME_PATH)
	print("Thème écrit dans %s" % THEME_PATH if error == OK else "Échec de l'écriture du thème : %s" % error_string(error))
	quit(error)
