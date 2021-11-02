#run {
    test_files := file_list(slice(#filepath, 0, #filepath.count-1));
    test_count := 0;
    pass_count := 0;
    for test_files {
        filename := path_filename(it);
        filename_without_extension := path_strip_extension(filename);
        if !ends_with(it, ".jai") || filename == "_build.jai" continue;
        test_count += 1;
        workspace_name := sprint("Test #%: %", test_count, filename_without_extension);
        print_color("Test #%:", test_count, color=BACKGROUND_RED|BACKGROUND_GREEN|BACKGROUND_BLUE|FOREGROUND_INTENSITY);
        print(" %\n", filename_without_extension);
        w := compiler_create_workspace(workspace_name);
        if !w { print("Workspace creation failed.\n"); return; }
        target_options := get_build_options(w);
        target_options.output_type = .NO_OUTPUT;
        set_build_options(target_options, w);
        compiler_begin_intercept(w);
        
        add_build_file(it, w);

        autoload := !contains(it, "noautoload");
        Entity_Framework.prebuild_step(w, autoload=autoload);

        failed := false;
        while true {
            message := compiler_wait_for_message();
            if !message break;
            if message.kind == .COMPLETE {
                complete := cast(*Message_Complete) message;
                if complete.error_code > 0 failed = true;
                break;
            }
            if message.kind == .ERROR { failed = true; break; }
            Entity_Framework.build_step(message);
        }
        compiler_end_intercept(w);
        if failed {
            sleep_milliseconds(100);
            print_color(FAILED, color=BACKGROUND_RED|FOREGROUND_RED|FOREGROUND_GREEN|FOREGROUND_BLUE|FOREGROUND_INTENSITY);
        }
        else {
            print_color(PASSED, color=BACKGROUND_GREEN);
            pass_count += 1;
        }
        print("\n");
    }
    {
        builder: String_Builder; defer free_buffers(*builder);
        pass_percent := slice(sprint("%", cast(float) pass_count / cast(float) test_count * 100), 0, 4);
        results := sprint(" %1/%2 PASSED (%3%%%%%%%%) ", pass_count, test_count, pass_percent);
        PERCENT_NONSENSE :: 3; // to compensate for all those %s above
        WIDTH :: 40;
        results_width := results.count - PERCENT_NONSENSE;
        before_padding := (WIDTH - results_width) / 2;
        after_padding := WIDTH - before_padding - results_width;
        for 1..before_padding print_to_builder(*builder, "─");
        print_to_builder(*builder, results);
        for 1..after_padding print_to_builder(*builder, "─");
        results_color: u8 = BACKGROUND_GREEN|BACKGROUND_BLUE;
        if pass_count != test_count results_color = BACKGROUND_RED|BACKGROUND_GREEN;
        print_color(builder_to_string(*builder), color=results_color);
        print("\n");
    }
    set_build_options_dc(.{do_output=false});
    exit(0); // without this the compiler hangs when some errors are encountered
}

PASSED :: "                 PASSED                 ";
FAILED :: "                 FAILED                 ";

#import "Basic";
#import "Compiler";
#import "String";
#import "File_Utilities";
#import "Print_Color";
#import "Process";
Entity_Framework :: #import "Entity_Framework"(BUILDING=true);
