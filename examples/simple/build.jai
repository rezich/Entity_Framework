// this is a dead-simple metaprogram to build the example with, to show what
// procedures you need to call in your own metaprogram in order to make the
// entity framework work:
#run {
    w := compiler_create_workspace("Target Program");
    if !w { print("Workspace creation failed.\n"); return; }
    target_options := get_build_options(w);
    target_options.output_executable_name = "example";
    set_build_options(target_options, w);
    compiler_begin_intercept(w);

    add_build_file("main.jai", w);

    // this procedure needs to be called here, before the message loop:
    Entity_Storage.prebuild_step(w);

    // here we're using it without additonal parameters, which is what you want
    // to do for the most straightforward, common use case of, say, a video game
    // or something, wherein you want to define your own Entity struct with
    // members common to all derived structs you define, AND ALSO we want to
    // have the metaprogram automatically #load all source files in the
    // entities/ directory, so we don't need to remember to add a #load
    // ourselves when we add a new entity to our video game (or whatever).
    //
    // if you want to do something else, there's some arguments you can tweak:
    //
    // entity_type_name := "Entity"
    //      if you want to call your base Entity struct something different, you
    //      can change this to whatever you like. or, if you don't want to use
    //      your own Entity struct, you could change this to "Entity_Base", or
    //      make it blank, or even just leave this parameter at its default
    //      value (as long as you never make an entity struct called Entity).
    //
    // autoload := true
    //      whether or not to autoload source files in the directory specified
    //      in autoload_directory (see below).
    //
    // autoload_directory := "entities/"
    //      if autoload (see above) is true, source files from this directory
    //      will be automatically #loaded during this prebuild step.

    while true {
        message := compiler_wait_for_message();
        if !message || message.kind == .COMPLETE break;
        // this procedure needs to be called here, in the message loop:
        Entity_Storage.build_step(message);
    }

    compiler_end_intercept(w);
    set_build_options_dc(.{do_output=false});
}

#import "Basic";
#import "Compiler";
// this line needs (BUILDING=true) to import the build code instead of the main
// application code:
Entity_Storage :: #import "Entity_Storage"(BUILDING=true);
