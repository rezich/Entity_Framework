#module_parameters(
    BUILDING := false
);

#if BUILDING
    #load "src/Meta.jai";
else
    #load "src/Entity_Base.jai";
