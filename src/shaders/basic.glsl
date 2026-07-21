@vs vs
layout(binding=0) uniform vs_params {
    mat4 model;
    mat4 view;
    mat4 projection;
    vec3 tint;
    vec2 uv_offset;
    vec2 uv_scale;
};

in vec2 position;
in vec2 texture0;

out vec2 uv;
out vec3 frag_tint;

void main() {
    gl_Position = projection * view * model * vec4(position, 0.0, 1.0);
    uv = (texture0 * uv_scale) + (uv_offset * uv_scale);
    frag_tint = tint;
}
@end

@fs fs
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;

in vec2 uv;
in vec3 frag_tint;
out vec4 frag_color;

void main() {
    frag_color = texture(sampler2D(tex, smp), uv) * vec4(frag_tint, 1.0);
}
@end

@program basic vs fs
