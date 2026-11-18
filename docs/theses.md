# Twelve theses

These are the working doctrine of Pyra, formerly python-gate. They describe the Level 3 world this repository builds today. What Level 4 might become is below the theses. It is a direction. It is not code in this tree.

1. **The Python environment is part of the program.** An interpreter, a set of wheels, and a script are one artifact. Shipping the script alone is a wish.

2. **A lockfile is not a closure.** `uv.lock` pins packages. `flake.lock` pins builders. The closure is the store paths those two proofs evaluate to.

3. **uv owns the expression.** Add, remove, and pin through `pyproject.toml` / `uv.lock`. Do not hand-translate the lock into `python3Packages`. Do not edit lockfiles by hand.

4. **Nix is the gate.** Nothing enters the world except through evaluation. If it does not evaluate, it is not a dependency.

5. **`mkVirtualEnv` / `withPackages` builds a world.** Individual packages are not a product. The aggregated environment is.

6. **`mkApplication` / `wrapProgram` locks the door.** The virtualenv is an implementation detail. The product is a wrapped binary.

7. **Wrapping is FFI.** The ABI of the program is the store path, not `LD_LIBRARY_PATH`, not the host `libstdc++`, not a hope that the wheel matches the machine.

8. **Eval is the critic.** Tests that run against a second venv are reviewing a different play. `nix flake show`, import inside the declared env, `nix run`.

9. **The product is `nix run`.** A green `uv sync` is a proof of packages. The product is the closed world a stranger can run without becoming you.

10. **nix-ld is the FHS lie.** It is Level 2: useful for unpatched binaries, unsafe as a default, and never bit-identical. On NixOS use `NIX_LD` / `NIX_LD_LIBRARY_PATH`. Never set `LD_LIBRARY_PATH` as the default.

11. **One Python set.** `devShells.default` and `packages.default` share the same interpreter and the same uv2nix overlay. Editables on the shell are a lens, not a second world. The peace treaty (`UV_NO_SYNC`, `UV_PYTHON`, `UV_PYTHON_DOWNLOADS=never`, unset `PYTHONPATH`) is how they stay one.

12. **What this template builds today is Level 3.** Pure Python. No native extension in the closure. Level 4 — PyO3/maturin kernels, Bend 2 components with machine-checked laws, optional CUDA, same store path — is the direction being explored. Level 2 is still not bit-identical.

## Where Level 4 might go

The same gate, a wider world. Ordinary Python would stay the control plane. Native code would be allowed in only when Nix evaluates it, and it would live in the same virtualenv.

Three ideas are in play:

- **PyO3 / maturin** for performance-critical or ecosystem-shaped kernels (sampling, tokenizers, loaders, rust-numpy interop, small CUDA kernels).
- **Bend 2** for components whose properties are stated as laws and checked by the Bend compiler before the extension is built. Shape-safe transforms, proved round-trips, tree-parallel reductions, policy pieces.
- **CUDA as an explicit mode.** CPU would remain what you get when you ask for nothing. torch, JAX, and anything else that needs the GPU would receive `cudaPackages` only under that mode.

Open questions, none of them settled here:

- crane, or a lighter Cargo lock import plus build-system overlays, for the Rust build?
- bend-python, or a thin CFFI/PyO3 wrapper around Bend-generated C, as the bridge into CPython?
- The intent is that an open or false Bend proof stops the product from building. How should `LAWS.bend` and `PROOF.bend` be wired so that is true, and so the resulting extension imports like any other module?
- How is the CUDA overlay selected so it stays opt-in and still evaluates to one closure?
- When a project actually contains Bend components, agent grading would grow a proof check. What is the smallest addition that does that and stays quiet on pure-Python projects?

The pure-Python path, the peace treaty, and the two lockfiles stay in every version of this picture. This direction is not a plan to replace PyTorch or JAX for dense linear algebra. Maturin and a Bend bridge are the two extension paths under discussion. Other native build systems can be added later by the same overlay mechanism, if they earn it. Bend on GPU is available only where Bend's own backends allow it; CPU and proofs are the part worth getting right first.
