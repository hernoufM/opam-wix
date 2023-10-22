This test verify functionalities of `opam-wix` compiled with MinGW compiler. We do this by using -k option to keep every build artefact for Wix. For test purpose, we will use mock version of package `foo`, `cygcheck` and dlls. Test depends on Wix toolset of version 3.11.

=== Opam setup ===
  $ export OPAMNOENVNOTICE=1
  $ export OPAMYES=1
  $ export OPAMROOT=$PWD/OPAMROOT
  $ export OPAMSTATUSLINE=never
  $ export OPAMVERBOSE=-1
  $ cat > compile << EOF
  > #!/bin/sh
  > echo "I'm launching \$(basename \${0}) \$@!"
  > EOF
  $ chmod +x compile
  $ tar czf compile.tar.gz compile
  $ SHA=`openssl sha256 compile.tar.gz | cut -d ' ' -f 2`
Repo setup
  $ mkdir -p REPO/packages/
  $ cat > REPO/repo << EOF
  > opam-version: "2.0"
  > EOF
Foo package.
  $ mkdir -p REPO/packages/foo/foo.0.1 REPO/packages/foo/foo.0.2
  $ cat > REPO/packages/foo/foo.0.1/opam << EOF
  > opam-version: "2.0"
  > name: "foo"
  > version: "0.1"
  > maintainer : [ "John Smith"]
  > synopsis: "Foo tool"
  > tags : ["tool" "dummy"]
  > build: [ "sh" "compile" name ]
  > install: [
  >  [ "cp" "compile" "%{bin}%/%{name}%" ]
  > ]
  > url {
  >  src: "file://./compile.tar.gz"
  >  checksum: "sha256=$SHA"
  > }
  > EOF
  $ cat > REPO/packages/foo/foo.0.2/opam << EOF
  > opam-version: "2.0"
  > name: "foo"
  > version: "0.2"
  > maintainer : [ "John Smith"]
  > synopsis: "Foo tool"
  > tags : ["tool" "dummy"]
  > build: [ "sh" "compile" name ]
  > install: [
  >  [ "cp" "compile" "%{bin}%/%{name}%_1" ]
  >  [ "cp" "compile" "%{bin}%/%{name}%_2" ]
  > ]
  > url {
  >  src: "file://./compile.tar.gz"
  >  checksum: "sha256=$SHA"
  > }
  > EOF
Opam setup
  $ mkdir $OPAMROOT
  $ opam init --bare ./REPO --no-setup --bypass-checks
  No configuration file found, using built-in defaults.

  <><> Fetching repository information ><><><><><><><><><><><><><><><><><><><><><>
  [default] Initialised
  $ opam switch create one --empty

Wix Toolset config.
  $ unzip -qq -d wix311 wix311.zip
  $ chmod 755 wix311/*
  $ WIX_PATH=$PWD/wix311
Cygcheck overriding and dlls.
  $ mkdir dlls bins
  $ touch dlls/dll1.fakedll dlls/dll2.fakedll

  $ chmod +x bins/cygcheck
  chmod: cannot access 'bins/cygcheck': No such file or directory
  [1]
  $ export PATH=$PWD/bins:$PATH
================== Test 1 ====================
Try to install package with just one binary.
  $ opam install foo.0.1
  [NOTE] External dependency handling not supported for OS family 'windows'.
         You can disable this check using 'opam option --global depext=false'
  The following actions will be performed:
    - install foo 0.1

  <><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  -> retrieved foo.0.1  (file://./compile.tar.gz)
  -> installed foo.0.1
  Done.
  $ cat > bins/cygcheck << EOF
  > #!/bin/sh
  >
  > echo "$(cygpath -wa $PWD/OPAMROOT/one/bin/foo)"
  > echo "$(cygpath -wa $PWD/dlls/dll1.fakedll)"
  > echo "$(cygpath -wa $PWD/dlls/dll2.fakedll)"
  >
  > EOF
  $ opam-wix --keep-wxs --wix-path=$WIX_PATH foo

  <><> Initialising opam ><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  Package foo.0.1 found with binaries:
    - foo
  Path to the selected binary file : $TESTCASE_ROOT/OPAMROOT/one/bin/foo
  <><> Creating installation bundle <><><><><><><><><><><><><><><><><><><><><><><>
  Getting dlls:
  Bundle created.
  <><> WiX setup ><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
  Compiling WiX components...
  Producing final msi...
  Done.
