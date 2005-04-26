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
Public NotInheritable Class NickServ
	Inherits WinSECore.Module
	Dim sc As WinSECore.ServiceClient
	Private t As WinSECore.Table
	Public Sub New(ByVal c As WinSECore.Core)
		MyBase.New(c)
		sc = New WinSECore.ServiceClient
		sc.Nick = "NickServ"
		sc.Ident = "nickname"
		sc.Host = c.Conf.ServerName
		sc.RealName = "Nickname Registration Services"
		sc.Usermode = c.protocol.ServiceUMode()
		sc.mainproc = AddressOf Me.NickServMain
		sc.CmdHash.Add("HELP", AddressOf CmdHelp)
		sc.CmdHash.Add("REGISTER", AddressOf CmdRegister)
		sc.CmdHash.Add("IDENTIFY", AddressOf CmdIdentify)
	End Sub
	Public Overrides Function ModLoad(ByVal params() As String) As Boolean
		c.Clients.Add(sc)
		AddHandler c.Events.ClientConnect, AddressOf OnClientConnect
		AddHandler c.Events.ClientNickChange, AddressOf OnClientNickChange
		Return True
	End Function
	Public Overrides Sub ModUnload()
		c.Clients.Remove(sc)
		RemoveHandler c.Events.ClientConnect, AddressOf OnClientConnect
		RemoveHandler c.Events.ClientNickChange, AddressOf OnClientNickChange
	End Sub
	Public Overrides Function LoadDatabase() As Boolean
		With c.db
			If .Contains("nickserv") Then
				t = .Item("nickserv")
			Else
				t = .Item(.Add("nickserv"))
			End If
		End With
		For Each r As WinSECore.Record In t
			With r
				If Not .Contains("Password") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing Password.")
					r.Name = ""
				ElseIf Not .Contains("EMail") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing EMail.")
					r.Name = ""
				ElseIf Not .Contains("LastAddress") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing LastAddress.")
					r.Name = ""
				ElseIf Not .Contains("LastQuit") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing LastQuit.")
					r.Name = ""
				ElseIf Not .Contains("AccessList") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing AccessList.")
					r.Name = ""
				ElseIf Not .Contains("LastSeenTime") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing LastSeenTime.")
					r.Name = ""
				ElseIf Not .Contains("Aliases") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing Aliases.")
					r.Name = ""
				ElseIf Not .Contains("Flags") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing Flags.")
					r.Name = ""
				ElseIf Not .Contains("Greet") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing Greet.")
					r.Name = ""
				ElseIf Not .Contains("Private") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing Private.")
					r.Name = ""
				ElseIf Not .Contains("HideQuit") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing HideQuit.")
					r.Name = ""
				ElseIf Not .Contains("HideEMail") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing HideEMail.")
					r.Name = ""
				ElseIf Not .Contains("HideAddress") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing HideAddress.")
					r.Name = ""
				ElseIf Not .Contains("NoAOP") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing NoAOP.")
					r.Name = ""
				ElseIf Not .Contains("VHost") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing VHost.")
					r.Name = ""
				ElseIf Not .Contains("AbuseTeam") Then
					c.Events.FireLogMessage("NickServ.Database", "WARNING", "Record " & r.Name & " invalid: missing AbuseTeam.")
					r.Name = ""
				End If
				If .GetField("Password") Is Nothing Then
					.SetField("Password", "")
				ElseIf Not TypeOf .GetField("Password") Is String Then
					.SetField("Password", .GetField("Password").ToString())
				End If
				If .GetField("EMail") Is Nothing Then
					.SetField("EMail", "")
				ElseIf Not TypeOf .GetField("EMail") Is String Then
					.SetField("EMail", .GetField("EMail").ToString())
				End If
				If .GetField("LastAddress") Is Nothing Then
					.SetField("LastAddress", "")
				ElseIf Not TypeOf .GetField("LastAddress") Is String Then
					.SetField("LastAddress", .GetField("LastAddress").ToString())
				End If
				If .GetField("LastQuit") Is Nothing Then
					.SetField("LastQuit", "")
				ElseIf Not TypeOf .GetField("LastQuit") Is String Then
					.SetField("LastQuit", .GetField("LastQuit").ToString())
				End If
				If .GetField("AccessList") Is Nothing Then
					.SetField("AccessList", "")
				ElseIf Not TypeOf .GetField("AccessList") Is String Then
					.SetField("AccessList", "")
				Else
					.SetField("AccessList", DirectCast(.GetField("AccessList"), String))
				End If
				If .GetField("LastSeenTime") Is Nothing Then
					.SetField("LastSeenTime", 0)
				ElseIf IsNumeric(.GetField("LastSeenTime")) Then
					.SetField("LastSeenTime", CInt(.GetField("LastSeenTime")))
				Else
					.SetField("LastSeenTime", 0)
				End If
				If .GetField("Aliases") Is Nothing Then
					.SetField("Aliases", "")
				ElseIf Not TypeOf .GetField("Aliases") Is String Then
					.SetField("Aliases", "")
				Else
					.SetField("Aliases", DirectCast(.GetField("Aliases"), String))
				End If
				If .GetField("Flags") Is Nothing Then
					.SetField("Flags", "")
				ElseIf Not TypeOf .GetField("Flags") Is String Then
					.SetField("Flags", .GetField("Flags").ToString())
				End If
				If r.Name = c.Conf.MasterNick Then
					If CStr(.GetField("Flags")).IndexOf(c.FLAG_Master) < 0 Then
						.SetField("Flags", .GetField("Flags").ToString() & c.FLAG_Master)
					End If
				End If
				If .GetField("Greet") Is Nothing Then
					.SetField("Greet", "")
				ElseIf Not TypeOf .GetField("Greet") Is String Then
					.SetField("Greet", .GetField("Greet").ToString())
				End If
				If .GetField("Private") Is Nothing Then
					.SetField("Private", False)
				ElseIf IsNumeric(.GetField("Private")) Then
					.SetField("Private", CBool(.GetField("Private")))
				Else
					.SetField("Private", False)
				End If
				If .GetField("HideQuit") Is Nothing Then
					.SetField("HideQuit", False)
				ElseIf IsNumeric(.GetField("HideQuit")) Then
					.SetField("HideQuit", CBool(.GetField("HideQuit")))
				Else
					.SetField("HideQuit", False)
				End If
				If .GetField("HideEMail") Is Nothing Then
					.SetField("HideEMail", False)
				ElseIf IsNumeric(.GetField("HideEMail")) Then
					.SetField("HideEMail", CBool(.GetField("HideEMail")))
				Else
					.SetField("HideEMail", False)
				End If
				If .GetField("HideAddress") Is Nothing Then
					.SetField("HideAddress", False)
				ElseIf IsNumeric(.GetField("HideAddress")) Then
					.SetField("HideAddress", CBool(.GetField("HideAddress")))
				Else
					.SetField("HideAddress", False)
				End If
				If .GetField("NoAOP") Is Nothing Then
					.SetField("NoAOP", False)
				ElseIf IsNumeric(.GetField("NoAOP")) Then
					.SetField("NoAOP", CBool(.GetField("NoAOP")))
				Else
					.SetField("NoAOP", False)
				End If
				If .GetField("VHost") Is Nothing Then
					.SetField("VHost", "")
				ElseIf Not TypeOf .GetField("VHost") Is String Then
					.SetField("VHost", .GetField("VHost").ToString())
				End If
				If .GetField("AbuseTeam") Is Nothing Then
					.SetField("AbuseTeam", False)
				ElseIf IsNumeric(.GetField("AbuseTeam")) Then
					.SetField("AbuseTeam", CBool(.GetField("AbuseTeam")))
				Else
					.SetField("AbuseTeam", False)
				End If
			End With
		Next
		Dim idx As Integer = 0
		While idx < t.Count - 1
			While t(idx).Name = ""
				t.RemoveAt(idx)
			End While
			idx += 1
		End While
		Return True
	End Function
	Public Sub NickServMain(ByVal Source As WinSECore.IRCNode, ByVal Message As String)
		If Not TypeOf Source Is WinSECore.User Then Return
		Try
			c.API.ExecCommand(sc.CmdHash, DirectCast(Source, WinSECore.User), Message)
		Catch ex As MissingMethodException
			DirectCast(Source, WinSECore.User).SendMessage(sc.node, DirectCast(Source, WinSECore.User), "Unknown command. Type " & WinSECore.API.FORMAT_BOLD & "/msg " & sc.node.Nick & " HELP" & WinSECore.API.FORMAT_BOLD & " for help.")
		End Try
	End Sub

	'DB Access stuff.
	Public Overloads Function FindRecord(ByVal nick As String, ByVal aliases As Boolean) As WinSECore.Record
		If nick = "" Then Return Nothing
		For Each r As WinSECore.Record In t
			If r.Name = nick Then Return r
			If aliases Then
				For Each s As String In Split(CStr(r("Aliases").Value), " ")
					If s = nick Then Return r
				Next
			End If
		Next
		Return Nothing
	End Function
	Public Overloads Function FindRecord(ByVal nick As WinSECore.User, ByVal aliases As Boolean) As WinSECore.Record
		Return FindRecord(nick.Nick, aliases)
	End Function

	'Callbacks go below here.
	Private Function CmdHelp(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean
		c.API.SendHelp(sc.node, Source, "NickServ", Args)
	End Function
	Private Function CmdRegister(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean
		'SYNTAX: REGISTER password email
		Dim r As WinSECore.Record
		If Args.Length < 2 Then
			Source.SendMessage(sc.node, Source, "Syntax: " & WinSECore.API.FORMAT_BOLD & "REGISTER " & WinSECore.API.FORMAT_UNDERLINE & "password" & WinSECore.API.FORMAT_UNDERLINE & " " & WinSECore.API.FORMAT_UNDERLINE & "email" & WinSECore.API.FORMAT_UNDERLINE & WinSECore.API.FORMAT_BOLD)
			Return False
		End If
		'Do some password sanity validation.
		If Len(Args(0)) < 4 Then
			Source.SendMessage(sc.node, Source, "Minimum password length is 4 characters.")
			Return False
		End If
		If Not Args(1) Like "?*@?*.?*" Then
			Source.SendMessage(sc.node, Source, "Invalid E-Mail address (format is user@domain.tld).")
			Return False
		End If
		r = FindRecord(Source, True)
		If Not r Is Nothing Then
			Source.SendMessage(sc.node, Source, "The nick you are using is already registered. If it is yours, type " & WinSECore.API.FORMAT_BOLD & "/msg " & sc.node.Nick & " IDENTIFY " & WinSECore.API.FORMAT_UNDERLINE & "password" & WinSECore.API.FORMAT_UNDERLINE & WinSECore.API.FORMAT_BOLD & ".")
			Return False
		End If
		If Source.Nick = c.Conf.MasterNick AndAlso Not c.protocol.IsIRCop(Source) Then
			Source.SendMessage(sc.node, Source, "You must be an IRCop to register the Master Nick.")
			Return False
		End If
		If Source.IdentifiedNick <> "" AndAlso (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.QUIRK_IDENTIFY_NO_LOGOUT) <> 0 Then
			Source.SendMessage(sc.node, Source, "Due to server limitations, you can only identify once per session. Please disconnect and reconnect and try again.")
			Return False
		End If
		r = New WinSECore.Record(Source.Nick)
		With r
			.SetField("Password", Args(0))
			.SetField("EMail", Args(1))
			.SetField("LastAddress", "")
			.SetField("LastQuit", "")
			.SetField("AccessList", WinSECore.API.Mask(String.Format("{0}!{1}@{2}", Source.Nick, IIf(Source.Username.StartsWith("~"), Source.Username.Substring(2), Source.Username), Source.Hostname), 3))
			.SetField("LastSeenTime", 0)
			.SetField("Aliases", "")
			.SetField("Flags", "")
			.SetField("Greet", "")
			.SetField("Private", False)
			.SetField("HideQuit", False)
			.SetField("HideEmail", False)
			.SetField("HideAddress", False)
			.SetField("NoAOP", False)
			.SetField("VHost", "")
			.SetField("AbuseTeam", False)
		End With
		t.Add(r)
		Source.SendMessage(sc.node, Source, "Your nick has been registered. Please remember your password for future connections, and use " & WinSECore.API.FORMAT_BOLD & "/msg " & sc.Nick & " IDENTIFY " & WinSECore.API.FORMAT_UNDERLINE & "password" & WinSECore.API.FORMAT_UNDERLINE & WinSECore.API.FORMAT_BOLD & " to identify yourself.")
		If Source.IdentifiedNick <> "" AndAlso (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.QUIRK_IDENTIFY_NO_LOGOUT) <> 0 Then
			Source.SendMessage(sc.node, Source, "Due to server limitations, you can only identify once per session. You will have to disconnect and reconnect to begin using this nick.")
		Else
			Source.IdentifiedNick = r.Name
			Source.AbuseTeam = False
			Source.Flags = ""
			If Source.Nick = c.Conf.MasterNick Then
				r.SetField("Flags", CStr(c.FLAG_Master))
				Source.SendMessage(sc.node, Source, "*** POOF ~ You are now a " & WinSECore.API.FORMAT_BOLD & "Services Master" & WinSECore.API.FORMAT_BOLD & ".")
				Source.SetFlags("+" & c.FLAG_Master)
			End If
			c.protocol.SetIdentify(sc.node, Source.Name, Source.IdentifiedNick)
		End If
	End Function
	Private Function CmdIdentify(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean
		'SYNTAX: IDENTIFY [nick] password
		Dim r As WinSECore.Record
		If Args.Length < 1 Then
			Source.SendMessage(sc.node, Source, "Syntax: " & WinSECore.API.FORMAT_BOLD & "IDENTIFY [" & WinSECore.API.FORMAT_UNDERLINE & "nickname" & WinSECore.API.FORMAT_UNDERLINE & "] " & WinSECore.API.FORMAT_UNDERLINE & "password" & WinSECore.API.FORMAT_UNDERLINE & WinSECore.API.FORMAT_BOLD)
			Return False
		End If
		If Source.IdentifiedNick <> "" AndAlso (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.QUIRK_IDENTIFY_NO_LOGOUT) <> 0 Then
			Source.SendMessage(sc.node, Source, "Due to server limitations, you can only identify once per session. Please disconnect and reconnect and try again.")
			Return False
		End If
		If Args.Length > 1 Then
			r = FindRecord(Args(0), True)
			If r Is Nothing Then
				Source.SendMessage(sc.node, Source, "Nick " & WinSECore.API.FORMAT_BOLD & Args(0) & WinSECore.API.FORMAT_BOLD & " is not registered.")
			ElseIf DirectCast(r("Password").Value, String) = "" Then
				Source.SendMessage(sc.node, Source, "Nick " & WinSECore.API.FORMAT_BOLD & Args(0) & WinSECore.API.FORMAT_BOLD & " may not be used.")
			ElseIf Args(1) <> DirectCast(r("Password").Value, String) Then
				Source.SendMessage(sc.node, Source, "Password incorrect.")
			Else
				Source.IdentifiedNick = r.Name
				Source.AbuseTeam = DirectCast(r("AbuseTeam").Value, Boolean)
				Source.Flags = DirectCast(r("Flags").Value, String)
				c.protocol.SetIdentify(sc.node, Source.Name, Source.IdentifiedNick)
				If r Is FindRecord(Source.Nick, True) Then
					If Source.Custom.ContainsKey("nicktimer") Then
						c.API.KillTimer(DirectCast(Source.Custom("nicktimer"), WinSECore.Timer))
						Source.Custom.Remove("nicktimer")
					End If
				End If
				Source.SendMessage(sc.node, Source, "Password accepted for nick " & WinSECore.API.FORMAT_BOLD & Args(0) & WinSECore.API.FORMAT_BOLD)
				End If
		Else
			r = FindRecord(Source.Nick, True)
			If r Is Nothing Then
				Source.SendMessage(sc.node, Source, "Nick " & WinSECore.API.FORMAT_BOLD & Source.Nick & WinSECore.API.FORMAT_BOLD & " is not registered.")
			ElseIf DirectCast(r("Password").Value, String) = "" Then
				Source.SendMessage(sc.node, Source, "Nick " & WinSECore.API.FORMAT_BOLD & Source.Nick & WinSECore.API.FORMAT_BOLD & " may not be used.")
			ElseIf Args(0) <> DirectCast(r("Password").Value, String) Then
				Source.SendMessage(sc.node, Source, "Password incorrect.")
			Else
				Source.IdentifiedNick = r.Name
				Source.AbuseTeam = DirectCast(r("AbuseTeam").Value, Boolean)
				Source.Flags = DirectCast(r("Flags").Value, String)
				c.protocol.SetIdentify(sc.node, Source.Name, Source.IdentifiedNick)
				'If there's a kill timer pending, kill it.
				If Source.Custom.ContainsKey("nicktimer") Then
					c.API.KillTimer(DirectCast(Source.Custom("nicktimer"), WinSECore.Timer))
					Source.Custom.Remove("nicktimer")
				End If
				Source.SendMessage(sc.node, Source, "Password accepted for nick " & WinSECore.API.FORMAT_BOLD & Source.Name & WinSECore.API.FORMAT_BOLD)
			End If
		End If
	End Function
	Private Sub OnClientConnect(ByVal cptr As WinSECore.Server, ByVal sptr As WinSECore.User)
		c.protocol.SetIdentify(sc.node, sptr.Nick, "")
		BeginEnforce(sptr)
	End Sub
	Private Sub OnClientNickChange(ByVal sptr As WinSECore.User, ByVal oldnick As String, ByVal nick As String)
		Dim rUsing As WinSECore.Record, rIdent As WinSECore.Record
		rUsing = FindRecord(sptr, True)
		rIdent = FindRecord(sptr.IdentifiedNick, True)
		If rUsing Is Nothing OrElse rIdent Is Nothing Then
			c.protocol.SetIdentify(sc.node, sptr.Nick, "")
		ElseIf rUsing Is rIdent Then
			c.protocol.SetIdentify(sc.node, sptr.Name, sptr.IdentifiedNick)
		End If
		If LCase(oldnick) <> LCase(nick) Then BeginEnforce(sptr)
	End Sub
	Private Sub BeginEnforce(ByVal who As WinSECore.User)
		Dim rUsing As WinSECore.Record, rIdent As WinSECore.Record
		rUsing = FindRecord(who, True)
		rIdent = FindRecord(who.IdentifiedNick, True)
		If rUsing Is rIdent Then Return
		If rUsing Is Nothing Then Return
		Dim al() As String = Split(DirectCast(rUsing.GetField("AccessList"), String), " ")
		If DirectCast(rUsing("Password").Value, String) = "" Then
			who.SendMessage(sc.node, who, "Your nick is forbidden and may not be used.")
			EndEnforce(who)
			Return
		Else
			who.SendMessage(sc.node, who, "Your nick is registered and protected. If it is yours please type " & WinSECore.API.FORMAT_BOLD & "/msg " & sc.node.Name & " IDENTIFY " & WinSECore.API.FORMAT_UNDERLINE & "password" & WinSECore.API.FORMAT_UNDERLINE & WinSECore.API.FORMAT_BOLD & ". Otherwise, please choose a different nick.")
			For Each sMask As String In al
				If WinSECore.API.IsMatch(who, sMask) Then
					Return
				End If
			Next
			If (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.SUPPORT_USER_FORCENICK) <> 0 Then
				who.SendMessage(sc.node, who, "Your nick will be changed in 60 seconds if you do not comply.")
			Else
				who.SendMessage(sc.node, who, "You will be disconnected from the network in 60 seconds if you do not comply.")
			End If
			'20 second timeout done 3 times, so we can do stuff at the 40sec and 20sec left marks...
			who.Custom.Add("nicktimer", c.API.AddTimer(New TimeSpan(0, 0, 20), AddressOf EnforceTimer, 3, who))
		End If
	End Sub
	Private Sub EnforceTimer(ByVal t As WinSECore.Timer)
		'Since repeat count is decreased after our run.
		Dim who As WinSECore.User = DirectCast(t.Params(0), WinSECore.User)
		Select Case t.Repeat
			Case 3			 '40 sec left
				who.SendMessage(sc.node, who, "You now have 40 seconds to identify or change your nick. The nick you are using is owned by someone else.")
			Case 2			 '20 sec left
				If (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.SUPPORT_USER_FORCENICK) <> 0 Then
					who.SendMessage(sc.node, who, "You now have 20 seconds to identify or change your nick. If you do not comply, I will change your nick for you. This is your final warning.")
				Else
					who.SendMessage(sc.node, who, "You now have 20 seconds to identify or change your nick. If you do not comply, you will be disconnected from the network. This is your final warning.")
				End If
			Case 1			 'DO IT.
				who.SendMessage(sc.node, who, "This nick is registered and protected. You may not use it.")
				EndEnforce(who)
		End Select
	End Sub
	Private Sub EndEnforce(ByVal who As WinSECore.User)
		If (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.SUPPORT_USER_FORCENICK) <> 0 Then
			Dim oldnick As String = who.Nick, newnick As String = "Guest" & Int((999999 * Rnd()) + 1).ToString()
			who.SendMessage(sc.node, who, "Your nick is being changed to " & newnick & ".")
			c.protocol.ForceNick(sc.node, who.Nick, newnick)
			If (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.SUPPORT_HOLD_NICK) <> 0 Then
				c.protocol.SetNickHold(sc.node, oldnick, True)
			ElseIf (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.SUPPORT_TEMPBAN_NICKNAME) <> 0 Then
				c.protocol.AddNicknameBan(sc.node, oldnick, "Nick held for registered user", New TimeSpan(0, 0, 60))
			Else
				c.API.CreateClient(who.Nick, "enforcer", c.Services.Name, "Enforcer", c.protocol.EnforcerUMode())
				c.API.AddTimer(New TimeSpan(0, 0, 60), AddressOf RemoveEnforcer, 1, who.Nick)
			End If
		Else
			Dim oldnick As String = who.Nick
			who.SendMessage(sc.node, who, "You will now be disconnected from the network. Please reconnect with a different nick.")
			c.protocol.KillUser(sc.node, who.Nick, "This is a registered and protected nick. Please use a different nickname.")
			If (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.SUPPORT_HOLD_NICK) <> 0 Then
				c.protocol.SetNickHold(sc.node, oldnick, True)
			ElseIf (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.SUPPORT_TEMPBAN_NICKNAME) <> 0 Then
				c.protocol.AddNicknameBan(sc.node, oldnick, "Nick held for registered user", New TimeSpan(0, 0, 60))
			Else
				c.API.CreateClient(oldnick, "enforcer", c.Services.Name, "Enforcer", c.protocol.EnforcerUMode())
				c.API.AddTimer(New TimeSpan(0, 0, 60), AddressOf RemoveEnforcer, 1, who.Nick)
			End If
		End If
	End Sub
	Private Sub RemoveEnforcer(ByVal t As WinSECore.Timer)
		Dim n As String = DirectCast(t.Params(0), String)
		Dim cptr As WinSECore.IRCNode = c.API.FindNode(n, c.Services)
		If Not TypeOf cptr Is WinSECore.User Then Return
		If Not cptr Is Nothing Then
			c.protocol.QuitUser(DirectCast(cptr, WinSECore.User), "My work here is done...")
			cptr.Dispose()
		End If
	End Sub
End Class
