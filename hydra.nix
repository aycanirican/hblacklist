{ system ? builtins.currentSystem
, nixpkgs
, hblacklistSrc
}:

let
  haskellPackages = nixpkgs.haskellPackages;
  inherit (haskellPackages) cabal;
in

cabal.mkDerivation (self: {
  pname = "hblacklist";
  src = hblacklistSrc
  isLibrary = false;
  isExecutable = true;
  preConfigure = ''rm -rf dist'';
  noHaddock = true;
  buildDepends = with haskellPackages;[ 
    attoparsec hdaemonize hinotify network text 
  ];
  meta = {
    homepage = "http://github.com/aycanirican/hblacklist";
    description = "A utility which listens snort logs and blacklists IP addresses for a certain time using iptables";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
  buildTools = [ haskellPackages.cabalInstall_1_20_0_3 ];
  enableSplitObjs = false;
})
