main :: () {
    { b: Block;  spawn(b); }
    { b: Block;  spawn(b); }
    { c: Coin;   spawn(c); }
    { p: Player; spawn(p); }
    { b: Block;  spawn(b); }
    { c: Coin;   spawn(c); }
    { c: Coin;   spawn(c); }

    print("---\nSimulating:\n---\n");
    dt := 0.0166666;
    simulate(dt);

    print("---\nPresenting:\n---\n");
    present();
    
    print("---\n");
}

simulate :: (dt: float) {
    using entity_storage;
    for _Block  simulate(it, dt);
    for _Coin   simulate(it, dt);
    for _Player simulate(it, dt);
}

present :: () {
    using entity_storage;
    for _Block  present(it);
    for _Coin   present(it);
    for _Player present(it);
}

#import "Basic";
#import "Entity_Framework";
