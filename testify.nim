import os, streams, xmltree, strformat, strutils

const
  R = "\e[31;1m"
  G = "\e[32;1m"
  Y = "\e[33;1m"
  B = "\e[34;1m"
  D = "\e[0m"

if paramCount() < 1:
  echo "Too few arguments"
  quit QuitFailure

let report = newFileStream(paramStr(1), fmWrite)
var testsuites = newElement("testsuites")

for d in commandLineParams()[1..^1]:
  let binDir = d / "bin"
  var
    suitename = lastPathPart(d)
    testsuite = newElement("testsuite")
    tests: int
    failures: int
    errors: int

  stdout.write &"{B}[Suite]{D} " & suitename & "\n"

  for f in walkFiles(d / "t*.nim"):
    inc(tests)

    var
      casename = splitFile(f).name
      testcase = newXmlTree("testcase", [], {"name": casename}.toXmlAttributes)

    let c = execShellCmd(&"nim c --outdir:{binDir} {f} >/dev/null 2>&1")
    if c != 0:
      inc(errors)
      stdout.write &"  {R}[ER]{D} " & casename & "\n"
      testcase.add(newXmlTree("failure", [],
                              {"message": "compile error"}.toXmlAttributes))
    else:
      let
        chop = splitFile(f)
        exe = chop.dir / "bin" / chop.name
        r = execShellCmd(&"{exe} >/dev/null 2>&1")
      if r != 0:
        stdout.write &"  {Y}[FL]{D} " & casename & "\n"
        inc(failures)
        testcase.add(newElement("failure"))
      else:
        stdout.write &"  {G}[OK]{D} " & casename & "\n"
    testsuite.add(testcase)
  testsuite.attrs = {"name": suitename,
                     "tests": $tests,
                     "errors": $errors,
                     "failures": $failures}.toXmlAttributes
  testsuites.add(testsuite)

  echo "----------------------------------------\n" &
       &"  {G}[OK]{D} {(tests - errors - failures).intToStr(3)}\n" &
       &"  {Y}[FL]{D} {failures.intToStr(3)}\n" &
       &"  {R}[ER]{D} {errors.intToStr(3)}\n" &
       "----------------------------------------\n"

report.write($testsuites)
close(report)
