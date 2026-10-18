shader_type canvas_item;
// Fond animé des écrans de menu (UiBackdrop) : ardoise en dégradé, lueur d'accent en haut,
// quadrillage qui monte lentement avec quelques points qui clignotent, et une bande de
// balayage qui descend. Tout reste très discret derrière les panneaux.

uniform vec4 base_color : source_color = vec4(0.03, 0.06, 0.09, 1.0);
uniform vec4 accent : source_color = vec4(0.35, 0.85, 1.0, 1.0);
// Taille du rectangle en pixels (le quadrillage garde des cases carrées).
uniform vec2 rect_size = vec2(1280.0, 800.0);
uniform float cell = 48.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 px = UV * rect_size;
	// Dégradé : un peu plus clair en haut.
	vec3 color = mix(base_color.rgb * 1.6, base_color.rgb * 0.7, UV.y);
	// Lueur d'accent en haut au centre.
	float glow = 1.0 - smoothstep(0.0, 0.75, length((UV - vec2(0.5, -0.1)) * vec2(1.0, 1.6)));
	color += accent.rgb * glow * 0.10;
	// Quadrillage qui monte lentement ; une ligne sur quatre plus marquée.
	vec2 grid_px = px + vec2(0.0, TIME * 6.0);
	vec2 in_cell = mod(grid_px, cell);
	float line = 1.0 - min(min(in_cell.x, cell - in_cell.x), min(in_cell.y, cell - in_cell.y));
	line = clamp(line, 0.0, 1.0);
	vec2 big = mod(grid_px, cell * 4.0);
	float major = step(min(min(big.x, cell * 4.0 - big.x), min(big.y, cell * 4.0 - big.y)), 1.0);
	color += accent.rgb * line * mix(0.035, 0.07, major);
	// Points aux croisements : quelques-uns s'allument et s'éteignent.
	vec2 node = floor(grid_px / cell + 0.5);
	float h = hash(node);
	float blink = step(0.93, h) * pow(max(sin(TIME * (0.6 + h) + h * 40.0), 0.0), 6.0);
	float dot_shape = 1.0 - smoothstep(1.5, 3.5, length(grid_px - node * cell));
	color += accent.rgb * blink * dot_shape * 0.6;
	// Bande de balayage qui descend (un passage toutes les 9 s).
	float scan = fract(TIME / 9.0) * 1.4 - 0.2;
	float band = exp(-pow((UV.y - scan) * 14.0, 2.0));
	color += accent.rgb * band * 0.035;
	// Bords assombris.
	float vignette = smoothstep(0.45, 1.1, length(UV - 0.5) * 1.414);
	color *= 1.0 - vignette * 0.55;
	COLOR = vec4(color, 1.0);
}
