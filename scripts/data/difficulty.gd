class_name Difficulty
extends RefCounted
## Niveaux de difficulté d'un niveau de la campagne : ils changent la vie (et le
## bouclier), le nombre et la vitesse des monstres. Chaque difficulté a ses propres
## étoiles : un niveau en rapporte jusqu'à 3 par difficulté. La difficulté se choisit
## dans la sélection des mondes et vaut pour les parties suivantes (réglage enregistré).
## Moyen est l'équilibrage des niveaux tel qu'il est réglé dans leurs scènes ; le mode
## infini et la partie de l'écran titre se jouent toujours en Moyen.

enum { FACILE, MOYEN, DIFFICILE, CAUCHEMAR }

const COUNT := 4
const DEFAULT := MOYEN
## Réglage (Progress) qui garde la difficulté choisie.
const SETTING := "difficulty"
const NAMES: Array[String] = ["Facile", "Moyen", "Difficile", "Cauchemar"]
const COLORS: Array[Color] = [Color(0.55, 0.9, 0.5), Color(0.95, 0.85, 0.45), Color(1.0, 0.6, 0.3),
	Color(0.95, 0.35, 0.45)]
## Multiplicateur de la vie et du bouclier des monstres.
const HEALTH: Array[float] = [0.7, 1.0, 1.35, 1.75]
## Multiplicateur du nombre de monstres de chaque groupe des vagues (au moins 1 par groupe).
const ENEMY_COUNT: Array[float] = [0.75, 1.0, 1.25, 1.5]
## Multiplicateur de la vitesse des monstres.
const SPEED: Array[float] = [0.9, 1.0, 1.1, 1.2]
## Nombre de tours différentes qu'on peut prendre dans un niveau : avec plus de tours
## débloquées, on choisit lesquelles au lancement du niveau.
const TOWER_LIMITS: Array[int] = [9, 8, 6, 5]


## Difficulté choisie par le joueur.
static func get_current() -> int:
	return clampi(Progress.get_setting(SETTING, DEFAULT), 0, COUNT - 1)


static func set_current(difficulty: int) -> void:
	Progress.set_setting(SETTING, clampi(difficulty, 0, COUNT - 1))


## « 6 tours différentes au plus par niveau. »
static func describe_tower_limit(difficulty: int) -> String:
	return "%d tours différentes au plus par niveau." % TOWER_LIMITS[difficulty]


## Effets d'une difficulté, en une phrase : « Monstres 35 % plus résistants, 25 % plus
## nombreux et 10 % plus rapides. »
static func describe(difficulty: int) -> String:
	if difficulty == MOYEN:
		return "Les monstres tels que le niveau les prévoit."
	var parts: Array[String] = []
	for item in [[HEALTH[difficulty], "résistants"], [ENEMY_COUNT[difficulty], "nombreux"],
			[SPEED[difficulty], "rapides"]]:
		var percent := roundi((item[0] - 1.0) * 100.0)
		if percent != 0:
			parts.append("%d %% %s %s" % [absi(percent), "plus" if percent > 0 else "moins", item[1]])
	var text := ", ".join(parts.slice(0, -1)) + " et " + parts[-1] if parts.size() > 1 else parts[0]
	return "Monstres %s." % text
