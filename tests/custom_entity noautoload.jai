Entity :: struct {
    using entity_base: Entity_Base;
    position: Vector2;
}

Player :: struct {
    using base: Entity;
    health: int = 100;
}

Enemy :: struct {
    using base: Entity;
    health: int = 50;
}

#run {
    // info := type_info(Entity_Storage); //COMPILERCRASH
    info := type_info(type_of(context.entity_storage));
    members: [..] string;
    for info.members array_add(*members, it.name);
    assert(array_find(members, "_Player"));
    assert(array_find(members, "_Enemy"));
    assert(!array_find(members, "_Entity"));
}

#import "Basic";
#import "Math";
#import "Entity_Framework";
