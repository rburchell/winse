Attribute VB_Name = "basFunctions"
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

'Explicitly declaring our types would be nice :) Makes
'moving to Option Strict level of coding SO much easier
' - aquanight
'Please explain?? Do you mean ParseBuffer() As VARIANT <--the VARIANT bit
'btw, shouldn't ParseBuffer always return an array of strings? --w00t
Public Function ParseBuffer(ByVal Buffer As String) As Variant
    'Splits a sentance or whatever into an array of words.
    'Did you know a VB function can do this for you? :)
    ' - aquanight
    'Actually, I didnt :| VB has too many functions anyway *blush* --w00t
    ParseBuffer = Split(Buffer, " ")
End Function

Public Sub LogEvent(Header As String, Message As String)
    'Logs given event to file.

    'Header eg "BUG"
    'Message eg "basMisc.Ident given null Username var."
    
    'check to log at all ;)
    If basMain.LoggingType = "NONE" Then
        Exit Sub
    End If
    'make sure we ignore debug messages unless we have debug logging ;)
    If basMain.LoggingType <> "DEBUG" And Header = "DEBUG" Then
        Exit Sub
    End If
    Open App.Path & "\winse.log" For Append As #FreeFile
    'we really should Format() Now, so it's consistent in the logfile. But meh. --w00t
    Print #FreeFile - 1, Now & "-[" & Header & "]: " & Message
    Close #FreeFile - 1
End Sub

Public Sub LogEventWithMessage(Header As String, Message As String)
    'Notifies all users with saccess, and logs event to file
    Call basFunctions.NotifyAllUsersWithServicesAccess(Header & " " & Message)
    Call basFunctions.LogEvent(Header, Message)
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
    Password = basFileIO.GetInitEntry("channels.db", UCase(ChanName), "Password")
    'Booleans rock :) - aquanight
    'I always have to look at them for a few seconds to understand them :( :P --w00t
    IsChanRegistered = (Password <> "")
End Function

Public Function IsNickRegistered(NickName As String)
    Dim Password As String
    'If we have a password, we must be registered ;)
    Password = basFileIO.GetInitEntry("users.db", UCase(NickName), "Password")
    'Booleans rock :) - aquanight
    IsNickRegistered = (Password <> "")
End Function

Public Sub IntroduceClient(Nick As String, Host As String, Name As String, Optional IsBot As Boolean = False)
    'stop erroring if the link died.
    On Error Resume Next
    Dim MyTime As String
    MyTime = basUnixTime.GetTime
    'we directly send the nick and user commands, as buffering stuffs things up. --w00t
    Call frmServer.tcpServer.Send("NICK " & Nick & " 1 " & MyTime & " " & Name & " " & Host & " " & basMain.Config.ServerName & " " & Nick & vbCrLf)
    Call frmServer.tcpServer.Send("USER " & Nick & " " & Name & " " & basMain.Config.ServerName & " " & Name & vbCrLf)
    'Don't send SVSMODE for clients on your server.
    'SVSMODE suggests forcefully changing modes for
    'other clients, which isn't necessary. - aquanight
        'Whoops. Also, nice use of "Not" rather than a messy If statement aquanight! --w00t
    basFunctions.SendData ":" & Nick & " MODE " & Nick & " +qS"
    If Not IsBot Then basFunctions.SendData ":" & Nick & " MODE " & Nick & " +d"
    'This actually causes Unreal to set +xt for the user
    'which may not be what we want. Since we send our
    '"vhost" as the real host in User, why is this
    'necessary anyway? - aquanight
        'I was thinking bots, but you are right about the USER thing. Unnecessary. --w00t
    'Call basFunctions.SendData(":" & Nick & " SETHOST " & Host)
End Sub

Public Sub JoinServicesToChannel(Sender As Integer, Channel As String)
    'aquanight: This may need to be bumped to a larger
    'type to satisify Option Strict when we .NET-ize it :) .
        'Argh, dont prefix comments... I thought I said that at first :|
        'Anyhow, you're the .NET expert. --w00t
    Dim i As Byte
    Dim Nick, Host, Name As String
    For i = 0 To basMain.TotalServices - 1
        Nick = basMain.Service(i).Nick
        Host = basMain.Service(i).Hostmask
        Name = basMain.Service(i).Name
        Call basFunctions.SendData(":" & Nick & " JOIN " & Channel)
        basFunctions.SendData ":" & Nick & " MODE " & Channel & " +ao " & Nick & " " & Nick
    Next i
End Sub

Public Sub PartServicesFromChannel(Sender As Integer, Channel As String)
    'See JoinServicesToChannel comment on this.  - aquanight
    Dim i As Byte
    Dim Nick, Host, Name As String
    For i = 0 To basMain.TotalServices - 1
        Nick = basMain.Service(i).Nick
        Host = basMain.Service(i).Hostmask
        Name = basMain.Service(i).Name
        Call basFunctions.SendData(":" & Nick & " PART " & Channel)
    Next i
End Sub

Public Function ReturnUserServicesPermissions(UserId As Integer) As Byte
    'Determines services permissions through a number of different factors.
    
    'If the userindex given doesnt exist, tell them that.
    If basMain.Users(UserId).Nick = "" Then
        ReturnUserServicesPermissions = -1
        Exit Function
    End If
    'If they are identified to services master nick, access=100
    If UCase(basMain.Users(UserId).IdentifiedToNick) = UCase(basMain.Config.ServicesMaster) Then
        ReturnUserServicesPermissions = 100
        Exit Function
    End If
    'else return their given permissions.
    ReturnUserServicesPermissions = basMain.Users(UserId).Access
End Function

Public Function IsAbuseTeamMember(UserId As Integer) As Boolean
    'Don't you love Booleans? :D - aquanight
    'God, what was I on!!! duh... it's already boolean... so why did I check? --w00t
    IsAbuseTeamMember = basMain.Users(UserId).AbuseTeam
End Function

Public Function IsServicesAdmin(UserId As Integer) As Boolean
    'ick. I have to think when I see things like that :( :P
    'Go the booleans aquanight! --w00t
    IsServicesAdmin = (InStr(basMain.Users(UserId).Modes, "a") <> 0)
End Function

Public Function IsOper(UserId As Integer) As Boolean
    IsOper = (InStr(basMain.Users(UserId).Modes, "o") <> 0)
End Function

Public Function GetTarget(Buffer As String) As String
    'What the heck? I've never seen this command before - aquanight
        'I've had problems with On--Resume next taking precedence in other proceedures.
        '"Local" seems to combat that. (perhaps some description of VB bug) --w00t
    'On Local Error Resume Next
    'Dim s As Variant
    's = Split(Buffer, " ")
    'GetTarget = IIf(Left(s(0), 1) = ":", s(2), s(1))
    
    'See my comment on GetSender. --w00t
    Dim FirstSpace As Byte
    Dim SecondSpace As Byte
    Dim Cmd As String
    On Local Error Resume Next
    FirstSpace = InStr(Buffer, " ") - 1
    SecondSpace = InStr(FirstSpace + 2, Buffer, " ")
    Cmd = Right(Buffer, Len(Buffer) - SecondSpace)
    FirstSpace = InStr(Cmd, " ") - 1
    GetTarget = Left(Cmd, FirstSpace)
End Function

Public Function GetSender(Buffer As String) As String
    'Your way stuffed up PRIVMSG handling, you can look into it if you want. For now,
    'the old code is back, yours is commented. --w00t
    'Dim s As Variant
    's = Split(Buffer, " ")
    'GetSender = IIf(Left(s(0), 1) = ":", s(0), "")
    
    Dim FirstSpace As Byte
    FirstSpace = InStr(Buffer, " ") - 1
    GetSender = Right(Left(Buffer, FirstSpace), Len(Left(Buffer, FirstSpace)))
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

'Changing Message to ByVal because we need to
'do some multiliation to it to send KILLs properly. -aquanight
Public Sub KillUser(UserId As Integer, ByVal Message As String, Optional Killer As String = "Agent")
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
                'Ick, I used to just make 'em functions and return, like -1 for an error...
                'I never got the hand of errors. I like Try... catch... End try blocks :P --w00t
            Error 5
        End If
        'Ever heard of kill paths? Yep, we need to
        'specify the Killer :) . - aquanight
            'You'll really have to explain this to me :| --w00t
        If Killer = "" Then
            Killer = basMain.ServerName
            Message = Killer & " (" & Message & ")"
        Else
            Message = basMain.ServerName & "!" & Killer & " (" & Message & ")"
        End If
        basFunctions.SendData (":" + Killer + " KILL " & basMain.Users(UserId).Nick & " :" & Message)
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
        'Services dont know them :| Shouldnt happen!!!!!! --w00t
            'In that case, let's throw an error. -aquanight
        Error 5
        'And say something went pear-shaped. --w00t
        Call basFunctions.NotifyAllUsersWithServicesAccess(Replace(Replies.SanityCheckInvalidIndex, "%n", "basFunctions.KillUser"))
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
    'Flood level goes down by 1 every 5 seconds?? --w00t
    'The GLINE'ing aspect will be pretty...
    'wierd considering that you KILL the user before you
    'get to the GLINE stage, but I don't see this
    'implemented anywhere, so that's ok :) --aquanight
    'Ahem. I realised that after I tried to implement it once :P --w00t
    With basMain.Users(UserId)
        If .Requests >= 8 Then
            'kill, dont specify killer so it will default to "Agent"
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
    'Returns -1 if user doesnt exist.
    For i = 0 To basMain.TotalUsers
        With basMain.Users(i)
            If UCase(NickName) = UCase(.Nick) Then
                ReturnUserIndex = i
                'Blah - aquanight
                Exit Function
            End If
        End With
        DoEvents
    Next i
    ReturnUserIndex = -1
End Function

Public Function ReturnChannelIndex(ChannelName As String)
    Dim i As Integer
    'Returns -1 if chan doesnt exist.
    For i = 0 To basMain.TotalChannels
        With basMain.Channels(i)
            If UCase(ChannelName) = UCase(.Name) Then
                ReturnChannelIndex = i
                Exit Function
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
'removal of a JUPE'd server. -aquanight
    'renamed DelServer cause I like that better. --w00t
Public Sub DelServer(ByVal Name As String, Optional ByVal Message As String = "")
    Call basFunctions.SendData("SQUIT " & Name & " :" & IIf(Message <> "", " :" & Message, ""))
End Sub

Public Sub AddServer(ByVal Name As String, Optional ByVal Message As String = "Winse JUPE")
    Call basFunctions.SendData("SERVER " & Name & " 1 :" & " " & Message & vbCrLf)
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

'I'll probably write a better Mode parser
'soon. And it will handle parameters and the like
'much better :) -aquanight
'Good. :P I suck at this kind of thing :'(

Public Sub SetUserModes(UserId As Integer, Modes As String)
    Dim Modes2 As String
    Dim j As Byte 'better not > 255 :|
    Dim ModeChar As String * 1
    Dim RemoveModes As Boolean
    Dim Result As Byte

    'Killed those STUPID tabs... -aquanight
    'You were warned that it was ripped directly ;)
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
            'I cant remember --w00t
            Select Case RemoveModes
                Case True
                    'remove mode
                    Result = InStr(Modes2, ModeChar)
                    If Result <> 0 Then
                        'remove that damn mode.
                        'Mid just looks so much better. -aquanight
                        'Yes, yes it does. I'll try remember :P --w00t
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
                        'Mid just looks so much better. -aquanight
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

'PHEW! :> -aquanight
'Yes, I really should split this into other .bas files, but I cba. And hey,
'is it worth it? --w00t
