uniform vec3 offset;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
    float pixel = snoise(vec3(sc / 100, 0) + offset);
    return vec4(pixel, pixel, pixel, 1);
}