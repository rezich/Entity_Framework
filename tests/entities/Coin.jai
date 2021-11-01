Coin :: struct {
    using base: Entity_Base;
    value: int = 100;
}

update :: (using coin: *Coin, total: *int) {
    <<total += value;
}
