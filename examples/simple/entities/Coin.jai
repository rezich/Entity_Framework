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
    print("Simulating Coin %\n", id);
}

present :: (using coin: *Coin) {
    print("Presenting Coin %\n", id);
}
