Entity_Framework
================

this is a simple entity framework for your video game or whatever.

it does not contain:

 - a component system
 - any sort of hierarchical/relational system
 - any kind of serialization/deserialization system

however, it would be trivial to build any of that on top of this framework.


what it is
----------

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
using context.entity_storage;
for _Physics_Object simulate(it, dt);
```

### `Handle`s instead of pointers

pointers are awesome but not great for remembering entities across frame
boundaries or even between procedure calls within a frame, because the location
in memory that an entity pointer points to could contain a completely different
entity than you expect, if, say, the entity was despawned and another entity was
spawned in its place in memory since you last checked.

for this reason, entities are assigned a unique `id` when they are spawned, and
you can call `get_handle(ptr)` on an entity pointer to get a `Handle(T)` that
contains both the entity pointer and the `id` of the entity. then, later, you
can use `ent, gone := get_from_handle(hnd)` to get the entity pointer back,
along with a `gone` boolean that's true if the entity has been despawned
(deactivated or cleaned up), or if the entity that's now in that pointer has a
different `id`. basically, if the entity is *`gone`*.

long story short, you want to use `Handle(T)`s to remember entities (which is
what `spawn()` returns, anyway) across frame boudaries and procedure calls,
unless you know what you're doing (i.e. passing a pointer to procedure calls
that you are 100% sure will not despawn the entity). then when you're actually
using the entity pointer to do some stuff with it, you use `get_from_handle()`,
and the compiler reminds you to check to see if it's `gone` since you last
checked.


documentation
-------------

the example is pretty simple and straightforward for the most part.
