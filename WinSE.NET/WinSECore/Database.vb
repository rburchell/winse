'Copyright (c) 2005 The WinSE Team 
'All rights reserved. 
' 
'Redistribution and use in source and binary forms, with or without 
'modification, are permitted provided that the following conditions 
'are met: 
'1. Redistributions of source code must retain the above copyright 
'   notice, this list of conditions and the following disclaimer. 
'2. Redistributions in binary form must reproduce the above copyright 
'   notice, this list of conditions and the following disclaimer in the 
'   documentation and/or other materials provided with the distribution. 
'3. The name of the author may not be used to endorse or promote products 
'   derived from this software without specific prior written permission.

'THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR 
'IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
'OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
'IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, 
'INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
'NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
'DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
'THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
'(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF 
'THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
Option Explicit On 
Option Strict On
Option Compare Binary
Imports Microsoft.VisualBasic
Imports System
Imports System.Collections
Imports System.Collections.Specialized

'Basic Database structure:
'Database
'+- Table1
'|  +- Record1
'|  |  `- Field1 = Value1
'|  |  `- Field2 = Value2
'|  `- Record 2
'|     `- Field1 = Value1
'|     `- Field2 = Value2
'`- Table 2
'   +- Record1
'   |  +- Field1 = Value1
'   |  `- Field2 = Value2
'   `- Record 2
'      +- Field1 = Value1
'      `- Field2 = Value2
'This structure should work with basically any kind of database format, be it flatfile format, SQL, or whatever.
'Record names are the only thing that might cause issues - because records must have a name of some kind, database
'modules have to decide how to name them. Typically the main key of the table will be used to name the record. In the
'event that there is no field gaurunteed to be unique, a random "RecordID" can be used as the identifier.

Public NotInheritable Class Field
	Public Name As String
	Public Value As Object
	Public Sub New(ByVal name As String, Optional ByVal val As Object = Nothing)
		Me.Name = name
		Me.Value = val
	End Sub
End Class

Public NotInheritable Class Record
	Implements IList, ICollection, IEnumerable
	Public Name As String
	Private a As New ArrayList
	Public Sub New(ByVal name As String)
		Me.Name = name
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
		Return a.GetEnumerator()
	End Function
	Private Function Add2(ByVal value As Object) As Integer Implements System.Collections.IList.Add
		Add(DirectCast(value, Field))
	End Function
	Public Overloads Function Add(ByVal rec As Field) As Integer
		Return a.Add(rec)
	End Function
	Public Overloads Function Add(ByVal name As String, Optional ByVal value As Object = Nothing) As Integer
		Return Add(New Field(name, value))
	End Function
	Public Sub Clear() Implements System.Collections.IList.Clear
		a.Clear()
	End Sub
	Private Function Contains2(ByVal value As Object) As Boolean Implements System.Collections.IList.Contains
		Return Contains(DirectCast(value, Field))
	End Function
	Public Overloads Function Contains(ByVal value As Field) As Boolean
		Return a.Contains(value)
	End Function
	Public Overloads Function Contains(ByVal name As String) As Boolean
		Return IndexOf(name) >= 0
	End Function
	Private Function IndexOf2(ByVal value As Object) As Integer Implements System.Collections.IList.IndexOf
		Return IndexOf(DirectCast(value, Field))
	End Function
	Public Overloads Function IndexOf(ByVal value As Field) As Integer
		Return a.IndexOf(value)
	End Function
	Public Overloads Function IndexOf(ByVal name As String) As Integer
		For idx As Integer = 0 To a.Count - 1
			If LCase(DirectCast(a(idx), Field).Name) = LCase(name) Then Return idx
		Next
		Return -1
	End Function
	Private Sub Insert2(ByVal index As Integer, ByVal value As Object) Implements System.Collections.IList.Insert
		Insert(index, DirectCast(value, Field))
	End Sub
	Public Overloads Sub Insert(ByVal index As Integer, ByVal value As Field)
		a.Insert(index, value)
	End Sub
	Public Overloads Sub Insert(ByVal index As Integer, ByVal name As String, Optional ByVal value As Object = Nothing)
		Insert(index, New Field(name, value))
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
			Item(index) = DirectCast(Value, Field)
		End Set
	End Property
	Default Public Overloads Property Item(ByVal index As Integer) As Field
		Get
			Return DirectCast(a(index), Field)
		End Get
		Set(ByVal Value As Field)
			a(index) = Value
		End Set
	End Property
	Default Public Overloads ReadOnly Property Item(ByVal name As String) As Field
		Get
			Dim idx As Integer = IndexOf(name)
			If idx < 0 Then Throw New IndexOutOfRangeException("No such field.")
			Return Item(idx)
		End Get
	End Property
	Private Sub Remove2(ByVal value As Object) Implements System.Collections.IList.Remove
		Remove(DirectCast(value, Field))
	End Sub
	Public Sub Remove(ByVal value As Field)
		a.Remove(value)
	End Sub
	Public Sub RemoveAt(ByVal index As Integer) Implements System.Collections.IList.RemoveAt
		a.RemoveAt(index)
	End Sub
	Public Function GetField(ByVal name As String) As Object
		If Not Contains(name) Then Return Nothing
		Return Item(name).Value
	End Function
	Public Sub SetField(ByVal name As String, ByVal value As Object)
		If Not Contains(name) Then
			Add(name, value)
		Else
			Item(name).Value = value
		End If
	End Sub
End Class

Public NotInheritable Class Table
	Implements IList, ICollection, IEnumerable
	Public Name As String
	Private a As New ArrayList
	Public Sub New(ByVal name As String)
		Me.Name = name
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
		Return a.GetEnumerator()
	End Function
	Private Function Add2(ByVal value As Object) As Integer Implements System.Collections.IList.Add
		Add(DirectCast(value, Record))
	End Function
	Public Overloads Function Add(ByVal rec As Record) As Integer
		Return a.Add(rec)
	End Function
	Public Overloads Function Add(ByVal name As String) As Integer
		Return Add(New Record(name))
	End Function
	Public Sub Clear() Implements System.Collections.IList.Clear
		a.Clear()
	End Sub
	Private Function Contains2(ByVal value As Object) As Boolean Implements System.Collections.IList.Contains
		Return Contains(DirectCast(value, Record))
	End Function
	Public Overloads Function Contains(ByVal value As Record) As Boolean
		Return a.Contains(value)
	End Function
	Public Overloads Function Contains(ByVal name As String) As Boolean
		Return IndexOf(name) >= 0
	End Function
	Private Function IndexOf2(ByVal value As Object) As Integer Implements System.Collections.IList.IndexOf
		Return IndexOf(DirectCast(value, Record))
	End Function
	Public Overloads Function IndexOf(ByVal value As Record) As Integer
		Return a.IndexOf(value)
	End Function
	Public Overloads Function IndexOf(ByVal name As String) As Integer
		For idx As Integer = 0 To a.Count - 1
			If LCase(DirectCast(a(idx), Record).Name) = LCase(name) Then Return idx
		Next
		Return -1
	End Function
	Private Sub Insert2(ByVal index As Integer, ByVal value As Object) Implements System.Collections.IList.Insert
		Insert(index, DirectCast(value, Record))
	End Sub
	Public Overloads Sub Insert(ByVal index As Integer, ByVal value As Record)
		a.Insert(index, value)
	End Sub
	Public Overloads Sub Insert(ByVal index As Integer, ByVal name As String)
		Insert(index, New Record(name))
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
			Item(index) = DirectCast(Value, Record)
		End Set
	End Property
	Default Public Overloads Property Item(ByVal index As Integer) As Record
		Get
			Return DirectCast(a(index), Record)
		End Get
		Set(ByVal Value As Record)
			a(index) = Value
		End Set
	End Property
	Default Public Overloads ReadOnly Property Item(ByVal name As String) As Record
		Get
			Dim idx As Integer = IndexOf(name)
			If idx < 0 Then Throw New IndexOutOfRangeException("No such record.")
			Return Item(idx)
		End Get
	End Property
	Private Sub Remove2(ByVal value As Object) Implements System.Collections.IList.Remove
		Remove(DirectCast(value, Record))
	End Sub
	Public Sub Remove(ByVal value As Record)
		a.Remove(value)
	End Sub
	Public Sub RemoveAt(ByVal index As Integer) Implements System.Collections.IList.RemoveAt
		a.RemoveAt(index)
	End Sub
End Class

Public NotInheritable Class Database
	Implements IList, ICollection, IEnumerable
	Private a As New ArrayList
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
		Return a.GetEnumerator()
	End Function
	Private Function Add2(ByVal value As Object) As Integer Implements System.Collections.IList.Add
		Add(DirectCast(value, Table))
	End Function
	Public Overloads Function Add(ByVal rec As Table) As Integer
		Return a.Add(rec)
	End Function
	Public Overloads Function Add(ByVal name As String) As Integer
		Return Add(New Table(name))
	End Function
	Public Sub Clear() Implements System.Collections.IList.Clear
		a.Clear()
	End Sub
	Private Function Contains2(ByVal value As Object) As Boolean Implements System.Collections.IList.Contains
		Return Contains(DirectCast(value, Table))
	End Function
	Public Overloads Function Contains(ByVal value As Table) As Boolean
		Return a.Contains(value)
	End Function
	Public Overloads Function Contains(ByVal name As String) As Boolean
		Return IndexOf(name) >= 0
	End Function
	Private Function IndexOf2(ByVal value As Object) As Integer Implements System.Collections.IList.IndexOf
		Return IndexOf(DirectCast(value, Table))
	End Function
	Public Overloads Function IndexOf(ByVal value As Table) As Integer
		Return a.IndexOf(value)
	End Function
	Public Overloads Function IndexOf(ByVal name As String) As Integer
		For idx As Integer = 0 To a.Count - 1
			If LCase(DirectCast(a(idx), Table).Name) = LCase(name) Then Return idx
		Next
		Return -1
	End Function
	Private Sub Insert2(ByVal index As Integer, ByVal value As Object) Implements System.Collections.IList.Insert
		Insert(index, DirectCast(value, Table))
	End Sub
	Public Overloads Sub Insert(ByVal index As Integer, ByVal value As Table)
		a.Insert(index, value)
	End Sub
	Public Overloads Sub Insert(ByVal index As Integer, ByVal name As String)
		Insert(index, New Table(name))
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
			Item(index) = DirectCast(Value, Table)
		End Set
	End Property
	Default Public Overloads Property Item(ByVal index As Integer) As Table
		Get
			Return DirectCast(a(index), Table)
		End Get
		Set(ByVal Value As Table)
			a(index) = Value
		End Set
	End Property
	Default Public Overloads ReadOnly Property Item(ByVal name As String) As Table
		Get
			Dim idx As Integer = IndexOf(name)
			If idx < 0 Then Throw New IndexOutOfRangeException("No such record.")
			Return Item(idx)
		End Get
	End Property
	Private Sub Remove2(ByVal value As Object) Implements System.Collections.IList.Remove
		Remove(DirectCast(value, Table))
	End Sub
	Public Sub Remove(ByVal value As Table)
		a.Remove(value)
	End Sub
	Public Sub RemoveAt(ByVal index As Integer) Implements System.Collections.IList.RemoveAt
		a.RemoveAt(index)
	End Sub
End Class

'This is the class a database module inherits to provide a database driver.
Public MustInherit Class DataDriver
	Public MustOverride Function LoadDatabase() As Database
	Public MustOverride Sub SaveDatabase(ByVal db As Database)
	Public Shared Function CreateRecordID(ByVal t As Table, Optional ByVal idlen As Integer = 10) As String
		Dim s As String = "", rnd As New Random
		If idlen < 1 Then Throw New ArgumentException("Invalid length", "idlen")
		While s = ""
			s = ""
			For idx As Integer = 1 To idlen
				s += Chr(rnd.Next(33, 126))
			Next
			If t.Contains(s) Then s = ""
		End While
		Return s
	End Function
End Class