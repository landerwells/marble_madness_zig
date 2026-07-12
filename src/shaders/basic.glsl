@vs vs
layout(binding=0) uniform vs_params {
    mat4 model;
    mat4 view;
    mat4 projection;
    vec2 uv_offset;
    vec2 uv_scale;
};

in vec2 position;
// Rename to texture_uv or something like that
in vec2 texture0;

out vec2 uv;

void main() {
    gl_Position = model * view * projection * vec4(position, 0.0, 1.0);
    uv = texture0 * uv_scale + uv_offset;
    uv = (texture0 * uv_scale) + (uv_offset * uv_scale);
}
@end

@fs fs
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;

in vec2 uv;
out vec4 frag_color;

void main() {
    frag_color = texture(sampler2D(tex, smp), uv);
}
@end

@program basic vs fs
