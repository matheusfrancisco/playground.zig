## Notes about zig
## Runtime versus compile-time known length in slices

the idea is that a thing is compile-time known, when we know everything
(the value, the attributes and the characteristics) about this thing at compile-time.
In contrast, a runtime known thing is when the exact valeu of thing is calculated only at runtime.


We have learned at Section 1.6.1 that slices are created by using a range selector, 
which represents a range of indexes. When this “range of indexes” (i.e. the start and the end of this range) is 
known at compile-time, the slice object that get’s created is actually, under the hood, just a single-item pointer to an array.

when the range of indexes is known at compile-time, the slice that get’s created is just a pointer to an array, 
accompanied by a length value that tells the size of the slice.


