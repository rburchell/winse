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
'TKL - <type> <user> <host> <source>
'Don't use :<source> for these.

Private Function IIRCd_AddPermNetworkIPBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String) As Boolean
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    'Add the thing.
    SendData FormatString("{0} + Z * {1} {2} 0 {3} :{4}", IIf(EnableToken, TOK_TKL, "TKL"), Mask, Source, ts, Reason)
    IIRCd_AddPermNetworkIPBan = True
End Function

Private Function IIRCd_AddPermNetworkNickBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String) As Boolean
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    'Add the thing.
    SendData FormatString("{0} + Q * {1} {2} 0 {3} :{4}", IIf(EnableToken, TOK_TKL, "TKL"), Mask, Source, ts, Reason)
    IIRCd_AddPermNetworkNickBan = True
End Function

Private Function IIRCd_AddPermNetworkRealnameBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String) As Boolean
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    'Add the thing.
    SendData FormatString("SVSNLINE + {0} :{1}", Replace(Reason, " ", "_"), Mask)
    IIRCd_AddPermNetworkRealnameBan = True
End Function

Private Function IIRCd_AddPermNetworkUserhostBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String) As Boolean
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    'Add the thing.
    SendData FormatString("{0} + G {1} {2} {3} 0 {4} :{5}", IIf(EnableToken, TOK_TKL, "TKL"), Split(Mask, "@", 2)(0), Split(Mask, "@", 2)(1), Source, ts, Reason)
    IIRCd_AddPermNetworkUserhostBan = True
End Function

Private Function IIRCd_AddTempNetworkIPBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String) As Boolean
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    'Add the thing.
    SendData FormatString("{0} + Z * {1} {2} {3} {4} :{5}", IIf(EnableToken, TOK_TKL, "TKL"), Mask, Source, ts + Expiry, ts, Reason)
    IIRCd_AddTempNetworkIPBan = True
End Function

Private Function IIRCd_AddTempNetworkNickBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String) As Boolean
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    'Add the thing.
    SendData FormatString("{0} + Q * {1} {2} {3} {4} :{5}", IIf(EnableToken, TOK_TKL, "TKL"), Mask, Source, ts + Expiry, ts, Reason)
    IIRCd_AddTempNetworkNickBan = True
End Function

Private Function IIRCd_AddTempNetworkRealnameBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String) As Boolean
    IIRCd_AddTempNetworkRealnameBan = False
End Function

Private Function IIRCd_AddTempNetworkUserhostBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String) As Boolean
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    'Add the thing.
    SendData FormatString("{0} + G {1} {2} {3} {4} {5} :{6}", IIf(EnableToken, TOK_TKL, "TKL"), Split(Mask, "@", 2)(0), Split(Mask, "@", 2)(1), Source, ts + Expiry, ts, Reason)
    IIRCd_AddTempNetworkUserhostBan = True
End Function

Private Property Get IIRCd_BanChar() As String
    IIRCd_BanChar = "b"
End Property

Private Sub IIRCd_BurstChannel(ByVal Source As String, ByVal Channel As String, ByVal ts As Long, ByVal Modes As String, ByVal ModeParams As String, Users() As String, WantModes() As String, ByRef Bans() As String, ByRef Exempts() As String, ByRef Invites() As String)
    'I JUST LOVE SJOIN >_<
    'SJOIN Format:
    ':server.name SJOIN ts channel modes [modeparam] :[[[*][~][@][%][+]member]] [[[&ban]["exempt]]]
    'If for some dumb reason we have a lot of members/bans/exempts to sjoin and/or a really long key/whatever
    'we may need to break up the SJOIN.
    Dim sjoinstr As String
    sjoinstr = FormatString("{0} {1} !{2} {3} {4} {5} :", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SJOIN, "SJOIN"), IntToB64(ts), Channel, Modes, ModeParams)
    Dim uidx As Long, bidx As Long, eidx As Long, iidx As Long, sTmp As String
    uidx = 0: bidx = 0: eidx = 0: iidx = 0
    Do Until uidx > UBound(Users) And bidx > UBound(Bans) And eidx > UBound(Exempts)
        sTmp = ""
        If uidx <= UBound(Users) Then
            If InStr(WantModes(uidx), "q") Then sTmp = sTmp + "*"
            If InStr(WantModes(uidx), "a") Then sTmp = sTmp + "~"
            If InStr(WantModes(uidx), "o") Then sTmp = sTmp + "@"
            If InStr(WantModes(uidx), "h") Then sTmp = sTmp + "%"
            If InStr(WantModes(uidx), "v") Then sTmp = sTmp + "+"
            sTmp = sTmp + Users(uidx)
            uidx = uidx + 1
        ElseIf bidx <= UBound(Bans) Then
            sTmp = "&" + Bans(bidx)
            bidx = bidx + 1
        ElseIf eidx <= UBound(Exempts) Then
            sTmp = """" + Exempts(eidx)
            eidx = eidx + 1
        End If
        If Len(sjoinstr + sTmp) > 510 Then
            SendData RTrim(sjoinstr)
            sjoinstr = FormatString("{0} {1} !{2} {3} + <none> :{4} ", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SJOIN, "SJOIN"), IntToB64(ts), Channel, sTmp)
        Else
            sjoinstr = sjoinstr & sTmp & " "
        End If
    Loop
End Sub

Private Function IIRCd_ChangeAccount(ByVal Source As String, ByVal Target As String, ByVal account As String) As Boolean
    'Change the account name.
    'First make sure the user is +r'd.
    SendData FormatString("{0} {1} {2} +r", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SVS2MODE, "SVS2MODE"), Target)
    SendData FormatString("{0} {1} {2} :is logged in as {3}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SWHOIS, "SWHOIS"), Target, account)
    IIRCd_ChangeAccount = True
End Function

Private Property Get IIRCd_ChanModes() As String
    IIRCd_ChanModes = "be,fkL,l,psmntirRcOAQKVGCuzNSMT"
End Property

Private Sub IIRCd_ChannelMode(ByVal Source As String, ByVal Channel As String, ByVal Modes As String)
    SendData FormatString("{0} {1} {2} {3}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_MODE, "MODE"), Channel, Modes)
End Sub

Private Sub IIRCd_ChannelTopic(ByVal Source As String, ByVal Channel As String, ByVal Topic As String, ByVal SetBy As String, ByVal SetOn As Long)
    SendData FormatString("{0} {1} {2} {3} {4} :{5}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_TOPIC, "TOPIC"), Channel, SetBy, SetOn, Topic)
End Sub

Private Property Get IIRCd_ChanOpChar() As String
    IIRCd_ChanOpChar = "o"
End Property

Private Sub IIRCd_CreateChannel(ByVal Source As String, ByVal Channel As String)
    Dim ts As Long
    ts = basUnixTime.GetTime()
    SendData FormatString("@{0} {1} !{2} {3} + <none> :@{4}", IntToB64(basMain.Config.ServerNumeric), IIf(EnableToken, TOK_SJOIN, "SJOIN"), IntToB64(ts), Channel, Source)
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

Private Function IIRCd_DeleteNetworkIPBan(ByVal Source As String, ByVal Mask As String) As Boolean
    SendData FormatString("{0} - Z * {1} {2}", IIf(EnableToken, TOK_TKL, "TKL"), Mask, Source)
    IIRCd_DeleteNetworkIPBan = True
End Function

Private Function IIRCd_DeleteNetworkNickBan(ByVal Source As String, ByVal Mask As String) As Boolean
    SendData FormatString("{0} - Q * {1} {2}", IIf(EnableToken, TOK_TKL, "TKL"), Mask, Source)
    IIRCd_DeleteNetworkNickBan = True
End Function

Private Function IIRCd_DeleteNetworkRealnameBan(ByVal Source As String, ByVal Mask As String) As Boolean
    SendData FormatString("SVSNLINE - :{0}", Mask)
    IIRCd_DeleteNetworkRealnameBan = True
End Function

Private Function IIRCd_DeleteNetworkUserhostBan(ByVal Source As String, ByVal Mask As String) As Boolean
    SendData FormatString("{0} - G {1} {2} {3}", IIf(EnableToken, TOK_TKL, "TKL"), Split(Mask, "@", 2)(0), Split(Mask, "@", 2)(1), Source)
    IIRCd_DeleteNetworkUserhostBan = True
End Function

Private Property Get IIRCd_ExemptChar() As String
    IIRCd_ExemptChar = "e"
End Property

Private Function IIRCd_ForceNickChange(ByVal Source As String, ByVal Target As String, ByVal NewNick As String) As Boolean
    Dim ts As Long
    'Get a TS.
    ts = basUnixTime.GetTime()
    SendData FormatString("{0} {1} {2} {3} {4}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SVSNICK, "SVSNICK"), Target, NewNick, ts)
    IIRCd_ForceNickChange = True
End Function

Private Property Get IIRCd_HalfopChar() As String
    IIRCd_HalfopChar = "h"
End Property

Private Sub IIRCd_HoldChannel(ByVal Source As String, ByVal Channel As String)
    'Since we can assume the channel is empty...
    Dim ts As Long
    ts = basUnixTime.GetTime()
    SendData FormatString("@{0} {1} !{2} {3} +imsOKVl 1 :*@{4}", IntToB64(basMain.Config.ServerNumeric), IIf(EnableToken, TOK_SJOIN, "SJOIN"), IntToB64(ts), Channel, Source)
End Sub

Private Function IIRCd_HoldNick(ByVal Source As String, ByVal Nick As String) As Boolean
    Dim ts As Long
    ts = basUnixTime.GetTime()
    SendData FormatString("{0} + Q H {1} {2} 0 {3} :{4}", IIf(EnableToken, TOK_TKL, "TKL"), Nick, Source, ts, "Held by services")
    IIRCd_HoldNick = True
End Function

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

Private Sub IIRCd_JoinChannel(ByVal Source As String, ByVal Channel As String)
    SendData FormatString(":{0} {1} {2}", Source, IIf(EnableToken, TOK_JOIN, "JOIN"), Channel)
End Sub

Private Sub IIRCd_KickUser(ByVal Source As String, ByVal Channel As String, ByVal Victim As String, ByVal Reason As String)
    SendData FormatString("{0} {1} {2} {3} :{4}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_KICK, "KICK"), Channel, Victim, Reason)
End Sub

Private Function IIRCd_KillUser(ByVal Source As String, ByVal SVSKillOK As Boolean, ByVal User As String, ByVal Reason As String) As KillSupport
    If SVSKillOK Then
        SendData FormatString("{0} {1} {2} :{3}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SVSKILL, "SVSKILL"), User, Reason)
        IIRCd_KillUser = KILL_SUPPORTED
    Else
        SendData FormatString("{0} {1} {2} :{0} ({3})", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_KILL, "KILL"), User, Reason)
        IIRCd_KillUser = KILL_SUPPORTED
    End If
End Function

Private Property Get IIRCd_OwnerChar() As String
    IIRCd_OwnerChar = "q"
End Property

Private Sub IIRCd_ParseCmd(ByVal Buffer As String)
'
End Sub

Private Sub IIRCd_PartChannel(ByVal Source As String, ByVal Channel As String, ByVal Reason As String)
    SendData FormatString("{0} {1} {2} :{3}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_PART, "PART"), Channel, Reason)
End Sub

Private Property Get IIRCd_ProtectChar() As String
    IIRCd_ProtectChar = "a"
End Property

Private Sub IIRCd_ReleaseChannel(ByVal Source As String, ByVal Channel As String)
    SendData FormatString(":{0} MODE {1} -imsOKVl", Source, Channel)
    SendData FormatString(":{0} PART {1}", Source, Channel)
End Sub

Private Function IIRCd_ReleaseNick(ByVal Source As String, ByVal Nick As String) As Boolean
    SendData FormatString("{0} - Q H {1} {2}", IIf(EnableToken, TOK_TKL, "TKL"), Nick, Source)
    IIRCd_ReleaseNick = True
End Function

Private Sub IIRCd_RemoveClient(ByVal Nick As String, ByVal Reason As String)
    SendData FormatString(":{0} {1} :{2}", Nick, IIf(EnableToken, TOK_QUIT, "QUIT"), Reason)
End Sub

Private Sub IIRCd_RemoveServer(ByVal Sender As String, ByVal Server As String, ByVal Reason As String)
    SendData FormatString("{0} {1} {2} :{3}", GetNSSourcePrefix(Sender), IIf(EnableToken, TOK_SQUIT, "SQUIT"), Server, Reason)
End Sub

Private Sub IIRCd_SendNumeric(ByVal Target As String, ByVal Numeric As Integer, ByVal Text As String)
    SendData FormatString("@{0} {1:000} {2} {3}", IntToB64(basMain.Config.ServerNumeric), Format(Numeric, "000"), Target, Text)
End Sub

Private Sub IIRCd_SendPrivMsg(ByVal Source As String, ByVal Target As String, ByVal Notice As Boolean, ByVal Text As String)
    SendData FormatString("{0} {1} {2} :{3}", GetNSSourcePrefix(Source), IIf(Notice, IIf(EnableToken, TOK_NOTICE, "NOTICE"), IIf(EnableToken, TOK_PRIVMSG, "PRIVMSG")), Target, Text)
End Sub

Private Sub IIRCd_SendToUMode(ByVal Source As String, ByVal UMode As String, ByVal Message As String)
    SendData FormatString("@{0} SMO {1} :{2}", IntToB64(basMain.Config.ServerNumeric), UMode, Message)
End Sub

Private Function IIRCd_SetAccount(ByVal Source As String, ByVal Target As String, ByVal account As String) As Boolean
    SendData FormatString("{0} {1} {2} +r", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SVS2MODE, "SVS2MODE"), Target)
    SendData FormatString("{0} {1} {2} :is logged in as {3}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SWHOIS, "SWHOIS"), Target, account)
    IIRCd_SetAccount = True
End Function

Private Function IIRCd_SetServerNoOpers(ByVal Source As String, ByVal Server As String) As Boolean
    SendData FormatString("{0} SVSNOOP {1} +", GetNSSourcePrefix(Source), Server)
    IIRCd_SetServerNoOpers = True
End Function

Private Function IIRCd_SetUserModes(ByVal Source As String, ByVal Nick As String, ByVal Modes As String) As Boolean
    SendData FormatString("{0} {1} {2} {3}", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SVS2MODE, "SVS2MODE"), Nick, Modes)
    IIRCd_SetUserModes = True
End Function

Private Function IIRCd_SetVHost(ByVal Source As String, ByVal Nick As String, ByVal VHost As String) As Boolean
    If VHost <> "" Then
        SendData FormatString("{0} CHGHOST {1} {2}", GetNSSourcePrefix(Source), Nick, VHost)
    Else
        SendData FormatString("{0} {1} {2} -x", GetNSSourcePrefix(Source), IIf(EnableToken, TOK_SVS2MODE, "SVS2MODE"), Nick)
    End If
    IIRCd_SetVHost = True
End Function

Private Function IIRCd_SetVIdent(ByVal Source As String, ByVal Nick As String, ByVal VIdent As String) As Boolean
    If VIdent <> "" Then
        SendData FormatString("{0} CHGIDENT {1} {2}", GetNSSourcePrefix(Source), Nick, VIdent)
        IIRCd_SetVIdent = True
    End If
End Function

Private Function IIRCd_UnsetServerNoOpers(ByVal Source As String, ByVal Server As String) As Boolean
    SendData FormatString("{0} SVSNOOP {1} -", GetNSSourcePrefix(Source), Server)
    IIRCd_UnsetServerNoOpers = True
End Function

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
Public Function IntToB64(ByVal val As Long) As String
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

Public Function B64ToInt(ByVal b64 As String) As Long
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
