Block :: struct @bucket_size=64 {
    using #as base: Entity;
    number: int;
}

BLOCK_SIZE :: 16;

simulate :: (using block: *Block, dt: float) {
    print("Simulating Block %\n", id);
}

present :: (using block: *Block) {
    print("Presenting Block %\n", id);
}
