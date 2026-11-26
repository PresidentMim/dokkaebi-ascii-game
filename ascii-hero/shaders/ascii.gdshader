shader_type canvas_item;

// ASCII post-process shader for the Dokkaebi game.
// The TextureRect this material is on shows the 3D SubViewport.
// Each screen cell (cell_size_px x cell_size_px, 12px) is replaced by
// one ASCII character from ascii_atlas.png, chosen by the cell's
// brightness. The atlas holds 10 glyphs in one row, left to right,
// in order of measured ink coverage (darkest -> brightest):
//   " "  "."  ":"  "+"  "*"  "o"  "%"  "#"  "M"  "@"
// The old ramp " .:-=+*#%@" was NOT monotonic in this font ('-' had
// fewer ink pixels than ':', '%' fewer than '#'), so brighter cells
// could pick a sparser glyph and the ASCII look collapsed. The new
// ramp is verified monotonic by tools/make_atlas.py — do not change
// the order without re-measuring.
//
// Why the old look failed: the scene was very dark (most cells had
// luminance 0.05-0.2), so the raw luminance mapped to index 0-2 only.
// The fix is twofold: the shader now boosts luminance
// (pow(lum, 0.65) * 1.4) so mid-tones reach mid characters, and the
// scene lighting was brightened so the luminance range actually
// covers the full ramp. Glyph strokes are bright and tinted by the
// original colour; cell backgrounds are near-black, so characters
// read clearly instead of washing out into the original image.

uniform sampler2D ascii_atlas;
uniform float cell_size_px = 12.0;
uniform bool ascii_enabled = true;

void fragment() {
	vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 cells = tex_size / cell_size_px;
	vec2 cell_coord = floor(UV * cells);
	vec2 cell_uv = (cell_coord + vec2(0.5)) / cells;
	vec4 col = texture(TEXTURE, cell_uv);

	if (!ascii_enabled) {
		COLOR = col;
	} else {
		float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
		// Lift the dark scene into the full ramp: gamma-lift the
		// shadows, then scale so a mid-bright cell (~0.35) lands
		// around the middle of the ramp instead of near the bottom.
		float boosted = clamp(pow(lum, 0.65) * 1.4, 0.0, 1.0);
		float idx = clamp(floor(boosted * 10.0), 0.0, 9.0);
		vec2 local_uv = fract(UV * cells);
		vec2 glyph_uv = vec2((idx + local_uv.x) / 10.0, local_uv.y);
		vec4 glyph = texture(ascii_atlas, glyph_uv);
		// Stroke bright, background near-black: glyphs pop instead
		// of blending back into the plain 3D image.
		float mask = clamp(0.05 + glyph.r, 0.0, 1.0);
		vec3 ascii_col = clamp(col.rgb * 1.3 * mask, 0.0, 1.0);
		COLOR = vec4(ascii_col, 1.0);
	}
}
