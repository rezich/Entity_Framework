Coin :: struct {
    using base: Entity_Base;
    value: int;
}

value_above_five :: (using coin: *Coin) -> bool {
    return value > 5;
}

EACH_COIN_WORTH_TAKING :: Each_Entity(Coin).{where=value_above_five};

#run {
    for 1..20 {c: Coin; c.value = it; spawn(c);}

    {
        total := 0;
        for each(Coin) {
            total += it.value;
        }
        assert(total == 210);
    }

    // iterate with condition method #1:
    //      standard if not condition continue
    {
        total := 0;
        for each(Coin) {
            if it.value <= 5 continue;
            total += it.value;
        }
        assert(total == 195);
    }

    // iterate with condition method #2:
    //      pass existing filter proc to each() via where=
    {
        total := 0;
        for each(Coin, where=value_above_five) {
            total += it.value;
        }
        assert(total == 195);
    }

    // iterate with condition method #3:
    //      where=lambda_filter
    {
        total := 0;
        for each(Coin, where= x=>x.value > 5) {
            total += it.value;
        }
        assert(total == 195);
    }

    // iterate with condition method #4:
    //      this just kinda seems silly
    {
        total := 0;
        for EACH_COIN_WORTH_TAKING {
            total += it.value;
        }
        assert(total == 195);
    }

    // iterate with condition method #4:
    //      basically method #1 but one line & no extra syntax
    // pretty sure this is the best, and the only thing that makes each() make
    // any sense at all. there is a good chance I will remove from= and leave
    // each() as a convenience for_expansion wrapper only.           –2021-11-09
    {
        total := 0;
        for each(Coin) if it.value > 5 then total += it.value;
        assert(total == 195);
    }

    // I'm not 100% convinced select_all is actually useful but it seems like it
    // might be. surely sometimes you want to filter all entities of a type for
    // a certain subset, and then remember that subset between frames?
    {
        total := 0;
        selection := select_all(Coin, where=value_above_five);
        assert(selection.entities.count == 15);
        for selection {
            total += it.value;
        }
        assert(total == 195);
    }

    {
        total := 0;
        selection := select_all(Coin, where= x=>x.value > 5);
        assert(selection.entities.count == 15);
        for selection {
            total += it.value;
        }
        assert(total == 195);
    }
}

#import "Basic";
#import "Entity_Storage";
