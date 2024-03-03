#define PI 3.1415926535897932384626433832795

uniform float size;
uniform float distortion;
uniform float yPosition;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
    if(tc.y >= yPosition - size && tc.y <= yPosition + size){
        tc.x -= (cos((tc.y - yPosition) / size * PI) + 1) / 2 * distortion;
    }
    return Texel(texture, tc) * color;
}