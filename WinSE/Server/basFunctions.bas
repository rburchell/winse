Attribute VB_Name = "basFunctions"
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

'Explicitly declaring our types would be nice :) Makes
'moving to Option Strict level of coding SO much easier
' - aquanight
Public Function ParseBuffer(ByVal Buffer As String) As Variant
    'Splits a sentance or whatever into an array of words.
    'These won't be needed - aquanight
    'Dim CrLf As Integer
    'Dim Elements As Integer
    'Dim Parameters() As String
    'ReDim Parameters(0)
    'Dim CurrentCmd As String
    If Left(Buffer, 1) = ":" Then
        Buffer = Right(Buffer, Len(Buffer) - 1)
    End If
    'Did you know a VB function can do this for you? :)
    ' - aquanight
    ParseBuffer = Split(Buffer, " ")
'    Do While InStr(Buffer, " ") <> 0
'        CrLf = InStr(Buffer, " ")
'        If CrLf <> 0 Then
'            Parameters(Elements) = Left(Buffer, CrLf - 1)
'        Else
'            Parameters(Elements) = Buffer
'        End If
'        Buffer = Right(Buffer, Len(Buffer) - CrLf)
'        Elements = Elements + 1
'        ReDim Preserve Parameters(Elements)
'    Loop
'    Parameters(Elements) = CurrentCmd
'    ParseBuffer = Parameters
End Function

Public Sub LogEvent(EventToLog As String)
    'Logs given event to file.
    
    'not written yet :P

    'Until it is, let's have it be a Sub, unless it
    'needs to return a value :) - aquanight
End Sub

Public Sub LogEventWithMessage(EventToLog As String)
    'Same as LogEvent, _but_ sends a message to all with services access too.
    Call basFunctions.NotifyAllUsersWithServicesAccess(EventToLog)
    Call basFunctions.LogEvent(EventToLog)
End Sub

Public Sub ForceChangeNick(Sender As Integer, OldNick As String, NewNick As String)
    'Now uses unix timestamp --w00t
    Dim TimeStamp As Long
    TimeStamp = basUnixTime.GetTime
    Call basFunctions.SendData("SVSNICK " & OldNick & " " & NewNick & " " & TimeStamp)
End Sub

Public Function IsChanRegistered(ChanName As String) As Boolean
    Dim Password As String
    'If we have a password, we must be registered ;)
    Password = basFileIO.GetInitEntry("channels.db", ChanName, "Password")
    'If Password <> "" Then IsChanRegistered = True
    'Booleans rock :) - aquanight
    IsChanRegistered = (Password <> "")
End Function

Public Function IsNickRegistered(NickName As String)
    Dim Password As String
    'If we have a password, we must be registered ;)
    Password = basFileIO.GetInitEntry("users.db", NickName, "Password")
    'If Password <> "" Then IsNickRegistered = True
    'Booleans rock :) - aquanight
    IsNickRegistered = (Password <> "")
End Function

Public Sub IntroduceClient(Nick As String, Host As String, Name As String, Optional IsBot As Boolean = False)
'At long bloody last I found the nick syntax required after trawling Unreal sourcecode
'for around 2 hours...
'NICKv1
'**  parv[0] = sender prefix
'**  parv[1] = nickname
'**      parv[2] = hopcount
'**      parv[3] = timestamp
'**      parv[4] = username
'**      parv[5] = hostname
'**      parv[6] = servername
'**      parv[7] = servicestamp

'And USER...
'**  parv[0] = sender prefix
'**  parv[1] = username (login name, account)
'**  parv[2] = client host name (used only from other servers)
'**  parv[3] = server host name (used only from other servers)
'**  parv[4] = users real name info
    Dim MyTime As String
    MyTime = basUnixTime.GetTime
    'we directly send the nick and user commands, as buffering stuffs
    'things up.
    Call frmServer.tcpServer.Send("NICK " & Nick & " 1 " & MyTime & " " & Name & " " & Host & " " & ServerName & " " & Nick & vbCrLf)
    Call frmServer.tcpServer.Send("USER " & Nick & " " & Name & " " & ServerName & " " & Name & vbCrLf)
    'THESE ARENT GETTING SENT PROPERLY
    'Don't send SVSMODE for clients on your server.
    'SVSMODE suggests forcefully changing modes for
    'other clients, which isn't necessary. - aquanight
'    If IsBot = False Then
'        Call basFunctions.SendData("SVSMODE " & Nick & " +dqS")
'    Else
'        Call basFunctions.SendData("SVSMODE " & Nick & " +qS")
'    End If
    basFunctions.SendData ":" & Nick & " MODE " & Nick & " +qS"
    If Not IsBot Then basFunctions.SendData ":" & Nick & " MODE " & Nick & " +d"
    'This actually causes Unreal to set +xt for the user
    'which may not be what we want. Since we send our
    '"vhost" as the real host in User, why is this
    'necessary anyway? - aquanight
    'Call basFunctions.SendData(":" & Nick & " SETHOST " & Host)
End Sub

Public Sub JoinServicesToChannel(Sender As Integer, Channel As String)
    'aquanight: This may need to be bumped to a larger
    'type to satisify Option Strict when we .NET-ize
    'it :) .
    Dim i As Byte '>255 services... ^@&%*^ hope not.
    Dim Nick, Host, Name As String
    For i = 0 To basMain.TotalServices
        Nick = basMain.Service(i).Nick
        Host = basMain.Service(i).Hostmask
        Name = basMain.Service(i).Name
        Call basFunctions.SendData(":" & Nick & " JOIN " & Channel)
        'Making services channel owner doesn't just
        'seem very good to me, dunno why. Anyway, I
        'think just admin is ok, especially since owner
        'status isn't really needed anyway :) .
        'Also, if we are to be cross-IRCd compatible,
        'we really shouldn't rely on +a or +q being
        'available. For example, what if I connected
        'this to Hybrid (yuck)? :) - aquanight
        'Call basFunctions.SendData(":" & Nick & " MODE " & Channel & " +qo " & Nick & " " & Nick)
        basFunctions.SendData ":" & Nick & " MODE " & Channel & " +ao " & Nick & " " & Nick
    Next i
End Sub

Public Sub PartServicesFromChannel(Sender As Integer, Channel As String)
    'See JoinServicesToChannel comment on this.
    ' - aquanight
    Dim i As Byte '>255 services... ^@&%*^ hope not.
    Dim Nick, Host, Name As String
    For i = 0 To basMain.TotalServices
        Nick = basMain.Service(i).Nick
        Host = basMain.Service(i).Hostmask
        Name = basMain.Service(i).Name
        Call basFunctions.SendData(":" & Nick & " PART " & Channel)
    Next i
End Sub

Public Function ReturnUserServicesPermissions(UserId As Integer) As Byte
    'Determines services permissions through a number of different factors.
    If basMain.Users(UserId).Nick = "" Then
        ReturnUserServicesPermissions = -1
        Exit Function
    End If
    If UCase(basMain.Users(UserId).IdentifiedToNick) = UCase(basMain.ServicesMaster) Then
        ReturnUserServicesPermissions = 100
        Exit Function
    End If
    ReturnUserServicesPermissions = basMain.Users(UserId).Access
End Function

Public Function IsAbuseTeamMember(UserId As Integer) As Boolean
    'Don't you love Booleans? :D - aquanight
    IsAbuseTeamMember = basMain.Users(UserId).AbuseTeam
'    If basMain.Users(UserId).AbuseTeam = True Then
'        IsAbuseTeamMember = True
'    Else
'        IsAbuseTeamMember = False
'    End If
End Function

Public Function IsServicesAdmin(UserId As Integer) As Boolean
    'Yawn - aquanight
    IsServicesAdmin = (InStr(basMain.Users(UserId).Modes, "a") <> 0)
'    If InStr(basMain.Users(UserId).Modes, "a") <> 0 Then
'        IsServicesAdmin = True
'    Else
'        IsServicesAdmin = False
'    End If
End Function

Public Function IsOper(UserId As Integer) As Boolean
    'Yawn again - aquanight
    IsOper = (InStr(basMain.Users(UserId).Modes, "o") <> 0)
'    If InStr(basMain.Users(UserId).Modes, "o") <> 0 Then
'        IsOper = True
'    Else
'        IsOper = False
'    End If
End Function

Public Function GetTarget(Buffer As String) As String
'    Dim FirstSpace As Byte
'    Dim SecondSpace As Byte
'    Dim Cmd As String
    'What the heck? I've never seen this command before
    ' - aquanight
    On Local Error Resume Next
'    FirstSpace = InStr(Buffer, " ") - 1
'    SecondSpace = InStr(FirstSpace + 2, Buffer, " ")
'    Cmd = Right(Buffer, Len(Buffer) - SecondSpace)
'    FirstSpace = InStr(Cmd, " ") - 1
'    GetTarget = Left(Cmd, FirstSpace)
    Dim s As Variant
    s = Split(Buffer, " ")
    GetTarget = IIf(Left(s(0), 1) = ":", s(2), s(1))
End Function

Public Function GetSender(Buffer As String) As String
'    Dim FirstSpace As Byte
    'Dim GetSender As String
'    FirstSpace = InStr(Buffer, " ") - 1
'    GetSender = Right(Left(Buffer, FirstSpace), Len(Left(Buffer, FirstSpace)) - 1)
    'Boy do I love split :) - aquanight
    'This is actually probably a little better since
    'it will return empty if no sender was actually
    'specified in the received command
    '(maybe make it return basMain.UplinkName?)
    Dim s As Variant
    s = Split(Buffer, " ")
    GetSender = IIf(Left(s(0), 1) = ":", Mid(s(0), 2), "")
End Function

Public Sub SendData(Buffer As String)
    'With the new socket library, buffering might not
    'be needed anymore, but for now I think it's ok to
    'leave alone - aquanight
    basMain.Buffer(basMain.BufferElements) = Buffer & vbCrLf
    basMain.BufferElements = basMain.BufferElements + 1
End Sub

Public Sub PrivMsg(Sender As String, Reciever As String, Message As String)
    basFunctions.SendData (":" & Sender & " PRIVMSG " & Reciever & " :" & Message)
End Sub

Public Sub Notice(Sender As String, Reciever As String, Message As String)
    basFunctions.SendData (":" & Sender & " NOTICE " & Reciever & " :" & Message)
End Sub

Public Sub SendMessage(Sender As String, Reciever As String, Message As String)
    Dim UserId As Integer
    'Wrapper for notice\privmsg. Checks which we should use, and uses it.
    UserId = basFunctions.ReturnUserIndex(Reciever)
    If UserId = -1 Then Exit Sub
    Select Case basMain.Users(UserId).MsgStyle
        Case True
            'Notice
            Call basFunctions.Notice(Sender, Reciever, Message)
        Case False
            'msg
            Call basFunctions.PrivMsg(Sender, Reciever, Message)
    End Select
End Sub

'aquanight: Changing Message to ByVal because we need to
'do some multiliation to it to send KILLs properly.
Public Sub KillUser(UserId As Integer, ByVal Message As String, Optional Killer As String = "")
    If UserId >= 0 Then
        'I think some kind of validation should be put
        'here... because we could theoretically call
        'KillUser with a positive UserId that is still
        'invalid. It shouldn't happen, but it'd be
        'good to know :) . -aquanight
        If basMain.Users(UserId).Nick = "" Then
            'For now, I'm throwing a Bad Call Error
            'Yes it's old fashioned, but if it where
            'my way, it'd be Throw New... you get the
            'idea :) . - aquanight
            Error 5
        End If
        'Ever heard of kill paths? Yep, we need to
        'specify the Killer :) . - aquanight
        If Killer = "" Then
            Killer = basMain.ServerName
            Message = Killer & " (" & Message & ")"
        Else
            Message = basMain.ServerName & "!" & Killer & " (" & Message & ")"
        End If
        basFunctions.SendData (": " + Killer + " KILL " & basMain.Users(UserId).Nick & " :" & Message)
        With basMain.Users(UserId)
            'Blank their record
            .Access = 0
            .Modes = ""
            .Nick = ""
            .Requests = 0
            .MsgStyle = False
        End With
        If UserId = basMain.TotalUsers - 1 Then basMain.TotalUsers = basMain.TotalUsers - 1
    Else
        'Services dont know them :| Shouldnt happen!!!!!!
        'aquanight: In that case, let's throw an error.
        Error 5
    End If
End Sub

Public Function ReturnUserName(UserId As Integer) As String
    'If return "" then user doesnt exist.
    If UserId = -1 Then Exit Function
    ReturnUserName = basMain.Users(UserId).Nick
End Function

Public Sub GlobalMessage(Message As String)
    Dim i As Integer
    Dim Reciever As String
    Dim Sender As String
    Sender = Service(8).Nick
    
    For i = 0 To basMain.TotalUsers
        Reciever = basMain.Users(i).Nick
        Call basFunctions.SendMessage(Sender, Reciever, Message)
        DoEvents
    Next i
End Sub

Public Sub CheckFloodLevel(UserId As Integer)
    'Flood level. Goes up by 1 on each request.
    'When it hits 5, a warning. 10, a kill. 20, a gline (unless >= services admin)
    'Flood level goes down by 1 every 5 seconds??
    'aquanight: The GLINE'ing aspect will be pretty...
    'wierd considering that you KILL the user before you
    'get to the GLINE stage, but I don't see this
    'implemented anywhere, so that's ok :) .
    With basMain.Users(UserId)
        If .Requests >= 8 Then
            'kill
            Call basFunctions.KillUser(UserId, Replies.ServiceFloodKill)
        End If
        If .Requests = 4 Then
            'warn
            Call basFunctions.SendMessage(basMain.Service(8).Nick, .Nick, Replies.ServiceFloodWarning)
        End If
    End With
    'Increase flood requests
    basMain.Users(UserId).Requests = basMain.Users(UserId).Requests + 1
End Sub

Public Function ReturnUserIndex(NickName As String) As Integer
    Dim i As Integer
    'Dim Found As Boolean
    'DOES (sorta) return a failure. Will return NOTEXIST if user doesnt exist.
    'Changed to avoid declaring stuff as variant, now returns -1
    For i = 0 To basMain.TotalUsers
        With basMain.Users(i)
            If UCase(NickName) = UCase(.Nick) Then
                ReturnUserIndex = i
                'Blah - aquanight
                Exit Function
'                Found = True
'                Exit For
            End If
        End With
        DoEvents
    Next i
    ReturnUserIndex = -1
End Function

Public Function ReturnChannelIndex(ChannelName As String)
    Dim i As Integer
    'Dim Found As Boolean
    'DOES (sorta) return a failure. Will return NOTEXIST if user doesnt exist.
    'Changed to avoid declaring stuff as variant, now returns -1
    For i = 0 To basMain.TotalChannels
        With basMain.Channels(i)
            If UCase(ChannelName) = UCase(.Name) Then
                ReturnChannelIndex = i
                Exit Function
'                Found = True
'                Exit For
            End If
        End With
        DoEvents
    Next i
    ReturnChannelIndex = -1
End Function

Public Sub SquitServices(Optional ByVal Message As String = "")
    Call basFunctions.SendData("SQUIT " & basMain.UplinkName & IIf(Message <> "", " :" & Message, ""))
End Sub

'A routine for if w00t gets around to doing OperServ
'JUPE. It can use this to make sure the JUPE'd server
'is not linked. It can also use this to indicate
'removal of a JUPE'd server.
Public Sub KillServer(ByVal Name As String, Optional ByVal Message As String = "")
    Call basFunctions.SendData("SQUIT " & Name & " :" & IIf(Message <> "", " :" & Message, ""))
End Sub

Public Sub NotifyAllUsersWithServicesAccess(Message As String)
    Dim i As Integer
    Dim Reciever As String
    Dim Sender As String
    Sender = Service(8).Nick
    For i = 0 To basMain.TotalUsers
        If basMain.Users(i).Access > 0 Then
            Reciever = basMain.Users(i).Nick
            Call basFunctions.SendMessage(Sender, Reciever, Message)
        End If
    Next i
End Sub

'aquanight: I'll probably write a better Mode parser
'soon. And it will handle parameters and the like
'much better :) .

Public Sub SetUserModes(UserId As Integer, Modes As String)
    Dim Modes2 As String
    Dim j As Byte 'better not > 255 :|
    Dim ModeChar As String * 1
    Dim RemoveModes As Boolean
    Dim Result As Byte
    'Ripped pretty much directly from nrc ;)
    '
    'Note that this doesnt tell the other servers etc etc the modes... do that elsewhere!
    'This is really archaic and messy... but it works.
    'Still, I really should recode it.
    'aquanight: Killed those STUPID tabs...
    With basMain.Users(UserId)
        If Modes2 = "" Then Modes2 = .Modes
        For j = 1 To Len(Modes)
            ModeChar = Mid(Modes, j, 1)
            If Asc(ModeChar) < 65 Or Asc(ModeChar) > 90 Then
                If Asc(ModeChar) < 97 Or Asc(ModeChar) > 122 Then
                    'Ignore as is invalid mode char. ie is not alphabet char.
                    If ModeChar = "-" Then
                        RemoveModes = True
                    ElseIf ModeChar = "+" Then
                        RemoveModes = False
                    End If
                    ModeChar = ""
                End If
            End If
DontClearMode:
            If ModeChar = "" Then GoTo Skip
            'WHAT THE HECK??? - aquanight
            Select Case RemoveModes
                Case True
                    'remove mode
                    Result = InStr(Modes2, ModeChar)
                    If Result <> 0 Then
                        'remove that damn mode.
                        'aquanight: Mid just looks so
                        'much better.
                        Modes2 = Left(Modes2, Result - 1) & Mid(Modes2, Result + 1)
                    End If
                Case False
                    'assume addmode
                    'If we havent got it...
                    If InStr(Modes2, ModeChar) = 0 Then
                        'add it
                        If InStr(ModeChar, basMain.UserModes) = 0 Then
                            Modes2 = Modes2 & ModeChar
                        End If
                    End If
            End Select
Skip:
        Next j
        .Modes = Modes2
    End With
End Sub

Public Function SetChannelModes(ChanID, Modes As String)
    Dim Modes2 As String
    Dim j As Byte 'better not > 255 :|
    Dim ModeChar As String * 1
    Dim RemoveModes As Boolean
    Dim Result As Byte
    'Copied from SetUserModes.
    Modes = basFunctions.ReturnChannelOnlyModes(Modes)
    With basMain.Channels(ChanID)
        If Modes2 = "" Then Modes2 = .Modes
        For j = 1 To Len(Modes)
            ModeChar = Mid(Modes, j, 1)
            If Asc(ModeChar) < 65 Or Asc(ModeChar) > 90 Then
                If Asc(ModeChar) < 97 Or Asc(ModeChar) > 122 Then
                    'Ignore as is invalid mode char. ie is not alphabet char.
                    If ModeChar = "-" Then
                        RemoveModes = True
                    ElseIf ModeChar = "+" Then
                        RemoveModes = False
                    End If
                    ModeChar = ""
                End If
            End If
DontClearMode:
            If ModeChar = "" Then GoTo Skip
            Select Case RemoveModes
                Case True
                    'remove mode
                    Result = InStr(Modes2, ModeChar)
                    If Result <> 0 Then
                        'remove that damn mode.
                        'aquanight: Mid just looks so
                        'much better.
                        Modes2 = Left(Modes2, Result - 1) & Mid(Modes2, Result + 1)
                    End If
                Case False
                    'assume addmode
                    'If we havent got it...
                    If InStr(Modes2, ModeChar) = 0 Then
                        'add it
                        If InStr(ModeChar, basMain.ChannelModes) = 0 Then
                            Modes2 = Modes2 & ModeChar
                        End If
                    End If
            End Select
Skip:
        Next j
        .Modes = Modes2
    End With
End Function

Public Function ReturnChannelOnlyModes(ChannelModes As String)
    'Takes a given string of modes eg +pmoi and returns +pmi (ie those not
    'related to channel access.
    Dim j As Byte
    Dim ModeChar As String
    For j = 1 To Len(ChannelModes)
        ModeChar = Mid(ChannelModes, j, 1)
        If InStr(basMain.ChannelModes, ModeChar) <> 0 Then
            ReturnChannelOnlyModes = ReturnChannelOnlyModes & ModeChar
        End If
    Next
End Function

'aquanight: PHEW! :>
