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

Public DB As Collection
Public Const ModVersion = "0.2.0.0"


Public Sub LoadData(ByVal conn As Connection)
    Set DB = ReadTableIntoCollection(conn, "MemoServ")
    Dim idx As Long, subcol As Collection
    'Key each subcollection under it's RECIEVER index. (guess this is a good idea lol)
    For idx = 1 To DB.Count
        Set subcol = DB(idx)
        DB.Remove idx
        DB.Add subcol, subcol("to"), idx
    Next idx
End Sub

Public Sub SaveData(ByVal conn As Connection)
    'Great. Now we're writing to the database. This aint as easy :| .
    Dim cn As Connection 'To enable direct SQL execution for w00t :p
    Dim rs As Recordset
    Dim rs2 As Recordset
    Call basFunctions.LogEvent(basMain.LogTypeDebug, "sMemoServ: SaveData: Entering, acquiring connection...")
    Set cn = basDBAccess.OpenDB(basMain.Config.ConnectString)
    Set rs = GetTable(conn, "MemoServ")
    Call basFunctions.LogEvent(basMain.LogTypeDebug, "sMemoServ: SaveData: Connection acquired, Updating...")
    
    Dim subcol As Collection
    For Each subcol In DB
        Set rs2 = cn.Execute("SELECT * FROM `memoserv` WHERE `memo_id` = " & subcol("memo_id"))
        'You know, the above probably isn't the most efficient way to do things...
        If Not rs2 Then
            'New memo.
            Debug.Print "new memo not in db"
            cn.Execute "INSERT INTO `MemoServ` (`from`,`read`,`text`,`to`,`memo_id`) VALUES ('" & subcol("from") & "','" & CInt(subcol("read")) & "','" & subcol("text") & "','" & subcol("to") & "','" & subcol("memo_id") & "')"
        Else
            'Memo exists in db, ignore.
            Debug.Print "existing memo already in db"
        End If
    Next subcol
    'Now we need to look for memos in the database that we don't have in the collection - these
    'were dropped between updates, so we need to remove them from the DB or they get mysteriously
    'resent :) .
    With rs
        On Error Resume Next
        .MoveFirst
        On Error GoTo 0
        While Not .EOF
            'Now see if the current record is in our memory cache.
            On Error Resume Next
            Set subcol = DB(.Fields("memo_id"))
            If Err.Number = 9 Then
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
    Call basFunctions.LogEvent(basMain.LogTypeDebug, "sMemoServ: SaveData: Finished.")
End Sub

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
    If (Not basFunctions.IsNickRegistered(SenderNick)) And (Sender.IdentifiedToNick <> "") Then
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
            Dim iMemo As Integer
            If UBound(Parameters) = 2 Then
                'Reading another persons memos.
                If Not Sender.HasFlag(AccFlagCanMemoServAdmin) Then
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, Replies.InsufficientPermissions)
                    Call basFunctions.SendNumeric(SenderNick, 481, ":Permission denied - Insufficient services access.")
                    Exit Sub
                End If
                On Error Resume Next
                Sender = Users(Parameters(1))
                If Sender Is Nothing Or Not basFunctions.IsNickRegistered(Parameters(1)) Then
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Either the nick doesnt exist, or they are not registered. Moo.")
                    Exit Sub
                End If
                On Error GoTo 0
                iMemo = Parameters(2)
            Else
                iMemo = Parameters(1)
            End If
            With Sender
                If .Memos.Exists(iMemo) Then
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Memo from " & .Memos(iMemo).strSenderNick & ":")
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "" & .Memos(iMemo).strMemoText)
                    'I guess we dont want them not to have an unread memo that appears read...
                    If SenderNick = Sender.Nick Then .Memos(iMemo).bllRead = True
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
            Dim MemoBody As String, m As Memo
            Set TargetID = Users(Parameters(1))
            If TargetID Is Nothing Or Not basFunctions.IsNickRegistered(Parameters(1)) Then
                Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Either the nick doesnt exist, or they are not registered. Moo.")
                Exit Sub
            End If
            For i = 2 To UBound(Parameters)
                MemoBody = MemoBody & " " & Parameters(i)
            Next i
            'really shouldnt use trim, but im too lazy to redisign a loop ;p
            Set m = sMemoServ.AddMemo(TargetID, SenderNick, Trim(MemoBody))
            Call basFunctions.SendMessage(basMain.Service(10).Nick, TargetID.Nick, "You have recieved a new memo from " & SenderNick & ". Use /msg memoserv read " & TargetID.Memos.IndexOf(m) & " to read it.")
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
            With Sender
                Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "START MEMOLIST:")
                For i = 1 To .Memos.Count
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
                With Sender
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
                    If Not .Memos.Exists(CByte(Parameters(1))) Then
                        Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Memo " & Parameters(1) & " does not exist.")
                        Exit Sub
                    End If
                    Call sMemoServ.DelMemo(Sender, CByte(Parameters(1)))
                    Call basFunctions.SendMessage(basMain.Service(10).Nick, SenderNick, "Memo " & Parameters(1) & " has been deleted.")
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
        Dim newcol As Collection
        Dim Rand As Double '...
        Set newcol = New Collection
        Randomize Timer
        Rand = Int((900000000 * Rnd) + 1)
        'we SHOULD check for duplicates in the future!
        '(unless someone can think of a better way of doing this?)
        '(remember, rand is ment to be unique.. admittedly, the chance
        'of duplicates is low, but 1/1000000000000 is too high odds for me...)
        newcol.Add SenderNick, "from"
        newcol.Add False, "read"
        newcol.Add MemoBody, "text"
        newcol.Add UserID.Nick, "to"
        newcol.Add Rand, "memo_id"
        DB.Add newcol
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
        'While UserID.Memos.Count <> 1
        'remove "1" 255 times... I guess this works
        For i = 0 To 253
            UserID.Memos.Remove 1
        Next i
        'Wend
    End If
    'Yay!
    DelMemo = 1
End Function
