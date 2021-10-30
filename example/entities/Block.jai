Block :: struct @bucket_size=64 {
    using base: Entity;
    number: int;
}

BLOCK_SIZE :: 16;

simulate :: (using block: *Block, dt: float) {
    if despawning return;
    print("Simulating Block %\n", id);
}

present :: (using block: *Block) {
    if despawning return;
    print("Presenting Block %\n", id);
}
