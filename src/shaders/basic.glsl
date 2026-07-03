@vs vs
layout(binding=0) uniform vs_params {
  vec2 offset;
  vec2 uv_offset;
  // uv_scale is the
  vec2 uv_scale;
};

in vec4 position;
in vec4 color0;
// So UV coordinates are loaded in via this here, but what if we passed
// them in via a uniform?
in vec2 texture0;

out vec2 uv;

void main() {
  vec2 pixel_pos = position.xy + offset;

  vec2 ndc = vec2(
    pixel_pos.x / 320.0 * 2.0 - 1.0,
    1.0 - pixel_pos.y / 240.0 * 2.0
  );

  gl_Position = vec4(ndc, position.z, 1.0);
  // So right here we can calculate the uv
  uv = texture0 * uv_scale + uv_offset;
}
@end

@fs fs
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;

// in vec4 color;
in vec2 uv;
out vec4 frag_color;

void main() {
  frag_color = texture(sampler2D(tex, smp), uv);
}
@end

@program basic vs fs
