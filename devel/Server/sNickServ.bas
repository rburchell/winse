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

Public Sub NickservHandler(Cmd As String, Sender As Integer)
    Dim Parameters() As String
    Dim SenderNick As String
    
    SenderNick = basFunctions.ReturnUserName(Sender)
    Parameters() = basFunctions.ParseBuffer(Cmd)
    
    Select Case UCase(Parameters(0))
        Case "REGISTER"
            'P[0] - Cmd
            'P[1] - Nick <-password
            'P[2] - Email
            'P[3] - Password <-n/a
            'Can only register current nickname now.
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(basMain.Service(1).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            Call sNickServ.Register(Sender, SenderNick, Parameters(2), Parameters(1))
        Case "IDENTIFY"
            'P[0] - Cmd
            'P[1] - Nick <- now password.
            'P[2] - Password <- now not used
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(basMain.Service(1).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            'We used to be able to ident to a nick that you werent called at the time.
            'Feature Removed... --w00t
            Call sNickServ.Identify(Sender, SenderNick, Parameters(1))
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
                Call basFunctions.SendMessage(basMain.Service(1).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            Call sNickServ.Set_(Sender, Parameters(1) & " " & Parameters(2))
        Case "LIST"
            'Really need to restrict this to access 10+
            Call sNickServ.List(Sender)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(1).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

Private Sub Help(Sender As Integer, Cmd)
    Dim SenderNick As String
    SenderNick = basFunctions.ReturnUserName(Sender)
    Select Case UCase(Cmd)
        Case "SET"
            Call basFunctions.SendMessage(basMain.Service(1).Nick, SenderNick, "NickServ Set:")
            Call basFunctions.SendMessage(basMain.Service(1).Nick, SenderNick, " COMMUNICATION [PRIVMSG/NOTICE] - Tells services how to message you.")
        Case Else
            Call basFunctions.SendMessage(basMain.Service(1).Nick, SenderNick, "NickServ Commands:")
            Call basFunctions.SendMessage(basMain.Service(1).Nick, SenderNick, " REGISTER")
            Call basFunctions.SendMessage(basMain.Service(1).Nick, SenderNick, " IDENTIFY")
            Call basFunctions.SendMessage(basMain.Service(1).Nick, SenderNick, " SET")
    End Select
End Sub

Private Sub Version(Sender As Integer)
    Call basFunctions.SendMessage(basMain.Service(1).Nick, basFunctions.ReturnUserName(Sender), AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(1).Nick & "[" & sNickServ.ModVersion & "]")
End Sub

Private Sub Set_(Sender As Integer, Cmd)
    Dim SenderNick As String
    SenderNick = basFunctions.ReturnUserName(Sender)
    Dim FirstSpace As String, Parameters As String
    FirstSpace = InStr(Cmd, " ")
    Parameters = Right(Cmd, Len(Cmd) - FirstSpace)
    If FirstSpace <> 0 Then Cmd = Left(Cmd, FirstSpace - 1)
    Select Case UCase(Cmd)
        Case "COMMUNICATION"
            Select Case UCase(Parameters)
                Case "PRIVMSG"
                    basMain.Users(Sender).MsgStyle = False
                    Call basFunctions.SendMessage(basMain.Service(1).Nick, SenderNick, Replies.NickServCommunicationPrivmsg)
                    If basFunctions.IsNickRegistered(basMain.Users(Sender).Nick) Then
                        Call basFileIO.SetInitEntry("users.db", basMain.Users(Sender).Nick, "MsgStyle", "False")
                    End If
                Case "NOTICE"
                    basMain.Users(Sender).MsgStyle = True
                    Call basFunctions.SendMessage(basMain.Service(1).Nick, SenderNick, Replies.NickServCommunicationNotice)
                    If basFunctions.IsNickRegistered(basMain.Users(Sender).Nick) Then
                        Call basFileIO.SetInitEntry("users.db", basMain.Users(Sender).Nick, "MsgStyle", "True")
                    End If
                Case Else
                    Call basFunctions.SendMessage(basMain.Service(1).Nick, SenderNick, Replies.IncorrectParam)
            End Select
    End Select
End Sub

Private Sub List(Sender As Integer)
    Dim TotalRegisteredNicks As Double
    TotalRegisteredNicks = CDec(basFileIO.GetInitEntry("index.db", "Totals", "TotalRegisteredNicks", -1))
    If TotalRegisteredNicks = -1 Then
        'No registered nicks
        Exit Sub
    Else
        Dim CurrentNick As String, Access As String, HideEMail As String, EMail As String
        Call basFunctions.SendMessage(basMain.Service(1).Nick, basMain.Users(Sender).Nick, "NickServ List:")
        Dim i As Integer
        For i = 0 To TotalRegisteredNicks
            'DO NOT SHOW ABUSE TEAM! ITS MEANT TO BE SECRET!
            CurrentNick = basFileIO.GetInitEntry("index.db", "Nicks", "RegisteredNick" & i)
            Access = basFileIO.GetInitEntry("users.db", CStr(CurrentNick), "Access")
            HideEMail = basFileIO.GetInitEntry("users.db", CStr(CurrentNick), "HideEmail")
            EMail = basFileIO.GetInitEntry("users.db", CStr(CurrentNick), "Email")
            Call basFunctions.SendMessage(basMain.Service(1).Nick, basMain.Users(Sender).Nick, CStr(CurrentNick))
            Call basFunctions.SendMessage(basMain.Service(1).Nick, basMain.Users(Sender).Nick, " Access: " & Access)
            'need an access check here too...
            If HideEMail = True Then
                Call basFunctions.SendMessage(basMain.Service(1).Nick, basMain.Users(Sender).Nick, " Email: Hidden")
            Else
                Call basFunctions.SendMessage(basMain.Service(1).Nick, basMain.Users(Sender).Nick, " Email: " & EMail)
            End If
        Next
    End If
End Sub

Private Sub Register(Sender As Integer, NickToRegister As String, EMail As String, Password As String)
    Dim Access As String
    Dim HideEMail As String
    Dim MsgStyle As String
    NickToRegister = UCase(NickToRegister)
    If basFunctions.IsNickRegistered(NickToRegister) Then
        'Nick already registered.
        Call basFunctions.SendMessage(basMain.Service(1).Nick, basMain.Users(Sender).Nick, Replies.NickServNickAlreadyRegistered)
        Exit Sub
    End If
    
    With basMain.Users(Sender)
        If UCase(.Nick) = UCase(basMain.Config.ServicesMaster) Then .Access = AccFullAccess
        Access = .Access
        HideEMail = .HideEMail
        MsgStyle = .MsgStyle
        Call basFileIO.SetInitEntry("users.db", NickToRegister, "AbuseTeam", "False")
        Call basFileIO.SetInitEntry("users.db", NickToRegister, "Access", Access)
        Call basFileIO.SetInitEntry("users.db", NickToRegister, "Email", EMail)
        Call basFileIO.SetInitEntry("users.db", NickToRegister, "HideEmail", HideEMail)
        Call basFileIO.SetInitEntry("users.db", NickToRegister, "MsgStyle", MsgStyle)
        Call basFileIO.SetInitEntry("users.db", NickToRegister, "Password", Password)
        Call basFunctions.SendMessage(basMain.Service(1).Nick, basMain.Users(Sender).Nick, Replace(Replies.NickServRegisterOK, "%p", Password))
    End With
    Dim TotalRegisteredNicks As Variant
    TotalRegisteredNicks = CDec(basFileIO.GetInitEntry("index.db", "Totals", "TotalRegisteredNicks", -1))
    TotalRegisteredNicks = CStr(TotalRegisteredNicks + 1)
    Call basFileIO.SetInitEntry("index.db", "Totals", "TotalRegisteredNicks", CStr(TotalRegisteredNicks))
    Call basFileIO.SetInitEntry("index.db", "Nicks", "RegisteredNick" & TotalRegisteredNicks, NickToRegister)
End Sub

Public Function Identify(Sender As Integer, NickToIdentify As String, Password As String)
    Dim PasswordonFile As String
    PasswordonFile = basFileIO.GetInitEntry("users.db", NickToIdentify, "Password")
    If PasswordonFile = "" Then
        Call basFunctions.SendMessage(basMain.Service(1).Nick, basMain.Users(Sender).Nick, Replies.NickServIdentificationNotRegistered)
        Exit Function
    End If
    If Password = PasswordonFile Then
        With basMain.Users(Sender)
            .AbuseTeam = basFileIO.GetInitEntry("users.db", .Nick, "AbuseTeam")
            .Access = IIf(IsDeny(Sender), "", basFileIO.GetInitEntry("users.db", .Nick, "Access"))
            ' ^ IIf added to remove services access if the user has been agent DENYed
            .EMail = basFileIO.GetInitEntry("users.db", .Nick, "Email")
            .HideEMail = basFileIO.GetInitEntry("users.db", .Nick, "HideEmail")
            .MsgStyle = basFileIO.GetInitEntry("users.db", .Nick, "MsgStyle")
            .Password = basFileIO.GetInitEntry("users.db", .Nick, "Password")
            'Check if they are a master, just in case their permissions got fiddled with.
            If UCase(.IdentifiedToNick) = UCase(basMain.Config.ServicesMaster) Then
                SetFlags Sender, "+" & AccFlagMaster ' Not AccFullAccess, He might not want to recieve Services Notices (flag g)
            End If
        End With
        Call basFunctions.SendMessage(basMain.Service(1).Nick, basMain.Users(Sender).Nick, Replies.NickServIdentificationSuccessful)
        basMain.Users(Sender).IdentifiedToNick = NickToIdentify
    Else
        Call basFunctions.SendMessage(basMain.Service(1).Nick, basMain.Users(Sender).Nick, Replies.NickServIdentificationBadPassword)
    End If
End Function

'Callin subs for channel mode changes
Public Sub HandlePrefix(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, ByVal Target As Integer)

End Sub

Public Sub HandleModeTypeA(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeB(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeC(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, Optional ByVal Entry As String)

End Sub

Public Sub HandleModeTypeD(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleCommand(ByVal Sender As String, ByVal Cmd As String, ByRef Args() As String)

End Sub

Public Sub HandleUserMode(ByVal UserID As Integer, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleTick(ByVal Interval As Single)

End Sub
