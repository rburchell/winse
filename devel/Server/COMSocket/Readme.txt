-- IMPORTANT! READ THIS BEFORE ATTEMPTING TO USE WINSE! --

COMSocket will need to be compiled on your system prior to use.
To compile it, you can use:
- Microsoft .NET SDK
- Microsoft Visual Basic .NET
- Microsoft Visual Studio .NET

For the Visual Basic and Visual Studio users, simply open .sln, then choose
Build Solution. The project will compiled and registered, and is now usable.

To compile with the .NET SDK, you will first need to invoke the Visual
Basic .NET Compiler.

Remove all line breaks and copy this line to a .NET SDK Command Prompt:
vbc.exe /nologo /out:bin\COMSocket.dll /reference:Microsoft.VisualBasic.dll
/imports:Microsoft.VisualBasic /imports:System /imports:System.Collections
/imports:System.Data /imports:System.Diagnostics /debug /optionexplicit+
/optionstrict- /optioncompare:binary /define:DEBUG=1 /define:TRACE=1
/rootnamespace:COMSocket TCPSocket.vb AssemblyInfo.vb

Once that is done, cd into bin where you will find COMSocket.dll, then run
this command:
regasm.exe /tlb COMSocket.dll
This will register COMSocket.dll for COM and generate a .tlb that you can play
with if you want.