#run {
    {c: Coin; spawn(c);}
    assert(entity_storage._Coin.storage.count == 1);

    coin: Handle(Coin);
    {c: Coin; coin = spawn(c);}
    assert(entity_storage._Coin.storage.count == 2);
    assert(coin.id == 2);
    assert(coin.loc.bucket_index == 0);
    assert(coin.loc.slot_index == 1);

    {b: Block; spawn(b);}
    assert(entity_storage._Block.storage.count == 1);

    block: Handle(Block);
    {b: Block; block = spawn(b);}
    assert(entity_storage._Block.storage.count == 2);
    assert(block.id == 2);
    assert(block.loc.bucket_index == 0);
    assert(block.loc.slot_index == 1);

    block2: Handle(Block);
    {b: Block; block2 = spawn(b);}
    assert(entity_storage._Block.storage.count == 3);
    assert(block2.loc.bucket_index == 1);
    assert(block2.loc.slot_index == 0);
}

#import "Basic";
#import "Entity_Framework";
