class_name Sound
extends Node
## Sons et musique. Le nœud est chargé au démarrage (autoload « SoundPlayer ») et
## s'utilise par ses fonctions statiques : `Sound.play(&"build")`. Il joue les effets
## sur un petit groupe de lecteurs réutilisés, et la musique en boucle d'une scène
## à l'autre : celle de l'écran titre dans les menus, celle du monde en partie. Les sons et la musique se coupent et se règlent séparément (menu
## Options) ; les choix sont enregistrés.
## (Fonctions statiques plutôt que le nom de l'autoload : les scripts restent
## compilables quand l'autoload n'est pas encore là, comme dans les tests.)

## Musiques (boucles de Kenney, CC0, voir assets/audio/musique/LICENCES.md) : celle des
## menus, puis une par biome (BiomeTheme).
const MUSICS := {
	&"titre": preload("res://assets/audio/musique/titre.ogg"),
	&"insectoid": preload("res://assets/audio/musique/ruche.ogg"),
	&"mecha": preload("res://assets/audio/musique/fonderie.ogg"),
	&"humanoid": preload("res://assets/audio/musique/cite.ogg"),
	&"undead": preload("res://assets/audio/musique/necropole.ogg"),
}
## Durée du fondu quand la musique change (de l'écran titre à une partie, par exemple).
const MUSIC_FADE := 0.6
const SOUNDS := {
	&"explosion": preload("res://assets/audio/explosion.ogg"),
	&"enemy_death": preload("res://assets/audio/enemy_death.ogg"),
	&"enemy_split": preload("res://assets/audio/enemy_split.ogg"),
	&"lives_lost": preload("res://assets/audio/lives_lost.ogg"),
	&"build": preload("res://assets/audio/build.ogg"),
	&"upgrade": preload("res://assets/audio/upgrade.ogg"),
	&"sell": preload("res://assets/audio/sell.ogg"),
	&"coins": preload("res://assets/audio/coins.ogg"),
	&"wave_start": preload("res://assets/audio/wave_start.ogg"),
	&"victory": preload("res://assets/audio/victory.ogg"),
	&"defeat": preload("res://assets/audio/defeat.ogg"),
}
const NODE_NAME := &"SoundPlayer"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"Sfx"
## Volume de chaque bus quand son curseur est au maximum, en décibels.
const BUS_BASE_DB := {MUSIC_BUS: -8.0, SFX_BUS: -4.0}
## Nombre de sons joués en même temps, au plus.
const VOICES := 16
## Méta du moteur qui coupe les effets sonores (voir set_effects_muted).
const EFFECTS_MUTED_META := &"sound_effects_muted"
## Un même son n'est pas rejoué avant ce délai (en secondes réelles) : une
## Mitrailleuse ou un Rayon ne saturent pas le mixage, même en x3.
const MIN_REPEAT_DELAY := 0.06

var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
## Dernière lecture de chaque son, en millisecondes.
var _last_played := {}
var _music_player: AudioStreamPlayer
## Musique en cours (clé de MUSICS), ou &"" avant la première.
var _music_track := &""
var _music_fade: Tween


func _ready() -> void:
	# Les sons continuent pendant la pause (achats, écran de fin).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = SFX_BUS
		add_child(voice)
		_voices.append(voice)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)
	_apply_volume(MUSIC_BUS)
	_apply_volume(SFX_BUS)


## Nœud des sons, ou null s'il n'est pas chargé.
static func get_player() -> Sound:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null(NodePath(NODE_NAME)) as Sound if tree else null


## Joue un son de la liste SOUNDS par son nom.
static func play(sound_name: StringName, volume_db := 0.0) -> void:
	play_stream(SOUNDS.get(sound_name), volume_db)


## Joue un son quelconque (par exemple celui d'une tour, défini dans ses données).
static func play_stream(stream: AudioStream, volume_db := 0.0) -> void:
	var player := get_player()
	if player and stream and not are_effects_muted() and player._can_play():
		player._play_stream(stream, volume_db)


## Lance une musique de MUSICS (celle des menus par défaut). Si elle joue déjà, elle
## continue d'une scène à l'autre ; sinon elle remplace l'autre après un court fondu.
static func play_music(track := &"titre") -> void:
	var player := get_player()
	if player == null or not player._can_play() or not MUSICS.has(track):
		return
	if player._music_track == track and player._music_player.playing:
		return
	player._switch_music(track)


## Coupe les effets sonores (pas la musique) sans toucher au réglage du joueur :
## la partie simulée derrière l'écran titre (TitleDemo) joue en silence.
static func set_effects_muted(muted: bool) -> void:
	Engine.set_meta(EFFECTS_MUTED_META, muted)


static func are_effects_muted() -> bool:
	return Engine.get_meta(EFFECTS_MUTED_META, false)


static func is_music_enabled() -> bool:
	return Progress.get_setting("music", true)


static func is_sound_enabled() -> bool:
	return Progress.get_setting("sound", true)


static func set_music_enabled(enabled: bool) -> void:
	Progress.set_setting("music", enabled)
	_apply_volume(MUSIC_BUS)


static func set_sound_enabled(enabled: bool) -> void:
	Progress.set_setting("sound", enabled)
	_apply_volume(SFX_BUS)


## Volume de la musique, de 0 (muette) à 1 (le maximum).
static func get_music_volume() -> float:
	return Progress.get_setting("music_volume", 1.0)


static func get_sound_volume() -> float:
	return Progress.get_setting("sound_volume", 1.0)


static func set_music_volume(volume: float) -> void:
	Progress.set_setting("music_volume", clampf(volume, 0.0, 1.0))
	_apply_volume(MUSIC_BUS)


static func set_sound_volume(volume: float) -> void:
	Progress.set_setting("sound_volume", clampf(volume, 0.0, 1.0))
	_apply_volume(SFX_BUS)


## Sans fenêtre (tests, serveur), personne n'écoute : on ne joue rien. Le pilote
## audio factice ne libère pas les sons joués, et le moteur les signalerait à la fermeture.
func _can_play() -> bool:
	return DisplayServer.get_name() != "headless"


## La hauteur varie un peu à chaque fois pour éviter l'effet « mitraillette ».
func _play_stream(stream: AudioStream, volume_db: float) -> void:
	var now := Time.get_ticks_msec()
	var key := stream.get_instance_id()
	if now - _last_played.get(key, -100000) < MIN_REPEAT_DELAY * 1000.0:
		return
	_last_played[key] = now
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = stream
	voice.volume_db = volume_db
	voice.pitch_scale = randf_range(0.94, 1.06)
	voice.play()


## Musique d'une partie : celle du biome de sa carte, celle des menus pour la démo de
## l'écran titre.
static func level_track(tileset: TileSet, is_demo: bool) -> StringName:
	return &"titre" if is_demo else StringName(BiomeTheme.biome_of(tileset))


func _switch_music(track: StringName) -> void:
	var was_playing := _music_player.playing and _music_track != &""
	_music_track = track
	if _music_fade:
		_music_fade.kill()
	if not was_playing:
		_start_music()
		return
	_music_fade = create_tween()
	_music_fade.tween_property(_music_player, ^"volume_db", -40.0, MUSIC_FADE / 2.0)
	_music_fade.tween_callback(_start_music)


func _start_music() -> void:
	var stream := (MUSICS[_music_track] as AudioStream).duplicate() as AudioStreamOggVorbis
	stream.loop = true
	_music_player.stream = stream
	_music_player.volume_db = 0.0
	_music_player.play()


## Règle un bus d'après les réglages : coupé, ou à son volume (le curseur suit
## l'oreille : linear_to_db, et 0 coupe le bus).
static func _apply_volume(bus: StringName) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index == -1:
		return
	var enabled := is_music_enabled() if bus == MUSIC_BUS else is_sound_enabled()
	var volume := get_music_volume() if bus == MUSIC_BUS else get_sound_volume()
	AudioServer.set_bus_mute(index, not enabled or volume <= 0.0)
	AudioServer.set_bus_volume_db(index, BUS_BASE_DB[bus] + linear_to_db(maxf(volume, 0.001)))


static func _ensure_bus(bus: StringName) -> void:
	if AudioServer.get_bus_index(bus) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus)
	AudioServer.set_bus_send(index, &"Master")
