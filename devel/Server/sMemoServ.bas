Attribute VB_Name = "sMemoServ"
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

'Add the following to basMain or whatever:
Public Const AccFlagCanMemoServAdmin As String * 1 = "e"
'Public Const AccFullAccess As String = "MmgoriIae"
Public Const MS_TOTALMEMOS = 19 'max of 20. (0-19) Should make user configurable?
'Memos(MS_TOTALMEMOS) As Memo           'Each user can have a max of 20 memos. (in userstructure)

'I put the memo type here for some reason...
Public Const ModVersion = "0.0.0.0"

Public Sub MemoservHandler(ByVal Cmd As String, ByVal Sender As User)
    'moo, memoserv yay.
    'created (screwed up) by w00t on 14/08/2004
    'Worked on 28/08/2004 again by w00t, since he got lazy on the 14th.
    'Added admin capabilities on 29/08 by... W00T!
    
    'Well, here's memoserv. It's a bit different to anope, etc... im still not sure
    'if its for the better or worse. Memo functions are available for other services,
    'so services themselves should be able to send/delete memos (either as services,
    'or for other users... Yay for apis.)
    '
    'Database stuff will need to be added when everything calms down, and this
    'atm relies on the recipient being online - defeating the purpose of memoserv.
    'still, at least I did some work again... and tried to avoid implicit declaration
    'of type too! --w00t
    
    'SEND <nick> <memo text and yeah...>
    'READ [nick, for admins] <memoid>
    'DEL [nick, for admins] <memoid/ALL>
    'LIST [nick, for admins]
    Dim Parameters() As String
    Dim SenderNick As String
    Dim i As Integer
    
    SenderNick = Sender.Nick
    Parameters() = Split(Cmd, " ")
    
    'Check that the nick is registered and identified.
    If (Not basFunctions.IsNickRegistered(SenderNick)) And (basMain.Users(Sender).IdentifiedToNick <> "") Then
        Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "You must be identified to a nickname!")
        Exit Sub
    End If
    
    Select Case UCase(Parameters(0))
        Case "HELP"
            'my god I love this helpsystem ;)
            Call basFunctions.CommandHelp(Sender, Parameters(), "memoserv", 10)
        Case "READ"
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            If UBound(Parameters) = 2 Then
                'Reading another persons memos.
                If Not Sender.HasFlag(AccFlagCanMemoServAdmin) Then
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "I SPIT AT YOU THUSLY!")
                    Exit Sub
                End If
                On Error Resume Next
                Sender = Users(Parameters(1))
                If Sender Is Nothing Or Not basFunctions.IsNickRegistered(Parameters(1)) Then
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Either the nick doesnt exist, or they are not registered. Moo.")
                    Exit Sub
                End If
                On Error GoTo 0
            End If
            With Sender
                If .Memos.Exists(CByte(Parameters(2))) Then
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Memo from " & .Memos(CByte(Parameters(2))).strSenderNick & ":")
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "" & .Memos(CByte(Parameters(2))).strMemoText)
                    'I guess we dont want them not to have an unread memo that appears read...
                    '.Memos(CByte(Parameters(2))).bllRead = True
                Else
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Hmm, it appears that memo doesnt exist. Bummer.")
                End If
            End With
        Case "SEND"
            'I am _NOT_ going to let admins send memos as someone else. If they want to
            'do this, then they can getpass the nick, identify to it and yeah. Alternativly
            'they can get some smart bugger to code it. --w00t
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            Dim TargetID As User
            Dim MemoBody As String
            Set TargetID = Users(Parameters(1))
            If TargetID = -1 Or Not basFunctions.IsNickRegistered(Parameters(1)) Then
                Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Either the nick doesnt exist, or they are not registered. Moo.")
                Exit Sub
            End If
            For i = 2 To UBound(Parameters)
                MemoBody = MemoBody & " " & Parameters(i)
            Next i
            'really shouldnt use trim, but im too lazy to redisign a loop ;p
            i = sMemoServ.AddMemo(TargetID, SenderNick, Trim(MemoBody))
            Call basFunctions.SendMessage(basMain.Service(10).Nick, TargetID.Nick, "You have recieved a new memo from " & SenderNick & ". Use /msg memoserv read " & i & " to read it.")
            Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Hmm. Memo sent, we hope.")
        Case "LIST"
            Dim SentOne As Boolean
            If UBound(Parameters) = 1 Then
                'Listing P(1)'s memos
                If Not Sender.HasFlag(AccFlagCanMemoServAdmin) Then
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "I SPIT AT YOU THUSLY!")
                    Exit Sub
                End If
                On Error Resume Next
                Set Sender = Users(Parameters(1))
                If Sender Is Nothing Or Not basFunctions.IsNickRegistered(Parameters(1)) Then
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Either the nick doesnt exist, or they are not registered. Moo.")
                    Exit Sub
                End If
                On Error GoTo 0
            End If
            'Ok. If we are listing ours, sender points to us. Else Sender is now the id of
            'the nick to list. Got it? ;p (yes, this could be done in the IF--ELSE statement,
            'but spacewise this is a bit more efficient). -w00t
            With basMain.Users(Sender)
                Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "START MEMOLIST:")
                For i = 0 To MS_TOTALMEMOS
                    If .Memos(i).strSenderNick <> "" Then
                        If .Memos(i).bllRead Then
                            Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Memo #" & i & " from " & .Memos(i).strSenderNick & " Read")
                        Else
                            Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Memo #" & i & " from " & .Memos(i).strSenderNick & " UNRead")
                        End If
                        SentOne = True
                    End If
                Next i
                If Not SentOne Then
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "No memos stored.")
                End If
                Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "END MEMOLIST")
            End With
        Case "DEL"
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            If UBound(Parameters) = 2 Then
                If Not Sender.HasFlag(AccFlagCanMemoServAdmin) Then
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "I SPIT AT YOU THUSLY!")
                    Exit Sub
                End If
                Set Sender = Users(Parameters(1))
                If Sender Is Nothing Or Not basFunctions.IsNickRegistered(Parameters(1)) Then
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Either the nick doesnt exist, or they are not registered. Moo.")
                    Exit Sub
                End If
                Parameters(1) = UCase(Parameters(2))
                If Parameters(1) = "ALL" Then
                    Call sMemoServ.DelMemo(Sender, 255)
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "All your memos have been deleted.")
                    Exit Sub
                End If
                With basMain.Users(Sender)
                    If .Memos(CByte(Parameters(2))).strSenderNick <> "" Then
                        Call sMemoServ.DelMemo(Sender, CInt(Parameters(2)))
                        Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Memo " & Parameters(1) & " has been deleted.")
                    Else
                        Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Memo " & Parameters(1) & " does not exist.")
                    End If
                End With
            Else
                'Duplicate code is SO passe. There is probably another way to do this.
                Parameters(1) = UCase(Parameters(1))
                If Parameters(1) = "ALL" Then
                    Call sMemoServ.DelMemo(Sender, 255)
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "All your memos have been deleted.")
                    Exit Sub
                End If
                With basMain.Users(Sender)
                    If .Memos(CByte(Parameters(1))).strSenderNick <> "" Then
                        Call sMemoServ.DelMemo(Sender, CByte(Parameters(1)))
                        Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Memo " & Parameters(1) & " has been deleted.")
                    Else
                        Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Memo " & Parameters(1) & " does not exist.")
                    End If
                End With
            End If

    End Select
End Sub

Public Function AddMemo(ByVal UserID As User, ByVal SenderNick As String, ByVal MemoBody As String) As Memo
    Dim i As Integer
    'Add a memo to UserID from SenderNick (NOT ID SO SERVICES CAN SEND MEMOS!)
    'Returns memoid on success.
    Dim m As Memo
    Set m = New Memo
    With m
        .bllRead = False
        .dblTimeSent = basUnixTime.GetTime
        .strMemoText = MemoBody
        .strSenderNick = SenderNick
        Set AddMemo = m
    End With
    If UserID.Memos.Count > MS_TOTALMEMOS + 1 Then
        'If we get here, they have no free memos. Bummer.
        Set AddMemo = Nothing
    Else
        UserID.Memos.Add m
    End If
End Function

Public Function DelMemo(ByVal UserID As User, ByVal MemoID As Variant) As Integer
    Dim i As Integer
    'Delete a memo with id MemoID from user UserID. If MemoID=-1, then delete all memos
    'for target user.
    
    'At the moment, no checking is done and therefore no errors will be returned.
    'In the future, 1 will indicate success, any other value indicates some kind of error.
    If MemoID <> -1 Then
        UserID.Memos.Remove MemoID
    Else
        While UserID.Memos.Count > 0: UserID.Memos.Remove 1: Wend
    End If
    'Yay!
    DelMemo = 1
End Function
