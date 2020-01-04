shader_type canvas_item;
render_mode blend_mix;

uniform vec4 evenColor : hint_color;
uniform vec4 oddColor : hint_color;
uniform vec4 gridColor : hint_color;
uniform vec4 outlineColor : hint_color;
uniform vec2 rectSize = vec2(100, 100);
uniform vec2 virtualSize = vec2(100, 100);
uniform vec2 checkersSize = vec2(16, 16);
uniform vec2 anchor = vec2(0, 0);
uniform vec2 gridSize = vec2(16, 16);
uniform bool drawGrid = false;

float outline(sampler2D tex, vec2 uv, vec2 tex_px_size, vec2 offset)
{
	vec4 texel = texture(tex, uv + offset * tex_px_size);
	return texel.a;
}

void fragment()
{	
	vec2 pix_size = TEXTURE_PIXEL_SIZE;
	float border = 0.0;
	border += outline(TEXTURE, UV, pix_size, vec2(+1, +0));
	border += outline(TEXTURE, UV, pix_size, vec2(-1, +0));
	border += outline(TEXTURE, UV, pix_size, vec2(+0, -1));
	border += outline(TEXTURE, UV, pix_size, vec2(+0, +1));
	
	float shadow = 0.0;
	shadow += outline(TEXTURE, UV, pix_size, vec2(-1, -2));
	shadow += outline(TEXTURE, UV, pix_size, vec2(-1, -3));
	shadow += outline(TEXTURE, UV, pix_size, vec2(-2, -3));
	
	float alpha = clamp(clamp(border, 0.0, 1.0) + clamp(shadow, 0.0, 1.0)*0.6, 0.0, 1.0);
	vec4 col = mix(vec4(0), outlineColor, alpha);
	vec4 texCol = texture(TEXTURE, UV);
	col = mix(col, texCol, texCol.a);
	
	vec2 pos = ((UV.xy - (anchor / virtualSize)) / checkersSize * virtualSize);
	bool is_even = mod(floor(pos.x) + floor(pos.y), 2.0) == 0.0;
	vec3 bg_color = is_even ? evenColor.rgb : oddColor.rgb;

	if(drawGrid)
	{
		vec2 coord = (UV.xy - (anchor / virtualSize)) / gridSize * virtualSize;
		vec2 grid = fract(coord) / fwidth(coord);
		float line = 1.0 - min(grid.x, grid.y);
		bg_color = mix(bg_color, gridColor.rgb, float(line > 0.0) * gridColor.a * clamp(1.0 / length(virtualSize / (gridSize * 40.0)), 0.4, 1.0));
	}

	COLOR = vec4(mix(bg_color, col.rgb, col.a), 1.0);
}