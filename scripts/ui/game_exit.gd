class_name GameExit
extends Node
## Sortie du jeu : le bouton Quitter du menu principal et le bouton retour d'Android.
##
## Sur Android, get_tree().quit() seul ne suffit pas : le moteur tue son processus avant
## d'avoir fermé la tâche de l'activité, si bien que le jeu reste dans les applications
## récentes et que le système peut le relancer aussitôt. quit() ferme donc d'abord la
## tâche (Activity.finishAndRemoveTask), puis arrête le moteur.
##
## Le bouton (ou le geste) retour d'Android ne ferme plus le jeu d'un coup depuis n'importe
## quel écran (application/config/quit_on_go_back est coupé) : il fait comme Échap ou le
## bouton B de la manette (ui_cancel), sauf si l'écran affiché le traite lui-même
## (go_back(), qui renvoie true) : l'écran titre quitte le jeu depuis son menu principal.
##
## Le nœud est chargé au démarrage (autoload « Sortie ») ; quit() est statique.


## Quitte le jeu pour de bon, sur toutes les plateformes.
static func quit(tree: SceneTree) -> void:
	if OS.has_feature("android") and Engine.has_singleton("AndroidRuntime"):
		var activity: Object = Engine.get_singleton("AndroidRuntime").getActivity()
		if activity:
			activity.finishAndRemoveTask()
	tree.quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


## Retour d'Android : l'écran affiché le traite, ou c'est un appui sur ui_cancel.
func go_back() -> void:
	var scene := get_tree().current_scene
	if scene and scene.has_method(&"go_back") and scene.go_back():
		return
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = &"ui_cancel"
		event.pressed = pressed
		Input.parse_input_event(event)
