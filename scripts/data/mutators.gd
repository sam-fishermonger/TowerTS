class_name Mutators
extends RefCounted
## Mutateurs : des règles du défi du jour (monstres rapides, hordes…) à activer avant de
## rejouer un niveau de la campagne déjà gagné. Ils s'ajoutent à la difficulté choisie,
## et chaque mutateur actif fait gagner une étoile infinie à la victoire, jusqu'à
## MAX_STARS par niveau (le meilleur résultat est gardé, voir Progress.record_mutators()).
## Les mutateurs choisis sont enregistrés (réglage SETTING) et valent pour toutes les
## parties suivantes sur un niveau déjà gagné, jusqu'à ce qu'on les retire.

## Règles proposées comme mutateurs, dans l'ordre de l'écran (Deux tours seulement n'en
## fait pas partie : le choix des tours de la difficulté la remplace).
const LIST: Array[int] = [DailyChallenge.RAPIDES, DailyChallenge.CORIACES, DailyChallenge.NOMBREUX,
	DailyChallenge.OR_SERRE, DailyChallenge.VIES_COMPTEES, DailyChallenge.SANS_AMELIORATION]
const SETTING := "mutators"
## Étoiles infinies qu'un niveau peut rapporter avec des mutateurs.
const MAX_STARS := 3
const COLOR := Color(0.95, 0.55, 0.85)


## Mutateurs choisis (dans l'ordre de LIST).
static func get_active() -> Array[int]:
	var saved: Array = Progress.get_setting(SETTING, [])
	var result: Array[int] = []
	for rule in LIST:
		if saved.has(rule):
			result.append(rule)
	return result


static func set_active(rules: Array[int]) -> void:
	var saved: Array[int] = []
	for rule in LIST:
		if rules.has(rule):
			saved.append(rule)
	Progress.set_setting(SETTING, saved)


## Active ou retire un mutateur.
static func set_enabled(rule: int, enabled: bool) -> void:
	var rules := get_active()
	if enabled and not rules.has(rule):
		rules.append(rule)
	elif not enabled:
		rules.erase(rule)
	set_active(rules)


## Étoiles infinies que rapporte une victoire avec ces mutateurs.
static func stars_for(rules: Array[int]) -> int:
	return mini(rules.size(), MAX_STARS)


## Les mutateurs s'appliquent aux niveaux de la campagne déjà gagnés (dans n'importe
## quelle difficulté).
static func applies_to(campaign: Campaign, level_path: String) -> bool:
	return campaign != null and campaign.world_index_of(level_path) >= 0 and Progress.get_stars(level_path) > 0


## Règles des mutateurs, une ligne chacune (traduites).
static func describe(rules: Array[int]) -> Array[String]:
	var result: Array[String] = []
	for rule in rules:
		result.append(DailyChallenge.describe_rule(rule))
	return result


## « Monstres rapides, Hordes » (traduit).
static func names(rules: Array[int]) -> String:
	var result := PackedStringArray()
	for rule in rules:
		result.append(TranslationServer.translate(DailyChallenge.RULE_NAMES[rule]))
	return ", ".join(result)
