# Amazon Device Farm Runner
Deploys app to device farm and starts a test run with a preconfigured test package and device pool.

## Setup instructions
:warning: This step requires a fair amount of configuration in order to work properly.
[Please read the wiki for setup instructions](https://github.com/peartherapeutics/bitrise-aws-device-farm-runner/wiki).

## How to use this Step

Can be run directly with the [bitrise CLI](https://github.com/bitrise-io/bitrise),
just `git clone` this repository, `cd` into it's folder in your Terminal/Command Line
and call `bitrise run test`.

*Check the `bitrise.yml` file for required inputs which have to be
added to your `.bitrise.secrets.yml` file!*

Step by step:

1. Open up your Terminal / Command Line
2. `git clone` the repository
3. `cd` into the directory of the step (the one you just `git clone`d)
5. Create a `.bitrise.secrets.yml` file in the same directory of `bitrise.yml` - the `.bitrise.secrets.yml` is a git ignored file, you can store your secrets in
6. Check the `bitrise.yml` file for any secret you should set in `.bitrise.secrets.yml`
  * Best practice is to mark these options with something like `# define these in your .bitrise.secrets.yml`, in the `app:envs` section.
7. Once you have all the required secret parameters in your `.bitrise.secrets.yml` you can just run this step with the [bitrise CLI](https://github.com/bitrise-io/bitrise): `bitrise run test`

An example `.bitrise.secrets.yml` file:

```
---
# These environments should NOT be checked into source control, they are used
# to populate your tests when running this step locally.
envs:
 - AWS_ACCESS_KEY: ""
 - AWS_SECRET_KEY: ""
 - DEVICE_FARM_PROJECT: ""
 - TEST_PACKAGE_NAME: "test_bundle.zip"
 - TEST_TYPE: "APPIUM_PYTHON"
 - PLATFORM: "ios+android"
 - IOS_POOL: ""
 - ANDROID_POOL: ""
 - RUN_NAME_PREFIX: "testscript"
 - AWS_REGION: "us-west-2"
 - BITRISE_IPA_PATH: ""
 - BITRISE_SIGNED_APK_PATH: ""
 - BITRISE_BUILD_NUMBER: 0
```

## Testing
- `bitrise run test`
 - Note: This test requires additional configuration to pass:
     1. `AWS_ACCESS_KEY` and `AWS_SECRET_KEY` must be set in `.bitrise.secrets.yml`
     1. An Amazon device farm project must be set up in the target region, and its ARN must be specified in the `device_farm_project` input
     1. If `platform` input is...
       1. ... set to `ios`, then `ios_pool` must be set to the ARN of an iOS device pool and `ipa_path` or envvar `BITRISE_IPA_PATH` must be set
       1. ... set to `android`, then `android_pool` must be set to the ARN of an Android device pool and `apk_path` or envvar `BITRISE_SIGNED_APK_PATH` must be set
       1. ... set to `ios+android`, then all of the above inputs must be set
  - see `step.yml` for more info on obtaining ARNs

## How to create your own step

1. Create a new git repository for your step (**don't fork** the *step template*, create a *new* repository)
2. Copy the [step template](https://github.com/bitrise-steplib/step-template) files into your repository
3. Fill the `step.sh` with your functionality
4. Wire out your inputs to `step.yml` (`inputs` section)
5. Fill out the other parts of the `step.yml` too
6. Provide test values for the inputs in the `bitrise.yml`
7. Run your step with `bitrise run test` - if it works, you're ready

__For Step development guidelines & best practices__ check this documentation: [https://github.com/bitrise-io/bitrise/blob/master/_docs/step-development-guideline.md](https://github.com/bitrise-io/bitrise/blob/master/_docs/step-development-guideline.md).

**NOTE:**

If you want to use your step in your project's `bitrise.yml`:

1. git push the step into it's repository
2. reference it in your `bitrise.yml` with the `git::PUBLIC-GIT-CLONE-URL@BRANCH` step reference style:

```
- git::https://github.com/user/my-step.git@branch:
   title: My step
   inputs:
   - my_input_1: "my value 1"
   - my_input_2: "my value 2"
```

You can find more examples of step reference styles
in the [bitrise CLI repository](https://github.com/bitrise-io/bitrise/blob/master/_examples/tutorials/steps-and-workflows/bitrise.yml#L65).

## How to contribute to this Step

1. Fork this repository
2. `git clone` it
3. Create a branch you'll work on
4. To use/test the step just follow the **How to use this Step** section
5. Do the changes you want to
6. Run/test the step before sending your contribution
  * You can also test the step in your `bitrise` project, either on your Mac or on [bitrise.io](https://www.bitrise.io)
  * You just have to replace the step ID in your project's `bitrise.yml` with either a relative path, or with a git URL format
  * (relative) path format: instead of `- original-step-id:` use `- path::./relative/path/of/script/on/your/Mac:`
  * direct git URL format: instead of `- original-step-id:` use `- git::https://github.com/user/step.git@branch:`
  * You can find more example of alternative step referencing at: https://github.com/bitrise-io/bitrise/blob/master/_examples/tutorials/steps-and-workflows/bitrise.yml
7. Once you're done just commit your changes & create a Pull Request


## Share your own Step

You can share your Step or step version with the [bitrise CLI](https://github.com/bitrise-io/bitrise). Just run `bitrise share` and follow the guide it prints.
