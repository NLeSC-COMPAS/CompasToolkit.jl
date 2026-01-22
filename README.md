<p align="center">
  <img src="https://avatars.githubusercontent.com/u/132893361" width=230 />
</p>


# Compas Toolkit

![GitHub License](https://img.shields.io/github/license/NLeSC-COMPAS/compas-toolkit)
![GitHub Tag](https://img.shields.io/github/v/tag/NLeSC-COMPAS/compas-toolkit)

These are the bindings to Julia for the [Compas Toolkit](https://github.com/NLeSC-COMPAS/compas-toolkit).


# Usage

To use the Compas Toolkit in Julia, simply add it as a package to your Julia project.

```julia
$ julia
> using Pkg; Pkg.add(url="https://github.com/NLeSC-COMPAS/CompasToolkit.jl")
```

Alternatively, you can also close this repository and add it using its local path.

```julia
$ git clone --recurse-submodules http://github.com/NLeSC-COMPAS/CompasToolkit.jl
$ julia
> using Pkg; Pkg.develop(path="CompasToolkit.jl")
```

You can then import the library with `using CompasToolkit`.

For examples of using the toolkit, take a look at the scripts available in the `CompasToolkit.jl/tests` directory.
