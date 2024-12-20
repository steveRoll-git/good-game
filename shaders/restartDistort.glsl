const float PI = 3.1415926535897932384626433832795;

uniform float size;
uniform float distortion;
uniform float yPosition;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
    vec4 addition;
    if(tc.y >= yPosition - size && tc.y <= yPosition + size){
        tc.x -= (cos((tc.y - yPosition) / size * PI) + 1) / 2 * distortion;
        addition = vec4(0.3, 0.3, 0.3, (cos(clamp((tc.y - yPosition) / (size / 2) * PI, -PI, PI)) + 1) / 2 * min(yPosition / 0.4, 1));
    }
    return (Texel(texture, tc) + addition * addition.a) * color;
}