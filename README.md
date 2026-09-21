# HOB Markdown

Markdown is cool, but unless you are always in VSC then how to do you read markdown files? How do you edit them, esepecially if they are not related to a software engineering project? That's why I started this project...oh and its free to use so you can save some cash for beer instead.

## Getting Started

This project is primarily optimized for use on macOS desktop because that is where I primarily use markdown files. The other platforms (android, iOS, etc.) will work, but this will not be optimized for them.

If you want to try this out, it is pretty easy. You'll need to have the XCode and Flutter tool chains installed and functioning properly. Basically that means a "flutter doctor" will come back with an all good.

When you have that, grab the code, go to the project root and start it up with "flutter run -d macos" and it should start up. The first startup will be a little slow as it gets dependencies and such downloaded. 

To build a clean non debug release that can be dropped in your applications folder on macOS run this command: 

flutter build macos --release

The release will be quite a bit smaller. It is configured to be a an option on the macOS menus to auto-open Markdown files if you like. 

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
