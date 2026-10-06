class_name Sound
extends Node
## Sons et musique. Le nœud est chargé au démarrage (autoload « SoundPlayer ») et
## s'utilise par ses fonctions statiques : `Sound.play(&"build")`. Il joue les effets
## sur un petit groupe de lecteurs réutilisés, et la musique en boucle d'une scène
## à l'autre. Les sons et la musique se coupent séparément ; le choix est enregistré.
## (Fonctions statiques plutôt que le nom de l'autoload : les scripts restent
## compilables quand l'autoload n'est pas encore là, comme dans les tests.)

const MUSIC: AudioStream = preload("res://assets/audio/music.ogg")
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
## Nombre de sons joués en même temps, au plus.
const VOICES := 16
## Un même son n'est pas rejoué avant ce délai (en secondes réelles) : une
## Mitrailleuse ou un Rayon ne saturent pas le mixage, même en x3.
const MIN_REPEAT_DELAY := 0.06

## Coupe les effets sonores (pas la musique) sans toucher au réglage du joueur :
## la partie simulée derrière l'écran titre (TitleDemo) joue en silence.
static var effects_muted := false

var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
## Dernière lecture de chaque son, en millisecondes.
var _last_played := {}
var _music_player: AudioStreamPlayer


func _ready() -> void:
	# Les sons continuent pendant la pause (achats, écran de fin).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(MUSIC_BUS, -8.0)
	_ensure_bus(SFX_BUS, -4.0)
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = SFX_BUS
		add_child(voice)
		_voices.append(voice)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)
	_apply_mute(MUSIC_BUS, not is_music_enabled())
	_apply_mute(SFX_BUS, not is_sound_enabled())


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
	if player and stream and not effects_muted and player._can_play():
		player._play_stream(stream, volume_db)


## Lance la musique si elle ne joue pas déjà (elle continue d'une scène à l'autre).
static func play_music() -> void:
	var player := get_player()
	if player and player._can_play() and not player._music_player.playing:
		player._start_music()


static func is_music_enabled() -> bool:
	return Progress.get_setting("music", true)


static func is_sound_enabled() -> bool:
	return Progress.get_setting("sound", true)


static func set_music_enabled(enabled: bool) -> void:
	Progress.set_setting("music", enabled)
	_apply_mute(MUSIC_BUS, not enabled)


static func set_sound_enabled(enabled: bool) -> void:
	Progress.set_setting("sound", enabled)
	_apply_mute(SFX_BUS, not enabled)


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


func _start_music() -> void:
	var stream := MUSIC.duplicate() as AudioStreamOggVorbis
	stream.loop = true
	_music_player.stream = stream
	_music_player.play()


static func _apply_mute(bus: StringName, muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), muted)


static func _ensure_bus(bus: StringName, volume_db: float) -> void:
	if AudioServer.get_bus_index(bus) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus)
	AudioServer.set_bus_volume_db(index, volume_db)
	AudioServer.set_bus_send(index, &"Master")
