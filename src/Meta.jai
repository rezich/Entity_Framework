prebuild_step :: (w: Workspace, entity_type_name: string = "Entity", autoload: bool = true, autoload_directory: string = "entities") {
    _entity_type_name = entity_type_name;
    if autoload {
        assert(file_exists(autoload_directory), sprint("Entity autoload directory % not found.", autoload_directory));
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
                        print_verbose("Detected entity '%'.\n", name);
                        bucket_size := DEFAULT_ITEMS_PER_BUCKET;
                        for code_struct.notes if begins_with(it.text, BUCKET_SIZE_NOTE) {
                            items_per_bucket := slice(it.text, BUCKET_SIZE_NOTE.count, 8);
                            bucket_size = parse_int(*items_per_bucket);
                        }
                        table_add(*entity_items_per_bucket, name, bucket_size);
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

reset :: () {
    _entity_type_name = "";
    generated_code = false;
    array_reset(*entity_type_names);
    table_reset(*entity_items_per_bucket);
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


    entity_storage: String_Builder; defer free_buffers(*entity_storage);
    reset_entity_storage: String_Builder; defer free_buffers(*reset_entity_storage);
    reset_entity_storage_individual: String_Builder; defer free_buffers(*reset_entity_storage_individual);
    despawning: String_Builder; defer free_buffers(*despawning);
    cleanup: String_Builder; defer free_buffers(*cleanup);
    cleanup_individual: String_Builder; defer free_buffers(*cleanup_individual);

    for entity_type_names {
        items_per_bucket, success := table_find(entity_items_per_bucket, it);
        assert(success);
        prepare(*entity_storage, #string XX
    _%1: Entity_Substorage(%1, %2);
XX      );
        prepare(*reset_entity_storage, #string XX
    inline reset_entity_storage(.%1);
XX      );
        prepare(*reset_entity_storage_individual, #string XX
        case .%1;
            inline cleanup_despawning_entities(.%1);
            bucket_array_reset(*_%1.storage);
            _%1.last_id = 0;
XX      );
        prepare(*despawning, #string XX
        _%: [..] Bucket_Locator;
XX      );
        prepare(*cleanup, #string XX
    for _%1.despawning bucket_array_remove(*_%1.storage, it);
    array_reset(*_%1.despawning);
XX      );
        prepare(*cleanup_individual, #string XX
        case .%1;
            for _%1.despawning bucket_array_remove(*_%1.storage, it);
            array_reset(*_%1.despawning);
XX      );
    }


    print_verbose("--begin codegen-------------------------\n");
    add(#string XX

NUM_ENTITY_TYPES :: %1;

Entity_Storage :: struct {
%2
    types: [NUM_ENTITY_TYPES] Type : .[ %3 ]; // not actually used for anything...
}

XX,     entity_type_names.count,
        output(*entity_storage),
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
%1
}

reset_entity_storage :: (type: Entity_Types) {
    using entity_storage;
    if type == {
%2
    }
}

XX,     output(*reset_entity_storage),
        output(*reset_entity_storage_individual)
    );
    add(#string XX

cleanup_despawning_entities :: () {
    using entity_storage;
%1
}

cleanup_despawning_entities :: (type: Entity_Types) {
    using entity_storage;
    if type == {
%2
    }
}

#import "Bucket_Array";
#import "Basic";

XX,     output(*cleanup),
        output(*cleanup_individual)
    );
    print_verbose("--end codegen---------------------------\n");

    add :: (data: string, args: .. Any) #expand {
        temp := sprint(data, ..args);
        print_verbose(temp);
        add_build_string(temp, `w);
    }
    prepare :: (builder : *String_Builder, format_string : string, args: .. Any) #expand {
        print_to_builder(builder, format_string, `it, `items_per_bucket);
    }
    output :: (builder: *String_Builder) -> string {
        built := builder_to_string(builder);
        return slice(built, 0, built.count-1);
    }
}

print_verbose :: (data: string, args: ..Any) {
    #if VERBOSE {
        print(data, ..args);
    }
}

#import "Basic";
#import "Compiler";
#import "String";
#import "Sort";
#import "File_Utilities";
#import "Hash_Table";
