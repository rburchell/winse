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
    Message As String           'This is in the database, but what is it for?
    Greet As String             'This is the Greet Message displayed by ChanServ.
    Private As Boolean          'Not in NICKSERV LIST.
    HideQuit As Boolean         'Don't show the quit message in INFO or !seen.
    HideEmail As Boolean        'Don't show the email in INFO.
    HideAddress As Boolean      'Don't show the user@host in INFO or !seen.
    Secure As Boolean           'Settings/Channel access can only be used when IDENTIFYd.
    NoAutoOp As Boolean         'Don't obey +GIVE in channels.
    VHost As String             'HostServ VHOST assigned to this account.
End Type

Public DB() As NickServDataRecord

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
        End With
    Next idx
End Sub

Public Sub SaveData(ByVal conn As Connection)
    'Great. Now we're writing to the database. This aint as easy :| .
    Dim rs As Recordset
    Set rs = GetTable(conn, "ChanServ")
    'Prepare the fields array in advance.
    Dim Fields(0 To 17) As String
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
    Dim vals(0 To 17) As Variant
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
            .MoveFirst
            .Find "Name=" & DB(idx).Nick
            If .BOF Or .EOF Then
                'Channel was registered since last update, so we need to create it.
                .AddNew Fields, vals
                .Update
            Else
                'Channel was previously registered, in which case we are pointing to a valid record.
                .Update Fields, vals
            End If
        Next idx
        'Now we need to look for channels in the database that we don't have in the collection - these
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
            'We used to be able to ident to a nick that you werent called at the time.
            'Feature Removed... --w00t
            If UBound(Parameters) = 1 Then Call sNickServ.Identify(Sender, SenderNick, Parameters(1))
            If UBound(Parameters) = 2 Then Call sNickServ.Identify(Sender, Parameters(1), Parameters(2))
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
            Call sNickServ.Set_(Sender, Parameters(1) & " " & Parameters(2))
        Case "LIST"
            'Really need to restrict this to access 10+ (we no longer use # permissions --Jason)
            Call sNickServ.List(Sender)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

Private Sub Help(Sender As User, Cmd)
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

Private Sub Set_(Sender As User, Cmd)
    Dim SenderNick As String
    SenderNick = Sender.Nick
    Dim FirstSpace As String, Parameters As String
    FirstSpace = InStr(Cmd, " ")
    Parameters = Right(Cmd, Len(Cmd) - FirstSpace)
    If FirstSpace <> 0 Then Cmd = Left(Cmd, FirstSpace - 1)
    Select Case UCase(Cmd)
        Case "COMMUNICATION"
            Select Case UCase(Parameters)
                Case "PRIVMSG"
                    basMain.Users(Sender).MsgStyle = False
                    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, Replies.NickServCommunicationPrivmsg)
                    If basFunctions.IsNickRegistered(basMain.Users(Sender).Nick) Then
                        Call basFileIO.SetInitEntry(App.Path & "\databases\users.db", basMain.Users(Sender).Nick, "MsgStyle", "False")
                    End If
                Case "NOTICE"
                    basMain.Users(Sender).MsgStyle = True
                    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, Replies.NickServCommunicationNotice)
                    If basFunctions.IsNickRegistered(basMain.Users(Sender).Nick) Then
                        Call basFileIO.SetInitEntry(App.Path & "\databases\users.db", basMain.Users(Sender).Nick, "MsgStyle", "True")
                    End If
                Case Else
                    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, Replies.IncorrectParam)
            End Select
    End Select
End Sub

Private Sub List(Sender As User)
    Dim TotalRegisteredNicks As Double
    TotalRegisteredNicks = CDec(basFileIO.GetInitEntry(App.Path & "\databases\index.db", "Totals", "TotalRegisteredNicks", -1))
    If TotalRegisteredNicks = -1 Then
        'No registered nicks
        Exit Sub
    Else
        Dim CurrentNick As String, Access As String, HideEmail As String, EMail As String
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, basMain.Users(Sender).Nick, "NickServ List:")
        Dim i As Integer
        For i = 0 To TotalRegisteredNicks
            'DO NOT SHOW ABUSE TEAM! ITS MEANT TO BE SECRET!
            CurrentNick = basFileIO.GetInitEntry(App.Path & "\databases\index.db", "Nicks", "RegisteredNick" & i)
            Access = basFileIO.GetInitEntry(App.Path & "\databases\users.db", CStr(CurrentNick), "Access")
            HideEmail = basFileIO.GetInitEntry(App.Path & "\databases\users.db", CStr(CurrentNick), "HideEmail")
            EMail = basFileIO.GetInitEntry(App.Path & "\databases\users.db", CStr(CurrentNick), "Email")
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, basMain.Users(Sender).Nick, CStr(CurrentNick))
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, basMain.Users(Sender).Nick, " Access: " & Access)
            'need an access check here too...
            If HideEmail = True Then
                Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, basMain.Users(Sender).Nick, " Email: Hidden")
            Else
                Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, basMain.Users(Sender).Nick, " Email: " & EMail)
            End If
        Next
    End If
End Sub

Private Sub Register(Sender As User, NickToRegister As String, EMail As String, Password As String)
    Dim Access As String
    Dim HideEmail As String
    Dim MsgStyle As String
    NickToRegister = UCase(NickToRegister)
    If basFunctions.IsNickRegistered(NickToRegister) Then
        'Nick already registered.
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, basMain.Users(Sender).Nick, Replies.NickServNickAlreadyRegistered)
        Exit Sub
    End If
    
    With basMain.Users(Sender)
        If UCase(.Nick) = UCase(basMain.Config.ServicesMaster) Then .Access = AccFullAccess
        Access = .Access
        HideEmail = .HideEmail
        MsgStyle = .MsgStyle
        Call basFileIO.SetInitEntry(App.Path & "\databases\users.db", NickToRegister, "AbuseTeam", "False")
        Call basFileIO.SetInitEntry(App.Path & "\databases\users.db", NickToRegister, "Access", Access)
        Call basFileIO.SetInitEntry(App.Path & "\databases\users.db", NickToRegister, "Email", EMail)
        Call basFileIO.SetInitEntry(App.Path & "\databases\users.db", NickToRegister, "HideEmail", HideEmail)
        Call basFileIO.SetInitEntry(App.Path & "\databases\users.db", NickToRegister, "MsgStyle", MsgStyle)
        Call basFileIO.SetInitEntry(App.Path & "\databases\users.db", NickToRegister, "Password", Password)
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, basMain.Users(Sender).Nick, Replace(Replies.NickServRegisterOK, "%p", Password))
    End With
    Dim TotalRegisteredNicks As Variant
    TotalRegisteredNicks = CDec(basFileIO.GetInitEntry(App.Path & "\databases\index.db", "Totals", "TotalRegisteredNicks", -1))
    TotalRegisteredNicks = CStr(TotalRegisteredNicks + 1)
    Call basFileIO.SetInitEntry(App.Path & "\databases\index.db", "Totals", "TotalRegisteredNicks", CStr(TotalRegisteredNicks))
    Call basFileIO.SetInitEntry(App.Path & "\databases\index.db", "Nicks", "RegisteredNick" & TotalRegisteredNicks, NickToRegister)
End Sub

Public Function Identify(Sender As User, NickToIdentify As String, Password As String)
    Dim PasswordonFile As String
    PasswordonFile = basFileIO.GetInitEntry(App.Path & "\databases\users.db", NickToIdentify, "Password")
    If PasswordonFile = "" Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, basMain.Users(Sender).Nick, Replies.NickServIdentificationNotRegistered)
        Exit Function
    End If
    If Password = PasswordonFile Then
        With Sender
            .AbuseTeam = basFileIO.GetInitEntry(App.Path & "\databases\users.db", .Nick, "AbuseTeam")
            .Access = IIf(IsDeny(Sender), "", basFileIO.GetInitEntry(App.Path & "\databases\users.db", .Nick, "Access"))
            ' ^ IIf added to remove services access if the user has been agent DENYed
            .EMail = basFileIO.GetInitEntry(App.Path & "\databases\users.db", .Nick, "Email")
            .HideEmail = basFileIO.GetInitEntry(App.Path & "\databases\users.db", .Nick, "HideEmail")
            .MsgStyle = basFileIO.GetInitEntry(App.Path & "\databases\users.db", .Nick, "MsgStyle")
            .Password = basFileIO.GetInitEntry(App.Path & "\databases\users.db", .Nick, "Password")
            'Check if they are a master, just in case their permissions got fiddled with.
            If UCase(.IdentifiedToNick) = UCase(basMain.Config.ServicesMaster) Then
                Sender.SetFlags "+" & AccFlagMaster ' Not AccFullAccess, He might not want to recieve Services Notices (flag g)
            End If
            Sender.Custom.Remove "NickKillCountdown"
        End With
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, Replies.NickServIdentificationSuccessful)
        Sender.IdentifiedToNick = NickToIdentify
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
End Function

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
    Static NextGuest As Long
    If NextGuest < 1000000 Or NextGuest > 9999999 Then NextGuest = Int(Rnd * 9000000) + 1000000
    Dim oldc As Single, u As User
    For Each u In Users
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
            SendMessage Service(SVSINDEX_NICKSERV).Nick, u.Nick, Replies.NickServEnforcingNick
            u.ForceChangeNick "Guest" & NextGuest
            NextGuest = NextGuest + 1
        End If
        oldc = u.BadIdentTimer
        u.BadIdentTimer = oldc - Interval
        If u.BadIdentTimer <= 0 Then u.BadIdentifies = 0
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
