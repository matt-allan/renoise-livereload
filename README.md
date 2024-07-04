# Renoise Livereload

This is a [Renoise tool](https://www.renoise.com/tools) for live reloading other tools under development.

## Usage

Once the tool is installed a new `LiveReload` menu is available under `Tools`. From there you can choose a folder containing your tool's source code. The folder must contain a `manifest.xml` with the tool `Id` set.

After choosing your tool's folder the build dialog is shown. From here you can set the build command, toggle watch mode, and view the build log.

A default build command is detected for you if possible. The build command will be executed verbatim using the shell so please be careful! You can easily do something dangerous like zipping up your entire hard drive.

With watch mode enabled each time you tab back to renoise, the tool will be rebuilt. If the `xrnx` has changed it will be re-installed without prompting. You can also manually trigger a build with the "Build" button.

Building your tool with `make` will provide the best user experience. To get started you can copy [this tool's Makefile](./Makefile). Make will only build a new `xrnx` if the source files have changed, which means the tool will only be re-installed if necessary.