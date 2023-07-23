uniform number minRadius = 1;
uniform number maxRadius = 0;

uniform number mul = 0;

uniform vec2 center = vec2(0.5, 0.5);

number dist(vec2 a, vec2 b){
  return sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2));
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc){
  number d = dist(tc, center);
  if(d >= minRadius && d <= maxRadius){
    number td = 1 - abs((d - minRadius) / (maxRadius - minRadius) - 0.5) * 2;
    tc.x += td * mul;
    tc.y += td * mul;
  }
  vec4 p = Texel(tex, tc);
  return p * color;
}