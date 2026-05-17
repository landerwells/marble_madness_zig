{
  description = "Sokol dependency flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        devShells.default = with pkgs; let
          libs = lib.makeLibraryPath (lib.optionals (lib.strings.hasInfix "linux" system) [
            libGL
            vulkan-loader
            libx11
            libxcursor
            libxi
            libxrandr
            libxkbcommon
            wayland
            alsa-lib
          ]);
        in
          mkShell {
            buildInputs =
              [
                zig
                zls
              ]
              ++ lib.optionals (lib.strings.hasInfix "linux" system) [
                # OpenGL / GLFW dependencies
                libGL
                libxkbcommon
                libx11
                libxcursor
                libxi
                libxrandr

                # Wayland
                wayland
                wayland-protocols

                # For sokol's optional Vulkan backend
                vulkan-loader
                vulkan-tools

                # Audio (if using sokol_audio)
                alsa-lib
              ];

            LD_LIBRARY_PATH = libs;
            LIBRARY_PATH = libs;
          };
      }
    );
}
