module app;

import dlangui.all;
import std.stdio;
import std.conv;
import dlangide.ui.frame;
import dlangide.ui.commands;
import dlangide.workspace.workspace;


mixin APP_ENTRY_POINT;

/// entry point for dlangui based application
extern (C) int UIAppMain(string[] args) {
    // resource directory search paths
    string[] resourceDirs = [
		appendPath(exePath, "res/"), // when res dir is located at the same directory as executable
		appendPath(exePath, "../res/"), // when res dir is located at project directory
		appendPath(exePath, "../../res/"), // when res dir is located at the same directory as executable
		appendPath(exePath, "res/mdpi/"), // when res dir is located at the same directory as executable
		appendPath(exePath, "../res/mdpi/"), // when res dir is located at project directory
		appendPath(exePath, "../../res/mdpi/"), // when res dir is located at the same directory as executable
        appendPath(exePath, "res/stdres/"), // when res dir is located at the same directory as executable
		appendPath(exePath, "../res/stdres/"), // when res dir is located at project directory
		appendPath(exePath, "../../res/stdres/"), // when res dir is located at the same directory as executable
		appendPath(exePath, "res/stdres/mdpi/"), // when res dir is located at the same directory as executable
		appendPath(exePath, "../res/stdres/mdpi/"), // when res dir is located at project directory
		appendPath(exePath, "../../res/stdres/mdpi/") // when res dir is located at the same directory as executable
	];

    // setup resource directories - will use only existing directories
	Platform.instance.resourceDirs = resourceDirs;
    // select translation file - for english language
	Platform.instance.uiLanguage = "en";
	// load theme from file "theme_default.xml"
	Platform.instance.uiTheme = "theme_default";

    // you can override default hinting mode here
    FontManager.instance.hintingMode = HintingMode.Normal;
    // you can override antialiasing setting here
    FontManager.instance.minAnitialiasedFontSize = 0;

    // create window
    Window window = Platform.instance.createWindow("Dlang IDE", null);
	
    IDEFrame frame = new IDEFrame(window);

    // create some widget to show in window
    window.windowIcon = drawableCache.getImage("dlangui-logo1");

    frame.loadWorkspace(appendPath(exePath, "../workspaces/sample1/sample1.dlangidews"));

    // show window
    window.show();

    // run message loop
    return Platform.instance.enterMessageLoop();
}