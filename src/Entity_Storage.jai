Entity_Id :: #type u64;

Handle :: struct (T: Type) {
    #assert is_subclass_of(type_info(T), "Entity_Base");
    ptr: *T;
    id: Entity_Id;
    loc: Bucket_Locator;
}

operator == :: (a: Handle($T), b: Handle(T)) -> bool {
    // we probably don't need to compare the two Bucket_Locators?
    return a.ptr == b.ptr && a.id == b.id;
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
        if it.despawning continue;
        #insert (remove={}) body;
    }
}

Entity_Selection :: struct(type: Type) {
    #assert is_subclass_of(type_info(type), "Entity_Base");
    entities: [..] Handle(type);
}

for_expansion :: (using selection: *$T/Entity_Selection, body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE)); // it would be nice to work around this in the future

    for entity, `it_index: entities {
        `it, gone := from_handle(entity);
        if gone {
            array_unordered_remove_by_index(*entities, it_index);
            continue;
        }
        #insert (remove={array_ordered_remove_by_index(*entities, it_index);}) body;
    }
}

Each_Entity :: struct(type: Type) {
    #assert is_subclass_of(type_info(type), "Entity_Base");
    where: (*type) -> bool;
}

for_expansion :: (using iterator: *Each_Entity($T), body: Code, flags: For_Flags) #expand {
    #assert(!(flags & .REVERSE)); // it would be nice to work around this in the future

    #insert #run sprint("entities := *context.entity_storage._%;", T);

    for `it, `it_index: entities {
        if it.despawning || (where && !where(it)) continue;
        #insert (remove={}) body;
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
    ptr, gone := from_handle(handle);
    if gone return;
    despawn(ptr);
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

each :: ($T: Type, where: (*T) -> bool=null) -> Each_Entity(T) {
    iterator: Each_Entity(T);
    iterator.where = where;
    return iterator;
}

select_all :: ($T: Type, where: (*T) -> bool) -> Entity_Selection(T) {
    selection: Entity_Selection(T);
    #insert #run sprint("substorage := *context.entity_storage._%;", T);
    for substorage if where(it) array_add(*selection.entities, get_handle(it));
    return selection;
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
