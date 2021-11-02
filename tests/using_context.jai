#run {
    using context.entity_storage;

    {c: Coin; spawn(c);}

    {
        total := 0;
        using context.entity_storage;
        for _Coin update(it, *total);
        assert(total == 100);
    }

    new_context := context;
    new_entity_storage: Entity_Storage;
    new_context.entity_storage = new_entity_storage;
    push_context new_context {
        {c: Coin; spawn(c);}
        {c: Coin; spawn(c);}
        {c: Coin; spawn(c);}
        total := 0;
        using context.entity_storage;
        for _Coin update(it, *total);
        assert(total == 300);
    }

    {
        total := 0;
        using context.entity_storage;
        for _Coin update(it, *total);
        assert(total == 100);
    }
}

#import "Basic";
#import "Entity_Framework";
