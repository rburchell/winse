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

'Uberstrict TS things for bahamut (like Client SJOINs).
#Const TS_STRICT = True
Const TS_STRICT As Boolean = True

Implements IIRCd

Private Sub IIRCd_AddPermNetworkIPBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String)
    Err.Raise E_NOTIMPL
End Sub

Private Sub IIRCd_AddPermNetworkNickBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String)
    SendData FormatString(":{0} SQLINE {1} :{2}", Source, Mask, Reason)
End Sub

Private Sub IIRCd_AddPermNetworkRealnameBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String)
    SendData FormatString(":{0} SGLINE {1} :{2}", Source, Mask, Reason)
End Sub

Private Sub IIRCd_AddPermNetworkUserhostBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String)
    'Bahamut's weird AKILL syntax:
    'AKILL host user expiry source ts :reason
    Dim ts As Long
    ts = basUnixTime.GetTime
    SendData FormatString("AKILL {1} {2} 0 {3} {4} :{5}", Source, Split(Mask, "@")(1), Split(Mask, "@")(0), Source, ts, Reason)
End Sub

Private Sub IIRCd_AddTempNetworkIPBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String)
    Err.Raise E_NOTIMPL
End Sub

Private Sub IIRCd_AddTempNetworkNickBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String)
    Err.Raise E_NOTIMPL
End Sub

Private Sub IIRCd_AddTempNetworkRealnameBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String)
    Err.Raise E_NOTIMPL
End Sub

Private Sub IIRCd_AddTempNetworkUserhostBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String)
    Dim ts As Long
    ts = basUnixTime.GetTime
    SendData FormatString("AKILL {1} {2} {3} {4} {5} :{6}", Source, Split(Mask, "@")(1), Split(Mask, "@")(0), Expiry, Source, ts, Reason)
End Sub

Private Property Get IIRCd_BanChar() As String
    IIRCd_BanChar = "b"
End Property

Private Sub IIRCd_BurstChannel(ByVal Source As String, ByVal Channel As String, ByVal ts As Long, ByVal Modes As String, ByVal ModeParams As String, Users() As String, WantModes() As String, Bans() As String, Exempts() As String, Invites() As String)
    'Bahamut has SJOIN :D
    'SJOIN Format:
    ':server.name SJOIN ts channel modes [modeparam] :[[[@][+]member]]
    'If for some dumb reason we have a lot of members to sjoin and/or a really long key/whatever
    'we may need to break up the SJOIN.
    Dim sjoinstr As String
    sjoinstr = FormatString(":{0} SJOIN {1} {2} {3} {4} :", Source, ts, Channel, Modes, ModeParams)
    Dim uidx As Long, bidx As Long, eidx As Long, iidx As Long, sTmp As String
    uidx = 0: bidx = 0: eidx = 0: iidx = 0
    For uidx = 0 To UBound(Users)
        sTmp = ""
        If InStr(WantModes(uidx), "o") Then sTmp = sTmp + "@"
        If InStr(WantModes(uidx), "v") Then sTmp = sTmp + "+"
        sTmp = sTmp + Users(uidx)
        uidx = uidx + 1
        If sjoinstr = "" Then
            sjoinstr = FormatString(":{0} SJOIN {1} {2} + <none> :{3} ", Source, ts, Channel, sTmp)
        ElseIf Len(sjoinstr + sTmp) > 510 Then
            SendData RTrim(sjoinstr)
            sjoinstr = FormatString(":{0} SJOIN {1} {2} + * :{3} ", Source, ts, Channel, sTmp)
        Else
            sjoinstr = sjoinstr & sTmp & " "
        End If
    Next
    If sjoinstr <> "" Then SendData sjoinstr
    'Now send the bans, exempts, and invites.
    For bidx = 0 To UBound(Bans) Step 6
        'We can send up to 6 modes.
        Select Case UBound(Bans) - bidx
            Case Is >= 5 'Pull 6
                SendData FormatString(":{0} MODE {1} +bbbbbb {2} {3} {4} {5} {6} {7} {8}", Source, Channel, Bans(bidx), Bans(bidx + 1), Bans(bidx + 2), Bans(bidx + 3), Bans(bidx + 4), Bans(bidx + 5), ts)
            Case 4 'Pull 5
                SendData FormatString(":{0} MODE {1} +bbbbb {2} {3} {4} {5} {6} {7}", Source, Channel, Bans(bidx), Bans(bidx + 1), Bans(bidx + 2), Bans(bidx + 3), Bans(bidx + 4), ts)
            Case 3 'Pull 4
                SendData FormatString(":{0} MODE {1} +bbbb {2} {3} {4} {5} {6}", Source, Channel, Bans(bidx), Bans(bidx + 1), Bans(bidx + 2), Bans(bidx + 3), ts)
            Case 2 'Pull 3
                SendData FormatString(":{0} MODE {1} +bbb {2} {3} {4} {5}", Source, Channel, Bans(bidx), Bans(bidx + 1), Bans(bidx + 2), ts)
            Case 1 'Pull 2
                SendData FormatString(":{0} MODE {1} +bb {2} {3} {4}", Source, Channel, Bans(bidx), Bans(bidx + 1), ts)
            Case 0 'Pull 1
                SendData FormatString(":{0} MODE {1} +b {2} {3}", Source, Channel, Bans(bidx), ts)
            Case Else: Exit For
        End Select
    Next bidx
    For eidx = 0 To UBound(Exempts) Step 6
        'We can send up to 6 modes.
        Select Case UBound(Exempts) - eidx
            Case Is >= 5 'Pull 6
                SendData FormatString(":{0} MODE {1} +eeeeee {2} {3} {4} {5} {6} {7} {8}", Source, Channel, Exempts(eidx), Exempts(eidx + 1), Exempts(eidx + 2), Exempts(eidx + 3), Exempts(eidx + 4), Exempts(eidx + 5), ts)
            Case 4 'Pull 5
                SendData FormatString(":{0} MODE {1} +eeeee {2} {3} {4} {5} {6} {7}", Source, Channel, Exempts(eidx), Exempts(eidx + 1), Exempts(eidx + 2), Exempts(eidx + 3), Exempts(eidx + 4), ts)
            Case 3 'Pull 4
                SendData FormatString(":{0} MODE {1} +eeee {2} {3} {4} {5} {6}", Source, Channel, Exempts(eidx), Exempts(eidx + 1), Exempts(eidx + 2), Exempts(eidx + 3), ts)
            Case 2 'Pull 3
                SendData FormatString(":{0} MODE {1} +eee {2} {3} {4} {5}", Source, Channel, Exempts(eidx), Exempts(eidx + 1), Exempts(eidx + 2), ts)
            Case 1 'Pull 2
                SendData FormatString(":{0} MODE {1} +ee {2} {3} {4}", Source, Channel, Exempts(eidx), Exempts(eidx + 1), ts)
            Case 0 'Pull 1
                SendData FormatString(":{0} MODE {1} +e {2} {3}", Source, Channel, Exempts(eidx), ts)
            Case Else: Exit For
        End Select
    Next eidx
    For iidx = 0 To UBound(Invites) Step 6
        'We can send up to 6 modes.
        Select Case UBound(Invites) - iidx
            Case Is >= 5 'Pull 6
                SendData FormatString(":{0} MODE {1} +IIIIII {2} {3} {4} {5} {6} {7} {8}", Source, Channel, Invites(iidx), Invites(iidx + 1), Invites(iidx + 2), Invites(iidx + 3), Invites(iidx + 4), Invites(iidx + 5), ts)
            Case 4 'Pull 5
                SendData FormatString(":{0} MODE {1} +IIIII {2} {3} {4} {5} {6} {7}", Source, Channel, Invites(iidx), Invites(iidx + 1), Invites(iidx + 2), Invites(iidx + 3), Invites(iidx + 4), ts)
            Case 3 'Pull 4
                SendData FormatString(":{0} MODE {1} +IIII {2} {3} {4} {5} {6}", Source, Channel, Invites(iidx), Invites(iidx + 1), Invites(iidx + 2), Invites(iidx + 3), ts)
            Case 2 'Pull 3
                SendData FormatString(":{0} MODE {1} +III {2} {3} {4} {5}", Source, Channel, Invites(iidx), Invites(iidx + 1), Invites(iidx + 2), ts)
            Case 1 'Pull 2
                SendData FormatString(":{0} MODE {1} +II {2} {3} {4}", Source, Channel, Invites(iidx), Invites(iidx + 1), ts)
            Case 0 'Pull 1
                SendData FormatString(":{0} MODE {1} +I {2} {3}", Source, Channel, Invites(iidx), ts)
            Case Else: Exit For
        End Select
    Next iidx
End Sub

Private Sub IIRCd_ChangeAccount(ByVal Source As String, ByVal Target As String, ByVal account As String)
    If account = "" Then
        SendData FormatString(":{0} SVSMODE {1} -r", Source, Target)
    Else
        SendData FormatString(":{0} SVSMODE {1} +r", Source, Target)
    End If
End Sub

Private Property Get IIRCd_ChanModes() As String
    IIRCd_ChanModes = "beI,k,jl,cimMnOprRst"
End Property

Private Sub IIRCd_ChannelMode(ByVal Source As String, ByVal Channel As String, ByVal Modes As String)
#If TS_STRICT Then
    'Send the current TS if we know the channel. Else, send the current time.
    Dim ts As Long
    If Channels.Exists(Channel) Then ts = Channels(Channel).ts Else ts = basUnixTime.GetTime()
    SendData FormatString(":{0} MODE {1} {2} {3}", Source, Channel, Modes, ts)
#Else
    'In all technicality we're supposed to send the TS, but as services we don't have to, thus we can
    '"blast TS".
    SendData FormatString(":{0} MODE {1} {2}", Source, Channel, Modes)
#End If
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
#If TS_STRICT Then
    SendData FormatString(":{0} SJOIN {1} {2} +  :@{3}", basMain.Config.ServerName, ts, Channel, Source)
#Else
    SendData FormatString(":{0} JOIN {1}", Source, Channel)
    SendData FormatString(":{0} MODE {1} +o {2} {3}", basMain.Config.ServerName, Channel, Source, ts)
#End If
End Sub

Private Function IIRCd_CreateCID() As String
    IIRCd_CreateCID = vbNullString
End Function

Private Function IIRCd_CreateSID() As String
    IIRCd_CreateSID = vbNullString
End Function

Private Sub IIRCd_DeleteNetworkIPBan(ByVal Source As String, ByVal Mask As String)
    Err.Raise E_NOTIMPL
End Sub

Private Sub IIRCd_DeleteNetworkNickBan(ByVal Source As String, ByVal Mask As String)
    SendData FormatString(":{0} UNSQLINE 0 {1}", Source, Mask)
End Sub

Private Sub IIRCd_DeleteNetworkRealnameBan(ByVal Source As String, ByVal Mask As String)
    SendData FormatString(":{0} UNSGLINE 0 {1}", Source, Mask)
End Sub

Private Sub IIRCd_DeleteNetworkUserhostBan(ByVal Source As String, ByVal Mask As String)
    SendData FormatString(":{0} RAKILL {1} {2}", Source, Split(Mask, "@")(1), Split(Mask, "@")(0))
End Sub

Private Property Get IIRCd_ExemptChar() As String
    IIRCd_ExemptChar = "e"
End Property

Private Sub IIRCd_ForceNickChange(ByVal Source As String, ByVal Target As String, ByVal NewNick As String)
    Dim ts As Long
    ts = basUnixTime.GetTime
    SendData FormatString(":{0} SVSNICK {1} {2} :{3}", Source, Target, NewNick, ts)
End Sub

Private Property Get IIRCd_HalfopChar() As String
    IIRCd_HalfopChar = vbNullString
End Property

Private Function IIRCd_HasSupport(ByVal SupportType As IRCdSupport) As Boolean
    Select Case SupportType
        Case SUPPORT_ISIRCD, SUPPORT_HASKILL, SUPPORT_HASSVSKILL, SUPPORT_SVSKILLACK, SUPPORT_HASNICKHACK, _
            SUPPORT_HASNICKJUPE, SUPPORT_HASUMODEHACK, SUPPORT_HASACCOUNT, SUPPORT_CHANGEACCOUNT, _
            SUPPORT_USERHOSTBAN, SUPPORT_NICKBAN, SUPPORT_GCOSBAN, SUPPORT_TEMPAKILL, SUPPORT_DELAKILL, _
            SUPPORT_DELNICKBAN, SUPPORT_DELGCOSBAN: IIRCd_HasSupport = True
        Case Else: IIRCd_HasSupport = False
    End Select
End Function

Private Sub IIRCd_HoldChannel(ByVal Source As String, ByVal Channel As String)
    SendData FormatString(":{0} SQLINE {1} :Held by services", Source, Channel)
End Sub

Private Sub IIRCd_HoldNick(ByVal Source As String, ByVal Nick As String)
    SendData FormatString(":{0} SVSHOLD {1} 60 :Held by services", Source, Nick)
End Sub

Private Sub IIRCd_HoldServer(ByVal Source As String, ByVal Server As String)
    Err.Raise E_NOTIMPL
End Sub

Private Sub IIRCd_IntroduceClient(ByVal Nick As String, ByVal UserName As String, ByVal HostName As String, ByVal RealName As Variant, ByVal VHost As String, ByVal UserModes As String, ByVal CID As String, ByVal Server As String)
    'Format is:
    ':server NICK nick ts umodes user host server 0 0 :realname
    If Servers.Exists(Server) Then Err.Raise 9, , "Introduce server " + Server + " first."
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
#If TS_STRICT Then
    'Bahamut has this weird thing called "Client SJOIN". It's essentially SJOIN, but coming from a client.
    'In this form, the SJOIN is essentially just a JOIN with a TS before the channel... In theory we could
    'do "TS Update" forcing with this method.
    'Technically however, we are to use the existing TS for the channel if we know it exists.
    Dim ts As Long
    If Channels.Exists(Channel) Then ts = Channels(Channel).ts Else ts = basUnixTime.GetTime()
    SendData FormatString(":{0} SJOIN {1} {2}", Source, ts, Channel)
#Else
    SendData FormatString(":{0} JOIN {1}", Source, Channel)
#End If
End Sub

Private Sub IIRCd_KickUser(ByVal Source As String, ByVal Channel As String, ByVal Victim As String, ByVal Reason As String)
    SendData FormatString(":{0} KICK {1} {2} :{3}", Source, Channel, Victim, Reason)
End Sub

Private Sub IIRCd_KillUser(ByVal Source As String, ByVal SVSKillOK As Boolean, ByVal User As String, ByVal Reason As String)
    If SVSKillOK Then
        SendData FormatString(":{0} SVSKILL {1} :{2}", Source, User, Reason)
    Else
        SendData FormatString(":{0} KILL {1} :{0} ({2})", Source, User, Reason)
    End If
End Sub

Private Property Get IIRCd_OwnerChar() As String
    IIRCd_OwnerChar = vbNullString
End Property

Private Sub IIRCd_ParseCmd(ByVal Buffer As String)
'
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

Private Sub IIRCd_ReleaseNick(ByVal Source As String, ByVal Nick As String)
    SendData FormatString(":{0} SVSHOLD {1} 0", Source, Nick)
End Sub

Private Sub IIRCd_ReleaseServer(ByVal Source As String, ByVal Server As String)
    Err.Raise E_NOTIMPL
End Sub

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

Private Sub IIRCd_SetAccount(ByVal Source As String, ByVal Target As String, ByVal account As String)
    SendData FormatString(":{0} SVSMODE {1} +r", Source, Target)
End Sub

Private Sub IIRCd_SetServerNoOpers(ByVal Source As String, ByVal Server As String)
    Err.Raise E_NOTIMPL
End Sub

Private Sub IIRCd_SetUserModes(ByVal Source As String, ByVal Nick As String, ByVal Modes As String)
    SendData FormatString(":{0} SVSMODE {1} {2}", Source, Nick, Modes)
End Sub

Private Sub IIRCd_SetVHost(ByVal Source As String, ByVal Nick As String, ByVal VHost As String)
    Err.Raise E_NOTIMPL
End Sub

Private Sub IIRCd_SetVIdent(ByVal Source As String, ByVal Nick As String, ByVal VIdent As String)
    Err.Raise E_NOTIMPL
End Sub

Private Sub IIRCd_UnsetServerNoOpers(ByVal Source As String, ByVal Server As String)
    Err.Raise E_NOTIMPL
End Sub

Private Property Get IIRCd_UserModes() As String
    IIRCd_UserModes = "aAbcdefFghiIjkKmnoOrRswxXy"
End Property

Private Property Get IIRCd_VoiceChar() As String
    IIRCd_VoiceChar = "v"
End Property

Private Sub IIRCd_Wallopers(ByVal Source As String, ByVal Message As String)
    SendData FormatString(":{0} GLOBOPS :{1}", Source, Message)
End Sub
