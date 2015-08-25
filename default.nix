{ turtle, optparse-applicative,

  cabal-install, ghc-mod, stylish-haskell, hoogle, hasktags, hlint,

  mkDerivation, stdenv }:

mkDerivation {
  pname = "xctl";
  version = "0.1.0.0";
  src = ./.;
  buildDepends = [ turtle optparse-applicative ];
  buildTools = [ cabal-install ghc-mod stylish-haskell hoogle hasktags hlint ];
  license = stdenv.lib.licenses.gpl3;
}
