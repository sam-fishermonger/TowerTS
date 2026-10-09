class_name Unlocks
extends RefCounted
## Déblocage progressif des modes de jeu : au départ, seuls la campagne, le tutoriel et
## la sélection des mondes sont ouverts. Les autres modes (et l'éditeur, les mutateurs)
## s'ouvrent l'un après l'autre avec le nombre de niveaux de la campagne gagnés, dans
## n'importe quelle difficulté (déjà enregistré : un joueur qui a passé un seuil garde
## l'accès). Un bouton verrouillé affiche une bulle (LockBubble) avec get_hint().

enum Feature { DAILY, ENDLESS, EDITOR, FREE_LEVELS, EXPEDITION, MUTATORS, CONQUEST }

const CAMPAIGN: Campaign = preload("res://resources/campaign.tres")
## Niveaux de la campagne à gagner pour ouvrir chaque mode, dans l'ordre du déblocage.
const LEVELS_WON := {
	Feature.DAILY: 3,
	Feature.ENDLESS: 4,
	Feature.EDITOR: 5,
	Feature.FREE_LEVELS: 7,
	Feature.EXPEDITION: 10,
	Feature.MUTATORS: 12,
	Feature.CONQUEST: 14,
}
## Nom du mode dans la bulle (« pour débloquer le défi du jour »).
const NAMES := {
	Feature.DAILY: "le défi du jour",
	Feature.ENDLESS: "le mode infini",
	Feature.EDITOR: "l'éditeur de niveau",
	Feature.FREE_LEVELS: "les niveaux libres",
	Feature.EXPEDITION: "l'Expédition",
	Feature.MUTATORS: "les mutateurs",
	Feature.CONQUEST: "la Conquête",
}


## Niveaux de la campagne gagnés (au moins une étoile, dans n'importe quelle difficulté).
static func get_levels_won() -> int:
	var count := 0
	for path in CAMPAIGN.levels:
		if Progress.get_stars(path) > 0:
			count += 1
	return count


static func is_unlocked(feature: Feature) -> bool:
	return get_levels_won() >= LEVELS_WON[feature]


## Comment débloquer le mode, avec la progression ("" s'il est déjà ouvert).
static func get_hint(feature: Feature) -> String:
	if is_unlocked(feature):
		return ""
	var needed: int = LEVELS_WON[feature]
	return TranslationServer.translate("Gagnez %d niveaux de la campagne pour débloquer %s.") \
		% [needed, TranslationServer.translate(NAMES[feature])] + "\n" \
		+ TranslationServer.translate("Niveaux gagnés : %d / %d") % [get_levels_won(), needed]


## Modes ouverts par la victoire qui vient de faire passer de `before` à `after` niveaux
## gagnés, dans l'ordre du déblocage.
static func unlocked_between(before: int, after: int) -> Array[Feature]:
	var result: Array[Feature] = []
	for feature: Feature in LEVELS_WON:
		if before < LEVELS_WON[feature] and after >= LEVELS_WON[feature]:
			result.append(feature)
	return result
