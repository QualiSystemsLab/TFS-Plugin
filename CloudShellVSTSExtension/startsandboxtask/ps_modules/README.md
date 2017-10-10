
For each of the tasks, you must download the VstsTaskSdk library to bundle it in the task packages:

    Save-Module -Name VstsTaskSdk -Path .\

Under each task, create a `ps_module` folder and copy `VstsTaskSdk` *excluding the folder like 0.10.0* so that these paths exist:

- `StartCloudShellSandbox\ps_module\VstsTaskSdk\`
- `EndCloudShellSandbox\ps_module\VstsTaskSdk\`
- `RunCloudShellCommand\ps_module\VstsTaskSdk\`

In `VstsTaskSdk` you should see multiple files including `VstsTaskSdk.psd1`.
