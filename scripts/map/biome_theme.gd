class_name BiomeTheme
## Habillage de chaque monde en vue de trois quarts : couleurs du sol et du chemin, ce
## qui pousse sur le sol (touffes, fleurs, boulons, os…) et le décor debout semé loin du
## chemin (arbres, maisons, cheminées, tombes…) ou le long du chemin (buissons, caisses…).
## Le monde se reconnaît au nom de ses tuiles (resources/tilesets/<monde>.tres).

const DEFAULT := "insectoid"

## Par monde :
## - grass : sol sombre, moyen et clair (taches du shader) ;
## - dirt : couleur du chemin, et path_style « dirt » (terre) ou « cobble » (pavés) ;
## - tufts : ce qui est semé sur le sol (« grass », « bolts », « dead_grass ») et sa
##   couleur, flowers : part de fleurs et leur couleur ;
## - leaves : feuillage sombre, moyen, clair des arbres et buissons ;
## - far / near : décor debout loin du chemin et le long du chemin, avec un poids
##   (DecorItem.Kind -> poids).
const THEMES := {
	"insectoid": {
		"grass": [Color(0.31, 0.5, 0.17), Color(0.42, 0.62, 0.22), Color(0.55, 0.73, 0.27)],
		"dirt": Color(0.85, 0.72, 0.5),
		"path_style": "dirt",
		"tufts": "grass",
		"tuft_color": Color(0.25, 0.45, 0.14),
		"flowers": 0.12,
		"flower_color": Color(1.0, 0.95, 0.7),
		"leaves": [Color(0.2, 0.4, 0.13), Color(0.33, 0.58, 0.2), Color(0.55, 0.76, 0.27)],
		"far": {DecorItem.Kind.TREE: 6.0, DecorItem.Kind.HIVE: 1.0, DecorItem.Kind.EGGS: 0.8},
		"near": {DecorItem.Kind.BUSH: 4.0, DecorItem.Kind.MUSHROOM: 1.0, DecorItem.Kind.EGGS: 0.6},
	},
	"mecha": {
		"grass": [Color(0.3, 0.27, 0.24), Color(0.4, 0.36, 0.31), Color(0.49, 0.44, 0.37)],
		"dirt": Color(0.58, 0.56, 0.53),
		"path_style": "plates",
		"tufts": "bolts",
		"tuft_color": Color(0.24, 0.22, 0.2),
		"flowers": 0.06,
		"flower_color": Color(0.95, 0.6, 0.15),
		"leaves": [Color(0.28, 0.3, 0.16), Color(0.4, 0.42, 0.2), Color(0.55, 0.55, 0.28)],
		"far": {DecorItem.Kind.CHIMNEY: 1.2, DecorItem.Kind.CRATE: 2.0, DecorItem.Kind.BARREL: 2.0,
			DecorItem.Kind.SCRAP: 2.0, DecorItem.Kind.DEAD_TREE: 1.0},
		"near": {DecorItem.Kind.CRATE: 1.5, DecorItem.Kind.BARREL: 1.5, DecorItem.Kind.SCRAP: 1.5,
			DecorItem.Kind.BUSH: 1.0},
	},
	"humanoid": {
		"grass": [Color(0.35, 0.55, 0.2), Color(0.46, 0.67, 0.26), Color(0.59, 0.78, 0.33)],
		"dirt": Color(0.78, 0.74, 0.66),
		"path_style": "cobble",
		"tufts": "grass",
		"tuft_color": Color(0.3, 0.5, 0.17),
		"flowers": 0.25,
		"flower_color": Color(1.0, 0.55, 0.6),
		"leaves": [Color(0.18, 0.42, 0.18), Color(0.3, 0.6, 0.24), Color(0.5, 0.78, 0.32)],
		"far": {DecorItem.Kind.HOUSE: 2.5, DecorItem.Kind.TREE: 3.0},
		"near": {DecorItem.Kind.BUSH: 3.0, DecorItem.Kind.LAMP: 1.2, DecorItem.Kind.FENCE: 1.0},
	},
	"undead": {
		"grass": [Color(0.2, 0.19, 0.24), Color(0.28, 0.27, 0.31), Color(0.36, 0.35, 0.37)],
		"dirt": Color(0.52, 0.47, 0.43),
		"path_style": "dirt",
		"tufts": "dead_grass",
		"tuft_color": Color(0.42, 0.38, 0.3),
		"flowers": 0.05,
		"flower_color": Color(0.9, 0.88, 0.8),
		"leaves": [Color(0.18, 0.13, 0.24), Color(0.3, 0.22, 0.38), Color(0.45, 0.35, 0.55)],
		"far": {DecorItem.Kind.DEAD_TREE: 3.0, DecorItem.Kind.TOMB: 3.0, DecorItem.Kind.CROSS: 1.2},
		"near": {DecorItem.Kind.TOMB: 2.0, DecorItem.Kind.MUSHROOM: 1.0, DecorItem.Kind.BUSH: 1.0},
	},
}


## Monde d'une carte, d'après ses tuiles (le premier monde sans tuiles).
static func biome_of(tileset: TileSet) -> String:
	var name := tileset.resource_path.get_file().get_basename() if tileset else ""
	return name if THEMES.has(name) else DEFAULT


static func get_theme(biome: String) -> Dictionary:
	return THEMES.get(biome, THEMES[DEFAULT])


## Tire un élément de décor selon les poids donnés (DecorItem.Kind -> poids).
static func pick(weights: Dictionary, rng: RandomNumberGenerator) -> DecorItem.Kind:
	var kinds := weights.keys()
	var values := PackedFloat32Array()
	for kind in kinds:
		values.append(weights[kind])
	return kinds[rng.rand_weighted(values)]
