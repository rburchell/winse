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

Public MustInherit Class IRCNode
	Implements IDisposable
	Public Name As String
	Public Info As String
	Public Numeric As Integer
	Protected Overrides Sub Finalize()
		Dispose(False)
	End Sub
	Public Sub Dispose() Implements System.IDisposable.Dispose
		Dispose(True)
		GC.SuppressFinalize(Me)
	End Sub
	Protected Overridable Sub Dispose(ByVal disposing As Boolean)
	End Sub
End Class

Public NotInheritable Class Nodes
	Implements IList, ICollection, IEnumerable
	ReadOnly a As ArrayList
	Public Sub New()
		a = New ArrayList
	End Sub
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
	Public Function GetEnumerator() As System.Collections.IEnumerator Implements System.Collections.IEnumerable.GetEnumerator
		Return a.GetEnumerator
	End Function
	Private Function Add2(ByVal value As Object) As Integer Implements System.Collections.IList.Add
		Return Add(DirectCast(value, IRCNode))
	End Function
	Public Function Add(ByVal value As IRCNode) As Integer
		Return a.Add(value)
	End Function
	Public Sub Clear() Implements System.Collections.IList.Clear
		a.Clear()
	End Sub
	Private Function Contains2(ByVal value As Object) As Boolean Implements System.Collections.IList.Contains
		Return Contains(DirectCast(value, IRCNode))
	End Function
	Public Overloads Function Contains(ByVal value As IRCNode) As Boolean
		Return a.Contains(value)
	End Function
	Public Overloads Function Contains(ByVal name As String) As Boolean
		Return IndexOf(name) >= 0
	End Function
	Private Function IndexOf2(ByVal value As Object) As Integer Implements System.Collections.IList.IndexOf
		Return IndexOf(DirectCast(value, IRCNode))
	End Function
	Public Overloads Function IndexOf(ByVal value As IRCNode) As Integer
		Return a.IndexOf(value)
	End Function
	Public Overloads Function IndexOf(ByVal name As String) As Integer
		For idx As Integer = 0 To a.Count - 1
			If DirectCast(a(idx), IRCNode).Name = name Then Return idx
		Next
		Return -1
	End Function
	Private Sub Insert2(ByVal index As Integer, ByVal value As Object) Implements System.Collections.IList.Insert
		Insert(index, DirectCast(value, IRCNode))
	End Sub
	Public Sub Insert(ByVal index As Integer, ByVal value As IRCNode)
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
			Item(index) = DirectCast(Value, IRCNode)
		End Set
	End Property
	Default Public Overloads Property Item(ByVal index As Integer) As IRCNode
		Get
			Return DirectCast(a(index), IRCNode)
		End Get
		Set(ByVal Value As IRCNode)
			a(index) = Value
		End Set
	End Property
	Default Public Overloads ReadOnly Property Item(ByVal name As String) As IRCNode
		Get
			Dim idx As Integer = IndexOf(name)
			If idx < 0 Then Throw New IndexOutOfRangeException("Object not found")
			Return Item(idx)
		End Get
	End Property
	Private Sub Remove2(ByVal value As Object) Implements System.Collections.IList.Remove
		Remove(DirectCast(value, IRCNode))
	End Sub
	Public Sub Remove(ByVal value As IRCNode)
		a.Remove(value)
	End Sub
	Public Sub RemoveAt(ByVal index As Integer) Implements System.Collections.IList.RemoveAt
		a.RemoveAt(index)
	End Sub
End Class

Public NotInheritable Class User
	Inherits IRCNode
	Public Property Nick() As String
		Get
			Return Name
		End Get
		Set(ByVal Value As String)
			Name = Value
		End Set
	End Property
	Public Username As String
	Public Hostname As String
	Public Property RealName() As String
		Get
			Return Info
		End Get
		Set(ByVal Value As String)
			Info = Value
		End Set
	End Property
	Public Usermodes As String
	Public ReadOnly Identifies As New StringCollection
	Public AwayMessage As String
	Public TS As Integer
	Public VHost As String
	Public Server As Server
	Public SWhois As String
	Public ReadOnly Custom As New Hashtable
	Public ReadOnly Channels As New Channels
	Protected Overloads Overrides Sub Dispose(ByVal disposing As Boolean)
		While Channels.Count > 0
			Channels(0).UserList.Remove(Channels(0).UserList(Me))
			Channels.RemoveAt(0)
		End While
	End Sub
End Class

Public NotInheritable Class Server
	Inherits IRCNode
	Public ReadOnly SubNodes As New Nodes
End Class

Public NotInheritable Class ListModeTable
	Implements IDictionary
	ReadOnly a As Hashtable
	Public Sub New()
		a = New Hashtable
	End Sub
	Public Sub New(ByVal keys() As Char)
		a = New Hashtable
		For Each key As Char In keys
			Add(key)
		Next
	End Sub
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
			Return a
		End Get
	End Property
	Private Sub Add2(ByVal key As Object, ByVal value As Object) Implements System.Collections.IDictionary.Add
		Add(DirectCast(key, Char), DirectCast(value, StringCollection))
	End Sub
	Public Overloads Sub Add(ByVal key As Char)
		Add(key, New StringCollection)
	End Sub
	Public Overloads Sub Add(ByVal key As Char, ByVal value As StringCollection)
		a.Add(key, value)
	End Sub
	Public Sub Clear() Implements System.Collections.IDictionary.Clear
		a.Clear()
	End Sub
	Private Function Contains2(ByVal key As Object) As Boolean Implements System.Collections.IDictionary.Contains
		Return Contains(DirectCast(key, Char))
	End Function
	Public Function Contains(ByVal key As Char) As Boolean
		Return a.Contains(key)
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
			Return Item(DirectCast(key, Char))
		End Get
		Set(ByVal Value As Object)
			Item(DirectCast(key, Char)) = DirectCast(Value, StringCollection)
		End Set
	End Property
	Default Public Property Item(ByVal key As Char) As StringCollection
		Get
			Return DirectCast(a(key), StringCollection)
		End Get
		Set(ByVal Value As StringCollection)
			a(key) = Value
		End Set
	End Property
	Public ReadOnly Property Keys() As System.Collections.ICollection Implements System.Collections.IDictionary.Keys
		Get
			Return a.Keys
		End Get
	End Property
	Private Sub Remove2(ByVal key As Object) Implements System.Collections.IDictionary.Remove
		Remove(DirectCast(key, Char))
	End Sub
	Public Sub Remove(ByVal key As Char)
		a.Remove(key)
	End Sub
	Public ReadOnly Property Values() As System.Collections.ICollection Implements System.Collections.IDictionary.Values
		Get
			Return a.Values
		End Get
	End Property
	Public Function GetEnumerator1() As System.Collections.IEnumerator Implements System.Collections.IEnumerable.GetEnumerator
		Return a.GetEnumerator
	End Function
End Class

Public NotInheritable Class ChannelMember
	Public Who As User
	Public Status As String
	Public Sub New(ByVal who As User)
		Me.Who = who
	End Sub
End Class

Public NotInheritable Class Members
	Implements IList, ICollection, IEnumerable
	ReadOnly a As ArrayList
	Public Sub New()
		a = New ArrayList
	End Sub
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
	Public Function GetEnumerator() As System.Collections.IEnumerator Implements System.Collections.IEnumerable.GetEnumerator
		Return a.GetEnumerator
	End Function
	Private Function Add2(ByVal value As Object) As Integer Implements System.Collections.IList.Add
		Return Add(DirectCast(value, ChannelMember))
	End Function
	Public Function Add(ByVal value As ChannelMember) As Integer
		Return a.Add(value)
	End Function
	Public Sub Clear() Implements System.Collections.IList.Clear
		a.Clear()
	End Sub
	Private Function Contains2(ByVal value As Object) As Boolean Implements System.Collections.IList.Contains
		Return Contains(DirectCast(value, ChannelMember))
	End Function
	Public Overloads Function Contains(ByVal value As ChannelMember) As Boolean
		Return a.Contains(value)
	End Function
	Public Overloads Function Contains(ByVal who As User) As Boolean
		Return IndexOf(who) >= 0
	End Function
	Public Overloads Function Contains(ByVal name As String) As Boolean
		Return IndexOf(name) >= 0
	End Function
	Private Function IndexOf2(ByVal value As Object) As Integer Implements System.Collections.IList.IndexOf
		Return IndexOf(DirectCast(value, ChannelMember))
	End Function
	Public Overloads Function IndexOf(ByVal value As ChannelMember) As Integer
		Return a.IndexOf(value)
	End Function
	Public Overloads Function IndexOf(ByVal who As User) As Integer
		For idx As Integer = 0 To a.Count - 1
			If DirectCast(a(idx), ChannelMember).Who Is who Then Return idx
		Next
		Return -1
	End Function
	Public Overloads Function IndexOf(ByVal name As String) As Integer
		For idx As Integer = 0 To a.Count - 1
			If DirectCast(a(idx), ChannelMember).Who.Name = name Then Return idx
		Next
		Return -1
	End Function
	Private Sub Insert2(ByVal index As Integer, ByVal value As Object) Implements System.Collections.IList.Insert
		Insert(index, DirectCast(value, ChannelMember))
	End Sub
	Public Sub Insert(ByVal index As Integer, ByVal value As ChannelMember)
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
			Item(index) = DirectCast(Value, ChannelMember)
		End Set
	End Property
	Default Public Overloads Property Item(ByVal index As Integer) As ChannelMember
		Get
			Return DirectCast(a(index), ChannelMember)
		End Get
		Set(ByVal Value As ChannelMember)
			a(index) = Value
		End Set
	End Property
	Default Public Overloads ReadOnly Property Item(ByVal who As User) As ChannelMember
		Get
			Dim idx As Integer = IndexOf(who)
			If idx < 0 Then Throw New IndexOutOfRangeException("Object not found")
			Return Item(idx)
		End Get
	End Property
	Default Public Overloads ReadOnly Property Item(ByVal name As String) As ChannelMember
		Get
			Dim idx As Integer = IndexOf(name)
			If idx < 0 Then Throw New IndexOutOfRangeException("Object not found")
			Return Item(idx)
		End Get
	End Property
	Private Sub Remove2(ByVal value As Object) Implements System.Collections.IList.Remove
		Remove(DirectCast(value, ChannelMember))
	End Sub
	Public Sub Remove(ByVal value As ChannelMember)
		a.Remove(value)
	End Sub
	Public Sub RemoveAt(ByVal index As Integer) Implements System.Collections.IList.RemoveAt
		a.RemoveAt(index)
	End Sub
End Class

Public NotInheritable Class Channel
	Public Name As String
	Public Topic As String
	Public ParamlessModes As String
	Public ReadOnly ParamedModes As New StringDictionary	'Key = modechar, value = modevalue
	Public ReadOnly ListModes As New ListModeTable	'Key = = modechar, value = StringCollection
	Public ReadOnly UserList As New Members
End Class

Public NotInheritable Class Channels
	Implements IList, ICollection, IEnumerable
	ReadOnly a As ArrayList
	Public Sub New()
		a = New ArrayList
	End Sub
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
	Public Function GetEnumerator() As System.Collections.IEnumerator Implements System.Collections.IEnumerable.GetEnumerator
		Return a.GetEnumerator
	End Function
	Private Function Add2(ByVal value As Object) As Integer Implements System.Collections.IList.Add
		Return Add(DirectCast(value, Channel))
	End Function
	Public Function Add(ByVal value As Channel) As Integer
		Return a.Add(value)
	End Function
	Public Sub Clear() Implements System.Collections.IList.Clear
		a.Clear()
	End Sub
	Private Function Contains2(ByVal value As Object) As Boolean Implements System.Collections.IList.Contains
		Return Contains(DirectCast(value, Channel))
	End Function
	Public Overloads Function Contains(ByVal value As Channel) As Boolean
		Return a.Contains(value)
	End Function
	Public Overloads Function Contains(ByVal name As String) As Boolean
		Return IndexOf(name) >= 0
	End Function
	Private Function IndexOf2(ByVal value As Object) As Integer Implements System.Collections.IList.IndexOf
		Return IndexOf(DirectCast(value, Channel))
	End Function
	Public Overloads Function IndexOf(ByVal value As Channel) As Integer
		Return a.IndexOf(value)
	End Function
	Public Overloads Function IndexOf(ByVal name As String) As Integer
		For idx As Integer = 0 To a.Count - 1
			If DirectCast(a(idx), IRCNode).Name = name Then Return idx
		Next
		Return -1
	End Function
	Private Sub Insert2(ByVal index As Integer, ByVal value As Object) Implements System.Collections.IList.Insert
		Insert(index, DirectCast(value, Channel))
	End Sub
	Public Sub Insert(ByVal index As Integer, ByVal value As Channel)
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
			Item(index) = DirectCast(Value, Channel)
		End Set
	End Property
	Default Public Overloads Property Item(ByVal index As Integer) As Channel
		Get
			Return DirectCast(a(index), Channel)
		End Get
		Set(ByVal Value As Channel)
			a(index) = Value
		End Set
	End Property
	Default Public Overloads ReadOnly Property Item(ByVal name As String) As Channel
		Get
			Dim idx As Integer = IndexOf(name)
			If idx < 0 Then Throw New IndexOutOfRangeException("Object not found")
			Return Item(idx)
		End Get
	End Property
	Private Sub Remove2(ByVal value As Object) Implements System.Collections.IList.Remove
		Remove(DirectCast(value, Channel))
	End Sub
	Public Sub Remove(ByVal value As Channel)
		a.Remove(value)
	End Sub
	Public Sub RemoveAt(ByVal index As Integer) Implements System.Collections.IList.RemoveAt
		a.RemoveAt(index)
	End Sub
End Class
