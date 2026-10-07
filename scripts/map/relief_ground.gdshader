shader_type canvas_item;
// Herbe peinte de la vue de trois quarts : grandes taches claires et sombres aux bords
// nets (façon dessin animé), grain plus fin par-dessus.

uniform vec4 grass : source_color = vec4(0.42, 0.62, 0.22, 1.0);
uniform vec4 grass_light : source_color = vec4(0.55, 0.73, 0.27, 1.0);
uniform vec4 grass_dark : source_color = vec4(0.31, 0.5, 0.17, 1.0);
uniform vec2 size = vec2(1280.0, 640.0);
uniform float seed = 0.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21) + seed);
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p);
		p *= 2.03;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 p = UV * size;
	float big = fbm(p / 170.0);
	float mid = fbm(p / 40.0 + 7.0);
	float fine = noise(p / 3.0);
	vec3 color = mix(grass_dark.rgb, grass.rgb, smoothstep(0.36, 0.42, big));
	color = mix(color, grass_light.rgb, smoothstep(0.58, 0.63, big));
	color *= 0.93 + 0.14 * mid;
	color *= 0.97 + 0.06 * fine;
	COLOR = vec4(color, 1.0);
}
