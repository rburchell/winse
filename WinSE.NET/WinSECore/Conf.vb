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
Imports System.IO
Imports System.Text
Imports System.Text.RegularExpressions
'The Configuration Loader where we will parse everything down into a managable class of keys and values.
'/// <summary>
'/// Represents a single Value in a configuration. A Value must reside in a
'/// key (even if the root-level key) and cannot contain Keys are Values.
'/// </summary>
Public Class Value
	'/// <summary>
	'/// Field containing the name of this Value. Names should be unique within the same container, but there is nothing that says they have to be.
	'/// </summary>
	Public name As String
	'/// <summary>
	'/// Field containing the value of this Value. The value can be of any .NET type.
	'/// </summary>
	Public value As Object
	'/// <summary>
	'/// Refers to the key that contains this value. It is set when the Value is created, but can be changed for whatever reason.
	'/// </summary>
	Public parent As Key
	Public file As String, line As Integer
	'/// <summary>
	'/// Creates a new instance of the value with the given name and parent Key.
	'/// </summary>
	'/// <param name="Name">The name of the new key.</param>
	'/// <param name="parent">The Key that contains this Value. It cannot be null (<b>Nothing</b> in Visual Basic).</param>
	'/// <exception cref="System.ArgumentNullException">parent is null (<b>Nothing</b> in Visual Basic).</exception>
	Public Sub New(ByVal Name As String, ByVal parent As Key)
		Me.name = Name
		Me.value = Nothing
		Me.parent = parent
	End Sub
	'/// <summary>
	'/// Creates a new instance of the value with the given name and parent Key and the specified initial value.
	'/// </summary>
	'/// <param name="Name">The name of the new key.</param>
	'/// <param name="Value">The initial value of the key. It can be any value of any type, including null (<b>Nothing</b> in Visual Basic).</param>
	'/// <param name="parent">The Key that contains this Value. It cannot be null (<b>Nothing</b> in Visual Basic).</param>
	'/// <exception cref="System.ArgumentNullException">parent is null (<b>Nothing</b> in Visual Basic).</exception>
	Public Sub New(ByVal Name As String, ByVal Value As Object, ByVal parent As Key)
		Me.name = Name
		Me.value = Value
		Me.parent = parent
	End Sub
End Class

'/// <summary>
'/// Holds a list of Value objects. For a description of methods, go look up other .NET Collections.
'/// </summary>
Public Class Values
	Implements ICollection, IList, IEnumerable
	Private l As ArrayList
	Public Sub New()
		l = New ArrayList
	End Sub
	Public Sub New(ByVal ParamArray v() As Value)
		l = New ArrayList(v)
	End Sub
	Public Sub CopyTo(ByVal array As Array, ByVal index As Integer) Implements ICollection.CopyTo
		l.CopyTo(array, index)
	End Sub
	Public Overloads ReadOnly Property Count() As Integer Implements ICollection.Count
		Get
			Return l.Count
		End Get
	End Property
	Public Overloads ReadOnly Property Count(ByVal name As String) As Integer
		Get
			Dim tmp As Integer = 0
			For Each v As Value In l
				If v.name = name Then
					tmp += 1
				End If
			Next
			Return tmp
		End Get
	End Property
	Public ReadOnly Property IsSynchronized() As Boolean Implements ICollection.IsSynchronized
		Get
			Return l.IsSynchronized
		End Get
	End Property
	Public ReadOnly Property SyncRoot() As Object Implements ICollection.SyncRoot
		Get
			Return l.SyncRoot
		End Get
	End Property
	Public Function GetEnumerator() As IEnumerator Implements IEnumerable.GetEnumerator
		Return l.GetEnumerator()
	End Function
	Private Function Add2(ByVal value As Object) As Integer Implements IList.Add
		Return Add(DirectCast(value, Value))
	End Function
	Public Function Add(ByVal value As Value) As Integer
		Return l.Add(value)
	End Function
	Public Sub Clear() Implements IList.Clear
		l.Clear()
	End Sub
	Private Function Contains2(ByVal value As Object) As Boolean Implements IList.Contains
		Return Contains(DirectCast(value, Value))
	End Function
	Public Function Contains(ByVal value As Value) As Boolean
		Return l.Contains(value)
	End Function
	Public Function Contains(ByVal name As String) As Boolean
		For Each v As Value In l
			If (v.name = name) Then Return True
		Next
		Return False
	End Function
	Private Function IndexOf2(ByVal value As Object) As Integer Implements IList.IndexOf
		Return IndexOf(DirectCast(value, Value))
	End Function
	Public Function IndexOf(ByVal value As Value) As Integer
		Return l.IndexOf(value)
	End Function
	Private Sub Insert2(ByVal index As Integer, ByVal value As Object) Implements IList.Insert
		Insert(index, DirectCast(value, Value))
	End Sub
	Public Sub Insert(ByVal index As Integer, ByVal value As Value)
		l.Insert(index, value)
	End Sub
	Private Sub Remove2(ByVal value As Object) Implements IList.Remove
		Remove(DirectCast(value, Value))
	End Sub
	Public Sub Remove(ByVal value As Value)
		l.Remove(value)
	End Sub
	Public Sub RemoveAt(ByVal index As Integer) Implements IList.RemoveAt
		l.RemoveAt(index)
	End Sub
	Public ReadOnly Property IsFixedSize() As Boolean Implements IList.IsFixedSize
		Get
			Return l.IsFixedSize
		End Get
	End Property
	Public ReadOnly Property IsReadOnly() As Boolean Implements IList.IsReadOnly
		Get
			Return l.IsReadOnly
		End Get
	End Property
	Private Property Item2(ByVal index As Integer) As Object Implements IList.Item
		Get
			Return Item(index)
		End Get
		Set(ByVal Value As Object)
			Item(index) = DirectCast(Value, Value)
		End Set
	End Property
	Default Public Property Item(ByVal index As Integer) As Value
		Get
			Return DirectCast(l(index), Value)
		End Get
		Set(ByVal Value As Value)
			l(index) = Value
		End Set
	End Property
	Default Public Property Item(ByVal name As String, ByVal index As Integer) As Value
		Get
			Dim tmp As Integer = index
			For Each v As Value In l
				If v.name = name Then
					If tmp = 0 Then Return v Else tmp -= 1
				End If
			Next
			Throw New IndexOutOfRangeException(String.Format("There aren't {0} keys named {1}.", index + 1, name))
		End Get
		Set(ByVal Value As Value)
			Dim tmp As Integer = index
			For i As Integer = 0 To l.Count - 1
				If DirectCast(l(i), Value).name = name Then
					If tmp = 0 Then l(i) = Value Else tmp -= 1
				End If
			Next
			Throw New IndexOutOfRangeException(String.Format("There aren't {0} keys named {1}.", index + 1, name))
		End Set
	End Property
End Class

'/// <summary>
'/// Represents a Key in a configuration file. A Key is like a Value, but it
'/// is also a container - meaning it can contain Values and other Keys.
'/// </summary>
Public Class Key
	'/// <summary>
	'/// Field containing the name of this Key. Keys in the same parent key should not have the same name, though there is nothing that requires this (mainly for XML and similar).
	'/// </summary>
	Public name As String
	'/// <summary>
	'/// Field containing the <i>default value</i> of this key. The default value is one that always exists, and is set much like the value property of the Value class.
	'/// </summary>
	Public defvalue As Object
	'/// <summary>
	'/// ReadOnly field referring to a collection of this key's subkeys. You can add or remove keys from this collection, all though you cannot modify the field itself.
	'/// </summary>
	Public ReadOnly SubKeys As Keys
	'/// <summary>
	'/// ReadOnly field referring to a collection of this key's values. You can add or remove values from this collection, all though you cannot modify the field itself.
	'/// </summary>
	Public ReadOnly Values As Values
	'/// <summary>
	'/// Field referring to this key's Parent key, or null (<b>Nothing</b> in Visual Basic) if this is the root key of a configuration.
	'/// </summary>
	Public parent As Key
	Public file As String, line As Integer
	'/// <summary>
	'/// Creates a new root key instance of the Key class. Root keys can have a name (which can be empty/null/<b>Nothing</b>), but does not have a parent key.
	'/// </summary>
	'/// <param name="name">Name of the new key.</param>
	Public Sub New(ByVal name As String)
		Me.name = name
		SubKeys = New Keys
		Values = New Values
	End Sub
	'/// <summary>
	'/// Creates a new key which is a subkey of the specified parent (which can be null (<b>Nothing</b> in Visual Basic) to create a root key).
	'/// </summary>
	'/// <param name="name">Name of the new key.</param>
	'/// <param name="parent">Parent of this key, or null (<b>Nothing</b> in Visual Basic) for root keys.</param>
	Public Sub New(ByVal name As String, ByVal parent As Key)
		Me.name = name
		Me.parent = parent
		SubKeys = New Keys
		Values = New Values
	End Sub
	'/// <summary>
	'/// Creates a new root key instance of the Key class. Root keys can have a name (which can be empty/null/<b>Nothing</b>), but does not have a parent key. Also initializes the key's default value to the given value.
	'/// </summary>
	'/// <param name="name">Name of the new key.</param>
	'/// <param name="defvalue">Value to initialize the default value to.</param>
	Public Sub New(ByVal name As String, ByVal defvalue As Object)
		Me.name = name
		Me.defvalue = defvalue
		SubKeys = New Keys
		Values = New Values
	End Sub
	'/// <summary>
	'/// Creates a new key which is a subkey of the specified parent (which can be null (<b>Nothing</b> in Visual Basic) to create a root key).
	'/// </summary>
	'/// <param name="name">Name of the new key.</param>
	'/// <param name="parent">Parent of this key, or null (<b>Nothing</b> in Visual Basic) for root keys.</param>
	'/// <param name="defvalue">Value to initialize the default value to.</param>
	Public Sub New(ByVal name As String, ByVal defvalue As Object, ByVal parent As Key)
		Me.name = name
		Me.parent = parent
		Me.defvalue = defvalue
		SubKeys = New Keys
		Values = New Values
	End Sub
	'/// <summary>
	'/// Returns all direct subkeys having the given name.
	'/// </summary>
	'/// <remarks>
	'/// The matching keys will be returned in the same order they appear in the collection - the only exception being the absence of the non-matching keys. If no keys match the given name, an empty collection will be returned.
	'/// </remarks>
	'/// <param name="name">Name of the key to search for.</param>
	'/// <returns>Keys Collection containing matching keys. If no match, collection will be empty (Count property will return 0).</returns>
	Public Function GetAllKeys(ByVal name As String) As Keys
		Dim kRet As Keys = New Keys
		For i As Integer = 0 To SubKeys.Count
			If SubKeys(i).name = name Then kRet.Add(SubKeys(i))
		Next
		Return kRet
	End Function
	'/// <summary>
	'/// Returns all direct subkeys whose name matches the given regular expression.
	'/// </summary>
	'/// <remarks>The regular expression should generally be single-line and, depending on the parser, have IgnoreCase on. Whitespace should not be ignored. Any match of the regular expression against a key name will cause it to be returned. To ensure matching against the entire Key name instead of parts of it, use the ^ and $ assertions in the regular expression.</remarks>
	'/// <param name="rx">A Regular Expression object to match against.</param>
	'/// <returns></returns>
	Public Function GetAllKeys(ByVal rx As System.Text.RegularExpressions.Regex) As Keys
		Dim kRet As Keys = New Keys
		For i As Integer = 0 To SubKeys.Count - 1
			If (rx.IsMatch(SubKeys(i).name)) Then kRet.Add(SubKeys(i))
		Next
		Return kRet
	End Function
	'/// <summary>
	'/// Returns a string representing this key and all it's parent keys. Each key name is sepereated with the given delimiter; however, no gauruntee is made that the key names themselves won't contain delimiters.
	'/// </summary>
	'/// <param name="delimiter">The string to seperate each key name in the path with.</param>
	'/// <returns>The full path of this key.</returns>
	Public Function FullPath(ByVal delimiter As String) As String
		If Not parent Is Nothing Then
			Return Me.parent.FullPath(delimiter) + delimiter + Me.name
		Else
			Return Me.name
		End If
	End Function
End Class

'/// <summary>
'/// Holds a list of Key objects. For a description of methods, go look up other .NET Collections.
'/// </summary>
Public Class Keys
	Implements ICollection, IList, IEnumerable
	Private l As ArrayList
	Public Sub New()
		l = New ArrayList
	End Sub
	Public Sub New(ByVal ParamArray v() As Key)
		l = New ArrayList(v)
	End Sub
	Public Sub CopyTo(ByVal array As Array, ByVal index As Integer) Implements ICollection.CopyTo
		l.CopyTo(array, index)
	End Sub
	Public ReadOnly Property Count() As Integer Implements ICollection.Count
		Get
			Return l.Count
		End Get
	End Property
	Public ReadOnly Property IsSynchronized() As Boolean Implements ICollection.IsSynchronized
		Get
			Return l.IsSynchronized
		End Get
	End Property
	Public ReadOnly Property SyncRoot() As Object Implements ICollection.SyncRoot
		Get
			Return l.SyncRoot
		End Get
	End Property
	Public Function GetEnumerator() As IEnumerator Implements IEnumerable.GetEnumerator
		Return l.GetEnumerator()
	End Function
	Private Function Add2(ByVal Key As Object) As Integer Implements IList.Add
		Return Add(DirectCast(Key, Key))
	End Function
	Public Function Add(ByVal Key As Key) As Integer
		Return l.Add(Key)
	End Function
	Public Sub Clear() Implements IList.Clear
		l.Clear()
	End Sub
	Private Function Contains2(ByVal Key As Object) As Boolean Implements IList.Contains
		Return Contains(DirectCast(Key, Key))
	End Function
	Public Function Contains(ByVal Key As Key) As Boolean
		Return l.Contains(Key)
	End Function
	Public Function Contains(ByVal name As String) As Boolean
		For Each v As Key In l
			If (v.name = name) Then Return True
		Next
		Return False
	End Function
	Private Function IndexOf2(ByVal Key As Object) As Integer Implements IList.IndexOf
		Return IndexOf(DirectCast(Key, Key))
	End Function
	Public Function IndexOf(ByVal Key As Key) As Integer
		Return l.IndexOf(Key)
	End Function
	Private Sub Insert2(ByVal index As Integer, ByVal Key As Object) Implements IList.Insert
		Insert(index, DirectCast(Key, Key))
	End Sub
	Public Sub Insert(ByVal index As Integer, ByVal Key As Key)
		l.Insert(index, Key)
	End Sub
	Private Sub Remove2(ByVal Key As Object) Implements IList.Remove
		Remove(DirectCast(Key, Key))
	End Sub
	Public Sub Remove(ByVal Key As Key)
		l.Remove(Key)
	End Sub
	Public Sub RemoveAt(ByVal index As Integer) Implements IList.RemoveAt
		l.RemoveAt(index)
	End Sub
	Public ReadOnly Property IsFixedSize() As Boolean Implements IList.IsFixedSize
		Get
			Return l.IsFixedSize
		End Get
	End Property
	Public ReadOnly Property IsReadOnly() As Boolean Implements IList.IsReadOnly
		Get
			Return l.IsReadOnly
		End Get
	End Property
	Private Property Item2(ByVal index As Integer) As Object Implements IList.Item
		Get
			Return Item(index)
		End Get
		Set(ByVal Key As Object)
			Item(index) = DirectCast(Key, Key)
		End Set
	End Property
	Default Public Property Item(ByVal index As Integer) As Key
		Get
			Return DirectCast(l(index), Key)
		End Get
		Set(ByVal Key As Key)
			l(index) = Key
		End Set
	End Property
	Default Public Property Item(ByVal name As String, ByVal index As Integer) As Key
		Get
			Dim tmp As Integer = index
			For Each v As Key In l
				If v.name = name Then
					If tmp = 0 Then Return v Else tmp -= 1
				End If
			Next
			Throw New IndexOutOfRangeException(String.Format("There aren't {0} keys named {1}.", index + 1, name))
		End Get
		Set(ByVal Key As Key)
			Dim tmp As Integer = index
			For i As Integer = 0 To l.Count - 1
				If DirectCast(l(i), Key).name = name Then
					If tmp = 0 Then l(i) = Key Else tmp -= 1
				End If
			Next
			Throw New IndexOutOfRangeException(String.Format("There aren't {0} keys named {1}.", index + 1, name))
		End Set
	End Property
End Class

'/// <summary>
'/// Represents a configuration loading/saving error.
'/// </summary>
<Serializable()> Public Class ConfigException : Inherits Exception
	Public file As String, line As Integer
	Public Sub New()
		MyBase.New()
	End Sub
	Public Sub New(ByVal message As String)
		MyBase.new(message)
	End Sub
	Public Sub New(ByVal message As String, ByVal innerException As Exception)
		MyBase.new(message, innerException)
	End Sub
	Public Sub New(ByVal message As String, ByVal file As String, ByVal line As Integer)
		MyBase.new(message)
		Me.file = file
		Me.line = line
	End Sub
	Public Sub New(ByVal message As String, ByVal innerException As Exception, ByVal file As String, ByVal line As Integer)
		MyBase.new(message, innerException)
		Me.file = file
		Me.line = line
	End Sub
	Protected Sub New(ByVal info As System.Runtime.Serialization.SerializationInfo, ByVal context As System.Runtime.Serialization.StreamingContext)
		MyBase.New(info, context)
	End Sub
	Public Overrides Function ToString() As String
		If Not file Is Nothing Then
			If line >= 1 Then
				Return file & "(" & line.ToString() & "): " & MyBase.ToString()
			Else
				Return file & ": " & MyBase.ToString()
			End If
		Else
			Return MyBase.ToString()
		End If
	End Function
End Class


'/// <summary>
'/// Parser used to provided a Structured Configuration Interface for
'/// INI Format Configuraiton Files.
'/// </summary>
Public Class INIParser
	Private Shared ReadOnly rxKey As New Regex("^\[(?<keyname>.+)\]\s*$", RegexOptions.Compiled Or RegexOptions.Singleline)
	Private Shared ReadOnly rxValue As New Regex("^(?<name>[^=]+)=(?<value>.*)$", RegexOptions.Compiled Or RegexOptions.Singleline)
	Private Shared ReadOnly rxShellComment As New Regex("^\s*(?<! \\)\#.*$", RegexOptions.Compiled Or RegexOptions.Multiline)
	Private Shared ReadOnly rxCXXComment As New Regex("^\s*//.*$", RegexOptions.Compiled Or RegexOptions.Multiline)
	Private Shared ReadOnly rxINIComment As New Regex("^\s*(?<! \\);.*$", RegexOptions.Compiled Or RegexOptions.Multiline)
	Public Sub New()
	End Sub
	Private Function Preprocess(ByVal strIn As String) As String
		'// Exterminate any comments.
		Dim sWork As String = strIn
		'// Strip out any \r since those will throw us a bone. :p
		sWork = sWork.Replace(vbCrLf, vbLf)
		sWork = sWork.Replace(vbCr, vbLf)
		'// We can collapse line comments w/o worrying about screwing up the
		'// block ones so we'll do that first.
		sWork = rxShellComment.Replace(sWork, "")
		sWork = rxCXXComment.Replace(sWork, "")
		sWork = rxINIComment.Replace(sWork, "")
		'// Now turn escaped comment characters into normal ones.
		sWork = sWork.Replace("\#", "#")
		sWork = sWork.Replace("\;", ";")
		Return sWork
	End Function
	'/// <summary>
	'/// Loads a configuration from an already opened stream.
	'/// </summary>
	'/// <remarks>The stream given will not be closed.</remarks>
	'/// <param name="File">Stream from which config should be read.</param>
	'/// <returns>Key object through which the entire document can be accessed as a structured configuration.</returns>
	'/// <exception cref="System.Security.SecurityException">The method does not have the privileges required.</exception>
	'/// <exception cref="System.IO.FileNotFoundException">The file couldn't be found.</exception>
	'/// <exception cref="System.IO.IOException">An I/O Exception occured during file access.</exception>
	'/// <exception cref="System.IO.PathTooLongException">The caller passed a path too long to be loaded.</exception>
	'/// <exception cref="System.IO.DirectoryNotFoundException">The caller specified a path that doesn't exist.</exception>
	'/// <exception cref="System.IO.EndOfStreamException">The parser unexpectedly reached the end of the file.</exception>
	'/// <exception cref="ConfigFile.ConfigException">The parser encountered an error parsing the configuration (such as incorrect config-file syntax).</exception>
	Public Function Load(ByVal File As String) As WinSECore.Key
		Dim fd As New StreamReader(File)
		Dim sFile As String = Nothing
		Dim kRoot As New Key(Nothing)
		Dim kCur As Key = Nothing
		Dim s() As String, idx As Integer, sLine As String
		sFile = fd.ReadToEnd()
		sFile = Preprocess(sFile)
		s = Split(sFile, vbLf)
		For idx = 0 To s.Length - 1
			sLine = s(idx)
			'// What is it?
			Dim m As Match = Nothing
			If sLine = "" Then
				'// Do nothing.
			Else
				m = rxKey.Match(sLine)
				If m.Success Then
					'// Key... 
					'// Only tag is keyname... fun fun fun
					kCur = New Key(m.Groups("keyname").Value, kRoot)
					With kRoot.SubKeys(kRoot.SubKeys.Add(kCur))
						.file = File
						.line = idx + 1
					End With
				Else
					m = rxValue.Match(sLine)
					If m.Success Then
						'// Value...
						'// Tags are name and value....
						Dim nKey As String = m.Groups("name").Value
						Dim nValue As String = m.Groups("value").Value
						If kCur Is Nothing Then
							Throw New ConfigException("Value outside of key.")
						End If
						With kCur.Values(kCur.Values.Add(New Value(nKey, nValue, kCur)))
							.file = File
							.line = idx + 1
						End With
					Else
						'// Something else...
						Throw New ConfigException("Syntax error: " + sLine)
					End If
				End If
			End If
		Next
		Return kRoot
	End Function
	'/// <summary>
	'/// Save a configuration to an already opened stream.
	'/// </summary>
	'/// <remarks>The stream given will not be closed.</remarks>
	'/// <param name="File">Stream to which file should be written.</param>
	'/// <param name="SaveWhat">Structured Configuration to save.</param>
	'/// <exception cref="System.Security.SecurityException">The method does not have the privileges required.</exception>
	'/// <exception cref="System.IO.FileNotFoundException">The file couldn't be found.</exception>
	'/// <exception cref="System.IO.IOException">An I/O Exception occured during file access.</exception>
	'/// <exception cref="System.IO.PathTooLongException">The caller passed a path too long to be loaded.</exception>
	'/// <exception cref="System.IO.DirectoryNotFoundException">The caller specified a path that doesn't exist.</exception>
	'/// <exception cref="System.IO.EndOfStreamException">The parser unexpectedly reached the end of the file.</exception>
	'/// <exception cref="ConfigFile.ConfigException">The parser encountered an error parsing the configuration (such as unsupported configuration feature).</exception>
	Public Sub Save(ByVal File As String, ByVal SaveWhat As Key)
		Dim sTmp As String = "", fd As StreamWriter
		fd = New StreamWriter(File)
		For Each k As Key In SaveWhat.SubKeys
			If k.SubKeys.Count > 0 Then Throw New ConfigException("Cannot use nested keys.")
			sTmp += String.Format("[{0}]", k.name)
			sTmp += vbCrLf
			For Each v As Value In k.Values
				Dim sVal As String = Nothing
				If TypeOf v.value Is String Then
					sVal = v.value.ToString()
				ElseIf TypeOf v.value Is Short OrElse TypeOf v.value Is Integer OrElse TypeOf v.value Is Long OrElse TypeOf v.value Is Single OrElse TypeOf v.value Is Double OrElse TypeOf v.value Is System.SByte OrElse TypeOf v.value Is UInt16 OrElse TypeOf v.value Is UInt32 OrElse TypeOf v.value Is UInt64 OrElse TypeOf v.value Is Date OrElse TypeOf v.value Is Decimal Then
					sVal = v.value.ToString()
				ElseIf TypeOf v.value Is Boolean Then
					sVal = IIf(CBool(v.value), 1, 0).ToString()
				Else
					Throw New ConfigException(String.Format("Unsupported type '{0}'. Can only save Strings, Integers, Doubles, or Serializable classes.", v.GetType().ToString()))
				End If
				sTmp += String.Format("{0}={1}{2}", v.name, sVal, vbCrLf)
			Next
			sTmp += vbCrLf
		Next
		fd.Write(sTmp)
		fd.Close()
	End Sub
End Class

