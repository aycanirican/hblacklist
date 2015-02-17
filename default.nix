{ mkDerivation, attoparsec, base, hdaemonize, hinotify, network
, network-uri, process, stdenv, text
}:
mkDerivation {
  pname = "hblacklist";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  buildDepends = [
    attoparsec base hdaemonize hinotify network network-uri process
    text
  ];
  homepage = "http://github.com/aycanirican/hblacklist";
  description = "A utility which listens snort logs and blacklists IP addresses for a certain time using iptables";
  license = stdenv.lib.licenses.bsd3;
}
