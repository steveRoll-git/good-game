uniform number idx;
uniform vec2 offset;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
  float ox = floor(mod(idx / 2 + 0.5, 2));
  float oy = floor(mod(idx / 2 + 0.11, 2));
  float fac = (mod(sc.x + ox + offset.x, 2) + mod(sc.y + oy + offset.y, 2));
  vec4 pixel = Texel(texture, tc) * color;
  return pixel * vec4(1, 1, 1, fac * 0.9);
}
