object file:
relocatable file
executable file
shared object file

link editor
dynamic linker

Linking View
Execution View

## ELF header
program header table
section header table
Files used to build a process image(execute a proram) must have a program header table.
Files used during linking must have a section header table.
section
segment

Data Representation:
* machine independent/dependent
* 32bit/64bit
* natural alignment
* padding
* no bit fields used
* no byte order specified

32bit/64bit data type(Elf32_X/Elf64_X):
* Addr/Off are 4/8 byte(both unsigned)
* unsigned char/Half/Word/Sword are the same(no signed char/half)
* Xword/Sxword are 64bit only

ELF Header(Program Header Table)

Elf32_Ehdr/Elf64_Ehdr

The following fields deal with elf/processor/object file type indentification:

1. Different layout due to Addr/Off
2. first 24 bytes(e_indent/e_type/e_machine/e_version) are the same
3. e_indent

  * EI_NINDENT(16) bytes
  * Magic Number: 0x7f 'E' 'L' 'F'
  * EI_CLASS: 32bit/64bit
  * EI_DATE: LSB/MSB(Only for the container file itself? Cann't be determined from e_machine?)
  * EI_VERSION(seem to be redundant with e_version?)
  * EI_OSABI
  * EI_ABIVERSION
  * EI_PAD
4. e_type: rel/exec/dyn/core/etc.
5. e_machine: x86/ppc/arm/etc.
6. e_version

The following fields serve as a "road map" to other fields in the object file:

7. e_entry: **virtual address** of entry point.
8. e_phoff: program header offset
9. e_shoff: section header offset
10. e_flags: processor-specific flags, EF_machine_flag.
11. e_ehsize: ELF header's size
12. e_phentsize
13. e_phnum
14. e_shentsize
15. e_shnum
16. e_shstrndx: section header table index of section name string table, or SHN_UNDEF

Notice two exception about e_shnum/e_shstrndx:

<code>
SHN_LORESERVE = 0xff00;
if (number_of_sections >= SHN_LORESERVE) {S
  e_shnum = 0;
  number_of_secitons = section_header[0].sh_size;
} else {
  section_header[0].sh_size = 0;
}
</code>

<code>
SHN_LORESERVE = 0xff00;
SHN_XINDEX = 0xffff;
alias snstsi = section_name_string_table_section_index;
if (snstsi >= SHN_LORESERVE) {
  e_shstrndx = SHN_XINDEX;
  snstsi = section_header[0].sh_link;
} else {
  section_header[0].sh_link = 0;
}
</code>

Notice all the quirks of ELF(dt_interp/dt_rpath/symbol table/relocation/PLT GOT/so dependencies) are **NOT** recorded in EFL header, only entry point is recorded in program header, perhaps becauses entry point is the thing exec()/dynamic loader cares most(besides dt_interp?).

## Sections
Recall e_shoff/e_shnum/e_shentsize in ELF header.

Special Section Indexes: sometimes you need to specify a section(like which section a reloc is relative to), in these cases, you can speficy special section indexes to convey special meaning.

* SHN_ABS: absolute values for the corresponding reference.
* SHN_COMMON: Symbols defined relative to this section are common symbols(e.g. FORTRAN COMMON/unallocated C extern variables).
* SHN_XINDEX: The actual section header index is too large to fit in the containing field and is to be found in another location(specific to the structure where is appears).

Sections are :

* possibly empty
* contiguous
* do not overlap

Elf32_Shdr/Elf64_Shdr:

* sh_name: index into section header string table
* sh_type:
* sh_flags:
* sh_addr: address of first byte in memory image of a process
* sh_offset: offset of first byte from the beginning of the file(except SHT_NOBITS)
* sh_size: (except SHT_NOBITS)
* sh_link: a section header table index, whose inderpretation depends on the section type.
* sh_info: whose interpretation depends on the section type.
* sh_addralign: alignment requirements, must be 0 or power of 2, 0 and 1 means no requirement.
* sh_entsize: if the section holds a table of fixed-size entries, this is the entry size.

Section Types(sh_type):

* SHT_NULL: inactive section
* SHT_PROGBITS:
* SHT_SYMTAB: the symbol table(one per object file)
* SHT_DYNSYM: the dynamic symbol table(one per object file)
* SHT_STRTAB: a string table
* SHT_RELA: relocation entries with explicit addends(Elf32_Rela/Elf64_Rela), possibly many per file.
* SHT_HASH: symbol hash table(one per object file)
* SHT_DYNAMIC: information for dynamic linking(one per object file)
* SHT_NOTE:
* SHT_NOBITS: this type of section occupies no space in the file.
* SHT_REL: relocation entries without explicit addends(Elf32_Rel/Elf64_Rel), possibly many per file.
* SHT_SHLIB: reserved
* SHT_INIT_ARRAY: an array of pointers to initialization functions.
* SHT_FINI_ARRAY: an array of pointers to termination functions.
* SHT_PREINIT_ARRAY: an array of pointers to function that are invoked before all other initialization functions.
* SHT_GROUP: defines a dection group, may apppear only in relocatable objects.
* SHT_SYMTAB_SHNDX: associated with SHT_SYMTAB, an array of Elf32_Word:

<code>
if (SHT_SYMTAB[x].st_shndx == SHN_XINDEX) {
  the_real_st_shndx = SHT_SYMTAB_SHNDX[x];
}
</code>

The zero-th section(SHN_UNDEF) is if SHT_NULL type, and may contains some information(sh_size/sh_link), if specified in ELF header.

sh_flags:

* SHF_WRITE
* SHF_ALLOC
* SHF_EXECINSTR
* SHF_MERGE
* SHF_STRINGS
* SHF_INFO_LINK
* SHF_LINK_ORDER
* SHF_OS_NONCONFORMING
* SHF_GROUP
* ***SHF_TLS***

Omit:

Figure 4-12: sh_link and sh_info Interpretation

Rules for Linking Unrecognized Sections

Section Groups

Special Sections

String Table

## Symbol Table

STN_UNDEF = 0

Elf32_Sym/Elf64_Sym;

* st_value
* st_size
* st_info: bind and type
* st_other: visibility
* st_shndx

### Symbol Binding
* STB_LOCAL: Local symbols are not visible outside the object file containing their definition. Local symbols of the same name may exist in multiple files without interfering with each other.
* STB_GLOBAL: Global symbols are visible to all object files being combined. One file's definition of a global symbol will satisfy another file's undefined reference to the same global symbol.
* STB_WEAK: Weak symbols resemble global symbols, but their definitions have lower precedence.

a common symbol exists (that is, a symbol whose st_shndx field holds SHN_COMMON)

* precedence: global/common > weak
* link editor resolves undefined global from archive's global/weak.
* link editor does not resolve undefined weak symbol. Unresolved weak symbol has zero value.

In each symbol table, all symbols with STB_LOCAL binding precede the weak and global symbols. Symbol table section's sh_info section header member holds the symbol table index for the first non-local symbol.

### Symbol Type

* STT_NOTYPE
* STT_OBJECT
* STT_FUNC
* STT_SECTION
* STT_FILE
* STT_COMMON
* STT_TLS

Function symbols (those with type STT_FUNC) in shared object files have special significance. When another object file references a function from a shared object, the link editor automatically creates a procedure linkage table entry for the referenced symbol. Shared object symbols with types other than STT_FUNC will not be referenced automatically through the procedure linkage table.

When the dynamic linker encounters a reference to a symbol that resolves to a definition of type STT_COMMON, it may (but is not required to) change its symbol resolution rules as follows: instead of binding the reference to the first symbol found with the given name, the dynamic linker searches for the first symbol with that name with type other than STT_COMMON. If no such symbol is found, it looks for the STT_COMMON definition of that name that has the largest size.

### Symbol Visibility
A symbol's visibility, although it may be specified in a relocatable object, defines how that symbol may be accessed once it has become part of an executable or shared object.

* STV_DEFAULT
* STV_PROTECTED
* STV_HIDDEN
* STV_INTERNAL

please refer to the original docs.


Global and weak symbols are also preemptable, that is, they may by preempted by definitions of the same name in another component.

TODO: Visibility and Binding resolution rule.

Symbols with section index SHN_COMMON may appear only in relocatable objects.

### Relocation

Elf32_Rel/Elf32_Rela/Efl64_Rel/Elf64_Rela

* r_offset: for a relocable file, byte offset from the beginning of the section;for an executable file or a shared object, the virtual address of the storage unit affected by the relocation. (PIE???)
* r_info: symbol table index and type of relocation. Relocation types are processor-specific.
* r_addend: Entries of type Elf32_Rel and Elf64_Rel store an implicit addend in the location to be modified.

If multiple consecutive relocation records are applied to the same relocation location (r_offset), they are composed instead of being applied independently, as described above.

### Program Header

Elf32_Phdr/Elf64_Phdr

* p_type
* p_offset: offset from the beginning of the file
* p_vaddr: virtual address the segment resides in memory
* p_paddr: physical address(on system for which physical addressing is relevant)
* p_filesz: number of bytes in file
* p_memsz: number of bytes in memory
* p_align

#### Segment Type

* PT_NULL
* PT_LOAD: if p_memsz > p_filesz, extra bytes are filled zero. Appear in the program header table in ascending order sorted on the p_vaddr member.
* PT_DYNAMIC: specifies dynamic linking information.
* PT_INTERP: dynamic interpreter path.
* PT_NOTE
* PT_SHLIB
* PT_PHDR: specifies the location and size of the program header table itself
* PT_TLS: ***Thread-Local*** Storage template

### Base Address

absolute code/position-independent code

???

Give relative position of segments are the save in (the same) object file or virtual memory:

<code>base address = the virtual address of any segment in memory - the corresponding virtual address in the file;</code>

### Segment Permissions

* PF_X
* PF_W
* PF_R

In no case, however, will a segment have write permission unless it is specified explicitly.

Omit: Segment Contents, Note Section

### Thread-Local Storage

TLS template, TLS initialization image.

See Ulrich Drepper's essay for more information.

## Dynamic Linking

* .dynamic section
* .hash section
* .got/.plt section

LD_BIND_NOW

### Dynamic Section

symbol _DYNAMIC

tagged union: Elf32_Dyn/Elf64_Dyn;

d_tag:

The following flags concerns with SO dependency:

* DT_NEEDED
* DT_SONAME
* DT_RPATH
* DT_RUNPATH

The following are flags:

* DT_FLAGS
* DT_BIND_NOW
* DT_SYMBOLIC
* DT_DEBUG
* DT_TEXTREL

The following concerns INIT/PREINIT/FINI:

* DT_INIT
* DT_FINI
* DT_INIT_ARRAY
* DT_FINI_ARRAY
* DT_INIT_ARRAY_SZ
* DT_FINI_ARRAY_SZ
* DT_PREINIT_ARRAY
* DT_PREINIT_ARRAYSZ

The following concerns symbol table and string table:

* DT_SYMTAB: address of symbol table
* DT_SYMENT: size of a symbol table entry
* DT_STRTAB: address of string table
* DT_STRSZ: string table size
* DT_HASH: address of symbol hash table

The following concerns REL/RELA table:

* DT_REL
* DT_RELSZ
* DT_RELENT
* DT_RELA
* DT_RELASZ
* DT_RELAENT

The following concerns PLT/GOT:

* DT_PLTRELSZ: total size of PLT relocation entries
* DT_JMPREL: address of PLT-only entries
* DT_PLTGOT: address assiciated with the PLT and/or GOT
* DT_PLTREL: type of plt relocation entry

The remaining flags:

* DT_NULL
* DT_ENCODING

#### DT_FLAGS

* DF_ORIGIN
* DF_SYMBOLIC: affect the dynamic linker's symbol resolution algorithm
* DF_TEXTREL
* DF_BIND_NOW
* DF_STATIC_TLS: static thread-local storage scheme

OMIT: Shared Object Dependencies, Substitution Sequences, Hash table, Initialization and Termination Functions
