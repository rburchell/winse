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
Public NotInheritable Class API
	Private ReadOnly c As Core
	Friend Sub New(ByVal c As Core)
	End Sub
	'Invokes a service command routine from the given hashtable.
	'Exceptions thrown:
	'- None : No error occured - all commands executed normally.
	'- ArgumentNullException : The parameter named in the exception was passed a Null Reference.
	'- MissingMethodException : The command named in the exception description was not found in the hashtable.
	'- TargetInvocationException : A command method threw an exception, which is contained in the innerException.
	Public Sub ExecCommand(ByVal hash As CommandHash, ByVal sender As User, ByVal Command As String)
		Dim cmd As String = Split(Command, " ", 2)(0)
		Dim args() As String = Split(Split(Command, " ", 2)(1), " ")
		If hash Is Nothing Then Throw New ArgumentNullException("hash")
		If sender Is Nothing Then Throw New ArgumentNullException("sender")
		If Not hash.Contains(cmd) Then
			Throw New MissingMethodException(cmd)
		Else
			For idx As Integer = 0 To hash(cmd).Count - 1
				Try
					If Not hash(cmd)(idx)(sender, cmd, args) Then Exit For
				Catch ex As Exception
					Throw New System.Reflection.TargetInvocationException(ex)
				End Try
			Next
		End If
	End Sub
	Public Function GetServ() As String
		Static buffer As String
		Dim stmp As String, b() As Byte
		If c.sck.Poll(0, Net.Sockets.SelectMode.SelectRead) Then
			b = New Byte(c.sck.Available) {}
			c.sck.Receive(b)
			buffer += System.Text.Encoding.ASCII.GetString(b)
			'Easier to handle things with just LF as opposed to CRLF.
			buffer = Replace(buffer, vbCrLf, vbLf)
			buffer = Replace(buffer, vbCr, vbLf)
		End If
		If InStr(buffer, vbLf) > 0 Then
			stmp = Split(buffer, vbLf, 2)(0)
			buffer = Split(buffer, vbLf, 2)(1)
			Return stmp
		Else
			Return Nothing
		End If
	End Function
	Public Function GetServ(ByVal timeout As TimeSpan) As String
		'If it's 0 from the outset, assume it means infinite.
		Dim str As String
		If timeout.Equals(TimeSpan.Zero) Then
			Do While str Is Nothing
				str = GetServ()
			Loop
			Return str
		Else
			Dim dteEnd As Date = Now.Add(timeout)
			Do While str Is Nothing AndAlso Now < dteEnd
				str = GetServ()
			Loop
			Return str
		End If
	End Function
	Public Overloads Sub PutServ(ByVal buffer As String)
		Dim b() As Byte = System.Text.Encoding.ASCII.GetBytes(buffer & vbCrLf)
		c.sck.Send(b)
	End Sub
	Public Overloads Sub PutServ(ByVal format As String, ByVal ParamArray args() As Object)
		PutServ(String.Format(format, args))
	End Sub
	Public Shared Function FMod(ByVal dividend As Double, ByVal divisor As Double) As Double
		'Floating modulus. When the Mod operator doesn't help.
		'Essentially, a % b == ((a / b) - iPart(a / b)) * b
		FMod = ((dividend / divisor) - Fix(dividend / divisor)) * divisor
	End Function
	Public Shared Function Mask(ByVal NUH As String, ByVal MaskType As Integer) As String
		Dim n As String, u As String, h As String, d As String
		If InStr(NUH, "!") = 0 Or InStr(NUH, "@") = 0 Or InStr(NUH, "!") >= InStr(NUH, "@") Then Error 5
		n = Left(NUH, InStr(NUH, "!") - 1)
		NUH = Mid(NUH, InStr(NUH, "!") + 1)
		u = Left(NUH, InStr(NUH, "@") - 1)
		h = Mid(NUH, InStr(NUH, "@") + 1)
		If Left(u, 1) = "~" Then u = Mid(u, 2)
		'Get the domain based on these rules:
		'If the hostname is an Numeric IP Address, use the first 3 octets.
		'If the hostname has 2 or less parts, use the entire hostname.
		'If the hostname has 5 or more parts, use only the top 4.
		'Otherwise, use all but the bottom domain.
		Dim hs() As String
		hs = Split(h, ".")
		If UBound(hs) <= 2 Then
			'Examples:
			'localhost (not masked)
			'mydomain.com (not masked)
			d = h
		ElseIf UBound(hs) = 3 Then
			'Examples:
			'mymachine.mydomain.com (masked as *.mydomain.com)
			d = "*." + Split(h, ".", 2)(1)
		ElseIf UBound(hs) = 4 And IsNumeric(hs(0)) And IsNumeric(hs(1)) And IsNumeric(hs(2)) And IsNumeric(hs(3)) Then
			'IPv4 ADDRESS!!!
			'Examples:
			'127.0.0.1 (masked as 127.0.0.* - maybe soon it will be masked as 127.0.0.0/24)
			d = hs(0) + "." + hs(1) + "." + hs(2) + ".*"
		ElseIf UBound(hs) = 4 Then
			'Examples:
			'localhost.127.in-addr.arpa (masked as *.in-addr.arpa)
			d = "*." + Split(h, ".", 2)(1)
		ElseIf UBound(hs) >= 5 Then
			'my.isp.gives.me.really.long.hosts.like.this (masked as *.long.hosts.like.this)
			d = "*." + hs(UBound(hs) - 3) + "." + hs(UBound(hs) - 2) + "." + hs(UBound(hs) - 1) + "." + hs(UBound(hs))
		End If
		Select Case MaskType Mod 10
			Case 0			 '*!user@host.domain
				Return "*!" + u + "@" + h
			Case 1			 '*!*user@host.domain
				Return "*!*" + u + "@" + h
			Case 2			 '*!*@host.domain
				Return "*!*@" + h
			Case 3			 '*!*user@*.domain
				Return "*!*" + u + "@" + d
			Case 4			 '*!*@*.domain
				Return "*!*@" + d
			Case 5			 'nick!user@host.domain
				Return n + "!" + u + "@" + h
			Case 6			 'nick!*user@host.domain
				Return n + "!*" + u + "@" + h
			Case 7			 'nick!*@host.domain
				Return n + "!*@" + h
			Case 8			 'nick!*user@*.domain
				Return n + "!*" + u + "@" + d
			Case 9			 'nick!*@*.domain
				Return n + "!*@" + d
		End Select
	End Function
	Public Shared Function ExtractNickFromNUH(ByVal Prefix As String) As String
		If InStr(Prefix, "!") = 0 Then
			If InStr(Prefix, "@") = 0 Then
				Return Prefix
			Else
				Return Left(Prefix, InStr(Prefix, "@") - 1)
			End If
		Else
			Return Left(Prefix, InStr(Prefix, "!") - 1)
		End If
	End Function
	Public Shared Function Duration(ByVal dur As String) As Integer
		'Takes a string like this: 1d2h3m4s and returns the number of seconds.
		'The exact format could be described with a regular expression:
		'([0-9]+([dD]|[hH]|[mM]|[sS]))+
		Dim secs As Integer, stmp As String
		Dim idx As Integer, ch As Char
		For idx = 1 To Len(dur)
			ch = dur.Chars(idx - 1)
			Select Case ch
				Case "0"c To "9"c
					stmp = stmp & ch
				Case "d"c, "D"c
					If stmp = "" Then Throw New ArgumentException("Not a valid duration string (period specifier without quantity).", "dur")
					secs = secs + CInt(stmp) * 86400
					stmp = ""
				Case "h"c, "H"c
					If stmp = "" Then Throw New ArgumentException("Not a valid duration string (period specifier without quantity).", "dur")
					secs = secs + CInt(stmp) * 3600
					stmp = ""
				Case "m"c, "M"c
					If stmp = "" Then Throw New ArgumentException("Not a valid duration string (period specifier without quantity).", "dur")
					secs = secs + CInt(stmp) * 60
					stmp = ""
				Case "s"c, "S"c
					If stmp = "" Then Throw New ArgumentException("Not a valid duration string (period specifier without quantity).", "dur")
					secs = secs + CInt(stmp)
					stmp = ""
				Case Else
					Throw New ArgumentException("Not a valid duration string (invalid character '" + ch + "').", "dur")
			End Select
		Next idx
		If stmp <> "" Then secs = secs + CInt(stmp)
		Return secs
	End Function
	Public Shared Function UnDuration(ByVal dur As Integer) As String
		'Take Duration's output and converts into a string.
		Dim days As Integer, hours As Integer, mins As Integer, secs As Integer
		If dur < 0 Then Throw New ArgumentException("Invalid time specifier (negative).", "dur")
		days = (dur \ 86400)
		hours = (dur \ 3600) Mod 24
		mins = (dur \ 60) Mod 60
		secs = dur Mod 60
		UnDuration = IIf(days > 0, CStr(days) & "d", "").ToString & IIf(hours > 0, CStr(hours) & "h", "").ToString & IIf(mins > 0, CStr(mins) & "m", "").ToString & IIf(secs > 0, CStr(secs) & "s", "").ToString
	End Function
	Public Function FindNode(ByVal name As String) As IRCNode
		Dim n As IRCNode
		n = FindNode(name, c.ServicesMap)
		If n Is Nothing Then n = FindNode(name, c.IRCMap)
		Return n
	End Function
	Public Shared Function FindNode(ByVal needle As String, ByVal haystack As Server) As IRCNode
		If haystack.Name = needle Then Return haystack
		With haystack
			For Each n As IRCNode In haystack.SubNodes
				If TypeOf n Is Server Then
					Return FindNode(needle, DirectCast(n, Server))
				Else
					If needle = n.Name Then Return n
				End If
			Next
		End With
		Return Nothing
	End Function
	Public Overloads Shared Function GetTS() As Long
		Return GetTS(Now)
	End Function
	Public Overloads Shared Function GetTS(ByVal d As Date) As Long
		Return DateDiff(DateInterval.Second, New Date(1970, 1, 1, 0, 0, 0), d.ToUniversalTime)
	End Function
	Public Sub SendHelp(ByVal SendTo As User, ByVal Base As String, ByVal Args() As String)

	End Sub
End Class

Public NotInheritable Class Events
	'This should only be created within the WinSE module...
	Friend Sub New()
	End Sub
	'Fired when a message is Logged.
	'Facility is in the format: module.<operation> where operation is up to the module to decide.
	'Severity is any of the following:
	'FATAL - Used for Fatal Errors that require WinSE to shut down.
	'ERROR - Used for general errors.
	'WARNING - Used for things that could be bad.
	'NOTICE - Used for things like command usage, general alerts, etc.
	'DEBUG - Used for debugging messages. Use this type for showing variable contents, etc.
	'TRACE - Used for debugging messages. Use this type for tracing code paths.
	Public Event LogMessage(ByVal Facility As String, ByVal Severity As String, ByVal Message As String)
	Public Sub FireLogMessage(ByVal Facility As String, ByVal Severity As String, ByVal Message As String)
		RaiseEvent LogMessage(Facility, Severity, Message)
	End Sub
	'Fired when WinSE successfully estabilishes a connection.
	Public Event ServerInit()
	Public Sub FireServerInit()
		RaiseEvent ServerInit()
	End Sub
	'Fired when a raw message from the server is received.
	Public Event RawMsg(ByVal sptr As IRCNode, ByVal cmd As String, ByVal params() As String)
	Public Sub FireRawMsg(ByVal sptr As IRCNode, ByVal cmd As String, ByVal params() As String)
		RaiseEvent RawMsg(sptr, cmd, params)
	End Sub
	'Fired when user sptr is introduced to the network (behind cptr).
	Public Event ClientConnect(ByVal cptr As Server, ByVal sptr As User)
	Public Sub FireClientConnect(ByVal cptr As Server, ByVal sptr As User)
		RaiseEvent ClientConnect(cptr, sptr)
	End Sub
	'Fired when user sptr disconnects.
	Public Event ClientQuit(ByVal sptr As User, ByVal reason As String)
	Public Sub FireClientQuit(ByVal sptr As User, ByVal reason As String)
		RaiseEvent ClientQuit(sptr, reason)
	End Sub
	'Fired when user cptr is killed by sptr (ClientQuit fired afterwards...)
	Public Event ClientKilled(ByVal sptr As IRCNode, ByVal cptr As User, ByVal Reason As String)
	Public Sub FireClientKilled(ByVal sptr As IRCNode, ByVal cptr As User, ByVal Reason As String)
		RaiseEvent ClientKilled(sptr, cptr, Reason)
	End Sub
	'Fired when server sptr connects to the network.
	Public Event ServerConnect(ByVal sptr As Server, ByVal sptrIsBehindThisGuy As Server)
	Public Sub FireServerConnect(ByVal sptr As Server, ByVal sptrIsBehindThisGuy As Server)
		RaiseEvent ServerConnect(sptr, sptrIsBehindThisGuy)
	End Sub
	'Fired when a server quits. ClientQuit and ServerQuit will be called for each client and server under this server.
	Public Event ServerQuit(ByVal sptr As Server, ByVal reason As String)
	Public Sub FireServerQuit(ByVal sptr As Server, ByVal reason As String)
		RaiseEvent ServerQuit(sptr, reason)
	End Sub
	'Fired when a client changes his nickname.
	Public Event ClientNickChange(ByVal sptr As User, ByVal nick As String)
	Public Sub FireClientNickChange(ByVal sptr As User, ByVal nick As String)
		RaiseEvent ClientNickChange(sptr, nick)
	End Sub
	'Fired when a client joins a channel.
	Public Event ClientJoin(ByVal sptr As User, ByVal chptr As Channel)
	Public Sub FireClientJoin(ByVal sptr As User, ByVal chptr As Channel)
		RaiseEvent ClientJoin(sptr, chptr)
	End Sub
	'Fired when a client leaves a channel.
	Public Event ClientPart(ByVal sptr As User, ByVal chptr As Channel, ByVal reason As String)
	Public Sub FireClientPart(ByVal sptr As User, ByVal chptr As Channel, ByVal reason As String)
		RaiseEvent ClientPart(sptr, chptr, reason)
	End Sub
	'Fired when a client sends a message to the channel.
	Public Event ClientChannelMessage(ByVal sptr As User, ByVal chptr As Channel, ByVal msg As String)
	Public Sub FireClientChannelMessage(ByVal sptr As User, ByVal chptr As Channel, ByVal msg As String)
		RaiseEvent ClientChannelMessage(sptr, chptr, msg)
	End Sub
	'Fired when a client sends a message to users with the given status in the channel.
	Public Event ClientChannelPrefixMessage(ByVal sptr As User, ByVal chptr As Channel, ByVal prefix As Char, ByVal msg As String)
	Public Sub FireClientChannelPrefixMessage(ByVal sptr As User, ByVal chptr As Channel, ByVal prefix As Char, ByVal msg As String)
		RaiseEvent ClientChannelPrefixMessage(sptr, chptr, prefix, msg)
	End Sub
	'Fired when a user changes his usermodes (or they are forcefully changed by SVSMODE, etc).
	Public Event UserModeChange(ByVal Source As IRCNode, ByVal Who As User, ByVal Flag As Char, ByVal Setting As Boolean)
	Public Sub FireUserModeChange(ByVal Source As IRCNode, ByVal Who As User, ByVal Flag As Char, ByVal Setting As Boolean)
		RaiseEvent UserModeChange(Source, Who, Flag, Setting)
	End Sub
	'Fired when a channel list entry (+b, +e, +I, etc) is added or removed.
	Public Event ChannelListChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal List As Char, ByVal Entry As String, ByVal Add As Boolean)
	Public Sub FireChannelListChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal List As Char, ByVal Entry As String, ByVal Add As Boolean)
		RaiseEvent ChannelListChange(Source, Chan, List, Entry, Add)
	End Sub
	'Fired when a channel mode requiring a parameter (+l, +k) is modified.
	Public Event ChannelParamModeChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal Mode As Char, ByVal Param As String)
	Public Sub FireChannelParamModeChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal Mode As Char, ByVal Param As String)
		RaiseEvent ChannelParamModeChange(Source, Chan, Mode, Param)
	End Sub
	'Fired when a channel binary mode (+i, +m) is changed.
	Public Event ChannelFlagModeChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal Mode As Char, ByVal Setting As Boolean)
	Public Sub FireChannelFlagModeChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal Mode As Char, ByVal Setting As Boolean)
		RaiseEvent ChannelFlagModeChange(Source, Chan, Mode, Setting)
	End Sub
End Class