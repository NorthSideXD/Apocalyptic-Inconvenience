shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 12.0, 1.0) = 3.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_frequency : hint_range(100.0, 800.0) = 400.0;
uniform float color_bleed : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;
uniform float aberration : hint_range(0.0, 3.0) = 0.8;

// Green/purple tint controls
uniform vec3 shadow_tint : source_color = vec3(0.25, 0.12, 0.35);   // Purple in darks
uniform vec3 midtone_tint : source_color = vec3(0.15, 0.3, 0.18);   // Green in mids
uniform vec3 highlight_tint : source_color = vec3(0.28, 0.38, 0.22); // Sickly green in brights
uniform float tint_strength : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec2 screen_size = vec2(textureSize(screen_texture, 0));
	vec2 uv = SCREEN_UV;

	// Pixelation
	vec2 pixel_uv = floor(uv * screen_size / pixel_size) * pixel_size / screen_size;

	// Chromatic aberration (offset R and B channels slightly)
	float ab = aberration / screen_size.x;
	float r = texture(screen_texture, pixel_uv + vec2(ab, 0.0)).r;
	float g = texture(screen_texture, pixel_uv).g;
	float b = texture(screen_texture, pixel_uv - vec2(ab, 0.0)).b;
	vec3 color = vec3(r, g, b);

	// Color bleed between channels for that CRT feel
	color.r = mix(color.r, (color.r + color.g) * 0.5, color_bleed * 0.3);
	color.b = mix(color.b, (color.b + color.g) * 0.5, color_bleed * 0.3);

	// Luminance for tint mapping
	float lum = dot(color, vec3(0.299, 0.587, 0.114));

	// Three-way color tint (shadows / midtones / highlights)
	vec3 shadow_weight = vec3(clamp(1.0 - lum * 2.0, 0.0, 1.0));
	vec3 highlight_weight = vec3(clamp(lum * 2.0 - 1.0, 0.0, 1.0));
	vec3 midtone_weight = vec3(1.0) - shadow_weight - highlight_weight;

	vec3 tint = shadow_tint * shadow_weight + midtone_tint * midtone_weight + highlight_tint * highlight_weight;
	color = mix(color, color * (vec3(1.0) + tint), tint_strength);

	// Scanlines
	float scanline = sin(uv.y * scanline_frequency * PI) * 0.5 + 0.5;
	scanline = pow(scanline, 1.5);
	color *= mix(1.0, scanline, scanline_strength);

	// Vignette
	vec2 vig_uv = uv * (1.0 - uv);
	float vig = vig_uv.x * vig_uv.y * 20.0;
	vig = clamp(pow(vig, 0.4), 0.0, 1.0);
	color *= mix(1.0, vig, vignette_strength);

	// Slight contrast boost to make colors pop through the filter
	color = (color - 0.5) * 1.1 + 0.5;
	color = clamp(color, 0.0, 1.0);

	COLOR = vec4(color, 1.0);
}
