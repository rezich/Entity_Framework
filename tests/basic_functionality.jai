#run {
    using context.entity_storage;
    
    {c: Coin; spawn(c);}
    assert(_Coin.storage.count == 1);

    coin: Handle(Coin);
    {c: Coin; coin = spawn(c);}
    assert(_Coin.storage.count == 2);
    assert(coin.id == 2);
    assert(coin.loc.bucket_index == 0);
    assert(coin.loc.slot_index == 1);

    {c: Coin; c.value = 108; spawn(c);}

    {
        total := 0;
        for _Coin update(it, *total);
        assert(total == 308);
    }

    {
        ptr, gone := from_handle(coin);
        assert(!gone);

        ptr.value = 200;

        handle := get_handle(ptr);
        assert(coin == handle);
    }
    {
        ptr, gone := from_handle(coin);
        assert(ptr.value == 200);
    }

    {b: Block; spawn(b);}
    assert(_Block.storage.count == 1);

    block: Handle(Block);
    {b: Block; block = spawn(b);}
    assert(_Block.storage.count == 2);
    assert(block.id == 2);
    assert(block.loc.bucket_index == 0);
    assert(block.loc.slot_index == 1);

    block2: Handle(Block);
    {b: Block; block2 = spawn(b);}
    assert(_Block.storage.count == 3);
    assert(block2.loc.bucket_index == 1);
    assert(block2.loc.slot_index == 0);

    despawn(block2);
    assert(_Block.storage.count == 3); // haven't cleanead up yet

    {
        invalid_block, gone := from_handle(block2);
        assert(gone);
    }

    cleanup_despawning_entities();
    assert(_Block.storage.count == 2);
}

#import "Basic";
#import "Entity_Storage";
