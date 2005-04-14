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
	Public ReadOnly Custom As New Hashtable
	Protected ReadOnly c As WinSECore.Core
	Protected Overrides Sub Finalize()
		Dispose(False)
	End Sub
	Public Sub Dispose() Implements System.IDisposable.Dispose
		Dispose(True)
		GC.SuppressFinalize(Me)
	End Sub
	Protected MustOverride Sub Dispose(ByVal disposing As Boolean)
	Protected Sub New(ByVal c As WinSECore.Core)
		Me.c = c
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

Public Delegate Function SendMsgProc(ByVal Source As IRCNode, ByVal Dest As User, ByVal Message As String) As Boolean

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
	Public IP As System.Net.IPAddress
	Public Property RealName() As String
		Get
			Return Info
		End Get
		Set(ByVal Value As String)
			Info = Value
		End Set
	End Property
	Public Usermodes As String
	Public Flags As String, AbuseTeam As Boolean
	Public Since As Integer
	Public ReadOnly Identifies As New StringCollection
	Public AwayMessage As String
	Public TS As Integer
	Public VHost As String, VIdent As String
	Public Server As Server
	Public SWhois As String
	Public SendMessage As SendMsgProc
	Public ReadOnly Channels As New Channels
	Protected Overloads Overrides Sub Dispose(ByVal disposing As Boolean)
		Dim chptr As Channel
		While Channels.Count > 0
			chptr = Channels(0)
			chptr.UserList.Remove(chptr.UserList(Me))
			If chptr.Identifies.Contains(Me) Then chptr.Identifies.Remove(Me)
			Channels.RemoveAt(0)
			c.Events.FireClientPart(Me, chptr, "Client Quit")
			If chptr.UserList.Count = 0 Then c.Channels.Remove(chptr)
		End While
		If Not Server Is Nothing AndAlso Server.SubNodes.Contains(Me) Then
			Server.SubNodes.Remove(Me)
			Server = Nothing
		End If
	End Sub
	Public Sub New(ByVal c As Core)
		MyBase.New(c)
	End Sub
	Public Sub SetUserModes(ByVal Modes As String, Optional ByVal Source As WinSECore.IRCNode = Nothing)
		Dim bSet As Boolean
		Dim ch As Char
		If Server Is Nothing Then Throw New ObjectDisposedException(Name)
		For idx As Integer = 0 To Modes.Length - 1
			ch = Modes.Chars(idx)
			Select Case ch
				Case "+"c : bSet = True
				Case "-"c : bSet = False
				Case Else
					If bSet AndAlso Usermodes.IndexOf(ch) < 0 Then
						Usermodes += ch
					ElseIf (Not bSet) AndAlso Usermodes.IndexOf(ch) >= 0 Then
						Usermodes = Usermodes.Replace(ch.ToString(), "")
					End If
					c.Events.FireUserModeChange(DirectCast(IIf(Source Is Nothing, Me, Source), WinSECore.IRCNode), Me, ch, bSet)
			End Select
		Next
	End Sub
	Public Sub ForceUserModes(ByVal Source As WinSECore.IRCNode, ByVal Modes As String)
		If Server Is Nothing Then Throw New ObjectDisposedException(Name)
		c.protocol.ForceUMode(Source, Name, Modes)
		SetUserModes(Modes, Source)
	End Sub
	Public Sub KillUser(ByVal Source As IRCNode, ByVal Reason As String)
		If Server Is Nothing Then Throw New ObjectDisposedException(Name)
		c.protocol.KillUser(Source, Name, Reason)
		Dispose()
	End Sub
	Public Sub SVSKillUser(ByVal Source As IRCNode, ByVal Reason As String)
		If Server Is Nothing Then Throw New ObjectDisposedException(Name)
		c.protocol.KillUser(Source, Name, Reason, True)
		If (c.protocol.SupportFlags And IRCdSupportFlags.QUIRK_SUPERKILL_ACKNOWLEDGE) = 0 Then
			Dispose()
		End If
	End Sub
	Public Sub AddFloodPoint()
		Dim ts As Integer = API.GetTS()
		If Server Is Nothing Then Throw New ObjectDisposedException(Name)
		If Since < ts Then
			Since = ts
		End If
		Since += 2
		If (Since - ts) >= 20 Then
			KillUser(c.Services, "Excess Flood")
		End If
	End Sub
	Public Sub SetFlags(ByVal FlagChange As String)
		Dim bSet As Boolean
		Dim ch As Char
		If Server Is Nothing Then Throw New ObjectDisposedException(Name)
		For idx As Integer = 0 To FlagChange.Length - 1
			ch = FlagChange.Chars(idx)
			Select Case ch
				Case "+"c : bSet = True
				Case "-"c : bSet = False
				Case Else
					If bSet AndAlso Flags.IndexOf(ch) >= 0 Then
						Flags += ch
					ElseIf (Not bSet) AndAlso Flags.IndexOf(ch) < 0 Then
						Flags = Flags.Replace(ch.ToString(), "")
					End If
			End Select
		Next
	End Sub
	Public Function HasFlag(ByVal flag As Char) As Boolean
		If Server Is Nothing Then Throw New ObjectDisposedException(Name)
		Return Flags.IndexOf(flag) >= 0
	End Function
End Class

Public NotInheritable Class Server
	Inherits IRCNode
	Public Parent As Server
	Public ReadOnly SubNodes As New Nodes
	Public Function HasClient(ByVal cptr As WinSECore.IRCNode, Optional ByVal RecursiveSearch As Boolean = True) As Boolean
		If SubNodes.Contains(cptr) Then Return True
		If RecursiveSearch Then
			For Each n As WinSECore.IRCNode In SubNodes
				If TypeOf n Is WinSECore.Server Then
					If DirectCast(n, WinSECore.Server).HasClient(cptr, True) Then
						Return True
					End If
				End If
			Next
		End If
		Return False
	End Function
	Public Function GetUsers() As Nodes
		Dim n As New Nodes
		For Each cptr As IRCNode In SubNodes
			If TypeOf cptr Is WinSECore.User Then
				n.Add(cptr)
			ElseIf TypeOf cptr Is WinSECore.Server Then
				DirectCast(cptr, WinSECore.Server).GetUsers(n)
			Else
				'Ugh.
			End If
		Next
		Return n
	End Function
	Private Sub GetUsers(ByVal n As Nodes)
		For Each cptr As IRCNode In SubNodes
			If TypeOf cptr Is WinSECore.User Then
				n.Add(cptr)
			ElseIf TypeOf cptr Is WinSECore.Server Then
				DirectCast(cptr, WinSECore.Server).GetUsers(n)
			Else
				'Ugh.
			End If
		Next
	End Sub
	Public Function GetServers() As Nodes
		Dim n As New Nodes
		For Each cptr As IRCNode In SubNodes
			If TypeOf cptr Is WinSECore.Server Then
				n.Add(cptr)
				DirectCast(cptr, WinSECore.Server).GetServers(n)
			End If
		Next
		Return n
	End Function
	Private Sub GetServers(ByVal n As Nodes)
		For Each cptr As IRCNode In SubNodes
			If TypeOf cptr Is WinSECore.Server Then
				n.Add(cptr)
				DirectCast(cptr, WinSECore.Server).GetServers(n)
			End If
		Next
	End Sub
	Protected Overloads Overrides Sub Dispose(ByVal disposing As Boolean)
		Dim n As IRCNode
		If Not Parent Is Nothing AndAlso Parent.SubNodes.Contains(Me) Then
			Parent.SubNodes.Remove(Me)
			Parent = Nothing
		End If
		While SubNodes.Count > 0
			n = SubNodes(0)
			If TypeOf n Is Server Then
				c.Events.FireServerQuit(DirectCast(n, Server), "Lost in the netsplit")
			Else
				c.Events.FireClientQuit(DirectCast(n, User), "Lost in the netsplit")
			End If
			n.Dispose()
		End While
	End Sub
	Public Sub New(ByVal c As Core)
		MyBase.New(c)
	End Sub
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
	Public Status As String = ""
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
	Public TS As Integer
	Public Topic As String, TopicWho As String, TopicTS As Integer
	Public ReadOnly Custom As New Hashtable
	Public ParamlessModes As String = ""
	Protected ReadOnly c As WinSECore.Core
	Public ReadOnly ParamedModes As New StringDictionary	'Key = modechar, value = modevalue
	Public ReadOnly ListModes As New ListModeTable	'Key = = modechar, value = StringCollection
	Public ReadOnly UserList As New Members
	Public ReadOnly Identifies As New Nodes	'Users who have identified as a founder.
	Public Sub New(ByVal c As Core)
		Me.c = c
	End Sub
	'FromSJOIN makes SetModes not whine about invalid users and just ignore them. Why do we need to do that?
	'Well recall that SJOIN will be a combinition of joining and modeing. A user that joins in SJOIN could
	'get kicked in response by ChanServ, but then the mode portion of SJOIN is parsed which may send info about
	'an invalid user. We would normally complain. FromSJOIN will make this see that invalid users could have been
	'recently joined and subsequently kicked.
	Public Sub SetModes(ByVal Source As IRCNode, ByVal ModeChange As String, Optional ByVal FromSJOIN As Boolean = False)
		Dim bSet As Boolean
		Dim ch As Char, acptr As ChannelMember, sTmp As String
		Dim mode() As String = Split(ModeChange, " ")
		Dim validmodes() As String = Split(c.protocol.ChanModes, ",")
		For iParam As Integer = 0 To UBound(mode)
			bSet = True
			If IsNumeric(mode(iParam)) Then
				c.Events.FireLogMessage("Protocol", "NOTICE", "Hmmm, mode list appears to contain a timestamp.")
				'Since this should only ever be the last parameter, we can probably break here.
				Return
			End If
			sTmp = mode(iParam)
			For idx As Integer = 0 To sTmp.Length - 1
				ch = sTmp.Chars(idx)
				If ch = "+"c Then
					bSet = True
				ElseIf ch = "-"c Then
					bSet = False
				ElseIf validmodes(0).IndexOf(ch) >= 0 Then
					'Status mode. Parameter names a valid user (or at least, it should
					iParam += 1
					If iParam > UBound(mode) Then
						c.Events.FireLogMessage("Protocol", "ERROR", String.Format("Missing parameter for Status Mode {0} (MODE {1} {2})", ch, Name, ModeChange))
					ElseIf Not UserList.Contains(mode(iParam)) Then
						If Not FromSJOIN Then
							c.Events.FireLogMessage("Protocol", "ERROR", String.Format("Non-existant user (or user not in channel) for Status Mode {0} (MODE {1} {2})", ch, Name, ModeChange))
						End If
					Else
						acptr = UserList(mode(iParam))
						If bSet AndAlso acptr.Status.IndexOf(ch) < 0 Then
							acptr.Status += ch
						ElseIf (Not bSet) AndAlso acptr.Status.IndexOf(ch) >= 0 Then
							acptr.Status = acptr.Status.Replace(ch.ToString(), "")
						End If
						c.Events.FireChannelStatusChange(Source, Me, ch, acptr, bSet)
					End If
				ElseIf validmodes(1).IndexOf(ch) >= 0 Then
					'List mode.
					iParam += 1
					If iParam > UBound(mode) Then
						c.Events.FireLogMessage("Protocol", "ERROR", String.Format("Missing parameter for List Mode {0} (MODE {1} {2})", ch, Name, ModeChange))
					Else
						If Not ListModes.Contains(ch) Then
							ListModes.Add(ch)
						End If
						If bSet AndAlso Not ListModes(ch).Contains(mode(iParam)) Then
							ListModes(ch).Add(mode(iParam))
						ElseIf (Not bSet) AndAlso ListModes(ch).Contains(mode(iParam)) Then
							ListModes(ch).Remove(mode(iParam))
						End If
						c.Events.FireChannelListChange(Source, Me, ch, mode(iParam), bSet)
					End If
				ElseIf validmodes(2).IndexOf(ch) >= 0 Then
					'Parametered Mode. Take parameter even when unsetting.
					iParam += 1
					If bSet Then
						If iParam > UBound(mode) Then
							c.Events.FireLogMessage("Protocol", "ERROR", String.Format("Missing parameter for Mode {0} (MODE {1} {2})", ch, Name, ModeChange))
						ElseIf ParamedModes.ContainsKey(ch) Then
							ParamedModes(ch) = mode(iParam)
						Else
							ParamedModes.Add(ch, mode(iParam))
						End If
					Else
						'We don't care about the parameter, we just have to eat it.
						If ParamedModes.ContainsKey(ch) Then
							ParamedModes.Remove(ch)
						End If
					End If
				ElseIf validmodes(3).IndexOf(ch) >= 0 Then
					'Parametered mode. Don't take parameter when unsetting.
					If bSet Then
						'Eat parameter only when +.
						iParam += 1
						If iParam > UBound(mode) Then
							c.Events.FireLogMessage("Protocol", "ERROR", String.Format("Missing parameter for Mode {0} (MODE {1} {2})", ch, Name, ModeChange))
						ElseIf ParamedModes.ContainsKey(ch) Then
							ParamedModes(ch) = mode(iParam)
						Else
							ParamedModes.Add(ch, mode(iParam))
						End If
					Else
						If ParamedModes.ContainsKey(ch) Then
							ParamedModes.Remove(ch)
						End If
					End If
				ElseIf validmodes(4).IndexOf(ch) >= 0 Then
					'Paramless mode.
					If bSet AndAlso ParamlessModes.IndexOf(ch) < 0 Then
						ParamlessModes += ch
					ElseIf (Not bSet) AndAlso ParamlessModes.IndexOf(ch) >= 0 Then
						ParamlessModes = ParamlessModes.Replace(ch.ToString(), "")
					End If
				Else
					'EEEEEEEEEEEEEEEEEEEEEEEEK!
					c.Events.FireLogMessage("Protocol", "ERROR", String.Format("Unknown MODE character {0} (MODE {1} {2}) (Assuming Type D)", ch, Name, ModeChange))
					If bSet AndAlso ParamlessModes.IndexOf(ch) < 0 Then
						ParamlessModes += ch
					ElseIf (Not bSet) AndAlso ParamlessModes.IndexOf(ch) >= 0 Then
						ParamlessModes = ParamlessModes.Replace(ch.ToString(), "")
					End If
				End If
			Next
		Next
	End Sub
	Public Sub SendModes(ByVal Source As IRCNode, ByVal ModeChange As String)
		c.protocol.SetChMode(Source, Name, ModeChange)
		SetModes(Source, ModeChange)
	End Sub
	Public Sub KickUser(ByVal Source As IRCNode, ByVal Victim As User, ByVal Reason As String)
		c.protocol.KickUser(Source, Name, Victim.Name, Reason)
		c.Events.FireClientKicked(Source, Me, Victim, Reason)
	End Sub
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
			If DirectCast(a(idx), Channel).Name = name Then Return idx
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

Public NotInheritable Class IRCBan
	Public Mask As String
	Public ExpireTS As Long
	Public Reason As String
End Class

Public NotInheritable Class Bans
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
		Return Add(DirectCast(value, IRCBan))
	End Function
	Public Function Add(ByVal value As IRCBan) As Integer
		Return a.Add(value)
	End Function
	Public Sub Clear() Implements System.Collections.IList.Clear
		a.Clear()
	End Sub
	Private Function Contains2(ByVal value As Object) As Boolean Implements System.Collections.IList.Contains
		Return Contains(DirectCast(value, IRCBan))
	End Function
	Public Overloads Function Contains(ByVal value As IRCBan) As Boolean
		Return a.Contains(value)
	End Function
	Public Overloads Function Contains(ByVal mask As String) As Boolean
		Return IndexOf(mask) >= 0
	End Function
	Private Function IndexOf2(ByVal value As Object) As Integer Implements System.Collections.IList.IndexOf
		Return IndexOf(DirectCast(value, IRCBan))
	End Function
	Public Overloads Function IndexOf(ByVal value As IRCBan) As Integer
		Return a.IndexOf(value)
	End Function
	Public Overloads Function IndexOf(ByVal mask As String) As Integer
		For idx As Integer = 0 To a.Count - 1
			If DirectCast(a(idx), IRCBan).Mask = mask Then Return idx
		Next
		Return -1
	End Function
	Private Sub Insert2(ByVal index As Integer, ByVal value As Object) Implements System.Collections.IList.Insert
		Insert(index, DirectCast(value, IRCBan))
	End Sub
	Public Sub Insert(ByVal index As Integer, ByVal value As IRCBan)
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
			Item(index) = DirectCast(Value, IRCBan)
		End Set
	End Property
	Default Public Overloads Property Item(ByVal index As Integer) As IRCBan
		Get
			Return DirectCast(a(index), IRCBan)
		End Get
		Set(ByVal Value As IRCBan)
			a(index) = Value
		End Set
	End Property
	Default Public Overloads ReadOnly Property Item(ByVal mask As String) As IRCBan
		Get
			Dim idx As Integer = IndexOf(mask)
			If idx < 0 Then Throw New IndexOutOfRangeException("Object not found")
			Return Item(idx)
		End Get
	End Property
	Private Sub Remove2(ByVal value As Object) Implements System.Collections.IList.Remove
		Remove(DirectCast(value, IRCBan))
	End Sub
	Public Sub Remove(ByVal value As IRCBan)
		a.Remove(value)
	End Sub
	Public Sub RemoveAt(ByVal index As Integer) Implements System.Collections.IList.RemoveAt
		a.RemoveAt(index)
	End Sub
	Public Function FindBan(ByVal check As String) As IRCBan
		For Each b As IRCBan In Me
			If API.IsMatch(check, b.Mask) Then Return b
		Next
		Return Nothing
	End Function
	Public Sub RemoveExpiredBans(ByVal ts As Integer)
		Dim idx As Integer = 0
		While idx <= Count()
			If Me(idx).ExpireTS <= ts Then
				RemoveAt(idx)
			Else
				idx += 1
			End If
		End While
	End Sub
End Class
