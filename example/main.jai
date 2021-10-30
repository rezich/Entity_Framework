// here we define what an "entity" is in the context of this project.
//
// Entity_Base is the default base entity type, and if you don't need any
// additional information stored in every single entity, then you don't need to
// define this struct, you can just do
//
// Entity :: #type Entity_Base;
//
// or just use
//
// using base: Entity_Base;
//
// in your entity struct definitions instead. it's up to you. however, it seems
// that the most likely use cases for this necessitate additional members on
// every entity, so, this is how you do that:

Entity :: struct {
    using entity_base: Entity_Base;
    position: Vector2;
}


main :: () {
    // spawn some stuff
    { b: Block;  spawn(b); }
    { b: Block;  spawn(b); }
    { c: Coin;   spawn(c); }

    // before we spawn the player, let's make a Handle to remember him with:
    player: Handle(Player);
    { p: Player; player = spawn(p); } // spawn optionally returns a Handle

    TOTAL_FRAMES :: 3; // simulating 3 frames of "gameplay"
    FRAME_WHERE_THE_PLAYER_DIES :: 2; // something bad happens on frame 2

    for 1..TOTAL_FRAMES {
        print("---\nFRAME %\n---\n", it);
        reset_temporary_storage();
        dt := 0.0166666;

        // a tragic mishap occurs
        if it == FRAME_WHERE_THE_PLAYER_DIES {
            print("  Player died!\n");
            despawn(player);
            // despawn takes either a Handle or an entity pointer! also it
            // doesn't actually free anything, it just deactivates it until
            // the end of the frame (or wherever you call the cleanup procedure)
        }
        
        // standard game loop stuff
        simulate(dt);
        present();

        // this will actually free up the slot in the Bucket_Array for anything
        // that was despawn()ed in the frame
        cleanup_despawning_entities();
    }
}

simulate :: (dt: float) {
    // here's how you iterate through all entities of a given type:
    using entity_storage;
    for _Player simulate(it, dt);
    for _Block  simulate(it, dt);
    for _Coin   simulate(it, dt);
}

present :: () {
    // you can easily do stuff in any order you want in different iterations:
    using entity_storage;
    for _Block  present(it);
    for _Coin   present(it);
    for _Player present(it);
}

// some other things you can do with the entity framework:
//
// hb: Handle(Block) = get_handle(some_block_pointer);
// cleanup_despawning_entities(.Block);
// reset_entity_storage();
// reset_entity_storage(.Block);
//
// Entity_Types is an enum of all of the Entity-derived types that you can use
// for whatever you want.

#import "Basic";
#import "Math";
#import "Entity_Framework"; // no module parameters necessary here
