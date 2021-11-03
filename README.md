Entity_Storage
==============

this is a simple entity storage system for your video game or whatever.

it does ***not*** contain:

 - a component system
 - any sort of hierarchical/relational system
 - any kind of serialization/deserialization system

however, it would be trivial to build any of that on top of this system.


what it is / how it works
-------------------------

this entity framework allows you to derive your "entity" structs either from the
included `Base_Entity` struct, or from an `Entity` struct you define yourself.
an `Entity_Storage` struct will be automatically generated for all the entity
structs in your code, containing an `Entity_Substorage` (which contains a
`Bucket_Array`) for each one, with the same name as the struct but preceded by
an underscore. the size of the buckets can be defined using a `@bucket_size=100`
note on the entity struct declaration.

an instance of this `Entity_Storage` struct is added to the context as
`context.entity_storage`, and this lets you write code that iterates over all
instances of a given entity type very easily:

```
Physics_Object :: struct {
    using base: Base_Entity;
    mass: float;
    // ...
}

simulate :: (using physics_object: *Physics_Object, dt: float) {
    // ...
}

using context.entity_storage;
for _Physics_Object simulate(it, dt);
```

sometimes you don't want to iterate over *all* instances of a given entity type,
but only a subset that meets some criteria. you can do this too:

```
can_be_picked_up :: (using physics_object: *Physics_Object) -> bool {
    return mass < 50;
}

for each(Physics_Object, where=can_be_picked_up) {
    // ...
}
```

`each()` returns an `Entity_Selector(T)` struct whose `for_expansion` iterates
through all of that type of entity, runs the `where=` procedure on it, and if
that returns true, then the code block is executed for that entity.

you might ask, well, isn't that just the same as the following code:

```
using context.entity_storage;
for _Physics_Object {
    if !can_be_picked_up(it) continue;
    // ...
}
```

and you'd be correct. they do exactly the same thing under the hood. `each()` is
a bit more consise when doing one-off things, and the other way is better for
main loops—like in the example above—where you're probably going to be writing
one `simulate()` or `update()` or `present()` or `draw()` (or whatever) line for
each entity type. (this sort of thing *intentionally* isn't automatically
generated for you, in order to give you full control over the order in which
things are executed.)

another useful tool is `select_all()`:

```
pickupable_objects := select_all(Physics_Object, where=can_be_picked_up);
print("there's % pickupable objects\n", pickupable_objects.entities.count);
for pickupable_objects {
    // ...
}
```

this has the exact same syntax as `each()`, except `select_all()` returns an
`Entity_Selection(T)` struct, which is a wrapper around an array of `Handle(T)`.
we'll get to what `Handle`s are in a second, but the important thing to know
about `select_all()` is that it is slower to iterate through than `each()` or
`for context.entity_storage._Foo`, because of indirection. the tradeoff is the
`Entity_Selection(T)` that `select_all()` returns is something that can safely
persist across procedure calls and frames (more on this in the next section).

as an added bonus, every time you iterate over an `Entity_Selection(T)`, any
entities in the selection that have since been despawned will be automatically
removed from the selection.


### `Handle`s instead of pointers

pointers are awesome but not great for remembering entities across frame
boundaries or even between procedure calls within a frame, because the location
in memory that an entity pointer points to could contain a completely different
entity than you expect, if, say, the entity was despawned and another entity was
spawned in its place in memory since you last checked. or it could have simply
despawned, and a pointer to its location in memory would now point at something
that shouldn't exist anymore (until a new entity of the same type is spawned to
take its place).

for this reason, entities are assigned a unique `id` when they are spawned, and
you can call `get_handle(ptr)` on an entity pointer to get a `Handle(T)` that
contains both the entity pointer and the `id` of the entity. then, later, you
can use `ent, gone := from_handle(hnd)` to get the entity pointer back, along
with a `gone` boolean that's true if the entity has been despawned (deactivated
or cleaned up), or if the entity that's now in that pointer has a different
`id`. basically, if the entity is *`gone`*. ***both return parameters are
enforced with `#must`***, forcing you to consume `gone`, whether you like it or
not, because it's for your own good.

long story short, you want to use `Handle(T)`s (which is what `spawn()` returns,
anyway) to remember entities across frame boudaries and procedure calls, unless
you know what you're doing (i.e. passing a pointer to procedure calls that you
are 100% sure will not despawn the entity). then when you're actually using the
entity pointer to do some stuff with it, you use `from_handle()`, and the
compiler reminds you to check to see if it's `gone` since you last checked.

as mentioned above, this is how you spawn entities:

```
{ obj: Physics_Object; obj.mass = 100; spawn(obj); }

player: Handle(Player);
{ p: Player; player = spawn(p); }
```

to `despawn()` entities, you can pass either a pointer or `Handle`:

```
despawn(player);

simulate :: (using obj: *Physics_Object, dt: float) {
    if mass == 0 despawn(obj);
}
```
