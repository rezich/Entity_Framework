#run {
    w := compiler_create_workspace("Target Program");
    if !w { print("Workspace creation failed.\n"); return; }
    target_options := get_build_options(w);
    target_options.output_executable_name = "game";
    set_build_options(target_options, w);
    compiler_begin_intercept(w);

    add_build_file("main.jai", w);

    Entity_Storage.prebuild_step(w);

    while true {
        message := compiler_wait_for_message();
        if !message || message.kind == .COMPLETE break;
        Entity_Storage.build_step(message);
    }

    compiler_end_intercept(w);
    set_build_options_dc(.{do_output=false});
}

#import "Basic";
#import "Compiler";
Entity_Storage :: #import "Entity_Storage"(BUILDING=true);
