# HOB Markdown

Markdown is cool, but unless you are always in Visual Studio Code (VSC) then how do you read and edit markdown files? Especially if they are not related to a software engineering project. Today I am using .md files outside of software engineering projects all the time - for example for creative writing and interacting with AI solutions. That's why I started this project...oh and its free to use so you can save some cash for beer instead.

I created and edited this file in the HOB Markdown app!! 

## Getting Started

This project is primarily optimized for use on macOS desktop because that is where I primarily use markdown files. The other platforms (Linux, android, iOS, Windows, etc.) will work, but this will not be optimized for them.

If you want to try this out, it is pretty easy. You'll need to have the XCode and Flutter tool chains installed and functioning properly. Basically that means a "flutter doctor" will come back with an all good.

When you have that, grab the code, go to the project root and start it up with "flutter run -d macos" and it should start up. The first startup will be a little slow as it gets dependencies and such downloaded. 

If you open an .md file in HOB Markdown that is not UTF-8, it will be converted to UTF-8, which normally should not cause any issues, but just be aware of this. 

Printing of most charaters, emojis, and things like this are supported by HOB Markdown, but it is possible that some icons or emoji's are not in the fonts that are included in HOB Markdown. This is simnply a size thing - to kepp the app small and not bloat it up with too many fonts. If you find something that doesn't print, it is likely not a bug in the app, but rather an issue with the fonts. 

## Using HOB Markdown

HOB Markdown works just like many editors. Open it from the Applications folder and you get some default content that also helps newbies with the basics of Markdown syntax. File New on the menu will clear that out. Or drag and drop an .md file into the window. 

Right click on an existing .md file and select "Open With" and then select HOB Markdown and it will load that right up. Or you can drag and drop an .md file into the current window and it will replace the document in the same window.  

There is help available from the Help menu for those not familiar with Markdown's markup tags. There are a bunch of chortcut keystrokes that you can learn about in the help menu for macOS. 

## Doing a Full Build

At this point I don't plan to put this in the app store because I don't feel the need to spend $99 on renewing my Apple developer account. The macOS client is fully configured so that you can build it locally and then drop it into your Applications folder and it will work just like something from the AppStore. 

This will not allow you to distribute it to other folks or they will get the gatekeeper warnings and such. Building this locally allows you to run this on your own computer with no warnings. 

Obviosuly you will need to have XCode installed along with the command line tools and also have the Flutter SDK installed and configured properly (flutter doctor returns no errors).

To run a code analysis on the project use this command: 

flutter analyze

To run the full set of tests use this command: 

flutter test

Keep in mind when you run the tests, there are "negative tests" included that will output errors to the console. This is normal operation for those tests. An example is a test attempting to save a file that does not exist. 

To build a clean non-debug release that can be dropped in your applications folder, download the code and then on macOS run this command: 

flutter build macos --release

The release will be quite a bit smaller than a debug release - should be around 36MB in size. It is configured to be a an option on the macOS menus to auto-open Markdown files. You can set it as the default if you like. 

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
