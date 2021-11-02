Coin :: struct {
    using base: Entity_Base;
    value: int;
}

value_above_five :: (using coin: *Coin) -> bool {
    return value > 5;
}

#run {
    for 1..20 {c: Coin; c.value = it; spawn(c);}
    
    total := 0;
    for each(Coin, where=value_above_five) {
        total += it.value;
    }
    assert(total == 195);
}

#import "Basic";
#import "Entity_Framework";
