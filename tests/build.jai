#run {
    test_files := file_list(slice(#filepath, 0, #filepath.count-1));
    test_number := 1;
    for test_files {
        filename := path_filename(it);
        filename_without_extension := path_strip_extension(filename);
        if !ends_with(it, ".jai") || filename == "build.jai" continue;
        workspace_name := sprint("Test #%: %", test_number, filename_without_extension);
        print(HORIZONTAL_RULE);
        print("Test #%: %\n", test_number, filename_without_extension);
        w := compiler_create_workspace(workspace_name);
        if !w { print("Workspace creation failed.\n"); return; }
        target_options := get_build_options(w);
        target_options.output_type = .NO_OUTPUT;
        set_build_options(target_options, w);
        compiler_begin_intercept(w);
        
        add_build_file(it, w);

        autoload := !contains(it, "noautoload");
        Entity_Framework.prebuild_step(w, autoload=autoload);

        while true {
            message := compiler_wait_for_message();
            if !message || message.kind == .COMPLETE break;
            Entity_Framework.build_step(message);
        }
        compiler_end_intercept(w);
        test_number += 1;
    }
    print(HORIZONTAL_RULE);
    set_build_options_dc(.{do_output=false});
}

HORIZONTAL_RULE :: "----------------------------------------\n";

#import "Basic";
#import "Compiler";
#import "String";
#import "File_Utilities";
#import "Print_Color";
#import "Process";
Entity_Framework :: #import "Entity_Framework"(BUILDING=true);
