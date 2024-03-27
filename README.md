# ClimaArtifacts

Pre-processing pipelines for the input data used by the CliMA project and
`Artifacts.toml` entry to use those artifacts.

Each folder (except for `ClimaArtifactsHelper.jl`) contains everything that is
needed to produce and use an artifact for CliMA:
- A readme to describe the details,
- `Project.toml` and a `Manifest.toml` files that describe the version of packages required,
- A `create_artifact.jl` Julia script to do the per-processing, optionally
  retrieving the data and creating an `Artifact.toml` entry,
- A `OutputArtifacts.toml` entry that contains the code needed to use that artifact. This is
  produced by the `create_artifact.jl` script.

To use an artifact, copy the content of the `OutputArtifacts.toml` to your
`Artifacts.toml`.

To recreate an artifact, `cd` into the desired folder and run `julia --project
create_artifact.jl`.

The `ClimaArtifactsHelper.jl` contains shared functions used across the various
artifacts.

## Artifacts available

- Aerosol data for the year 2005 (monthly means averaged over the years 2000-2009)


# The ultimate guide to ClimaArtifacts

Last update: 27 March 2023

#### What is an artifact?

Sometimes, Julia packages require external piece of binary data to work. This
might be a compiled library, a binary blob, or anything else. At CliMA, we use
Julia artifacts to define and manage external data required to run our models
(e.g., the surface albedo of the globe as a function of time).

> Important: While we refer to data as artifacts, technically, Julia artifacts
> are always folders and not single files.

#### As a developer, how do I use an existing artifact?

You can find the list of artifacts associated to a package by looking at its
`Artifacts.toml` file.

Let us consider an example `Artifacts.toml`.
```toml
[era5_static_example]
git-tree-sha1 = "9e0fa7970c5ade600867f5afe737bc3ab6930204"

    [[era5_static_example.download]]
    sha256 = "6c2c3312ff49776ab4d3db7e84ba348dc8e3ffad2d3cb5e77e35039bdeec1610"
    url = "https://caltech.box.com/shared/static/pdsre5tumpc04qbomzjduw07ryd3emwj.gz"

[era5_example]
git-tree-sha1 = "c08d3035085c3c2969d1d9fb6f299686bad8d253"
very_important = "yes"

[socrates]
git-tree-sha1 = "43563e7631a7eafae1f9f8d9d332e3de44ad7239"
lazy = true

    [[socrates.download]]
    url = "https://github.com/staticfloat/small_bin/raw/master/socrates.tar.gz"
    sha256 = "e65d2f13f2085f2c279830e863292312a72930fee5ba3c792b14c33ce5c5cc58"
```

This `Artifacts.toml` defines three distinct artifacts named
`era_static_example`, `era5_example`, and `socrates`. The name is local to this
package and there could be packages with artifacts that share the same names.

Let us focus on the first one,
```toml
[era5_static_example]
git-tree-sha1 = "9e0fa7970c5ade600867f5afe737bc3ab6930204"

    [[era5_static_example.download]]
    sha256 = "6c2c3312ff49776ab4d3db7e84ba348dc8e3ffad2d3cb5e77e35039bdeec1610"
    url = "https://caltech.box.com/shared/static/pdsre5tumpc04qbomzjduw07ryd3emwj.gz"
```
In the brackets, we have the name of the artifact, `era5_static_example`. This
is how we access this artifact from the code in this package (see below). Next,
we have the `git-tree-sha1`, this is a cryptographic hash used to verify the
integrity of the artifact. When the artifact is downloaded, Julia checks that
the hash of the downloaded folder corresponds to one in the `Artifacts.toml`.
The hash is also used to identify the same artifact across different packages
(even if they might have different names), allowing for reuse. The subsequent
section, `[[era5_static_example.download]]`, specifies how to obtain the
artifact.

Now that we have a sense of how an artifact is specified, let us see how to use
it in the code. If we use directly the Julia infrastructure, we can simply import
`Artifacts`:
```julia
using Artifacts
println(artifact"era5_static_example")
# ~/.julia/artifacts/9e0fa7970c5ade600867f5afe737bc3ab6930204
```
Note that `artifact"era5_static_example"`is the path of a folder. The folder
could contain one or multiple files, but it is up to the user to specify which
one they want to access. Suppose this artifact only contains one file,
`era5.nc`, the code to access that file would look like
```julia
using Artifacts
era5_data = joinpath(artifact"era5_static_example", "era5.nc")
# ~/.julia/artifacts/9e0fa7970c5ade600867f5afe737bc3ab6930204/era4.nc
```
This is **not** the preferred way to access artifacts. Instead, we use
`ClimaUtilities.ClimaArtifacts`. This module is MPI safe and allows us to keep
track of what artifacts are being used. When the `ClimaComms` context is not
available or relevant, `ClimaUtilities.ClimaArtifacts` provides a drop-in
replacement for `artifact`:
```julia
using ClimaUtilities.ClimaArtifacts
era5_data = joinpath(@clima_artifact("era5_static_example"), "era5.nc")
# ~/.julia/artifacts/9e0fa7970c5ade600867f5afe737bc3ab6930204/era4.nc
```
If the context is available, it is always best to pass it to (as in
`clima_artifact("era5_static_example", context)`). This ensures that the
acquiring the artifact is MPI-safe.

Let us now look at the second block,
```toml
[era5_example]
git-tree-sha1 = "c08d3035085c3c2969d1d9fb6f299686bad8d253"
very_important = "yes"
```
This second block does not contain a download section. This makes the artifact
undownloadable. This means that Julia will not try to download the artifact.
Instead, the folder has to be acquired in a different way and the path specified
using the `Overrides` mechanism (more on this below). Large artifacts (> 500 MB)
should be marked as undownlodable. If you are using the Caltech cluster, all the
undownloadable artifacts have been handled for you and there is nothing else you
have to do. You can use undownloadable artifacts exactly in the same way you would
use downlodable one (ie, with `@clima_artifacts`).

This second block also has an additional tag, `very_important = "yes"`. We are
free to add any extra information to the `Artifacts.toml`.

Finally, the last block introduces us to a new tag, `lazy = true`. This
annotation marks the artifact as lazy: instead of being downloaded upon
instantiation, it is downloaded the first time is used. To use this we must pass
the `ClimaComms` context and also load the `LazyArtifacts` package.
```julia
using LazyArtifacts
using ClimaUtilities.ClimaArtifacts
socrates = joinpath(@clima_artifact("socrates"), "apology.txt")
```

#### How to download an undownloadable artifact?

If you are on the Caltech cluster, some has already downloaded and configured
everything for you (see below on how this is done in practice). If you are using
a different machine, you will have to create a file `Overrides.toml` in the
`artifacts` folder of your depot (typically `~/.julia`). The `Overrides.toml`
provides a map between `git-tree-sha1`s to paths. The simplest `Overrides.toml`
might look like
```toml
c08d3035085c3c2969d1d9fb6f299686bad8d253 = "/path/to/era5folder"
```
This `Overrides.toml` binds the artifact with id
`c08d3035085c3c2969d1d9fb6f299686bad8d253` to a specific folder on your machine.
Now, it is up to you to fill the folder with the correct files. You should add
bindings for all the undownloadable artifacts you want to use in your
simulations.

#### As a developer, how do I add a new ClimaArtifact?

CliMA artifacts must be reproducible, respect the licenses under which original
data is released, and be consistent across different repositories. The
`ClimaArtifacts` collects the pipelines and environments used to produce data,
as well as tools to help creating Julia artifacts.

To create a new artifact:
1. Clone the `ClimaArtifacts` repository
2. Create a new folder with the name of your artifact, e.g., `dormouse1819`
3. Create a new Julia project with the script that acquires and processes the
   data. The script should save all the new data files into a new folder. Such
   folder will become the artifact (remember, Julia artifacts are always folder)
4. At the end of your script, call `create_artifact_guided(folder_path;
   artifact_name = basename(@__DIR__))`
5. The `create_artifact_guided` starts a guided process that gives you the
   string to put in your `Artifacts.toml` files.

The `create_artifact_guided` behaves differently depending on the size of the
artifact. For small artifacts, it creates and archive, prompt you to upload the
archive to the correct place, computes the hash, and validates that the archive
can be correctly downloaded and corresponds to the hash.

For large artifacts, we rely on the `Overrides.toml` mechanism described in the
previous section. In this case, you will have to copy the data to the
`/groups/esm/ClimaArtifacts/artifact` folder on the cluster and add a new entry
to the `Overrides.toml` that lives there.

#### How are artifacts managed on the Caltech cluster?

We do not want to keep downloading the same artifacts over and over, especially
when they are large in size. So, on the Caltech cluster, we store them in a
folder and point the `Artifacts` system to that folder. This section describes
how this is accomplished.

The implementation of the system that allows a centrally-managed artifact system
relies on the `ClimaModules`. We install and maintain our version of Julia,
which is accessible to users via `ClimaModules`. This allows us to execute code
upon startup to customize the behavior of Julia for all our users. This is
accomplished by editing the `/etc/julia/startup.jl` file. In particular, we are
going to add a new entry to the `Base.DEPOT_PATH` vector to point to
`/groups/esm/ClimaArtifacts`. So, we add a new line to the shared `startup.jl`:
```
push!(Base.DEPOT_PATH, "/groups/esm/ClimaArtifacts")
```
This adds `/groups/esm/ClimaArtifacts` as depot with lowest priority.
In`/groups/esm/ClimaArtifacts`, there is a folder `artifacts`, which contains
the data and contains a `Overrides.toml` that is loaded by all users. In this way,
every user will automatically have access to all the artifacts available on the
system.

> Q: Why are we using the `startup.jl`instead of using system-wide depot?

> A: Typically, `Base.DEPOT_PATH` contains two depots that are "system-wide"
> (ie, meant to be managed by the system administrators). Unfortunately,
> changing the `JULIA_DEPOT_PATH` resets `Base.DEPOT_PATH`, so that the system
> depots are ignored. We use `JULIA_DEPOT_PATH` extensively in `slurm-buildkite`.

