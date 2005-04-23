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
Public NotInheritable Class UnrealModule
	Inherits WinSECore.Module
	Public Sub New(ByVal c As WinSECore.Core)
		MyBase.New(c)
	End Sub

	Public Overrides Sub ModUnload()

	End Sub

	Public Overrides Function ModLoad(ByVal params() As String) As Boolean
		For Each s As String In params
			If s Like "protover=*" Then
				Try
					Unreal.ProtocolVersion = CInt(Split(s, "=", 2)(1))
				Catch ex As Exception
					Return False
				End Try
			ElseIf s Like "prefixaq=*" Then
				Select Case UCase(Split(s, "=", 2)(1))
					Case "Y", "YES", "1", "TRUE"
						Unreal.PrefixAQ = True
					Case "N", "NO", "0", "FALSE"
						Unreal.PrefixAQ = False
					Case Else
						Return False
				End Select
			ElseIf s Like "tokens=*" Then
				Select Case UCase(Split(s, "=", 2)(1))
					Case "Y", "YES", "1", "TRUE"
						Unreal.EnableTokens = True
					Case "N", "NO", "0", "FALSE"
						Unreal.EnableTokens = False
					Case Else
						Return False
				End Select
			ElseIf s Like "svs2mode=*" Then
				Select Case UCase(Split(s, "=", 2)(1))
					Case "Y", "YES", "1", "TRUE"
						Unreal.UseSVS2MODE = True
					Case "N", "NO", "0", "FALSE"
						Unreal.UseSVS2MODE = False
					Case Else
						Return False
				End Select
			End If
		Next
		c.protocol = New Unreal(c)
		Return True
	End Function
End Class

Public NotInheritable Class Unreal
	Inherits WinSECore.IRCd
	Friend Shared ProtocolVersion As Integer
	Friend Shared EnableTokens As Boolean
	Friend Shared UseSVS2MODE As Boolean
	Friend Shared PrefixAQ As Boolean
	Friend ReadOnly ProtoCtl As New StringCollection
#Region "Token Constants"
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
	Private Const TOK_AWAY As String = "6"
	Private Const TOK_AKILL As String = "V"
	Private Const TOK_ADCHAT As String = "x"
	Private Const TOK_ADMIN As String = "@"
	Private Const TOK_ADDOMOTD As String = "AR"
	Private Const TOK_ADDMOTD As String = "AQ"
	Private Const TOK_ADDLINE As String = "z"
	Private Const TOK_WHOWAS As String = "$"
	Private Const TOK_WHOIS As String = "#"
	Private Const TOK_WHO As String = """"
	Private Const TOK_WALLOPS As String = "="
	Private Const TOK_VHOST As String = "BE"
	Private Const TOK_USERHOST As String = "J"
	Private Const TOK_UNZLINE As String = "r"
	Private Const TOK_UNSQLINE As String = "d"
	Private Const TOK_UNKLINE As String = "X"
	Private Const TOK_UNDCCDENY As String = "BJ"
	Private Const TOK_UMODE2 As String = "|"
	Private Const TOK_TSCTL As String = "AW"
	Private Const TOK_TRACE As String = "b"
	Private Const TOK_GLINE As String = "}"
	Private Const TOK_SHUN As String = "BL"
	Private Const TOK_TEMPSHUN As String = "Tz"
	Private Const TOK_TIME As String = ">"
	Private Const TOK_SVSWATCH As String = "Bw"
	Private Const TOK_SVSSNO As String = "BV"
	Private Const TOK_SVS2SNO As String = "BW"
	Private Const TOK_SVSSILENCE As String = "Bs"
	Private Const TOK_SVSPART As String = "BT"
	Private Const TOK_SVSO As String = "BB"
	Private Const TOK_SVSNOOP As String = "f"
	Private Const TOK_SVSNLINE As String = "BR"
	Private Const TOK_SVSMOTD As String = "AS"
	Private Const TOK_SVSLUSERS As String = "BU"
	Private Const TOK_SVSJOIN As String = "BX"
	Private Const TOK_SVSFLINE As String = "BC"
	Private Const TOK_STATS As String = "2"
	Private Const TOK_SQLINE As String = "c"
	Private Const TOK_SILENCE As String = "U"
	Private Const TOK_SETNAME As String = "AE"
	Private Const TOK_SETIDENT As String = "AD"
	Private Const TOK_SETHOST As String = "AA"
	Private Const TOK_SENDUMODE As String = "AP"
	Private Const TOK_SMO As String = "AU"
	Private Const TOK_SENDSNO As String = "Ss"
	Private Const TOK_SDESC As String = "AG"
	Private Const TOK_SAPART As String = "AY"
	Private Const TOK_SAMODE As String = "o"
	Private Const TOK_SAJOIN As String = "AX"
	Private Const TOK_RULES As String = "t"
	Private Const TOK_RPING As String = "AM"
	Private Const TOK_RPONG As String = "AN"
	Private Const TOK_RAKILL As String = "Y"
	Private Const TOK_PROTOCTL As String = "_"
	Private Const TOK_PING As String = "8"
	Private Const TOK_PONG As String = "9"
	Private Const TOK_PASS As String = "<"
	Private Const TOK_OPER As String = ";"
	Private Const TOK_NETINFO As String = "AO"
	Private Const TOK_NACHAT As String = "AC"
	Private Const TOK_MKPASSWD As String = "y"
	Private Const TOK_MAP As String = "u"
	Private Const TOK_LOCOPS As String = "^"
	Private Const TOK_LIST As String = "("
	Private Const TOK_LINKS As String = "0"
	Private Const TOK_LAG As String = "AF"
	Private Const TOK_KNOCK As String = "AI"
	Private Const TOK_ISON As String = "K"
	Private Const TOK_INVITE As String = "*"
	Private Const TOK_HTM As String = "BH"
	Private Const TOK_HELPOP As String = "4"
	Private Const TOK_EOS As String = "ES"
	Private Const TOK_DCCDENY As String = "BI"
	Private Const TOK_CYCLE As String = "BP"
	Private Const TOK_CONNECT As String = "7"
	Private Const TOK_CLOSE As String = "Q"
	Private Const TOK_CHGNAME As String = "BK"
	Private Const TOK_CHGIDENT As String = "AZ"
	Private Const TOK_CHATOPS As String = "p"
	Private Const TOK_CHGHOST As String = "AL"
	'Below came from include/msg.h :/
	Private Const TOK_USER As String = "%"
	Private Const TOK_VERSION As String = "+"
	Private Const TOK_INFO As String = "/"
	Private Const TOK_SUMMON As String = "1"
	Private Const TOK_USERS As String = "3"
	Private Const TOK_ERROR As String = "5"
	Private Const TOK_NAMES As String = "?"
	Private Const TOK_LUSERS As String = "E"
	Private Const TOK_MOTD As String = "F"
	Private Const TOK_SERVICE As String = "I"
	Private Const TOK_REHASH As String = "O"
	Private Const TOK_RESTART As String = "P"
	Private Const TOK_DIE As String = "R"
	Private Const TOK_HASH As String = "S"
	Private Const TOK_DNS As String = "T"
	Private Const TOK_KLINE As String = "W"
	Private Const TOK_GNOTICE As String = "Z"
	Private Const TOK_GOPER As String = "["
	Private Const TOK_WATCH As String = "`"
	Private Const TOK_ZLINE As String = "q"
	Private Const TOK_DALINFO As String = "w"
	Private Const TOK_CREDITS As String = "AJ"
	Private Const TOK_LICENSE As String = "AK"
	Private Const TOK_OPERMOTD As String = "AV"
	Private Const TOK_BOTMOTD As String = "BF"
	Private Const TOK_REMGLINE As String = "BG"
	'SVSNAME is documented in include/msg.h but doesn't have a token :/ .
	'NEWJOIN is documented in include/msg.h but doesn't have a token :/ .
	Private Const TOK_POST As String = "BN"
	Private Const TOK_MODULE As String = "BQ"
#End Region
	Shared Sub New()
		ProtocolVersion = 2302
		EnableTokens = True
		UseSVS2MODE = False
		PrefixAQ = False
	End Sub
	Public Sub New(ByVal c As WinSECore.Core)
		MyBase.New(c)
	End Sub
#Region "Base Overrides"
	Public Overrides Sub IntroduceClient(ByVal Nick As String, ByVal Username As String, ByVal Hostname As String, ByVal Realname As String, ByVal Usermodes As String, ByVal Numeric As Integer, ByVal Server As String, ByVal ts As Integer)
		'Format of this:
		'@servernum NICK nick hops ts user host server stamp umodes vhost ipaddr :real name
		'ts is to be !<b64 of timestamp> for SJB64
		'ipaddr is a b64encoded IP in network byte order (eg, a.b.c.d, byte order is a b c d).
		c.API.PutServ("@{0} {1} {2} 1 !{3} {4} {5} {6} {3} {7} * * :{8}", IntToB64(c.Conf.ServerNumeric), IIf(EnableTokens, TOK_NICK, "NICK"), Nick, IntToB64(ts), Username, Hostname, Server, Usermodes, Realname)
	End Sub
	Public Overrides Sub IntroduceServer(ByVal Server As String, ByVal Hops As Integer, ByVal Numeric As Integer, ByVal Description As String, ByVal ts As Integer)
		c.API.PutServ("@{0} {1} {2} {3} {4} :{5}", IntToB64(c.Conf.ServerNumeric), IIf(EnableTokens, TOK_SERVER, "SERVER"), Server, Hops, Numeric, Description)
	End Sub
	Public Overrides Function IsValidNumeric(ByVal Numeric As Integer, ByVal ServerNumeric As Boolean) As Boolean
		Return (Not ServerNumeric) OrElse (Numeric >= 0 AndAlso Numeric <= 254)
	End Function
	Public Overrides Sub KillUser(ByVal Source As WinSECore.IRCNode, ByVal Target As String, ByVal Reason As String, Optional ByVal SuperKill As Boolean = False)
		c.API.PutServ("{0} {1} {2} :{3}", GetNSPrefix(Source), IIf(SuperKill, IIf(EnableTokens, TOK_SVSKILL, "SVSKILL"), IIf(EnableTokens, TOK_KILL, "KILL")), Target, IIf(SuperKill, Reason, Source.Name & " (" & Reason & ")"))
	End Sub
	Public Overrides Sub LoginToServer()
		'We can't use TOKENs here.
		c.API.PutServ("PASS :{0}", c.Conf.SendPass)
		'VHP is an undocumented token. What it does is when Unreal sends us user information, it sends us the cloaked host as the VHost.
		'If the user is -x, the realhost is sent as the vhost.
		'For example, without VHP:
		':irc.server.name NICK aquanight 1 1234567890 aquanight 192.168.2.97 irc.server.name 0 +isRx * wKgCYQ== :aquanight
		'With VHP:
		':irc.server.name NICK aquanight 1 1234567890 aquanight 192.168.2.97 irc.server.name 0 +isRx 97869835.7CE6B37B.B08B7D94.IP wKgCYQ== :aquanight
		'This means we don't have to copy/paste unreal's cloaking algo and force users to configure cloak keys.
		'Note that VHP works even without NICKv2. Unreal would then send us the cloaked host or real host in a SETHOST command.
		c.API.PutServ("PROTOCTL NOQUIT {0}NICKv2 VHP SJOIN SJOIN2 UMODE2 VL SJ3 {1}SJB64 TKLEXT NICKIP", IIf(EnableTokens, "TOKEN ", ""), IIf(c.Conf.ServerNumeric >= 0, "NS ", ""))
		c.API.PutServ("SERVER {0} 1 :U{1}-0{2} {3}", c.Conf.ServerName, ProtocolVersion, IIf(c.Conf.ServerNumeric >= 0, "-" & c.Conf.ServerNumeric.ToString(), ""), c.Conf.ServerDesc)
	End Sub
	Public Overrides Sub EndSynch()
		':server NETINFO globalpeak syncTS protocol cloakcrc 0 0 0 :network name
		c.API.PutServ("{0} 1 {1} {2} * 0 0 0 :{3}", IIf(EnableTokens, TOK_NETINFO, "NETINFO"), c.API.GetTS(), ProtocolVersion, c.Conf.NetworkName)
		c.API.PutServ("{0} EOS", GetNSPrefix(c.Services))
	End Sub
	Public Overrides Sub SendError(ByVal Text As String)
		c.API.PutServ("ERROR :{0}", Text)
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
		c.API.PutServ("{0} {1} + {2} :{3}", GetNSPrefix(Source), IIf(EnableTokens, TOK_SVSNLINE, "SVSNLINE"), Replace(Replace(Reason, "_", "__"), " ", "_"), Mask)
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
		c.API.PutServ("{0} {1} - * :{2}", GetNSPrefix(Source), IIf(EnableTokens, TOK_SVSNLINE, "SVSNLINE"), Mask)
	End Sub
	Public Overrides Sub DelUserhostBan(ByVal Source As WinSECore.IRCNode, ByVal Mask As String)
		c.API.PutServ("{0} - G {1} {2} {3}", IIf(EnableTokens, TOK_TKL, "TKL"), Split(Mask, "@", 2)(0), Split(Mask, "@", 2)(1), Source)
	End Sub
	Public Overrides Sub DoNetBurst(ByVal Source As WinSECore.IRCNode, ByVal Channel As String, ByVal ts As Integer, ByVal Modes As String, ByVal ModeParams() As String, Optional ByVal Users()() As String = Nothing, Optional ByVal Bans() As String = Nothing, Optional ByVal Excepts() As String = Nothing, Optional ByVal Invites() As String = Nothing)
		'I JUST LOVE SJOIN >_<
		'SJOIN Format:
		':server.name SJOIN ts channel modes [modeparam] :[[[*][~][@][%][+]member]] [[[&ban]["exempt]['invite]]]
		'If for some dumb reason we have a lot of members/bans/exempts to sjoin and/or a really long key/whatever
		'we may need to break up the SJOIN.
		Dim sjoinstr As String
		If ModeParams Is Nothing Then
			sjoinstr = String.Format("{0} {1} !{2} {3} {4} <none> :", GetNSPrefix(Source), IIf(EnableTokens, TOK_SJOIN, "SJOIN"), IntToB64(ts), Channel, Modes)
		Else
			sjoinstr = String.Format("{0} {1} !{2} {3} {4} {5} :", GetNSPrefix(Source), IIf(EnableTokens, TOK_SJOIN, "SJOIN"), IntToB64(ts), Channel, Modes, Join(ModeParams, " "))
		End If
		Dim uidx As Integer, bidx As Integer, eidx As Integer, iidx As Integer, stmp As String
		uidx = 0 : bidx = 0 : eidx = 0 : iidx = 0
		If Users Is Nothing Then
			Users = New String()() {}
		End If
		If Bans Is Nothing Then
			Bans = New String() {}
		End If
		If Excepts Is Nothing Then
			Excepts = New String() {}
		End If
		If Invites Is Nothing Then
			Invites = New String() {}
		End If
		Do Until uidx > UBound(Users) And bidx > UBound(Bans) And eidx > UBound(Excepts) And iidx > UBound(Invites)
			stmp = ""
			If uidx <= UBound(Users) Then
				If InStr(Users(uidx)(1), "q") > 0 Then stmp += "*"
				If InStr(Users(uidx)(1), "a") > 0 Then stmp += "~"
				If InStr(Users(uidx)(1), "o") > 0 Then stmp += "@"
				If InStr(Users(uidx)(1), "h") > 0 Then stmp += "%"
				If InStr(Users(uidx)(1), "v") > 0 Then stmp += "+"
				stmp += Users(uidx)(0)
				uidx += 1
			ElseIf bidx <= UBound(Bans) Then
				stmp = "&" + Bans(bidx)
				bidx += 1
			ElseIf eidx <= UBound(Excepts) Then
				stmp = """" + Excepts(eidx)
				eidx += 1
			ElseIf iidx <= UBound(Invites) AndAlso ProtocolVersion >= 2306 Then
				stmp = "'" + Invites(iidx)
				iidx += 1
			End If
			If sjoinstr = "" Then
				sjoinstr = String.Format("{0} {1} !{2} {3} + <none> :{4} ", GetNSPrefix(Source), IIf(EnableTokens, TOK_SJOIN, "SJOIN"), IntToB64(ts), Channel, stmp)
			ElseIf Len(sjoinstr + stmp) > 510 Then
				c.API.PutServ(RTrim(sjoinstr))
				sjoinstr = ""
			Else
				sjoinstr = sjoinstr & stmp & " "
			End If
		Loop
		If sjoinstr <> "" Then c.API.PutServ(RTrim(sjoinstr))
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
		c.API.PutServ("{0} {1} {2} {3}", GetNSPrefix(Source), IIf(EnableTokens, TOK_SVSJOIN, "SVSJOIN"), Channel, User)
	End Sub
	Public Overrides Sub ForcePart(ByVal Source As WinSECore.IRCNode, ByVal Channel As String, ByVal User As String, ByVal Reason As String)
		c.API.PutServ("{0} {1} {2} {3} :{4}", GetNSPrefix(Source), IIf(EnableTokens, TOK_SVSPART, "SVSPART"), Channel, User, Reason)
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
		Dim source As String, cmd As String, args() As String
		Dim sptr As WinSECore.IRCNode
		Dim temp As String = Buffer, atmp() As String
		c.Events.FireLogMessage("Protocol.Unreal", "DEBUG", "Parsing: " & Buffer)
		If Left(temp, 1) = ":" Then
			atmp = Split(Buffer, " ", 2)
			source = Mid(atmp(0), 2)
			temp = atmp(1)
			If Not c.IRCMap Is Nothing Then
				sptr = c.API.FindNode(source)
				If sptr Is Nothing Then
					If InStr(source, ".") > 0 Then
						SQuitServer(c.Services, source, String.Format("{0}(?) (Unknown server)", source))
					Else
						KillUser(c.Services, source, String.Format("{0}(?) (Unknown user)", source))
					End If
					Return
				End If
			End If
		ElseIf Left(temp, 1) = "@" Then
			atmp = Split(Buffer, " ", 2)
			source = Mid(atmp(0), 2)
			temp = atmp(1)
			If Not c.IRCMap Is Nothing Then
				If c.IRCMap.Numeric = CInt(source) Then
					sptr = c.IRCMap
				Else
					For Each srv As WinSECore.Server In c.IRCMap.GetServers()
						If srv.Numeric = CInt(source) Then
							sptr = srv
							Exit For
						End If
					Next
				End If
				If sptr Is Nothing Then
					If InStr(source, ".") > 0 Then
						SQuitServer(c.Services, source, String.Format("{0}(?) (Unknown server)", source))
					Else
						KillUser(c.Services, source, String.Format("{0}(?) (Unknown user)", source))
					End If
					Return
				End If
			End If
		ElseIf Left(temp, 1) = " " Then		  'Random leading space on some messages is stuffing up the parser.
			sptr = c.IRCMap
			temp = Mid(temp, 2)
		Else
			sptr = c.IRCMap
		End If
		atmp = Split(temp, " ", 2)
		cmd = atmp(0)
		If atmp.Length >= 2 Then
			temp = atmp(1)
			If Left(temp, 1) = ":" Then
				'First argument is a longie.
				args = New String() {Mid(temp, 2)}
			ElseIf InStr(temp, " :") > 0 Then
				'There are some shorties before the longie.
				Dim slong As String = Mid(temp, InStr(temp, " :") + 2)
				'A little trick here: by not subtracting 1 from the InStr return, we leave a trailing space. This causes Split to return
				'an array with an empty element at the end. Guess what gets put in there? :P
				temp = Left(temp, InStr(temp, " :"))
				args = Split(temp, " ")
				'You guessed it :P .
				args(UBound(args)) = slong
			Else
				'All shorties. Split 'em up.
				args = Split(temp, " ")
			End If
		Else
			'Make an empty array. Note that empty array != null array, and it's important that we know there's a difference.
			'An upper bound of -1 makes this an empty array.
			atmp = New String(-1) {}
		End If
		'Now it's Invoke time!
		MyBase.ExecuteCommand(sptr, cmd, args, Buffer)
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
			c.API.PutServ("{0} {1} {2} -ilKVb *!*@* 1", GetNSPrefix(Source), IIf(EnableTokens, TOK_MODE, "MODE"), Channel)
			c.API.PutServ("{0} {1} {2} :Released", GetNSPrefix(Source), IIf(EnableTokens, TOK_PART, "PART"), Channel)
		End If
	End Sub
	Public Overrides Sub SetChMode(ByVal Source As WinSECore.IRCNode, ByVal Channel As String, ByVal Mode As String)
		If TypeOf Source Is WinSECore.Server Then
			c.API.PutServ("{0} {1} {2} {3} {4}", GetNSPrefix(Source), IIf(EnableTokens, TOK_MODE, "MODE"), Channel, Mode, c.API.GetTS())
		Else
			c.API.PutServ("{0} {1} {2} {3}", GetNSPrefix(Source), IIf(EnableTokens, TOK_MODE, "MODE"), Channel, Mode)
		End If
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
		c.API.PutServ("{0} {1} +{2}", GetNSPrefix(Source), IIf(EnableTokens, TOK_SVSNOOP, "SVSNOOP"), Target)
	End Sub
	Public Overloads Overrides Sub SetNoopers(ByVal Source As WinSECore.IRCNode, ByVal Target As String, ByVal Reason As String, ByVal Expiry As System.TimeSpan)
		Throw New NotSupportedException("Auto-expiring NOOP not supported.")
	End Sub
	Public Overrides Sub SetOper(ByVal Source As WinSECore.IRCNode, ByVal Target As String, ByVal Flags As String)
		c.API.PutServ("{0} {1} {2} {3}", GetNSPrefix(Source), IIf(EnableTokens, TOK_SVSO, "SVSO"), Target, Flags)
	End Sub
	Public Overrides Sub UnsetNoopers(ByVal Source As WinSECore.IRCNode, ByVal Target As String)
		c.API.PutServ("{0} {1} -{2}", GetNSPrefix(Source), IIf(EnableTokens, TOK_SVSNOOP, "SVSNOOP"), Target)
	End Sub
	Public Overrides ReadOnly Property VoiceChar() As Char
		Get
			Return "v"c
		End Get
	End Property
	Public Overrides ReadOnly Property SupportFlags() As WinSECore.IRCdSupportFlags
		Get
			Dim flg As WinSECore.IRCdSupportFlags
			flg = WinSECore.IRCdSupportFlags.QUIRK_CHANHOLD_WONTKICK Or WinSECore.IRCdSupportFlags.SUPPORT_BAN_IPADDR Or WinSECore.IRCdSupportFlags.SUPPORT_BAN_NICKNAME Or WinSECore.IRCdSupportFlags.SUPPORT_BAN_REALNAME Or WinSECore.IRCdSupportFlags.SUPPORT_BAN_USERHOST Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_BANEXMPT Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_FORCEJOIN Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_FORCEPART Or _
			WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_HALFOP Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_MASSDEOP Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_MODEHACK Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_NETBURST Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_OWNER Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_PROTECT Or WinSECore.IRCdSupportFlags.SUPPORT_HOLD_NICK Or WinSECore.IRCdSupportFlags.SUPPORT_SERVER_SVSNOOPERS Or WinSECore.IRCdSupportFlags.SUPPORT_TEMPBAN_IPADDR Or _
			WinSECore.IRCdSupportFlags.SUPPORT_TEMPBAN_NICKNAME Or WinSECore.IRCdSupportFlags.SUPPORT_TEMPBAN_USERHOST Or WinSECore.IRCdSupportFlags.SUPPORT_UNBAN_IPADDR Or WinSECore.IRCdSupportFlags.SUPPORT_UNBAN_NICKNAME Or WinSECore.IRCdSupportFlags.SUPPORT_UNBAN_REALNAME Or WinSECore.IRCdSupportFlags.SUPPORT_UNBAN_USERHOST Or WinSECore.IRCdSupportFlags.SUPPORT_USER_FORCENICK Or WinSECore.IRCdSupportFlags.SUPPORT_USER_FORCEUMODE Or WinSECore.IRCdSupportFlags.SUPPORT_USER_SUPERKILL Or _
			WinSECore.IRCdSupportFlags.SUPPORT_USER_SVSOPER Or WinSECore.IRCdSupportFlags.SUPPORT_USER_VHOST Or WinSECore.IRCdSupportFlags.SUPPORT_USER_VIDENT Or WinSECore.IRCdSupportFlags.QUIRK_VIDENT_REPLACES_REALIDENT
			If PrefixAQ Then
				flg = flg Or WinSECore.IRCdSupportFlags.QUIRK_PROTECT_ISOPER
			Else
				flg = flg Or WinSECore.IRCdSupportFlags.QUIRK_OWNER_NOTOPER
			End If
			If ProtocolVersion >= 2306 Then
				flg = flg Or WinSECore.IRCdSupportFlags.QUIRK_INVEX_ONLY_INVONLY Or WinSECore.IRCdSupportFlags.SUPPORT_CHANNEL_INVEX
			End If
		End Get
	End Property
	Public Overrides ReadOnly Property ChanModes() As String
		Get
			If ProtocolVersion >= 2306 Then
				Return "qaohv,beI,kfL,l,psmntirRcOAQKVGCuzNSMTG"
			Else
				Return "qaohv,be,kfL,l,psmntirRcOAQKVGCuzNSMTG"
			End If
		End Get
	End Property
	Public Overrides ReadOnly Property UserModes() As String
		Get
			Return "iowghraAsORTVSxNCWqBzvdHtGp"
		End Get
	End Property
	Public Overrides Function ServiceUMode() As String
		Return "oSqp"
	End Function
	Public Overrides Function InvisServiceUMode() As String
		Return "ioSqp"
	End Function
	Public Overrides Sub SetVHost(ByVal Source As WinSECore.IRCNode, ByVal Target As WinSECore.User, ByVal VHost As String)
		If Source Is Target Then
			c.API.PutServ("{0} {1} {2}", GetNSPrefix(Source), IIf(EnableTokens, TOK_SETHOST, "SETHOST"), VHost)
		Else
			c.API.PutServ("{0} {1} {2} {3}", GetNSPrefix(Source), IIf(EnableTokens, TOK_CHGHOST, "CHGHOST"), Target, VHost)
		End If
	End Sub
	Public Overrides Sub SetVIdent(ByVal Source As WinSECore.IRCNode, ByVal Target As WinSECore.User, ByVal VIdent As String)
		If Source Is Target Then
			c.API.PutServ("{0} {1} {2}", GetNSPrefix(Source), IIf(EnableTokens, TOK_SETIDENT, "SETIDENT"), VIdent)
		Else
			c.API.PutServ("{0} {1} {2} {3}", GetNSPrefix(Source), IIf(EnableTokens, TOK_CHGIDENT, "CHGIDENT"), Target, VIdent)
		End If
	End Sub
	Public Overrides Sub SendNumeric(ByVal Source As WinSECore.IRCNode, ByVal Target As WinSECore.IRCNode, ByVal Numeric As Integer, ByVal Format As String, ByVal ParamArray Parameters() As Object)
		c.API.PutServ("@{0} {1:000} {2} {3}", IntToB64(c.Conf.ServerNumeric), Numeric, Target.Name, String.Format(Format, Parameters))
	End Sub
	Public Overrides Sub SendToAll(ByVal Source As WinSECore.IRCNode, ByVal Message As String)
		c.API.PutServ("{0} {1} $* :{2}", GetNSPrefix(Source), IIf(EnableTokens, TOK_NOTICE, "NOTICE"), Message)
	End Sub
	Public Overrides Sub SendToIRCops(ByVal Source As WinSECore.IRCNode, ByVal Message As String)
		c.API.PutServ("{0} {1} :{2}", GetNSPrefix(Source), IIf(EnableTokens, TOK_GLOBOPS, "GLOBOPS"), Message)
	End Sub
	Public Overrides Sub SendToUMode(ByVal Source As WinSECore.IRCNode, ByVal Usermode As Char, ByVal Message As String)
		c.API.PutServ("{0} {1} {2} :{3}", Source.Name, IIf(EnableTokens, TOK_SMO, "SMO"), Usermode, Message)
	End Sub
	Public Overrides Function IsSAdmin(ByVal u As WinSECore.User) As Boolean
		Return u.Usermodes.IndexOf("a"c) >= 0
	End Function
	Public Overrides Sub SetIdentify(ByVal Source As WinSECore.IRCNode, ByVal Target As String, ByVal Name As String)
		If Name = "" Then
			ForceUMode(Source, Target, "-r")
		Else
			ForceUMode(Source, Target, "+r")
		End If
	End Sub
#End Region
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
		Static b64buf As String = New String(Chr(0), 7)
		Dim i As Integer
		i = 8
		'Unreal does some weird check to see if val is over 2^31-1, but we don't need it since Integer can't do that.
		'Unreal's check just calls abort() if it is over, which we shouldn't do.
		'We probably should just check if val is under 0, since that shouldn't happen anyway.
		If val < 0 Then Throw New ArgumentException("Negative value not permitted.", "val")
		Do
			i = i - 1
			Mid(b64buf, i, 1) = map(val And 63)
			'Now we need to do a 6-bit right shift. Unreal's code uses a signed long, and by C's standard,
			'>> on a signed integer performs an arithmetic shift. This will play havoc if val is < 0 but that
			'shouldn't happen anyway.
			val >>= 6
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
			v <<= 6
			v += map(Asc(Mid(b64, idx, 1)))
		Next idx
		Return v
	End Function
#Region "Command Handlers"
	<WinSECore.Command("LUSERS", False), WinSECore.Command(TOK_LUSERS, True), WinSECore.Command("CLOSE", False), WinSECore.Command(TOK_CLOSE, True), WinSECore.Command("WATCH", False), WinSECore.Command(TOK_WATCH, True), WinSECore.Command("CYCLE", False), WinSECore.Command(TOK_CYCLE, True), WinSECore.Command("ISON", False), WinSECore.Command(TOK_ISON, True), WinSECore.Command("KNOCK", False), WinSECore.Command(TOK_KNOCK, True), WinSECore.Command("USERHOST", False), WinSECore.Command(TOK_USERHOST, True), WinSECore.Command("WHO", False), WinSECore.Command(TOK_WHO, True), WinSECore.Command("SILENCE", False), WinSECore.Command(TOK_SILENCE, True), WinSECore.Command("DNS", False), WinSECore.Command(TOK_DNS, True), WinSECore.Command("POST", False), WinSECore.Command(TOK_POST, True), WinSECore.Command("NEWJOIN", False), WinSECore.Command("SVSNAME", False), WinSECore.Command("REMGLINE", False), WinSECore.Command(TOK_REMGLINE, True), WinSECore.Command("ZLINE", False), WinSECore.Command(TOK_ZLINE, True), _
	WinSECore.Command("GOPER", False), WinSECore.Command(TOK_GOPER, True), WinSECore.Command("GNOTICE", False), WinSECore.Command(TOK_GNOTICE, True), WinSECore.Command("KLINE", False), WinSECore.Command(TOK_KLINE, True), WinSECore.Command("HASH", False), WinSECore.Command(TOK_HASH, True), WinSECore.Command("SERVICE", False), WinSECore.Command(TOK_SERVICE, True), WinSECore.Command("USERS", False), WinSECore.Command(TOK_USERS, True), WinSECore.Command("SUMMON", False), WinSECore.Command(TOK_SUMMON, True), WinSECore.Command("USER", False), WinSECore.Command(TOK_USER, True), WinSECore.Command("CHATOPS", False), WinSECore.Command(TOK_CHATOPS, True), WinSECore.Command("CONNECT", False), WinSECore.Command(TOK_CONNECT, True), WinSECore.Command("LINKS", False), WinSECore.Command(TOK_LINKS, True), WinSECore.Command("LIST", False), WinSECore.Command(TOK_LIST, True), WinSECore.Command("LOCOPS", False), WinSECore.Command(TOK_LOCOPS, True), WinSECore.Command("MAP", False), WinSECore.Command(TOK_MAP, True), _
	WinSECore.Command("MKPASSWD", False), WinSECore.Command(TOK_MKPASSWD, True), WinSECore.Command("VHOST", False), WinSECore.Command(TOK_VHOST, True), WinSECore.Command("NACHAT", False), WinSECore.Command(TOK_NACHAT, True), WinSECore.Command("OPER", False), WinSECore.Command(TOK_OPER, True), WinSECore.Command("SVSFLINE", False), WinSECore.Command(TOK_SVSFLINE, True), WinSECore.Command("SVSJOIN", False), WinSECore.Command(TOK_SVSJOIN, True), WinSECore.Command("SVSLUSERS", False), WinSECore.Command(TOK_SVSLUSERS, True), WinSECore.Command("SVSMOTD", False), WinSECore.Command(TOK_SVSMOTD, True), WinSECore.Command("SVSNOOP", False), WinSECore.Command(TOK_SVSNOOP, True), WinSECore.Command("SVSO", False), WinSECore.Command(TOK_SVSO, True), WinSECore.Command("SVSPART", False), WinSECore.Command(TOK_SVSPART, True), WinSECore.Command("SVSSILENCE", False), WinSECore.Command(TOK_SVSSILENCE, True), WinSECore.Command("SVS2SNO", False), WinSECore.Command(TOK_SVS2SNO, True), WinSECore.Command("SVSSNO", False), _
	WinSECore.Command(TOK_SVSSNO, True), WinSECore.Command("SVSWATCH", False), WinSECore.Command(TOK_SVSWATCH, True), WinSECore.Command("UNKLINE", False), WinSECore.Command(TOK_UNKLINE, True), WinSECore.Command("UNSQLINE", False), WinSECore.Command(TOK_UNSQLINE, True), WinSECore.Command("UNZLINE", False), WinSECore.Command(TOK_UNZLINE, True), WinSECore.Command("WALLOPS", False), WinSECore.Command(TOK_WALLOPS, True), WinSECore.Command("ADDLINE", False), WinSECore.Command(TOK_ADDLINE, True), WinSECore.Command("ADDMOTD", False), WinSECore.Command(TOK_ADDMOTD, True), WinSECore.Command("ADDOMOTD", False), WinSECore.Command(TOK_ADDOMOTD, True), WinSECore.Command("ADCHAT", False), WinSECore.Command(TOK_ADCHAT, True), WinSECore.Command("SVS2MODE", False), WinSECore.Command(TOK_SVS2MODE, True), WinSECore.Command("SVSMODE", False), WinSECore.Command(TOK_SVSMODE, True), WinSECore.Command("GLOBOPS", False), WinSECore.Command(TOK_GLOBOPS, True), WinSECore.Command("SMO", False), WinSECore.Command("AU", True), _
	WinSECore.Command("SENDSNO", False), WinSECore.Command("Ss", True), WinSECore.Command("SENDUMODE", False), WinSECore.Command("AP", True), _
	WinSECore.Command("NAMES", False), WinSECore.Command(TOK_NAMES, True), WinSECore.Command("HTM", False), WinSECore.Command(TOK_HTM, True), _
	WinSECore.Command("UNDCCDENY", False), WinSECore.Command("BJ", True), WinSECore.Command("TEMPSHUN", False), WinSECore.Command("Tz", True), _
	WinSECore.Command("DCCDENY", False), WinSECore.Command("BI", True)> _
	Public Sub IgnoreCommand(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)

	End Sub
#Region "Stubs from ignored commands. Keeping them around ""just in case""."
	Public Sub CmdUnDCCDeny(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdTempShun(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdDCCDeny(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdHTM(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdNames(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSendUMode(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSMO(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSendSNO(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdDns(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdWatch(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdRemGLine(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSVSName(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdNewJoin(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdPost(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdGlobOps(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSVSMode(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSVS2Mode(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdAdChat(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdAddOMOTD(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdAddMOTD(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdAddLine(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdWallOps(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdVHost(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdUnZLine(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdUnSQLine(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdUnKLine(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSVSWatch(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSVSSNO(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSVS2SNO(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSVSSilence(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSVSPart(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSVSO(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSVSNOOP(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSVSMOTD(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSVSLUsers(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSVSJoin(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSVSFLine(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdOper(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdNAChat(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdMkPassWd(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdMap(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdLocOps(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdList(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdLinks(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdConnect(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdChatOps(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdUser(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSummon(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdUsers(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdService(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdHash(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdKLine(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdGNotice(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdGOper(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdZLine(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdWho(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdUserHost(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdSilence(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdKnock(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdIsOn(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdCycle(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdClose(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
	Public Sub CmdLUsers(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
	End Sub
#End Region
	<WinSECore.Command("TKL", False), WinSECore.Command(TOK_TKL, True)> Public Sub CmdTkl(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
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
		'OKAY, it's fun time!
		'In all formats, a minimum of 5 parameters are present.
		If args.Length < 5 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 5) in TKL (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		If args(0) = "+" Then
			If args.Length < 8 Then
				c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 8) in TKL (Buffer = {1})", args.Length, rawcmd))
				Return
			End If
			Dim b As New WinSECore.IRCBan
			b.Reason = args(7)
			b.ExpireTS = Integer.Parse(args(5))
			Select Case args(1)
				Case "G"
					b.Mask = args(2) + "@" + args(3)
					c.UserhostBans.Add(b)
				Case "Q"
					b.Mask = args(3)
					c.NickBans.Add(b)
				Case "Z"
					b.Mask = args(3)
					c.IPBans.Add(b)
				Case "S"
					b.Mask = args(2) + "@" + args(3)
					c.Squelches.Add(b)
				Case "F"
				Case Else
					c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Invalid TKL Type {0}! (Buffer = {1})", args(1), rawcmd))
			End Select
		ElseIf args(0) = "-" Then
			Select Case args(1)
				Case "G"
					If c.UserhostBans.Contains(args(2) + "@" + args(3)) Then
						c.UserhostBans.Remove(c.UserhostBans(args(2) + "@" + args(3)))
					End If
				Case "Q"
					If c.NickBans.Contains(args(3)) Then
						c.NickBans.Remove(c.UserhostBans(args(3)))
					End If
				Case "Z"
					If c.IPBans.Contains(args(3)) Then
						c.IPBans.Remove(c.UserhostBans(args(3)))
					End If
				Case "S"
					If c.Squelches.Contains(args(2) + "@" + args(3)) Then
						c.Squelches.Remove(c.UserhostBans(args(2) + "@" + args(3)))
					End If
				Case "F"
				Case Else
					c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Invalid TKL Type {0}! (Buffer = {1})", args(1), rawcmd))
			End Select
		Else
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Invalid TKL Action {0}! (Buffer {1})", args(0), rawcmd))
		End If
	End Sub
	<WinSECore.Command("NICK", False), WinSECore.Command(TOK_NICK, True)> Public Sub CmdNick(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'New user or nick change.
		Dim cptr As WinSECore.IRCNode
		If TypeOf Source Is WinSECore.User Then
			'Nick change...
			If args.Length > 1 Then
				c.Events.FireLogMessage("Protocol.Unreal", "WARNING", "Extra parameters in NICK change! Buffer = " + rawcmd)
			End If
			cptr = c.API.FindNode(args(0))
			If LCase(Source.Name) = LCase(args(0)) OrElse cptr Is Nothing Then
				'Case change or user not found. So it's an okay nickchange.
				Dim oldnick As String = Source.Name
				Source.Name = args(0)
				c.Events.FireClientNickChange(DirectCast(Source, WinSECore.User), oldnick, args(0))
			ElseIf TypeOf cptr Is WinSECore.Server Then
				c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("NICK Change Collision with Server object at {0} ({1}@{2} <-> {3}@{4})!", args(0), DirectCast(cptr, WinSECore.User).Username, DirectCast(cptr, WinSECore.User).Hostname, DirectCast(Source, WinSECore.User).Username, DirectCast(Source, WinSECore.User).Hostname))
				KillUser(c.Services, args(0), "Nick change collision")
				c.Events.FireClientKilled(c.Services, DirectCast(Source, WinSECore.User), "Nick change collision")
				c.Events.FireClientQuit(DirectCast(Source, WinSECore.User), "Killed: Nick change collision")
				Source.Dispose()
			Else
				c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("NICK Change Collision at {0} ({1}@{2} <-> {3}@{4})!", args(0), DirectCast(cptr, WinSECore.User).Username, DirectCast(cptr, WinSECore.User).Hostname, DirectCast(Source, WinSECore.User).Username, DirectCast(Source, WinSECore.User).Hostname))
				KillUser(c.Services, args(0), "Nick change collision")
				c.Events.FireClientKilled(c.Services, DirectCast(Source, WinSECore.User), "Nick change collision")
				c.Events.FireClientQuit(DirectCast(Source, WinSECore.User), "Killed: Nick change collision")
				Source.Dispose()
				c.Events.FireClientKilled(c.Services, DirectCast(cptr, WinSECore.User), "Nick change collision")
				c.Events.FireClientQuit(DirectCast(cptr, WinSECore.User), "Killed: Nick change collision")
				cptr.Dispose()
			End If
		ElseIf TypeOf Source Is WinSECore.Server Then
			'New user, or at least... it should be.
			'Format of this:
			'@servernum NICK nick hops ts user host server stamp umodes vhost[ ipaddr] :real name
			If args.Length < 10 Then
				c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("Insufficient parameters ({0} < 10) in NICK introduction! Buffer = {1}", args.Length, rawcmd))
			ElseIf args.Length = 10 Then
				'No NICKIP.
				cptr = c.API.FindNode(args(0))
				If cptr Is Nothing Then
					'Ok, create a new user object.
					Dim sptr As WinSECore.IRCNode
					If c.IRCMap.Name = args(5) OrElse c.IRCMap.Numeric = Val(args(5)) Then
						sptr = c.IRCMap
					Else
						For Each srv As WinSECore.Server In c.IRCMap.GetServers()
							If srv.Name = args(5) OrElse srv.Numeric = Val(args(5)) Then
								sptr = srv
								Exit For
							End If
						Next
					End If
					If sptr Is Nothing Then
						c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Missing server {0} for client {1}! (Buffer = {2})", args(5), args(0), rawcmd))
						KillUser(c.Services, args(0), "Unknown server: " + args(5))
						Exit Sub
					ElseIf Not (Left(args(2), 1) = "!" OrElse IsNumeric(args(2))) Then
						c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Bad TimeStamp (not an integer or base64 TS) {0} for client {1}! (Buffer = {2})", args(2), args(0), rawcmd))
						KillUser(c.Services, args(0), "Bad TS: " + args(2))
						Exit Sub
					ElseIf Not IsNumeric(args(6)) Then
						c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Bad service stamp {0} (not an integer) for client {1}! (Buffer = {2})", args(6), args(0), rawcmd))
						KillUser(c.Services, args(0), "Bad Stamp: " + args(6))
						Exit Sub
					End If
					cptr = New WinSECore.User(c)
					With DirectCast(cptr, WinSECore.User)
						.AwayMessage = Nothing
						.IdentifiedNick = Nothing
						.SWhois = Nothing
						.Nick = args(0)
						If Left(args(2), 1) = "!" Then
							.TS = B64ToInt(Mid(args(2), 2))
						Else
							.TS = CInt(args(2))
						End If
						.Username = args(3)
						.Hostname = args(4)
						.Server = DirectCast(sptr, WinSECore.Server)
						If Left(args(6), 1) = "!" Then
							.TS = B64ToInt(Mid(args(6), 2))
						Else
							.TS = CInt(args(6))
						End If
						.Usermodes = args(7)
						.VHost = DirectCast(IIf(args(8) <> "*", args(8), Nothing), String)
						.VIdent = .Username
						.RealName = args(9)
						.SendMessage = AddressOf c.API.SendMsg_NOTICE
					End With
					DirectCast(sptr, WinSECore.Server).SubNodes.Add(cptr)
					c.Events.FireClientConnect(DirectCast(sptr, WinSECore.Server), DirectCast(cptr, WinSECore.User))
				ElseIf TypeOf cptr Is WinSECore.Server Then
					c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Nick/Server Collision at {0}!", args(0)))
					KillUser(c.Services, args(0), "Nick/Server collision")
					c.Events.FireClientKilled(c.Services, DirectCast(cptr, WinSECore.User), "Nick/Server collision")
					c.Events.FireClientQuit(DirectCast(cptr, WinSECore.User), "Killed: Nick/Server collision")
					cptr.Dispose()
				Else
					c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Nick Collision at {0}!", args(0)))
					KillUser(c.Services, args(0), "Nick Collision")
					c.Events.FireClientKilled(c.Services, DirectCast(cptr, WinSECore.User), "Nick Collision")
					c.Events.FireClientQuit(DirectCast(cptr, WinSECore.User), "Killed: Nick Collision")
					cptr.Dispose()
				End If
			ElseIf args.Length >= 11 Then
				'Has NICKIP.
				cptr = c.API.FindNode(args(0))
				If cptr Is Nothing Then
					'Ok, create a new user object.
					Dim sptr As WinSECore.IRCNode, b() As Byte
					If c.IRCMap.Name = args(5) OrElse c.IRCMap.Numeric = Val(args(5)) Then
						sptr = c.IRCMap
					Else
						For Each srv As WinSECore.Server In c.IRCMap.GetServers()
							If srv.Name = args(5) OrElse srv.Numeric = Val(args(5)) Then
								sptr = srv
								Exit For
							End If
						Next
					End If
					If sptr Is Nothing Then
						c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Missing server {0} for client {1}! (Buffer = {2})", args(5), args(0), rawcmd))
						KillUser(c.Services, args(0), "Unknown server: " + args(5))
						Exit Sub
					End If
					If sptr Is Nothing Then
						c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Missing server {0} for client {1}! (Buffer = {2})", args(5), args(0), rawcmd))
						KillUser(c.Services, args(0), "Unknown server: " + args(5))
						Exit Sub
					ElseIf Not (Left(args(2), 1) = "!" OrElse IsNumeric(args(2))) Then
						c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Bad TimeStamp (not an integer or base64 TS) {0} for client {1}! (Buffer = {2})", args(2), args(0), rawcmd))
						KillUser(c.Services, args(0), "Bad TS: " + args(2))
						Exit Sub
					ElseIf Not IsNumeric(args(6)) Then
						c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Bad Hopcount {0} (not an integer) for client {1}! (Buffer = {2})", args(6), args(0), rawcmd))
						KillUser(c.Services, args(0), "Unknown server: " + args(5))
						Exit Sub
					End If
					cptr = New WinSECore.User(c)
					With DirectCast(cptr, WinSECore.User)
						.AwayMessage = Nothing
						.IdentifiedNick = Nothing
						.SWhois = Nothing
						.Nick = args(0)
						If Left(args(2), 1) = "!" Then
							.TS = B64ToInt(Mid(args(2), 2))
						Else
							.TS = CInt(args(2))
						End If
						.Username = args(3)
						.Hostname = args(4)
						.Server = DirectCast(sptr, WinSECore.Server)
						If Left(args(6), 1) = "!" Then
							.TS = B64ToInt(Mid(args(6), 2))
						Else
							.TS = CInt(args(6))
						End If
						.Usermodes = args(7)
						.VHost = DirectCast(IIf(args(8) <> "*", args(8), Nothing), String)
						.VIdent = .Username
						b = WinSECore.API.B64Decode(args(9))
						If b.Length = 4 Then
							.IP = System.Net.IPAddress.Parse(String.Format("{0}.{1}.{2}.{3}", b(0), b(1), b(2), b(3)))
						Else
							.IP = New System.Net.IPAddress(b)
						End If
						.RealName = args(10)
						.SendMessage = AddressOf c.API.SendMsg_NOTICE
					End With
					DirectCast(sptr, WinSECore.Server).SubNodes.Add(cptr)
					c.Events.FireClientConnect(DirectCast(sptr, WinSECore.Server), DirectCast(cptr, WinSECore.User))
				ElseIf TypeOf cptr Is WinSECore.Server Then
					c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Nick/Server Collision at {0}!", args(0)))
					KillUser(c.Services, args(0), "Nick/Server collision")
					c.Events.FireClientKilled(c.Services, DirectCast(cptr, WinSECore.User), "Nick/Server collision")
					c.Events.FireClientQuit(DirectCast(cptr, WinSECore.User), "Killed: Nick/Server collision")
					cptr.Dispose()
				Else
					c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Nick Collision at {0}!", args(0)))
					KillUser(c.Services, args(0), "Nick Collision")
					c.Events.FireClientKilled(c.Services, DirectCast(cptr, WinSECore.User), "Nick Collision")
					c.Events.FireClientQuit(DirectCast(cptr, WinSECore.User), "Killed: Nick Collision")
					cptr.Dispose()
				End If
			End If
		End If
	End Sub
	<WinSECore.Command("SVSKILL", False), WinSECore.Command(TOK_SVSKILL, True)> Public Sub CmdSVSKill(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		Dim acptr As WinSECore.IRCNode
		If args.Length < 2 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 2) in SVSKILL (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		acptr = c.API.FindNode(args(0))
		If acptr Is Nothing Then
			c.Events.FireLogMessage("Protocol.Unreal", "WARNING", "Non-existant user " + args(0) + " targeted by SVSKILL?!")
		Else
			c.Events.FireClientKilled(Source, DirectCast(acptr, WinSECore.User), "SVSKILL: " + args(1))
			c.Events.FireClientQuit(DirectCast(acptr, WinSECore.User), "SVSKilled: " + args(1))
			acptr.Dispose()
		End If
	End Sub
	<WinSECore.Command("KILL", False), WinSECore.Command(TOK_KILL, True)> Public Sub CmdKill(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		Dim acptr As WinSECore.IRCNode
		If args.Length < 2 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 2) in KILL (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		acptr = c.API.FindNode(args(0))
		If acptr Is Nothing Then
			c.Events.FireLogMessage("Protocol.Unreal", "WARNING", "Non-existant user " + args(0) + " targeted by KILL?!")
		Else
			c.Events.FireClientKilled(Source, DirectCast(acptr, WinSECore.User), args(1))
			c.Events.FireClientQuit(DirectCast(acptr, WinSECore.User), "Killed: " + args(1))
			acptr.Dispose()
		End If
	End Sub
	<WinSECore.Command("SVSNICK", False), WinSECore.Command(TOK_SVSNICK, True)> Public Sub CmdSVSNick(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'Blah
	End Sub
	<WinSECore.Command("SJOIN", False), WinSECore.Command(TOK_SJOIN, True)> Public Sub CmdSJoin(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'Remember the format for this...? No? OK, here it is:
		':server.name SJOIN ts channel modes [modeparam] :[[[*][~][@][%][+]member]] [[[&ban]["exempt]['invite]]]
		Dim chptr As WinSECore.Channel, ts As Integer, mode As String, modeparam As String, extra As String
		Dim userinf As New WinSECore.Nodes, modeinf As New StringCollection
		If args.Length < 3 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 5) in SJOIN (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		If Left(args(0), 1) = "!" Then
			ts = B64ToInt(Mid(args(0), 2))
		ElseIf Not IsNumeric(args(0)) Then
			c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("Invalid TS {0} in SJOIN {1}! (Buffer = {2})", args(0), args(1), rawcmd))
			ts = 0
		Else
			ts = Integer.Parse(args(0))
		End If
		If c.Channels.Contains(args(1)) Then
			chptr = c.Channels(args(1))
		End If
		If args.Length = 3 Then
			extra = args(2)
		ElseIf args.Length = 4 Then
			mode = args(2)
			extra = args(3)
			modeinf.Add(mode)
		ElseIf args.Length >= 5 Then
			mode = args(2)
			modeparam = String.Join(" ", args, 3, args.Length - 4)			 'Leave the last parameter alone.
			extra = args(args.Length - 1)
			If LCase(modeparam) = "<*>" OrElse LCase(modeparam) = "<none>" Then modeparam = Nothing
			modeinf.Add(mode + IIf(modeparam = "", "", " " + modeparam).ToString())
		End If
		For Each s As String In Split(extra, " ")
			If s <> "" Then
				Select Case Left(s, 1)
					Case "&"
						modeinf.Add("+b " + Mid(s, 2))
					Case """"
						modeinf.Add("+e " + Mid(s, 2))
					Case "'"
						modeinf.Add("+I " + Mid(s, 2))
					Case Else
						Dim nick As String = s, modes As String = "", acptr As WinSECore.IRCNode
						While InStr("*~@%+", Left(nick, 1)) > 0
							modes += Mid("qaohv", InStr("*~@%+", Left(nick, 1)), 1)
							nick = Mid(nick, 2)
						End While
						acptr = c.API.FindNode(nick)
						If acptr Is Nothing Then
							c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Unknown user {0} in SJOIN {1}!", nick, args(1)))
							KillUser(c.Services, args(1), "Unknown user")
						Else
							userinf.Add(acptr)
							If modes <> "" Then
								modeinf.Add("+" + modes + " " + RTrim(Replace(New String(Chr(0), modes.Length), Chr(0), nick + " ")))
							End If
						End If
				End Select
			End If
		Next
		If chptr Is Nothing Then
			'Channel Create
			c.Events.FireLogMessage("Protocol.Unreal", "TRACE", String.Format("SJOIN from {0} creating channel {1} (TS = {2})", Source.Name, args(1), ts))
			chptr = New WinSECore.Channel(c)
			With chptr
				.Name = args(1)
				.TS = ts
			End With
			c.Channels.Add(chptr)
		ElseIf ts < chptr.TS AndAlso ts > 0 Then
			'SJOIN with earlier time stamp. Wipe existing mode info.
			c.Events.FireLogMessage("Protocol.Unreal", "TRACE", String.Format("SJOIN from {0} replacing modes on channel {1} (SJOIN TS {2} < Existing TS {3})", Source.Name, args(1), ts, chptr.TS))
			With chptr
				.SetModes(Source, "-" & .ParamlessModes, True)
				.SetModes(Source, "-" & Join(DirectCast(New ArrayList(.ParamedModes.Keys).ToArray(GetType(String)), String()), ""), True)
				.SetModes(Source, "-" & New String("b"c, .ListModes.Count) & " " & Join(DirectCast(New ArrayList(.ListModes("b"c)).ToArray(GetType(String)), String()), " "), True)
				.SetModes(Source, "-" & New String("b"c, .ListModes.Count) & " " & Join(DirectCast(New ArrayList(.ListModes("b"c)).ToArray(GetType(String)), String()), " "), True)
				If ProtocolVersion >= 2306 Then .SetModes(Source, "-" & New String("e"c, .ListModes.Count) & " " & Join(DirectCast(New ArrayList(.ListModes("I"c)).ToArray(GetType(String)), String()), " "), True)
				For Each m As WinSECore.ChannelMember In .UserList
					.SetModes(Source, "-" & m.Status & " " & RTrim(Replace(New String(Chr(0), m.Status.Length), Chr(0), m.Who.Name + " ")), True)
				Next
				.TS = ts
			End With
		ElseIf ts = chptr.TS OrElse ts = 0 Then
			'Merge existing info.
			c.Events.FireLogMessage("Protocol.Unreal", "TRACE", String.Format("SJOIN from {0} merging modes into channel {1} (TS = {2})", Source.Name, args(1), ts))
		ElseIf ts > chptr.TS Then
			c.Events.FireLogMessage("Protocol.Unreal", "TRACE", String.Format("Ignoring modes in SJOIN from {0} on channel {1} (SJOIN TS {2} > Existing TS {3})", Source.Name, args(1), ts, chptr.TS))
			modeinf.Clear()
		End If
		'Now add the users...
		For Each u As WinSECore.IRCNode In userinf
			If c.Channels(args(1)).UserList.Contains(DirectCast(u, WinSECore.User)) Then
				c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("User {1} in SJOIN {0} is already in the channel!", chptr.Name, Source.Name))
			Else
				chptr.UserList.Add(New WinSECore.ChannelMember(DirectCast(u, WinSECore.User)))
				c.Events.FireClientJoin(DirectCast(u, WinSECore.User), chptr)
			End If
		Next
		'Now parse the mode information.
		For Each s As String In modeinf
			chptr.SetModes(Source, s)
		Next
	End Sub
	<WinSECore.Command("JOIN", False), WinSECore.Command(TOK_JOIN, True)> Public Sub CmdJoin(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		Dim chptr As WinSECore.Channel
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in JOIN (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		If Not TypeOf Source Is WinSECore.User Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Non-user {0} joining channel {1}!", Source.Name, args(0)))
			Return
		End If
		'Now we have to find this channel.
		If c.Channels.Contains(args(0)) Then
			chptr = c.Channels(args(0))
		Else
			chptr = New WinSECore.Channel(c)
			chptr.Name = args(0)
			chptr.TS = c.API.GetTS()
			c.Channels.Add(chptr)
		End If
		If c.Channels(args(0)).UserList.Contains(DirectCast(Source, WinSECore.User)) Then
			c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("Ignoring duplicate JOIN {0} from {1}", chptr.Name, Source.Name))
		Else
			chptr.UserList.Add(New WinSECore.ChannelMember(DirectCast(Source, WinSECore.User)))
			c.Events.FireClientJoin(DirectCast(Source, WinSECore.User), chptr)
		End If
	End Sub
	<WinSECore.Command("MODE", False), WinSECore.Command(TOK_MODE, True)> Public Sub CmdMode(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		Dim chptr As WinSECore.Channel, acptr As WinSECore.IRCNode, modes As String, ts As Integer
		If args.Length < 2 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 2) in MODE (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		If args(0).Chars(0) = "#"c Then
			If c.Channels.Contains(args(0)) Then
				chptr = c.Channels(args(0))
				'We have to pull a P10[1] here. If the last argument is numeric, pull it out of the way.
				If IsNumeric(args(args.Length - 1)) Then
					ts = Integer.Parse(args(args.Length - 1))
					modes = String.Join(" ", args, 1, args.Length - 2)
				Else
					ts = chptr.TS
					modes = String.Join(" ", args, 1, args.Length - 1)
				End If
				'Now we have to obey TS here.
				If ts > 0 Then
					If ts > chptr.TS Then
						'Blah.
						c.Events.FireLogMessage("Protocol.Unreal", "TRACE", String.Format("Ignoring TS MODE {0} {1} (TS {2} > {3})", args(0), modes, ts, chptr.TS))
						Return
					ElseIf ts < chptr.TS Then
						c.Events.FireLogMessage("Protocol.Unreal", "TRACE", String.Format("Replacing modes on {0} with TS MODE {1} (TS {2} < {3})", args(0), modes, ts, chptr.TS))
						With chptr
							.SetModes(Source, "-" & .ParamlessModes)
							.SetModes(Source, "-" & Join(DirectCast(New ArrayList(.ParamedModes.Keys).ToArray(GetType(String)), String()), ""))
							.SetModes(Source, "-" & New String("b"c, .ListModes.Count) & " " & Join(DirectCast(New ArrayList(.ListModes("b"c)).ToArray(GetType(String)), String()), " "))
							.SetModes(Source, "-" & New String("b"c, .ListModes.Count) & " " & Join(DirectCast(New ArrayList(.ListModes("b"c)).ToArray(GetType(String)), String()), " "))
							If ProtocolVersion >= 2306 Then .SetModes(Source, "-" & New String("e"c, .ListModes.Count) & " " & Join(DirectCast(New ArrayList(.ListModes("I"c)).ToArray(GetType(String)), String()), " "))
							For Each m As WinSECore.ChannelMember In .UserList
								.SetModes(Source, "-" & m.Status & " " & RTrim(Replace(New String(Chr(0), m.Status.Length), Chr(0), m.Who.Name + " ")))
							Next
							.TS = ts
						End With
					End If
				End If
				chptr.SetModes(Source, modes)
				'[1] = P10 defines for reading parameters counting from the end as well as the beginning. We read the TS from the end when it
				'      is present which is a very P10ish thing to do :-) .
			Else
				c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("MODE for nonexistant channel {0}!", args(0)))
			End If
		Else
			acptr = c.API.FindNode(args(0))
			If acptr Is Nothing Then
				c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("MODE for nonexistant user {0}", args(0)))
				KillUser(c.Services, args(0), String.Format("{0}? (Unknown user)", args(0)))
			ElseIf Not TypeOf acptr Is WinSECore.User Then
				c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("MODE for non-user {0}", args(0)))
			Else
				With DirectCast(acptr, WinSECore.User)
					.SetUserModes(args(1), Source)
				End With
			End If
		End If
	End Sub
	<WinSECore.Command("PART", False), WinSECore.Command(TOK_PART, True)> Public Sub CmdPart(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		Dim chptr As WinSECore.Channel
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in PART (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		If Not TypeOf Source Is WinSECore.User Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Non-user {0} parting channel {1}!", Source.Name, args(0)))
			Return
		End If
		If Not c.Channels.Contains(args(0)) Then
			c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("User {0} PARTed non-existant channel {1}!", Source.Name, args(0)))
			Return
		End If
		chptr = c.Channels(args(0))
		If Not chptr.UserList.Contains(DirectCast(Source, WinSECore.User)) Then
			c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("User {0} PARTed channel {1} but wasn't even in it!", Source.Name, args(0)))
			Return
		End If
		chptr.UserList.Remove(chptr.UserList(DirectCast(Source, WinSECore.User)))
		If chptr.UserList.Count = 0 Then
			c.Channels.Remove(chptr)
		End If
		If args.Length > 1 Then
			c.Events.FireClientPart(DirectCast(Source, WinSECore.User), chptr, args(1))
		Else
			c.Events.FireClientPart(DirectCast(Source, WinSECore.User), chptr, Nothing)
		End If
	End Sub
	<WinSECore.Command("QUIT", False), WinSECore.Command(TOK_QUIT, True)> Public Sub CmdQuit(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If Not TypeOf Source Is WinSECore.User Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Non-user {0} quitting!", Source.Name))
			Return
		End If
		If args.Length < 1 Then
			c.Events.FireClientQuit(DirectCast(Source, WinSECore.User), Nothing)
		Else
			c.Events.FireClientQuit(DirectCast(Source, WinSECore.User), args(0))
		End If
		'Loop through their channels and remove any that will become empty.
		For Each chptr As WinSECore.Channel In DirectCast(Source, WinSECore.User).Channels
			If chptr.UserList.Count = 1 AndAlso chptr.UserList(0) Is Source Then
				c.Channels.Remove(chptr)
			End If
		Next
		Source.Dispose()
	End Sub
	<WinSECore.Command("SQUIT", False), WinSECore.Command(TOK_SQUIT, True)> Public Sub CmdSQuit(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		Dim acptr As WinSECore.IRCNode
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in PART (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		acptr = c.API.FindNode(args(0))
		If acptr Is Nothing OrElse Not TypeOf acptr Is WinSECore.Server Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("SQUIT targeting user or non-existant server {0}", args(0)))
			Return
		End If
		'Ok, time for mass-fun-recursive Dispose() crap!
		If args.Length < 2 Then
			c.Events.FireServerQuit(DirectCast(acptr, WinSECore.Server), "Netsplit")
		Else
			c.Events.FireServerQuit(DirectCast(acptr, WinSECore.Server), args(1))
		End If
		acptr.Dispose()
	End Sub
	<WinSECore.Command("SERVER", False), WinSECore.Command(TOK_SERVER, True)> Public Sub CmdServer(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'Possible formats:
		'SERVER <server.name> <hopcount> :<info> (New server without NS or VL).
		'SERVER <server.name> <hopcount> :U<proto>-<flags> <info> (Uplink server +VL -NS)
		'SERVER <server.name> <hopcount> :U<proto>-<flags>-<numeric> <info> (Uplink server +VL +NS)
		'SERVER <server.name> <hopcount> <numeric> :<info> (Remote Server +VL +NS)
		Dim name As String, hops As Integer, numeric As Integer = -1, protover As Integer, protoflags As String, info As String
		If args.Length < 3 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 3) in SERVER (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		name = args(0)
		If Not IsNumeric(args(1)) Then
			c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("Invalid hopcount {0} for server {1} (using hopcount of 2) (Buffer = {2})", args(1), args(0), rawcmd))
			hops = 2
		Else
			hops = Integer.Parse(args(1))
		End If
		If args.Length = 3 Then
			If c.IRCMap Is Nothing Then
				'IRCMap hasn't been initialized, which means this is the uplink server. This means we're about to get connected!
				'Possible formats:
				'SERVER <server.name> <hopcount> :<info> (New server without NS or VL).
				'SERVER <server.name> <hopcount> :U<proto>-<flags> <info> (Uplink server +VL -NS)
				'SERVER <server.name> <hopcount> :U<proto>-<flags>-<numeric> <info> (Uplink server +VL +NS)
				If name <> c.Conf.UplinkName Then
					c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("First SERVER message did not name the uplink ({0} != {1}). Possibly wrong IP in the configuration!", name, c.Conf.UplinkName))
					c.API.ExitServer("No matching link configuration")
					Return
				Else
					If ProtoCtl.Contains("VL") Then
						Dim tmp() As String = Split(Split(args(2), " ", 2)(0), "-")
						info = Split(args(2), " ", 2)(1)
						If tmp(0).Chars(0) <> "U"c Then
							c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("Incorrect VL information leader '{0}' (wanted 'U')", tmp(0).Chars(0)))
							info = args(2)
						ElseIf Not IsNumeric(Mid(tmp(0), 2)) Then
							c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("Invalid protocol number {0} (not an integer)", Mid(tmp(0), 2)))
						Else
							protover = Integer.Parse(Mid(tmp(0), 2))
							If ProtocolVersion <> 0 AndAlso protover <> ProtocolVersion Then
								c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("Configured Protocol Version {0} does not match uplink's advertised protocol version {1}, switching to version {1}", ProtocolVersion, protover))
								ProtocolVersion = protover
							End If
							If ProtoCtl.Contains("NS") Then
								If tmp.Length < 3 Then
									c.Events.FireLogMessage("Protocol.Unreal", "WARNING", "Uplink advertised NS support but did not send a numeric!")
									numeric = -1
								ElseIf Not IsNumeric(tmp(2)) Then
									c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Invalid numeric {0} (not an integer)!", tmp(2)))
									c.API.ExitServer("Invalid numeric")
									Return
								Else
									numeric = Integer.Parse(tmp(2))
									If numeric < 0 OrElse numeric > 254 Then
										c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Invalid numeric {0} (out of range)", numeric))
										c.API.ExitServer("Invalid numeric")
										Return
									End If
									If numeric = c.Conf.ServerNumeric Then
										c.Events.FireLogMessage("Protocol.Unreal", "ERROR", "NUMERIC COLLISION: Uplink wants to use our numeric! (Should we be getting this far?)")
										c.API.ExitServer("Numeric collision")
										Return
									End If
								End If
							Else
								numeric = -1
							End If
						End If
					Else
						info = args(2)
						numeric = -1
					End If
					c.IRCMap = New WinSECore.Server(c)
					With c.IRCMap
						.Name = name
						.Numeric = numeric
						.Info = info
					End With
					c.Events.FireServerConnect(c.IRCMap, Nothing)
					c.Events.FireServerInit()
				End If
			Else
				'Introducing a new server.
				'sptr is the new server's uplink.
				Dim cptr As WinSECore.IRCNode
				'Possible formats:
				'SERVER <server.name> <hopcount> :<info> (New server without NS or VL).
				'SERVER <server.name> <hopcount> <numeric> :<info> (Remote Server +VL +NS)
				'It better not already exist...
				cptr = c.API.FindNode(args(0))
				If Not cptr Is Nothing Then
					'COLLISION!!!!!!!!!!!!!!!!!!!!!!
					'In the case of server collisions, we are probably so screwed that there really is nothing else for it. Since Unreal
					'handles a collision like this by simply exiting the direct connection the SERVER message came from, that's we're going
					'to do: just assume we're so desynched that the only way out is to unlink.
					c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("Collision by introduction of server {0}. Assuming majorly desynched - squitting."))
					c.Events.FireServerTerm()
					c.Events.FireServerQuit(c.IRCMap, "Link cancelled (Server collision)")
					c.IRCMap.Dispose()
					c.IRCMap = Nothing
					c.API.ExitServer("Link cancelled (Server collision)")
					Return
				End If
				cptr = New WinSECore.Server(c)
				With DirectCast(cptr, WinSECore.Server)
					If args.Length = 3 Then
						.Name = args(0)
						.Numeric = -1
						.Info = args(2)
					ElseIf Not IsNumeric(args(2)) Then
						c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("Invalid numeric {0} for server {1} (not an integer)!", args(2), args(0)))
						.Name = args(0)
						.Numeric = -1
						.Info = args(3)
					ElseIf args.Length >= 4 Then
						.Name = args(0)
						.Numeric = Integer.Parse(args(2))
						.Info = args(3)
					End If
					.Parent = DirectCast(Source, WinSECore.Server)
				End With
				DirectCast(Source, WinSECore.Server).SubNodes.Add(cptr)
			End If
		End If
	End Sub
	<WinSECore.Command("PRIVMSG", False), WinSECore.Command(TOK_PRIVMSG, True)> Public Sub CmdPrivMsg(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If TypeOf Source Is WinSECore.Server Then
			'This isn't really an error at all, we just ignore it.
			Return
		End If
		If args.Length < 2 Then
			'This on the other hand, is.
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 2) in PRIVMSG (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		Dim target As WinSECore.IRCNode, msg As String
		target = c.API.FindNode(IIf(args(0).IndexOf("@"c) >= 0, Split(args(0), "@", 2)(0), args(0)).ToString())
		msg = args(1)
		If target Is Nothing OrElse TypeOf target Is WinSECore.Server OrElse Not c.Services.HasClient(target, True) Then
			'Ick. Just ignore this.
			Return
		Else
			'It is one of our service clients. Here we go:
			Dim sc As WinSECore.ServiceClient
			For Each sc In c.Clients
				If sc.Nick = target.Name Then
					'FOUND IT!
					sc.mainproc(Source, msg)
					Exit For
				End If
			Next
		End If
	End Sub
	<WinSECore.Command("TOPIC", False), WinSECore.Command(TOK_TOPIC, True)> Public Sub CmdTopic(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'Two possible formats:
		':sender TOPIC #channel :new topic
		':sender TOPIC #channel sender ts :new topic
		If args.Length < 2 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 2) in TOPIC (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		Dim chptr As WinSECore.Channel
		If c.Channels.Contains(args(0)) Then
			chptr = c.Channels(args(0))
		Else
			Return
		End If
		If args.Length < 4 Then
			chptr.Topic = args(1)
			chptr.TopicWho = Source.Name
			chptr.TopicTS = c.API.GetTS()
		Else
			chptr.Topic = args(3)
			chptr.TopicWho = args(1)
			If IsNumeric(args(2)) Then
				chptr.TopicTS = Integer.Parse(args(2))
			Else
				c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("Invalid TS {0} in TS TOPIC for {1} (Buffer = {2})", args(2), args(0), rawcmd))
				chptr.TopicTS = -1
			End If
		End If
		c.Events.FireChannelTopicChange(Source, chptr, chptr.Topic)
	End Sub
	<WinSECore.Command("NOTICE", False), WinSECore.Command(TOK_NOTICE, True)> Public Sub CmdNotice(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'We probably could ignore this for now, but I'm going to think of a way this will be needed later.
	End Sub
	<WinSECore.Command("SWHOIS", False), WinSECore.Command(TOK_SWHOIS, True)> Public Sub CmdSWhois(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'Format:
		':sender SWHOIS target :info
		If args.Length < 2 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 2) in SWHOIS (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		Dim acptr As WinSECore.IRCNode
		acptr = c.API.FindNode(args(0))
		If acptr Is Nothing OrElse Not TypeOf acptr Is WinSECore.User Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("SWHOIS on server on non-existant user {0}!", args(0)))
			Return
		End If
		With DirectCast(acptr, WinSECore.User)
			.SWhois = args(1)
		End With
	End Sub
	<WinSECore.Command("KICK", False), WinSECore.Command(TOK_KICK, True)> Public Sub CmdKick(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		Dim chptr As WinSECore.Channel, acptr As WinSECore.IRCNode
		Dim idx As Integer
		If args.Length < 2 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 2) in KICK (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		idx = c.Channels.IndexOf(args(0))
		If idx < 0 Then
			c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("Non-existant channel {0} in KICK! (Buffer = {1})", args(0), rawcmd))
			Return
		End If
		chptr = c.Channels(idx)
		acptr = c.API.FindNode(args(1))
		If acptr Is Nothing Then
			c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("Non-existant user {0} in KICK {1}! (Buffer = {2})", args(1), args(0), rawcmd))
			Return
		ElseIf Not TypeOf acptr Is WinSECore.User Then
			c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("Non-user {0} in KICK {1}! (Buffer = {2})", args(1), args(0), rawcmd))
			Return
		ElseIf Not chptr.UserList.Contains(DirectCast(acptr, WinSECore.User)) Then
			c.Events.FireLogMessage("Protocol.Unreal", "WARNING", String.Format("User {0} not on channel in KICK {1}! (Buffer = {2})", args(1), args(0), rawcmd))
			Return
		End If
		chptr.UserList.Remove(chptr.UserList(DirectCast(acptr, WinSECore.User)))
		If chptr.UserList.Count = 0 Then
			c.Channels.Remove(chptr)
		End If
		If args.Length >= 3 Then
			c.Events.FireClientKicked(Source, chptr, DirectCast(acptr, WinSECore.User), args(2))
			c.Events.FireClientPart(DirectCast(acptr, WinSECore.User), chptr, "Kicked by " + Source.Name + " (" + args(2) + ")")
		Else
			c.Events.FireClientKicked(Source, chptr, DirectCast(acptr, WinSECore.User), Nothing)
			c.Events.FireClientPart(DirectCast(acptr, WinSECore.User), chptr, "Kicked by " + Source.Name)
		End If
	End Sub
	<WinSECore.Command("AWAY", False), WinSECore.Command(TOK_AWAY, True)> Public Sub CmdAway(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If Not TypeOf Source Is WinSECore.User Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Non-user sending AWAY! (Buffer = {0})", rawcmd))
			Return
		End If
		With DirectCast(Source, WinSECore.User)
			If args.Length < 1 Then
				.AwayMessage = Nothing
				c.Events.FireClientAway(DirectCast(Source, WinSECore.User), Nothing)
			Else
				.AwayMessage = args(0)
				c.Events.FireClientAway(DirectCast(Source, WinSECore.User), args(0))
			End If
		End With
	End Sub
	<WinSECore.Command("AKILL", False), WinSECore.Command(TOK_AKILL, True)> Public Sub CmdAKill(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'We should never receive this from a server, but we should deal with it just in case.
		c.Events.FireLogMessage("Protocol.Unreal", "WARNING", "Uplink using deprecated command AKILL!")
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in AKILL (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		'For the sake of internal ban tracking, we are going to take a message like this:
		':sender AKILL user@host :reason
		'And treat it as this:
		'TKL + G user host sender 0 TS-NOW :reason
		Dim s(7) As String
		s(0) = "+"
		s(1) = "G"
		s(2) = Split(args(0), "@", 2)(0)
		s(3) = Split(args(0), "@", 2)(1)
		s(4) = Source.Name
		s(5) = "0"
		s(6) = c.API.GetTS().ToString()
		If args.Length = 1 Then
			s(7) = "No reason specified"
		Else
			s(7) = args(1)
		End If
		CmdTkl(c.IRCMap, DirectCast(IIf(EnableTokens, TOK_TKL, "TKL"), String), s, rawcmd)
	End Sub
	<WinSECore.Command("ADMIN", False), WinSECore.Command(TOK_ADMIN, True)> Public Sub CmdAdmin(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		c.API.PutServ("{0} 256 {1} {2} :Administrative Info", GetNSPrefix(c.Services), Source.Name, c.Services.Name)
		'First Line: Name and Info of Services
		c.API.PutServ("{0} 257 {1} {2} :{3}", GetNSPrefix(c.Services), Source.Name, c.Services.Name, c.Services.Info)
		'Second Line: Name of the permanent Services Master.
		c.API.PutServ("{0} 258 {1} {2}", GetNSPrefix(c.Services), Source.Name, c.Conf.MasterNick)
		Dim sSOPs As String, u As WinSECore.User
		c.API.PutServ("{0} 259 {1} :Online Operators", GetNSPrefix(c.Services), Source.Name)
		For Each u In c.IRCMap.GetUsers()
			If Len(sSOPs) >= 430 Then
				'Limit is 510, longest nick is 30, limiting to 430 (510 - 80) gives a little extra breathing room.
				c.API.PutServ("{0} 259 {1} :{2}", GetNSPrefix(c.Services), Source.Name, RTrim(sSOPs))
				sSOPs = ""
			End If
			If u.Flags <> "" Then
				If u.HasFlag(WinSECore.Core.FLAG_Master) Then
					sSOPs += String.Format("{0}{1}{2}{1}{0} ", WinSECore.API.FORMAT_BOLD, WinSECore.API.FORMAT_UNDERLINE, u.Nick)
				ElseIf u.HasFlag(WinSECore.Core.FLAG_CoMaster) Then
					sSOPs += String.Format("{0}{1}{0} ", WinSECore.API.FORMAT_BOLD, u.Nick)
				Else
					sSOPs += u.Nick + " "
				End If
			End If
		Next
		c.API.PutServ("{0} 259 {1} :{2}", GetNSPrefix(c.Services), Source.Name, RTrim(sSOPs))
	End Sub
	<WinSECore.Command("WHOWAS", False), WinSECore.Command(TOK_WHOWAS, True)> Public Sub CmdWhoWas(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in WHOWAS (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		If Not TypeOf Source Is WinSECore.User Then
			'This is probably perfectly valid but we're just going to ignore it.
			Return
		End If
		'Why we are even getting queried with this is beyond me but we'll have to deal with it somehow.
		'We could integrate this into NickServ's "last online time" stuff but... for now:
		SendNumeric(c.Services, DirectCast(Source, WinSECore.User), 406, "{0} :There was no such nickname", args(0))
		SendNumeric(c.Services, DirectCast(Source, WinSECore.User), 369, "{0} :End of WHOWAS", args(0))
	End Sub
	<WinSECore.Command("WHOIS", False), WinSECore.Command(TOK_WHOIS, True)> Public Sub CmdWhoIs(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in WHOIS (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		'Probably a "far whois" (/whois NickServ NickServ, for example).
		Dim acptr As WinSECore.IRCNode
		Dim sptr As WinSECore.User
		If Not TypeOf Source Is WinSECore.User Then
			Return
		End If
		sptr = DirectCast(Source, WinSECore.User)
		If args.Length >= 2 Then
			acptr = c.API.FindNode(args(1))
		Else
			acptr = c.API.FindNode(args(0))
		End If
		If acptr Is Nothing Then
			SendNumeric(c.Services, sptr, 401, "{0} :No such nick/channel", args(CInt(IIf(args.Length >= 2, 1, 0))))
		ElseIf TypeOf acptr Is WinSECore.User Then
			With DirectCast(acptr, WinSECore.User)
				'WHOIS DUMP TIME.
				'First line: 311 NickServ nickserv services.winse.net * :Nickname Services
				'* NickServ is nickserv@services.winse.net * Nickname Services
				SendNumeric(c.Services, sptr, 311, "{0} {1} {2} * :{3}", .Name, .Username, IIf(.VHost <> "", .VHost, .Hostname), .RealName)
				'If this user is registered we should send the registered nick numeric.
				If .Usermodes.IndexOf("r"c) >= 0 Then
					SendNumeric(c.Services, sptr, 307, "{0} :is a registered nick", .Name)
				End If
				'We should probably send channel information. But I cba atm.
				'Next line: 312 NickServ services.winse.net :WinSE IRC Services
				'* NickServ connected to services.winse.net - WinSE IRC Services
				SendNumeric(c.Services, sptr, 312, "{0} {1} :{2}", .Name, .Server.Name, .Server.Info)
				'Now for fun IRCop line...
				'313 NickServ :is a Network Service
				'* NickServ is a Network Service
				If .Username.IndexOf("H"c) < 0 Then
					If .Usermodes.IndexOf("N"c) >= 0 Then
						SendNumeric(c.Services, sptr, 313, "{0} :is a Network Administrator", .Name)
					ElseIf .Usermodes.IndexOf("a"c) >= 0 Then
						SendNumeric(c.Services, sptr, 313, "{0} :is a Services Administrator", .Name)
					ElseIf .Usermodes.IndexOf("A"c) >= 0 Then
						SendNumeric(c.Services, sptr, 313, "{0} :is a Server Administrator", .Name)
					ElseIf .Usermodes.IndexOf("C"c) >= 0 Then
						SendNumeric(c.Services, sptr, 313, "{0} :is a Co-Administrator", .Name)
					ElseIf .Usermodes.IndexOf("S"c) >= 0 Then
						SendNumeric(c.Services, sptr, 313, "{0} :is a Network Service", .Name)
					ElseIf .Usermodes.IndexOf("o"c) >= 0 Then
						SendNumeric(c.Services, sptr, 313, "{0} :is an IRC Operator", .Name)
					End If
					If .Usermodes.IndexOf("h"c) >= 0 AndAlso .AwayMessage <> "" Then
						SendNumeric(c.Services, sptr, 310, "{0} :is available for help", .Name)
					End If
				End If
				If .Usermodes.IndexOf("z"c) >= 0 Then
					SendNumeric(c.Services, sptr, 671, "{0} :is using a Secure Connection", .Name)
				End If
				If .Username.IndexOf("H"c) < 0 AndAlso .SWhois <> "" Then
					SendNumeric(c.Services, sptr, 320, "{0} :{1}", .Name, .SWhois)
				End If
				If c.API.IsService(acptr) Then
					'We can return signon and idletime. In most cases, the service's TS will suffice.
					SendNumeric(c.Services, sptr, 317, "{0} 0 {1} :seconds idle, signon time", .Name, .TS)
				End If
			End With
		End If
		SendNumeric(c.Services, sptr, 318, "{0} :End of /WHOIS list", acptr.Name)
	End Sub
	<WinSECore.Command("UMODE2", False), WinSECore.Command(TOK_UMODE2, True)> Public Sub CmdUMode2(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in UMODE2 (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		If Not TypeOf Source Is WinSECore.User Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Usermode change on non-user {0}", Source.Name))
		End If
		Dim s(1) As String
		s(0) = Source.Name
		s(1) = args(0)
		CmdMode(Source, DirectCast(IIf(EnableTokens, TOK_UMODE2, "UMODE2"), String), s, rawcmd)
	End Sub
	<WinSECore.Command("TSCTL", False), WinSECore.Command(TOK_TSCTL, True)> Public Sub CmdTSCTL(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'The only thing we care about is TSCTL ALLTIME.
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in TSCTL (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		If UCase(args(0)) = "ALLTIME" Then
			'Send the output like Unreal would:
			c.API.PutServ("{0} {1} {2} :*** Server={3} TStime={4} time()={4} TSoffset=0", GetNSPrefix(c.Services), IIf(EnableTokens, TOK_NOTICE, "NOTICE"), Source.Name, c.Services.Name, c.API.GetTS())
		End If
	End Sub
	<WinSECore.Command("TRACE", False), WinSECore.Command(TOK_TRACE, True)> Public Sub CmdTrace(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'TRACE is so fun.
		c.API.PutServ("{0} 209 {1} Class Service {2}", GetNSPrefix(c.Services), Source.Name, c.Clients.Count)
		c.API.PutServ("{0} 209 {1} Class UplinkServer 1", GetNSPrefix(c.Services), Source.Name)
		c.API.PutServ("{0} 206 {1} Server UplinkServer {2}S {3}C {4}[{5}] AutoConn.!*@{6}", GetNSPrefix(c.Services), Source.Name, c.IRCMap.GetServers().Count, c.IRCMap.GetUsers.Count, c.IRCMap.Name, DirectCast(c.sck.RemoteEndPoint, System.Net.IPEndPoint).Address.ToString(), c.Services.Name)
		For Each acptr As WinSECore.IRCNode In c.Services.SubNodes
			If TypeOf acptr Is WinSECore.Server Then
				c.API.PutServ("{0} 206 {1} Server Jupe 1S 0C {2}[127.0.0.1] *!*@{3}", GetNSPrefix(c.Services), Source.Name, acptr.Name, c.Services.Name)
			ElseIf TypeOf acptr Is WinSECore.User Then
				If DirectCast(acptr, WinSECore.User).Usermodes.IndexOf("i") < 0 OrElse TypeOf Source Is WinSECore.Server OrElse IsIRCop(DirectCast(Source, WinSECore.User)) Then
					If IsIRCop(DirectCast(acptr, WinSECore.User)) Then
						c.API.PutServ("{0} 204 {1} Operator Service {2} [127.0.0.1] :0")
					Else
						c.API.PutServ("{0} 204 {1} User Service {2} [127.0.0.1] :0")
					End If
				End If
			End If
		Next
	End Sub
	<WinSECore.Command("GLINE", False), WinSECore.Command(TOK_GLINE, True)> Public Sub CmdGLine(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in GLINE (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		Dim s() As String
		If Left(args(0), 1) = "-" Then
			':sender GLINE -user@host
			'To...
			'TKL - G user host sender
			s = New String(4) {}
			s(0) = "-"
			s(1) = "G"
			s(2) = Mid(Split(args(0), "@", 2)(0), 2)
			s(3) = Split(args(0), "@", 2)(1)
			s(4) = Source.Name
		Else
			'For the sake of internal ban tracking, we are going to take a message like this:
			':sender GLINE user@host [<expiry> [:reason]]
			'And treat it as this:
			'TKL + G user host sender 0 TS-NOW :reason
			s = New String(7) {}
			s(0) = "+"
			s(1) = "G"
			s(2) = Split(args(0), "@", 2)(0)
			s(3) = Split(args(0), "@", 2)(1)
			s(4) = Source.Name
			s(6) = c.API.GetTS().ToString()
			If args.Length = 1 Then
				s(5) = "0"
				s(7) = "No reason specified"
			ElseIf args.Length = 2 Then
				s(5) = "0"
				s(7) = args(1)
			ElseIf args.Length > 2 Then
				Try
					s(5) = CStr(CInt(s(6)) + c.API.Duration(args(1)))
					If s(5) = s(6) Then s(5) = "0"
					s(7) = args(2)
				Catch ex As Exception
					s(5) = "0"
					s(7) = args(1)
				End Try
			End If
		End If
		CmdTkl(c.IRCMap, DirectCast(IIf(EnableTokens, TOK_TKL, "TKL"), String), s, rawcmd)
	End Sub
	<WinSECore.Command("SHUN", False), WinSECore.Command(TOK_SHUN, True)> Public Sub CmdShun(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in SHUN (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		Dim s() As String
		If Left(args(0), 1) = "-" Then
			':sender SHUN -user@host
			'To...
			'TKL - S user host sender
			s = New String(4) {}
			s(0) = "-"
			s(1) = "S"
			s(2) = Mid(Split(args(0), "@", 2)(0), 2)
			s(3) = Split(args(0), "@", 2)(1)
			s(4) = Source.Name
		Else
			'For the sake of internal ban tracking, we are going to take a message like this:
			':sender SHUN user@host [<expiry> [:reason]]
			'And treat it as this:
			'TKL + S user host sender 0 TS-NOW :reason
			s = New String(7) {}
			s(0) = "+"
			s(1) = "S"
			s(2) = Split(args(0), "@", 2)(0)
			s(3) = Split(args(0), "@", 2)(1)
			s(4) = Source.Name
			s(6) = c.API.GetTS().ToString()
			If args.Length = 1 Then
				s(5) = "0"
				s(7) = "No reason specified"
			ElseIf args.Length = 2 Then
				s(5) = "0"
				s(7) = args(1)
			ElseIf args.Length > 2 Then
				Try
					s(5) = CStr(CInt(s(6)) + c.API.Duration(args(1)))
					If s(5) = s(6) Then s(5) = "0"
					s(7) = args(2)
				Catch ex As Exception
					s(5) = "0"
					s(7) = args(1)
				End Try
			End If
		End If
		CmdTkl(c.IRCMap, DirectCast(IIf(EnableTokens, TOK_TKL, "TKL"), String), s, rawcmd)
	End Sub
	<WinSECore.Command("TIME", False), WinSECore.Command(TOK_TIME, True)> Public Sub CmdTime(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		c.API.PutServ("{0} 391 {1} :{2}", GetNSPrefix(c.Services), Source.Name, Format(Now, "dddd, mmmm d, yyyy HH:mm:ss zzz"))
	End Sub
	<WinSECore.Command("SVSNLINE", False), WinSECore.Command(TOK_SVSNLINE, True)> Public Sub CmdSVSNLine(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in SVSNLINE (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		Dim nline As WinSECore.IRCBan
		Select Case args(0)
			Case "+"
				If args.Length < 3 Then
					c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 3) in SVSNLINE (Buffer = {1})", args.Length, rawcmd))
					Return
				End If
				nline = New WinSECore.IRCBan
				nline.Mask = args(2)
				nline.Reason = Replace(args(1), "_", " ")
				nline.ExpireTS = 0
				c.RealnameBans.Add(nline)
			Case "-"
				If args.Length < 2 Then
					c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 2) in SVSNLINE (Buffer = {1})", args.Length, rawcmd))
					Return
				End If
				If c.RealnameBans.Contains(args(1)) Then
					c.RealnameBans.RemoveAt(c.RealnameBans.IndexOf(args(1)))
				End If
			Case "*"
				c.RealnameBans.Clear()
			Case Else
				c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Illegal SVSNLINE action {0} (expected +, -, or*)", args(0)))
		End Select
	End Sub
	<WinSECore.Command("STATS", False), WinSECore.Command(TOK_STATS, True)> Public Sub CmdStats(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in STATS (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		If Not TypeOf Source Is WinSECore.User Then Return
		Select Case LCase(args(0))
			Case "banversion"
				args(0) = "B"
			Case "badword"
				args(0) = "b"
			Case "link"
				args(0) = "C"
			Case "denylinkauto"
				args(0) = "d"
			Case "denylinkall"
				args(0) = "D"
			Case "exceptthrottle"
				args(0) = "e"
			Case "spamfilter"
				args(0) = "f"
			Case "denydcc"
				args(0) = "F"
			Case "gline"
				args(0) = "G"
			Case "allow"
				args(0) = "I"
			Case "officialchans"
				args(0) = "j"
			Case "kline"
				args(0) = "K"
			Case "linkinfo"
				args(0) = "l"
			Case "linkinfoall"
				args(0) = "L"
			Case "command"
				args(0) = "M"
			Case "banrealname"
				args(0) = "n"
			Case "oper"
				args(0) = "O"
			Case "port"
				args(0) = "P"
			Case "bannick"
				args(0) = "q"
			Case "sqline"
				args(0) = "Q"
			Case "chanrestrict"
				args(0) = "r"
			Case "set"
				args(0) = "S"
			Case "shun"
				args(0) = "s"
			Case "tld"
				args(0) = "t"
			Case "traffic"
				args(0) = "T"
			Case "uptime"
				args(0) = "u"
			Case "uline"
				args(0) = "U"
			Case "denyver"
				args(0) = "v"
			Case "vhost"
				args(0) = "V"
			Case "notlink"
				args(0) = "X"
			Case "class"
				args(0) = "Y"
			Case "zip"
				args(0) = "z"
			Case "mem"
				args(0) = "Z"
		End Select
		Select Case args(0)
			Case "o", "O"
				SendMessage(c.Services, DirectCast(Source, WinSECore.User), "Sorry, but /stats O is not implemented yet.", True)
			Case Else
		End Select
		SendNumeric(c.Services, Source, 219, "{0} :End of /STATS report", args(0))
	End Sub
	<WinSECore.Command("SQLINE", False), WinSECore.Command(TOK_SQLINE, True)> Public Sub CmdSQLine(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'We should never receive this from a server, but we should deal with it just in case.
		c.Events.FireLogMessage("Protocol.Unreal", "WARNING", "Uplink using deprecated command SQLINE!")
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in SQLINE (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		'For the sake of internal ban tracking, we are going to take a message like this:
		':sender SQLINE nick :reason
		'And treat it as this:
		'TKL + Q * nick sender 0 TS-NOW :reason
		Dim s(7) As String
		s(0) = "+"
		s(1) = "Q"
		s(2) = "*"
		s(3) = args(0)
		s(4) = Source.Name
		s(5) = "0"
		s(6) = c.API.GetTS().ToString()
		If args.Length = 1 Then
			s(7) = "No reason specified"
		Else
			s(7) = args(1)
		End If
		CmdTkl(c.IRCMap, DirectCast(IIf(EnableTokens, TOK_TKL, "TKL"), String), s, rawcmd)
	End Sub
	<WinSECore.Command("SETNAME", False), WinSECore.Command(TOK_SETNAME, True)> Public Sub CmdSetName(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in SETNAME (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		If Not TypeOf Source Is WinSECore.User Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Non-user {0} changing realname to {1}! (Buffer = {2})", Source.Name, args(0), rawcmd))
			Return
		End If
		DirectCast(Source, WinSECore.User).RealName = args(0)
	End Sub
	<WinSECore.Command("SETIDENT", False), WinSECore.Command(TOK_SETIDENT, True)> Public Sub CmdSetIdent(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in SETIDENT (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		If Not TypeOf Source Is WinSECore.User Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Non-user {0} changing vIdent to {1}! (Buffer = {2})", Source.Name, args(0), rawcmd))
			Return
		End If
		DirectCast(Source, WinSECore.User).Username = args(0)
		DirectCast(Source, WinSECore.User).VIdent = args(0)
	End Sub
	<WinSECore.Command("SETHOST", False), WinSECore.Command(TOK_SETHOST, True)> Public Sub CmdSetHost(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in SETHOST (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		If Not TypeOf Source Is WinSECore.User Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Non-user {0} changing vHost to {1}! (Buffer = {2})", Source.Name, args(0), rawcmd))
			Return
		End If
		DirectCast(Source, WinSECore.User).VHost = args(0)
	End Sub
	<WinSECore.Command("SDESC", False), WinSECore.Command(TOK_SDESC, True)> Public Sub CmdSDesc(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in SDESC (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		Dim srv As WinSECore.Server
		If TypeOf Source Is WinSECore.Server Then
			srv = DirectCast(Source, WinSECore.Server)
		Else
			srv = DirectCast(Source, WinSECore.User).Server
		End If
		srv.Info = args(0)
	End Sub
	<WinSECore.Command("SAPART", False), WinSECore.Command(TOK_SAPART, True)> Public Sub CmdSAPart(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'We will only get this if a service is SAPARTed. Good thing we don't have to honor it.
		'Tell the SAdmin who used it to get stuffed.
		If Not TypeOf Source Is WinSECore.User Then Return
		SendMessage(c.Services, DirectCast(Source, WinSECore.User), "Sorry, SAPART may not be used on services.", True)
	End Sub
	<WinSECore.Command("SAMODE", False), WinSECore.Command(TOK_SAMODE, True)> Public Sub CmdSAMode(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'We should NEVER receive this...
	End Sub
	<WinSECore.Command("SAJOIN", False), WinSECore.Command(TOK_SAJOIN, True)> Public Sub CmdSAJoin(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'We will only get this if a service is SAJOINed. Good thing we don't have to honor it.
		'Tell the SAdmin who used it to get stuffed.
		If Not TypeOf Source Is WinSECore.User Then Return
		SendMessage(c.Services, DirectCast(Source, WinSECore.User), "Sorry, SAJOIN may not be used on services.", True)
	End Sub
	<WinSECore.Command("RULES", False), WinSECore.Command(TOK_RULES, True)> Public Sub CmdRules(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		SendNumeric(c.Services, Source, 422, ":RULES File is missing")
	End Sub
	<WinSECore.Command("RPING", False), WinSECore.Command(TOK_RPING, True)> Public Sub CmdRPing(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'Coming from a server, this looks like this:
		':sender RPING pinged-server original-sender start-time start-time-ms :remark
		If args.Length < 5 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 5) in RPING (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		'We send this the same way unreal does. Yes, we break TOKEN and NS here. Blame unreal.
		c.API.PutServ(":{0} RPONG {1} {2} {3} {4} :{5}", c.Services.Name, Source.Name, args(1), args(2), args(3), args(4))
	End Sub
	<WinSECore.Command("RPONG", False), WinSECore.Command(TOK_RPONG, True)> Public Sub CmdRPong(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		c.Events.FireLogMessage("Protocol.Unreal", "TRACE", "RPONG: " & Join(args, " "))
	End Sub
	<WinSECore.Command("RAKILL", False), WinSECore.Command(TOK_RAKILL, True)> Public Sub CmdRAKill(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		Dim s(4) As String
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 1) in RAKILL (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		s(0) = "-"
		s(1) = "G"
		s(2) = Split(args(0), "@", 2)(0)
		s(3) = Split(args(0), "@", 2)(1)
		s(4) = Source.Name
		CmdTkl(c.IRCMap, DirectCast(IIf(EnableTokens, TOK_TKL, "TKL"), String), s, rawcmd)
	End Sub
	<WinSECore.Command("PROTOCTL", False), WinSECore.Command("_", True)> Public Sub CmdProtoCtl(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		ProtoCtl.AddRange(args)
	End Sub
	<WinSECore.Command("PING", False), WinSECore.Command(TOK_PING, True)> Public Sub CmdPing(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If InStr(args(args.Length - 1), " ") > 0 Then
			'Sneaky, but it works.
			args(args.Length - 1) = ":" + args(args.Length - 1)
		End If
		c.API.PutServ("{0} {1} {2}", GetNSPrefix(Source), IIf(EnableTokens, TOK_PONG, "PONG"), Join(args, " "))
	End Sub
	<WinSECore.Command("PONG", False), WinSECore.Command(TOK_PONG, True)> Public Sub CmdPong(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		c.Events.FireLogMessage("Protocol.Unreal", "TRACE", "PONG " + Join(args, " "))
	End Sub
	<WinSECore.Command("PASS", False), WinSECore.Command(TOK_PASS, True)> Public Sub CmdPass(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'If we require a password, check it...
		If args.Length < 1 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", "No password from uplink! Link denied.")
			c.API.ExitServer("Link denied (No password)")
			Return
		ElseIf c.Conf.RecvPass.PassPhrase = "" Then
			c.Events.FireLogMessage("Protocol.Unreal", "NOTICE", "Got a password (and not caring poo about it)...")
		ElseIf Not c.Conf.RecvPass.Equals(args(0)) Then
			c.Events.FireLogMessage("Protocol.Unreal", "NOTICE", "Incorrect password from uplink! Link denied.")
			c.API.ExitServer("Link denied (Authentication failure)")
			Return
		End If
	End Sub
	<WinSECore.Command("NETINFO", False), WinSECore.Command(TOK_NETINFO, True)> Public Sub CmdNetInfo(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		':server NETINFO globalpeak syncTS protocol cloakcrc 0 0 0 :network name
		If args.Length < 8 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 8) in NETINFO (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		If CInt(args(2)) <> ProtocolVersion Then
			'UGH.
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Warning - uplink is version {0} but services configured for version {1}!", args(2), ProtocolVersion))
		End If
	End Sub
	<WinSECore.Command("LAG", False), WinSECore.Command(TOK_LAG, True)> Public Sub CmdLag(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If Not TypeOf Source Is WinSECore.User Then Return
		SendMessage(c.Services, DirectCast(Source, WinSECore.User), String.Format("Lag reply -- {0} {1} {2}", c.Services.Name, args(0), c.API.GetTS()), True)
	End Sub
	<WinSECore.Command("INVITE", False), WinSECore.Command(TOK_INVITE, True)> Public Sub CmdInvite(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'INVITE is typically sent similar to PRIVMSG. We shouldn't need to handle this. However, I have reason to believe it may be of use
		'later; for example, AntiSpamServ.
	End Sub
	<WinSECore.Command("HELPOP", False), WinSECore.Command(TOK_HELPOP, True)> Public Sub CmdHelpOp(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'For now, I'm going to ignore this, but it may be of use later.
	End Sub
	<WinSECore.Command("EOS", False), WinSECore.Command(TOK_EOS, True)> Public Sub CmdEOS(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'END OF SYNCH.
		c.Events.FireLogMessage("Protocol.Unreal", "NOTICE", String.Format("Services have completely processed netburst from uplink."))
		Me.Synched = True
	End Sub
	<WinSECore.Command("CHGNAME", False), WinSECore.Command(TOK_CHGNAME, True)> Public Sub CmdChgName(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If args.Length < 2 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 2) in CHGNAME (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		Dim acptr As WinSECore.IRCNode = c.API.FindNode(args(0))
		If Not TypeOf acptr Is WinSECore.User Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Non-user {0} changing realname to {1}! (Buffer = {2})", Source.Name, args(1), rawcmd))
			Return
		End If
		DirectCast(acptr, WinSECore.User).RealName = args(1)
	End Sub
	<WinSECore.Command("CHGIDENT", False), WinSECore.Command(TOK_CHGIDENT, True)> Public Sub CmdChgIdent(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If args.Length < 2 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 2) in CHGIDENT (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		Dim acptr As WinSECore.IRCNode = c.API.FindNode(args(0))
		If Not TypeOf acptr Is WinSECore.User Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Non-user {0} changing vident to {1}! (Buffer = {2})", Source.Name, args(1), rawcmd))
			Return
		End If
		DirectCast(acptr, WinSECore.User).VIdent = args(1)
		DirectCast(acptr, WinSECore.User).Username = args(1)
	End Sub
	<WinSECore.Command("CHGHOST", False), WinSECore.Command(TOK_CHGHOST, True)> Public Sub CmdChgHost(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If args.Length < 2 Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Insufficient parameters ({0} < 2) in CHGHOST (Buffer = {1})", args.Length, rawcmd))
			Return
		End If
		Dim acptr As WinSECore.IRCNode = c.API.FindNode(args(0))
		If Not TypeOf acptr Is WinSECore.User Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("Non-user {0} changing vhost to {1}! (Buffer = {2})", Source.Name, args(1), rawcmd))
			Return
		End If
		DirectCast(acptr, WinSECore.User).VHost = args(1)
	End Sub
	<WinSECore.Command("VERSION", False), WinSECore.Command(TOK_VERSION, True)> Public Sub CmdVersion(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'Fetch the WinSE version and OS...
		Dim flags As String = "", osver As System.OperatingSystem = Environment.OSVersion
		'Build flags like Unreal does.
		'c = Server is chrooted. We can't chroot.
		'C = Command line config enabled. Not a chance in heck.
		'D = Debug mode. If we are in debug, I guess so :P .
#If DEBUG Then
		flags += "D"
#End If
		'F = Using FD lists. Whaa....?
		'h = Compiled as a hub. Not really, but we better in case something actually CHECKS this.
		flags += "h"
		'i = Shows invisible users in /trace. Why not?
		flags += "i"
		'n = NOSPOOF enabled. Uh, we don't even RECEIVE connections.
		'V = Uses valloc(). Erm, in .NET? Nope.
		'W = Windows. HECK YES.
#If Win32 Then
		flags += "W"
#End If
		'Y = Syslog logging enabled. Since the bootstrap EXE handles logging, we won't know, so say no.
		'K = No ident checking. Sounds about right.
		flags += "K"
		'6 = IPv6 supported. Nope.
		'X = STRIPBADWORDS Enabled. That's the IRCd's job, but we better say yes in case it screws up the network.
		flags += "X"
		'P = Uses poll(). Nope. .NET all the way
		'e = SSL Supported. HECK NO.
		'O = OperOverride enabled. Trying to define this in the core is stepping on the service module's shoes. So no.
		'o = Join +p/+s without /invite. A stupid feature, and we don't even care. Just send it anyway.
		flags += "o"
		'Ziplinks supported. Nope.
		flags += "Z"
		'3 = 3rd party modules loaded. I don't know really. Maybe I'll add a way to define this later.
		'E = Extended channel modes. Absolutely. We have to :P .
		flags += "E"
		c.API.PutServ("{0} 351 {1} WinSE.{2} {3} :{4} [{5}]", GetNSPrefix(c.Services), Source.Name, System.Reflection.Assembly.GetExecutingAssembly().GetName().Version.ToString(), c.Services.Name, flags, osver.ToString())
	End Sub
	<WinSECore.Command("INFO", False), WinSECore.Command(TOK_INFO, True)> Public Sub CmdInfo(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If Not TypeOf Source Is WinSECore.User Then Return
		SendMessage(c.Services, DirectCast(Source, WinSECore.User), "Try using just /INFO.", True)
	End Sub
	<WinSECore.Command("ERROR", False), WinSECore.Command(TOK_ERROR, True)> Public Sub CmdError(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'AAAAAAAAAAAAAAAAAAAAAARRRRRRRRRRRRRRRRRGGGGGGGGGGGHHHHHHHHHHHHHHHHHHHHHHH
		If Not c.IRCMap Is Nothing Then
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", String.Format("SERVER ERROR: {0}", args(0)))
			c.Events.FireLogMessage("Protocol.Unreal", "ERROR", "Error from server - squitting.")
			c.Events.FireServerTerm()
			c.Events.FireServerQuit(c.IRCMap, "Error from uplink")
			c.IRCMap.Dispose()
			c.IRCMap = Nothing
			c.API.ExitServer("Error from uplink", c.IRCMap.Name)
		End If
	End Sub
	<WinSECore.Command("MOTD", False), WinSECore.Command(TOK_MOTD, True)> Public Sub CmdMOTD(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		Dim s() As String
		s = c.API.GetMOTD()
		If s Is Nothing Then
			SendNumeric(c.Services, Source, 422, ":MOTD File is missing")
		Else
			SendNumeric(c.Services, Source, 375, ":- {0} Message of the Day - ", c.Services.Name)
			For Each sLine As String In s
				SendNumeric(c.Services, Source, 372, ":- {0}", sLine)
			Next
			SendNumeric(c.Services, Source, 376, ":End of /MOTD command")
		End If
	End Sub
	<WinSECore.Command("REHASH", False), WinSECore.Command(TOK_REHASH, True)> Public Sub CmdRehash(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		c.Events.FireLogMessage("Protocol.Unreal", "NOTICE", Source.Name + " requested a REHASH.")
		SendToUMode(c.Services, "o"c, String.Format("*** Notice -- from {0}: {1} is remotely rehashing config file.", c.Services.Name, Source.Name))
		SendNumeric(c.Services, Source, 382, "{0} :Rehashing", c.ConfFile)
		c.Rehash()
	End Sub
	<WinSECore.Command("RESTART", False), WinSECore.Command(TOK_RESTART, True)> Public Sub CmdRestart(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'We shouldn't get this. Unreal doesn't support remote rehashing.
		c.Events.FireLogMessage("Protocol.Unreal", "WARNING", "Remote /RESTART attempt by " + Source.Name)
		If Not TypeOf Source Is WinSECore.User Then Return
		SendMessage(c.Services, DirectCast(Source, WinSECore.User), "Remote /RESTART not supported.", True)
	End Sub
	<WinSECore.Command("DIE", False), WinSECore.Command(TOK_DIE, True)> Public Sub CmdDie(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		'Remote /DIE definately not supported.
		c.Events.FireLogMessage("Protocol.Unreal", "WARNING", "Remote /DIE attempt by " + Source.Name)
		If Not TypeOf Source Is WinSECore.User Then Return
		SendMessage(c.Services, DirectCast(Source, WinSECore.User), "Remote /DIE not supported.", True)
	End Sub
	<WinSECore.Command("DALINFO", False), WinSECore.Command(TOK_DALINFO, True)> Public Sub CmdDALInfo(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If Not TypeOf Source Is WinSECore.User Then Return
		SendMessage(c.Services, DirectCast(Source, WinSECore.User), "Try using just /DALINFO.", True)
	End Sub
	<WinSECore.Command("CREDITS", False), WinSECore.Command("AJ", True)> Public Sub CmdCredits(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)

	End Sub
	<WinSECore.Command("LICENSE", False), WinSECore.Command("AK", True)> Public Sub CmdLicense(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)

	End Sub
	<WinSECore.Command("OPERMOTD", False), WinSECore.Command(TOK_OPERMOTD, True)> Public Sub CmdOperMOTD(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		SendNumeric(c.Services, Source, 422, ":OPERMOTD File is missing")
	End Sub
	<WinSECore.Command("BOTMOTD", False), WinSECore.Command(TOK_BOTMOTD, True)> Public Sub CmdBotMOTD(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		SendNumeric(c.Services, Source, 422, ":BOTMOTD File is missing")
	End Sub
	<WinSECore.Command("MODULE", False), WinSECore.Command(TOK_MODULE, True)> Public Sub CmdModule(ByVal Source As WinSECore.IRCNode, ByVal cmd As String, ByVal args() As String, ByVal rawcmd As String)
		If Not TypeOf Source Is WinSECore.User Then Return
		For Each m As WinSECore.Module In c.Modules
			'The general appearance will be:
			'moduleclassname - assembly.dll (assembly info)
			Dim sInfo As String, o As Object(), ad As System.Reflection.AssemblyDescriptionAttribute
			o = m.GetType().Assembly.GetCustomAttributes(GetType(System.Reflection.AssemblyDescriptionAttribute), False)
			If o.Length >= 1 Then
				ad = DirectCast(o(0), System.Reflection.AssemblyDescriptionAttribute)
				sInfo = ad.Description
			Else
				sInfo = ""
			End If
			SendMessage(c.Services, DirectCast(Source, WinSECore.User), String.Format("*** {0} - {1} ({2})", m.GetType().ToString(), m.GetType().Assembly.Location, sInfo), True)
		Next
	End Sub
#End Region

End Class
