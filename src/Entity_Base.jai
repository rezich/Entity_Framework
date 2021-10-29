Gen :: #type u64;

Handle :: struct (T: Type) {
    #assert is_subclass_of(type_info(T), "Entity_Base");
    ptr: *T;
    gen: Gen;
    loc: Bucket_Locator;
}

Entity_Base :: struct {
    despawning: bool;
    gen: Gen;
    loc: Bucket_Locator;
}

spawn :: (entity: $T/Entity_Base) -> Handle(T) {
    #insert #run sprint("gen := *entity_storage.gens[Entity_Types.%];", T);
    #insert #run sprint("storage := *entity_storage._%;", T);
    locator := bucket_array_add(storage, entity);
    pointer := bucket_array_find_pointer(storage, locator);
    
    <<gen += 1;
    pointer.gen = <<gen;
    pointer.loc = locator;
    pointer.despawning = false;

    handle: Handle(T);
    handle.ptr = pointer;
    handle.loc = locator;
    handle.gen = pointer.gen;
    return handle;
}

despawn :: (handle: Handle($T)) {
    _, gone := get_from_handle(handle);
    if gone return;
    handle.ptr.gen = 0;
    handle.ptr.despawning = true;
    #insert #run sprint("despawning_array := *entity_storage.despawning._%;", T);
    array_add(despawning_array, handle.loc);
}

// pretty sure this is just going to be for despawning yourself?
despawn :: inline (entity: *$T/Entity_Base) {
    despawn(get_handle(entity)); //TODO: don't be lazy here
}

get_handle :: (entity: *$T/Entity_Base) -> Handle(T) #must {
    handle: Handle(T);
    handle.ptr = entity;
    handle.gen = entity.gen;
    handle.loc = entity.loc;
    return handle;
}

get_from_handle :: (handle: Handle($T)) -> entity: *T = null, gone := false #must {
    if handle.ptr.despawning || handle.ptr.gen != handle.gen return gone = true;
    return handle.ptr;
}

bucket_array_find_pointer :: (using array: *Bucket_Array, locator: Bucket_Locator) -> *array.type {
    bucket := all_buckets[locator.bucket_index];
    assert(bucket.occupied[locator.slot_index] == true);
    result := *bucket.data[locator.slot_index];
    return result;
}

/*each :: inline ($T: Type) -> *Bucket_Array(T, 20 /*or GLOBAL_BUCKET_SIZE (or...) */, true) {
    // this would work, but only if every Entity's Bucket_Array had the same
    // items_per_bucket. Or, sure, we could move this to the metaprogram and
    // have it fill that out for us, or something... but, in the end, after
    // playing around with things, the way we do things now makes more sense,
    // plus ends up being more consise as well, as an added bonus.
    #insert #run sprint("return *entity_storage._%;", T);
}*/

#placeholder NUM_ENTITY_TYPES;
#placeholder Entity_Types;
#placeholder Entity_Storage;

entity_storage: Entity_Storage;

#import "Compiler";
#import "Bucket_Array";
#import "Basic";
