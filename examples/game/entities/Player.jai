Player :: struct @bucket_size=1 {
    using #as base: Entity;
    firing: bool;
}

simulate :: (using player: *Player, dt: float) {
    input_direction: Vector2;
    if input_button_states[Key_Code.ARROW_UP] & .DOWN input_direction.y += 1;
    if input_button_states[Key_Code.ARROW_DOWN] & .DOWN input_direction.y -= 1;
    if input_button_states[Key_Code.ARROW_RIGHT] & .DOWN input_direction.x += 1;
    if input_button_states[Key_Code.ARROW_LEFT] & .DOWN input_direction.x -= 1;
    normalize_or_zero(*input_direction);

    if input_button_states[Key_Code.SPACEBAR] & .START && !firing {
        firing = true;
        b: Bullet;
        b.position = position;
        b.velocity = xy(400, 0);
        spawn(b);
    }
    if input_button_states[Key_Code.SPACEBAR] & .END {
        firing = false;
    }

    velocity = input_direction * 400;
    simulate_entity(player, dt);

    for each(Coin) {
        if distance(position, it.position) <= SIZE {
            game.score += it.value;
            despawn(it);
        }
    }
}

present :: (using player: *Player) {
    Simp.set_shader_for_color();
    using position;
    Simp.immediate_quad(x - SIZE/2, y - SIZE/2, x + SIZE/2, y + SIZE/2, COLOR);
}

#scope_file

COLOR :: Vector4.{0,0.5,0,1};
SIZE :: 32;
