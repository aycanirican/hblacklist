{ system ? builtins.currentSystem
, pkgs
, hblacklistSrc
}:

let
  hs = pkgs.haskellPackages;
  inherit (hs) cabal;
in

cabal.mkDerivation (self: {
  pname = "hblacklist";
  src = hblacklistSrc;
  version = hblacklistSrc.gitTag;
  isLibrary = false;
  isExecutable = true;
  preConfigure = ''rm -rf dist'';
  noHaddock = true;
  buildDepends = with pkgs.haskellPackages;[ 
    hdaemonize attoparsec hinotify network text 
  ];
  meta = {
    homepage = "http://github.com/aycanirican/hblacklist";
    description = "A utility which listens snort logs and blacklists IP addresses for a certain time using iptables";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
  buildTools = [ hs.cabalInstall_1_20_0_3 ];
  enableSplitObjs = false;
})
