class_name UiBackdrop
extends ColorRect
## Fond animé des écrans de menu (style « console tactique ») : à mettre sur le
## ColorRect du fond, qui couvre tout l'écran. Le dessin est fait par un shader
## (ui_backdrop.gdshader) ; `accent` colore la lueur et le quadrillage.

const SHADER: Shader = preload("res://scripts/ui/ui_backdrop.gdshader")

@export var accent := UiStyle.ACCENT


func _ready() -> void:
	color = UiStyle.BACKGROUND
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader_material := ShaderMaterial.new()
	shader_material.shader = SHADER
	shader_material.set_shader_parameter(&"base_color", UiStyle.BACKGROUND)
	shader_material.set_shader_parameter(&"accent", accent)
	material = shader_material
	resized.connect(_on_resized)
	_on_resized()


func _on_resized() -> void:
	(material as ShaderMaterial).set_shader_parameter(&"rect_size", size)
