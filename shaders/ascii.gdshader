shader_type canvas_item;

// ASCII post-process shader for the Dokkaebi game.
// The TextureRect this material is on shows the 3D SubViewport.
// Each screen cell (cell_size_px x cell_size_px) is replaced by one
// ASCII character from ascii_atlas.png, chosen by the cell's brightness.
// The atlas holds 10 characters in one row, left to right:
//   " "  "."  ":"  "-"  "="  "+"  "*"  "#"  "%"  "@"
// (darkest -> brightest). The glyph is white-on-black, so multiplying
// the original colour by the glyph keeps the green grass / orange
// lights tinted correctly.

uniform sampler2D ascii_atlas;
uniform float cell_size_px = 8.0;
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
		float idx = clamp(floor(lum * 10.0), 0.0, 9.0);
		vec2 local_uv = fract(UV * cells);
		vec2 glyph_uv = vec2((idx + local_uv.x) / 10.0, local_uv.y);
		vec4 glyph = texture(ascii_atlas, glyph_uv);
		// glyph.r is 1 on the strokes, 0 elsewhere. Keep a little of the
		// original colour so very dark cells are not pure black.
		float mask = clamp(glyph.r * 0.9 + 0.08, 0.0, 1.0);
		COLOR = vec4(col.rgb * mask, 1.0);
	}
}
