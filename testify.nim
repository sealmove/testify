import os, osproc, streams, xmltree, strformat, strutils, terminal, times

proc main =
  let params = commandLineParams()
  if "--help" in params or "-h" in params or params.len < 2:
    quit("Compile-Run-Report helper for Nim\n\n" &
        "Command line syntax: \n\n" &
        "  > ./testify output_path suite_dir1, suite_dir2, ...\n")

  let
    suites = newElement("testsuites")
    curDir = getCurrentDir()
    binDir = "bin"
    nim = getCurrentCompilerExe()

  for i in 1 ..< params.len:
    let suiteDir = curDir / params[i]
    stdout.write suiteDir
    setCurrentDir(suiteDir)
    createDir(binDir)

    let
      suiteName = lastPathPart(params[i])
      suite = newElement("testsuite")
    var
      tests = 0
      failures = 0
      errors = 0

    stdout.styledWrite(styleBright, fgBlue, "\n[Suite] ", resetStyle, suiteName)

    for f in walkFiles("t*.nim"):
      let
        (testDir, testName, _) = splitFile(f)
        test = newElement("testcase")
        (co, cc) = execCmdEx(&"{nim} c --hints:off -w:off --outdir:{binDir} {f}")

      if cc != 0:
        stdout.styledWrite(styleBright, fgRed, "\n  [ER] ", resetStyle, testName)
        test.attrs = {"name": testName, "time": "0.00000000"}.toXmlAttributes
        test.add(newXmlTree("error", [], {"message": xmltree.escape(co)}.toXmlAttributes))
        inc(errors)
      else:
        let
          exe = testDir / binDir / testName.addFileExt(ExeExt)
          startTime = epochTime()
          (ro, rc) = execCmdEx(exe)
          duration = epochTime() - startTime

        test.attrs = {"name": testName,
            "time": formatFloat(duration, ffDecimal, 8)}.toXmlAttributes
        if rc != 0:
          stdout.styledWrite(styleBright, fgYellow, "\n  [FL] ", resetStyle, testName)
          test.add(newXmlTree("failure", [], {"message": xmltree.escape(ro)}.toXmlAttributes))
          inc(failures)
        else:
          stdout.styledWrite(styleBright, fgGreen, "\n  [OK] ", resetStyle, testName)

      suite.add(test)
      inc(tests)

    suite.attrs = {"name": suiteName, "tests": $tests, "errors": $errors,
        "failures": $failures}.toXmlAttributes
    suites.add(suite)

    stdout.styledWrite "\n----------------------------------------",
        styleBright, fgGreen, "\n  [OK] ", resetStyle, &"{(tests - errors - failures):3}",
        styleBright, fgYellow, "\n  [FL] ", resetStyle, &"{failures:3}",
        styleBright, fgRed, "\n  [ER] ", resetStyle, &"{errors:3}",
        "\n----------------------------------------\n"

  setCurrentDir(curDir)
  let report = newFileStream(params[0], fmWrite)
  if report == nil:
    quit("Failed to create output file: " & params[0])

  report.write($suites)
  close(report)

main()
