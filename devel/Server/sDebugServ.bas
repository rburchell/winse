Attribute VB_Name = "sDebugServ"
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
Public Const ModVersion = "1.0.0.0"

Public Sub DebugservHandler(Cmd As String, Sender As Integer)
    Dim Parameters() As String
    Dim SenderNick As String
    Dim i As Variant 'i am soooo naughty >:)
    
    SenderNick = basFunctions.ReturnUserName(Sender)
    Parameters() = Split(Cmd, " ") 'Way better ;p
    
    Select Case UCase(Parameters(0))
        Case "MYEMAIL"
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, basMain.Users(Sender).EMail)
        Case "MYACCESS"
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, CStr(basMain.Users(Sender).Access))
        Case "MYABUSETEAMSTATUS"
            i = basFunctions.IsAbuseTeamMember(Sender)
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, CStr(i))
        Case "MYMODES"
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, basMain.Users(Sender).Modes)
        Case "INDEXOFUSER"
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, ReturnUserIndex(Parameters(SenderNick)))
            Else
                Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, ReturnUserIndex(Parameters(1)))
            End If
        Case "INDEXOFCHANNEL"
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, "Not enough parameters.")
            Else
                Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, ReturnChannelIndex(Parameters(1)))
            End If
        Case "DUMPUSER"
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, "Not enough parameters.")
            Else
                If Not IsNumeric(Parameters(1)) Then
                    Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, "Invalid syntax.")
                Else
                    Call DumpUser(SenderNick, Parameters(1))
                End If
            End If
        Case "DUMPCHANNEL"
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, "Not enough parameters.")
            Else
                If Not IsNumeric(Parameters(1)) Then
                    Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, "Invalid syntax.")
                Else
                    Call DumpChannel(SenderNick, Parameters(1))
                End If
            End If
        Case "HELP"
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, "DebugServ:")
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, "If you don't know what debugserv is, then at the moment you shouldn't be using these services...")
        Case Else
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, Replies.UnknownCommand)
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

End Sub

Private Sub DumpLine(ByVal DumpTo As String, ByVal Line As String)
    'Because most clients will open a seperate window
    'for PRIVMSG, we will take advantage of this for
    'dumping.
    PrivMsg Service(11).Nick, DumpTo, Line
End Sub

Private Sub DumpUser(ByVal DumpTo As String, ByVal ID As Integer)
    If ID = 32767 Then
        SendMessage Service(11).Nick, DumpTo, "No such user."
        Exit Sub
    ElseIf Users(ID).Nick = "" Then
        SendMessage Service(11).Nick, DumpTo, "No such user."
        Exit Sub
    End If
    With Users(ID)
        DumpLine DumpTo, "Nick: " + .Nick
        DumpLine DumpTo, "E-Mail: " + .EMail
        DumpLine DumpTo, "Password: " + .Password
        DumpLine DumpTo, "MemoID: " + CStr(.MemoID)
        DumpLine DumpTo, "Modes: " + .Modes
        DumpLine DumpTo, "E-Mail Visible? " + IIf(.HideEMail, "No", "Yes")
        DumpLine DumpTo, "Acess: " + .Access
        DumpLine DumpTo, "Flood Level: " + CStr(.Requests)
        Select Case .MsgStyle
            Case True
                DumpLine DumpTo, "Message Type: NOTICE"
            Case False
                DumpLine DumpTo, "Message Type: PRIVMSG"
        End Select
        DumpLine DumpTo, "Abuse Team: " + IIf(.AbuseTeam, "Yes", "No")
        DumpLine DumpTo, "Last IDENTIFY: " + .IdentifiedToNick
        DumpLine DumpTo, "On Channels:"
        Dim vChan As Variant
        For Each vChan In .Channels
            DumpLine DumpTo, "  " + Channels(vChan).Name
        Next vChan
        DumpLine DumpTo, "End of Channels."
        DumpLine DumpTo, "Signed on: " + CStr(.SignOn)
        DumpLine DumpTo, "Services Stamp: " + CStr(.SvsStamp)
        DumpLine DumpTo, "User Name: " + .UserName
        DumpLine DumpTo, "Real Host: " + .HostName
        DumpLine DumpTo, "Real Name: " + .RealName
        DumpLine DumpTo, "VirtualHost: " + .VirtHost
        DumpLine DumpTo, "On Server: " + .Server
    End With
    DumpLine DumpTo, "End of Dump."
End Sub

Private Sub DumpChannel(ByVal DumpTo As String, ByVal ID As Integer)
    If ID = 32767 Then
        SendMessage Service(11).Nick, DumpTo, "No such channel."
        Exit Sub
    ElseIf Channels(ID).Name = "" Then
        SendMessage Service(11).Nick, DumpTo, "No such channel."
        Exit Sub
    End If
    With Channels(ID)
        DumpLine DumpTo, "Name: " + .Name
        DumpLine DumpTo, "Topic is: " + .Topic
        DumpLine DumpTo, "Set by " + .TopicSetBy + " on " + CStr(.TopicSetOn)
        DumpLine DumpTo, "Password: " + .FounderPassword
        DumpLine DumpTo, "ModeLock: " + .MLock
        DumpLine DumpTo, "Access List:"
        Dim i As Integer
        On Error Resume Next
        For i = 0 To UBound(.AccessList)
            With .AccessList(i)
                DumpLine DumpTo, .Nick + " flags: " + .Access
            End With
        Next i
        On Error GoTo 0
        DumpLine DumpTo, "End of Access List"
        DumpLine DumpTo, "Modes: " + .Modes
        DumpLine DumpTo, "Users on channel:"
        For i = 1 To .Users.Count
            DumpLine DumpTo, Users(.Users(i)).Nick + " " + .UsersModes(CStr(.Users(i)))
        Next i
        DumpLine DumpTo, "End of users."
        DumpLine DumpTo, "Channel Ban List"
        For i = 1 To .Bans.Count
            DumpLine DumpTo, .Bans(i)
        Next i
        DumpLine DumpTo, "End of Channel Ban List"
        DumpLine DumpTo, "Exception List"
        For i = 1 To .Excepts.Count
            DumpLine DumpTo, .Excepts(i)
        Next i
        DumpLine DumpTo, "End of Channel Exception List"
        DumpLine DumpTo, "Invitation List"
        For i = 1 To .Invites.Count
            DumpLine DumpTo, .Invites(i)
        Next i
        DumpLine DumpTo, "End of Channel Inivitation List"
        DumpLine DumpTo, "Channel key is: " + IIf(.ChannelKey <> "", .ChannelKey, "Not Set")
        DumpLine DumpTo, "Flood Proection: " + IIf(.FloodProtection <> "", .FloodProtection, "Not Set")
        DumpLine DumpTo, "Channel Limit is: " + IIf(.OverflowLimit > 0, CStr(.OverflowLimit), "Not Set")
        DumpLine DumpTo, "Channel Link is: " + IIf(.OverflowChannel <> "", .OverflowChannel, "Not Set")
    End With
    DumpLine DumpTo, "End of Dump."
End Sub

Public Sub HandleTick(ByVal Interval As Single)

End Sub

