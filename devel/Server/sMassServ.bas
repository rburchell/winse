Attribute VB_Name = "sMassServ"
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
Public Const ModVersion = "0.0.0.1"

Public Sub MassservHandler(ByVal Cmd As String, ByVal Sender As User)

' Explicit ByVals entered: .NET uses ByVal by default, VB6 uses ByRef
' I want any problems with a ByVal definition caught now.

    Dim SenderNick As String
    
    SenderNick = Sender.Nick
    
    Dim Parameters As String
    If InStr(Cmd, " ") > 0 Then
        'doing that doesn't work for me. It only works when Variant is used.
        'Correction: it works fine when the array is dynamic. Don't worry, Split() won't fail us :P .
        Dim CmdParts() As String ' (0 To 1): Yes, I'm paranoid
        CmdParts() = Split(Cmd, " ", 2)
        Parameters = CmdParts(1)
        Cmd = CmdParts(0)
    Else
        Parameters = ""
    End If
    
    If Not Sender.HasFlag(AccFlagCanMassServ) Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, Replies.InsufficientPermissions)
        Exit Sub
    End If
    Select Case UCase(Cmd)
        Case "HELP"
            Call sMassServ.Help(Sender, Parameters)
        Case "VERSION"
            Call sMassServ.Version(Sender)
        Case "SERVJOIN"
            Call sMassServ.sJoin(Sender, Parameters)
        Case "SERVPART"
            Call sMassServ.sPart(Sender, Parameters)
        Case "OPERJOIN"
            Call sMassServ.OperJoin(Sender, Parameters)
        Case "OPERINVITE"
            Call sMassServ.OperInvite(Sender, Parameters)
        Case "ALLINVITE"
            Call sMassServ.AllInvite(Sender, Parameters)
        Case "MMODE"
            Call sMassServ.MMode(Sender, Parameters)
        Case "MKICK"
            Call sMassServ.MKick(Sender, Parameters)
        Case "MINVITE"
            Call sMassServ.MInvite(Sender, Parameters)
        Case "MKILL"
            If Sender.HasFlag(AccFlagCanMassKill) Then
                Call sMassServ.MKill(Sender, Parameters)
            Else
                Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, Replies.UnknownCommand)
            End If
        Case "CHANKILL"
            If Sender.HasFlag(AccFlagCanMassKill) Then
                Call sMassServ.ChanKill(Sender, Parameters)
            Else
                Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, Replies.UnknownCommand)
            End If
        Case Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

Private Sub Help(ByVal Sender As User, ByVal Cmd As String)
    Dim SenderNick As String
    SenderNick = Sender.Nick
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, "MassServ Commands:")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, " ")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, "  SERVJOIN     #<chan>        Make all Services bots join a channel")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, "  SERVPART     #<chan>        Make all Services bots part a channel")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, "  *ALLBOTJOIN  #<chan>         Make all bots join a channel")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, "  *ALLBOTPART  #<chan>         Make all bots part a channel")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, "  OPERJOIN #<chan>            Make all opers join a channel")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, "  OPERINVITE #<chan>          Invite all opers into a channel")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, "  ALLINVITE #<chan>           Invite all users into a channel")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, "  -----------------------------------------")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, "  MMODE   #<chan>  <mode>     Set a mode on each user on a channel")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, "  MKICK   #<chan>  <reason>   Kick all users from a channel")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, "  MINVITE #<chans> #<chand>   Mass Invite all users in one channel to another")
    If Sender.HasFlag(AccFlagCanMassKill) Then
      ' Begin Mass Kill Commands
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, "  MKILL <N!U@H> <Reason>      Kill all users matching the specified host")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, "  CHANKILL #<chan> <Reason>   Kill all users in the specified channel")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, SenderNick, "  *CHANGLINE #<chan> <Reason> G:Line all users in the specified channel")
      ' End Mass Kill Commands
    End If
End Sub

Private Sub Version(ByVal Sender As User)
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_MASSSERV).Nick, Sender.Nick, AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(SVSINDEX_MASSSERV).Nick & "[" & sMassServ.ModVersion & "]")
End Sub

Private Sub sJoin(ByVal Sender As User, ByVal Channel As String)
    Call basFunctions.JoinServicesToChannel(Sender, Channel)
End Sub

Private Sub sPart(ByVal Sender As User, ByVal Channel As String)
    Call basFunctions.PartServicesFromChannel(Sender, Channel)
End Sub

Private Sub OperJoin(ByVal Sender As User, ByVal Channel As String)
    Dim l As Integer
    For l = 1 To Users.Count
        If Not Users(l).Nick = "" Then
            If InStr(Users(l).Modes, "o") Then
                Call basFunctions.SendData(":" & Service(SVSINDEX_MASSSERV).Nick & " INVITE " & Users(l).Nick & " " & Channel)
                Call basFunctions.SendData("SVSJOIN " & Users(l).Nick & " " & Channel)
            End If
        End If
    Next l
End Sub

Private Sub OperInvite(ByVal Sender As User, ByVal Channel As String)
    Dim l As Integer
    For l = 1 To Users.Count
        If Not Users(l).Nick = "" Then
            If InStr(Users(l).Modes, "o") Then
                Call basFunctions.SendData(":" & Service(SVSINDEX_MASSSERV).Nick & " INVITE " & Users(l).Nick & " " & Channel)
            End If
        End If
    Next l
End Sub

Private Sub AllInvite(ByVal Sender As User, ByVal Channel As String)
    Dim l As Integer
    For l = 1 To Users.Count
        If Not Users(l).Nick = "" Then
            Call basFunctions.SendData(":" & Service(SVSINDEX_MASSSERV).Nick & " INVITE " & Users(l).Nick & " " & Channel)
        End If
    Next l
End Sub

Private Sub MMode(ByVal Sender As User, ByVal Parameters As String)
    On Local Error GoTo Fail
    Dim Chan As Channel, Mode As String
    Set Chan = Channels(Split(Parameters, " ")(0))
    Mode = Split(Parameters, " ")(1)
    Dim l As Integer, i As Integer
    'Actually, I'm gonna make a bit of a sneaky trick here :) .
    Dim bSet As Boolean
    bSet = True
    For l = 1 To Len(Mode)
        Select Case Mid(Mode, l, 1)
            Case "+": bSet = True
            Case "-": bSet = False
            Case Else
                If bSet Then
                    For i = 1 To Channels(Chan).Members.Count
                        basFunctions.SendData Service(SVSINDEX_MASSSERV).Nick & " MODE " & Chan.Name & " +" & Mid(Mode, l, 1) & " " & Chan.Members(i).Member.Nick
                    Next i
                Else
                    If UCase(basMain.Config.ServerType) = "UNREAL" Then
                        basFunctions.SendData Service(SVSINDEX_MASSSERV).Nick & " SVSMODE " & Chan.Name & " -" & Mid(Mode, l, 1)
                    Else
                        For i = 1 To Channels(Chan).Members.Count
                            basFunctions.SendData Service(SVSINDEX_MASSSERV).Nick & " MODE " & Chan.Name & " -" & Mid(Mode, l, 1) & " " & Chan.Members(i).Member.Nick
                        Next i
                    End If
                End If
        End Select
    Next l
    Exit Sub
Fail:
    basFunctions.NotifyAllUsersWithServicesAccess "Error in MassServ MMODE! " & Err.Number & ": " & Err.Description
End Sub

Private Sub MKick(ByVal Sender As User, ByVal Parameters As String)
    On Local Error GoTo Fail
    Dim Chan As Channel, Reason As String
    Set Chan = Channels(Split(Parameters, " ", 2)(0))
    Reason = Split(Parameters, " ", 2)(1)
    Dim l As Integer
    For l = 1 To Chan.Members.Count
        Call basFunctions.SendData(":" & Service(SVSINDEX_CHANSERV).Nick & " KICK " & Chan.Name & " " & Chan.Members(l).Member.Nick & " :" & Reason)
    Next l
    Exit Sub
Fail:
    basFunctions.NotifyAllUsersWithServicesAccess "Error in MassServ MKICK! " & Err.Number & ": " & Err.Description
End Sub

Private Sub MInvite(ByVal Sender As User, ByVal Parameters As String)
    On Local Error GoTo Fail
    Dim SourceChan As Channel, DestChan As String
    Set SourceChan = Channels(Split(Parameters, " ")(0))
    DestChan = Split(Parameters, " ")(1)
    Dim l As Integer
    For l = 1 To SourceChan.Members.Count
        Call basFunctions.SendData(":" & Service(SVSINDEX_MASSSERV).Nick & " INVITE " & SourceChan.Members(l).Member.Nick & " " & DestChan)
    Next l
    Exit Sub
Fail:
    basFunctions.NotifyAllUsersWithServicesAccess "Error in MassServ MInvite! " & Err.Number & ": " & Err.Description
End Sub

Private Sub MKill(ByVal Sender As User, ByVal Parameters As String)
    Dim l As Integer, Mask As String, Reason As String
    Mask = Split(Parameters, " ", 2)(0)
    Reason = Split(Parameters, " ", 2)(1)
    'Now check to see if the mask is too broad.
    If Len(Replace(Replace(Replace(Replace(Mask, "?", ""), "*", ""), "@", ""), "!", "")) < 2 Then
        LogEventWithMessage basMain.LogTypeNotice, "MassServ MKILL - " & Sender.Nick & " tried to use an overbroad mask!"
    End If
    For l = 1 To Users.Count
        With Users(l)
            If .Nick & "!" & .UserName & "@" & .HostName Like Mask Then
                'Use a sender of "" so that KillUser doesn't mulilate our custom path.
                Users(l).KillUser " :" & basMain.Service(SVSINDEX_OPERSERV).Nick & "!" & Sender.Nick & " (" & Reason & ")", ""
            End If
        End With
    Next l
End Sub

Private Sub ChanKill(ByVal Sender As User, ByVal Parameters As String)
    On Local Error GoTo Fail
    Dim Chan As Channel, Message As String
    Set Chan = Channels(Split(Parameters, " ", 2)(0))
    Message = Split(Parameters, " ", 2)(1)
    Dim l As Integer
    For l = 0 To Chan.Members.Count
        Users(l).KillUser basMain.Service(SVSINDEX_OPERSERV).Nick & "!" & Sender.Nick & " (" & Message & ")", ""
    Next l
    Exit Sub
Fail:
    basFunctions.NotifyAllUsersWithServicesAccess "Error in MassServ CHANKILL! " & Err.Number & ": " & Err.Description
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

End Sub

