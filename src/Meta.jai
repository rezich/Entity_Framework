prebuild_step :: (w: Workspace, entity_type_name: string = "Entity", autoload: bool = true, autoload_directory: string = "entities") {
    _entity_type_name = entity_type_name;
    if autoload {
        entity_files := file_list(autoload_directory);
        for entity_files add_build_string(tprint("#load \"%\";", it), w);
    }

    init(*entity_items_per_bucket);
}

build_step :: inline (message: *Message) {
    if message.kind == {
        case .TYPECHECKED;
            typechecked := cast(*Message_Typechecked) message;
            for typechecked.structs {
                code_struct := it.expression;
                name := code_struct.defined_type.name;
                if is_subclass_of(code_struct.defined_type, "Entity_Base") && name != _entity_type_name {
                    if array_add_if_unique(*entity_type_names, name) {
                        print("Detected entity '%'.\n", name);
                        table_add(*entity_items_per_bucket, name, get_bucket_size(code_struct));
                    }
                }
            }
        
        case .PHASE;
            phase := cast(*Message_Phase) message;
            if phase.phase == .TYPECHECKED_ALL_WE_CAN {
                if !generated_code {
                    generate_code(message.workspace);
                    generated_code = true;
                }
            }
    }
}


#scope_file


_entity_type_name: string;

generated_code := false;

entity_type_names: [..] string;
entity_items_per_bucket: Table(string, int);

generate_code :: (w: Workspace) {
    quick_sort(entity_type_names, compare_strings);

    type_names := join(..entity_type_names, ", ");
    type_names_for_enum := join(..entity_type_names, ";\n    ");

    add :: (data: string, args: .. Any) #expand {
        temp := sprint(data, ..args);
        print(temp);
        add_build_string(temp, `w);
    }

    entity_storage: String_Builder; defer free_buffers(*entity_storage);
    reset_entity_storage: String_Builder; defer free_buffers(*reset_entity_storage);
    reset_entity_storage_individual: String_Builder; defer free_buffers(*reset_entity_storage_individual);
    despawning: String_Builder; defer free_buffers(*despawning);
    cleanup: String_Builder; defer free_buffers(*cleanup);
    cleanup_individual: String_Builder; defer free_buffers(*cleanup_individual);

    for entity_type_names {
        items_per_bucket, success := table_find(entity_items_per_bucket, it);
        assert(success);
        print_to_builder(*entity_storage, "    _%1: Entity_Substorage(%1, %2);\n", it, items_per_bucket);
        print_to_builder(*reset_entity_storage, "    reset_entity_storage(.%);\n", it);
        print_to_builder(*reset_entity_storage_individual, "        case .%1;\n            cleanup_despawning_entities(.%1);\n            bucket_array_reset(*_%1.storage);\n            _%1.last_id = 0;\n", it);
        print_to_builder(*despawning, "        _%: [..] Bucket_Locator;\n", it);
        print_to_builder(*cleanup, "    for _%1.despawning\n        bucket_array_remove(*_%1.storage, it);\n    array_reset(*_%1.despawning);\n", it);
        print_to_builder(*cleanup_individual, "        case .%1; for _%1.despawning {\n            bucket_array_remove(*_%1.storage, it);\n            array_reset(*_%1.despawning);\n        }\n", it);
    }

    print("----------------------------------------\n");

    add(#string XX

NUM_ENTITY_TYPES :: %;

XX,     entity_type_names.count
    );

    add(#string XX

Entity_Storage :: struct {
%1
    types: [%2] Type : .[ %3 ]; // not actually used for anything...
}

XX,     builder_to_string(*entity_storage),
        entity_type_names.count,
        type_names
    );

    add(#string XX

Entity_Types :: enum {
    %1;
}

XX,     type_names_for_enum
    );

    add(#string XX

reset_entity_storage :: () {
%1}

reset_entity_storage :: (type: Entity_Types) {
    using entity_storage;
    if type == {
%2    }
}

XX,     builder_to_string(*reset_entity_storage),
        builder_to_string(*reset_entity_storage_individual)
    );

    add(#string XX

cleanup_despawning_entities :: () {
    using entity_storage;
%1}

cleanup_despawning_entities :: (type: Entity_Types) {
    using entity_storage;
    if type == {
%2    }
}

XX,     builder_to_string(*cleanup),
        builder_to_string(*cleanup_individual)
    );

    add(#string XX

#import "Bucket_Array";

XX  );
    print("----------------------------------------\n");
}

get_bucket_size :: (header: *Code_Struct) -> int {
    for header.notes if begins_with(it.text, BUCKET_SIZE_NOTE) {
        items_per_bucket := slice(it.text, BUCKET_SIZE_NOTE.count, 8);
        return parse_int(*items_per_bucket);
    }
    return DEFAULT_ITEMS_PER_BUCKET;
}

#import "Basic";
#import "Compiler";
#import "String";
#import "Sort";
#import "File_Utilities";
#import "Hash_Table";
