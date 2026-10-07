class_name SpriteCache
extends Node
## Vue de trois quarts : des dessins en code faits une seule fois, puis recopiés.
## Un monstre dessiné en code (Creature) coûte une centaine de formes, une tour à peine
## moins, et ils se redessinent sans cesse (les pattes à chaque pas, l'arme qui vise) :
## avec beaucoup de monstres (défi du jour, mode infini), c'était l'essentiel du temps
## de chaque image sur téléphone. Ici, chaque dessin qui revient (une image de la marche
## d'un type de monstre, le donjon d'une tour) est fait une fois dans une planche hors
## écran (un SubViewport dessiné une seule fois) ; en jeu, il n'en reste qu'une copie
## d'image, d'un coût fixe et minime.
## Les planches sont dessinées à l'échelle de l'écran (fenêtre agrandie, téléphone) :
## elles restent aussi nettes que le dessin en code.

## Largeur la plus grande d'une planche, en pixels (limite des téléphones).
const MAX_SHEET_WIDTH := 4096
## Images à attendre avant de se servir d'une planche : le temps qu'elle soit dessinée.
const BAKE_FRAMES := 3
## Les planches gardent les couleurs multipliées par leur transparence (ce que donne un
## dessin sur un fond transparent). Ce matériau, posé sur ce qui les dessine (les
## monstres), les remet d'aplomb avant de les mélanger au décor. Sans effet sur les
## dessins sans image (la texture vaut alors un blanc opaque).
const UNPREMULTIPLY_SHADER := """
shader_type canvas_item;
varying vec4 vertex_color;
void vertex() {
	vertex_color = COLOR;
}
void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	if (texel.a > 0.0) {
		texel.rgb /= texel.a;
	}
	COLOR = texel * vertex_color;
}
"""

## Faux : tout se dessine en code, comme avant (comparaisons).
static var enabled := true
## Zoom de la caméra qui montre les monstres et les tours (la démo de l'écran titre
## grossit la carte) : les planches sont dessinées d'autant plus fines.
static var zoom := 1.0
static var _instance: SpriteCache
static var _material: ShaderMaterial

## Planches déjà demandées, par clé (voir get_sheet()).
var _sheets := {}
## Échelle de l'écran à laquelle les planches sont dessinées.
var _scale := 1.0


## Planche d'un dessin, prête à servir, ou null : pas d'affichage (tests), ou planche
## demandée mais pas encore dessinée (il faut alors dessiner en code, cette fois-ci).
## `key` désigne le dessin (deux dessins de même clé sont identiques), `cells` le nombre
## d'images de la planche, `extent` la place que prend une image autour de son origine,
## et `drawer` (CanvasItem, numéro de l'image) dessine une image autour de (0, 0).
static func get_sheet(key: String, cells: int, extent: Rect2, drawer: Callable) -> Sheet:
	if Relief.headless or not enabled:
		return null
	if not is_instance_valid(_instance):
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null:
			return null
		_instance = SpriteCache.new()
		_instance.name = "SpriteCache"
		tree.root.add_child.call_deferred(_instance)
		return null
	return _instance._get_sheet(key, cells, extent, drawer)


## Matériau de ce qui dessine des planches avec de la transparence (UNPREMULTIPLY_SHADER).
static func get_material() -> ShaderMaterial:
	if _material == null:
		var shader := Shader.new()
		shader.code = UNPREMULTIPLY_SHADER
		_material = ShaderMaterial.new()
		_material.shader = shader
	return _material


func _ready() -> void:
	_scale = _screen_scale()
	get_tree().root.size_changed.connect(_on_screen_resized)
	# Chaque écran (niveau, menu) a ses monstres et ses tours : les planches du précédent
	# ne gardent pas la mémoire de l'appareil.
	get_tree().scene_changed.connect(clear)


## Oublie toutes les planches (elles seront redessinées à la demande).
func clear() -> void:
	for sheet: Sheet in _sheets.values():
		sheet.viewport.queue_free()
	_sheets.clear()


func _get_sheet(key: String, cells: int, extent: Rect2, drawer: Callable) -> Sheet:
	var sheet: Sheet = _sheets.get(key)
	if sheet == null:
		sheet = Sheet.new(cells, extent, drawer, _scale)
		sheet.ready_frame = Engine.get_process_frames() + BAKE_FRAMES
		_sheets[key] = sheet
		# Demandée en plein dessin : la planche entre dans l'arbre juste après.
		add_child.call_deferred(sheet.viewport)
		return null
	return sheet if Engine.get_process_frames() >= sheet.ready_frame else null


## Change le zoom de la caméra (voir `zoom`).
static func set_zoom(value: float) -> void:
	zoom = value
	if is_instance_valid(_instance) and _instance.is_inside_tree():
		_instance._on_screen_resized()


## Échelle des planches : celle de la fenêtre (étirement « canvas_items », 1 en
## 1280 x 800), grossie du zoom de la caméra.
func _screen_scale() -> float:
	var stretch := get_tree().root.get_final_transform().get_scale()
	return clampf(maxf(stretch.x, stretch.y) * zoom, 1.0, 4.0)


## La fenêtre change de taille : les planches seront redessinées à la nouvelle échelle.
func _on_screen_resized() -> void:
	var scale := _screen_scale()
	if is_equal_approx(scale, _scale):
		return
	_scale = scale
	clear()


## Planche : ses images en grille, dans un SubViewport dessiné une seule fois.
class Sheet:
	var viewport: SubViewport
	var texture: Texture2D
	## Taille d'une image, en pixels de la planche, et place de l'origine dans l'image.
	var cell: Vector2
	var origin: Vector2
	var scale: float
	var columns: int
	var ready_frame := 0

	func _init(cells: int, extent: Rect2, drawer: Callable, screen_scale: float) -> void:
		scale = screen_scale
		cell = (extent.size * scale).ceil()
		origin = (-extent.position * scale).round()
		columns = maxi(1, mini(cells, int(MAX_SHEET_WIDTH / cell.x)))
		viewport = SubViewport.new()
		viewport.transparent_bg = true
		viewport.disable_3d = true
		viewport.size = Vector2i(int(cell.x) * columns, int(cell.y) * ceili(float(cells) / columns))
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		for i in cells:
			var frame := Frame.new()
			frame.drawer = drawer
			frame.index = i
			frame.position = Vector2(i % columns, i / columns) * cell + origin
			frame.scale = Vector2(scale, scale)
			viewport.add_child(frame)
		texture = viewport.get_texture()

	## Recopie l'image `index`, son origine en `at` (retournée de gauche à droite si
	## `flip`), teintée de `tint`.
	func draw(canvas: CanvasItem, index: int, at := Vector2.ZERO, flip := false, tint := Color.WHITE) -> void:
		var source := Rect2(Vector2(index % columns, index / columns) * cell, cell)
		var target := Rect2(-origin / scale, cell / scale)
		if flip:
			canvas.draw_set_transform(at, 0.0, Vector2(-1.0, 1.0))
		else:
			target.position += at
		canvas.draw_texture_rect_region(texture, target, source, tint)
		if flip:
			canvas.draw_set_transform(Vector2.ZERO)


## Une image d'une planche.
class Frame extends Node2D:
	var drawer: Callable
	var index := 0

	func _draw() -> void:
		drawer.call(self, index)
