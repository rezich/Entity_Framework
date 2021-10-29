build :: () {
    w := compiler_create_workspace("Target Program");
    if !w {
        print("Workspace creation failed.\n");
        return;
    }
    target_options := get_build_options(w);
    target_options.output_executable_name = "example";
    set_build_options(target_options, w);
    compiler_begin_intercept(w);

    add_build_file("main.jai", w);

    Entity_Framework.prebuild_step(w);

    message_loop();

    compiler_end_intercept(w);
    set_build_options_dc(.{do_output=false});
}
#run build();

message_loop :: () {
    while true {
        message := compiler_wait_for_message();
        if !message break;
        if message.kind == .COMPLETE break;
        Entity_Framework.build_step(message);
    }
}

#import "Basic";
#import "Compiler";
#import "String";
Entity_Framework :: #import "Entity_Framework"(BUILDING=true);
