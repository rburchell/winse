VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Unreal32"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'UnrealIRCd 3.2*

#Const UnrealVer = 2303 '2303 = Unreal 3.2, 2304 = Unreal 3.2.1, 2305 = Unreal 3.2.2
Const UnrealVer = 2303
Dim EnableToken As Boolean

Implements IIRCd

'TOKENS:
Private Const TOK_TKL = "BD"    ' == TKL
Private Const TOK_NICK = "&"    ' == NICK
Private Const TOK_SVSKILL = "h" ' == SVSKILL
Private Const TOK_KILL = "."    ' == KILL
Private Const TOK_SVSNICK = "e" ' == SVSNICK
Private Const TOK_SJOIN = "~"   ' == SJOIN
Private Const TOK_JOIN = "C"    ' == JOIN
Private Const TOK_MODE = "G"    ' == MODE
Private Const TOK_PART = "D"    ' == PART
Private Const TOK_QUIT = ","    ' == QUIT
Private Const TOK_SQUIT = "-"   ' == SQUIT
Private Const TOK_SERVER = "'"  ' == SERVER (NOT DURING CONNECT)
Private Const TOK_PRIVMSG = "!" ' == PRIVMSG
Private Const TOK_TOPIC = ")"   ' == TOPIC
Private Const TOK_NOTICE = "B"  ' == NOTICE
Private Const TOK_GLOBOPS = "]" ' == GLOBOPS
Private Const TOK_SVSMODE = "n" ' == SVSMODE
Private Const TOK_SVS2MODE = "v" '== SVS2MODE
Private Const TOK_SWHOIS = "BA" ' == SWHOIS
Private Const TOK_KICK = "H"    ' == KICK

'Used for NS.
Private Function GetNSSourcePrefix(ByVal Source As String) As String
    If Servers.Exists(Source) Then
        GetNSSourcePrefix = "@" + IntToB64(CByte(Servers(Source).SID))
    Else
        GetNSSourcePrefix = ":" + Source
    End If
End Function

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

Private Sub IIRCd_AddPermNetworkIPBan(ByVal Source As String, ByVal Mask As String, ByVal reason As String)
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    'Add the thing.
    SendData FormatString("{0} + Z * {1} {2} 0 {3} :{4}", IIf(EnableToken, TOK_TKL, "TKL"), Mask, Source, ts, reason)
End Sub

Private Sub IIRCd_AddPermNetworkNickBan(ByVal Source As String, ByVal Mask As String, ByVal reason As String)
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    'Add the thing.
    SendData FormatString("{0} + Q * {1} {2} 0 {3} :{4}", IIf(EnableToken, TOK_TKL, "TKL"), Mask, Source, ts, reason)
End Sub

Private Sub IIRCd_AddPermNetworkRealnameBan(ByVal Source As String, ByVal Mask As String, ByVal reason As String)
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    'Add the thing.
    SendData FormatString("SVSNLINE + {0} :{1}", Replace(reason, " ", "_"), Mask)
End Sub

Private Sub IIRCd_AddPermNetworkUserhostBan(ByVal Source As String, ByVal Mask As String, ByVal reason As String)
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    'Add the thing.
    SendData FormatString("{0} + G {1} {2} {3} 0 {4} :{5}", IIf(EnableToken, TOK_TKL, "TKL"), Split(Mask, "@", 2)(0), Split(Mask, "@", 2)(1), Source, ts, reason)
End Sub

Private Sub IIRCd_AddTempNetworkIPBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal reason As String)
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    'Add the thing.
    SendData FormatString("{0} + Z * {1} {2} {3} {4} :{5}", IIf(EnableToken, TOK_TKL, "TKL"), Mask, Source, ts + Expiry, ts, reason)
End Sub

Private Sub IIRCd_AddTempNetworkNickBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal reason As String)
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    'Add the thing.
    SendData FormatString("{0} + Q * {1} {2} {3} {4} :{5}", IIf(EnableToken, TOK_TKL, "TKL"), Mask, Source, ts + Expiry, ts, reason)
End Sub

Private Sub IIRCd_AddTempNetworkRealnameBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal reason As String)
    Err.Raise E_NOTIMPL
End Sub

Private Sub IIRCd_AddTempNetworkUserhostBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal reason As String)
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    'Add the thing.
    SendData FormatString("{0} + G {1} {2} {3} {4} {5} :{6}", IIf(EnableToken, TOK_TKL, "TKL"), Split(Mask, "@", 2)(0), Split(Mask, "@", 2)(1), Source, ts + Expiry, ts, reason)
End Sub

Private Property Get IIRCd_BanChar() As String
    IIRCd_BanChar = "b"
End Property

Private Sub IIRCd_BurstChannel(ByVal Source As String, ByVal channel As String, ByVal ts As Long, ByVal modes As String, ByVal ModeParams As String, Users() As String, WantModes() As String, ByRef Bans() As String, ByRef Exempts() As String, ByRef Invites() As String)
    'I JUST LOVE SJOIN >_<
    'SJOIN Format:
    ':server.name SJOIN ts channel modes [modeparam] :[[[*][~][@][%][+]member]] [[[&ban]["exempt]]]
    'If for some dumb reason we have a lot of members/bans/exempts to sjoin and/or a really long key/whatever
    'we may need to break up the SJOIN.
    Dim sjoinstr As String
    sjoinstr = FormatString("{0} {1} !{2} {3} {4} {5} :", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SJOIN, "SJOIN"), IntToB64(ts), channel, modes, ModeParams)
    Dim uidx As Long, bidx As Long, eidx As Long, iidx As Long, stmp As String
    uidx = 0: bidx = 0: eidx = 0: iidx = 0
    Do Until uidx > UBound(Users) And bidx > UBound(Bans) And eidx > UBound(Exempts)
        stmp = ""
        If uidx <= UBound(Users) Then
            If InStr(WantModes(uidx), "q") Then stmp = stmp + "*"
            If InStr(WantModes(uidx), "a") Then stmp = stmp + "~"
            If InStr(WantModes(uidx), "o") Then stmp = stmp + "@"
            If InStr(WantModes(uidx), "h") Then stmp = stmp + "%"
            If InStr(WantModes(uidx), "v") Then stmp = stmp + "+"
            stmp = stmp + Users(uidx)
            uidx = uidx + 1
        ElseIf bidx <= UBound(Bans) Then
            stmp = "&" + Bans(bidx)
            bidx = bidx + 1
        ElseIf eidx <= UBound(Exempts) Then
            stmp = """" + Exempts(eidx)
            eidx = eidx + 1
        End If
        If sjoinstr = "" Then
            sjoinstr = FormatString("{0} {1} !{2} {3} + <none> :{4} ", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SJOIN, "SJOIN"), IntToB64(ts), channel, stmp)
        ElseIf Len(sjoinstr + stmp) > 510 Then
            SendData RTrim(sjoinstr)
            sjoinstr = ""
        Else
            sjoinstr = sjoinstr & stmp & " "
        End If
    Loop
    If sjoinstr <> "" Then SendData sjoinstr
End Sub

Private Sub IIRCd_ChangeAccount(ByVal Source As String, ByVal target As String, ByVal account As String)
    'Change the account name.
    'First make sure the user is +r'd.
    SendData FormatString("{0} {1} {2} +r", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SVS2MODE, "SVS2MODE"), target)
    SendData FormatString("{0} {1} {2} :is logged in as {3}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SWHOIS, "SWHOIS"), target, account)
End Sub

Private Property Get IIRCd_ChanModes() As String
    IIRCd_ChanModes = "be,fkL,l,psmntirRcOAQKVGCuzNSMT"
End Property

Private Sub IIRCd_ChannelMode(ByVal Source As String, ByVal channel As String, ByVal modes As String)
    SendData FormatString("{0} {1} {2} {3}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_MODE, "MODE"), channel, modes)
End Sub

Private Sub IIRCd_ChannelTopic(ByVal Source As String, ByVal channel As String, ByVal Topic As String, ByVal SetBy As String, ByVal SetOn As Long)
    SendData FormatString("{0} {1} {2} {3} {4} :{5}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_TOPIC, "TOPIC"), channel, SetBy, SetOn, Topic)
End Sub

Private Property Get IIRCd_ChanOpChar() As String
    IIRCd_ChanOpChar = "o"
End Property

Private Sub IIRCd_CreateChannel(ByVal Source As String, ByVal channel As String)
    Dim ts As Long
    ts = basUnixTime.GetTime()
    SendData FormatString("@{0} {1} !{2} {3} + <none> :@{4}", IntToB64(basMain.Config.ServerNumeric), IIf(EnableToken, TOK_SJOIN, "SJOIN"), IntToB64(ts), channel, Source)
End Sub

Private Function IIRCd_CreateCID() As String
    Dim CID As Long, ts As Long
MakeCID:
    CID = Int(Rnd * (2# ^ 31))
    Dim u As User
    For Each u In basMain.Users
        If u.CID = CStr(CID) Then GoTo MakeCID
    Next u
    IIRCd_CreateCID = CID
End Function

Private Function IIRCd_CreateSID() As String
    Dim SID As Byte
MakeSID:
    SID = Int(Rnd * 255)
    Dim s As Server
    For Each s In basMain.Servers
        If s.SID = CStr(SID) Then GoTo MakeSID
    Next s
    IIRCd_CreateSID = SID
End Function

Private Sub IIRCd_DeleteNetworkIPBan(ByVal Source As String, ByVal Mask As String)
    SendData FormatString("{0} - Z * {1} {2}", IIf(EnableToken, TOK_TKL, "TKL"), Mask, Source)
End Sub

Private Sub IIRCd_DeleteNetworkNickBan(ByVal Source As String, ByVal Mask As String)
    SendData FormatString("{0} - Q * {1} {2}", IIf(EnableToken, TOK_TKL, "TKL"), Mask, Source)
End Sub

Private Sub IIRCd_DeleteNetworkRealnameBan(ByVal Source As String, ByVal Mask As String)
    SendData FormatString("SVSNLINE - :{0}", Mask)
End Sub

Private Sub IIRCd_DeleteNetworkUserhostBan(ByVal Source As String, ByVal Mask As String)
    SendData FormatString("{0} - G {1} {2} {3}", IIf(EnableToken, TOK_TKL, "TKL"), Split(Mask, "@", 2)(0), Split(Mask, "@", 2)(1), Source)
End Sub

Private Property Get IIRCd_ExemptChar() As String
    IIRCd_ExemptChar = "e"
End Property

Private Sub IIRCd_ForceNickChange(ByVal Source As String, ByVal target As String, ByVal NewNick As String)
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    SendData FormatString("{0} {1} {2} {3} {4}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SVSNICK, "SVSNICK"), target, NewNick, ts)
End Sub

Private Property Get IIRCd_HalfopChar() As String
    IIRCd_HalfopChar = "h"
End Property

Private Function IIRCd_HasSupport(ByVal SupportType As IRCdSupport) As Boolean
    Select Case SupportType
        Case SUPPORT_ISIRCD, SUPPORT_HASKILL, SUPPORT_HASSVSKILL, SUPPORT_HASNICKHACK, SUPPORT_HASNICKJUPE, _
            SUPPORT_HASVHOST, SUPPORT_HASVIDENT, SUPPORT_HASUMODEHACK, SUPPORT_HASNOOPERS, _
            SUPPORT_HASACCOUNT, SUPPORT_CHANGEACCOUNT, SUPPORT_USERHOSTBAN, SUPPORT_NICKBAN, SUPPORT_GCOSBAN, _
            SUPPORT_IPADDRBAN, SUPPORT_TEMPAKILL, SUPPORT_TEMPNICKBAN, SUPPORT_TEMPIPADDRBAN, _
            SUPPORT_DELAKILL, SUPPORT_DELNICKBAN, SUPPORT_DELGCOSBAN, SUPPORT_DELIPBAN, SUPPORT_USESSERVID, _
            SUPPORT_USESCLIENTID: IIRCd_HasSupport = True
        Case Else: IIRCd_HasSupport = False
    End Select
End Function

Private Sub IIRCd_HoldChannel(ByVal Source As String, ByVal channel As String)
    'Since we can assume the channel is empty...
    Dim ts As Long
    ts = basUnixTime.GetTime()
    SendData FormatString("@{0} {1} !{2} {3} +imsOKVl 1 :*@{4} &*!*@*", IntToB64(basMain.Config.ServerNumeric), IIf(EnableToken, TOK_SJOIN, "SJOIN"), IntToB64(ts), channel, Source)
    SendData FormatString("@{0} {1} {2} {3} {4} :{5}", IntToB64(basMain.Config.ServerNumeric), IIf(EnableToken, TOK_TOPIC, "TOPIC"), channel, Source, ts, "Channel juped by services")
End Sub

Private Sub IIRCd_HoldNick(ByVal Source As String, ByVal Nick As String)
    Dim ts As Long
    ts = basUnixTime.GetTime()
    SendData FormatString("{0} + Q H {1} {2} 0 {3} :{4}", IIf(EnableToken, TOK_TKL, "TKL"), Nick, Source, ts, "Held by services")
End Sub

Private Sub IIRCd_HoldServer(ByVal Source As String, ByVal Server As String)
    Err.Raise E_NOTIMPL
End Sub

Private Sub IIRCd_IntroduceClient(ByVal Nick As String, ByVal UserName As String, ByVal HostName As String, ByVal RealName As Variant, ByVal VHost As String, ByVal UserModes As String, ByVal CID As String, ByVal Server As String)
    Dim ts As Long
    'Get a TS
    ts = basUnixTime.GetTime()
    If Servers.Exists(Server) Then Err.Raise 9, , "Introduce server " + Server + " first."
#If UnrealVer >= 2304 Then
    'Need to do NICKv2 with SJB64 and NICKIP.
    SendData FormatString("{0} {1} {2} {3} !{4} {5} {6} {7} {8} {9} {10} * :{11}", GetNSSourcePrefix(Server), IIf(EnableToken, TOK_NICK, "NICK"), Nick, Servers(Server).Hops, IntToB64(ts), UserName, HostName, Server, CID, UserModes, VHost, RealName)
#Else
    'Need to do NICKv2 with SJB64.
    SendData FormatString("{0} {1} {2} {3} !{4} {5} {6} {7} {8} {9} {10} :{11}", GetNSSourcePrefix(Server), IIf(EnableToken, TOK_NICK, "NICK"), Nick, Servers(Server).Hops, IntToB64(ts), UserName, HostName, Server, CID, UserModes, VHost, RealName)
#End If
End Sub

Private Sub IIRCd_IntroduceSelf()
    'We can't token these.
    SendData FormatString("PASS :{0}", basMain.Config.UplinkPassword)
    SendData "PROTOCTL NOQUIT TOKEN NICKv2 SJOIN SJOIN2 UMODE2 VL SJ3 NS SJB64 TKLEXT NICKIP"
    SendData FormatString("SERVER {0} 1 :U{2}-*-{3} {4}", basMain.Config.ServerName, UnrealVer, CStr(basMain.Config.ServerNumeric), basMain.Config.ServerDescription)
End Sub

Private Sub IIRCd_IntroduceServer(ByVal ServerName As String, ByVal Hops As Long, ByVal SID As String, ByVal Description As String, ByVal BehindServer As String)
    SendData FormatString("{0} {1} {2} {3} :{4}", IIf(EnableToken, TOK_SERVER, "SERVER"), Hops, SID, Description)
End Sub

Private Property Get IIRCd_InvExChar() As String
    'NULL.
#If UnrealVer >= 2306 Then '3.2.3?
    IIRCd_InvExChar = "I"
#End If
End Property

Private Sub IIRCd_JoinChannel(ByVal Source As String, ByVal channel As String)
    SendData FormatString(":{0} {1} {2}", Source, IIf(EnableToken, TOK_JOIN, "JOIN"), channel)
End Sub

Private Sub IIRCd_KickUser(ByVal Source As String, ByVal channel As String, ByVal Victim As String, ByVal reason As String)
    SendData FormatString("{0} {1} {2} {3} :{4}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_KICK, "KICK"), channel, Victim, reason)
End Sub

Private Sub IIRCd_KillUser(ByVal Source As String, ByVal SVSKillOK As Boolean, ByVal User As String, ByVal reason As String)
    If SVSKillOK Then
        SendData FormatString("{0} {1} {2} :{3}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SVSKILL, "SVSKILL"), User, reason)
    Else
        SendData FormatString("{0} {1} {2} :{0} ({3})", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_KILL, "KILL"), User, reason)
    End If
End Sub

Private Property Get IIRCd_OwnerChar() As String
    IIRCd_OwnerChar = "q"
End Property

Private Sub IIRCd_ParseCmd(ByVal Buffer As String)
    If Buffer = "" Then Exit Sub
    Dim stmp As String
    stmp = Buffer 'Make a copy of the incoming text.
    'Hopefully this will replace all the stuff in
    '*_DataArrival :P . I'm hoping this will make us
    'less dependent on the form.
    Dim sLongArg As String 'Contain the long argument.
    Dim sSource As String 'Contain the source.
    Dim sCmd As String 'The command
    Dim vArgs As Variant 'Args not part of the long arg.
    'Asc() returns the ASCII code of the first char
    'of a string, so we can use that to check for a
    'source :) .
    If Asc(stmp) = Asc(":") Then
        sSource = Mid(stmp, 2)
        sSource = Left(sSource, InStr(sSource, " ") - 1)
        stmp = Mid(stmp, InStr(stmp, " ") + 1)
    End If
    'Now pull the command.
    If stmp = "" Then Exit Sub
    If InStr(stmp, " ") = 0 Then
        sCmd = stmp
        stmp = ""
    Else
        sCmd = Left(stmp, InStr(stmp, " ") - 1)
        stmp = Mid(stmp, InStr(stmp, " ") + 1)
    End If
    'Now, do we have any arguments?
    If stmp <> "" Then
        'Pull the long argument.
        If Asc(stmp) = Asc(":") Then
            'The whole list is the long arg.
            sLongArg = Mid(stmp, 2)
            stmp = ""
        ElseIf InStr(stmp, " :") > 0 Then
            'The long arg comes later.
            sLongArg = Mid(stmp, InStr(stmp, " :") + 2)
            stmp = Left(stmp, InStr(stmp, " :") - 1)
        End If
        'Now parse the remaining arguments.
        If stmp <> "" Then
            vArgs = Split(stmp, " ")
            'If we have a long arg, append it to the
            'end.
            If sLongArg <> "" Then
                ReDim Preserve vArgs(UBound(vArgs) + 1)
                vArgs(UBound(vArgs)) = sLongArg
            End If
        Else
            vArgs = Array(sLongArg)
        End If
    End If
    'Now validate the source.
    If InStr(sSource, ".") > 0 Then
        If Not Servers.Exists(sSource) Then
            PutQuick FormatString(":{0} SQUIT {1} :Unknown server ({1}(?) <- {2})", basMain.Config.ServerName, sSource, basMain.Config.UplinkName)
            Exit Sub
        End If
    Else
        If Not Users.Exists(sSource) Then
            PutQuick FormatString(":{0} KILL {1} :{0} ({1}(?) <- {2})", basMain.Config.ServerName, sSource, basMain.Config.UplinkName)
            Exit Sub
        End If
    End If
    'The command procs take a String(), not a Variant, so we have to make the types match. I tweaked this
    'so that all args start at (1) instead of (0), and (0) is the same as source. That way we never have an
    'empty argument array.
    Dim sArgs() As String, idx As Long
    If Not IsEmpty(vArgs) Then
        ReDim sArgs(0 To UBound(vArgs) + 1)
        sArgs(0) = sSource
        For idx = 0 To UBound(vArgs)
            sArgs(idx + 1) = vArgs(idx + 1)
        Next idx
    Else
        ReDim sArgs(0)
        sArgs(0) = sSource
    End If
    'Unreal is weird about this. Case is important in tokens, but not important in actual commands.
    'So what we'll do is a case sensitive Select for the tokens, then a case-insensitive select for the
    'commands. Apparently there's a known issue that include/msg.h isn't being as authoritive as it probably
    'should be, so I'm going to have to refer to the individual .c's for each command to get this :/ .
    Select Case sCmd
        'What shocks me is that some of these things even HAVE tokens! Items marked "???" are for commands
        'that I believe are never sent between servers.
        Case "6" 'AWAY
            sCmd = "AWAY"
        Case "V" 'AKILL - ??? (Unreal considers AKILL deperecated and TKL is used instead.)
            sCmd = "AKILL"
        Case "x" 'ADCHAT
            sCmd = "ADCHAT"
        Case "@" 'ADMIN
            sCmd = "ADMIN"
        Case "AR" 'ADDOMOTD
            sCmd = "ADDOMOTD"
        Case "AQ" 'ADDMOTD
            sCmd = "ADDMOTD"
        Case "z" 'ADDLINE - ???
            sCmd = "ADDLINE"
        Case "$" 'WHOWAS
            sCmd = "WHOWAS"
        Case "#" 'WHOIS
            sCmd = "WHOIS"
        Case """" 'WHO (This is a single quotation mark :/ .) - ???
            sCmd = "WHO"
        Case "=" 'WALLOPS
            sCmd = "WALLOPS"
        Case "BE" 'VHOST - ???
            sCmd = "VHOST"
        'USERIP doesn't have a token.
        Case "J" 'USERHOST - ???
            sCmd = "USERHOST"
        Case "r" 'UNZLINE
            sCmd = "UNZLINE"
        Case "d" 'UNSQLINE
            sCmd = "UNSQLINE"
        Case "X" 'UNKLINE
            sCmd = "UNKLINE"
        Case "BJ" 'UNDCCDENY
            sCmd = "UNDCCDENY"
        Case "|" 'UMODE2
            sCmd = "UMODE2"
        Case "AW" 'TSCTL (ALLTIME and SVSTIME only, probably)
            sCmd = "TSCTL"
        Case "b" 'TRACE
            sCmd = "TRACE"
        Case ")" 'TOPIC
            sCmd = "TOPIC"
        Case "}" 'GLINE
            sCmd = "GLINE"
        Case "BL" 'SHUN
            sCmd = "SHUN"
        Case "Tz" 'TEMPSHUN
            sCmd = "TEMPSHUN"
        Case ">" 'TIME
            sCmd = "TIME"
        Case "BA" 'SWHOIS
            sCmd = "SWHOIS"
        Case "Bw" 'SVSWATCH
            sCmd = "SVSWATCH"
        Case "BV" 'SVSSNO
            sCmd = "SVSSNO"
        Case "BW" 'SVS2SNO
            sCmd = "SVS2SNO"
        Case "Bs" 'SVSSILENCE
            sCmd = "SVSSILENCE"
        Case "BT" 'SVSPART
            sCmd = "SVSPART"
        Case "BB" 'SVSO
            sCmd = "SVSO"
        Case "f" 'SVSNOOP
            sCmd = "SVSNOOP"
        Case "BR" 'SVSNLINE
            sCmd = "SVSNLINE"
        Case "e" 'SVSNICK
            sCmd = "SVSNICK"
        Case "AS" 'SVSMOTD
            sCmd = "SVSMOTD"
        Case "n" 'SVSMODE
            sCmd = "SVSMODE"
        Case "v" 'SVS2MODE
            sCmd = "SVS2MODE"
        Case "BU" 'SVSLUSERS
            sCmd = "SVSLUSERS"
        Case "h" 'SVSKILL
            sCmd = "SVSKILL"
        Case "BX" 'SVSJOIN
            sCmd = "SVSJOIN"
        Case "BC" 'SVSFLINE
            sCmd = "SVSFLINE"
        Case "2" 'STATS
            sCmd = "STATS"
        Case "-" 'SQUIT
            sCmd = "SQUIT"
        Case "c" 'SQLINE
            sCmd = "SQLINE"
        Case "~" 'SJOIN
            sCmd = "SJOIN"
        Case "U" 'SILENCE - ???
            sCmd = "SILENCE"
        Case "AE" 'SETNAME
            sCmd = "SETNAME"
        Case "AD" 'SETIDENT
            sCmd = "SETIDENT"
        Case "AA" 'SETHOST
            sCmd = "SETHOST"
        Case "'" 'SERVER (Token valid for introducing servers behind self only.)
            sCmd = "SERVER"
        Case "AP" 'SENDUMODE
            sCmd = "SENDUMODE"
        Case "AU" 'SMO
            sCmd = "SMO"
        Case "Ss" 'SENDSNO
            sCmd = "SENDSNO"
        Case "AG" 'SDESC
            sCmd = "SDESC"
        Case "AY" 'SAPART
            sCmd = "SAPART"
        Case "o" 'SAMODE
            sCmd = "SAMODE"
        Case "AX" 'SAJOIN
            sCmd = "SAJOIN"
        Case "t" 'RULES
            sCmd = "RULES"
        Case "AM" 'RPING
            sCmd = "RPING"
        Case "AN" 'RPONG
            sCmd = "RPONG"
        Case "Y" 'RAKILL - ??? (Unreal considers AKILL deperecated and TKL is used instead.)
            sCmd = "RAKILL"
        Case "," 'QUIT
            sCmd = "QUIT"
        Case "_" 'PROTOCTL - ??? (PROTOCTL is only valid in the "registration" stage.)
            sCmd = "PROTOCTL"
        Case "8" 'PING
            sCmd = "PING"
        Case "9" 'PONG
            sCmd = "PONG"
        Case "<" 'PASS
            sCmd = "PASS"
        Case ";" 'OPER - ??? (Someone actually had Unreal CRASH by sending this as a server!)
            sCmd = "OPER"
        Case "AO" 'NETINFO
            sCmd = "NETINFO"
        Case "AC" 'NACHAT
            sCmd = "NACHAT"
        Case "y" 'MKPASSWD - ??? (Isn't this client-only?)
            sCmd = "MKPASSWD"
        Case "!" 'PRIVMSG
            sCmd = "PRIVMSG"
        Case "B" 'NOTICE
            sCmd = "NOTICE"
        Case "&" 'NICK
            sCmd = "NICK"
        Case "u" 'MAP - ??? (Servers should know about all servers, shouldn't need to ask another server...)
            sCmd = "MAP"
        Case "^" 'LOCOPS
            sCmd = "LOCOPS"
        Case "(" 'LIST - ??? (Servers should know about all channels, shouldn't need to ask around...)
            sCmd = "LIST"
        Case "0" 'LINKS - ??? (Servers should know about all servers, shouldn't need to ask around...)
            sCmd = "LINKS"
        Case "AF" 'LAG
            sCmd = "LAG"
        Case "AI" 'KNOCK - ??? (Actually not sure on this one.)
            sCmd = "KNOCK"
        Case "." 'KILL
            sCmd = "KILL"
        Case "H" 'KICK
            sCmd = "KICK"
        Case "K" 'ISON - ??? (Servers should know about all clients, shouldn't need to ask around...)
            sCmd = "ISON"
        Case "*" 'INVITE
            sCmd = "INVITE"
        Case "BH" 'HTM
            sCmd = "HTM"
        Case "4" 'HELP(OP)
            sCmd = "HELPOP"
        Case "]" 'GLOBOPS
            sCmd = "GLOBOPS"
        Case "ES" 'EOS
            sCmd = "EOS"
        Case "BI" 'DCCDENY
            sCmd = "DCCDENY"
        Case "BP" 'CYCLE - ??? (Unreal automatically changes CYCLE # to PART # :cycling \ JOIN # ...)
            sCmd = "CYCLE"
        Case "7" 'CONNECT
            sCmd = "CONNECT"
        Case "Q" 'CLOSE
            sCmd = "CLOSE"
        Case "BK" 'CHGNAME
            sCmd = "CHGNAME"
        Case "AZ" 'CHGIDENT
            sCmd = "CHGIDENT"
        Case "p" 'CHATOPS
            sCmd = "CHATOPS"
        Case "AL" 'CHGHOST
            sCmd = "CHGHOST"
        'Below came from include/msg.h :/
        Case "%" 'USER - ??? (Client-only thing.)
            sCmd = "USER"
        Case "+" 'VERSION
            sCmd = "VERSION"
        Case "/" 'INFO
            sCmd = "INFO"
        Case "1" 'SUMMON
            sCmd = "SUMMON"
        Case "3" 'USERS
            sCmd = "USERS"
        Case "5" 'ERROR
            sCmd = "ERROR"
        Case "?" 'NAMES
            sCmd = "NAMES"
        Case "C" 'JOIN
            sCmd = "JOIN"
        Case "D" 'PART
            sCmd = "PART"
        Case "E" 'LUSERS
            sCmd = "LUSERS"
        Case "F" 'MOTD
            sCmd = "MOTD"
        Case "G" 'MODE
            sCmd = "MODE"
        Case "I" 'SERVICE
            sCmd = "SERVICE"
        Case "O" 'REHASH
            sCmd = "REHASH"
        Case "P" 'RESTART
            sCmd = "RESTART"
        Case "R" 'DIE - ???
            sCmd = "DIE"
        Case "S" 'HASH - ??? (This isn't even an Unreal command >_>. Probably something from DreamForge.)
            sCmd = "HASH"
        Case "T" 'DNS - ???
            sCmd = "DNS"
        Case "W" 'KLINE - ??? (KLINEs are local, why should they be sent to other servers?)
            sCmd = "KLINE"
        Case "Z" 'GNOTICE - ??? (Probably another dreamforge command that got removed?)
            sCmd = "GNOTICE"
        Case "[" 'GOPER - ??? (Same.)
            sCmd = "GOPER"
        Case "`" 'WATCH - ??? (WATCH lists aren't servered, are they?)
            sCmd = "WATCH"
        Case "q" 'ZLINE - ??? (ZLINEs are local, why should they be sent to other servers?)
            sCmd = "ZLINE"
        Case "w" 'DALINFO - ???
            sCmd = "DALINFO"
        Case "AJ" 'CREDITS
            sCmd = "CREDITS"
        Case "AK" 'LICENSE
            sCmd = "LICENSE"
        Case "AV" 'OPERMOTD
            sCmd = "OPERMOTD"
        Case "BD" 'TKL
            sCmd = "TKL"
        Case "BF" 'BOTMOTD
            sCmd = "BOTMOTD"
        Case "BG" 'REMGLINE - ??? (Another DreamForge thingy?)
            sCmd = "REMGLINE"
        'SVSNAME is documented in include/msg.h but doesn't have a token :/ .
        'NEWJOIN is documented in include/msg.h but doesn't have a token :/ .
        Case "BN" 'POST
            sCmd = "POST"
        Case "BQ" 'MODULE
            sCmd = "MODULE"
    End Select
    Select Case UCase(sCmd)
        Case "AWAY": Call CmdAway(sSource, sArgs, Buffer)
        Case "AKILL": Call CmdAKill(sSource, sArgs, Buffer)
        Case "ADCHAT": Call CmdAdChat(sSource, sArgs, Buffer)
        Case "ADMIN": Call CmdAdmin(sSource, sArgs, Buffer)
        Case "ADDOMOTD": Call CmdAddOMotd(sSource, sArgs, Buffer)
        Case "ADDMOTD": Call CmdAddMotd(sSource, sArgs, Buffer)
        Case "ADDLINE": Call CmdAddLine(sSource, sArgs, Buffer)
        Case "WHOWAS": Call CmdWhoWas(sSource, sArgs, Buffer)
        Case "WHOIS": Call CmdWhoIs(sSource, sArgs, Buffer)
        Case "WHO": Call CmdWho(sSource, sArgs, Buffer)
        Case "WALLOPS": Call CmdWallops(sSource, sArgs, Buffer)
        Case "VHOST": Call CmdVHost(sSource, sArgs, Buffer)
        Case "USERIP": Call CmdUserIP(sSource, sArgs, Buffer)
        Case "USERHOST": Call CmdUserHost(sSource, sArgs, Buffer)
        Case "UNZLINE": Call CmdUnZLine(sSource, sArgs, Buffer)
        Case "UNSQLINE": Call CmdUnSQLine(sSource, sArgs, Buffer)
        Case "UNKLINE": Call CmdUnKLine(sSource, sArgs, Buffer)
        Case "UNDCCDENY": Call CmdUnDCCDeny(sSource, sArgs, Buffer)
        Case "UMODE2": Call CmdUMode2(sSource, sArgs, Buffer)
        Case "TSCTL": Call CmdTSCTL(sSource, sArgs, Buffer)
        Case "TRACE": Call CmdTrace(sSource, sArgs, Buffer)
        Case "TOPIC": Call CmdTopic(sSource, sArgs, Buffer)
        Case "GLINE": Call CmdGLine(sSource, sArgs, Buffer)
        Case "SHUN": Call CmdShun(sSource, sArgs, Buffer)
        Case "TEMPSHUN": Call CmdTempShun(sSource, sArgs, Buffer)
        Case "TIME": Call CmdTime(sSource, sArgs, Buffer)
        Case "SWHOIS": Call CmdSWhois(sSource, sArgs, Buffer)
        Case "SVSWATCH": Call CmdSVSWatch(sSource, sArgs, Buffer)
        Case "SVSSNO": Call CmdSVSSno(sSource, sArgs, Buffer)
        Case "SVS2SNO": Call CmdSVS2Sno(sSource, sArgs, Buffer)
        Case "SVSSILENCE": Call CmdSVSSilence(sSource, sArgs, Buffer)
        Case "SVSPART": Call CmdSVSPart(sSource, sArgs, Buffer)
        Case "SVSO": Call CmdSVSO(sSource, sArgs, Buffer)
        Case "SVSNOOP": Call CmdSVSNoOp(sSource, sArgs, Buffer)
        Case "SVSNLINE": Call CmdSVSNLine(sSource, sArgs, Buffer)
        Case "SVSNICK": Call CmdSVSNick(sSource, sArgs, Buffer)
        Case "SVSMOTD": Call CmdSVSMotd(sSource, sArgs, Buffer)
        Case "SVSMODE": Call CmdSVSMode(sSource, sArgs, Buffer)
        Case "SVS2MODE": Call CmdSVS2Mode(sSource, sArgs, Buffer)
        Case "SVSLUSERS": Call CmdSVSLUsers(sSource, sArgs, Buffer)
        Case "SVSKILL": Call CmdSVSKill(sSource, sArgs, Buffer)
        Case "SVSJOIN": Call CmdSVSJoin(sSource, sArgs, Buffer)
        Case "SVSFLINE": Call CmdSVSFLine(sSource, sArgs, Buffer)
        Case "STATS": Call CmdStats(sSource, sArgs, Buffer)
        Case "SQUIT": Call CmdSQuit(sSource, sArgs, Buffer)
        Case "SQLINE": Call CmdSQLine(sSource, sArgs, Buffer)
        Case "SJOIN": Call CmdSJoin(sSource, sArgs, Buffer)
        Case "SILENCE": Call CmdSilence(sSource, sArgs, Buffer)
        Case "SETNAME": Call CmdSetName(sSource, sArgs, Buffer)
        Case "SETIDENT": Call CmdSETIDENT(sSource, sArgs, Buffer)
        Case "SETHOST": Call CmdSetHost(sSource, sArgs, Buffer)
        Case "SERVER": Call CmdServer(sSource, sArgs, Buffer)
        Case "SENDUMODE": Call CmdSENDUMODE(sSource, sArgs, Buffer)
        Case "SMO": Call CmdSMo(sSource, sArgs, Buffer)
        Case "SENDSNO": Call CmdSENDSNO(sSource, sArgs, Buffer)
        Case "SDESC": Call CmdSDESC(sSource, sArgs, Buffer)
        Case "SAPART": Call CmdSAPART(sSource, sArgs, Buffer)
        Case "SAMODE": Call CmdSAMODE(sSource, sArgs, Buffer)
        Case "SAJOIN": Call CmdSAJOIN(sSource, sArgs, Buffer)
        Case "RULES": Call CmdRULES(sSource, sArgs, Buffer)
        Case "RPING": Call CmdRPING(sSource, sArgs, Buffer)
        Case "RPONG": Call CmdRPONG(sSource, sArgs, Buffer)
        Case "RAKILL": Call CmdRAKILL(sSource, sArgs, Buffer)
        Case "QUIT": Call CmdQuit(sSource, sArgs, Buffer)
        Case "PROTOCTL": Call CmdProtoctl(sSource, sArgs, Buffer)
        Case "PING": Call CmdPing(sSource, sArgs, Buffer)
        Case "PONG": Call CmdPong(sSource, sArgs, Buffer)
        Case "PASS": Call CmdPass(sSource, sArgs, Buffer)
        Case "OPER": Call CmdOPER(sSource, sArgs, Buffer)
        Case "NETINFO": Call CmdNetinfo(sSource, sArgs, Buffer)
        Case "NACHAT": Call CmdNACHAT(sSource, sArgs, Buffer)
        Case "MKPASSWD": Call CmdMKPASSWD(sSource, sArgs, Buffer)
        Case "PRIVMSG": Call CmdPrivMsg(sSource, sArgs, Buffer)
        Case "NOTICE": Call CmdNotice(sSource, sArgs, Buffer)
        Case "NICK": Call CmdNick(sSource, sArgs, Buffer)
        Case "MAP": Call CmdMAP(sSource, sArgs, Buffer)
        Case "LOCOPS": Call CmdLOCOPS(sSource, sArgs, Buffer)
        Case "LIST": Call CmdLIST(sSource, sArgs, Buffer)
        Case "LINKS": Call CmdLINKS(sSource, sArgs, Buffer)
        Case "LAG": Call CmdLAG(sSource, sArgs, Buffer)
        Case "KNOCK": Call CmdKNOCK(sSource, sArgs, Buffer)
        Case "KILL": Call CmdKill(sSource, sArgs, Buffer)
        Case "KICK": Call CmdKICK(sSource, sArgs, Buffer)
        Case "ISON": Call CmdISON(sSource, sArgs, Buffer)
        Case "INVITE": Call CmdINVITE(sSource, sArgs, Buffer)
        Case "HTM": Call CmdHTM(sSource, sArgs, Buffer)
        Case "HELP", "HELPOP": Call CmdHELP(sSource, sArgs, Buffer)
        Case "GLOBOPS": Call CmdGLOBOPS(sSource, sArgs, Buffer)
        Case "EOS": Call CmdEOS(sSource, sArgs, Buffer)
        Case "DCCDENY": Call CmdDCCDENY(sSource, sArgs, Buffer)
        Case "CYCLE": Call CmdCYCLE(sSource, sArgs, Buffer)
        Case "CONNECT": Call CmdCONNECT(sSource, sArgs, Buffer)
        Case "CLOSE": Call CmdCLOSE(sSource, sArgs, Buffer)
        Case "CHGNAME": Call CmdCHGNAME(sSource, sArgs, Buffer)
        Case "CHGIDENT": Call CmdCHGIDENT(sSource, sArgs, Buffer)
        Case "CHATOPS": Call CmdCHATOPS(sSource, sArgs, Buffer)
        Case "CHGHOST": Call CmdCHGHOST(sSource, sArgs, Buffer)
        Case "USER": Call CmdUSER(sSource, sArgs, Buffer)
        Case "VERSION": Call CmdVersion(sSource, sArgs, Buffer)
        Case "INFO": Call CmdINFO(sSource, sArgs, Buffer)
        Case "SUMMON": Call CmdSUMMON(sSource, sArgs, Buffer)
        Case "USERS": Call CmdUSERS(sSource, sArgs, Buffer)
        Case "ERROR": Call CmdError(sSource, sArgs, Buffer)
        Case "NAMES": Call CmdNAMES(sSource, sArgs, Buffer)
        Case "JOIN": Call CmdJoin(sSource, sArgs, Buffer)
        Case "PART": Call CmdPart(sSource, sArgs, Buffer)
        Case "LUSERS": Call CmdLUSERS(sSource, sArgs, Buffer)
        Case "MOTD": Call CmdMotd(sSource, sArgs, Buffer)
        Case "MODE": Call CmdMode(sSource, sArgs, Buffer)
        Case "SERVICE": Call CmdSERVICE(sSource, sArgs, Buffer)
        Case "REHASH": Call CmdRehash(sSource, sArgs, Buffer)
        Case "RESTART": Call CmdRESTART(sSource, sArgs, Buffer)
        Case "DIE": Call CmdDIE(sSource, sArgs, Buffer)
        Case "HASH": Call CmdHASH(sSource, sArgs, Buffer)
        Case "DNS": Call CmdDNS(sSource, sArgs, Buffer)
        Case "KLINE": Call CmdKLINE(sSource, sArgs, Buffer)
        Case "GNOTICE": Call CmdGNOTICE(sSource, sArgs, Buffer)
        Case "GOPER": Call CmdGOPER(sSource, sArgs, Buffer)
        Case "WATCH": Call CmdWATCH(sSource, sArgs, Buffer)
        Case "ZLINE": Call CmdZLINE(sSource, sArgs, Buffer)
        Case "DALINFO": Call CmdDALINFO(sSource, sArgs, Buffer)
        Case "CREDITS": Call CmdCREDITS(sSource, sArgs, Buffer)
        Case "LICENSE": Call CmdLICENSE(sSource, sArgs, Buffer)
        Case "OPERMOTD": Call CmdOPERMOTD(sSource, sArgs, Buffer)
        Case "TKL": Call CmdTKL(sSource, sArgs, Buffer)
        Case "BOTMOTD": Call CmdBOTMOTD(sSource, sArgs, Buffer)
        Case "REMGLINE": Call CmdREMGLINE(sSource, sArgs, Buffer)
        Case "SVSNAME": Call CmdSVSNAME(sSource, sArgs, Buffer)
        Case "NEWJOIN": Call CmdNEWJOIN(sSource, sArgs, Buffer)
        Case "POST": Call CmdPOST(sSource, sArgs, Buffer)
        Case "MODULE": Call CmdMODULE(sSource, sArgs, Buffer)
        Case Else: LogEventWithMessage LogTypeNotice, FormatString("Unknown message from uplink: {0}", Buffer)
    End Select
End Sub

Private Sub IIRCd_PartChannel(ByVal Source As String, ByVal channel As String, ByVal reason As String)
    SendData FormatString("{0} {1} {2} :{3}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_PART, "PART"), channel, reason)
End Sub

Private Property Get IIRCd_ProtectChar() As String
    IIRCd_ProtectChar = "a"
End Property

Private Sub IIRCd_ReleaseChannel(ByVal Source As String, ByVal channel As String)
    SendData FormatString(":{0} MODE {1} -imsOKVl", Source, channel)
    SendData FormatString(":{0} PART {1}", Source, channel)
End Sub

Private Sub IIRCd_ReleaseNick(ByVal Source As String, ByVal Nick As String)
    SendData FormatString("{0} - Q H {1} {2}", IIf(EnableToken, TOK_TKL, "TKL"), Nick, Source)
End Sub

Private Sub IIRCd_ReleaseServer(ByVal Source As String, ByVal Server As String)
    Err.Raise E_NOTIMPL
End Sub

Private Sub IIRCd_RemoveClient(ByVal Nick As String, ByVal reason As String)
    SendData FormatString(":{0} {1} :{2}", Nick, IIf(EnableToken, TOK_QUIT, "QUIT"), reason)
End Sub

Private Sub IIRCd_RemoveServer(ByVal Sender As String, ByVal Server As String, ByVal reason As String)
    SendData FormatString("{0} {1} {2} :{3}", GetNSSourcePrefix(Sender), IIf(EnableToken, TOK_SQUIT, "SQUIT"), Server, reason)
End Sub

Private Sub IIRCd_SendNumeric(ByVal target As String, ByVal Numeric As Integer, ByVal Text As String)
    SendData FormatString("@{0} {1:000} {2} {3}", IntToB64(basMain.Config.ServerNumeric), Format(Numeric, "000"), target, Text)
End Sub

Private Sub IIRCd_SendPrivMsg(ByVal Source As String, ByVal target As String, ByVal Notice As Boolean, ByVal Text As String)
    SendData FormatString("{0} {1} {2} :{3}", GetNSSourcePrefix(Source), IIf(Notice, IIf(EnableToken, TOK_NOTICE, "NOTICE"), IIf(EnableToken, TOK_PRIVMSG, "PRIVMSG")), target, Text)
End Sub

Private Sub IIRCd_SendToUMode(ByVal Source As String, ByVal UMode As String, ByVal Message As String)
    SendData FormatString("@{0} SMO {1} :{2}", IntToB64(basMain.Config.ServerNumeric), UMode, Message)
End Sub

Private Sub IIRCd_SetAccount(ByVal Source As String, ByVal target As String, ByVal account As String)
    SendData FormatString("{0} {1} {2} +r", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SVS2MODE, "SVS2MODE"), target)
    SendData FormatString("{0} {1} {2} :is logged in as {3}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SWHOIS, "SWHOIS"), target, account)
End Sub

Private Sub IIRCd_SetServerNoOpers(ByVal Source As String, ByVal Server As String)
    SendData FormatString("{0} SVSNOOP {1} +", GetNSSourcePrefix(Source), Server)
End Sub

Private Sub IIRCd_SetUserModes(ByVal Source As String, ByVal Nick As String, ByVal modes As String)
    SendData FormatString("{0} {1} {2} {3}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SVS2MODE, "SVS2MODE"), Nick, modes)
End Sub

Private Sub IIRCd_SetVHost(ByVal Source As String, ByVal Nick As String, ByVal VHost As String)
    If VHost <> "" Then
        SendData FormatString("{0} CHGHOST {1} {2}", GetNSSourcePrefix(Source), Nick, VHost)
    Else
        SendData FormatString("{0} {1} {2} -x", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SVS2MODE, "SVS2MODE"), Nick)
    End If
End Sub

Private Sub IIRCd_SetVIdent(ByVal Source As String, ByVal Nick As String, ByVal VIdent As String)
    If VIdent <> "" Then
        SendData FormatString("{0} CHGIDENT {1} {2}", GetNSSourcePrefix(Source), Nick, VIdent)
    End If
End Sub

Private Sub IIRCd_UnsetServerNoOpers(ByVal Source As String, ByVal Server As String)
    SendData FormatString("{0} SVSNOOP {1} -", GetNSSourcePrefix(Source), Server)
End Sub

Private Property Get IIRCd_UserModes() As String
    IIRCd_UserModes = "iowghraAsORTVSxNCWqBzvdHtGp"
End Property

Private Property Get IIRCd_VoiceChar() As String
    IIRCd_VoiceChar = "v"
End Property

Private Sub IIRCd_Wallopers(ByVal Source As String, ByVal Message As String)
    SendData FormatString("{0} {1} :{2}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_GLOBOPS, "GLOBOPS"), Message)
End Sub

'And these functions are translated from UnrealIRCd src/aln.c
Private Function IntToB64(ByVal val As Long) As String
    Dim map() As Variant
    map = Array("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", _
        "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", _
        "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", _
        "w", "x", "y", "z", "{", "}")
    Static b64buf As String * 7
    Dim i As Long
    i = 8
    'Unreal does some weird check to see if val is over 2^31-1, but we don't need it since Long can't do that.
    'Unreal's check just calls abort() if it is over, which we shouldn't do.
    Do
        i = i - 1
        Mid(b64buf, i, 1) = map(val And 63)
        'Now we need to do a 6-bit right shift. Unreal's code uses a signed long, and by C's standard,
        '>> on a signed integer performs an arithmetic shift. This will play havoc if val is < 0 but that
        'shouldn't happen anyway.
        val = val \ (2 ^ 6)
    Loop While val
    IntToB64 = Mid(b64buf, i)
End Function

Private Function B64ToInt(ByVal b64 As String) As Long
    Dim map() As Variant
    map = Array(-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -1, -1, -1, -1, -1, -1, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, _
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, -1, -1, -1, -1, -1, -1, 36, 37, 38, 39, 40, 41, _
    42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, -1, 63, -1, -1, -1, _
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1)
    Dim idx As Long
    Dim v As Long
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
        If CDbl(v) * (2 ^ 6) > 2147483647# Then
            v = FMod(v * (2 ^ 6), 2147483648#) + -2147483648#
        Else
            v = v * (2 ^ 6)
        End If
        v = v + map(Asc(Mid(b64, idx, 1)))
    Next idx
    B64ToInt = v
End Function

Private Sub CmdAway(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    Dim u As User
    If Source = "" Or InStr(Source, ".") > 0 Then Exit Sub
    If UBound(Args) < 1 Then
        u.AwayMessage = vbNullString
    Else
        u.AwayMessage = Args(1)
    End If
End Sub

Private Sub CmdAKill(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    'All t*lines will be passed to CmdTKL, so generate a TKL.
    Dim tklargs(0 To 8) As String, ts As Long
    ts = basUnixTime.GetTime
    If UBound(Args) < 2 Then Exit Sub
    'TKL + <type> <user> <host> <source> <expiry_ts> <set_ts> :<reason>
    tklargs(0) = Source
    tklargs(1) = "+" 'Setting
    tklargs(2) = "G" 'Type = GLINE
    tklargs(3) = Split(Args(1), "@", 2)(0) 'Username
    tklargs(4) = Split(Args(1), "@", 2)(1) 'Hostname
    tklargs(5) = Source 'Setby.
    tklargs(6) = "0" 'No expiry.
    tklargs(7) = CStr(ts)  'Timestamp
    tklargs(8) = Args(2) 'Reason
    CmdTKL Source, tklargs, RawMsg
End Sub

Private Sub CmdAdChat(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    'We could log this if we wanted to...
    If UBound(Args) < 1 Then Exit Sub
#If 0 Then 'Change to 1 if you want to log this.
    LogEvent basMain.LogTypeNotice, FormatString("ADCHAT from {0}: {1}", Source, Args(1))
#End If
End Sub

Private Sub CmdAdmin(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    'ADMIN reply...
    Dim sNick As String
    sNick = ExtractNickFromNUH(Source)
    Call basFunctions.SendData(":" & basMain.Config.ServerName & " 256 " & sNick & " " & basMain.Config.ServerName & " :Administrative info")
    'First Line: Name and Info of the server
    Call basFunctions.SendData(":" & basMain.Config.ServerName & " 257 " & sNick & " :" & basMain.Config.ServerName & " " & basMain.Config.ServerDescription)
    'Second Line: The permenant Services Master (and email?)
    Call basFunctions.SendData(":" & basMain.Config.ServerName & " 258 " & sNick & " :" & basMain.Config.ServicesMaster)
    'Third Line: List of online service ops (nick only). Put comasters in bold, and master in bold and underline.
    Dim sSOPs As String, u As User
    For Each u In Users
        If u.Access <> "" Then
            If u.HasFlag(AccFlagMaster) Then
                sSOPs = sSOPs & MakeBold(MakeUnderline(u.Nick)) & " "
            ElseIf u.HasFlag(AccFlagCoMaster) Then
                sSOPs = sSOPs & MakeBold(u.Nick) & " "
            Else
                sSOPs = sSOPs & u.Nick & " "
            End If
        End If
    Next u
    sSOPs = RTrim(sSOPs)
    'We need to check this, to be sure we don't go over 510 bytes :/
    Dim sSendString As String
    If Len(sSendString) > 510 Then
        'Oh dear, we have that many operators (and/or their nicks are that long?).
        sSendString = ":" & basMain.Config.ServerName & " 259 " & sNick & " :Online Operators: " & MakeBold(MakeColor("A LOT", 4)) & " - Try " & MakeBold("/stats o " & basMain.Config.ServerName) & " to see them."
    Else
        sSendString = ":" & basMain.Config.ServerName & " 259 " & sNick & " :Online Operators: " & sSOPs
    End If
    Call basFunctions.SendData(sSendString)
End Sub

Private Sub CmdAddOMotd(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    'IGNORE.
End Sub

Private Sub CmdAddMotd(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    'IGNORE.
End Sub

Private Sub CmdAddLine(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    'IGNORE.
End Sub

Private Sub CmdWhoWas(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    'I'm not planning on nicktracking like that... IGNORE.
End Sub

Private Sub CmdWhoIs(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    Dim target As String
    If UBound(Args) < 1 Then Exit Sub
    If UBound(Args) = 1 Then target = Args(1)
    If UBound(Args) >= 2 Then target = Args(2)
    If Not IsServicesNick(target) Then
        SendNumeric target, 401, FormatString("{0} :No such nick/channel", target)
    Else
        Dim srv As Long, idx As Long
        For idx = 0 To UBound(Service)
            If Service(idx).Nick = target Then
                srv = idx
                Exit For
            End If
        Next idx
        'NickServ is nickname@services.winse.net * nickname
        SendNumeric Source, 311, FormatString("{0} {1} {2} * {1}", Service(srv).Nick, Service(srv).Name, Service(srv).Hostmask)
        'If it's an IRCop request, send our usermodes, snomasks (none), and real host/ip...
        If Users.Exists(Source) Then
            If InStr(Users(Source).modes, "o") > 0 Then
                'NickServ is using modes +iSqr
                SendNumeric Source, 379, FormatString("{0} :is using modes {1}", Service(srv).Nick, Service(srv).UserModes)
                'NickServ is connecting from *@services.winse.net 0.0.0.0
                SendNumeric Source, 378, FormatString("{0} :is connecting from *@{1} 0.0.0.0", basMain.Config.ServerName)
            End If
        End If
        'NickServ is a registered nick.
        SendNumeric Source, 307, FormatString("{0} :is a registered nick.")
        'Don't report channels.
        'NickServ on services.winse.net :WinSE IRC Services
        SendNumeric Source, 312, FormatString("{0} {1} :{2}", Service(srv).Nick, basMain.Config.ServerName, basMain.Config.ServerDescription)
        'NickServ is a Network Service
        SendNumeric Source, 313, FormatString("{0} :is a Network Service", Service(srv).Nick)
        'NickServ - Nickname Registration Services
        SendNumeric Source, 320, FormatString("{0} :- {1}", Service(srv).Nick, Service(srv).Info)
        'NickServ has been idle X seconds, signed on Y
        'Not sending this for now since we would have to track when services started...
        SendNumeric Source, 318, FormatString("{0} :End of /WHOIS list.", target)
    End If
End Sub

Private Sub CmdWho(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdWallops(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    'We could log this if we wanted to...
    If UBound(Args) < 1 Then Exit Sub
#If 0 Then 'Change to 1 if you want to log this.
    LogEvent basMain.LogTypeNotice, FormatString("WALLOPS from {0}: {1}", Source, Args(1))
#End If
End Sub

Private Sub CmdVHost(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdUserIP(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdUserHost(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdUnZLine(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdUnSQLine(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    Dim tklargs(0 To 5) As String
    If UBound(Args) < 1 Then Exit Sub
    'TKL - <type> <user> <host> <source>
    tklargs(0) = Source
    tklargs(1) = "-"
    tklargs(2) = "Q"
    tklargs(3) = "*"
    tklargs(4) = Args(1)
    tklargs(5) = Source
    CmdTKL Source, tklargs, RawMsg
End Sub

Private Sub CmdUnKLine(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdUnDCCDeny(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdUMode2(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    Dim umodeargs(0 To 2) As String
    If UBound(Args) < 1 Then Exit Sub
    umodeargs(0) = Source
    umodeargs(1) = Source
    umodeargs(2) = Args(1)
    CmdMode Source, umodeargs, RawMsg
End Sub

Private Sub CmdTSCTL(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    'Only ALLTIME and SVSTIME are valid - and technically only ALLTIME since SVSTIME is a Services command.
    If UBound(Args) < 1 Then Exit Sub
    If UCase(Args(1)) = "ALLTIME" Then
        'Report the reply, unreal-style!
        Notice basMain.Config.ServerName, Source, FormatString("Server={0} TStime={1} time()={1} TSoffset=0", basMain.Config.ServerName, basUnixTime.GetTime())
    ElseIf UCase(Args(1)) = "SVSTIME" Then
        'We could set our time but... no. :)
    End If
End Sub

Private Sub CmdTrace(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE. :x
End Sub

Private Sub CmdTopic(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    Dim sNick As String
    sNick = ExtractNickFromNUH(Source)
    If UBound(Args) < 2 Then
        Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replies.SanityCheckTOPICInsufficientParameters)
        Call basFunctions.PutQuick(":" + basMain.Config.ServerName + " 461 " + basMain.Config.UplinkName + " TOPIC :Not enough parameters")
    ElseIf UBound(Args) = 2 Then
        With Channels(Args(1))
            .Topic = Args(2)
            .TopicSetBy = Source
            .TopicSetOn = basUnixTime.GetTime
        End With
    ElseIf UBound(Args) > 2 And UBound(Args) < 4 Then
        Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replies.SanityCheckTOPICInsufficientParameters)
        Call basFunctions.PutQuick(":" + basMain.Config.ServerName + " 461 " + basMain.Config.UplinkName + " TOPIC :Not enough parameters")
    ElseIf UBound(Args) >= 4 Then
        With Channels(Args(1))
            .Topic = Args(4)
            .TopicSetBy = Args(2)
            .TopicSetOn = Args(3)
        End With
    End If
End Sub

Private Sub CmdGLine(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    Dim tklargs(0 To 8) As String, ts As Long, Expiry As Long
    ts = basUnixTime.GetTime
    If UBound(Args) < 2 Then Exit Sub
    If UBound(Args) = 3 Then
        On Error Resume Next
        Expiry = Duration(Args(2))
        If Err.Number Then Expiry = 0
        On Error GoTo 0
    Else
        Expiry = 0
    End If
    'TKL + <type> <user> <host> <source> <expiry_ts> <set_ts> :<reason>
    tklargs(0) = Source
    tklargs(1) = "+" 'Setting
    tklargs(2) = "G" 'Type = GLINE
    tklargs(3) = Split(Args(1), "@", 2)(0) 'Username
    tklargs(4) = Split(Args(1), "@", 2)(1) 'Hostname
    tklargs(5) = Source 'Setby.
    tklargs(6) = IIf(Expiry > 0, CStr(ts + Expiry), "0")
    tklargs(7) = CStr(ts)  'Timestamp
    tklargs(8) = Args(2) 'Reason
    CmdTKL Source, tklargs, RawMsg
End Sub

Private Sub CmdShun(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    Dim tklargs(0 To 8) As String, ts As Long, Expiry As Long
    ts = basUnixTime.GetTime
    If UBound(Args) < 2 Then Exit Sub
    If UBound(Args) = 3 Then
        On Error Resume Next
        Expiry = Duration(Args(2))
        If Err.Number Then Expiry = 0
        On Error GoTo 0
    Else
        Expiry = 0
    End If
    'TKL + <type> <user> <host> <source> <expiry_ts> <set_ts> :<reason>
    tklargs(0) = Source
    tklargs(1) = "+" 'Setting
    tklargs(2) = "s" 'Type = GLINE
    tklargs(3) = Split(Args(1), "@", 2)(0) 'Username
    tklargs(4) = Split(Args(1), "@", 2)(1) 'Hostname
    tklargs(5) = Source 'Setby.
    tklargs(6) = IIf(Expiry > 0, CStr(ts + Expiry), "0")
    tklargs(7) = CStr(ts)  'Timestamp
    tklargs(8) = Args(2) 'Reason
    CmdTKL Source, tklargs, RawMsg
End Sub

Private Sub CmdTempShun(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdTime(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    SendNumeric Source, 391, Format(Now, "dddd mmmm dd yyyy -- hh:mm")
End Sub

Private Sub CmdSWhois(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    If UBound(Args) < 1 Then Exit Sub
    If Users.Exists(Source) Then
        Users(Source).SWhois = Args(1)
    End If
End Sub

Private Sub CmdSVSWatch(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdSVSSno(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdSVS2Sno(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdSVSSilence(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdSVSPart(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdSVSO(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdSVSNoOp(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE
End Sub

Private Sub CmdSVSNLine(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdSVSNick(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdSVSMotd(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdSVSMode(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdSVS2Mode(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdSVSLUsers(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdSVSKill(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'This we have to handle somehow :X
End Sub

Private Sub CmdSVSJoin(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdSVSFLine(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdStats(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdSQuit(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    'Delete a server...
    Dim target As String, reason As String
    If UBound(Args) < 2 Then Exit Sub
    target = Args(1)
    reason = Args(2)
    If Not Servers.Exists(target) Then Exit Sub
    If target = basMain.Config.ServerName Then
        'Eeek?
    ElseIf target = basMain.Config.UplinkName Then
        'Exit SQUIT! Don't bother with message because we're getting zapped.
        LogEvent LogTypeNotice, FormatString("SQUIT to uplink ({0}) by {1}: {2}", basMain.Config.UplinkName, Source, reason)
    ElseIf Servers(target).OurServer Then
        LogEventWithMessage LogTypeNotice, FormatString("SQUIT for jupe {0} by {1}: {2}", target, Source, reason)
    End If
    Servers(target).Dispose
End Sub

Private Sub CmdSQLine(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    Dim tklargs(0 To 8) As String, ts As Long
    ts = basUnixTime.GetTime
    If UBound(Args) < 2 Then Exit Sub
    'TKL + <type> <user> <host> <source> <expiry_ts> <set_ts> :<reason>
    tklargs(0) = Source
    tklargs(1) = "+" 'Setting
    tklargs(2) = "Q" 'Type = GLINE
    tklargs(3) = "*" 'Username = *
    tklargs(4) = Args(1) 'Hostname = Nickpattern
    tklargs(5) = Source 'Setby.
    tklargs(6) = "0" 'No expiry.
    tklargs(7) = CStr(ts)  'Timestamp
    tklargs(8) = Args(2) 'Reason
    CmdTKL Source, tklargs, RawMsg
End Sub

Private Sub CmdSJoin(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    'SJOIN! The most fun command ever... YAY.
    'Now we remember the format of this from BurstChannel, right? If not here it is again:
    'SJOIN ts #channel +modes modeparams :*Owner ~Admin @Op %Halfop +Voice &Ban "Exempt
    Dim ts As Long, channame As String, modes As String, u() As String, stmp As Variant
    Dim modeargs() As String, joinargs() As String
    If UBound(Args) < 5 Then Exit Sub
    ts = Args(1)
    channame = Args(2)
    modes = Args(3)
    u = Split(Args(UBound(Args)), " ")
    Dim idx As Long
    For idx = 4 To UBound(Args) - 1
        modes = modes & " " & Args(idx)
    Next idx
    Dim chptr As channel
    'Do we already know this channel?
    If Channels.Exists(channame) Then
        Set chptr = Channels(channame)
        'If the TS is bigger, ignore the mode info (except bans/exempts).
        If chptr.ts < ts Then
            'Only parse the nicks, bans and exempts.
            For Each stmp In u
                'Does stmp start with an & or "?
                If Left(stmp, 1) = "&" Then
                    'It's a ban...
                    ReDim modeargs(0 To 4)
                    modeargs(0) = Source
                    modeargs(1) = channame
                    modeargs(2) = "+b"
                    modeargs(3) = Mid(stmp, 2)
                    modeargs(4) = ts
                    CmdMode Source, modeargs, RawMsg
                    Erase modeargs
                ElseIf Left(stmp, 1) = """" Then
                    'It's an except.
                    ReDim modeargs(0 To 4)
                    modeargs(0) = Source
                    modeargs(1) = channame
                    modeargs(2) = "+e"
                    modeargs(3) = Mid(stmp, 2)
                    modeargs(4) = ts
                    CmdMode Source, modeargs, RawMsg
                    Erase modeargs
                Else
                    'It's a user. Ignore the prefixes.
                    While InStr("*~@%+", Left(stmp, 1)) > 0
                        stmp = Mid(stmp, 2)
                    Wend
                    ReDim joinargs(0 To 1)
                    joinargs(0) = stmp
                    joinargs(1) = channame
                    CmdJoin Source, joinargs, RawMsg
                    Erase joinargs
                End If
            Next stmp
        ElseIf chptr.ts = ts Then
            Dim prfx As String
            'Merge existing info.
            Dim v As Variant
            v = Split(modes, " ")
            ReDim modeargs(UBound(v) + 2)
            modeargs(0) = Source
            modeargs(1) = channame
            For idx = 2 To UBound(modeargs)
                modeargs(idx) = v(idx - 2)
            Next idx
            CmdMode Source, modeargs, RawMsg
            For Each stmp In u
                'Does stmp start with an & or "?
                If Left(stmp, 1) = "&" Then
                    'It's a ban...
                    ReDim modeargs(0 To 4)
                    modeargs(0) = Source
                    modeargs(1) = channame
                    modeargs(2) = "+b"
                    modeargs(3) = Mid(stmp, 2)
                    modeargs(4) = ts
                    CmdMode Source, modeargs, RawMsg
                    Erase modeargs
                ElseIf Left(stmp, 1) = """" Then
                    'It's an except.
                    ReDim modeargs(0 To 4)
                    modeargs(0) = Source
                    modeargs(1) = channame
                    modeargs(2) = "+e"
                    modeargs(3) = Mid(stmp, 2)
                    modeargs(4) = ts
                    CmdMode Source, modeargs, RawMsg
                    Erase modeargs
                Else
                    'It's a user.
                    prfx = ""
                    While InStr("*~@%+", Left(stmp, 1)) > 0
                        prfx = prfx & Choose(InStr("*~@%+", Left(stmp, 1)), "q", "a", "o", "h", "v")
                        stmp = Mid(stmp, 2)
                    Wend
                    ReDim joinargs(0 To 1)
                    joinargs(0) = stmp
                    joinargs(1) = channame
                    CmdJoin Source, joinargs, RawMsg
                    Erase joinargs
                    ReDim modeargs(0 To Len(prfx) + 1)
                    modeargs(0) = Source
                    modeargs(1) = "+" & prfx
                    For idx = 2 To Len(prfx) + 1
                        modeargs(idx) = stmp
                    Next idx
                End If
            Next stmp
        ElseIf chptr.ts > ts Then
            'Replace existing info.
            ReDim modeargs(0 To 2)
            modeargs(0) = Source
            modeargs(1) = channame
            modeargs(2) = "-" & chptr.modes
            CmdMode Source, modeargs, RawMsg
            If chptr.ChannelKey <> "" Then
                modeargs(2) = "-k"
                CmdMode Source, modeargs, RawMsg
            End If
            If chptr.OverflowChannel <> "" Then
                modeargs(2) = "-L"
                CmdMode Source, modeargs, RawMsg
            End If
            If chptr.OverflowLimit > 0 Then
                modeargs(2) = "-l"
                CmdMode Source, modeargs, RawMsg
            End If
            If chptr.FloodProtection <> "" Then
                modeargs(2) = "-f"
                CmdMode Source, modeargs, RawMsg
            End If
            Dim mem As ChannelMember
            For Each mem In chptr.Members
                modeargs(2) = "-" & mem.modes
                ReDim Preserve modeargs(0 To Len(mem.modes) + 2)
                For idx = 3 To UBound(modeargs)
                    modeargs(idx) = mem.Member
                Next idx
                CmdMode Source, modeargs, RawMsg
            Next mem
            v = Split(modes, " ")
            ReDim modeargs(UBound(v) + 2)
            modeargs(0) = Source
            modeargs(1) = channame
            For idx = 2 To UBound(modeargs)
                modeargs(idx) = v(idx - 2)
            Next idx
            CmdMode Source, modeargs, RawMsg
            For Each stmp In u
                'Does stmp start with an & or "?
                If Left(stmp, 1) = "&" Then
                    'It's a ban...
                    ReDim modeargs(0 To 4)
                    modeargs(0) = Source
                    modeargs(1) = channame
                    modeargs(2) = "+b"
                    modeargs(3) = Mid(stmp, 2)
                    modeargs(4) = ts
                    CmdMode Source, modeargs, RawMsg
                    Erase modeargs
                ElseIf Left(stmp, 1) = """" Then
                    'It's an except.
                    ReDim modeargs(0 To 4)
                    modeargs(0) = Source
                    modeargs(1) = channame
                    modeargs(2) = "+e"
                    modeargs(3) = Mid(stmp, 2)
                    modeargs(4) = ts
                    CmdMode Source, modeargs, RawMsg
                    Erase modeargs
                Else
                    'It's a user.
                    prfx = ""
                    While InStr("*~@%+", Left(stmp, 1)) > 0
                        prfx = prfx & Choose(InStr("*~@%+", Left(stmp, 1)), "q", "a", "o", "h", "v")
                        stmp = Mid(stmp, 2)
                    Wend
                    ReDim joinargs(0 To 1)
                    joinargs(0) = stmp
                    joinargs(1) = channame
                    CmdJoin Source, joinargs, RawMsg
                    Erase joinargs
                    ReDim modeargs(0 To Len(prfx) + 1)
                    modeargs(0) = Source
                    modeargs(1) = "+" & prfx
                    For idx = 2 To Len(prfx) + 1
                        modeargs(idx) = stmp
                    Next idx
                End If
            Next stmp
        End If
    Else
        Set chptr = New channel
        chptr.Name = channame
        Channels.Add chptr
        v = Split(modes, " ")
        ReDim modeargs(UBound(v) + 2)
        modeargs(0) = Source
        modeargs(1) = channame
        For idx = 2 To UBound(modeargs)
            modeargs(idx) = v(idx - 2)
        Next idx
        CmdMode Source, modeargs, RawMsg
        For Each stmp In u
            'Does stmp start with an & or "?
            If Left(stmp, 1) = "&" Then
                'It's a ban...
                ReDim modeargs(0 To 4)
                modeargs(0) = Source
                modeargs(1) = channame
                modeargs(2) = "+b"
                modeargs(3) = Mid(stmp, 2)
                modeargs(4) = ts
                CmdMode Source, modeargs, RawMsg
                Erase modeargs
            ElseIf Left(stmp, 1) = """" Then
                'It's an except.
                ReDim modeargs(0 To 4)
                modeargs(0) = Source
                modeargs(1) = channame
                modeargs(2) = "+e"
                modeargs(3) = Mid(stmp, 2)
                modeargs(4) = ts
                CmdMode Source, modeargs, RawMsg
                Erase modeargs
            Else
                'It's a user.
                prfx = ""
                While InStr("*~@%+", Left(stmp, 1)) > 0
                    prfx = prfx & Choose(InStr("*~@%+", Left(stmp, 1)), "q", "a", "o", "h", "v")
                    stmp = Mid(stmp, 2)
                Wend
                ReDim joinargs(0 To 1)
                joinargs(0) = stmp
                joinargs(1) = channame
                CmdJoin Source, joinargs, RawMsg
                Erase joinargs
                ReDim modeargs(0 To Len(prfx) + 1)
                modeargs(0) = Source
                modeargs(1) = "+" & prfx
                For idx = 2 To Len(prfx) + 1
                    modeargs(idx) = stmp
                Next idx
            End If
        Next stmp
    End If
End Sub

Private Sub CmdSilence(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
'IGNORE.
End Sub

Private Sub CmdSetName(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    Dim u As User
    If UBound(Args) < 1 Then Exit Sub
    If Users.Exists(Source) Then
        Set u = Users(Source)
        u.RealName = Args(1)
    End If
End Sub

Private Sub CmdSETIDENT(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    Dim u As User
    If UBound(Args) < 1 Then Exit Sub
    If Users.Exists(Source) Then
        Set u = Users(Source)
        u.UserName = Args(1)
    End If
End Sub

Private Sub CmdSetHost(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
    Dim u As User
    If UBound(Args) < 1 Then Exit Sub
    If Users.Exists(Source) Then
        Set u = Users(Source)
        u.VirtHost = Args(1)
        'Also set +xt.
        Dim umodeargs(0 To 2) As String
        umodeargs(0) = Source
        umodeargs(1) = Source
        umodeargs(2) = "+xt"
        CmdMode Source, umodeargs, RawMsg
    End If
End Sub

Private Sub CmdServer(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdSENDUMODE(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdSMo(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdSENDSNO(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdSDESC(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdSAPART(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdSAMODE(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdSAJOIN(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdRULES(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdRPING(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdRPONG(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdRAKILL(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdQuit(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdProtoctl(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdPing(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdPong(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdPass(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdOPER(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdNetinfo(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdNACHAT(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdMKPASSWD(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdPrivMsg(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdNotice(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdNick(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdMAP(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdLOCOPS(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdLIST(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdLINKS(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdLAG(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdKNOCK(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdKill(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdKICK(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdISON(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdINVITE(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdHTM(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdHELP(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdGLOBOPS(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdEOS(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdDCCDENY(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdCYCLE(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdCONNECT(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdCLOSE(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdCHGNAME(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdCHGIDENT(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdCHATOPS(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdCHGHOST(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdUSER(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdVersion(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdINFO(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdSUMMON(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdUSERS(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdError(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdNAMES(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdJoin(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdPart(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdLUSERS(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdMotd(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdMode(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdSERVICE(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdRehash(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdRESTART(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdDIE(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdHASH(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdDNS(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdKLINE(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdGNOTICE(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdGOPER(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdWATCH(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdZLINE(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdDALINFO(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdCREDITS(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdLICENSE(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdOPERMOTD(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdTKL(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)
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
End Sub

Private Sub CmdBOTMOTD(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdREMGLINE(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdSVSNAME(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdNEWJOIN(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdPOST(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub

Private Sub CmdMODULE(ByVal Source As String, ByRef Args() As String, ByVal RawMsg As String)

End Sub
