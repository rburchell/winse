' Winse - WINdows SErvices. IRC services for Windows.
' Copyright (C) 2004 The Winse Team [http://www.sourceforge.net/projects/winse]
'
' This program is free software; you can redistribute it and/or modify
' it under the terms of the GNU General Public License as published by
' the Free Software Foundation; either version 2 of the License, or
' (at your option) any later version.
'
' This program is distributed in the hope that it will be useful,
' but WITHOUT ANY WARRANTY; without even the implied warranty of
' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
' GNU General Public License for more details.
'
' You should have received a copy of the GNU General Public License
' along with this program; if not, write to the Free Software
' Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
Option Explicit On 
Option Strict On
Option Compare Binary
Imports Microsoft.VisualBasic
Imports System
Imports System.Collections
Imports System.Collections.Specialized
'The describes the procedure that is called when the associated Service Client receives a PRIVMSG. For a service
'it should invoke the API.ExecCommand method to use the command hash. Note that this procedure MUST NOT do this
'if TypeOf Source Is Server (eg, the sender is a server, not a user). Though since servers almost never send a PRIVMSG
'anyway...
Public Delegate Sub ServiceMain(ByVal Source As IRCNode, ByVal Message As String)
'This describes the procedure that is called for a command executed through API.ExecCommand.
'(Server messages don't go through API.ExecCommand.)
Public Delegate Function CommandFunc(ByVal Source As User, ByVal Cmd As String, ByVal Args() As String) As Boolean
'This is a command list - essentially a collection of CommandFunc objects.
Public NotInheritable Class CommandList
	Implements IList, ICollection, IEnumerable
	ReadOnly a As ArrayList
	Public Sub New()
		a = New ArrayList
	End Sub
	Public Sub New(ByVal ParamArray Cmds() As CommandFunc)
		a = New ArrayList(Cmds)
	End Sub
	Public Sub CopyTo(ByVal array As System.Array, ByVal index As Integer) Implements System.Collections.ICollection.CopyTo
		a.CopyTo(array, index)
	End Sub
	Public ReadOnly Property Count() As Integer Implements System.Collections.ICollection.Count
		Get
			Return a.Count()
		End Get
	End Property
	Public ReadOnly Property IsSynchronized() As Boolean Implements System.Collections.ICollection.IsSynchronized
		Get
			Return False
		End Get
	End Property
	Public ReadOnly Property SyncRoot() As Object Implements System.Collections.ICollection.SyncRoot
		Get
			Return Me
		End Get
	End Property
	Public Function GetEnumerator() As System.Collections.IEnumerator Implements System.Collections.IEnumerable.GetEnumerator
		Return a.GetEnumerator
	End Function
	Private Function Add2(ByVal value As Object) As Integer Implements System.Collections.IList.Add
		Return Add(DirectCast(value, CommandFunc))
	End Function
	Public Function Add(ByVal value As CommandFunc) As Integer
		Return a.Add(value)
	End Function
	Public Sub Clear() Implements System.Collections.IList.Clear
		a.Clear()
	End Sub
	Private Function Contains2(ByVal value As Object) As Boolean Implements System.Collections.IList.Contains
		Return Contains(DirectCast(value, CommandFunc))
	End Function
	Public Function Contains(ByVal value As CommandFunc) As Boolean
		Return a.Contains(value)
	End Function
	Private Function IndexOf2(ByVal value As Object) As Integer Implements System.Collections.IList.IndexOf
		Return IndexOf(DirectCast(a, CommandFunc))
	End Function
	Public Function IndexOf(ByVal value As CommandFunc) As Integer
		Return a.IndexOf(value)
	End Function
	Private Sub Insert2(ByVal index As Integer, ByVal value As Object) Implements System.Collections.IList.Insert
		Insert(index, DirectCast(value, CommandFunc))
	End Sub
	Public Sub Insert(ByVal index As Integer, ByVal value As CommandFunc)
		a.Insert(index, value)
	End Sub
	Public ReadOnly Property IsFixedSize() As Boolean Implements System.Collections.IList.IsFixedSize
		Get
			Return False
		End Get
	End Property
	Public ReadOnly Property IsReadOnly() As Boolean Implements System.Collections.IList.IsReadOnly
		Get
			Return False
		End Get
	End Property
	Private Property Item2(ByVal index As Integer) As Object Implements System.Collections.IList.Item
		Get
			Return Item(index)
		End Get
		Set(ByVal Value As Object)
			Item(index) = DirectCast(Value, CommandFunc)
		End Set
	End Property
	Default Public Property Item(ByVal index As Integer) As CommandFunc
		Get
			Return DirectCast(a(index), CommandFunc)
		End Get
		Set(ByVal Value As CommandFunc)
			a(index) = Value
		End Set
	End Property
	Private Sub Remove2(ByVal value As Object) Implements System.Collections.IList.Remove
		Remove(DirectCast(value, CommandFunc))
	End Sub
	Public Sub Remove(ByVal value As CommandFunc)
		a.Remove(value)
	End Sub
	Public Sub RemoveAt(ByVal index As Integer) Implements System.Collections.IList.RemoveAt
		a.RemoveAt(index)
	End Sub
End Class
'This is a command hash...
Public NotInheritable Class CommandHash
	Implements IDictionary
	ReadOnly a As New Hashtable
	Public Sub CopyTo(ByVal array As System.Array, ByVal index As Integer) Implements System.Collections.ICollection.CopyTo
		a.CopyTo(array, index)
	End Sub
	Public ReadOnly Property Count() As Integer Implements System.Collections.ICollection.Count
		Get
			Return a.Count
		End Get
	End Property
	Public ReadOnly Property IsSynchronized() As Boolean Implements System.Collections.ICollection.IsSynchronized
		Get
			Return False
		End Get
	End Property
	Public ReadOnly Property SyncRoot() As Object Implements System.Collections.ICollection.SyncRoot
		Get
			Return Me
		End Get
	End Property
	Private Sub Add2(ByVal key As Object, ByVal value As Object) Implements System.Collections.IDictionary.Add
		If TypeOf value Is CommandFunc Then
			Add(DirectCast(key, String), DirectCast(value, CommandFunc))
		ElseIf TypeOf value Is CommandList Then
			Add(DirectCast(key, String), DirectCast(value, CommandList))
		Else
			Throw New InvalidOperationException("Cannot resolve overload.")
		End If
	End Sub
	Public Overloads Sub Add(ByVal key As String, ByVal value As CommandList)
		a.Add(key, value)
	End Sub
	Public Overloads Function Add(ByVal cmd As String, ByVal cmdfunc As CommandFunc, Optional ByVal InsertAt As Integer = -1) As Integer
		If a.Contains(cmd) Then
			If InsertAt < 0 OrElse InsertAt >= DirectCast(a(cmd), CommandList).Count Then
				Return DirectCast(a(cmd), CommandList).Add(cmdfunc)
			Else
				DirectCast(a(cmd), CommandList).Insert(InsertAt, cmdfunc)
				Return InsertAt
			End If
		Else
			Add(cmd, New CommandList(cmdfunc))
			Return 0
		End If
	End Function
	Public Sub Clear() Implements System.Collections.IDictionary.Clear
		a.Clear()
	End Sub
	Private Function Contains2(ByVal key As Object) As Boolean Implements System.Collections.IDictionary.Contains
		If TypeOf key Is CommandFunc Then
			Return Contains(DirectCast(key, CommandFunc))
		ElseIf TypeOf key Is String Then
			Return Contains(DirectCast(key, String))
		Else
			Throw New InvalidOperationException("Cannot resolve overload.")
		End If
	End Function
	Public Overloads Function Contains(ByVal key As String) As Boolean
		Return a.ContainsKey(key)
	End Function
	Public Overloads Function Contains(ByVal cmdfunc As CommandFunc) As Boolean
		For Each cmdlist As CommandList In a.Values
			If cmdlist.Contains(cmdfunc) Then Return True
		Next
		Return False
	End Function
	Public Function GetEnumerator() As System.Collections.IDictionaryEnumerator Implements System.Collections.IDictionary.GetEnumerator
		Return a.GetEnumerator
	End Function
	Public ReadOnly Property IsFixedSize() As Boolean Implements System.Collections.IDictionary.IsFixedSize
		Get
			Return False
		End Get
	End Property
	Public ReadOnly Property IsReadOnly() As Boolean Implements System.Collections.IDictionary.IsReadOnly
		Get
			Return False
		End Get
	End Property
	Private Property Item2(ByVal key As Object) As Object Implements System.Collections.IDictionary.Item
		Get
			Return Item(DirectCast(key, String))
		End Get
		Set(ByVal Value As Object)
			Item(DirectCast(key, String)) = DirectCast(Value, CommandList)
		End Set
	End Property
	Default Public Property Item(ByVal key As String) As CommandList
		Get
			Return DirectCast(a(key), CommandList)
		End Get
		Set(ByVal Value As CommandList)
			a(key) = Value
		End Set
	End Property
	Public ReadOnly Property Keys() As System.Collections.ICollection Implements System.Collections.IDictionary.Keys
		Get
			Return a.Keys
		End Get
	End Property
	Private Sub Remove2(ByVal key As Object) Implements System.Collections.IDictionary.Remove
		If TypeOf key Is CommandFunc Then
			Remove(DirectCast(key, CommandFunc))
		ElseIf TypeOf key Is String Then
			Remove(DirectCast(key, String))
		Else
			Throw New InvalidOperationException("Cannot resolve overload.")
		End If
	End Sub
	Public Sub Remove(ByVal cmd As String)
		a.Remove(cmd)
	End Sub
	Public Sub Remove(ByVal cmdfunc As CommandFunc)
		For Each cmdlist As CommandList In a.Values
			If cmdlist.Contains(cmdfunc) Then cmdlist.Remove(cmdfunc)
		Next
	End Sub
	Public ReadOnly Property Values() As System.Collections.ICollection Implements System.Collections.IDictionary.Values
		Get
			Return a.Values
		End Get
	End Property
	Private Function GetEnumerator1() As System.Collections.IEnumerator Implements System.Collections.IEnumerable.GetEnumerator
		Return DirectCast(a, IEnumerable).GetEnumerator
	End Function
End Class
'A list of ServiceClients
Public NotInheritable Class ServiceClients
	Implements IList, ICollection, IEnumerable
	ReadOnly a As ArrayList
	Public Sub New()
		a = New ArrayList
	End Sub
	Public Sub New(ByVal ParamArray Cmds() As ServiceClient)
		a = New ArrayList(Cmds)
	End Sub
	Public Sub CopyTo(ByVal array As System.Array, ByVal index As Integer) Implements System.Collections.ICollection.CopyTo
		a.CopyTo(array, index)
	End Sub
	Public ReadOnly Property Count() As Integer Implements System.Collections.ICollection.Count
		Get
			Return a.Count()
		End Get
	End Property
	Public ReadOnly Property IsSynchronized() As Boolean Implements System.Collections.ICollection.IsSynchronized
		Get
			Return False
		End Get
	End Property
	Public ReadOnly Property SyncRoot() As Object Implements System.Collections.ICollection.SyncRoot
		Get
			Return Me
		End Get
	End Property
	Public Function GetEnumerator() As System.Collections.IEnumerator Implements System.Collections.IEnumerable.GetEnumerator
		Return a.GetEnumerator
	End Function
	Private Function Add2(ByVal value As Object) As Integer Implements System.Collections.IList.Add
		Return Add(DirectCast(value, ServiceClient))
	End Function
	Public Function Add(ByVal value As ServiceClient) As Integer
		Return a.Add(value)
	End Function
	Public Sub Clear() Implements System.Collections.IList.Clear
		a.Clear()
	End Sub
	Private Function Contains2(ByVal value As Object) As Boolean Implements System.Collections.IList.Contains
		Return Contains(DirectCast(value, ServiceClient))
	End Function
	Public Function Contains(ByVal value As ServiceClient) As Boolean
		Return a.Contains(value)
	End Function
	Public Function Contains(ByVal nick As String) As Boolean
		Return (IndexOf(nick) >= 0)
	End Function
	Private Function IndexOf2(ByVal value As Object) As Integer Implements System.Collections.IList.IndexOf
		Return IndexOf(DirectCast(a, ServiceClient))
	End Function
	Public Function IndexOf(ByVal value As ServiceClient) As Integer
		Return a.IndexOf(value)
	End Function
	Public Function IndexOf(ByVal nick As String) As Integer
		For idx As Integer = 0 To a.Count - 1
			If DirectCast(a(idx), ServiceClient).Nick = nick Then Return idx
		Next
		Return -1
	End Function
	Private Sub Insert2(ByVal index As Integer, ByVal value As Object) Implements System.Collections.IList.Insert
		Insert(index, DirectCast(value, ServiceClient))
	End Sub
	Public Sub Insert(ByVal index As Integer, ByVal value As ServiceClient)
		a.Insert(index, value)
	End Sub
	Public ReadOnly Property IsFixedSize() As Boolean Implements System.Collections.IList.IsFixedSize
		Get
			Return False
		End Get
	End Property
	Public ReadOnly Property IsReadOnly() As Boolean Implements System.Collections.IList.IsReadOnly
		Get
			Return False
		End Get
	End Property
	Private Property Item2(ByVal index As Integer) As Object Implements System.Collections.IList.Item
		Get
			Return Item(index)
		End Get
		Set(ByVal Value As Object)
			Item(index) = DirectCast(Value, ServiceClient)
		End Set
	End Property
	Default Public Property Item(ByVal index As Integer) As ServiceClient
		Get
			Return DirectCast(a(index), ServiceClient)
		End Get
		Set(ByVal Value As ServiceClient)
			a(index) = Value
		End Set
	End Property
	Private Sub Remove2(ByVal value As Object) Implements System.Collections.IList.Remove
		Remove(DirectCast(value, ServiceClient))
	End Sub
	Public Sub Remove(ByVal value As ServiceClient)
		a.Remove(value)
	End Sub
	Public Sub RemoveAt(ByVal index As Integer) Implements System.Collections.IList.RemoveAt
		a.RemoveAt(index)
	End Sub
End Class
'This describes a service client that is set up by a module...
Public NotInheritable Class ServiceClient
	Public Nick As String, Ident As String, Host As String, RealName As String
	Public Usermode As String
	Public ReadOnly CmdHash As New CommandHash
	Public mainproc As ServiceMain
End Class
'A module is required to have one class that inherits from this class.
Public MustInherit Class [Module]
	'The constructor is the module's initialization routine. The module must have a Sub New matching this signature. WinSE passes to c
	'an instance of the Core class which controls everything. Through the core the module can add service clients, and add commands to
	'existing clients.
	Protected c As Core
	'This is called at module load time, during conf loading. Must not add API things here. This is for one-time initialization.
	Protected Sub New(ByVal c As Core)
		Me.c = c
	End Sub
	'This is called when a module is enabled. Modules can have arguments, which make things more fun :) .
	'To abort loading, return False or throw an exception.
	Public MustOverride Function ModLoad(ByVal params() As Collections.Specialized.StringCollection) As Boolean
	'This is called when the module goes inactive. It should remove it's API things here.
	Public MustOverride Sub ModUnload()
	'This asks the module for a help directory.
	Public MustOverride Function GetHelpDirectory() As IO.DirectoryInfo
End Class
