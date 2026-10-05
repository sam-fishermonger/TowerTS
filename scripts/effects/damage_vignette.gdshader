shader_type canvas_item;
// Voile rouge plein écran, plus marqué sur les bords : signale une perte de vies.

// 0 = invisible, 1 = effet maximal.
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(0.85, 0.05, 0.05, 0.7);

void fragment() {
	// 0 au centre de l'écran, 1 dans les coins.
	float edge = smoothstep(0.35, 1.0, length(UV - 0.5) * 1.414);
	COLOR = vec4(tint.rgb, tint.a * intensity * (0.15 + 0.85 * edge));
}
