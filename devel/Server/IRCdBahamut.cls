VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "IRCdBahamut"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'Protocol module for Bahamut 1.8

'Warning to other WinSE coders: the commands contained herein may look very strange from an UnrealIRCd
'stand point. Some of Bahamut's server-server protocol is very weird and strange compared to Unreal.
'I will attempt to document these differences where possible.

'WinSE will only support 1.8 versions of bahamut. Always use the latest version of the IRCd!

Implements IIRCd

Private Function IIRCd_AddPermNetworkIPBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String) As Boolean
    IIRCd_AddPermNetworkIPBan = False
End Function

Private Function IIRCd_AddPermNetworkNickBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String) As Boolean
    SendData FormatString(":{0} SQLINE {1} :{2}", Source, Mask, Reason)
    IIRCd_AddPermNetworkNickBan = True
End Function

Private Function IIRCd_AddPermNetworkRealnameBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String) As Boolean
    SendData FormatString(":{0} SGLINE {1} :{2}", Source, Mask, Reason)
    IIRCd_AddPermNetworkRealnameBan = True
End Function

Private Function IIRCd_AddPermNetworkUserhostBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String) As Boolean
    'Bahamut's weird AKILL syntax:
    'AKILL host user expiry source ts :reason
    Dim ts As Long
    ts = basUnixTime.GetTime
    SendData FormatString("AKILL {1} {2} 0 {3} {4} :{5}", Source, Split(Mask, "@")(1), Split(Mask, "@")(0), Source, ts, Reason)
    IIRCd_AddPermNetworkUserhostBan = True
End Function

Private Function IIRCd_AddTempNetworkIPBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String) As Boolean
    IIRCd_AddTempNetworkIPBan = False
End Function

Private Function IIRCd_AddTempNetworkNickBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String) As Boolean
    IIRCd_AddTempNetworkNickBan = False
End Function

Private Function IIRCd_AddTempNetworkRealnameBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String) As Boolean
    IIRCd_AddTempNetworkRealnameBan = False
End Function

Private Function IIRCd_AddTempNetworkUserhostBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String) As Boolean
    Dim ts As Long
    ts = basUnixTime.GetTime
    SendData FormatString("AKILL {1} {2} {3} {4} {5} :{6}", Source, Split(Mask, "@")(1), Split(Mask, "@")(0), Expiry, Source, ts, Reason)
    IIRCd_AddTempNetworkUserhostBan = True
End Function

Private Property Get IIRCd_BanChar() As String
    IIRCd_BanChar = "b"
End Property

Private Sub IIRCd_BurstChannel(ByVal Source As String, ByVal Channel As String, ByVal ts As Long, ByVal Modes As String, ByVal ModeParams As String, Users() As String, WantModes() As String, Bans() As String, Exempts() As String, Invites() As String)
    '
End Sub

Private Function IIRCd_ChangeAccount(ByVal Source As String, ByVal Target As String, ByVal account As String) As Boolean
    SendData FormatString(":{0} SVSMODE {1} +r", Source, Target)
    IIRCd_ChangeAccount = True
End Function

Private Property Get IIRCd_ChanModes() As String
    IIRCd_ChanModes = "beI,k,jl,cimMnOprRst"
End Property

Private Sub IIRCd_ChannelMode(ByVal Source As String, ByVal Channel As String, ByVal Modes As String)
    SendData FormatString(":{0} MODE {1} {2}", Source, Channel, Modes)
End Sub

Private Sub IIRCd_ChannelTopic(ByVal Source As String, ByVal Channel As String, ByVal Topic As String, ByVal SetBy As String, ByVal SetOn As Long)
    SendData FormatString(":{0} TOPIC {1] :{2}", Source, Channel, Topic)
End Sub

Private Property Get IIRCd_ChanOpChar() As String
    IIRCd_ChanOpChar = "o"
End Property

Private Sub IIRCd_CreateChannel(ByVal Source As String, ByVal Channel As String)
    Dim ts As Long
    ts = basUnixTime.GetTime
    SendData FormatString(":{0} JOIN {1}", Source, Channel)
    SendData FormatString(":{0} MODE {1} +o {2} {3}", basMain.Config.ServerName, Channel, Source, ts)
End Sub

Private Function IIRCd_CreateCID() As String
    IIRCd_CreateCID = vbNullString
End Function

Private Function IIRCd_CreateSID() As String
    IIRCd_CreateSID = vbNullString
End Function

Private Function IIRCd_DeleteNetworkIPBan(ByVal Source As String, ByVal Mask As String) As Boolean
    IIRCd_DeleteNetworkIPBan = False
End Function

Private Function IIRCd_DeleteNetworkNickBan(ByVal Source As String, ByVal Mask As String) As Boolean
    SendData FormatString(":{0} UNSQLINE 0 {1}", Source, Mask)
    IIRCd_DeleteNetworkNickBan = True
End Function

Private Function IIRCd_DeleteNetworkRealnameBan(ByVal Source As String, ByVal Mask As String) As Boolean
    SendData FormatString(":{0} UNSGLINE 0 {1}", Source, Mask)
    IIRCd_DeleteNetworkRealnameBan = True
End Function

Private Function IIRCd_DeleteNetworkUserhostBan(ByVal Source As String, ByVal Mask As String) As Boolean
    SendData FormatString(":{0} RAKILL {1} {2}", Source, Split(Mask, "@")(1), Split(Mask, "@")(0))
End Function

Private Property Get IIRCd_ExemptChar() As String
    IIRCd_ExemptChar = "e"
End Property

Private Function IIRCd_ForceNickChange(ByVal Source As String, ByVal Target As String, ByVal NewNick As String) As Boolean
    Dim ts As Long
    ts = basUnixTime.GetTime
    SendData FormatString(":{0} SVSNICK {1} {2} :{3}", Source, Target, NewNick, ts)
End Function

Private Property Get IIRCd_HalfopChar() As String
    IIRCd_HalfopChar = vbNullString
End Property

Private Sub IIRCd_HoldChannel(ByVal Source As String, ByVal Channel As String)
    SendData FormatString(":{0} SQLINE {1} :Held by services", Source, Channel)
End Sub

Private Function IIRCd_HoldNick(ByVal Source As String, ByVal Nick As String) As Boolean
    SendData FormatString(":{0} SVSHOLD {1} 60 :Held by services", Source, Nick)
End Function

Private Sub IIRCd_IntroduceClient(ByVal Nick As String, ByVal UserName As String, ByVal HostName As String, ByVal RealName As Variant, ByVal VHost As String, ByVal UserModes As String, ByVal CID As String, ByVal Server As String)
    'Format is:
    ':server NICK nick ts umodes user host server 0 0 :realname
    SendData FormatString(":{0} NICK {1} {2} {3} {4} {5} {0} 0 0 :{6}", Server, Nick, basUnixTime.GetTime, UserModes, UserName, IIf(VHost <> "", VHost, HostName), RealName)
End Sub

Private Sub IIRCd_IntroduceSelf()
    'This is rather silly, yes. What's so wrong with CAPAB TS or something like that? :/
    SendData FormatString("PASS {0} :TS", basMain.Config.UplinkPassword)
    SendData FormatString("CAPAB NICKIP SSJOIN TS3 NOQUIT TSMODE UNCONNECT")
    SendData FormatString("SERVER {0} 1 :{1}", basMain.Config.ServerName, basMain.Config.ServerDescription)
    'TS Version 3, Minimum Version 1
    SendData FormatString("SVINFO 3 1 0 :{0}", basUnixTime.GetTime())
End Sub

Private Sub IIRCd_IntroduceServer(ByVal ServerName As String, ByVal Hops As Long, ByVal SID As String, ByVal Description As String, ByVal BehindServer As String)
    SendData FormatString(":{0} SERVER {1} {2} :{3}", BehindServer, ServerName, Hops, Description)
End Sub

Private Property Get IIRCd_InvExChar() As String
    IIRCd_InvExChar = "I"
End Property

Private Sub IIRCd_JoinChannel(ByVal Source As String, ByVal Channel As String)
    SendData FormatString(":{0} JOIN {1}", Source, Channel)
End Sub

Private Sub IIRCd_KickUser(ByVal Source As String, ByVal Channel As String, ByVal Victim As String, ByVal Reason As String)
    SendData FormatString(":{0} KICK {1} {2} :{3}", Source, Channel, Victim, Reason)
End Sub

Private Function IIRCd_KillUser(ByVal Source As String, ByVal SVSKillOK As Boolean, ByVal User As String, ByVal Reason As String) As KillSupport
    If SVSKillOK Then
        SendData FormatString(":{0} SVSKILL {1} :{2}", Source, User, Reason)
        IIRCd_KillUser = KILL_NODISPOSE
    Else
        SendData FormatString(":{0} KILL {1} :{0} ({2})", Source, User, Reason)
        IIRCd_KillUser = KILL_SUPPORTED
    End If
End Function

Private Property Get IIRCd_OwnerChar() As String
    IIRCd_OwnerChar = vbNullString
End Property

Private Sub IIRCd_ParseCmd(ByVal Buffer As String)

End Sub

Private Sub IIRCd_PartChannel(ByVal Source As String, ByVal Channel As String, ByVal Reason As String)
    If Reason <> "" Then
        SendData FormatString(":{0} PART {1} :{2}", Source, Channel, Reason)
    Else
        SendData FormatString(":{0} PART {1}", Source, Channel)
    End If
End Sub

Private Property Get IIRCd_ProtectChar() As String
    IIRCd_ProtectChar = vbNullString
End Property

Private Sub IIRCd_ReleaseChannel(ByVal Source As String, ByVal Channel As String)
    SendData FormatString(":{0} UNSQLINE 0 {1}", Source, Channel)
End Sub

Private Function IIRCd_ReleaseNick(ByVal Source As String, ByVal Nick As String) As Boolean
    SendData FormatString(":{0} SVSHOLD {1} 0", Source, Nick)
    IIRCd_ReleaseNick = True
End Function

Private Sub IIRCd_RemoveClient(ByVal Nick As String, ByVal Reason As String)
    SendData FormatString(":{0} QUIT :{1}", Nick, Reason)
End Sub

Private Sub IIRCd_RemoveServer(ByVal Sender As String, ByVal Server As String, ByVal Reason As String)
    SendData FormatString(":{0} SQUIT {1} :{2}", Sender, Server, Reason)
End Sub

Private Sub IIRCd_SendNumeric(ByVal Target As String, ByVal Numeric As Integer, ByVal Text As String)
    SendData FormatString(":{0} {1:000} {2} {3}", basMain.Config.ServerName, Numeric, Target, Text)
End Sub

Private Sub IIRCd_SendPrivMsg(ByVal Source As String, ByVal Target As String, ByVal Notice As Boolean, ByVal Text As String)
    SendData FormatString(":{0} {1} {2} :{3}", Source, IIf(Notice, "PRIVMSG", "NOTICE"), Target, Text)
End Sub

Private Sub IIRCd_SendToUMode(ByVal Source As String, ByVal UMode As String, ByVal Message As String)
    Dim u As User
    For Each u In Users
        If InStr(u, UMode) > 0 Then
            SendData FormatString(":{0} NOTICE {1} :{2}", Source, u.Nick, Message)
        End If
    Next u
End Sub

Private Function IIRCd_SetAccount(ByVal Source As String, ByVal Target As String, ByVal account As String) As Boolean
    SendData FormatString(":{0} SVSMODE {1} +r", Source, Target)
    IIRCd_SetAccount = True
End Function

Private Function IIRCd_SetServerNoOpers(ByVal Source As String, ByVal Server As String) As Boolean
'
End Function

Private Function IIRCd_SetUserModes(ByVal Source As String, ByVal Nick As String, ByVal Modes As String) As Boolean
    SendData FormatString(":{0} SVSMODE {1} {2}", Source, Nick, Modes)
    IIRCd_SetUserModes = True
End Function

Private Function IIRCd_SetVHost(ByVal Source As String, ByVal Nick As String, ByVal VHost As String) As Boolean
'
End Function

Private Function IIRCd_SetVIdent(ByVal Source As String, ByVal Nick As String, ByVal VIdent As String) As Boolean
'
End Function

Private Function IIRCd_UnsetServerNoOpers(ByVal Source As String, ByVal Server As String) As Boolean
'
End Function

Private Property Get IIRCd_UserModes() As String
    IIRCd_UserModes = "aAbcdefFghiIjkKmnoOrRswxXy"
End Property

Private Property Get IIRCd_VoiceChar() As String
    IIRCd_VoiceChar = "v"
End Property

Private Sub IIRCd_Wallopers(ByVal Source As String, ByVal Message As String)
    SendData FormatString(":{0} GLOBOPS :{1}", Source, Message)
End Sub
