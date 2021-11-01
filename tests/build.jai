HORIZONTAL_RULE :: "----------------------------------------\n";

#run {
    test_files := file_list(slice(#filepath, 0, #filepath.count-1));
    test_number := 1;
    for test_files {
        filename := path_filename(it);
        if !ends_with(it, ".jai") || filename == "build.jai" continue;
        workspace_name := sprint("Test #%: %", test_number, filename);
        print(HORIZONTAL_RULE);
        print("Test #%: %\n", test_number, filename);
        w := compiler_create_workspace(workspace_name);
        if !w { print("Workspace creation failed.\n"); return; }
        target_options := get_build_options(w);
        target_options.output_type = .NO_OUTPUT;
        set_build_options(target_options, w);
        compiler_begin_intercept(w);
        
        add_build_file(it, w);

        autoload := contains(it, "autoload");
        Entity_Framework.prebuild_step(w, autoload=autoload);

        while true {
            message := compiler_wait_for_message();
            if !message || message.kind == .COMPLETE break;
            Entity_Framework.build_step(message);
        }
        compiler_end_intercept(w);
        Entity_Framework.reset();
        test_number += 1;
    }
    print(HORIZONTAL_RULE);
    set_build_options_dc(.{do_output=false});
}

#import "Basic";
#import "Compiler";
#import "String";
#import "File_Utilities";
#import "Print_Color";
#import "Process";
Entity_Framework :: #import "Entity_Framework"(BUILDING=true);
