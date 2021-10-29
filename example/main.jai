// define what an Entity is in this game
Entity :: struct {
    using entity_base: Entity_Base;
    position: Vector2;
}

main :: () {
    { b: Block;  spawn(b); }
    { b: Block;  spawn(b); }
    { c: Coin;   spawn(c); }

    p: Player;
    player := spawn(p);

    TOTAL_FRAMES :: 3;
    FRAME_WHERE_THE_PLAYER_DIES :: 2;

    for 1..TOTAL_FRAMES {
        print("---\nFRAME %\n---\n", it);
        reset_temporary_storage();
        dt := 0.0166666;

        if it == FRAME_WHERE_THE_PLAYER_DIES {
            print("  Player died!\n");
            despawn(player);
        }

        simulate(dt);
        present();

        cleanup_despawning_entities();
    }
}

simulate :: (dt: float) {
    using entity_storage;
    for _Player simulate(it, dt);
    for _Block  simulate(it, dt);
    for _Coin   simulate(it, dt);
}

present :: () {
    using entity_storage;
    for _Block  present(it);
    for _Coin   present(it);
    for _Player present(it);
}

#import "Basic";
#import "Math";
#import "Entity_Framework";
