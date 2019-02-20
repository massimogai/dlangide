module dlangide.ui.outlinepanel;

import std.string, std.json;
import dlangui;
import dlangide.workspace.workspace;
import dlangide.workspace.project;
import dlangide.ui.commands;
import imports;
import dastworx;
import std.stdio;

enum ModuleItemType : int
{
    Class,
    Interface,
    Enum,

}

interface OutlineItemSelectionHandler
{
    void onOutlineItemSelected(ulong line);
}

class OutlineItemData
{
    ulong line;
    this(JSONValue value)
    {
        JSONValue line_value = value["line"];
        this.line = line_value.uinteger;
    }

    this(ulong value)
    {

        this.line = value;
    }

}

class OutlinePanel : DockWindow
{

    protected TreeWidget _tree;
    Signal!OutlineItemSelectionHandler outlineItemSelectionListener;
    /// handle source file selection change

    this(string id)
    {
        super(id);
        _caption.text = "Module Outline Explorer"d;
    }

    public void reset()
    { _tree.selectionChange.disconnect(&onTreeItemSelected);
        _tree.items.clear();
         _tree.selectionChange = &onTreeItemSelected;
    }

    public void update(ProjectSourceFile file)
    { writeln("--------Prima Reset ");
        reset();
        writeln("--------Dopo Reset ");
        SymbolResult result;
        Launcher.handleSymListOption(file.filename, result);

        JSONValue json = result.json;
        string moduleName = result.moduleName;

        TreeItem mainFolder = _tree.items.newChild("mainFolder",
                to!dstring(moduleName), "symbol-module");

        mainFolder.objectParam = new OutlineItemData(0);
        JSONValue[] items = json.array();
        foreach (JSONValue item; items)
        {
            processRecursiveJson(item, mainFolder, 1);
        }
writeln("TREEE ",_tree);
writeln("mainFolder ",mainFolder.id);
        _tree.selectItem(mainFolder);
       
    }

    private void processRecursiveJson(JSONValue json, TreeItem treeItem, int level)
    {
        dstring name = to!dstring(json["name"].str);
        string type = json["type"].str;
        string iconType;
        TreeItem newItem;
        bool add = false;
        switch (type)
        {
        case "_function":
            iconType = "symbol-function";
            add = true;
            break;
        case "_variable":
            iconType = "symbol-var";
            add = true;
            break;
        case "_import":
            iconType = "symbol-other";
            break;
        case "_class":
            iconType = "symbol-class";
            add = true;
            break;

        default:
            iconType = "folder";
        }

        if (add)
        {
            if (name == "ctor")
            {
                name = "Constructor";
            }
            else if (name == "dtor")
            {
                name = "Destructor";
            }

            newItem = treeItem.newChild(to!string(name), name, iconType);
            if (level > 2)
            {
                treeItem.collapse();
             
            }
            newItem.objectParam = new OutlineItemData(json);
        }
        else
        {
            newItem = treeItem;
        }

        if ("items" in json)
        {
            JSONValue[] items = json["items"].array;
            foreach (JSONValue item; items)
            {
                processRecursiveJson(item, newItem, level + 1);
            }
        }
    }

    void onTreeItemSelected(TreeItems source, TreeItem selectedItem, bool activated)
    {

        if (outlineItemSelectionListener.assigned)
        {
            OutlineItemData data = cast(OutlineItemData) selectedItem.objectParam;

            outlineItemSelectionListener(data.line - 1);

        }
    }

    // activate workspace panel if hidden
    void activate()
    {
        if (visibility == Visibility.Gone)
        {
            visibility = Visibility.Visible;
            parent.layout(parent.pos);
        }
        setFocus();
    }

    override protected Widget createBodyWidget()
    {

        _tree = new TreeWidget("wstree", ScrollBarMode.Auto, ScrollBarMode.Auto);
        _tree.layoutHeight(FILL_PARENT).layoutHeight(FILL_PARENT);
        _tree.selectionChange = &onTreeItemSelected;
        _tree.fontSize = 16;
               // _tree.noCollapseForSingleTopLevelItem = true;
        return _tree;
    }

}

