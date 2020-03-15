# testify [WIP]
Compile-Run-Report helper for Nim

This project was born out of the need of an external tool that produces a report out of multiple Nim modules/files.
It does not provide any debugging info like stdlib's unittest module. Instead, it is a simple tool that works as follows:
  1. the first command line argument is the path of the JUnit report to be generated
  2. each command line argument that follows must be a directory and corresponds to one JUnit testsuite
  3. each Nim module in the directory corresponds to one JUnit testcase
  4. a single JUnit report is printed in stdout which reports for each module:
    - whether it compiled successfully or not
    - whether it executed successfully or not (in case of failure the error message is logged)
