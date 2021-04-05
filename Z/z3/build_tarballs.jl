# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "z3"
version = v"4.8.10"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Z3Prover/z3.git", "517d907567f4283ad8b48ff9c2a3f6dce838569e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/z3/

mkdir z3-build && cd z3-build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_FIND_ROOT_PATH="${prefix}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DZ3_BUILD_JULIA_BINDINGS=True \
    ..
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/z3/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms_libcxxwrap = [
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows")
]

platforms = filter(x->!(x in platforms_libcxxwrap), supported_platforms())

platforms_libcxxwrap = expand_cxxstring_abis(platforms_libcxxwrap)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products_libcxxwrap = [
    LibraryProduct("libz3", :libz3),
    LibraryProduct("libz3jl", :libz3jl),
    ExecutableProduct("z3", :z3)
]

products = [
    LibraryProduct("libz3", :libz3),
    ExecutableProduct("z3", :z3)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("libcxxwrap_julia_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

include("../../fancy_toys.jl")

if any(should_build_platform.(triplet.(platforms_libcxxwrap)))
    build_tarballs(non_reg_ARGS, name, version, sources, script, platforms_libcxxwrap, products_libcxxwrap, dependencies; preferred_gcc_version=v"8")
end
if any(should_build_platform.(triplet.(platforms)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
end
