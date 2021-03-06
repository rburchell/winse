Attribute VB_Name = "sAgent"
' Winse - WINdows SErvices. IRC services for Windows.
' Copyright (C) 2004 w00t[w00t@netronet.org]
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
'
' Contact Maintainer: w00t[w00t@netronet.org]

Option Explicit
Public Const ModVersion = "0.0.2.2"

Public Sub AgentHandler(Cmd As String, Sender As Integer)
    'Agent does NOT require a user to be opered. This is by design. (Any user can be abuseteam,
    'so basically meaning "behave, big brother is watching..."
    'It instead requires the AbuseTeam flag be set on the Sender.
    '---*NOTE*--- AbuseTeam should be _very_ restricted.
    
    'Agent also doesnt require services access in general.
    
    Dim Parameters() As String
    Dim Message As String
    ReDim Parameters(0) As String
    Dim Cmdcopy As String
    
    Dim SenderNick As String
    Dim Spacer As Byte
    Dim Elements As Integer
    Dim i As Integer
    SenderNick = basFunctions.ReturnUserName(Sender)
       
    'We shouldnt need either oper status or services access to use agent...
    'just be on the abuse team. --w00t
    
    'Considering that Service Master (?) can probably
    'add/remove Abuse Team members, we may as well give
    'him automatic access here, don't you think?
    ' - aquanight

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
    
    'Moved checks to stop wasting CPU on a request that was going to be ignored.
    
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
                Message = Message & " " & Parameters(i)
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
                Message = Message & " " & Parameters(i)
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
                Message = Message & " " & Parameters(i)
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
            Call sAgent.UnIdentify(Sender, Parameters(1))
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
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  UNIDENTIFY - Makes user with nick specified not be identified.")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  *ZLINE      - Add a global Z:LINE to the network")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, " ")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  Notice: For more Information type /msg Agent HELP command")
    Call basFunctions.SendMessage(basMain.Service(7).Nick, SenderNick, "  Notice: All commands sent to Agent are logged!")
End Sub

Private Sub Version(Sender As Integer)
    Call basFunctions.SendMessage(basMain.Service(7).Nick, basFunctions.ReturnUserName(Sender), AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(7).Nick & "[" & sAgent.ModVersion & "]")
End Sub

Private Sub Exit_(Sender As Integer, Nick As String, Message As String)
    Call basFunctions.LogEventWithMessage(basMain.Users(Sender).Nick & " used AGENT EXIT " & Nick & " with message " & Message)
    basFunctions.SendData ("SVSKILL " & Nick & " :" & LTrim(Message))
End Sub

Private Sub UMode(Sender As Integer, Nick As String, Modes As String)
    Dim Target As Integer
    Target = basFunctions.ReturnUserIndex(Nick)
    Call basFunctions.LogEventWithMessage(basMain.Users(Sender).Nick & " set modes " & Modes & " on " & Nick)
    Call basFunctions.SetUserModes(Target, Modes)
    Call basFunctions.SendData("SVS2MODE " & Nick & " " & Modes)
End Sub

Private Sub Nick(Sender As Integer, OldNick As String, NewNick As String)
    'IMHO, we really ought to have a check to make sure that users cant change
    'the nick of those with access greater than them, but that can wait for now.
    '--w00t
    'They're _ABUSE TEAM_. I can understand such a check
    'for other Abuse Team members, but otherwise...
    Call basFunctions.LogEventWithMessage(basMain.Users(Sender).Nick & " used AGENT NICK " & OldNick & " " & NewNick)
    Call basFunctions.ForceChangeNick(Sender, OldNick, NewNick)
End Sub

Private Sub Kill(Sender As Integer, Nick As String, Message As String)
    Call basFunctions.LogEventWithMessage(basMain.Users(Sender).Nick & " used AGENT KILL " & Nick & " with reason " & Message)
    Call basFunctions.SendData(":" & basMain.Service(7).Nick & " KILL " & Nick & " :" & LTrim(Message) & " (" & basFunctions.ReturnUserName(Sender) & ")")
End Sub

Private Sub Kick(Sender As Integer, Nick As String, Channel As String, Message As String)
    Call basFunctions.LogEventWithMessage(basMain.Users(Sender).Nick & " used AGENT KICK " & Nick & " from " & Channel & " with reason " & Message)
    Call basFunctions.SendData(":" & basMain.Service(7).Nick & " KICK " & Nick & " " & Channel & " :" & Message & " (" & basFunctions.ReturnUserName(Sender) & ")")
End Sub

Private Sub UnIdentify(Sender As Integer, Nick As String)
    Dim TargetIndex As Variant
    TargetIndex = basFunctions.ReturnUserIndex(Nick)
    If TargetIndex = -1 Then
        Call basFunctions.SendMessage(basMain.Service(7).Nick, basMain.Users(Sender).Nick, Replies.UserDoesntExist)
    End If
    Call basFunctions.LogEventWithMessage(basMain.Users(Sender).Nick & " used AGENT UNIDENTIFY " & Nick)
    basMain.Users(TargetIndex).IdentifiedToNick = ""
    basMain.Users(TargetIndex).Access = 0
    basMain.Users(TargetIndex).AbuseTeam = False
End Sub

Private Sub FJoin(Sender As Integer, Nick As String, Channel As String)
    Call basFunctions.LogEventWithMessage(basMain.Users(Sender).Nick & " AGENT FJOINed " & Nick & " to " & Channel)
    Call basFunctions.SendData("SVSJOIN " & Nick & " " & Channel)
End Sub

Private Sub FPart(Sender As Integer, Nick As String, Channel As String)
    Call basFunctions.LogEventWithMessage(basMain.Users(Sender).Nick & " AGENT FPARTed " & Nick & " from " & Channel)
    Call basFunctions.SendData("SVSPART " & Nick & " " & Channel)
End Sub
