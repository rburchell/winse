Attribute VB_Name = "sAgent"
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
Public Const ModVersion = "0.0.2.4"
Public DenyMasks As New Collection

Public Sub AgentHandler(Cmd As String, Sender As Integer)
    'You need not be opered, or have services access to use Agent. All you
    'need is to be on the abuse team. --w00t
    Dim Parameters() As String
    Dim Message As String
    ReDim Parameters(0) As String
    Dim Cmdcopy As String
    
    Dim SenderNick As String
    Dim Spacer As Byte
    Dim Elements As Integer
    Dim i As Integer
    SenderNick = basFunctions.ReturnUserName(Sender)
    
    'Considering that Service Master (?) can probably
    'add/remove Abuse Team members, we may as well give
    'him automatic access here, don't you think? -aquanight
        'Nope, cause my eventual scheme is to require diplomatic "voting" from users
        'connected to the server... Long way off, but saves us adding a check that
        'will eventually be removed. (maybe perhaps :P) --w00t
        '(oh, and besides, what's the point? Since he is, he can just add himself :))

    If basFunctions.IsAbuseTeamMember(Sender) = False Then
        Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, Replies.ServiceRestrictedToAbuseTeam)
        Exit Sub
    End If
    
    Cmdcopy = Cmd
    Do While InStr(Cmdcopy, " ") <> 0
        Spacer = InStr(Cmdcopy, " ")
        If Spacer <> 0 Then
            Parameters(Elements) = Left(Cmdcopy, Spacer - 1)
        Else
            Parameters(Elements) = Cmdcopy
        End If
        Cmdcopy = Right(Cmdcopy, Len(Cmdcopy) - Spacer)
        Elements = Elements + 1
        ReDim Preserve Parameters(Elements)
    Loop
    Parameters(Elements) = Cmdcopy
    
    Select Case UCase(Parameters(0))
        Case "HELP"
            Call sAgent.Help(Sender)
        Case "UMODE"
            'P[0] - Cmd
            'P[1] - Nick
            'P[2] - Modes string
            If Elements < 2 Then
                Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            Call sAgent.UMode(Sender, Parameters(1), Parameters(2))
        Case "EXIT"
            'P[0] - Cmd
            'P[1] - Nick
            'P[2>] - Message
            If Elements < 2 Then
                Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            For i = 2 To Elements
                Message = Message & IIf(i = 2, "", " ") & Parameters(i)
            Next
            Call sAgent.Exit_(Sender, Parameters(1), Message)
        Case "FJOIN"
            'P[0] - Cmd
            'P[1] - Nick
            'P[2] - Chan
            If Elements < 2 Then
                Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            Call sAgent.FJoin(Sender, Parameters(1), Parameters(2))
        Case "FPART"
            'P[0] - Cmd
            'P[1] - Nick
            'P[2] - Chan
            If Elements < 2 Then
                Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            Call sAgent.FPart(Sender, Parameters(1), Parameters(2))
        Case "KILL"
            'P[0] - Cmd
            'P[1] - Nick
            'P[2>] - Message
            If Elements < 2 Then
                Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            For i = 2 To Elements
                Message = Message & IIf(i = 2, "", " ") & Parameters(i)
            Next
            Call sAgent.Kill(Sender, Parameters(1), Message)
        Case "KICK"
            'P[0] - Cmd
            'P[1] - Nick
            'P[2] - Channel
            'P[3>] - Message
            If Elements < 3 Then
                Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            For i = 3 To Elements
                Message = Message & IIf(i = 3, "", " ") & Parameters(i)
            Next
            Call sAgent.Kick(Sender, Parameters(1), Parameters(2), Message)
        Case "NICK"
            'P[0] - Cmd
            'P[1] - Old Nick
            'P[2] - New Nick
            If Elements < 2 Then
                Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            Call sAgent.Nick(Sender, Parameters(1), Parameters(2))
        Case "UNIDENTIFY"
            'P[0] - Cmd
            'P[1] - Target
            If Elements < 1 Then
                Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            Call sAgent.UnIdentify(Sender, Parameters(1))
        Case "DEOPER"
            'P[0] - Cmd
            'P[1] - Target
            Call sAgent.DeOper(Sender, Parameters(1))
            'Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, " Not yet functional.")
        Case "DENY"
            'P[0] - Cmd
            'P[1] - BaseCommand
            'P[2] - Parameters (If needed)
            If Elements < 1 Then
              Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, Replies.InsufficientParameters)
              Exit Sub
            Else
              If Elements < 2 And UCase(Parameters(1)) <> "HELP" And UCase(Parameters(1)) <> "LIST" And UCase(Parameters(1)) <> "WIPE" Then
                Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
              End If
            End If
            If Elements < 2 Then
              Call sAgent.Deny(Sender, Parameters(1))
            Else
              Call sAgent.Deny(Sender, Parameters(1), Parameters(2))
            End If
        Case "VERSION"
            Call sAgent.Version(Sender)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

Private Sub Help(Sender As Integer)
    Dim SenderNick As String
    SenderNick = basFunctions.ReturnUserName(Sender)
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "Agent Commands:")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, " ")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, " --Abuse Team Only--")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  *MODE         Give mode to nick in channel.")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  EXIT       -  Exit user from server with reason.")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  NICK       -  Change user nickname.")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  *IGNORE     - Manipulate the IGNORE list")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  KICK       - Kick a users from any channel.")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  KILL       - Kill user from server.")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  FJOIN      - Force join a user to a channel.")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  FPART      - Force part a user from a channel.")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  UMODE      - Change user modes")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  *DENY       - Deny a client from services/opering")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  *UNDENY     - Grant services back to client")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  UNIDENTIFY - Removes services access from a client.")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  DEOPER     - Removes +o from a client.")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  *ZLINE      - Add a global Z:LINE to the network")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  DENY      - Deny a hostmask IRCop and Services power: See DENY HELP")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, " ")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  Notice: For more Information type /msg Agent HELP command")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  Notice: All commands sent to Agent are logged!")
End Sub

Private Sub Version(Sender As Integer)
    Call basFunctions.SendMessage(basMain.Service(7).Nick, basFunctions.ReturnUserName(Sender), AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(7).Nick & "[" & sAgent.ModVersion & "]")
End Sub

'damn not letting me use a keyword >:(
Private Sub Exit_(Sender As Integer, Nick As String, Message As String)
    Call basFunctions.LogEventWithMessage(basMain.LogTypeNotice, basMain.Users(Sender).Nick & " used AGENT EXIT " & Nick & " with message " & Message)
    basFunctions.SendData ("SVSKILL " & Nick & " :" & Message)
End Sub

Private Sub UMode(Sender As Integer, Nick As String, Modes As String)
    Dim Target As Integer
    Target = basFunctions.ReturnUserIndex(Nick)
    Call basFunctions.LogEventWithMessage(basMain.LogTypeNotice, basMain.Users(Sender).Nick & " set modes " & Modes & " on " & Nick)
    Call basFunctions.SetUserModes(Target, Modes)
    Call basFunctions.SendData(IIf(basMain.Config.ServerType = "Unreal", "SVS2MODE ", "SVSMODE ") & Nick & " " & Modes)
End Sub

Private Sub Nick(Sender As Integer, OldNick As String, NewNick As String)
    'IMHO, we really ought to have a check to make sure that users cant change
    'the nick of those with access greater than them, but that can wait for now.
    '--w00t
        'They're _ABUSE TEAM_. I can understand such a check
        'for other Abuse Team members, but otherwise... -aquanight
            'True. Belay that order. I take it you mean NON-abuse team members? --w00t
    Call basFunctions.LogEventWithMessage(basMain.LogTypeNotice, basMain.Users(Sender).Nick & " used AGENT NICK " & OldNick & " " & NewNick)
    Call basFunctions.ForceChangeNick(Sender, OldNick, NewNick)
End Sub

Private Sub Kill(Sender As Integer, Nick As String, Message As String)
    Call basFunctions.LogEventWithMessage(basMain.LogTypeNotice, basMain.Users(Sender).Nick & " used AGENT KILL " & Nick & " with reason " & Message)
    Call basFunctions.SendData(":" & basMain.Service(7).Nick & " KILL " & Nick & " :" & Message & " (" & basFunctions.ReturnUserName(Sender) & ")")
End Sub

Private Sub Kick(Sender As Integer, Nick As String, Channel As String, Message As String)
    Call basFunctions.LogEventWithMessage(basMain.LogTypeNotice, basMain.Users(Sender).Nick & " used AGENT KICK " & Nick & " from " & Channel & " with reason " & Message)
    Call basFunctions.SendData(":" & basMain.Service(7).Nick & " KICK " & Channel & " " & Nick & " :" & Message & " (" & basFunctions.ReturnUserName(Sender) & ")")
End Sub

Private Sub UnIdentify(Sender As Integer, Nick As String)
    Dim TargetIndex As Variant
    TargetIndex = basFunctions.ReturnUserIndex(Nick)
    If TargetIndex = -1 Then
        Call basFunctions.SendMessage(basMain.Service(7).Nick, basMain.Users(Sender).Nick, Replies.UserDoesntExist)
    End If
    Call basFunctions.LogEventWithMessage(basMain.LogTypeNotice, basMain.Users(Sender).Nick & " used AGENT UNIDENTIFY " & Nick)
    basMain.Users(TargetIndex).IdentifiedToNick = ""
    basMain.Users(TargetIndex).Access = 0
    basMain.Users(TargetIndex).AbuseTeam = False
    Call basFunctions.SendMessage(basMain.Service(7).Nick, basMain.Users(Sender).Nick, Replace(Replies.AgentUserUnidentified, "%n", Nick))
End Sub

Private Sub DeOper(Sender As Integer, Nick As String)
    Dim TargetIndex As Variant
    TargetIndex = basFunctions.ReturnUserIndex(Nick)
    If TargetIndex = -1 Then
        Call basFunctions.SendMessage(basMain.Service(7).Nick, basMain.Users(Sender).Nick, Replies.UserDoesntExist)
    End If
    Call basFunctions.LogEventWithMessage(basMain.LogTypeNotice, basMain.Users(Sender).Nick & " used AGENT DEOPER " & Nick)
    'remove their oper privilages, courtesy of Agent :)
    If basMain.Config.ServerType = "UNREAL" Then ' Support SVSO? Its a better way of removing operflags
      Call basFunctions.SendData("SVSO " & Nick & " -")
      If InStr(Users(TargetIndex).Modes, "g") Then Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVS2MODE " & Nick & " -g")
      If InStr(Users(TargetIndex).Modes, "v") Then Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVS2MODE " & Nick & " -v")
      ' These two flags arent cleared by svso for some reason:
      '  Recieve Infected DCC notices (v)
      '  Can Read and Send To GLOBOPS (g)
    Else ' SVSO Unsupported, Use SVSMODE
      If InStr(Users(TargetIndex).Modes, "o") Then
        Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVSMODE " & Nick & " -o")
        Users(TargetIndex).Modes = Replace(Users(TargetIndex).Modes, "o", "")
      End If
      If InStr(Users(TargetIndex).Modes, "O") Then
        Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVSMODE " & Nick & " -O")
        Users(TargetIndex).Modes = Replace(Users(TargetIndex).Modes, "O", "")
      End If
      If InStr(Users(TargetIndex).Modes, "C") Then
        Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVSMODE " & Nick & " -C")
        Users(TargetIndex).Modes = Replace(Users(TargetIndex).Modes, "C", "")
      End If
      If InStr(Users(TargetIndex).Modes, "A") Then
        Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVSMODE " & Nick & " -A")
        Users(TargetIndex).Modes = Replace(Users(TargetIndex).Modes, "A", "")
      End If
      If InStr(Users(TargetIndex).Modes, "a") Then
        Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVSMODE " & Nick & " -a")
        Users(TargetIndex).Modes = Replace(Users(TargetIndex).Modes, "a", "")
      End If
      If InStr(Users(TargetIndex).Modes, "N") Then
        Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVSMODE " & Nick & " -N")
        Users(TargetIndex).Modes = Replace(Users(TargetIndex).Modes, "N", "")
      End If
    End If
    'Until we clear up all this modes business, blank OUR copy of their modes
    'and request a new one. (ie let the current parser reparse their new modes)
    'instead of trying to remove one :/ What I would do for C flags... --w00t
    basMain.Users(TargetIndex).Modes = ""
    Call basFunctions.SendData("MODE " & Nick)
    Call basFunctions.SendMessage(basMain.Service(7).Nick, basMain.Users(Sender).Nick, Replace(Replies.AgentUserDeOpered, "%n", Nick))
End Sub

Private Sub FJoin(Sender As Integer, Nick As String, Channel As String)
    'Use SVSJOIN since we are forcing them.
    Call basFunctions.LogEventWithMessage(basMain.LogTypeNotice, basMain.Users(Sender).Nick & " AGENT FJOINed " & Nick & " to " & Channel)
    'SVSJOIN isn't enough to fjoin through +bikl. Do we
    'want this?
    basFunctions.SendData ":" + basMain.Service(7).Nick + " INVITE " + Nick + " " + Channel
    Call basFunctions.SendData("SVSJOIN " & Nick & " " & Channel)
End Sub

Private Sub FPart(Sender As Integer, Nick As String, Channel As String)
    'Use SVSPART since we are forcing them.
    Call basFunctions.LogEventWithMessage(basMain.LogTypeNotice, basMain.Users(Sender).Nick & " AGENT FPARTed " & Nick & " from " & Channel)
    Call basFunctions.SendData("SVSPART " & Nick & " " & Channel)
End Sub

Private Sub Deny(Sender As Integer, sCommand As String, Optional sParameter As String)
Dim SenderNick As String
Dim l As Integer
SenderNick = basFunctions.ReturnUserName(Sender)

Select Case UCase(sCommand)
  Case "HELP"
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "DENY LIST: List Deny Masks")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "DENY ADD Nick!User@Host: Add a mask to the DENY list")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "DENY DEL #: Remove Item # from the DENY list")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "DENY WIPE: Clear the DENY list")
  Case "LIST"
    For l = 1 To DenyMasks.Count
      Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, l & " " & DenyMasks(l))
    Next l
  Case "ADD"
    DenyMasks.Add sParameter
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, sParameter & " was added to the DENY list")
    Dim CurrentUser
    For l = LBound(Users) To UBound(Users)
      If Not Users(l).Nick = "" Then ' Check if there is a user occupying this id
      ' I NEED A BETTER WAY TO DO THIS, and it has to be FAST ^
        If IsDeny(l) And Not UCase(basMain.Users(l).IdentifiedToNick) = UCase(basMain.Config.ServicesMaster) Then ' <-- Make sure a Master is exempt
          ' Do all denys (to remove from the newly denied)
          With Users(l)
            .Access = 0
            If basMain.Config.ServerType = "UNREAL" Then ' Support SVSO? Its a better way of removing operflags
              Call basFunctions.SendData("SVSO " & .Nick & " -")
              If InStr(.Modes, "g") Then Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVS2MODE " & .Nick & " -g")
              If InStr(.Modes, "v") Then Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVS2MODE " & .Nick & " -v")
              ' These two flags arent cleared by svso for some reason:
              '  Recieve Infected DCC notices (v)
              '  Can Read and Send To GLOBOPS (g)
            Else ' SVSO Unsupported, Use SVSMODE
              If InStr(.Modes, "o") Then
                Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVSMODE " & .Nick & " -o")
                .Modes = Replace(.Modes, "o", "")
              End If
              If InStr(.Modes, "O") Then
                Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVSMODE " & .Nick & " -O")
                .Modes = Replace(.Modes, "O", "")
              End If
              If InStr(.Modes, "C") Then
                Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVSMODE " & .Nick & " -C")
                .Modes = Replace(.Modes, "C", "")
              End If
              If InStr(.Modes, "A") Then
                Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVSMODE " & .Nick & " -A")
                .Modes = Replace(.Modes, "A", "")
              End If
              If InStr(.Modes, "a") Then
                Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVSMODE " & .Nick & " -a")
                .Modes = Replace(.Modes, "a", "")
              End If
              If InStr(.Modes, "N") Then
                Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVSMODE " & .Nick & " -N")
                .Modes = Replace(.Modes, "N", "")
              End If
              ' Get a new copy of their modes using w00t's method
              basMain.Users(l).Modes = ""
              Call basFunctions.SendData("MODE " & .Nick)
            End If
          End With
        End If
      End If
    Next l
  Case "DEL"
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, DenyMasks(sParameter) & " was removed from the DENY list")
    DenyMasks.Remove sParameter
  Case "WIPE"
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "The DENY list was cleared")
    For l = 1 To DenyMasks.Count
      DenyMasks.Remove 1
    Next l
  Case Else
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "Unknown subcommand.")
End Select
End Sub

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
' DENY
If bSet And InStr("oOCAaN" & IIf(basMain.Config.ServerType = "UNREAL", "vg", ""), Char) Then
  If IsDeny(UserID) And Not UCase(basMain.Users(UserID).IdentifiedToNick) = UCase(basMain.Config.ServicesMaster) Then ' <-- Make sure a Master can OPER
    If basMain.Config.ServerType = "UNREAL" Then ' Support SVSO? Its a better way of removing operflags
      If Char = "O" Then Call basFunctions.SendData("SVSO " & Users(UserID).Nick & " -")
      ' ^ If verifys that only one SVSO is sent
      If Char = "v" Or Char = "g" Then Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVS2MODE " & Users(UserID).Nick & " -" & Char)
      ' These two flags arent cleared by svso for some reason:
      '  Recieve Infected DCC notices (v)
      '  Can Read and Send To GLOBOPS (g)
    Else ' SVSO Unsupported, Use SVSMODE
      Call basFunctions.SendData(":" & basMain.Service(7).Nick & " SVSMODE " & Users(UserID).Nick & " -" & Char)
      Users(UserID).Modes = Replace(Users(UserID).Modes, Char, "")
    End If
  End If
End If
' END DENY
End Sub

Public Function IsDeny(UserID As Integer) As Boolean
Dim UserHost As String, Denied As Boolean, l As Integer ' Change it to byte?
UserHost = Users(UserID).Nick & "!" & Users(UserID).UserName & "@" & Users(UserID).HostName
Denied = False
'if not denymasks.Count
For l = 1 To sAgent.DenyMasks.Count
  If UserHost Like CStr(Replace(Replace(DenyMasks(l), "[", "[[]"), "#", "[#]")) Then
    Denied = True
    Exit For
  End If
Next l
IsDeny = Denied
End Function
