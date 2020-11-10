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

  let suites = newElement("testsuites")

  for i in 1 ..< params.len:
    let suiteDir = getCurrentDir() / params[i]
    stdout.write suiteDir, "\n"
    setCurrentDir(suiteDir)
    createDir("bin")

    let
      suiteName = lastPathPart(params[i])
      suite = newElement("testsuite")
    var
      tests = 0
      failures = 0
      errors = 0

    stdout.write &"{stSuite}[Suite]{resetCode} {suiteName}\n"

    for f in walkFiles("t*.nim"):
      let
        (testDir, testName, _) = splitFile(f)
        test = newElement("testcase")
        (co, cc) = execCmdEx("nim c --hints:off -w:off --outdir:bin " & f)

      if cc != 0:
        stdout.write &"  {stError}[ER]{resetCode} {testName}\n"
        test.attrs = {"name": testName, "time": "0.00000000"}.toXmlAttributes
        test.add(newXmlTree("failure", [], {"message": co}.toXmlAttributes))
        inc(errors)
      else:
        let
          exe = testDir / "bin" / testName
          startTime = epochTime()
          (ro, rc) = execCmdEx(exe)
          duration = epochTime() - startTime

        test.attrs = {"name": testName,
            "time": formatFloat(duration, ffDecimal, 8)}.toXmlAttributes
        if rc != 0:
          stdout.write &"  {stFailure}[FL]{resetCode} {testName}\n"
          test.add(newXmlTree("failure", [], {"message": ro}.toXmlAttributes))
          inc(failures)
        else:
          stdout.write &"  {stSuccess}[OK]{resetCode} {testName}\n"

      suite.add(test)
      inc(tests)

    suite.attrs = {"name": suiteName, "tests": $tests, "errors": $errors,
        "failures": $failures}.toXmlAttributes
    suites.add(suite)

    stdout.write "----------------------------------------\n",
        &"  {stSuccess}[OK]{resetCode} {(tests - errors - failures):3}\n",
        &"  {stFailure}[FL]{resetCode} {failures:3}\n",
        &"  {stError}[ER]{resetCode} {errors:3}\n",
        "----------------------------------------\n"

  let report = newFileStream(params[0], fmWrite)
  if report == nil:
    quit("Failed to create output file: " & params[0])

  report.write($suites)
  close(report)

main()
