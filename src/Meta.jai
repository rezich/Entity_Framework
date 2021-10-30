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

    //TODO: make all of this generation 1000x better
    String_Prep :: struct { //TODO: better name
        str: string;
        builder: String_Builder;
    }

    prep :: (q: *String_Prep) { //TODO: better name
        q.str = builder_to_string(*q.builder);
    }

    entity_storage: String_Prep;
    defer free_buffers(*entity_storage.builder);
    reset_entity_storage: String_Prep;
    defer free_buffers(*reset_entity_storage.builder);
    reset_entity_storage_individual: String_Prep;
    defer free_buffers(*reset_entity_storage_individual.builder);
    despawning: String_Prep;
    defer free_buffers(*despawning.builder);
    cleanup: String_Prep;
    defer free_buffers(*cleanup.builder);
    cleanup_individual: String_Prep;
    defer free_buffers(*cleanup_individual.builder);

    for it, i: entity_type_names {
        items_per_bucket, success := table_find(entity_items_per_bucket, it);
        assert(success);
        print_to_builder(*entity_storage.builder, "    _%1: Bucket_Array(%1, %2, true);\n", it, items_per_bucket);
        print_to_builder(*reset_entity_storage.builder, "    bucket_array_reset(*_%);\n", it);
        print_to_builder(*reset_entity_storage_individual.builder, "        case .%1;\n            cleanup_despawning_entities(.%1);\n            bucket_array_reset(*_%1);\n", it);
        print_to_builder(*despawning.builder, "        _%: [..] Bucket_Locator;\n", it);
        print_to_builder(*cleanup.builder, "    for despawning._%1\n        bucket_array_remove(*_%1, it);\n    array_reset(*despawning._%1);\n", it);
        print_to_builder(*cleanup_individual.builder, "        case .%1; for despawning._%1 {\n            bucket_array_remove(*_%1, it);\n            array_reset(*despawning._%1);\n        }\n", it);
    }
    
    prep(*entity_storage);
    prep(*reset_entity_storage);
    prep(*reset_entity_storage_individual);
    prep(*despawning);
    prep(*cleanup);
    prep(*cleanup_individual);
    
    build_string := sprint(#string DONE
NUM_ENTITY_TYPES :: %1;

Entity_Storage :: struct {
%3
    gens: [%1] u32;
    despawning: struct {
%7    }
    types: [%1] Type : .[ %2 ];
}

Entity_Types :: enum {
    %4;
}

reset_entity_storage :: () {
    cleanup_despawning_entities();
    using entity_storage;
    for 0..NUM_ENTITY_TYPES-1 gens[it] = 0;
    //array_reset(*gens);
%5}

reset_entity_storage :: (type: Entity_Types) {
    using entity_storage;
    gens[type] = 0;
    if type == {
%6    }
}

cleanup_despawning_entities :: (type: Entity_Types) {
    using entity_storage;
    if type == {
%9    }
}

cleanup_despawning_entities :: () {
    using entity_storage;
%8}

#import "Bucket_Array"; // ???
DONE,
        entity_type_names.count,
        type_names,
        entity_storage.str,
        type_names_for_enum,
        reset_entity_storage.str,
        reset_entity_storage_individual.str,
        despawning.str,
        cleanup.str,
        cleanup_individual.str
    );
    
    add_build_string(build_string, w);
    
    print("Adding build string:\n----\n%\n----\n", build_string);
}

get_bucket_size :: (header: *Code_Struct) -> int {
    DEFAULT_ITEMS_PER_BUCKET :: 32;
    BUCKET_SIZE_NOTE :: "bucket_size=";
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
