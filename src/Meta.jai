prebuild_step :: (w: Workspace, entity_type_name: string = "Entity", autoload: bool = true, autoload_directory: string = "entities") {
    generated_code = false;
    array_reset(*entity_type_names);
    table_reset(*entity_items_per_bucket);
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


#scope_file


_entity_type_name: string;
generated_code := false;
entity_type_names: [..] string;
entity_items_per_bucket: Table(string, int);

generate_code :: (w: Workspace) {
    quick_sort(entity_type_names, compare_strings);

    type_names := join(..entity_type_names, ", ");
    type_names_for_enum := tprint("%;\n", join(..entity_type_names, ";\n    "));

    print_verbose("--begin codegen-------------------------\n");

    add_to_build(w, tprint(#string XX

NUM_ENTITY_TYPES :: %;

XX, entity_type_names.count), #string XX

Entity_Storage :: struct {
XX, iterate(#string XX
    _%1: Entity_Substorage(%1, %2);
XX), tprint(#string XX
    types: [NUM_ENTITY_TYPES] Type : .[ % ]; // not actually used for anything...
XX, type_names), #string XX
}

Entity_Types :: enum {
XX, type_names_for_enum, #string XX
}

reset_entity_storage :: () {
XX, iterate(#string XX
    inline reset_entity_storage(.%1);
XX), #string XX
}

reset_entity_storage :: (type: Entity_Types) {
    using context.entity_storage;
    if type == {
XX, iterate(#string XX
        case .%1;
            inline cleanup_despawning_entities(.%1);
            bucket_array_reset(*_%1.storage);
            _%1.last_id = 0;
XX), #string XX
    } 
}

cleanup_despawning_entities :: () {
    using context.entity_storage;
XX, iterate(#string XX
    for _%1.despawning bucket_array_remove(*_%1.storage, it);
    array_reset(*_%1.despawning);
XX), #string XX
}

cleanup_despawning_entities :: (type: Entity_Types) {
    using context.entity_storage;
    if type == {
XX, iterate(#string XX
        case .%1;
            for _%1.despawning bucket_array_remove(*_%1.storage, it);
            array_reset(*_%1.despawning);
XX), #string XX
    }
}

#import "Bucket_Array";
#import "Basic";

XX
    );
    print_verbose("--end codegen---------------------------\n");

    iterate :: (str: string) -> string #expand {
        builder: String_Builder;
        defer free_buffers(*builder);
        for `entity_type_names {
            items_per_bucket, success := table_find(entity_items_per_bucket, it);
            assert(success);
            print_to_builder(*builder, str, it, items_per_bucket);
        }
        return builder_to_string(*builder);
    }

    add_to_build :: (w: Workspace, args: ..Any) {
        builder: String_Builder;
        defer free_buffers(*builder);
        for args {
            print_verbose("%", it);
            print_to_builder(*builder, tprint("%", it));
        }
        add_build_string(builder_to_string(*builder), w);
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
