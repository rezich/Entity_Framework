Player :: struct @bucket_size=1 {
    using base: Entity;
}

simulate :: (using player: *Player, dt: float) {
    print("Simulating Player %\n", id);
}

present :: (using player: *Player) {
    print("Presenting Player %\n", id);
}
