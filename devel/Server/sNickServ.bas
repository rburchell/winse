Attribute VB_Name = "sNickServ"
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
Option Explicit
Public Const ModVersion = "0.0.2.2"

Public Type NickServDataRecord
    Nick As String              'The registered nick or account.
    Password As String          'Soon to be MD5 hashed! :D
    EMail As String             'The email. NOT CHECKED FOR VALIDITY.
    LastAddress As String       'The last seen nick!user@host. Used in INFO and BotServ !seen.
    LastQuit As String          'The last quit message. Used in INFO and BotServ !seen.
    AccessList() As String      'user@host entries that are exempt from nick enforcement.
    LastSeenTime As Long        'TS of last quit.
    GroupedNicks() As String    'Grouped nicknames.
    Access As String            'Access flags.
    Message As Long             'This is in the database, but what is it for?
    Greet As String             'This is the Greet Message displayed by ChanServ.
    Private As Boolean          'Not in NICKSERV LIST.
    HideQuit As Boolean         'Don't show the quit message in INFO or !seen.
    HideEmail As Boolean        'Don't show the email in INFO.
    HideAddress As Boolean      'Don't show the user@host in INFO or !seen.
    Secure As Boolean           'Settings/Channel access can only be used when IDENTIFYd.
    NoAutoOp As Boolean         'Don't obey +GIVE in channels.
    VHost As String             'HostServ VHOST assigned to this account.
    AbuseTeam As Boolean        'If the user is on the abuse team.
End Type

Public DB() As NickServDataRecord
Public Enforcers As New Collection
Public NextGuest As Long

Public Sub LoadData(ByVal conn As Connection)
    Dim mDB As Collection
    Set mDB = ReadTableIntoCollection(conn, "NickServ")
    Dim idx As Long, subcol As Collection
    If mDB.Count <= 0 Then
        Erase DB()
        Exit Sub
    End If
    ReDim DB(0 To mDB.Count - 1)
    For idx = 1 To mDB.Count
        Set subcol = mDB(idx)
        With DB(idx - 1)
            .Nick = subcol("name")
            .Password = subcol("password")
            .EMail = subcol("email")
            .LastAddress = subcol("last_address")
            .LastQuit = subcol("last_quit")
            If Len(subcol("access_list")) > 0 Then
                .AccessList = Split(subcol("access_list"), " ")
            Else
                Erase .AccessList
            End If
            .LastSeenTime = subcol("last_seen_time")
            .GroupedNicks = Split(subcol("grouped_nicks"), " ")
            .Access = subcol("access")
            .Message = subcol("message")
            .Greet = subcol("greet")
            .Private = subcol("private")
            .HideQuit = subcol("hide_quit")
            .HideEmail = subcol("hide_email")
            .HideAddress = subcol("hide_address")
            .Secure = subcol("secure")
            .NoAutoOp = subcol("no_auto_op")
            .VHost = subcol("hostserv_mask")
            .AbuseTeam = subcol("abuse_team")
        End With
    Next idx
End Sub

Public Sub SaveData(ByVal conn As Connection)
    'Great. Now we're writing to the database. This aint as easy :| .
    Dim rs As Recordset
    Set rs = GetTable(conn, "ChanServ")
    'Prepare the fields array in advance.
    Dim Fields(0 To 18) As String
    Fields(0) = "name"
    Fields(1) = "password"
    Fields(2) = "email"
    Fields(3) = "last_address"
    Fields(4) = "last_quit"
    Fields(5) = "access_list"
    Fields(6) = "last_seen_time"
    Fields(7) = "grouped_nicks"
    Fields(8) = "access"
    Fields(9) = "message"
    Fields(10) = "greet"
    Fields(11) = "private"
    Fields(12) = "hide_quit"
    Fields(13) = "hide_email"
    Fields(14) = "hide_address"
    Fields(15) = "secure"
    Fields(16) = "no_auto_op"
    Fields(17) = "hostserv_mask"
    Fields(18) = "abuse_team"
    Dim vals(0 To 18) As Variant
    'We can borrow one if the vals values to check if the DB has been initialized.
    On Local Error Resume Next
    vals(0) = UBound(DB)
    If Err = 9 Then Exit Sub 'No data to save.
    On Error GoTo 0
    With rs
        Dim idx As Long, idx2 As Long
        For idx = 0 To UBound(DB)
            vals(0) = DB(idx).Nick
            vals(1) = DB(idx).Password
            vals(2) = DB(idx).EMail
            vals(3) = DB(idx).LastAddress
            vals(4) = DB(idx).LastQuit
            vals(5) = Join(DB(idx).Access, " ")
            vals(6) = DB(idx).LastSeenTime
            vals(7) = Join(DB(idx).GroupedNicks, " ")
            vals(8) = DB(idx).Access
            vals(9) = DB(idx).Message
            vals(10) = DB(idx).Greet
            vals(11) = DB(idx).Private
            vals(12) = DB(idx).HideQuit
            vals(13) = DB(idx).HideEmail
            vals(14) = DB(idx).HideAddress
            vals(15) = DB(idx).Secure
            vals(16) = DB(idx).NoAutoOp
            vals(17) = DB(idx).VHost
            vals(18) = DB(idx).AbuseTeam
            .MoveFirst
            .Find "Name=" & DB(idx).Nick
            If .BOF Or .EOF Then
                'Nick was registered since last update, so we need to create it.
                .AddNew Fields, vals
                .Update
            Else
                'Nick was previously registered, in which case we are pointing to a valid record.
                .Update Fields, vals
            End If
        Next idx
        'Now we need to look for nicks in the database that we don't have in the collection - these
        'were dropped between updates, so we need to remove them from the DB or they get mysteriously
        'reregistered :) .
        .MoveFirst
        While Not .EOF
            'Now see if the current record is in our memory cache.
            If DBIndexOf(.Fields("name")) = -1 Then
                'Not found.
                Err.Clear
                .Delete 'Delete this record. Note that this doesn't move the record-pointer, which means
                        'any read or write operation will fail. We have to use Move*/Seek/Find/Close/etc
                        'before we can safely do stuff again. Thankfully we don't need to do anything else
                        'but just think of this as a warning in case you need to .Delete in other code.
            End If
            .MoveNext 'A deleted record is fully released here :) . This means that MovePrevious won't put
                      'us back on strange-deleted-record-land. Example: if we .MoveFirst then .Delete,
                      'MoveNext and MoveFirst would have the same result. Thus, we could theoretically
                      'clear a table by looping around .MoveFirst and .Delete :) .
        Wend
    End With
End Sub

Public Sub NickservHandler(ByVal Cmd As String, ByVal Sender As User)
    Dim Parameters() As String
    Dim SenderNick As String
    
    SenderNick = Sender.Nick
    Parameters() = basFunctions.ParseBuffer(Cmd)
    
    Select Case UCase(Parameters(0))
        Case "REGISTER"
            'P[0] - Cmd
            'P[1] - Nick <-password
            'P[2] - Email
            'P[3] - Password <-n/a
            'Can only register current nickname now.
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            Call sNickServ.Register(Sender, SenderNick, Parameters(2), Parameters(1))
        Case "IDENTIFY"
            'P[0] - Cmd
            'P[1] - Nick OPTIONAL
            'P[2] - Password
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            If UBound(Parameters) = 1 Then Call sNickServ.Identify(Sender, SenderNick, Parameters(1))
            If UBound(Parameters) = 2 Then Call sNickServ.Identify(Sender, Parameters(1), Parameters(2))
        Case "RECOVER"
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            If UBound(Parameters) = 1 Then Call sNickServ.Recover(Sender, Parameters(1), "")
            If UBound(Parameters) = 2 Then Call sNickServ.Recover(Sender, Parameters(1), Parameters(2))
        Case "RELEASE"
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            If UBound(Parameters) = 1 Then Call sNickServ.Release(Sender, Parameters(1), "")
            If UBound(Parameters) = 2 Then Call sNickServ.Release(Sender, Parameters(1), Parameters(2))
        Case "GHOST"
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            If UBound(Parameters) = 1 Then Call sNickServ.Ghost(Sender, Parameters(1), "")
            If UBound(Parameters) = 2 Then Call sNickServ.Ghost(Sender, Parameters(1), Parameters(2))
        Case "HELP"
            If UBound(Parameters) <> 0 Then
                Call sNickServ.Help(Sender, Parameters(1))
            Else
                Call sNickServ.Help(Sender, "")
            End If
        Case "VERSION"
            Call sNickServ.Version(Sender)
        Case "SET"
            'P[0] - Cmd
            'P[1] - Option
            'P[2] - Value
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            Call sNickServ.Set_(Sender, Parameters(1), Split(Cmd, " ", 3)(2))
        Case "LIST"
            'Really need to restrict this to access 10+ (we no longer use # permissions --Jason)
            Call sNickServ.List(Sender)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

Private Sub Help(Sender As User, ByVal Cmd As String)
    Dim SenderNick As String
    SenderNick = Sender.Nick
    Select Case UCase(Cmd)
        Case "SET"
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, "NickServ Set:")
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, " COMMUNICATION [PRIVMSG/NOTICE] - Tells services how to message you.")
        Case Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, "NickServ Commands:")
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, " REGISTER")
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, " IDENTIFY")
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, " SET")
    End Select
End Sub

Private Sub Version(Sender As User)
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(SVSINDEX_NICKSERV).Nick & "[" & sNickServ.ModVersion & "]")
End Sub

Private Sub Set_(ByVal Sender As User, ByVal Setting As String, ByVal Parameters As String)
    Dim cptr As Long
    If Sender.IdentifiedToNick <> "" Then
        Call basFunctions.SendMessage(Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.NickServNotIdentified)
        Exit Sub
    End If
    cptr = DBIndexOf(Sender.IdentifiedToNick)
    If cptr < 0 Then
        Call basFunctions.SendMessage(Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.NickServIdentificationNotRegistered)
        Exit Sub
    End If
    Select Case UCase(Setting)
        Case "MESSAGE"
            'We really want people to register their nick, so unless they do that, they get stuck with the
            'default method :P .
            Select Case UCase(Parameters)
                Case "PRIVMSG"
                    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.NickServCommunicationPrivmsg)
                    DB(cptr).Message = 0
                Case "NOTICE"
                    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.NickServCommunicationNotice)
                    DB(cptr).Message = 1
                Case Else
                    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.IncorrectParam)
            End Select
        Case "GREET"
            DB(cptr).Greet = Parameters
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, FormatString("[{0}] {1}", Sender.IdentifiedToNick, Parameters))
        Case "PRIVATE"
            Select Case UCase(Parameters)
                Case "ON"
                    DB(cptr).Private = False
                Case "OFF"
                    DB(cptr).Private = True
                Case Else
                    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.IncorrectParam)
            End Select
        Case "HIDEQUIT"
            Select Case UCase(Parameters)
                Case "ON"
                    DB(cptr).HideQuit = False
                Case "OFF"
                    DB(cptr).HideQuit = True
                Case Else
                    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.IncorrectParam)
            End Select
        Case "HIDEEMAIL"
            Select Case UCase(Parameters)
                Case "ON"
                    DB(cptr).HideEmail = False
                Case "OFF"
                    DB(cptr).HideEmail = True
                Case Else
                    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.IncorrectParam)
            End Select
        Case "HIDEADDRESS"
            Select Case UCase(Parameters)
                Case "ON"
                    DB(cptr).HideAddress = False
                Case "OFF"
                    DB(cptr).HideAddress = True
                Case Else
                    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.IncorrectParam)
            End Select
        Case "SECURE"
            Select Case UCase(Parameters)
                Case "ON"
                    DB(cptr).Secure = False
                Case "OFF"
                    DB(cptr).Secure = True
                Case Else
                    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.IncorrectParam)
            End Select
        Case "NOAUTOOP"
            Select Case UCase(Parameters)
                Case "ON"
                    DB(cptr).NoAutoOp = False
                Case "OFF"
                    DB(cptr).NoAutoOp = True
                Case Else
                    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.IncorrectParam)
            End Select
        Case Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.IncorrectParam)
    End Select
End Sub

Private Sub List(ByVal Sender As User)
    Dim c As Long
    On Local Error Resume Next
    c = UBound(DB)
    If Err = 9 Then
        'No registered nicks
        Exit Sub
    End If
    On Error GoTo 0
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, "NickServ List:")
    Dim i As Integer, lines As Long
    For i = 0 To c
        'This is just a simple list. If someone wants more info, they'll use INFO :-P.
        'A normal user should see these indicators:
        '* = Service Oper
        '% = Service CoMaster
        '@ = Service Master
        'Admins and abuse team should also see these indictators:
        '? = User has PRIVATE setting
        'Master should also see this indicator:
        '! = Abuse Team
        With DB(i)
            If Sender.HasFlag(AccFlagCoMaster) Or Sender.HasFlag(AccFlagMaster) Then
                If lines < 20 Then
                    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender, " " + IIf(InStr(.Access, AccFlagMaster) > 0, "@", IIf(InStr(.Access, AccFlagCoMaster) > 0, "%", IIf(.Access <> "", "*", ""))) + IIf(.Private, "?", "") + IIf(.AbuseTeam, "!", "") + " " + .Nick + " " + .EMail)
                    lines = lines + 1
                End If
            ElseIf Sender.HasFlag(AccFlagNickAdmin) Then
                If lines < 20 Then
                    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender, " " + IIf(InStr(.Access, AccFlagMaster) > 0, "@", IIf(InStr(.Access, AccFlagCoMaster) > 0, "%", IIf(.Access <> "", "*", ""))) + IIf(.Private, "?", "") + " " + .Nick + " " + .EMail)
                    lines = lines + 1
                End If
            Else
                'Don't show private nicks, and limit 20 lines else people get nice Max SendQ deals.
                If Not .Private And lines < 20 Then
                    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender, " " + IIf(InStr(.Access, AccFlagMaster) > 0, "@", IIf(InStr(.Access, AccFlagCoMaster) > 0, "%", IIf(.Access <> "", "*", ""))) + " " + .Nick + " " + IIf(.HideEmail, "Hidden@EMail.Address", .EMail))
                    lines = lines + 1
                End If
            End If
        End With
    Next
End Sub

Private Sub Register(ByVal Sender As User, ByVal NickToRegister As String, ByVal EMail As String, ByVal Password As String)
    NickToRegister = UCase(NickToRegister)
    If DBIndexOf(NickToRegister) Then
        'Nick already registered.
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, basMain.Users(Sender).Nick, Replies.NickServNickAlreadyRegistered)
        Exit Sub
    End If
    Dim c As Long
    With basMain.Users(Sender)
        On Local Error Resume Next
        c = UBound(DB) + 1
        If Err = 9 Then
            ReDim DB(0)
            c = 0
        Else
            ReDim Preserve DB(c)
        End If
        Dim ts As Long
        ts = basUnixTime.GetTime
        DB(c).AbuseTeam = False
        DB(c).Access = IIf(NickToRegister = basMain.Config.ServicesMaster, AccFlagMaster, "")
        ReDim DB(c).AccessList(0)
        DB(c).AccessList(0) = Mask(Sender.Nick + "!" + Sender.UserName + "@" + Sender.HostName, 3)
        DB(c).EMail = EMail
        ReDim DB(c).GroupedNicks(0)
        DB(c).GroupedNicks(0) = NickToRegister
        DB(c).HideAddress = False
        DB(c).HideEmail = False
        DB(c).HideQuit = False
        DB(c).LastAddress = Sender.UserName + "@" + IIf(Sender.VirtHost <> "", Sender.VirtHost, Sender.HostName)
        DB(c).LastQuit = ""
        DB(c).LastSeenTime = ts
        DB(c).Message = basMain.Config.DefaultMessageType
        DB(c).Nick = NickToRegister
        DB(c).NoAutoOp = False
        DB(c).Password = Password
        DB(c).Private = False
        DB(c).Secure = False
        DB(c).VHost = ""
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, .Nick, Replace(Replies.NickServRegisterOK, "%p", Password))
    End With
End Sub

Public Sub Identify(Sender As User, NickToIdentify As String, Password As String)
    Dim cptr As Long
    cptr = DBIndexOf(NickToIdentify)
    If cptr < 0 Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, basMain.Users(Sender).Nick, Replies.NickServIdentificationNotRegistered)
        Exit Sub
    End If
    If Password = DB(cptr).Password Then
        With Sender
            .AbuseTeam = DB(cptr).AbuseTeam
            .Access = IIf(IsDeny(Sender), "", DB(cptr).Access)
            ' ^ IIf added to remove services access if the user has been agent DENYed
            .MsgStyle = DB(cptr).Message
            .IdentifiedToNick = DB(cptr).Nick
            'Check if they are a master, just in case their permissions got fiddled with.
            If UCase(.IdentifiedToNick) = UCase(basMain.Config.ServicesMaster) Then
                Sender.SetFlags "+" & AccFlagMaster ' Not AccFullAccess, He might not want to recieve Services Notices (flag g)
            End If
            Sender.NickKillTimer = -1 'Cancel the enforce timer.
        End With
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.NickServIdentificationSuccessful)
        Call basFunctions.SendData(FormatString(":{0} SVS{1}MODE {2} +r", basMain.Service(SVSINDEX_NICKSERV).Nick, IIf(UCase(basMain.Config.ServerType) = "UNREAL", "2", ""), Sender.Nick))
        Dim u As User
        For Each u In Users
            If u.IdentifiedToNick = Sender.IdentifiedToNick And u.Nick <> Sender.Nick Then
                SendMessage Service(SVSINDEX_NICKSERV).Nick, u.Nick, Replies.NickServIdentifyCloneWarning
            End If
        Next u
    Else
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.NickServIdentificationBadPassword)
        If Sender.BadIdentifies <= 0 Then
            Sender.BadIdentifies = 1
            Sender.BadIdentTimer = basMain.Config.BadPassTimeout
        Else
            Sender.BadIdentifies = Sender.BadIdentifies + 1
        End If
        If Sender.BadIdentifies >= IIf(basMain.Config.BadPassLimit > 0, basMain.Config.BadPassLimit, 1) Then
            basFunctions.SendMessage Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.NickServTooManyBadPasswords
            Sender.SVSKillUser Replies.KillReasonPasswordLimit, Service(SVSINDEX_NICKSERV).Nick
        End If
    End If
End Sub

Public Sub Recover(ByVal Sender As User, ByVal Nick As String, ByVal Password As String)
    'How the access check works:
    'Is the nick in the same group as the sender's?
    'Is the password correct?
    If NextGuest < 1000000 Or NextGuest > 9999999 Then NextGuest = Int(Rnd * 9000000) + 1000000
    Dim cptr As Long, u As User, nicktmp As String
    cptr = DBIndexOf(Nick)
    If cptr < 0 Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, basMain.Users(Sender).Nick, Replies.NickServIdentificationNotRegistered)
        Exit Sub
    End If
    If Not Users.Exists(Nick) Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, basMain.Users(Sender).Nick, Replies.UserDoesntExist)
        Exit Sub
    End If
    Set u = Users(Nick)
    If Sender.IdentifiedToNick = DB(cptr).Nick Then
        'Screw the password.
        SendMessage Service(SVSINDEX_NICKSERV).Nick, u.Nick, Replies.NickServEnforceImmed
        SendMessage Service(SVSINDEX_NICKSERV).Nick, u.Nick, Replace(Replies.NickServEnforcingNick, "%n", "Guest" & NextGuest)
        nicktmp = u.Nick
        u.ForceChangeNick "Guest" & NextGuest
        'Let IRCops KILL it (as an implicit RELEASE).
        basFunctions.IntroduceClient nicktmp, basMain.Config.ServerName, "enforcer", True, "-S"
        Enforcers.Add Array(60!, nicktmp), nicktmp
        SendMessage Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replace(Replace(Replies.NickServNickRecover, "%n", nicktmp), "%g", "Guest" + NextGuest)
        SendMessage Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replace(Replies.NickServRecoverRelease, "%n", Nick)
        NextGuest = NextGuest + 1
    Else
        If DB(cptr).Password = Password Then
            SendMessage Service(SVSINDEX_NICKSERV).Nick, u.Nick, Replies.NickServEnforceImmed
            SendMessage Service(SVSINDEX_NICKSERV).Nick, u.Nick, Replace(Replies.NickServEnforcingNick, "%n", "Guest" & NextGuest)
            nicktmp = u.Nick
            u.ForceChangeNick "Guest" & NextGuest
            'Let IRCops KILL it (as an implicit RELEASE).
            basFunctions.IntroduceClient nicktmp, basMain.Config.ServerName, "enforcer", True, "-S"
            Enforcers.Add Array(60!, nicktmp), nicktmp
            SendMessage Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replace(Replace(Replies.NickServNickRecover, "%n", nicktmp), "%g", "Guest" + NextGuest)
            SendMessage Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replace(Replies.NickServRecoverRelease, "%n", Nick)
            NextGuest = NextGuest + 1
        Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.NickServIdentificationBadPassword)
            If Sender.BadIdentifies <= 0 Then
                Sender.BadIdentifies = 1
                Sender.BadIdentTimer = basMain.Config.BadPassTimeout
            Else
                Sender.BadIdentifies = Sender.BadIdentifies + 1
            End If
            If Sender.BadIdentifies >= IIf(basMain.Config.BadPassLimit > 0, basMain.Config.BadPassLimit, 1) Then
                basFunctions.SendMessage Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.NickServTooManyBadPasswords
                Sender.SVSKillUser Replies.KillReasonPasswordLimit, Service(SVSINDEX_NICKSERV).Nick
            End If
        End If
    End If
End Sub

Public Sub Release(ByVal Sender As User, ByVal Nick As String, ByVal Password As String)
    'Release an enforcer using the nick.
    Dim cptr As Long
    cptr = DBIndexOf(Nick)
    If cptr < 0 Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.NickServIdentificationNotRegistered)
        Exit Sub
    End If
    On Local Error Resume Next
    'Item is a function, so we can play this dirty trick.
    Call Enforcers.Item(Nick)
    If Err = 9 Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replace(Replies.NickServRelaseNotHeld, "%n", Nick))
    End If
    If Sender.IdentifiedToNick = DB(cptr).Nick Then
        'Screw the password.
        SendData FormatString(":{0} QUIT :Released by {1}", Nick, Sender.Nick)
        Enforcers.Remove Nick
    Else
        If DB(cptr).Password = Password Then
            SendData FormatString(":{0} QUIT :Released by {1}", Nick, Sender.Nick)
            Enforcers.Remove Nick
        Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.NickServIdentificationBadPassword)
            If Sender.BadIdentifies <= 0 Then
                Sender.BadIdentifies = 1
                Sender.BadIdentTimer = basMain.Config.BadPassTimeout
            Else
                Sender.BadIdentifies = Sender.BadIdentifies + 1
            End If
            If Sender.BadIdentifies >= IIf(basMain.Config.BadPassLimit > 0, basMain.Config.BadPassLimit, 1) Then
                basFunctions.SendMessage Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.NickServTooManyBadPasswords
                Sender.SVSKillUser Replies.KillReasonPasswordLimit, Service(SVSINDEX_NICKSERV).Nick
            End If
        End If
    End If
End Sub

Public Sub Ghost(ByVal Sender As User, ByVal Nick As String, ByVal Password As String)
    Dim cptr As Long, u As User, nicktmp As String
    cptr = DBIndexOf(Nick)
    If cptr < 0 Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, basMain.Users(Sender).Nick, Replies.NickServIdentificationNotRegistered)
        Exit Sub
    End If
    If Not Users.Exists(Nick) Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, basMain.Users(Sender).Nick, Replies.UserDoesntExist)
        Exit Sub
    End If
    Set u = Users(Nick)
    If Sender.IdentifiedToNick = DB(cptr).Nick Then
        'Screw the password.
        u.SVSKillUser Replace(Replies.KillReasonGhostKill, "%n", Sender.Nick)
        SendMessage Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replace(Replies.NickServNickGhosted, "%n", Nick)
    Else
        If DB(cptr).Password = Password Then
            u.SVSKillUser Replace(Replies.KillReasonGhostKill, "%n", Sender.Nick)
            SendMessage Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replace(Replies.NickServNickGhosted, "%n", Nick)
        Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.NickServIdentificationBadPassword)
            If Sender.BadIdentifies <= 0 Then
                Sender.BadIdentifies = 1
                Sender.BadIdentTimer = basMain.Config.BadPassTimeout
            Else
                Sender.BadIdentifies = Sender.BadIdentifies + 1
            End If
            If Sender.BadIdentifies >= IIf(basMain.Config.BadPassLimit > 0, basMain.Config.BadPassLimit, 1) Then
                basFunctions.SendMessage Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.NickServTooManyBadPasswords
                Sender.SVSKillUser Replies.KillReasonPasswordLimit, Service(SVSINDEX_NICKSERV).Nick
            End If
        End If
    End If
End Sub

'Callin subs for channel mode changes
Public Sub HandlePrefix(ByVal Source As String, ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Target As User)

End Sub

Public Sub HandleModeTypeA(ByVal Source As String, ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeB(ByVal Source As String, ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeC(ByVal Source As String, ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, Optional ByVal Entry As String)

End Sub

Public Sub HandleModeTypeD(ByVal Source As String, ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleCommand(ByVal Sender As String, ByVal Cmd As String, ByRef Args() As String)

End Sub

Public Sub HandleUserMode(ByVal User As User, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleTick(ByVal Interval As Single)
    If NextGuest < 1000000 Or NextGuest > 9999999 Then NextGuest = Int(Rnd * 9000000) + 1000000
    Dim oldc As Single, u As User, nicktmp As String, idx As Long
    For Each u In Users
        'Decrement and/or remove enforcers.
        For idx = 1 To Enforcers.Count
            oldc = Enforcers(idx)(0)
            oldc = oldc - Interval
            nicktmp = Enforcers(idx)(1)
            If oldc <= 0 Then
                SendData FormatString(":{0} QUIT :My work here is done.", nicktmp)
                Enforcers.Remove idx
                idx = idx - 1
            Else
                Enforcers.Remove idx
                Enforcers.Add Array(oldc, nicktmp), nicktmp, before:=idx
            End If
        Next idx
        'Is there a kill timer active?
        If u.NickKillTimer <= 0 Then
            oldc = u.NickKillTimer
            u.NickKillTimer = oldc - Interval
            If u.NickKillTimer <= 40! And oldc > 40! Then
                'Dropped below 40 seconds, send the 40 second warning.
                SendMessage Service(SVSINDEX_NICKSERV).Nick, u.Nick, Replies.NickServEnforceIn40
            ElseIf u.NickKillTimer <= 20! And oldc > 20! Then
                SendMessage Service(SVSINDEX_NICKSERV).Nick, u.Nick, Replies.NickServEnforceIn20
            ElseIf u.NickKillTimer <= 0! And oldc > 0! Then
                'IDENTIFY TIMEOUT!
                LogEventWithMessage LogTypeNotice, "User " + u.Nick + " did not identify."
                SendMessage Service(SVSINDEX_NICKSERV).Nick, u.Nick, Replies.NickServEnforceImmed
                SendMessage Service(SVSINDEX_NICKSERV).Nick, u.Nick, Replace(Replies.NickServEnforcingNick, "%n", "Guest" & NextGuest)
                nicktmp = u.Nick
                u.ForceChangeNick "Guest" & NextGuest
                'Let IRCops KILL it (as an implicit RELEASE).
                basFunctions.IntroduceClient nicktmp, basMain.Config.ServerName, "enforcer", True, "-S"
                Enforcers.Add Array(60!, nicktmp), nicktmp
                NextGuest = NextGuest + 1
            End If
        End If
        If u.BadIdentifies = 0 Then
            u.BadIdentTimer = u.BadIdentTimer - Interval
            If u.BadIdentTimer <= 0 Then u.BadIdentifies = 0
        End If
    Next u
End Sub

Public Sub HandleEvent(ByVal Source As String, ByVal EventName As String, Parameters() As Variant)
    Dim sptr As User, NewNick As String
    Select Case EventName
        Case basEvents.UserConnect
            Set sptr = Parameters(0)
            NewNick = sptr.Nick
        Case basEvents.UserNickChange
            Set sptr = Parameters(0)
            NewNick = Parameters(2)
    End Select
    If Not IsNickRegistered(NewNick) Then Exit Sub
    If sptr.IdentifiedToNick <> NewNick Then
        'Begin the countdown.
        sptr.NickKillTimer = 60!
        basFunctions.SendMessage Service(SVSINDEX_NICKSERV).Nick, NewNick, Replies.NickServNickRegistered
        basFunctions.SendMessage Service(SVSINDEX_NICKSERV).Nick, NewNick, Replies.NickServEnforceIn60
    End If
End Sub

Public Function DBIndexOf(ByVal Nick As String) As Long
    Dim idx As Long, idx2 As Long
    'First check if there's even DB.
    On Local Error Resume Next
    idx = UBound(DB)
    If Err = 9 Then
        DBIndexOf = -1
        Exit Function
    End If
    On Error GoTo 0
    For idx = 0 To UBound(DB)
        With DB(idx)
            If Nick = .Nick Then
                DBIndexOf = idx
                Exit Function
            Else
                For idx2 = 0 To UBound(.GroupedNicks)
                    If Nick = .GroupedNicks(idx2) Then
                        DBIndexOf = idx
                        Exit Function
                    End If
                Next idx2
            End If
        End With
    Next idx
    DBIndexOf = -1
End Function
