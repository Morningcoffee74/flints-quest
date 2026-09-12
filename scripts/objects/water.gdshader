shader_type canvas_item;

// Water-look voor Water.gd. `front` = false: de eigenlijke waterlaag achter de
// speler (kleurverloop, golvend oppervlak, zachte lichtvlekken). `front` = true:
// een dun blauw waas dat vóór de speler getekend wordt.
uniform bool front = false;
uniform vec4 shallow : source_color = vec4(0.30, 0.72, 0.92, 0.42);
uniform vec4 deep    : source_color = vec4(0.05, 0.30, 0.58, 0.62);

void fragment() {
	vec2 uv = UV;
	// Oppervlaktelijn die zachtjes golft.
	float wave = 0.008 * sin(uv.x * 28.0 + TIME * 2.2) + 0.005 * sin(uv.x * 61.0 - TIME * 3.1);
	float surface_y = 0.02 + wave;
	if (front) {
		if (uv.y < surface_y) {
			discard;
		}
		COLOR = vec4(0.35, 0.65, 0.95, 0.16);
	} else {
		if (uv.y < surface_y) {
			discard;
		}
		vec4 c = mix(shallow, deep, smoothstep(0.0, 1.0, uv.y));
		// Zachte, bewegende lichtvlekken (caustics).
		float ca = sin(uv.x * 38.0 + TIME * 1.1) * sin(uv.y * 22.0 - TIME * 0.7);
		float cb = sin(uv.x * 17.0 - TIME * 0.8 + uv.y * 9.0);
		c.rgb += 0.045 * (ca + 0.6 * cb) * (1.0 - uv.y);
		// Lichte schuimrand vlak onder het oppervlak.
		float rim = 1.0 - smoothstep(0.0, 0.05, uv.y - surface_y);
		c = mix(c, vec4(0.85, 0.97, 1.0, 0.75), rim * 0.7);
		COLOR = c;
	}
}
