class_name ChestBonus
extends RefCounted
## Bonus des coffres : un monstre porteur de coffre (Enemy.Carrier.CHEST) le lâche à sa
## mort, et le coffre ramassé donne au hasard un de ces bonus, pour le reste du niveau
## (pas au-delà : la progression d'une partie à l'autre reste l'arbre des améliorations).
## Un même bonus peut tomber plusieurs fois, jusqu'à son maximum. C'est le niveau (Level)
## qui garde les bonus gagnés et applique leurs effets.

const COLOR := Color(1.0, 0.78, 0.3)

const DAMAGE := &"chest_damage"
const RANGE := &"chest_range"
const FIRE_RATE := &"chest_fire_rate"
const BOUNTY := &"chest_bounty"
const WAVE_GOLD := &"chest_wave_gold"
const INTEREST := &"chest_interest"
const POWERS := &"chest_powers"
const WORKERS := &"chest_workers"

## Or donné par un coffre quand tous les bonus possibles sont au maximum.
const FALLBACK_GOLD := 60

## Fiche de chaque bonus : identifiant, nom, effet d'un exemplaire (description), valeur
## par exemplaire (per_level), nombre maximum et couleur. `needs` dit quand il peut tomber :
## "powers" (au moins un pouvoir), "interest" (le niveau a des intérêts), "conquest".
const DEFINITIONS: Array[Dictionary] = [
	{id = DAMAGE, name = "Poudre noire", per_level = 0.1, max = 3, color = Color(1.0, 0.55, 0.4),
		description = "Tours : +10 % de dégâts."},
	{id = RANGE, name = "Lentilles polies", per_level = 0.08, max = 3, color = Color(0.55, 0.8, 1.0),
		description = "Tours : +8 % de portée."},
	{id = FIRE_RATE, name = "Ressorts tendus", per_level = 0.08, max = 3, color = Color(0.7, 0.95, 0.5),
		description = "Tours : +8 % de cadence de tir."},
	{id = BOUNTY, name = "Bourse du chasseur", per_level = 0.2, max = 3, color = Color(1.0, 0.82, 0.25),
		description = "Monstres : +20 % d'or."},
	{id = WAVE_GOLD, name = "Butin de guerre", per_level = 0.25, max = 3, color = Color(1.0, 0.9, 0.5),
		description = "Bonus de vague : +25 % d'or."},
	{id = INTEREST, name = "Coffre-fort", per_level = 0.02, max = 3, color = Color(0.95, 0.75, 0.45),
		description = "Intérêts : +2 points, et plafond +10 or.", needs = "interest"},
	{id = POWERS, name = "Sablier", per_level = 0.15, max = 3, color = Color(0.75, 0.65, 1.0),
		description = "Pouvoirs : recharge 15 % plus courte.", needs = "powers"},
	{id = WORKERS, name = "Pioches d'acier", per_level = 0.2, max = 3, color = Color(0.78, 0.8, 0.88),
		description = "Ouvriers : minage et construction +20 %.", needs = "conquest"},
]
## Plafond des intérêts en plus, par Coffre-fort.
const INTEREST_CAP_PER_LEVEL := 10


static func get_definition(id: StringName) -> Dictionary:
	for definition in DEFINITIONS:
		if definition.id == id:
			return definition
	return {}


## Bonus qui peuvent encore tomber : pas au maximum (`levels` : exemplaires déjà gagnés,
## par identifiant), et utiles dans cette partie.
static func get_available(levels: Dictionary, has_powers: bool, has_interest: bool, is_conquest: bool) -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in DEFINITIONS:
		if levels.get(definition.id, 0) >= definition.max:
			continue
		match definition.get("needs", ""):
			"powers":
				if not has_powers:
					continue
			"interest":
				if not has_interest:
					continue
			"conquest":
				if not is_conquest:
					continue
		result.append(definition.id)
	return result


## Effet d'un bonus gagné `count` fois, sur une ligne courte, traduit : « +20 % dégâts ».
static func describe_total(id: StringName, count: int) -> String:
	var definition := get_definition(id)
	var percent := roundi(definition.per_level * count * 100.0)
	match id:
		DAMAGE:
			return TranslationServer.translate("+%d %% dégâts") % percent
		RANGE:
			return TranslationServer.translate("+%d %% portée") % percent
		FIRE_RATE:
			return TranslationServer.translate("+%d %% cadence") % percent
		BOUNTY:
			return TranslationServer.translate("+%d %% or des monstres") % percent
		WAVE_GOLD:
			return TranslationServer.translate("+%d %% bonus de vague") % percent
		INTEREST:
			return TranslationServer.translate("+%d %% intérêts") % percent
		POWERS:
			return TranslationServer.translate("-%d %% recharge") % percent
		WORKERS:
			return TranslationServer.translate("+%d %% travail") % percent
	return ""
