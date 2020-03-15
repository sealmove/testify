import os, strformat, xmltree

type
  Unit = object
    name: string
    retc: int
    retr: int

var units = newSeqOfCap[Unit](paramCount())

for f in commandLineParams():
  var u = Unit(name: splitFile(f).name)
  let c = execShellCmd(&"nim c -w:off --hints:off {f}")
  u.retc = c
  if c == 0:
    let r = execShellCmd(&"./{f}")
    u.retr = r
  units.add u

for u in units:
  echo u.name
  echo "\tretc: " & $u.retc
  echo "\tretr: " & $u.retr

# echo newXmlTree("testsuites", [])
