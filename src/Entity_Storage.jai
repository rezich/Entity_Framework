Entity_Id :: #type u64;

Handle :: struct (T: Type) {
    #assert is_subclass_of(type_info(T), "Entity_Base");
    ptr: *T;
    id: Entity_Id;
    loc: Bucket_Locator;
}

Entity_Base :: struct {
    despawning: bool;
    id: Entity_Id;
    loc: Bucket_Locator;
}

Entity_Substorage :: struct(type: Type, items_per_bucket: int) {
    storage: Bucket_Array(type, items_per_bucket, true);
    last_id: Entity_Id;
    despawning: [..] Bucket_Locator;
}

for_expansion :: (using substorage: *$T/Entity_Substorage, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE)); // it would be nice to work around this in the future

    for `it, `it_index: storage {
        if `it.despawning continue;
        #insert (remove={despawn(`it);}) body;
    }
}

Entity_Collection :: struct(type: Type) {
    #assert is_subclass_of(type_info(type), "Entity_Base");
    entities: [..] *type;
}

for_expansion :: (using collection: *$T/Entity_Collection, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE)); // it would be nice to work around this in the future

    for `it, `it_index: entities {
        if `it.despawning continue;
        #insert (remove={despawn(`it);}) body;
    }
}

spawn :: (entity: $T/Entity_Base) -> Handle(T) {
    #insert #run sprint("substorage := *context.entity_storage._%;", T);
    last_id := *substorage.last_id;
    locator := bucket_array_add(*substorage.storage, entity);
    pointer := bucket_array_find_pointer(*substorage.storage, locator);
    
    <<last_id += 1;
    pointer.id = <<last_id;
    pointer.loc = locator;
    pointer.despawning = false;

    handle: Handle(T);
    handle.ptr = pointer;
    handle.loc = locator;
    handle.id = pointer.id;
    return handle;
}

despawn :: (handle: Handle($T)) {
    _, gone := from_handle(handle);
    if gone return;
    despawn(handle.ptr);
}

despawn :: (using entity: *$T/Entity_Base) {
    id = 0;
    despawning = true;
    #insert #run sprint("despawning_array := *context.entity_storage._%.despawning;", T);
    array_add(despawning_array, loc);
}

get_handle :: (entity: *$T/Entity_Base) -> Handle(T) #must {
    handle: Handle(T);
    handle.ptr = entity;
    handle.id = entity.id;
    handle.loc = entity.loc;
    return handle;
}

from_handle :: (using handle: Handle($T)) -> entity: *T = null, gone := false #must {
    if id == 0 || ptr.despawning || ptr.id != id return gone = true;
    return ptr;
}

null_handle :: inline ($T: Type) -> Handle(T) {
    handle: Handle(T);
    return handle;
}

operator == :: (a: Handle($T), b: Handle(T)) -> bool {
    // we probably don't need to compare the two Bucket_Locators?
    return a.ptr == b.ptr && a.id == b.id;
}

each :: ($T: Type, where: (*T) -> bool) -> Entity_Collection(T) {
    collection: Entity_Collection(T);
    #insert #run sprint("substorage := *context.entity_storage._%;", T);
    for substorage if where(it) array_add(*collection.entities, it);
    return collection;
}

bucket_array_find_pointer :: (using array: *Bucket_Array, locator: Bucket_Locator) -> *array.type {
    bucket := all_buckets[locator.bucket_index];
    assert(bucket.occupied[locator.slot_index] == true);
    result := *bucket.data[locator.slot_index];
    return result;
}

#placeholder NUM_ENTITY_TYPES;
#placeholder Entity_Types;
#placeholder Entity_Storage;
// these two lines crash when compiling... anything but the tests?
//#placeholder reset_entity_storage;        //COMPILERCRASH
//#placeholder cleanup_despawning_entities; //COMPILERCRASH
// thankfully, we don't actually need them...

#add_context entity_storage: Entity_Storage;

#import "Compiler";
#import "Bucket_Array";
#import "Basic";
