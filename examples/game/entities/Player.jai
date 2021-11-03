Player :: struct @bucket_size=1 {
    using base: Entity;
}

simulate :: (using player: *Player, dt: float) {
    input_direction: Vector2;
    if input_button_states[Key_Code.ARROW_UP] == .DOWN input_direction.y += 1;
    if input_button_states[Key_Code.ARROW_DOWN] == .DOWN input_direction.y -= 1;
    if input_button_states[Key_Code.ARROW_RIGHT] == .DOWN input_direction.x += 1;
    if input_button_states[Key_Code.ARROW_LEFT] == .DOWN input_direction.x -= 1;
    normalize_or_zero(*input_direction);

    velocity = input_direction * 400 * dt;
    position += velocity;
}

present :: (using player: *Player) {
    C_PLAYER : Vector4 : .{0,0.5,0,1};
    SIZE :: 32;
    Simp.set_shader_for_color();
    {
        using position;
        Simp.immediate_quad(x - SIZE / 2, y - SIZE / 2, x + SIZE / 2, y + SIZE / 2, C_PLAYER);
    }
}
