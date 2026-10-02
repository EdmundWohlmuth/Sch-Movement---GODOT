shader_type spatial;

uniform float colour_r:hint_range(0.0, 1.0, 0.01);
uniform float colour_g:hint_range(0.0, 1.0, 0.01);
uniform float colour_b:hint_range(0.0, 1.0, 0.01);
uniform float colour_a:hint_range(0.0, 1.0, 0.01);

void fragment() {
  ALBEDO = vec3(colour_r, colour_g, colour_b);
  ALPHA = colour_a;
  
  //if (UV.x > 0.5) {
    //ALPHA = 0.0;
  //}
  
  //if (UV.y > 0.5) {
    //ALPHA = 0.0;
  //}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
