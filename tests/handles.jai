Entity :: struct {
    using entity_base: Entity_Base;
    position: Vector2;
}

Player :: struct {
    using base: Entity;
    health: int = 100;
    target: Handle(Enemy);
}

simulate :: (using player: *Player) {
    target = find_first_enemy_at_x_coordinate(position.x);
}

damage :: (using enemy: *Enemy, amount: int) {
    health -= amount;
    if health <= 0 despawn(enemy);
}

Enemy :: struct {
    using base: Entity;
    health: int = 50;
}

#run {
    // spawn player
    player: Handle(Player);
    {
        p: Player;
        p.position = xy(4, 2);
        player = spawn(p);
    }
    // spawn unused enemy
    {
        e: Enemy;
        e.position = xy(7, 2);
        spawn(e);
    }
    // spawn boss enemy
    boss: Handle(Enemy);
    {
        e: Enemy;
        e.position = xy(4, 3);
        boss = spawn(e);
    }
    // ensure player doesn't have a target yet
    {
        p, player_gone := from_handle(player);
        assert(!player_gone);
        t, target_gone := from_handle(p.target);
        assert(target_gone);
    }
    // game loop iteration
    {
        using context.entity_storage;
        for _Player simulate(it);
    }
    // ensure player does have a target now, and damage it
    {
        p, player_gone := from_handle(player);
        assert(!player_gone);
        t, target_gone := from_handle(p.target);
        assert(!target_gone);
        damage(t, 25);
    }
    // loop through enemies, make sure the 2nd one was damaged
    {
        enemy_healths: [..] int;
        using context.entity_storage;
        for _Enemy array_add(*enemy_healths, it.health);
        assert(enemy_healths[1] == 25);
    }
    // something happened to make the player lose the target
    {
        p, player_gone := from_handle(player);
        assert(!player_gone);
        p.target = null_handle(Enemy);
        t, target_gone := from_handle(p.target);
        assert(target_gone);
        assert(p.target == null_handle(Enemy));
    }
    // game loop iteration
    {
        using context.entity_storage;
        for _Player simulate(it);
    }
    // ensure player still has a target, damage it again
    {
        p, player_gone := from_handle(player);
        assert(!player_gone);
        t, target_gone := from_handle(p.target);
        assert(!target_gone);
        damage(t, 25);
    }
    // we should still have 2 enemies because we haven't cleaned up yet
    {
        using context.entity_storage;
        assert(_Enemy.storage.count == 2);
    }
    // cleanup
    {
        cleanup_despawning_entities();
    }
    // ensure we are now down to one enemy post-cleanup
    {
        using context.entity_storage;
        assert(_Enemy.storage.count == 1);
    }
    // ensure player no longer has a target
    {
        p, player_gone := from_handle(player);
        assert(!player_gone);
        _, target_gone := from_handle(p.target);
        assert(target_gone);
        p.target = null_handle(Enemy);
    }
}

find_first_enemy_at_x_coordinate :: (x: float) -> Handle(Enemy) {
    handle: Handle(Enemy);
    {
        using context.entity_storage;
        for _Enemy {
            if it.position.x == x return get_handle(it);
        }
    }
    return handle;
}

#import "Basic";
#import "Math";
#import "Entity_Storage";
