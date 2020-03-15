import os, streams, xmltree, strformat

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
    errors: int
    failures: int

  for f in walkFiles(d / "t*.nim"):
    inc(tests)

    var
      casename = splitFile(f).name
      testcase = newXmlTree("testcase", [], {"name": casename}.toXmlAttributes)

    let c = execShellCmd(&"nim c --outdir:{binDir} {f} >/dev/null 2>&1")
    if c != 0:
      inc(errors)
      testcase.add(newXmlTree("failure", [],
                              {"message": "compile error"}.toXmlAttributes))
    else:
      let
        chop = splitFile(f)
        exe = chop.dir / "bin" / chop.name
        r = execShellCmd(&"{exe} >/dev/null 2>&1")
      echo &"{exe} >/dev/null 2>&1"
      if r != 0:
        inc(failures)
        testcase.add(newElement("failure"))
    testsuite.add(testcase)
  testsuite.attrs = {"name": suitename,
                     "tests": $tests,
                     "errors": $errors,
                     "failures": $failures}.toXmlAttributes
  testsuites.add(testsuite)

report.write($testsuites)
close(report)
