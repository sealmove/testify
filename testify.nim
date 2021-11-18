import os, osproc, streams, xmltree, strformat, strutils, times

const
  stError = "\e[31;1m"
  stSuccess = "\e[32;1m"
  stFailure = "\e[33;1m"
  stSuite = "\e[34;1m"
  resetCode = "\e[0m"

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
    let
      suiteDir = curDir / params[i]
      suiteName = lastPathPart(params[i])
      suite = newElement("testsuite")

    setCurrentDir(suiteDir)
    createDir(binDir)

    var
      tests = 0
      failures = 0
      errors = 0

    echo &"{stSuite}[Suite]{resetCode} {suiteName}"

    for f in walkFiles("t*.nim"):
      let
        (testDir, testName, _) = splitFile(f)
        test = newElement("testcase")
        (co, cc) = execCmdEx(&"{nim} c --hints:off -w:off --outdir:{binDir} {f}")

      if cc != 0:
        echo &"  {stError}[ER]{resetCode} {testName}"
        test.attrs = {"name": testName, "time": "0.00000000"}.toXmlAttributes
        test.add(newXmlTree("failure", [], {"message": xmltree.escape(co)}.toXmlAttributes))
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
          echo &"  {stFailure}[FL]{resetCode} {testName}"
          test.add(newXmlTree("failure", [], {"message": xmltree.escape(ro)}.toXmlAttributes))
          inc(failures)
        else:
          echo &"  {stSuccess}[OK]{resetCode} {testName}"

      suite.add(test)
      inc(tests)

    suite.attrs = {"name": suiteName, "tests": $tests, "errors": $errors,
        "failures": $failures}.toXmlAttributes
    suites.add(suite)

    echo "----------------------------------------\n",
        &"  {stSuccess}[OK]{resetCode} {(tests - errors - failures):3}\n",
        &"  {stFailure}[FL]{resetCode} {failures:3}\n",
        &"  {stError}[ER]{resetCode} {errors:3}\n",
        "----------------------------------------\n"

  setCurrentDir(curDir)
  let report = newFileStream(params[0], fmWrite)
  if report == nil:
    quit("Failed to create output file: " & params[0])

  report.write($suites)
  close(report)

main()
