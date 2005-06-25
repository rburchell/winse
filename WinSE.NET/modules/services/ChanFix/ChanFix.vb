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
Imports WinSECore.API
Public NotInheritable Class ChanFix
	Inherits WinSECore.Module
	Dim sc As WinSECore.ServiceClient
	Private t As WinSECore.Table
	Private tmr As WinSECore.Timer
	Private nMinUsers As Integer
	Private nMinChops As Integer
	Private nMinChopTime As Integer
	Private bDontRequireIdentd As Boolean = False
	Private nDataExpire As Integer = 14
	Private bEnableOpMe As Boolean = False
	Private bIgnoreTilde As Boolean = False
	Private bSmartTildeMatching As Boolean = False
	Private Structure CFOper
		Public LoginName As String
		Public Address() As String
		Public Password As String
		Public Permissions As String
	End Structure
	Private cfOpers() As CFOper

	Public Sub New(ByVal c As WinSECore.Core)
		MyBase.New(c)
		sc = New WinSECore.ServiceClient
		sc.Nick = "ChanFix"
		sc.Usermode = "chanfix"
		sc.Host = c.Conf.ServerName
		sc.RealName = "Channel Fixer"
		sc.Usermode = c.protocol.ServiceUMode()
		sc.mainproc = AddressOf ChanFixMain
		sc.CmdHash.Add("HELP", AddressOf CmdStub)
		sc.CmdHash.Add("CHANFIX", AddressOf CmdStub)
		sc.CmdHash.Add("OPNICKS", AddressOf CmdStub)
		sc.CmdHash.Add("SCORE", AddressOf CmdStub)
		sc.CmdHash.Add("CSCORE", AddressOf CmdStub)
		sc.CmdHash.Add("HISTORY", AddressOf CmdStub)
		sc.CmdHash.Add("OPLIST", AddressOf CmdStub)
		sc.CmdHash.Add("ADDNOTE", AddressOf CmdStub)
		sc.CmdHash.Add("DELNOTE", AddressOf CmdStub)
		sc.CmdHash.Add("ALERT", AddressOf CmdStub)
		sc.CmdHash.Add("UNALERT", AddressOf CmdStub)
		sc.CmdHash.Add("BLOCK", AddressOf CmdStub)
		sc.CmdHash.Add("UNBLOCK", AddressOf CmdStub)
		sc.CmdHash.Add("MODE", AddressOf CmdStub)
		sc.CmdHash.Add("KICK", AddressOf CmdStub)
		sc.CmdHash.Add("CLEAR", AddressOf CmdStub)
		sc.CmdHash.Add("FORGETCHAN", AddressOf CmdStub)
	End Sub
	Public Sub ChanFixMain(ByVal Source As WinSECore.IRCNode, ByVal Message As String)
		If Not TypeOf Source Is WinSECore.User Then Return
		Try
			c.API.ExecCommand(sc.CmdHash, DirectCast(Source, WinSECore.User), Message)
		Catch ex As MissingMethodException
			DirectCast(Source, WinSECore.User).SendMessage(sc.node, DirectCast(Source, WinSECore.User), "Unknown command. Type " & WinSECore.API.FORMAT_BOLD & "/msg " & sc.node.Nick & " HELP" & WinSECore.API.FORMAT_BOLD & " for help.")
		End Try
	End Sub
	Public Overrides Function ModLoad(ByVal params() As String) As Boolean
		Dim p As New WinSECore.INIParser
		Dim kRoot As WinSECore.Key
		Dim conffile As String = c.Conf.ExtConfRoot & "\" & Replace(MyBase.Name, "/", "\") & "\chanfix.conf"
		Try
			kRoot = p.Load(conffile)
			If kRoot.SubKeys.Contains("ChanFix") Then
				With kRoot.SubKeys("ChanFix", 0)
					If .Values.Contains("MyNick") Then
						sc.Nick = CStr(.Values("MyNick", 0).value)
					End If
					If .Values.Contains("MyUser") Then
						sc.Ident = CStr(.Values("MyUser", 0).value)
					End If
					If .Values.Contains("MyHost") Then
						sc.Host = CStr(.Values("MyHost", 0).value)
					End If
					If .Values.Contains("MyReal") Then
						sc.RealName = CStr(.Values("MyReal", 0).value)
					End If
					If .Values.Contains("MinUsers") AndAlso IsNumeric(.Values("MinUsers", 0).value) Then
						nMinUsers = CInt(.Values("MinUsers", 0).value)
					Else
						Throw New WinSECore.ConfigException("[ChanFix],MinUsers is missing or invalid.")
					End If
					If .Values.Contains("MinChanops") AndAlso IsNumeric(.Values("MinChanops", 0).value) Then
						nMinChops = CInt(.Values("MinChanops", 0).value)
					Else
						Throw New WinSECore.ConfigException("[ChanFix],MinChanops is missing or invalid.")
					End If
					If .Values.Contains("MinChanopTime") AndAlso IsNumeric(.Values("MinChanopTime", 0).value) Then
						nMinChopTime = CInt(.Values("MinChanopTime", 0).value)
					Else
						Throw New WinSECore.ConfigException("[ChanFix],MinChanopTime is missing or invalid.")
					End If
					If .Values.Contains("DontRequireIdentd") Then
						Select Case LCase(.Values("DontRequireIdentd", 0).value.ToString())
							Case "yes", "true", "on", "1"
								bDontRequireIdentd = True
							Case "no", "false", "off", "0"
								bDontRequireIdentd = False
							Case Else
								Throw New WinSECore.ConfigException("[ChanFix],DontRequireIdentd is invalid.")
						End Select
					End If
					If .Values.Contains("DataExpire") Then
						If IsNumeric(.Values("DataExpire", 0).value) Then
							nDataExpire = CInt(.Values("DataExpire", 0).value)
						Else
							Throw New WinSECore.ConfigException("[ChanFix],DataExpire is invalid.")
						End If
					End If
					If .Values.Contains("EnableOpMe") Then
						Select Case LCase(.Values("DontRequireIdentd", 0).value.ToString())
							Case "yes", "true", "on", "1"
								bEnableOpMe = True
							Case "no", "false", "off", "0"
								bEnableOpMe = False
							Case Else
								Throw New WinSECore.ConfigException("[ChanFix],EnableOpMe is invalid.")
						End Select
					End If
					If .Values.Contains("IgnoreTilde") Then
						Select Case LCase(.Values("DontRequireIdentd", 0).value.ToString())
							Case "yes", "true", "on", "1"
								bIgnoreTilde = True
							Case "no", "false", "off", "0"
								bIgnoreTilde = False
							Case Else
								Throw New WinSECore.ConfigException("[ChanFix],IgnoreTilde is invalid.")
						End Select
					End If
					If .Values.Contains("SmartTildeMatching") Then
						Select Case LCase(.Values("DontRequireIdentd", 0).value.ToString())
							Case "yes", "true", "on", "1"
								bSmartTildeMatching = True
							Case "no", "false", "off", "0"
								bSmartTildeMatching = False
							Case Else
								Throw New WinSECore.ConfigException("[ChanFix],SmartTidleMatching is invalid.")
						End Select
					End If
					If .Values.Contains("Admin") Then
						cfOpers = New CFOper(.Values.Count("Admin") - 1) {}
						For idx As Integer = 0 To .Values.Count("Admin") - 1
							If CStr(.Values("Admin", idx).value) = "ChanFix" Then
								Throw New WinSECore.ConfigException("ChanFix cannot be used as an oper login name.")
							End If
							cfOpers(idx).LoginName = CStr(.Values("Admin", idx).value)
							If kRoot.SubKeys.Contains(cfOpers(idx).LoginName) Then
								With kRoot.SubKeys(cfOpers(idx).LoginName, 0)
									If .Values.Contains("Address") Then
										cfOpers(idx).Address = New String(.Values.Count("Address")) {}
										For idx2 As Integer = 0 To .Values.Count("Address") - 1
											cfOpers(idx).Address(idx2) = CStr(.Values("Address", idx2).value)
										Next
									Else
										Throw New WinSECore.ConfigException("[" & .name & "],Address[] missing.")
									End If
									If .Values.Contains("Password") Then
										cfOpers(idx).Password = CStr(.Values("Password", 0).value)
									Else
										Throw New WinSECore.ConfigException("[" & .name & "],Password missing.")
									End If
									If .Values.Contains("Permissions") Then
										cfOpers(idx).Permissions = CStr(.Values("Permissions", 0).value)
									Else
										Throw New WinSECore.ConfigException("[" & .name & "],Permissions missing.")
									End If
								End With
							Else
								Throw New WinSECore.ConfigException("[" & .name & "] missing.")
							End If
						Next
					Else
						Throw New WinSECore.ConfigException("[ChanFix],Admin[] missing.")
					End If
				End With
			Else
				Throw New WinSECore.ConfigException("[ChanFix] missing.")
			End If
		Catch ex As WinSECore.ConfigException
			c.Events.FireLogMessage("ChanFix", "ERROR", "Cannot parse configuration file: " & ex.Message)
			Return False
		End Try
		If bEnableOpMe Then
			sc.CmdHash.Add("OPME", AddressOf CmdStub)
		End If
		c.Clients.Add(sc)
		tmr = c.API.AddTimer(New TimeSpan(0, 5, 0), AddressOf ScanChannels, -1)
	End Function
	Public Overrides Sub ModUnload()
		c.Clients.Remove(sc)
		c.API.KillTimer(tmr)
	End Sub
	Public Overrides Function LoadDatabase() As Boolean
		With c.db
			If .Contains("chanfix") Then
				t = .Item("chanfix")
			Else
				t = .Item(.Add("chanfix"))
			End If
		End With
		For Each r As WinSECore.Record In t
			With r
				If Not .Contains("Alert") Then
					.SetField("Alert", False)
				Else
					Select Case LCase(CStr(.GetField("Alert")))
						Case "yes", "true", "on", "1"
							.SetField("Alert", True)
						Case "no", "false", "off", "0"
							.SetField("Alert", False)
						Case Else
							.SetField("Alert", False)
					End Select
				End If
				If Not .Contains("Block") Then
					.SetField("Block", False)
				Else
					Select Case LCase(CStr(.GetField("Block")))
						Case "yes", "true", "on", "1"
							.SetField("Block", True)
						Case "no", "false", "off", "0"
							.SetField("Block", False)
						Case Else
							.SetField("Block", False)
					End Select
				End If
				If .Contains("User") Then
					Dim s() As String = Split(.GetField("User").ToString(), vbLf)
					For idx As Integer = 0 To s.Length - 1
						Dim s2() As String = Split(s(idx), " ")
						If s2(0) Like "*@*" Then
							For idx2 As Integer = 1 To s2.Length - 1
								If Not IsNumeric(s2(idx2)) Then
									s(idx) = ""
									Exit For
								End If
							Next
						Else
							s(idx) = ""
						End If
					Next
					.SetField("User", Join(s, vbLf))
					While InStr(.GetField("User").ToString(), vbLf & vbLf) > 0
						.SetField("User", Replace(CStr(.GetField("User")), vbLf & vbLf, vbLf))
					End While
				End If
			End With
		Next
	End Function
	Private Overloads Function FindChannel(ByVal chan As String) As WinSECore.Record
		For Each r As WinSECore.Record In t
			If LCase(r.Name) = LCase(chan) Then
				Return r
			End If
		Next
		Return Nothing
	End Function
	Private Overloads Function FindChannel(ByVal chan As WinSECore.Channel) As WinSECore.Record
		Return FindChannel(chan.Name)
	End Function
	Private Overloads Function GetOpScore(ByVal chan As String, ByVal userhost As String) As Integer
		Dim r As WinSECore.Record = FindChannel(chan)
		Dim user As String = Split(userhost, "@", 2)(0), host As String = Split(userhost, "@", 2)(1)
		If r Is Nothing Then Return 0
		Dim s() As String = Split(CStr(r.GetField("User")), vbLf)
		Dim s2() As String
		Dim total As Integer = 0
		For Each sUser As String In s
			s2 = Split(sUser, " ")
			If IdentsEqual(user, Split(s2(0), "@", 2)(0)) AndAlso (host = Split(s2(0), "@", 2)(1)) Then
				Return GetOpScore(s2)
			End If
		Next
		Return 0
	End Function
	Private Overloads Function GetOpScore(ByVal chan As WinSECore.Channel, ByVal userhost As String) As Integer
		Return GetOpScore(chan.Name, userhost)
	End Function
	Private Overloads Function GetOpScore(ByVal chan As String, ByVal who As WinSECore.User) As Integer
		Dim r As WinSECore.Record = FindChannel(chan)
		If r Is Nothing Then Return 0
		Dim s() As String = Split(CStr(r.GetField("User")), vbLf)
		Dim s2() As String
		Dim total As Integer = 0
		For Each sUser As String In s
			s2 = Split(sUser, " ")
			If IdentsEqual(who.Username, Split(s2(0), "@", 2)(0)) AndAlso (who.Hostname = Split(s(2), "@", 2)(1)) Then
				Return GetOpScore(s2)
			End If
		Next
		Return 0
	End Function
	Private Overloads Function GetOpScore(ByVal sUser() As String) As Integer
		Dim total As Integer = 0
		For idx As Integer = 1 To sUser.Length - 1
			total += CInt(sUser(idx))
		Next
		Return total
	End Function
	Private Overloads Function GetOpScore(ByVal chan As WinSECore.Channel, ByVal who As WinSECore.User) As Integer
		Return GetOpScore(chan.Name, who)
	End Function
	Private Overloads Sub GiveOpPoint(ByVal chan As String, ByVal userhost As String)
		Dim r As WinSECore.Record = FindChannel(chan)
		Dim user As String = Split(userhost, "@", 2)(0), host As String = Split(userhost, "@", 2)(1)
		If r Is Nothing Then
			'A new channel? Create time!
			r = t(t.Add(chan))
			r.SetField("User", userhost & " 1")
			Exit Sub
		End If
		Dim s() As String = Split(CStr(r.GetField("User")), vbLf)
		Dim s2() As String
		Dim total As Integer = 0
		For idx As Integer = 0 To s.Length - 1
			s2 = Split(s(idx), " ")
			If IdentsEqual(user, Split(s2(0), "@", 2)(0)) AndAlso (host = Split(s2(0), "@", 2)(1)) Then
				'Give this one a point.
				s2(1) = CStr(CInt(s2(1)) + 1)
				s(idx) = Join(s2, " ")
				r.SetField("User", Join(s, vbLf))
				Exit Sub
			End If
		Next
		'Got here? Use doesn't exist? Add him!
		ReDim Preserve s(UBound(s) + 1)
		s(UBound(s)) = userhost & " 1"
		r.SetField("User", Join(s, vbLf))
	End Sub
	Private Overloads Sub GiveOpPoint(ByVal chan As WinSECore.Channel, ByVal userhost As String)
		GiveOpPoint(chan.Name, userhost)
	End Sub
	Private Overloads Sub GiveOpPoint(ByVal chan As String, ByVal u As WinSECore.User)
		Dim r As WinSECore.Record = FindChannel(chan)
		Dim user As String = u.Username, host As String = u.Hostname
		If r Is Nothing Then
			'A new channel? Create time!
			r = t(t.Add(chan))
			r.SetField("User", String.Format("{0}@{1}", user, host) & " 1")
			Exit Sub
		End If
		Dim s() As String = Split(CStr(r.GetField("User")), vbLf)
		Dim s2() As String
		Dim total As Integer = 0
		For idx As Integer = 0 To s.Length - 1
			s2 = Split(s(idx), " ")
			If IdentsEqual(user, Split(s2(0), "@", 2)(0)) AndAlso (host = Split(s2(0), "@", 2)(1)) Then
				'Give this one a point.
				s2(1) = CStr(CInt(s2(1)) + 1)
				s(idx) = Join(s2, " ")
				r.SetField("User", Join(s, vbLf))
				Exit Sub
			End If
		Next
		'Got here? Use doesn't exist? Add him!
		ReDim Preserve s(UBound(s) + 1)
		s(UBound(s)) = String.Format("{0}@{1}", user, host) & " 1"
		r.SetField("User", Join(s, vbLf))
	End Sub
	Private Overloads Sub GiveOpPoint(ByVal chan As WinSECore.Channel, ByVal u As WinSECore.User)
		GiveOpPoint(chan.Name, u)
	End Sub
	Private Overloads Function GetSortedScores(ByVal chan As WinSECore.Channel) As SortedList
		Dim n As New SortedList
		Dim r As WinSECore.Record = FindChannel(chan)
		If r Is Nothing Then Return Nothing
		Dim s() As String = Split(CStr(r.GetField("User")), vbLf)
		Dim s2() As String, nScore As Integer
		For Each sUser As String In s
			s2 = Split(sUser, " ")
			nScore = GetOpScore(s2)
			n.Add(nScore, s2(0))
		Next
	End Function
	Private Sub RollDays()
		Dim s() As String, s2() As String
		For Each r As WinSECore.Record In t
			s = Split(CStr(r.GetField("User")), vbLf)
			For idx As Integer = 0 To s.Length - 1
				s2 = Split(s(idx), " ")
				Select Case s2.Length - 1
					Case Is > nDataExpire
						ReDim Preserve s2(nDataExpire)
					Case Is < nDataExpire
						ReDim Preserve s2(s2.Length)
				End Select
				For idx2 As Integer = 1 To nDataExpire - 1
					s2(idx2 + 1) = s2(idx)
				Next
				s2(1) = "0"
				s(idx) = Join(s2, " ")
			Next
		Next
	End Sub

	Private Sub ScanChannels(ByVal t As WinSECore.Timer)
		Dim hasops As Boolean
		For Each ch As WinSECore.Channel In c.Channels
			Dim l As SortedList = GetSortedScores(ch)
			While CInt(l.GetKey(0)) < nMinChopTime
				l.RemoveAt(0)
			End While
			If ch.UserList.Count >= nMinUsers Then
				hasops = False
				For Each m As WinSECore.ChannelMember In ch.UserList
					If (InStr(m.Status, "o") > 0) OrElse ((c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_PROTECT) = WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_PROTECT AndAlso InStr(m.Status, c.protocol.ProtectChar) > 0 AndAlso (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.QUIRK_PROTECT_ISOPER) = WinSECore.IRCdSupportFlags.QUIRK_PROTECT_ISOPER) OrElse ((c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_OWNER) = WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_OWNER AndAlso InStr(m.Status, c.protocol.OwnerChar) > 0 AndAlso (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.QUIRK_OWNER_NOTOPER) = 0) Then
						hasops = True
						Exit For
					End If
				Next
				If (Not hasops) AndAlso l.Count >= nMinChops Then
					'We need to fix it.
					Dim fixes As Integer = 5
					'Send ChanFix into the channel, preferably with chanops :) .
					Dim s(0)() As String
					s(0) = New String() {sc.node.Nick, "o"}
					c.protocol.DoChanBurst(c.Services, ch.Name, ch.TS, "+", New String() {}, s)
					'If, for some insane reason, anyone has owner or admin status but are not considered opped, op them first.
					If (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_OWNER) = WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_OWNER Then
						For Each m As WinSECore.ChannelMember In ch.UserList
							If fixes <= 0 Then Exit For
							If InStr(m.Status, c.protocol.OwnerChar) > 0 Then
								ch.SendModes(sc.node, "+o " & m.Who.Nick)
								fixes -= 1
							End If
						Next
					End If
					If (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_PROTECT) = WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_PROTECT Then
						For Each m As WinSECore.ChannelMember In ch.UserList
							If fixes <= 0 Then Exit For
							If InStr(m.Status, c.protocol.ProtectChar) > 0 Then
								ch.SendModes(sc.node, "+o " & m.Who.Nick)
								fixes -= 1
							End If
						Next
					End If
					'The list is sorted ascending. So step backwards through it.
					For idx As Integer = l.Count - 1 To 0 Step -1
						Dim uhost As String = DirectCast(l(idx), String)
						Dim user As String = Split(uhost, "@", 2)(0), host As String = Split(uhost, "@", 2)(1)
						If fixes <= 0 Then Exit For
						If CInt(l.GetKey(idx)) >= nMinChopTime Then
							For Each m As WinSECore.ChannelMember In ch.UserList
								If m.Who.Hostname = host AndAlso IdentsEqual(m.Who.Username, user) Then
									ch.SendModes(sc.node, "+o " & m.Who.Nick)
									fixes -= 1
								End If
							Next
						End If
					Next
					'Ok, that's all of them.
					c.protocol.PartChan(sc.node, ch.Name, "My work here is done.")
				ElseIf hasops Then
					'Loop all the ops and give them one point.
					For Each m As WinSECore.ChannelMember In ch.UserList
						If (InStr(m.Status, "o") > 0) OrElse ((c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_PROTECT) = WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_PROTECT AndAlso InStr(m.Status, c.protocol.ProtectChar) > 0 AndAlso (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.QUIRK_PROTECT_ISOPER) = WinSECore.IRCdSupportFlags.QUIRK_PROTECT_ISOPER) OrElse ((c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_OWNER) = WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_OWNER AndAlso InStr(m.Status, c.protocol.OwnerChar) > 0 AndAlso (c.protocol.SupportFlags And WinSECore.IRCdSupportFlags.QUIRK_OWNER_NOTOPER) = 0) Then
							'Give him a point.
							If bDontRequireIdentd OrElse Not m.Who.Username.StartsWith("~") Then
								GiveOpPoint(ch, m.Who)
							End If
						End If
					Next
				End If
			End If
		Next
	End Sub

	Private Function IdentsEqual(ByVal ident1 As String, ByVal ident2 As String) As Boolean
		ident1 = LCase(ident1)
		ident2 = LCase(ident2)
		If ident1 = ident2 Then Return True
		If bIgnoreTilde Then
			If ident1.Chars(0) = "~"c Then
				If ident2.Chars(0) = "~"c Then
					'If they both have tildes, then we're just back to equality again :/ .
					Return False
				Else
					'Kill the ~ from ident1 and compare again.
					If Mid(ident1, 2) = ident2 Then Return True
					If bSmartTildeMatching AndAlso Len(ident2) = 10 Then
						'If ident2 is 10 characters (the USERLEN value for most IRCds), then kill the last character of ident2.
						If Mid(ident1, 1) = Left(ident2, 9) Then Return True
					End If
					'Otherwise they just don't match.
					Return False
				End If
			Else
				If ident2.Chars(0) = "~"c Then
					'Kill the ~ from ident2 and compare again.
					If Mid(ident2, 2) = ident1 Then Return True
					If bSmartTildeMatching AndAlso Len(ident1) = 10 Then
						'If ident1 is 10 characters (the USERLEN value for most IRCds), then kill the last character of ident1.
						If Mid(ident2, 1) = Left(ident1, 9) Then Return True
					End If
					'Otherwise they just don't match.
					Return False
				End If
			End If
		End If
		'Blah.
		Return False
	End Function

	'Duplicates Unreal's salting system.
	Private Function SaltHash(ByVal phrase As String, ByVal salt() As Byte, ByVal hasher As System.Security.Cryptography.HashAlgorithm) As String
		Dim result1() As Byte, hsize As Integer
		Dim result2() As Byte
		result1 = hasher.ComputeHash(System.Text.Encoding.ASCII.GetBytes(phrase))
		'result1 bounds will be 0 to size - 1
		hsize = UBound(result1) + 1
		'Increase size to 0 to size + saltsize - 1
		ReDim Preserve result1(hsize + salt.Length - 1)
		'Now copy salt into result. Since size - 1 is the last byte of the MD5, and hsize is size, we can start copying at hsize.
		salt.CopyTo(result1, hsize)
		'Hash Round Two
		result2 = hasher.ComputeHash(result1)
		Return String.Format("${0}${1}", WinSECore.API.B64Encode(salt), WinSECore.API.B64Encode(result2))
	End Function

	Private Function HexString(ByVal b() As Byte) As String
		Dim s As String = ""
		For idx As Integer = 0 To b.Length - 1
			s += Hex(b(idx)).PadRight(2, "0"c)
		Next
		Return s
	End Function

	Private Function PasswordMatch(ByVal hashedpass As String, ByVal triedpass As String) As Boolean
		Dim md5 As New System.Security.Cryptography.MD5CryptoServiceProvider
		Dim b() As Byte
		Select Case hashedpass.Chars(0)
			Case "@"c
				Return (Mid(hashedpass, 2) = triedpass)
			Case "$"c
				Dim s() As String = Split(hashedpass, "$")
				's(0) will be ""
				If s.Length < 2 Then
					's(1) is the b64'd md5.
					Return (WinSECore.API.B64Encode(md5.ComputeHash(System.Text.Encoding.ASCII.GetBytes(triedpass))) = s(1))
				Else
					's(1) is the b64'd salt.
					's(2) is the b64'd salted md5.
					b = WinSECore.API.B64Decode(s(1))
					Return (SaltHash(triedpass, b, md5) = hashedpass)
				End If
			Case "0"c To "9"c, "A"c To "F"c, "a"c To "f"c
				Return (HexString(md5.ComputeHash(System.Text.Encoding.ASCII.GetBytes(triedpass))) = triedpass)
			Case Else
				Throw New ArgumentException("hashedpass invalid format", "hashedpass")
		End Select
	End Function

	Private Function CmdStub(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean
	End Function
End Class
