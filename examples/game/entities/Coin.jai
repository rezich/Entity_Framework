Coin :: struct {
    using base: Entity;
    value: int = 100;
}

simulate :: (using coin: *Coin, dt: float) {
    velocity *= 0.8;
    simulate_entity(coin, dt);
}

present :: (using coin: *Coin) {
    Simp.set_shader_for_color();
    using position;
    Simp.immediate_quad(x - SIZE/2, y - SIZE/2, x + SIZE/2, y + SIZE/2, COLOR);
}

#scope_file

SIZE :: 16;
COLOR :: Vector4.{1,1,0,1};
