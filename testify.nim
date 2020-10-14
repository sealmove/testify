import os, osproc, streams, xmltree, strformat, strutils, times

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
  echo (getCurrentDir() / &"{d}")
  setCurrentDir(getCurrentDir() / &"{d}")
  createDir("bin")

  var
    suitename = lastPathPart(d)
    testsuite = newElement("testsuite")
    tests: int
    failures: int
    errors: int

  stdout.write &"{B}[Suite]{D} " & suitename & "\n"

  for f in walkFiles("t*.nim"):
    inc(tests)

    var
      casename = splitFile(f).name
      testcase = newElement("testcase")

    let (co, cc) = execCmdEx(&"nim c --hints:off -w:off --outdir:bin {f}")
    if cc != 0:
      inc(errors)
      stdout.write &"  {R}[ER]{D} " & casename[1..^1] & "\n"
      testcase.attrs = {"name": casename, "time": "0.00000000"}.toXmlAttributes
      testcase.add(newXmlTree("failure", [],
                              {"message": co}.toXmlAttributes))
    else:
      let
        chop = splitFile(f)
        exe = chop.dir / "bin" / chop.name
        startTime = epochTime()
        (ro, rc) = execCmdEx(&"{exe}")
        duration = epochTime() - startTime
      testcase.attrs = {"name": casename, "time": $duration}.toXmlAttributes
      if rc != 0:
        stdout.write &"  {Y}[FL]{D} " & casename[1..^1] & "\n"
        inc(failures)
        testcase.add(newXmlTree("failure", [],
                                {"message": ro}.toXmlAttributes))
      else:
        stdout.write &"  {G}[OK]{D} " & casename[1..^1] & "\n"
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
