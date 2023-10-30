{
  description = "Miki's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    myNurPackages = {
      url = "github:AsterisMono/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvim-config = {
      url = "git+https://github.com/AsterisMono/nvim-config?ref=despacito";
      flake = false; 
    };
  };

  outputs = inputs:
    let
      nixos = import ./configurations/nixos.nix inputs;
      collectFiles = import ./utils/collect-files.nix inputs.nixpkgs.lib;
    in
    {
      nixosConfigurations = nixos.configs;
      lib = {
        inherit collectFiles;
      };
      sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIESmYINQDHO1+7FY0mDdcl+UIu2RPuMNOtj242d2N3cf";
    };
}
