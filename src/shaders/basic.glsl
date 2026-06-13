@vs vs
// layout (binding=0) uniform vs_params {
// }

in vec4 position;
in vec4 color0;
in vec2 texture0;

out vec2 uv;


void main() {
    gl_Position = position;
    uv = texture0;
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
