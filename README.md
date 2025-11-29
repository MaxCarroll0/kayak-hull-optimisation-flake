Nix flake for a direnv developer environment to build a python project on [optimising kayak hulls](https://github.com/Extreme-Kayaking/kayak-hull-optimisation)

## Instructions
Roughly along the lines of:

- Install nix: `sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon`
- Install direnv: `apt install direnv`
- Enable flakes: `echo "experimental-features = nix-command flakes" | tee ~/.config/nix/nix.conf`
- (Optional) Install nix-direnv: `nix profile install nixpkgs#nix-direnv`
- Enable direnv in root dir of project: `direnv allow`
