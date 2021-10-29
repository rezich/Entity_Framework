Coin :: struct {
    using base: Entity;
    style: Coin_Style;
}

Coin_Style :: enum {
    WACK;
    FUNKY;
    FRESH;
    FLY;
}

simulate :: (using coin: *Coin, dt: float) {
    if despawning return;
    print("Simulating Coin %\n", gen);
}

present :: (using coin: *Coin) {
    if despawning return;
    print("Presenting Coin %\n", gen);
}
