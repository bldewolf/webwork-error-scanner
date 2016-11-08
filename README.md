# webwork-error-scanner

When Webwork renders problems, the warnings and errors go to the Apache logs.
It quickly becomes tedious to attempt to trace these messages back to their sources.
Instead, it would be simpler to render the images outside of the web server and observe the messages there.

This script is the result of probing the barrier between Webwork and PG to determine the bare minimum PG needs to function.
It reads in a list of problem files and creates an output directory containing a log file per problem.

Checking every problem in webwork-open-problem-library only takes 1-2 hours on a regular desktop machine.
