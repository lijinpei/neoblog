## lua ffi

Please note that the association with a metatable is permanent and the metatable must not be modified afterwards! Ditto for the __index table. 

 The JIT compiler has special logic to eliminate all of the lookup overhead for functions resolved from a C library namespace! Thus it's not helpful and actually counter-productive to cache individual C functions like this: 

 don't cache C functions, but do cache namespaces!

 C declarations are not passed through a C pre-processor, yet. No pre-processor tokens are allowed, except for #pragma pack. Replace #define in existing C header files with enum, static const or typedef and/or pass the files through an external C pre-processor (once). Be careful not to include unneeded or redundant declarations from unrelated header files. 