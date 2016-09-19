# Amazon Device Farm Runner
Deploys app to device farm and starts a test run with a preconfigured test package and device pool.

This Step requires an Amazon Device Farm registration. To register an account, [click here](https://aws.amazon.com/device-farm/)

Can be run directly with the [bitrise CLI](https://github.com/bitrise-io/bitrise),
just `git clone` this repository, `cd` into it's folder in your Terminal/Command Line
and call `bitrise run test`.

*Check the `bitrise.yml` file for required inputs which have to be
added to your `.bitrise.secrets.yml` file!*