Player :: struct @bucket_size=1 {
    using #as base: Entity;
}

simulate :: (using player: *Player, dt: float) {
    print("Simulating Player %\n", id);
}

present :: (using player: *Player) {
    print("Presenting Player %\n", id);
}
