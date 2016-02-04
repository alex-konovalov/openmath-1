#############################################################################
##
##  OPENMATHBuildManual()
##
OPENMATHBuildManual:=function()
local path, main, files, bookname;
path:=Concatenation(
               GAPInfo.PackagesInfo.("openmath")[1].InstallationPath,"/doc/");
main:="manual.xml";
files:=[];
bookname:="openmath";
MakeGAPDocDoc( path, main, files, bookname );  
end;


#############################################################################
##
##  OPENMATHBuildManualHTML()
##
OPENMATHBuildManualHTML:=function()
local path, main, files, str, r, h;
path:=Concatenation(
               GAPInfo.PackagesInfo.("openmath")[1].InstallationPath,"/doc/");
main:="manual.xml";
files:=[];
str:=ComposedXMLString( path, main, files );
r:=ParseTreeXMLString( str );
CheckAndCleanGapDocTree( r );
h:=GAPDoc2HTML( r, path );
GAPDoc2HTMLPrintHTMLFiles( h, path );
end;


#############################################################################
##
#E
##