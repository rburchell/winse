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
Public NotInheritable Class UnrealModule
	Inherits WinSECore.Module
	Public Sub New(ByVal c As WinSECore.Core)
		MyBase.New(c)
	End Sub

	Public Overrides Sub ModUnload()

	End Sub

	Public Overrides Function ModLoad(ByVal params() As System.Collections.Specialized.StringCollection) As Boolean
		Return False
	End Function

	Public Overrides Function GetHelpDirectory() As System.IO.DirectoryInfo
		Return Nothing
	End Function
End Class

Public Class Unreal
	Inherits WinSECore.IRCd
	Friend Shared ProtocolVersion As Integer
	Friend Shared EnableTokens As Boolean
	Friend Shared UseSVS2MODE As Boolean
	Friend Shared PrefixAQ As Boolean
	Private Const TOK_TKL As String = "BD"
	Private Const TOK_NICK As String = "&"
	Private Const TOK_SVSKILL As String = "h"
	Private Const TOK_KILL As String = "."
	Private Const TOK_SVSNICK As String = "e"
	Private Const TOK_SJOIN As String = "~"
	Private Const TOK_JOIN As String = "C"
	Private Const TOK_MODE As String = "G"
	Private Const TOK_PART As String = "D"
	Private Const TOK_QUIT As String = ","
	Private Const TOK_SQUIT As String = "-"
	Private Const TOK_SERVER As String = "'"
	Private Const TOK_PRIVMSG As String = "!"
	Private Const TOK_TOPIC As String = ")"
	Private Const TOK_NOTICE As String = "B"
	Private Const TOK_GLOBOPS As String = "]"
	Private Const TOK_SVSMODE As String = "n"
	Private Const TOK_SVS2MODE As String = "v"
	Private Const TOK_SWHOIS As String = "BA"
	Private Const TOK_KICK As String = "H"
	Shared Sub New()
		ProtocolVersion = 2302
		EnableTokens = True
		UseSVS2MODE = False
		PrefixAQ = False
	End Sub
	Public Sub New(ByVal c As WinSECore.Core)
		MyBase.New(c)
	End Sub
	Public Overrides Sub IntroduceClient(ByVal Nick As String, ByVal Username As String, ByVal Hostname As String, ByVal Realname As String, ByVal Usermodes As String, ByVal Numeric As String, ByVal Server As String, ByVal ts As Integer)
		c.API.PutServ("@{0} {1} {2} 1 {3} {4} {5} {6} {3} {7} * :{8}", IntToB64(c.Conf.ServerNumeric), IIf(EnableTokens, TOK_NICK, "NICK"), ts, Username, Hostname, Server, Usermodes, Realname)
	End Sub
	Public Overrides Sub IntroduceServer(ByVal Server As String, ByVal Hops As Integer, ByVal Numeric As String, ByVal Description As String, ByVal ts As Integer)
		c.API.PutServ("@{0} {1} {2} {3} {4} :{5}", IntToB64(c.Conf.ServerNumeric), IIf(EnableTokens, TOK_SERVER, "SERVER"), Server, Hops, Numeric, Description)
	End Sub
	Public Overrides Function IsValidNumeric(ByVal Numeric As Integer, ByVal ServerNumeric As Boolean) As Boolean
		Return (Not ServerNumeric) OrElse (Numeric >= 0 AndAlso Numeric <= 254)
	End Function
	Public Overrides Sub KillUser(ByVal Source As WinSECore.IRCNode, ByVal Target As String, ByVal Reason As String, Optional ByVal SuperKill As Boolean = False)
		c.API.PutServ("{0} {1} {2} :{3}", GetNSPrefix(Source), IIf(SuperKill, IIf(EnableTokens, TOK_SVSKILL, "SVSKILL"), IIf(EnableTokens, TOK_KILL, "KILL")), Target, IIf(SuperKill, Reason, Source.Name & " (" & Reason & ")"))
	End Sub
	Public Overrides Sub LoginToServer()
		c.API.PutServ("PASS :{0}", c.Conf.SendPass)
		c.API.PutServ("PROTOCTL NOQUIT {0}NICKv2 SJOIN SJOIN2 UMODE2 VL SJ3 NS SJB64 TKLEXT", IIf(EnableTokens, "TOKEN ", ""))
		c.API.PutServ("SERVER {0} 1 :U{1}-*-{2} {3}", c.Conf.ServerName, ProtocolVersion, c.Conf.ServerNumeric, c.Conf.ServerDesc)
	End Sub
	Public Overrides Sub SQuitServer(ByVal Source As WinSECore.IRCNode, ByVal Server As String, ByVal Reason As String)
		c.API.PutServ("{0} {1} {2} :{3}", GetNSPrefix(Source), IIf(EnableTokens, TOK_SQUIT, "SQUIT"), Server, Reason)
	End Sub
	'Format of TKL:
	'Adding:
	'TKL + <type> <user> <host> <source> <expiry_ts> <set_ts> :<reason>
	'Removing:
	'TKL - <type> <user> <host> <source>
	'Adding Spamfilter (without TKLEXT)
	'TKL + F <target> <action> <(un)setby> 0 <set_ts> :<regex>
	'Removing Spamfilter:
	'TKL - F <target> <action> <(un)setby> 0 <set_ts> :<regex>
	'Adding Spamfilter (with TKLEXT)
	'TKL + F <target> <action> <(un)setby> 0 <set_ts> <tkl-duration> <tkl-reason> :<regex>
	' -- tkl-reason must be space-escaped (eg, _ -> __ then space -> _)
	'Adding/Removing SQLINE:
	'TKL + Q [H|*] <nick> <(un)setby> <expire_ts> <set_ts> :<reason>
	' -- H for a HOLD - this supresses the qline reject notices. * is a normal SQLINE.
	'Don't use :<source> for these.
	Public Overloads Overrides Sub AddIPAddressBan(ByVal Source As WinSECore.IRCNode, ByVal Mask As String, ByVal Reason As String)
		Dim ts As Long = c.API.GetTS()
		c.API.PutServ("{0} + Z * {1} {2} 0 {3} :{4}", IIf(EnableTokens, TOK_TKL, "TKL"), Mask, Source, ts, Reason)
	End Sub
	Public Overloads Overrides Sub AddIPAddressBan(ByVal Source As WinSECore.IRCNode, ByVal Mask As String, ByVal Reason As String, ByVal Expiry As System.TimeSpan)
		Dim ts As Long = c.API.GetTS()
		c.API.PutServ("{0} + Z * {1} {2} {3} {4} :{5}", IIf(EnableTokens, TOK_TKL, "TKL"), Mask, Source, ts + Expiry.TotalSeconds, ts, Reason)
	End Sub
	Public Overloads Overrides Sub AddNicknameBan(ByVal Source As WinSECore.IRCNode, ByVal Mask As String, ByVal Reason As String)
		Dim ts As Long = c.API.GetTS()
		c.API.PutServ("{0} + Q * {1} {2} 0 {3} :{4}", IIf(EnableTokens, TOK_TKL, "TKL"), Mask, Source, ts, Reason)
	End Sub
	Public Overloads Overrides Sub AddNicknameBan(ByVal Source As WinSECore.IRCNode, ByVal Mask As String, ByVal Reason As String, ByVal Expiry As System.TimeSpan)
		Dim ts As Long = c.API.GetTS()
		c.API.PutServ("{0} + Q * {1} {2} {3} {4} :{5}", IIf(EnableTokens, TOK_TKL, "TKL"), Mask, Source, ts + Expiry.TotalSeconds, ts, Reason)
	End Sub
	Public Overloads Overrides Sub AddRealnameBan(ByVal Source As WinSECore.IRCNode, ByVal Mask As String, ByVal Reason As String)
		'TODO: Get SVSNLINE Token.
		c.API.PutServ("{0} {1} + {2} :{3}", GetNSPrefix(Source), "SVSNLINE", Replace(Replace(Reason, "_", "__"), " ", "_"), Mask)
	End Sub
	Public Overloads Overrides Sub AddRealnameBan(ByVal Source As WinSECore.IRCNode, ByVal Mask As String, ByVal Reason As String, ByVal Expiry As System.TimeSpan)
		Throw New NotSupportedException("Unreal IRCd does not support temporary realname bans.")
	End Sub
	Public Overloads Overrides Sub AddUserHostBan(ByVal Source As WinSECore.IRCNode, ByVal Mask As String, ByVal Reason As String)
		Dim ts As Long = c.API.GetTS()
		c.API.PutServ("{0} + G {1} {2} {3} 0 {4} :{5}", IIf(EnableTokens, TOK_TKL, "TKL"), Split(Mask, "@", 2)(0), Split(Mask, "@", 2)(1), Source, ts, Reason)
	End Sub
	Public Overloads Overrides Sub AddUserhostBan(ByVal Source As WinSECore.IRCNode, ByVal Mask As String, ByVal Reason As String, ByVal Expiry As System.TimeSpan)
		Dim ts As Long = c.API.GetTS()
		c.API.PutServ("{0} + G {1} {2} {3} {4} {5} :{6}", IIf(EnableTokens, TOK_TKL, "TKL"), Split(Mask, "@", 2)(0), Split(Mask, "@", 2)(1), Source, ts + Expiry.TotalSeconds, ts, Reason)
	End Sub
	Public Overrides ReadOnly Property BanChar() As Char
		Get
			Return "b"c
		End Get
	End Property
	Public Overrides ReadOnly Property ChanOpChar() As Char
		Get
			Return "o"c
		End Get
	End Property
	Public Overrides Sub ClearList(ByVal Source As WinSECore.IRCNode, ByVal Channel As String, ByVal ModeCh As Char)
		c.API.PutServ("{0} {1} {2} -{3}", GetNSPrefix(Source), IIf(EnableTokens, TOK_SVSMODE, "SVSMODE"), Channel, ModeCh)
	End Sub
	Public Overrides Sub DelIPAddressBan(ByVal Source As WinSECore.IRCNode, ByVal Mask As String)
		c.API.PutServ("{0} - Z * {1} {2}", IIf(EnableTokens, TOK_TKL, "TKL"), Mask, Source)
	End Sub
	Public Overrides Sub DelNicknameBan(ByVal Source As WinSECore.IRCNode, ByVal Mask As String)
		c.API.PutServ("{0} - Q * {1} {2}", IIf(EnableTokens, TOK_TKL, "TKL"), Mask, Source)
	End Sub
	Public Overrides Sub DelRealnameBan(ByVal Source As WinSECore.IRCNode, ByVal Mask As String)
		'TODO: Get SVSNLINE Token.
		c.API.PutServ("{0} {1} - * :{2}", GetNSPrefix(Source), "SVSNLINE", Mask)
	End Sub
	Public Overrides Sub DelUserhostBan(ByVal Source As WinSECore.IRCNode, ByVal Mask As String)
		c.API.PutServ("{0} - G {1} {2} {3}", IIf(EnableTokens, TOK_TKL, "TKL"), Split(Mask, "@", 2)(0), Split(Mask, "@", 2)(1), Source)
	End Sub
	Public Overrides Sub DoNetBurst(ByVal Source As WinSECore.IRCNode, ByVal Channel As String, ByVal ts As Integer, Optional ByVal Users()() As String = Nothing, Optional ByVal Bans() As String = Nothing, Optional ByVal Excepts() As String = Nothing, Optional ByVal Invites() As String = Nothing)
		'TODO: This lot :/
	End Sub
	Public Overrides ReadOnly Property ExemptChar() As Char
		Get
			Return "e"c
		End Get
	End Property
	Public Overrides Sub ForceNick(ByVal Source As WinSECore.IRCNode, ByVal Target As String, ByVal NewNick As String)
		c.API.PutServ("{0} {1} {2} {3} {4}", GetNSPrefix(Source), IIf(EnableTokens, TOK_SVSNICK, "SVSNICK"), Target, NewNick, c.API.GetTS())
	End Sub
	Public Overrides Sub ForceJoin(ByVal Source As WinSECore.IRCNode, ByVal Channel As String, ByVal User As String)
		'TODO: Get SVSJOIN Token.
		c.API.PutServ("{0} {1} {2} {3}", GetNSPrefix(Source), "SVSJOIN", Channel, User)
	End Sub
	Public Overrides Sub ForcePart(ByVal Source As WinSECore.IRCNode, ByVal Channel As String, ByVal User As String, ByVal Reason As String)
		'TODO: Get SVSPART Token.
		c.API.PutServ("{0} {1} {2} {3} :{4}", GetNSPrefix(Source), "SVSPART", Channel, User, Reason)
	End Sub
	Public Overrides Sub ForceUMode(ByVal Source As WinSECore.IRCNode, ByVal Target As String, ByVal Mode As String)
		c.API.PutServ("{0} {1} {2} {3}", GetNSPrefix(Source), IIf(UseSVS2MODE, IIf(EnableTokens, TOK_SVS2MODE, "SVS2MODE"), IIf(EnableTokens, TOK_SVSMODE, "SVSMODE")), Target, Mode)
	End Sub
	Public Overrides ReadOnly Property HalfopChar() As Char
		Get
			Return "h"c
		End Get
	End Property
	Public Overrides ReadOnly Property InviteChar() As Char
		Get
			If ProtocolVersion >= 2306 Then
				Return "I"c
			Else
				Throw New NotSupportedException("INVEX not supported by Unreal IRCd versions prior to 3.2.3.")
			End If
		End Get
	End Property
	Public Overrides Sub JoinChan(ByVal Source As WinSECore.IRCNode, ByVal Channel As String)
		c.API.PutServ("{0} {1} {2}", GetNSPrefix(Source), IIf(EnableTokens, TOK_JOIN, "JOIN"), Channel)
	End Sub
	Public Overloads Overrides Sub JupeSpecial(ByVal Source As WinSECore.IRCNode, ByVal Target As String, ByVal Reason As String)
		Throw New NotImplementedException
	End Sub
	Public Overloads Overrides Sub JupeSpecial(ByVal Source As WinSECore.IRCNode, ByVal Target As String, ByVal Reason As String, ByVal Expiry As System.TimeSpan)
		Throw New NotImplementedException
	End Sub
	Public Overrides Sub KickUser(ByVal Source As WinSECore.IRCNode, ByVal Channel As String, ByVal User As String, ByVal Reason As String)
		c.API.PutServ("{0} {1} {2} {3} :{4}", GetNSPrefix(Source), IIf(EnableTokens, TOK_KICK, "KICK"), Channel, User, Reason)
	End Sub
	Public Overrides ReadOnly Property OwnerChar() As Char
		Get
			Return "q"c
		End Get
	End Property
	Public Overrides Sub ParseCmd(ByVal Buffer As String)
		'TODO: This lot :/ .
	End Sub
	Public Overrides Sub PartChan(ByVal Source As WinSECore.IRCNode, ByVal Channel As String, ByVal Reason As String)
		c.API.PutServ("{0} {1} {2}", GetNSPrefix(Source), IIf(EnableTokens, TOK_PART, "PART"), Channel)
	End Sub
	Public Overrides ReadOnly Property ProtectChar() As Char
		Get
			Return "a"c
		End Get
	End Property
	Public Overloads Overrides Sub SendMessage(ByVal Source As WinSECore.IRCNode, ByVal Target As WinSECore.Channel, ByVal Prefix As Char, ByVal Message As String, ByVal Notice As Boolean)
		c.API.PutServ("{0} {1} {3}{2} :{4}", GetNSPrefix(Source), IIf(Notice, IIf(EnableTokens, TOK_NOTICE, "NOTICE"), IIf(EnableTokens, TOK_PRIVMSG, "PRIVMSG")), Target.Name, Prefix, Message)
	End Sub
	Public Overloads Overrides Sub SendMessage(ByVal Source As WinSECore.IRCNode, ByVal Target As WinSECore.Channel, ByVal Message As String, ByVal Notice As Boolean)
		c.API.PutServ("{0} {1} {2} :{3}", GetNSPrefix(Source), IIf(Notice, IIf(EnableTokens, TOK_NOTICE, "NOTICE"), IIf(EnableTokens, TOK_PRIVMSG, "PRIVMSG")), Target.Name, Message)
	End Sub
	Public Overloads Overrides Sub SendMessage(ByVal Source As WinSECore.IRCNode, ByVal Target As WinSECore.User, ByVal Message As String, ByVal Notice As Boolean)
		c.API.PutServ("{0} {1} {2} :{3}", GetNSPrefix(Source), IIf(Notice, IIf(EnableTokens, TOK_NOTICE, "NOTICE"), IIf(EnableTokens, TOK_PRIVMSG, "PRIVMSG")), Target.Name, Message)
	End Sub
	Public Overrides Sub SetChanHold(ByVal Source As WinSECore.IRCNode, ByVal Channel As String, ByVal [Set] As Boolean)
		If [Set] Then
			c.API.PutServ("@{0} {1} 1 {2} +ilKV 1 :*@{3} &*!*@*", IntToB64(c.Conf.ServerNumeric), IIf(EnableTokens, TOK_SJOIN, "SJOIN"), Channel, Source)
		Else
			c.API.PutServ("{0} {1} {2} -ilKVb *!*@*", GetNSPrefix(Source), IIf(EnableTokens, TOK_MODE, "MODE"), Channel)
			c.API.PutServ("{0} {1} {2} :Released", GetNSPrefix(Source), IIf(EnableTokens, TOK_PART, "PART"), Channel)
		End If
	End Sub
	Public Overrides Sub SetChMode(ByVal Source As WinSECore.IRCNode, ByVal Channel As String, ByVal Mode As String)
		c.API.PutServ("{0} {1} {2} {3}", GetNSPrefix(Source), IIf(EnableTokens, TOK_MODE, "MODE"), Channel, Mode)
	End Sub
	Public Overrides Sub SetNickHold(ByVal Source As WinSECore.IRCNode, ByVal Nick As String, ByVal [Set] As Boolean)
		If [Set] Then
			Dim ts As Long = c.API.GetTS()
			'HACK: We need to decide on the expiry time for this, since I doubt Unreal will accept an expiry of 0 for holds. 
			c.API.PutServ("{0} + Q H {1} {2} {3} {4} :{5}", IIf(EnableTokens, TOK_TKL, "TKL"), Nick, Source, ts + 60, ts, "Held by services")
		Else
			c.API.PutServ("{0} - Q H {1} {2}", IIf(EnableTokens, TOK_TKL, "TKL"), Nick, Source)
		End If
	End Sub
	Public Overloads Overrides Sub SetNoopers(ByVal Source As WinSECore.IRCNode, ByVal Target As String, ByVal Reason As String)
		'We need to be absolutely sure everyone gets deoped...
		Dim s As WinSECore.Server = DirectCast(c.API.FindNode(Target), WinSECore.Server)
		For Each n As WinSECore.IRCNode In s.SubNodes
			If TypeOf n Is WinSECore.User Then
				SetOper(Source, n.Name, "-")
			End If
			'For now, we won't descend into servers behind the noop'd server.
		Next
		'TODO: Get SVSNOOP Token.
		c.API.PutServ("{0} {1} +{2}", GetNSPrefix(Source), "SVSNOOP", Target)
	End Sub
	Public Overloads Overrides Sub SetNoopers(ByVal Source As WinSECore.IRCNode, ByVal Target As String, ByVal Reason As String, ByVal Expiry As System.TimeSpan)
		Throw New NotSupportedException("Auto-expiring NOOP not supported.")
	End Sub
	Public Overrides Sub SetOper(ByVal Source As WinSECore.IRCNode, ByVal Target As String, ByVal Flags As String)
		'TODO: Get SVSO Token.
		c.API.PutServ("{0} {1} {2} {3}", GetNSPrefix(Source), "SVSO", Target, Flags)
	End Sub
	Public Overrides Sub UnsetNoopers(ByVal Source As WinSECore.IRCNode, ByVal Target As String)
		'TODO: Get SVSNOOP Token.
		c.API.PutServ("{0} {1} -{2}", GetNSPrefix(Source), "SVSNOOP", Target)
	End Sub
	Public Overrides ReadOnly Property VoiceChar() As Char
		Get
			Return "v"c
		End Get
	End Property
	Public Overrides ReadOnly Property SupportFlags() As WinSECore.IRCdSupportFlags
		Get
			Dim flg As WinSECore.IRCdSupportFlags
			flg = WinSECore.IRCdSupportFlags.QUIRK_CHANHOLD_WONTKICK Or WinSECore.IRCdSupportFlags.QUIRK_INVEX_ONLY_INVONLY Or WinSECore.IRCdSupportFlags.SUPPORT_BAN_IPADDR Or WinSECore.IRCdSupportFlags.SUPPORT_BAN_NICKNAME Or WinSECore.IRCdSupportFlags.SUPPORT_BAN_REALNAME Or WinSECore.IRCdSupportFlags.SUPPORT_BAN_USERHOST Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_BANEXMPT Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_FORCEJOIN Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_FORCEPART Or _
			 WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_HALFOP Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_MASSDEOP Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_MODEHACK Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_NETBURST Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_OWNER Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_PROTECT Or WinSECore.IRCdSupportFlags.SUPPORT_HOLD_NICK Or WinSECore.IRCdSupportFlags.SUPPORT_SERVER_SVSNOOPERS Or WinSECore.IRCdSupportFlags.SUPPORT_TEMPBAN_IPADDR Or _
			 WinSECore.IRCdSupportFlags.SUPPORT_TEMPBAN_NICKNAME Or WinSECore.IRCdSupportFlags.SUPPORT_TEMPBAN_USERHOST Or WinSECore.IRCdSupportFlags.SUPPORT_UNBAN_IPADDR Or WinSECore.IRCdSupportFlags.SUPPORT_UNBAN_NICKNAME Or WinSECore.IRCdSupportFlags.SUPPORT_UNBAN_REALNAME Or WinSECore.IRCdSupportFlags.SUPPORT_UNBAN_USERHOST Or WinSECore.IRCdSupportFlags.SUPPORT_USER_FORCENICK Or WinSECore.IRCdSupportFlags.SUPPORT_USER_FORCEUMODE Or WinSECore.IRCdSupportFlags.SUPPORT_USER_SUPERKILL Or _
			 WinSECore.IRCdSupportFlags.SUPPORT_USER_SVSOPER
			If ProtocolVersion >= 2306 Then
				flg = flg Or WinSECore.IRCdSupportFlags.QUIRK_INVEX_ONLY_INVONLY Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_INVEX
			End If
		End Get
	End Property
	Public Overrides ReadOnly Property ChanModes() As String
		Get
			If ProtocolVersion >= 2306 Then
				Return "beI,kfL,l,psmntirRcOAQKVGCuzNSMTG"
			Else
				Return "be,kfL,l,psmntirRcOAQKVGCuzNSMTG"
			End If
		End Get
	End Property
	Public Overrides ReadOnly Property UserModes() As String
		Get
			Return "iowghraAsORTVSxNCWqBzvdHtGp"
		End Get
	End Property
	Public Overrides Function ServiceUMode() As String
		Return "oS"
	End Function
	Public Overrides Function InvisServiceUMode() As String
		Return "ioS"
	End Function
	Public Overrides Function ChServiceUMode() As String
		Return "oSqp"
	End Function
	Private Function GetNSPrefix(ByVal Source As WinSECore.IRCNode) As String
		If Source Is Nothing Then Throw New ArgumentNullException("Source")
		If TypeOf Source Is WinSECore.Server Then Return "@" + IntToB64(Source.Numeric) Else Return ":" + Source.Name
	End Function
	'And these functions are translated from UnrealIRCd src/aln.c
	Private Function IntToB64(ByVal val As Integer) As String
		Dim map() As String
		map = New String() {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", _
		 "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", _
		 "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", _
		 "w", "x", "y", "z", "{", "}"}
		Static b64buf As String
		Dim i As Integer
		i = 8
		'Unreal does some weird check to see if val is over 2^31-1, but we don't need it since Long can't do that.
		'Unreal's check just calls abort() if it is over, which we shouldn't do.
		Do
			i = i - 1
			Mid(b64buf, i, 1) = map(val And 63)
			'Now we need to do a 6-bit right shift. Unreal's code uses a signed long, and by C's standard,
			'>> on a signed integer performs an arithmetic shift. This will play havoc if val is < 0 but that
			'shouldn't happen anyway.
			val = val \ 64
		Loop While val <> 0
		Return Mid(b64buf, i)
	End Function
	Private Function B64ToInt(ByVal b64 As String) As Integer
		Dim map() As Integer
		map = New Integer() {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
		0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -1, -1, -1, -1, -1, -1, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, _
		22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, -1, -1, -1, -1, -1, -1, 36, 37, 38, 39, 40, 41, _
		42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, -1, 63, -1, -1, -1, _
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1}
		Dim idx As Integer
		Dim v As Integer
		idx = 1
		v = map(Asc(Mid(b64, idx, 1)))
		idx = idx + 1
		If idx > Len(b64) Then
			B64ToInt = 0
			Exit Function
		End If
		For idx = idx To Len(b64)
			'Do a 6-bit left shift. Harder than a right.
			'Mask off bits that will fall off.
			v = v And &H3FFFFFF
			If CDbl(v) * (2 ^ 6) > 2147483647.0# Then
				v = CInt(c.API.FMod(v * 64, 2147483648.0#) + -2147483648.0#)
			Else
				v = v * 64
			End If
			v = v + map(Asc(Mid(b64, idx, 1)))
		Next idx
		Return v
	End Function
End Class
