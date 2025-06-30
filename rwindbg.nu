export def main [] {
    if not ("Cargo.toml" | path exists) {
        error make {msg: "Cargo.toml not found cd into a rust project" }
    }
    let src_types_supported = '*.rs *.cpp *.h *.hpp *.c *.S'
    let rustc_sysroot = rustc --print=sysroot

    let rust_etc_for_natvis = $rustc_sysroot  | path join 'lib\rustlib\etc'
    let rust_bin_for_pdb = $rustc_sysroot  | path join 'bin'
    let rust_src_for_rs = $rustc_sysroot  | path join 'lib\rustlib\src\rust'
    rustup component add rust-src

    let repo_base = git rev-parse --show-toplevel
    # NOTE: where downloaded pdb files will be cached
    let tempdir = $env.TEMP
    let pdb_cache = $tempdir | path join 'rwindbg\symbols'
    mkdir ($pdb_cache | path join ms)
    mkdir ($tempdir | path join 'rwindbg\source')

    print "Env var settings that WinDbg uses"
    $env | transpose name value | where {$in.name | str starts-with _NT}
    $env | transpose name value | where {$in.name | str starts-with DBGHELP}
    print "Rust env vars will also affect our commands"
    $env | transpose name value | where {$in.name | str starts-with RU}


    let $windbg_init_script = $tempdir | path join 'rwindbg.windbg'


    print $"========== .reload /f - forces loading of the symbols associated with our currently loaded modules> ($windbg_init_script)"
    print $".reload /f>> ($windbg_init_script)"

    print $"'sxe *' tells the debugger to stop when any of the known exceptions happen at the instruction where it happens on the ipc \(instruction pointer register\)"
    print $"sxe *>> ($windbg_init_script)"

    print $"an example how to load a WinDBG extension"
    print $".load uext>> ($windbg_init_script)"

    print $"most extensions will list their commands when you execute their help command"
    print $"!uext.help>> ($windbg_init_script)

    # print "add new exceptions that is not on WinDBG original list, e06d7363 is a C++ exception to indicate unhandled exception"
    # print $"sxn -c2 \"k;.echo First Chance Exception at this stack above\" e06d7363>> ($windbg_init_script)

    print $"add a new exception that is not on WinDBG original list; 406D1388 'MS_VC_EXCEPTION' is a special exception used by MS VC++ that the debugger process and uses its argument to set the name of the thread to aid debugging"
    print $"sxe -c \"k;.echo First Chance Exception setting a thread name;.echo type GN when done looking at the stack\" 406D1388>> ($windbg_init_script)

    # print $"add some commands to execute on STACK_OVERFLOW; c00000fd 'STAUTS_STACK_OVERFLOW'"
    # print $"sxe -c \".echo Show stacks for all existing threads;~*k;.echo Show current thread 'where stack overflow event happened' with more details, showing first 4 args to each call on the stack;.echo type GN when done looking at the stack\" c00000fd>> ($windbg_init_script)
    #
    # print $"sxe -c \".echo Show current thread (where stack overflow event happened) with more details, showing first 4 args to each call on the stack;~#k;.echo type GN when done looking at the stack\" sov>> %$windbg_init_script%"
    # print $"find the address of a Win32 API function: CreateFileW (uncomment if desired; left as an example)"
    # print $"x *!CreateFileW>> ($windbg_init_script)
    #
    # print $"The following lines were output on my laptop when I executed the command above; as OS versions change, you might get different results"
    # print $"00007fff`6e6149f0 KERNELBASE!CreateFileW (CreateFileW)"
    # print $"00007fff`6fdd0460 KERNEL32!CreateFileW (CreateFileW)"
    # print $".echo This is an example of a reference to the Win32 API being exported by other OS DLLs>> ($windbg_init_script)
    # print $"uf KERNEL32!CreateFileW>> ($windbg_init_script)
    # print $".echo You can disassemble the actual Win32API by typing: uf KERNELBASE!CreateFileW>> ($windbg_init_script)
    #
    # print $"finally we find the real CreateFileW() Win32 API function (uncomment next line if you want to see the disassembly of it; left as example)"
    # print $"uf KERNELBASE!CreateFileW>> ($windbg_init_script)
    #
    # print $"sets a beakpoint on a Win32 API: CreateFileW() which is used to open and/or create files (uncomment next line if desired; left as example)"
    # print $"bp KERNELBASE!CreateFileW>> ($windbg_init_script)
    #
    # print $"tell WinDBG to start running the process once it stops on the initial break point, at which point all modules are loaded into the process memory"
    # print $"g>> ($windb_init_script)
    #
    # print $"load formatters to printout rust data structures in WinDBG"
    let natvis_files = ls $rust_etc_for_natvis | get name | where {$in =~ .natvis}
    $natvis_files | each { $".nvload ($in | path basename)" }

    let pdbpath_init_script = $"($windbg_init_script)_PDBpath"

    echo $".sympath cache*($pdb_cache)\\ms;srv*https://msdl.microsoft.com/download/symbols" | save --append %PDBPATH_INIT_SCRIPT%"

    cd $rust_bin_for_pdb

    let pdb_files = ls ($rust_bin_for_pdb | path join 'dir/s/b') | get name | where {$in =~ .pdb}
    $pdb_files | each { $"PREV=($in | path basename)" }


    # :: merge all unique source containing directories to windbg init script's source path

}
