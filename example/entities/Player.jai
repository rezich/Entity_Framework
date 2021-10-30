Player :: struct @bucket_size=1 {
    using base: Entity;
}

simulate :: (using player: *Player, dt: float) {
    if despawning return;
    print("Simulating Player %\n", id);
}

present :: (using player: *Player) {
    if despawning return;
    print("Presenting Player %\n", id);
}
