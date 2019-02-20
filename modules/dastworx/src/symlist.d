module symlist;

import
    std.stdio, std.array, std.traits, std.conv, std.json, std.format,
    std.algorithm;
import
    iz.memory: construct;
import
    iz.containers : Array;
import
    dparse.lexer, dparse.ast, dparse.parser, dparse.formatter : Formatter;
import
    common;

/**
 * Serializes the symbols in the standard output
 */
JSONValue listSymbols(const(Module) mod, AstErrors errors, bool deep = true)
{
    mixin(logCall);
  
    
    SymbolListBuilder sl = new SymbolListBuilder();  
    sl.addAstErrors(errors);
    sl.visit(mod);
    sl.serialize.writeln;    
    return sl.json;
    
}

private:

enum ListFmt
{
    Pas,
    Json
}

enum SymbolType
{
    _alias,
    _class,
    _enum,
    _error,
    _function,
    _interface,
    _import,
    _mixin, // (template decl)
    _struct,
    _template,
    _union,
    _unittest,
    _variable,
    _warning
}

string makeSymbolTypeArray()
{
    string result = "string[SymbolType.max + 1] symbolTypeStrings = [";
    foreach(st; EnumMembers!SymbolType)
        result ~= `"` ~ to!string(st) ~ `",`;
    result ~= "];";
    return result;
}

mixin(makeSymbolTypeArray);

class SymbolListBuilder: ASTVisitor
{
    private  bool _deep=true;
        JSONValue json;
         JSONValue* jarray;
     

    static Array!(char) funcNameApp;
    static Formatter!(typeof(&funcNameApp)) fmtVisitor;
    static uint utc;

    

    alias visit = ASTVisitor.visit;

     this()
    {
      
        
            this.json = parseJSON("[]");
            
            this.jarray = &json;
        
        fmtVisitor = construct!(typeof(fmtVisitor))(&funcNameApp);
    }

     void addAstErrors(AstErrors errors)
    {
        foreach(error; errors)
        {
            string type = (error.type == ErrorType.error) ?
                symbolTypeStrings[SymbolType._error] :
                symbolTypeStrings[SymbolType._warning];
            
            
                JSONValue item = parseJSON("{}");
                item["line"] = JSONValue(error.line);
                item["col"]  = JSONValue(error.column);
                item["name"] = JSONValue(error.message);
                item["type"] = JSONValue(type);
                this.jarray.array ~= item;
            
        }
    }

    final string serialize()
    {
        
        {
            JSONValue result = parseJSON("{}");
            result["items"] = json;
          //  version (assert)
                return result.toPrettyString;
        //    else
          //      return result.toString;
        }
    }

    /// visitor implementation if the declaration has a "name".
    final void namedVisitorImpl(DT, SymbolType st, bool dig = true)(const(DT) dt)
//    if (__traits(hasMember, DT, "name"))
    {
         
        
        {
            JSONValue item = parseJSON("{}");
            item["line"] = JSONValue(dt.name.line);
            item["col"]  = JSONValue(dt.name.column);
            static if (is(DT == FunctionDeclaration))
            {
                if (dt.parameters && dt.parameters.parameters &&
                    dt.parameters.parameters.length)
                {
                    import dparse.formatter : fmtNode = format;
                    funcNameApp.length = 0;
                    fmtVisitor.format(dt.parameters);
                    //MASSIMO app.
                    item["name"] = JSONValue(dt.name.text ~ funcNameApp[]);
                }
                else item["name"] = JSONValue(dt.name.text);
            }
            else
            {
                item["name"] = JSONValue(dt.name.text);
            }
            item["type"] = JSONValue(symbolTypeStrings[st]);
            static if (dig) if (_deep)
            {
                JSONValue subs = parseJSON("[]");
                const JSONValue* old = jarray;
                jarray = &subs;
                writeln("************************PRIMA-INNER");
                dt.accept(this);
                       writeln("************************DOPO_INNER",subs.toPrettyString);
                item["items"] = subs;
                jarray = cast(JSONValue*)old;
            }
            jarray.array ~= item;
        }
    }

    /// visitor implementation for special cases.
    final void otherVisitorImpl(DT, bool dig = true)
        (const(DT) dt, SymbolType st, string name, size_t line, size_t col)
    {
       
        {
            JSONValue item = parseJSON("{}");
            item["line"] = JSONValue(line);
            item["col"]  = JSONValue(col);
            item["name"] = JSONValue(name);
            item["type"] = JSONValue(symbolTypeStrings[st]);
            static if (dig)
            {
                JSONValue subs = parseJSON("[]");
                const JSONValue* old = jarray;
                jarray = &subs;
                 writeln("************************PRIMA2-INNER");
                dt.accept(this);
                item["items"] = subs;
                 writeln("************************DOPO2-INNER");
                jarray = cast(JSONValue*)old;
            }
            jarray.array ~= item;
        }
    }

    final override void visit(const AliasDeclaration decl)
    {
        if (decl.initializers.length)
            namedVisitorImpl!(AliasInitializer, SymbolType._alias)(decl.initializers[0]);
    }

    final override void visit(const AnonymousEnumMember decl)
    {
        namedVisitorImpl!(AnonymousEnumMember, SymbolType._enum)(decl);
    }

    final override void visit(const AnonymousEnumDeclaration decl)
    {
        decl.accept(this);
    }

    final override void visit(const AutoDeclarationPart decl)
    {
        otherVisitorImpl(decl, SymbolType._variable, decl.identifier.text,
            decl.identifier.line, decl.identifier.column);
    }

    final override void visit(const ClassDeclaration decl)
    {writeln("************************CLASS-PRIMA");
        namedVisitorImpl!(ClassDeclaration, SymbolType._class)(decl);
        writeln("************************CLASS-DOPO");
    }

    final override void visit(const Constructor decl)
    {
        otherVisitorImpl(decl, SymbolType._function, "ctor", decl.line, decl.column);
    }

    final override void visit(const Destructor decl)
    {
        otherVisitorImpl(decl, SymbolType._function, "dtor", decl.line, decl.column);
    }

    final override void visit(const EnumDeclaration decl)
    {
        namedVisitorImpl!(EnumDeclaration, SymbolType._enum)(decl);
    }

    final override void visit(const EponymousTemplateDeclaration decl)
    {
        namedVisitorImpl!(EponymousTemplateDeclaration, SymbolType._template)(decl);
    }

    final override void visit(const FunctionDeclaration decl)
    {writeln("************************FUNCTION-PRIMA");
        namedVisitorImpl!(FunctionDeclaration, SymbolType._function)(decl);
        writeln("************************FUNCTION-DOPO");
    }

    final override void visit(const InterfaceDeclaration decl)
    {writeln("************************InterfaceDeclaration-PRIMA");
        namedVisitorImpl!(InterfaceDeclaration, SymbolType._interface)(decl);
    }

    final override void visit(const ImportDeclaration decl)
    {writeln("************************import-PRIMA");
        foreach (const(SingleImport) si; decl.singleImports)
        {
            if (!si.identifierChain.identifiers.length)
                continue;

            otherVisitorImpl(decl, SymbolType._import,
                si.identifierChain.identifiers.map!(a => a.text).join("."),
                si.identifierChain.identifiers[0].line,
                si.identifierChain.identifiers[0].column);
        }
        if (decl.importBindings) with (decl.importBindings.singleImport)
            otherVisitorImpl(decl, SymbolType._import,
                identifierChain.identifiers.map!(a => a.text).join("."),
                identifierChain.identifiers[0].line,
                identifierChain.identifiers[0].column);
    }

    final override void visit(const Invariant decl)
    {writeln("************************invariant-PRIMA");
        otherVisitorImpl(decl, SymbolType._function, "invariant", decl.line, 0);
    }

    final override void visit(const MixinTemplateDeclaration decl)
    {
        writeln("************************mixin-PRIMA");
        namedVisitorImpl!(TemplateDeclaration, SymbolType._mixin)(decl.templateDeclaration);
    }

    final override void visit(const Postblit pb)
    {writeln("************************postblit-PRIMA");
        otherVisitorImpl(pb, SymbolType._function, "postblit", pb.line, pb.column);
        pb.accept(this);
    }

    final override void visit(const StructDeclaration decl)
    {writeln("************************struct-PRIMA");
        namedVisitorImpl!(StructDeclaration, SymbolType._struct)(decl);
    }

    final override void visit(const TemplateDeclaration decl)
    {writeln("************************template-PRIMA");
        namedVisitorImpl!(TemplateDeclaration, SymbolType._template)(decl);
    }

    final override void visit(const UnionDeclaration decl)
    {writeln("************************union-PRIMA");
        namedVisitorImpl!(UnionDeclaration, SymbolType._union)(decl);
    }

    final override void visit(const Unittest decl)
    {writeln("************************unittest-PRIMA");
        otherVisitorImpl(decl, SymbolType._unittest, format("test%.4d",utc++),
            decl.line, decl.column);
    }

    final override void visit(const VariableDeclaration decl)
    {writeln("************************variable-PRIMA");
        if (decl.declarators)
            foreach (elem; decl.declarators)
                namedVisitorImpl!(Declarator, SymbolType._variable, false)(elem);
        else if (decl.autoDeclaration)
            visit(decl.autoDeclaration);
    }

    final override void visit(const StaticConstructor decl)
    {writeln("************************static-cons-PRIMA");
        otherVisitorImpl(decl, SymbolType._function, "static ctor", decl.line, decl.column);
    }

    final override void visit(const StaticDestructor decl)
    {writeln("************************static-desc-PRIMA");
        otherVisitorImpl(decl, SymbolType._function, "static dtor", decl.line, decl.column);
    }

    final override void visit(const SharedStaticConstructor decl)
    {writeln("************************shared-static-con-PRIMA");
        otherVisitorImpl(decl, SymbolType._function, "shared static ctor", decl.line, decl.column);
    }

    final override void visit(const SharedStaticDestructor decl)
    {writeln("************************shared-static-des-PRIMA");
        otherVisitorImpl(decl, SymbolType._function, "shared static dtor", decl.line, decl.column);
    }
}

