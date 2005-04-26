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

Public Class DebugServ
	Inherits WinSECore.Module
	Dim sc As WinSECore.ServiceClient
	Public Sub New(ByVal c As WinSECore.Core)
		MyBase.New(c)
		sc = New WinSECore.ServiceClient
		sc.Nick = "DebugServ"
		sc.Ident = "debug"
		sc.Host = c.Conf.ServerName
		sc.RealName = "Debugging Services"
		sc.Usermode = c.protocol.InvisServiceUMode()
		sc.mainproc = AddressOf Me.DebugServMain
		sc.CmdHash.Add("HELP", AddressOf CmdHelp)
		sc.CmdHash.Add("DUMPCLIENT", AddressOf CmdDumpClient)
		sc.CmdHash.Add("DUMPCHANNEL", AddressOf CmdDumpChannel)
		sc.CmdHash.Add("DIE", AddressOf CmdDie)
		sc.CmdHash.Add("TIMEDMSG", AddressOf CmdTimedMsg)
	End Sub
	Public Overrides Function ModLoad(ByVal params() As String) As Boolean
		c.Clients.Add(sc)
		Return True
	End Function
	Public Overrides Sub ModUnload()
		c.Clients.Remove(sc)
	End Sub
	Public Sub DebugServMain(ByVal Source As WinSECore.IRCNode, ByVal Message As String)
		If Not TypeOf Source Is WinSECore.User Then Return
		If Not c.protocol.IsIRCop(DirectCast(Source, WinSECore.User)) Then
			DirectCast(Source, WinSECore.User).SendMessage(sc.node, DirectCast(Source, WinSECore.User), "Access denied")
			Return
		End If
		Try
			c.API.ExecCommand(sc.CmdHash, DirectCast(Source, WinSECore.User), Message)
		Catch ex As MissingMethodException
			DirectCast(Source, WinSECore.User).SendMessage(sc.node, DirectCast(Source, WinSECore.User), "Unknown command. Type " & WinSECore.API.FORMAT_BOLD & "/msg " & sc.node.Nick & " HELP" & WinSECore.API.FORMAT_BOLD & " for help.")
		End Try
	End Sub
	Private Function CmdHelp(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean
		c.API.SendHelp(sc.node, Source, "DebugServ", Args)
	End Function
	Private Function CmdDie(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean
		c.Halt = WinSECore.Core.HaltCode.HALT_SHUTDOWN
	End Function
	Private Function CmdDumpClient(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean
		If Args.Length < 1 Then
			Source.SendMessage(sc.node, Source, "Syntax: " & WinSECore.API.FORMAT_BOLD & "DUMPCLIENT " & WinSECore.API.FORMAT_UNDERLINE & "nick" & WinSECore.API.FORMAT_UNDERLINE & WinSECore.API.FORMAT_BOLD)
			Return False
		End If
		Dim n As WinSECore.IRCNode
		n = c.API.FindNode(Args(0))
		If n Is Nothing Then
			Source.SendMessage(sc.node, Source, "Client " & WinSECore.API.FORMAT_BOLD & Args(0) & WinSECore.API.FORMAT_BOLD & " does not exist.")
			Return False
		End If
		If TypeOf n Is WinSECore.User Then
			With DirectCast(n, WinSECore.User)
				Source.SendMessage(sc.node, Source, "Nick: " & .Nick)
				Source.SendMessage(sc.node, Source, "Numeric: " & .Numeric)
				Source.SendMessage(sc.node, Source, "Username: " & .Username & DirectCast(IIf(.VIdent <> "" AndAlso .VIdent <> .Username, " => " & .VIdent, ""), String))
				Source.SendMessage(sc.node, Source, "Hostname: " & .Hostname & DirectCast(IIf(.VHost <> "" AndAlso .VHost <> .Hostname, " => " & .VHost, ""), String))
				Source.SendMessage(sc.node, Source, "IP Address: " & .IP.ToString())
				Source.SendMessage(sc.node, Source, "Realname: " & .RealName)
				Source.SendMessage(sc.node, Source, "Server: " & .Server.Name)
				Source.SendMessage(sc.node, Source, "Timestamp: " & .TS.ToString())
				Source.SendMessage(sc.node, Source, "Usermodes: " & .Usermodes)
				Source.SendMessage(sc.node, Source, "Flood Level: " & .Since)
				If .SWhois <> "" Then Source.SendMessage(sc.node, Source, "SWhoIs: " & .SWhois)
				Source.SendMessage(sc.node, Source, DirectCast(IIf(.AwayMessage <> "", "Away: " & .AwayMessage, "Away? No"), String))
				If .IdentifiedNick <> "" Then
					Source.SendMessage(sc.node, Source, "Identified to nicks: " & .IdentifiedNick)
				Else
					Source.SendMessage(sc.node, Source, "Not identified.")
				End If
				Source.SendMessage(sc.node, Source, "Abuse Team? " & DirectCast(IIf(.AbuseTeam, "Yes", "No"), String))
				Source.SendMessage(sc.node, Source, "Access Flags: " & .Flags)
				For Each chptr As WinSECore.Channel In .Channels
					Source.SendMessage(sc.node, Source, "On channel: " & chptr.Name)
				Next
				Try
					Source.SendMessage(sc.node, Source, "Send Method: " & .SendMessage.Method.DeclaringType.ToString() & "." & .SendMessage.Method.Name)
				Catch ex As Exception
				End Try
			End With
		ElseIf TypeOf n Is WinSECore.Server Then
			With DirectCast(n, WinSECore.Server)
				Source.SendMessage(sc.node, Source, "Name: " & .Name)
				Source.SendMessage(sc.node, Source, "Numeric: " & .Numeric)
				Source.SendMessage(sc.node, Source, "Description: " & .Info)
				If .Parent Is Nothing Then
					Source.SendMessage(sc.node, Source, "Uplink: Direct link")
				Else
					Source.SendMessage(sc.node, Source, "Uplink: " & .Parent.Name)
				End If
			End With
		End If
	End Function
	Private Function CmdDumpChannel(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean
		If Args.Length < 1 Then
			Source.SendMessage(sc.node, Source, "Syntax: " & WinSECore.API.FORMAT_BOLD & "DUMPCHANNEL " & WinSECore.API.FORMAT_UNDERLINE & "channel" & WinSECore.API.FORMAT_UNDERLINE & WinSECore.API.FORMAT_BOLD)
			Return False
		End If
		Dim chptr As WinSECore.Channel, idx As Integer
		idx = c.Channels.IndexOf(Args(0))
		If idx < 0 Then
			Source.SendMessage(sc.node, Source, "Channel " & WinSECore.API.FORMAT_BOLD & Args(0) & WinSECore.API.FORMAT_BOLD & " is empty.")
		Else
			chptr = c.Channels(idx)
			With chptr
				Source.SendMessage(sc.node, Source, "Name: " & chptr.Name)
				Source.SendMessage(sc.node, Source, "Topic: " & chptr.Topic)
				Source.SendMessage(sc.node, Source, "Set by " & chptr.TopicWho & " on " & Format(New Date(1970, 1, 1).AddSeconds(chptr.TopicTS).ToLocalTime, "dddd, mmmm dd, yyyy HH:mm:ss zzz"))
				Source.SendMessage(sc.node, Source, "Timestamp: " & chptr.TS)
				Source.SendMessage(sc.node, Source, "Binary Modes: " & chptr.ParamlessModes)
				For Each k As String In chptr.ParamedModes.Keys
					Source.SendMessage(sc.node, Source, "Mode +" & k & ": " & chptr.ParamedModes(k))
				Next
				For Each k As Char In chptr.ListModes.Keys
					Source.SendMessage(sc.node, Source, "List +" & k)
					For Each sEntry As String In chptr.ListModes(k)
						Source.SendMessage(sc.node, Source, "    " & sEntry)
					Next
					Source.SendMessage(sc.node, Source, "End list +" & k)
				Next
				Source.SendMessage(sc.node, Source, "Members:")
				For Each m As WinSECore.ChannelMember In chptr.UserList
					Source.SendMessage(sc.node, Source, "    " & m.Who.Name & " = +" & m.Status)
				Next
				Source.SendMessage(sc.node, Source, "End of members list")
				Source.SendMessage(sc.node, Source, "Identified users:")
				For Each n As WinSECore.IRCNode In chptr.Identifies
					Source.SendMessage(sc.node, Source, "    " & n.Name)
				Next
				Source.SendMessage(sc.node, Source, "End of identified users list")
				Source.SendMessage(sc.node, Source, "End dump for channel " & chptr.Name)
			End With
		End If
	End Function
	Private Function CmdTimedMsg(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean
		If Args.Length < 4 Then
			Source.SendMessage(sc.node, Source, "Syntax: " & WinSECore.API.FORMAT_BOLD & "TIMEDMSG " & WinSECore.API.FORMAT_UNDERLINE & "[nick|#channel]" & WinSECore.API.FORMAT_UNDERLINE & " " & WinSECore.API.FORMAT_UNDERLINE & "repeat" & WinSECore.API.FORMAT_UNDERLINE & " " & WinSECore.API.FORMAT_UNDERLINE & "delay" & WinSECore.API.FORMAT_UNDERLINE & " " & WinSECore.API.FORMAT_UNDERLINE & "message" & WinSECore.API.FORMAT_UNDERLINE & WinSECore.API.FORMAT_BOLD)
			Return False
		End If
		Dim target As String = Args(0)
		Dim repeat As Integer, interval As Integer, msg As String
		If Not IsNumeric(Args(1)) Then
			Source.SendMessage(sc.node, Source, "Invalid repeat count.")
			Source.SendMessage(sc.node, Source, "Syntax: " & WinSECore.API.FORMAT_BOLD & "TIMEDMSG " & WinSECore.API.FORMAT_UNDERLINE & "[nick|#channel]" & WinSECore.API.FORMAT_UNDERLINE & " " & WinSECore.API.FORMAT_UNDERLINE & "repeat" & WinSECore.API.FORMAT_UNDERLINE & " " & WinSECore.API.FORMAT_UNDERLINE & "delay" & WinSECore.API.FORMAT_UNDERLINE & " " & WinSECore.API.FORMAT_UNDERLINE & "message" & WinSECore.API.FORMAT_UNDERLINE & WinSECore.API.FORMAT_BOLD)
			Return False
		Else
			repeat = Integer.Parse(Args(1))
		End If
		If Not IsNumeric(Args(2)) Then
			Source.SendMessage(sc.node, Source, "Invalid delay.")
			Source.SendMessage(sc.node, Source, "Syntax: " & WinSECore.API.FORMAT_BOLD & "TIMEDMSG " & WinSECore.API.FORMAT_UNDERLINE & "[nick|#channel]" & WinSECore.API.FORMAT_UNDERLINE & " " & WinSECore.API.FORMAT_UNDERLINE & "repeat" & WinSECore.API.FORMAT_UNDERLINE & " " & WinSECore.API.FORMAT_UNDERLINE & "delay" & WinSECore.API.FORMAT_UNDERLINE & " " & WinSECore.API.FORMAT_UNDERLINE & "message" & WinSECore.API.FORMAT_UNDERLINE & WinSECore.API.FORMAT_BOLD)
			Return False
		Else
			interval = Integer.Parse(Args(2))
		End If
		msg = String.Join(" ", Args, 3, Args.Length - 3)
		c.API.AddTimer(New TimeSpan(0, 0, interval), AddressOf TimedMsgCB, repeat, target, msg)
	End Function
	Private Sub TimedMsgCB(ByVal t As WinSECore.Timer)
		Dim target As String, msg As String
		target = DirectCast(t.Params(0), String)
		msg = DirectCast(t.Params(1), String)
		Dim n As WinSECore.IRCNode, chptr As WinSECore.Channel
		n = c.API.FindNode(target)
		If n Is Nothing Then
			If c.Channels.Contains(target) Then
				chptr = c.Channels(target)
				c.protocol.SendMessage(sc.node, chptr, msg, True)
			End If
		ElseIf TypeOf n Is WinSECore.User Then
			c.protocol.SendMessage(sc.node, DirectCast(n, WinSECore.User), msg, True)
		End If
	End Sub
End Class
