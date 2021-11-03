Block :: struct @bucket_size=64 {
    using base: Entity;
    number: int;
}

simulate :: (using block: *Block, dt: float) {
}

present :: (using block: *Block) {
    Simp.set_shader_for_color();
    using position;
    Simp.immediate_quad(x - SIZE/2, y - SIZE/2, x + SIZE/2, y + SIZE/2, COLOR);
}

#scope_file

SIZE :: 32;
COLOR :: Vector4.{0.75,0.5,0,1};
