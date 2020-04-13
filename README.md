# IoT DSL
DSL for easy sensor access as well as communication between devices.

## When cloning the repo
When the repository in cloned, the projects should be imported to eclipse.
Start by running the .mwe2 workflow by rightclicking on the file: `sdu.mdsd.iot/src/sdu/mdsd/GenerateIoT.mwe2` and press run. This results in folders being generated together with the classes and interfaces used by the model.
When the workflow is run, a few errors might occur due to missing folders in dir `sdu.mdsd.iot.ui.tests`. This can simply be fixed by creating the missing folders. E.g. `mkdir sdu.mdsd.iot.ui.tests/xtend-gen`
