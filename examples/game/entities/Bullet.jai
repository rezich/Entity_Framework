Bullet :: struct @bucket_size=128 {
    using #as base: Entity;
}

simulate :: (using bullet: *Bullet, dt: float) {
    for block: each(Block) {
        if distance(position, block.position) <= SIZE + EXTRA_HIT_SIZE {
            num_coins := MIN_REWARD + random_get() % (MAX_REWARD-MIN_REWARD);
            for 0..num_coins {
                c: Coin;
                c.position = block.position;
                c.velocity = rotate(xy(400,0), random_get_within_range(0, 2*PI));
                spawn(c);
            }
            despawn(block);
            despawn(bullet);
            break;
        }
    }
    using position;
    if x < -SIZE/2 || y < -SIZE/2 || x > xx (WINDOW_WIDTH-SIZE/2) || y > xx (WINDOW_WIDTH-SIZE/2) despawn(bullet);

    simulate_entity(bullet, dt);
}

present :: (using bullet: *Bullet) {
    Simp.set_shader_for_color();
    using position;
    Simp.immediate_quad(x - SIZE/2, y - SIZE/2, x + SIZE/2, y + SIZE/2, COLOR);
}

#scope_file

SIZE :: 8;
EXTRA_HIT_SIZE :: 8;
COLOR :: Vector4.{0.5,0.5,0.5,1};
MIN_REWARD :: 4;
MAX_REWARD :: 8;
