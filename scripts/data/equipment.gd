class_name Equipment
extends RefCounted
## Équipement des tours : des objets gardés d'une partie à l'autre, rangés dans
## l'inventaire et posés dans l'Armurerie sur un type de tour (le Canon, le Sniper…). Un
## objet posé renforce toutes les tours de ce type dans toutes les parties : bonus de
## caractéristiques (dégâts, portée, cadence…) ou effet en plus (brûlure, ralentissement,
## détection…). Chaque type de tour a SLOTS emplacements, et certains objets sont réservés
## à un type de tour.
##
## Les objets sortent des coffrets : une victoire dans un mode qui donne des étoiles
## (campagne, niveaux libres, Conquête) a des chances d'en donner un, et sa rareté dépend
## de la difficulté et de la place du niveau dans son monde. Les coffrets s'ouvrent dans
## l'Armurerie. Trois objets libres d'une même rareté se fondent en un coffret de la
## rareté au-dessus.
##
## Ces coffrets n'ont rien à voir avec les coffres lâchés en jeu par les porteurs
## (ChestBonus), dont les bonus ne durent que le niveau.
##
## Tout est enregistré dans la section « equipment » de la progression (Progress) :
## « items » (les objets, des dictionnaires { uid, kind, rarity, extra }), « equipped »
## (chemin de la TowerData -> uid des objets posés), « boxes » (rareté des coffrets pas
## encore ouverts) et « next_uid ». Comme l'arbre des améliorations, l'équipement ne compte
## pas pendant le défi du jour ni le tutoriel (Perks.DISABLED_META).

const SECTION := "equipment"
const ARMORY_SCREEN := "res://scenes/ui/armory_screen.tscn"
## Emplacements de chaque type de tour.
const SLOTS := 3
## Méta du moteur qui garde les effets posés sur chaque type de tour, { chemin: [[effet,
## valeur], …] } : les statistiques des tours sont recalculées très souvent, la
## progression n'est relue qu'après un changement. (Des tableaux et pas des objets :
## Godot signalerait une fuite.)
const CACHE_META := &"equipment_cache"

enum { COMMUN, RARE, EPIQUE, LEGENDAIRE }
const RARITY_COUNT := 4
## Noms des raretés (tr() à l'affichage) et leurs couleurs.
const RARITY_NAMES: Array[String] = ["Commun", "Rare", "Épique", "Légendaire"]
const RARITY_COLORS: Array[Color] = [Color(0.8, 0.84, 0.88), Color(0.35, 0.65, 1.0), Color(0.75, 0.45, 1.0),
	Color(1.0, 0.62, 0.15)]
## Nom des coffrets de chaque rareté (tr() à l'affichage).
const BOX_NAMES: Array[String] = ["Coffret commun", "Coffret rare", "Coffret épique", "Coffret légendaire"]
## Couleur de l'Armurerie et des coffrets dans les menus.
const COLOR := Color(1.0, 0.72, 0.3)

## Chances de gagner un coffret en finissant un niveau, par difficulté (Facile à
## Cauchemar). La première victoire d'un niveau dans une difficulté en donne toujours un.
const BOX_CHANCES: Array[float] = [0.3, 0.4, 0.5, 0.6]
## Chances de chaque rareté au plus bas (Facile, premier niveau d'un monde) et au plus haut
## (Cauchemar, dernier niveau d'un monde). Entre les deux, elles suivent la « qualité » du
## niveau (voir get_quality()).
const RARITY_CHANCES_LOW: Array[float] = [0.7, 0.24, 0.05, 0.01]
const RARITY_CHANCES_HIGH: Array[float] = [0.2, 0.4, 0.28, 0.12]
## Part de la difficulté dans la qualité d'un niveau (le reste : sa place dans son monde).
const DIFFICULTY_WEIGHT := 0.6

## Objets. `values` : effet de l'objet à chaque rareté (de Commun à Légendaire). `tower` :
## chemin du type de tour auquel l'objet est réservé ("" = toutes). `icon` : dessin de son
## badge (EquipmentIcon). Les effets (`effect`) sont appliqués par apply_effect().
const DEFINITIONS: Array[Dictionary] = [
	{id = "poudre", name = "Munitions affûtées", effect = "damage", icon = "powder",
		values = [0.06, 0.1, 0.15, 0.22]},
	{id = "lunette", name = "Lunette de visée", effect = "range", icon = "lens",
		values = [0.05, 0.08, 0.12, 0.18]},
	{id = "rouages", name = "Culasse rapide", effect = "fire_rate", icon = "gear",
		values = [0.05, 0.08, 0.12, 0.18]},
	{id = "viseur", name = "Viseur de précision", effect = "critical", icon = "crosshair",
		values = [10, 8, 6, 4]},
	{id = "trophee", name = "Trophée de chasse", effect = "boss", icon = "crown",
		values = [0.15, 0.25, 0.4, 0.6]},
	{id = "plumes", name = "Plumes de faucon", effect = "air", icon = "wing",
		values = [0.15, 0.25, 0.4, 0.6]},
	{id = "braises", name = "Braises", effect = "burn", icon = "flame",
		values = [0.15, 0.22, 0.32, 0.45]},
	{id = "givre", name = "Éclats de givre", effect = "chill", icon = "snow",
		values = [0.1, 0.14, 0.19, 0.25]},
	{id = "oeil", name = "Œil de lynx", effect = "detection", icon = "eye",
		values = [0.5, 0.65, 0.8, 1.0]},
	{id = "boulets_lestes", name = "Boulets lestés", effect = "knockback", icon = "bomb",
		tower = "res://resources/towers/cannon.tres", values = [5.0, 8.0, 12.0, 17.0]},
	{id = "balles_tungstene", name = "Balles de tungstène", effect = "pierce", icon = "bullet",
		tower = "res://resources/towers/sniper.tres", values = [0.05, 0.1, 0.16, 0.25]},
	{id = "canons_rotatifs", name = "Canons rotatifs", effect = "fire_rate", icon = "gear",
		tower = "res://resources/towers/gatling.tres", values = [0.1, 0.15, 0.22, 0.32]},
	{id = "charge_creuse", name = "Charge creuse", effect = "splash", icon = "bomb",
		tower = "res://resources/towers/mortar.tres", values = [0.1, 0.16, 0.24, 0.35]},
	{id = "coeur_de_glace", name = "Cœur de glace", effect = "slow_strength", icon = "snow",
		tower = "res://resources/towers/frost.tres", values = [0.08, 0.12, 0.17, 0.24]},
	{id = "lentille_focale", name = "Lentille focale", effect = "beam_ramp", icon = "lens",
		tower = "res://resources/towers/beam.tres", values = [0.1, 0.16, 0.25, 0.4]},
	{id = "napalm", name = "Napalm", effect = "dot", icon = "flame",
		tower = "res://resources/towers/flame.tres", values = [0.15, 0.25, 0.4, 0.6]},
	{id = "spores", name = "Spores tenaces", effect = "cloud_duration", icon = "cloud",
		tower = "res://resources/towers/pesticide.tres", values = [1.0, 1.5, 2.5, 4.0]},
	{id = "condensateur", name = "Condensateur", effect = "chain", icon = "bolt",
		tower = "res://resources/towers/arc.tres", values = [1, 1, 2, 3]},
	{id = "bobinage", name = "Bobinage de cuivre", effect = "boost", icon = "bolt",
		tower = "res://resources/towers/coil.tres", values = [0.03, 0.05, 0.08, 0.12]},
	{id = "aimant_neodyme", name = "Aimant au néodyme", effect = "knockback_multiplier", icon = "bolt",
		tower = "res://resources/towers/magnet.tres", values = [0.15, 0.25, 0.4, 0.6]},
	{id = "eau_benite", name = "Eau bénite", effect = "revive_block", icon = "drop",
		tower = "res://resources/towers/censer.tres", values = [1.0, 1.5, 2.5, 4.0]},
]
## Bonus en plus des objets épiques et légendaires, tiré au sort parmi ces effets avec la
## valeur d'un objet Commun (épique) ou Rare (légendaire) : deux objets de même sorte
## peuvent ainsi être différents.
const EXTRA_EFFECTS: Array[String] = ["damage", "range", "fire_rate"]
const EXTRA_VALUES := {"damage": [0.06, 0.1], "range": [0.05, 0.08], "fire_rate": [0.05, 0.08]}
## Durée de la brûlure des Braises et du ralentissement des Éclats de givre, en secondes.
const BURN_DURATION := 2.0
const CHILL_DURATION := 1.0


static func get_definition(kind: String) -> Dictionary:
	for definition in DEFINITIONS:
		if definition.id == kind:
			return definition
	return {}


static func rarity_name(rarity: int) -> String:
	return TranslationServer.translate(RARITY_NAMES[clampi(rarity, 0, RARITY_COUNT - 1)])


static func box_name(rarity: int) -> String:
	return TranslationServer.translate(BOX_NAMES[clampi(rarity, 0, RARITY_COUNT - 1)])


static func rarity_color(rarity: int) -> Color:
	return RARITY_COLORS[clampi(rarity, 0, RARITY_COUNT - 1)]


# --- Inventaire ---------------------------------------------------------------

## Objets de l'inventaire (copies), dans l'ordre où ils ont été obtenus.
static func get_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Dictionary in Progress.get_value(SECTION, "items", []):
		result.append(item)
	return result


static func get_item(uid: int) -> Dictionary:
	for item in get_items():
		if item.uid == uid:
			return item
	return {}


## Objets posés sur chaque type de tour : { chemin de la TowerData: [uid, …] }.
static func get_equipped_map() -> Dictionary:
	return Progress.get_value(SECTION, "equipped", {})


## Uid des objets posés sur un type de tour, dans l'ordre des emplacements.
static func get_equipped_uids(tower_path: String) -> Array:
	return get_equipped_map().get(tower_path, [])


## Objets posés sur un type de tour.
static func get_equipped(tower_path: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var uids := get_equipped_uids(tower_path)
	for item in get_items():
		if uids.has(item.uid):
			result.append(item)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return uids.find(a.uid) < uids.find(b.uid))
	return result


## Type de tour où l'objet est posé (chemin), ou "".
static func get_tower_of(uid: int) -> String:
	var equipped := get_equipped_map()
	for path: String in equipped:
		if (equipped[path] as Array).has(uid):
			return path
	return ""


## L'objet peut-il aller sur ce type de tour ? Pas s'il est réservé à un autre, ni si un
## objet de même sorte y est déjà posé.
static func can_equip(item: Dictionary, tower_path: String) -> bool:
	if item.is_empty() or tower_path.is_empty():
		return false
	var reserved: String = get_definition(item.kind).get("tower", "")
	if not reserved.is_empty() and reserved != tower_path:
		return false
	for other in get_equipped(tower_path):
		if other.kind == item.kind and other.uid != item.uid:
			return false
	return true


## Pose l'objet sur un type de tour (il quitte celui où il était). Renvoie false si ce
## n'est pas possible : objet réservé à une autre tour, de même sorte qu'un objet déjà
## posé, ou plus d'emplacement libre.
static func equip(uid: int, tower_path: String) -> bool:
	var item := get_item(uid)
	if not can_equip(item, tower_path):
		return false
	var equipped := get_equipped_map()
	var slots: Array = equipped.get(tower_path, [])
	if slots.has(uid):
		return true
	if slots.size() >= SLOTS:
		return false
	for path: String in equipped.keys():
		(equipped[path] as Array).erase(uid)
		if (equipped[path] as Array).is_empty():
			equipped.erase(path)
	slots.append(uid)
	equipped[tower_path] = slots
	Progress.set_value(SECTION, "equipped", equipped)
	return true


## Retire l'objet de la tour où il est posé (il reste dans l'inventaire).
static func unequip(uid: int) -> void:
	var equipped := get_equipped_map()
	var changed := false
	for path: String in equipped.keys():
		if (equipped[path] as Array).has(uid):
			(equipped[path] as Array).erase(uid)
			changed = true
			if (equipped[path] as Array).is_empty():
				equipped.erase(path)
	if changed:
		Progress.set_value(SECTION, "equipped", equipped)


## Ajoute un objet à l'inventaire et le renvoie (avec son uid).
static func add_item(kind: String, rarity: int, extra := "") -> Dictionary:
	var config_items: Array = Progress.get_value(SECTION, "items", [])
	var uid: int = Progress.get_value(SECTION, "next_uid", 1)
	var item := {uid = uid, kind = kind, rarity = clampi(rarity, 0, RARITY_COUNT - 1), extra = extra}
	config_items.append(item)
	Progress.set_value(SECTION, "next_uid", uid + 1)
	Progress.set_value(SECTION, "items", config_items)
	return item


## Retire des objets de l'inventaire (et de leurs emplacements).
static func remove_items(uids: Array) -> void:
	var kept: Array = []
	for item in get_items():
		if not uids.has(item.uid):
			kept.append(item)
	for uid: int in uids:
		unequip(uid)
	Progress.set_value(SECTION, "items", kept)


# --- Coffrets -----------------------------------------------------------------

## Rareté des coffrets pas encore ouverts.
static func get_boxes() -> Array[int]:
	var result: Array[int] = []
	for rarity: int in Progress.get_value(SECTION, "boxes", []):
		result.append(rarity)
	return result


static func add_box(rarity: int) -> void:
	var boxes := get_boxes()
	boxes.append(clampi(rarity, 0, RARITY_COUNT - 1))
	Progress.set_value(SECTION, "boxes", boxes)


## Ouvre le coffret de rang `index` (le premier par défaut) : un objet de sa rareté, de
## sorte tirée au sort, va dans l'inventaire. Renvoie l'objet, ou {} sans coffret.
static func open_box(index := 0, rng: RandomNumberGenerator = null) -> Dictionary:
	var boxes := get_boxes()
	if index < 0 or index >= boxes.size():
		return {}
	var rarity := boxes[index]
	boxes.remove_at(index)
	Progress.set_value(SECTION, "boxes", boxes)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	return add_item_from(roll_kind(rng), rarity, rng)


## Ajoute un objet de cette sorte et de cette rareté, avec son bonus en plus tiré au sort
## (épique et légendaire).
static func add_item_from(kind: String, rarity: int, rng: RandomNumberGenerator) -> Dictionary:
	var extra := ""
	if rarity >= EPIQUE:
		# Pas le même effet que l'effet principal : « +15 % dégâts, +6 % dégâts » ne dirait rien.
		var choices := EXTRA_EFFECTS.filter(func(effect: String) -> bool:
			return effect != get_definition(kind).get("effect", ""))
		extra = choices[rng.randi_range(0, choices.size() - 1)]
	return add_item(kind, rarity, extra)


## Sorte d'objet tirée au sort : les objets réservés à une tour sont deux fois moins
## fréquents (chacun ne sert qu'à un type de tour).
static func roll_kind(rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for definition in DEFINITIONS:
		total += 0.5 if definition.has("tower") else 1.0
	var roll := rng.randf() * total
	for definition in DEFINITIONS:
		roll -= 0.5 if definition.has("tower") else 1.0
		if roll < 0.0:
			return definition.id
	return DEFINITIONS[0].id


## Objets libres (posés nulle part) d'une rareté, les plus anciens d'abord.
static func get_free_items(rarity: int) -> Array[Dictionary]:
	var equipped := get_equipped_map()
	var used: Array = []
	for path: String in equipped:
		used.append_array(equipped[path])
	var result: Array[Dictionary] = []
	for item in get_items():
		if item.rarity == rarity and not used.has(item.uid):
			result.append(item)
	return result


## Peut-on fondre trois objets libres de cette rareté (pas Légendaire) ?
static func can_merge(rarity: int) -> bool:
	return rarity < LEGENDAIRE and get_free_items(rarity).size() >= 3


## Fond les trois plus anciens objets libres de cette rareté en un coffret de la rareté
## au-dessus. Renvoie true si c'est fait.
static func merge(rarity: int) -> bool:
	if not can_merge(rarity):
		return false
	var uids: Array = []
	for item in get_free_items(rarity).slice(0, 3):
		uids.append(item.uid)
	remove_items(uids)
	add_box(rarity + 1)
	return true


# --- Coffrets en fin de niveau ------------------------------------------------

## Le niveau peut-il donner un coffret ? Ceux qui donnent des étoiles : la campagne, les
## niveaux libres et la Conquête.
static func level_gives_boxes(level_path: String) -> bool:
	return Perks.CAMPAIGN.levels.has(level_path) or FreeLevels.has(level_path) \
		or ConquestLevels.LEVELS.has(level_path)


## Place du niveau dans sa série, de 0 (le premier) à 1 (le dernier) : son monde pour la
## campagne, la liste des niveaux libres ou de la Conquête sinon.
static func get_level_position(level_path: String) -> float:
	var list: Array[String] = []
	var world := Perks.CAMPAIGN.world_index_of(level_path)
	if world >= 0:
		list = Perks.CAMPAIGN.worlds[world].levels
	elif FreeLevels.has(level_path):
		list = FreeLevels.LEVELS
	elif ConquestLevels.LEVELS.has(level_path):
		list = ConquestLevels.LEVELS
	var index := list.find(level_path)
	if index < 0 or list.size() < 2:
		return 0.0
	return index / float(list.size() - 1)


## Qualité d'une victoire, de 0 (Facile, premier niveau) à 1 (Cauchemar, dernier niveau) :
## elle fait monter les chances des raretés hautes.
static func get_quality(level_path: String, difficulty: int) -> float:
	return DIFFICULTY_WEIGHT * difficulty / float(Difficulty.COUNT - 1) \
		+ (1.0 - DIFFICULTY_WEIGHT) * get_level_position(level_path)


## Chances de chaque rareté pour une qualité donnée.
static func get_rarity_chances(quality: float) -> Array[float]:
	var result: Array[float] = []
	for rarity in RARITY_COUNT:
		result.append(lerpf(RARITY_CHANCES_LOW[rarity], RARITY_CHANCES_HIGH[rarity], clampf(quality, 0.0, 1.0)))
	return result


static func roll_rarity(quality: float, rng: RandomNumberGenerator) -> int:
	var chances := get_rarity_chances(quality)
	var roll := rng.randf()
	for rarity in RARITY_COUNT:
		roll -= chances[rarity]
		if roll < 0.0:
			return rarity
	return COMMUN


## Victoire sur un niveau : renvoie la rareté du coffret gagné (ajouté à ceux à ouvrir),
## ou -1 s'il n'y en a pas. `first_win` : premier succès sur ce niveau dans cette
## difficulté (le coffret est alors assuré).
static func roll_victory_box(level_path: String, difficulty: int, first_win: bool,
		rng: RandomNumberGenerator = null) -> int:
	if not level_gives_boxes(level_path):
		return -1
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	if not first_win and rng.randf() >= BOX_CHANCES[clampi(difficulty, 0, Difficulty.COUNT - 1)]:
		return -1
	var rarity := roll_rarity(get_quality(level_path, difficulty), rng)
	add_box(rarity)
	return rarity


# --- Effets -------------------------------------------------------------------

## Valeur de l'effet principal d'un objet.
static func get_value(item: Dictionary) -> float:
	var definition := get_definition(item.kind)
	return definition.values[clampi(item.rarity, 0, RARITY_COUNT - 1)] if not definition.is_empty() else 0.0


## Valeur du bonus en plus d'un objet (0 s'il n'en a pas).
static func get_extra_value(item: Dictionary) -> float:
	var extra: String = item.get("extra", "")
	if extra.is_empty() or not EXTRA_VALUES.has(extra):
		return 0.0
	return EXTRA_VALUES[extra][1 if item.rarity >= LEGENDAIRE else 0]


## Effets des objets posés sur un type de tour, [[effet, valeur], …], gardés en mémoire.
## Vide pendant le défi du jour et le tutoriel.
static func get_tower_effects(tower_path: String) -> Array:
	if tower_path.is_empty() or Engine.has_meta(Perks.DISABLED_META):
		return []
	if not Engine.has_meta(CACHE_META):
		Engine.set_meta(CACHE_META, {})
	var cache: Dictionary = Engine.get_meta(CACHE_META)
	if not cache.has(tower_path):
		var effects: Array = []
		for item in get_equipped(tower_path):
			var definition := get_definition(item.kind)
			if definition.is_empty():
				continue
			effects.append([definition.effect, get_value(item)])
			if get_extra_value(item) > 0.0:
				effects.append([item.extra, get_extra_value(item)])
		cache[tower_path] = effects
	return cache[tower_path]


## Oublie les effets gardés en mémoire (la progression a changé).
static func clear_cache() -> void:
	if Engine.has_meta(CACHE_META):
		Engine.remove_meta(CACHE_META)


## Applique l'équipement posé sur ce type de tour à ses statistiques (modifiées sur place).
## Appelé par TowerData.get_stats_at_level(), après l'arbre des améliorations.
static func apply_to(stats: TowerData, tower_path: String) -> void:
	for effect: Array in get_tower_effects(tower_path):
		apply_effect(stats, effect[0], effect[1])


## Un effet sur des statistiques de tour (modifiées sur place).
static func apply_effect(stats: TowerData, effect: String, value: float) -> void:
	match effect:
		"damage":
			stats.scale_stats(1.0 + value, 1.0, 1.0, 0.0)
		"range":
			stats.scale_stats(1.0, 1.0 + value, 1.0, 0.0)
		"fire_rate":
			stats.scale_stats(1.0, 1.0, 1.0 + value, 0.0)
		"critical":
			var every := roundi(value)
			stats.critical_every = every if stats.critical_every <= 0 else mini(stats.critical_every, every)
		"boss":
			stats.boss_damage_multiplier *= 1.0 + value
		"air":
			stats.air_damage_multiplier *= 1.0 + value
		"burn":
			# Une brûlure en plus, d'une part des dégâts du coup, ou plus forte si la tour en a déjà une.
			stats.dot_damage += stats.damage * value
			stats.dot_duration = maxf(stats.dot_duration, BURN_DURATION)
		"chill":
			stats.slow_factor = minf(stats.slow_factor, 1.0 - value)
			stats.slow_duration = maxf(stats.slow_duration, CHILL_DURATION)
		"detection":
			stats.detection_range = maxf(stats.detection_range, stats.attack_range * value)
		"knockback":
			stats.knockback += value
		"pierce":
			stats.armor_piercing = true
			stats.scale_stats(1.0 + value, 1.0, 1.0, 0.0)
		"splash":
			stats.splash_radius *= 1.0 + value
		"slow_strength":
			if stats.slow_factor < 1.0:
				stats.slow_factor = clampf(stats.slow_factor - value, 0.05, 1.0)
		"beam_ramp":
			stats.beam_ramp_max *= 1.0 + value
		"dot":
			stats.dot_damage *= 1.0 + value
		"cloud_duration":
			stats.cloud_duration += value
		"chain":
			stats.chain_count += roundi(value)
		"boost":
			if stats.boost_damage > 0.0:
				stats.boost_damage += value
			if stats.boost_fire_rate > 0.0:
				stats.boost_fire_rate += value
		"knockback_multiplier":
			stats.knockback *= 1.0 + value
		"revive_block":
			stats.revive_block_duration += value
		"slow_duration":
			if stats.slow_factor < 1.0:
				stats.slow_duration += value
		"shield_damage":
			stats.shield_damage_multiplier *= 1.0 + value
		"shield_jam":
			stats.shield_jam_duration += value
		"heal_block":
			stats.heal_block_duration += value


## Effet sur une ligne courte, traduit : « +15 % dégâts ».
static func describe_effect(effect: String, value: float) -> String:
	var percent := roundi(value * 100.0)
	match effect:
		"damage":
			return TranslationServer.translate("+%d %% dégâts") % percent
		"range":
			return TranslationServer.translate("+%d %% portée") % percent
		"fire_rate":
			return TranslationServer.translate("+%d %% cadence") % percent
		"critical":
			return TranslationServer.translate("Un coup sur %d fait double dégâts") % roundi(value)
		"boss":
			return TranslationServer.translate("+%d %% dégâts aux boss") % percent
		"air":
			return TranslationServer.translate("+%d %% dégâts aux volants") % percent
		"burn":
			return TranslationServer.translate("Brûle : %d %% des dégâts par seconde, %s s") \
				% [percent, _format(BURN_DURATION)]
		"chill":
			return TranslationServer.translate("Ralentit de %d %% pendant %s s") \
				% [percent, _format(CHILL_DURATION)]
		"detection":
			return TranslationServer.translate("Révèle les furtifs à %d %% de sa portée") % percent
		"knockback":
			return TranslationServer.translate("Fait reculer de %d") % roundi(value)
		"pierce":
			return TranslationServer.translate("Ignore l'armure, +%d %% dégâts") % percent
		"splash":
			return TranslationServer.translate("+%d %% rayon d'explosion") % percent
		"slow_strength":
			return TranslationServer.translate("Ralentissement : +%d points") % percent
		"beam_ramp":
			return TranslationServer.translate("+%d %% montée en puissance") % percent
		"dot":
			return TranslationServer.translate("+%d %% dégâts de brûlure") % percent
		"cloud_duration":
			return TranslationServer.translate("Nuage : +%s s") % _format(value)
		"chain":
			return TranslationServer.translate("+%d rebond") % roundi(value) if roundi(value) == 1 \
				else TranslationServer.translate("+%d rebonds") % roundi(value)
		"boost":
			return TranslationServer.translate("Renfort donné : +%d points") % percent
		"knockback_multiplier":
			return TranslationServer.translate("+%d %% recul") % percent
		"revive_block":
			return TranslationServer.translate("Consacre %s s de plus") % _format(value)
		"slow_duration":
			return TranslationServer.translate("Ralentissement : +%s s") % _format(value)
		"shield_damage":
			return TranslationServer.translate("+%d %% dégâts aux boucliers") % percent
		"shield_jam":
			return TranslationServer.translate("Brouille les boucliers %s s de plus") % _format(value)
		"heal_block":
			return TranslationServer.translate("Empêche les soins %s s de plus") % _format(value)
	return ""


## Lignes d'effet d'un objet : son effet principal, puis son bonus en plus.
static func describe_item(item: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var definition := get_definition(item.kind)
	if definition.is_empty():
		return lines
	lines.append(describe_effect(definition.effect, get_value(item)))
	if get_extra_value(item) > 0.0:
		lines.append(describe_effect(item.extra, get_extra_value(item)))
	return lines


## Nom de l'objet, traduit.
static func item_name(item: Dictionary) -> String:
	return TranslationServer.translate(get_definition(item.kind).get("name", "?"))


## Type de tour auquel l'objet est réservé (chemin), ou "".
static func get_reserved_tower(item: Dictionary) -> String:
	return get_definition(item.kind).get("tower", "")


## Types de tour qu'on peut équiper : ceux de départ et ceux débloqués dans l'arbre.
static func get_towers() -> Array[String]:
	var result: Array[String] = []
	result.append_array(CustomLevel.BASE_TOWERS)
	for tower in Perks.get_unlocked_towers():
		if not result.has(tower.resource_path):
			result.append(tower.resource_path)
	return result


## Nombre sans décimales inutiles : 2, 1.5.
static func _format(value: float) -> String:
	var text := String.num(value, 1)
	return text.rstrip("0").trim_suffix(".") if text.contains(".") else text
