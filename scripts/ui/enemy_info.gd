class_name EnemyInfo
extends RefCounted
## Textes (BBCode, pour un RichTextLabel) qui décrivent un ennemi : nom avec son rang
## (élite, boss), statistiques et capacités. Servent au lexique, à la fiche de la
## prochaine vague, à celle du monstre sous la souris et à la sélection des mondes.

const MUTED := "#ffffff99"
const ELITE_HEX := "#ffcc40"
const BOSS_HEX := "#ff5a4d"
const GOLD_HEX := "#ffd54d"
const LIVES_HEX := "#ff8080"


## Image de l'ennemi à la taille donnée (un rond de sa couleur s'il n'en a pas).
static func icon(data: EnemyData, size := 24) -> String:
	if data.texture and not data.texture.resource_path.is_empty():
		return "[img=%dx%d]%s[/img]" % [size, size, data.texture.resource_path]
	return "[color=#%s]●[/color]" % data.color.to_html(false)


## Étiquette du rang : « ÉLITE » doré, « BOSS » rouge, ou rien.
static func rank_tag(data: EnemyData, elite := false) -> String:
	if data.is_boss:
		return "[color=%s][b]%s[/b][/color]" % [BOSS_HEX, TranslationServer.translate("BOSS")]
	if elite or data.is_elite:
		return "[color=%s][b]%s[/b][/color]" % [ELITE_HEX, TranslationServer.translate("ÉLITE")]
	return ""


## Nom dans la couleur de l'ennemi (dorée pour un élite, rouge pour un boss), suivi de
## son rang.
static func title(data: EnemyData, elite := false) -> String:
	var color := data.color.lightened(0.35)
	if data.is_boss:
		color = EnemyData.boss_color()
	elif elite or data.is_elite:
		color = EnemyData.ELITE_COLOR
	var text := "[color=#%s][b]%s[/b][/color]" % [color.to_html(false), data.get_translated_name()]
	var tag := rank_tag(data, elite and not data.is_elite)
	return text + ("  " + tag if not tag.is_empty() else "")


## Statistiques, une par ligne : vie (multipliée par la vague et la difficulté), armure,
## bouclier, vitesse, or rapporté, vies retirées, puis les capacités.
## `current_health` (positif) : vie restante d'un ennemi en jeu.
static func stats(data: EnemyData, health_multiplier := 1.0, speed_multiplier := 1.0,
		current_health := -1.0, current_shield := -1.0) -> String:
	var lines: Array[String] = []
	var max_health := roundi(data.max_health * health_multiplier)
	if current_health >= 0.0:
		lines.append(_stat("Vie", "%d / %d" % [ceili(current_health), max_health]))
	else:
		lines.append(_stat("Vie", str(max_health)))
	if data.max_shield > 0.0:
		var max_shield := roundi(data.max_shield * health_multiplier)
		lines.append(_stat("Bouclier", "%d / %d" % [ceili(current_shield), max_shield] if current_shield >= 0.0
			else str(max_shield)))
	if data.armor > 0.0:
		lines.append(_stat("Armure", str(data.armor).trim_suffix(".0")))
	lines.append(_stat("Vitesse", str(roundi(data.speed * speed_multiplier))))
	lines.append(_stat("Or", "[color=%s]+%d[/color]" % [GOLD_HEX, data.reward]))
	lines.append(_stat("Vies", TranslationServer.translate("[color=%s]-%d[/color] s'il atteint la base")
		% [LIVES_HEX, data.damage]))
	var abilities := data.get_abilities()
	if not abilities.is_empty():
		lines.append("")
		for ability in abilities:
			lines.append("[color=#c8e6c8]• %s[/color]" % ability)
	return "\n".join(lines)


## Statistiques en une ligne : « Vie 150 · Armure 3 · Vitesse 60 · +5 or · -1 vie ».
static func summary_line(data: EnemyData, health_multiplier := 1.0, speed_multiplier := 1.0) -> String:
	var parts: Array[String] = [TranslationServer.translate("Vie %d") % roundi(data.max_health * health_multiplier)]
	if data.max_shield > 0.0:
		parts.append(TranslationServer.translate("Bouclier %d") % roundi(data.max_shield * health_multiplier))
	if data.armor > 0.0:
		parts.append(TranslationServer.translate("Armure %s") % str(data.armor).trim_suffix(".0"))
	parts.append(TranslationServer.translate("Vitesse %d") % roundi(data.speed * speed_multiplier))
	parts.append("[color=%s]%s[/color]" % [GOLD_HEX, TranslationServer.translate("+%d or") % data.reward])
	parts.append("[color=%s]%s[/color]" % [LIVES_HEX,
		TranslationServer.translate_plural("-%d vie", "-%d vies", data.damage) % data.damage])
	return "[color=%s]%s[/color]" % [MUTED, "  ·  ".join(parts)]


## Ligne « Vie :  150 » (nom de la statistique traduit).
static func _stat(stat_name: String, value: String) -> String:
	return "[color=%s]%s[/color]  %s" % [MUTED, TranslationServer.translate("%s :") % TranslationServer.translate(stat_name),
		value]


## Une vague en une ligne : « [img] 12 Larves   [img] 1 Couveuse ÉLITE ».
static func wave_line(wave: WaveData, icon_size := 20) -> String:
	var parts: Array[String] = []
	for entry in wave.get_summary():
		var data: EnemyData = entry.enemy
		var text := "%s %d %s" % [icon(data, icon_size), entry.count, EnemyData.plural(data.display_name, entry.count)]
		var tag := rank_tag(data, entry.elite)
		if not tag.is_empty():
			text += " " + tag
		parts.append(text)
	return "   ".join(parts)
