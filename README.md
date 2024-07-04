# Renoise Livereload

This is a [Renoise tool](https://www.renoise.com/tools) for live reloading other tools under development.

## Usage

Once the tool is installed a new `LiveReload` menu is available under `Tools`. 
<img width="311" alt="Screenshot 2024-07-04 at 8 50 41" src="https://github.com/matt-allan/renoise-livereload/assets/4966687/38418ddc-bd77-4752-93f5-f76b47fb17c6">

From there you can choose a folder containing your tool's source code. The folder must contain a `manifest.xml` with the tool `Id` set.

After choosing your tool's folder the build dialog is shown. From here you can set the build command, toggle watch mode, and view the build log.
<img width="458" alt="Screenshot 2024-07-04 at 8 51 26" src="https://github.com/matt-allan/renoise-livereload/assets/4966687/5d23e8b7-7e12-4979-b9ab-76c4598d6993">

A default build command is detected for you if possible. The build command will be executed verbatim using the shell so please be careful! You can easily do something dangerous like zipping up your entire hard drive.

With watch mode enabled each time you tab back to renoise, the tool will be rebuilt. If the `xrnx` has changed it will be re-installed without prompting. You can also manually trigger a build with the "Build" button.

Building your tool with `make` will provide the best user experience. To get started you can copy [this tool's Makefile](./Makefile). Make will only build a new `xrnx` if the source files have changed, which means the tool will only be re-installed if necessary.
