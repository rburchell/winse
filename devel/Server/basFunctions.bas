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
        'Well... we're supposed to include the killer
        'in a kill path. But further research with
        'Unreal reveals that we actually do NOT include
        'the server name :).
        If Not Killer = "" Then
            Message = Killer & " (" & Message & ")"
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
        'Error 5
        'And say something went pear-shaped. --w00t
            'Sending a notice certainly is better :) .
        Call basFunctions.NotifyAllUsersWithServicesAccess(Replace(Replies.SanityCheckInvalidIndex, "%n", "basFunctions.KillUser"))
    End If
End Sub

Public Function ReturnUserName(UserId As Integer) As String
    'If return "" then user doesnt exist.
    If UserId = -1 Then Exit Function
    ReturnUserName = basMain.Users(UserId).Nick
End Function

Public Sub GlobalMessage(Message As String)
    'I'm thinking that we should Global the easy way :)
    'IMHO, global messages should always be NOTICE,
    'but that's partly because mIRC does wierd things
    'with $target PRIVMSGs (in status: (nick) message).
    ' - aquanight
    basFunctions.SendData ":" + Service(8).Nick + " NOTICE " + basMain.Config.GlobalTargets + " :" + Message
'    Dim i As Integer
'    Dim Reciever As String
'    Dim Sender As String
'    Sender = Service(8).Nick
'
'    For i = 0 To basMain.TotalUsers
'        Reciever = basMain.Users(i).Nick
'        Call basFunctions.SendMessage(Sender, Reciever, Message)
'        DoEvents
'    Next i
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
    Call basFunctions.SendData("SQUIT " & basMain.Config.UplinkName & IIf(Message <> "", " :" & Message, ""))
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

Public Function SetChannelModes(ChanID As Integer, Modes As String)
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

Public Sub ParseCmd(ByVal Incoming As String)
    If Incoming = "" Then Exit Sub
    Dim sTmp As String
    sTmp = Incoming 'Make a copy of the incoming text.
    'Hopefully this will replace all the stuff in
    '*_DataArrival :P . I'm hoping this will make us
    'less dependent on the form.
    Dim sLongArg As String 'Contain the long argument.
    Dim sSource As String 'Contain the source.
    Dim sCmd As String 'The command
    Dim vArgs As Variant 'Args not part of the long arg.
    'Asc() returns the ASCII code of the first char
    'of a string, so we can use that to check for a
    'source :) .
    If Asc(sTmp) = Asc(":") Then
        sSource = Mid(2, sTmp)
        sSource = Left(sSource, InStr(sSource, " ") - 1)
        sTmp = Mid(sTmp, InStr(sTmp, " ") + 1)
    End If
    'Now pull the command.
    If sTmp = "" Then Exit Sub
    If InStr(sTmp, " ") = 0 Then
        sCmd = sTmp
        sTmp = ""
    Else
        sCmd = Left(sTmp, InStr(sTmp, " ") - 1)
        sTmp = Mid(sTmp, InStr(sTmp, " ") + 1)
    End If
    'Now, do we have any arguments?
    If sTmp <> "" Then
        'Pull the long argument.
        If Asc(sTmp) = Asc(":") Then
            'The whole list is the long arg.
            sLongArg = Mid(sTmp, 2)
            sTmp = ""
        ElseIf InStr(sTmp, " :") > 0 Then
            'The long arg comes later.
            sLongArg = Mid(sTmp, InStr(sTmp, " :") + 2)
            sTmp = Left(sTmp, InStr(sTmp, " :") - 1)
        End If
        'Now parse the remaining arguments.
        If sTmp <> "" Then
            vArgs = Split(sTmp, " ")
            'If we have a long arg, append it to the
            'end.
            ReDim Preserve vArgs(UBound(vArgs) + 1)
            vArgs(UBound(vArgs)) = sLongArg
        End If
    End If
    'Now we have the command parsed. Let's see what to
    'do with it!
    'Create a command dispatcher. FIXME: Maybe we should
    'have this be a persistant variable?
    Dim cd As CommandDispatcher
    Set cd = New CommandDispatcher
    'Now execute it :) Use late-binding to pick the
    'correct procedure.
    On Error Resume Next
    Call CallByName(cd, sCmd, VbMethod, Array(sSource, vArgs, Incoming))
    If Err.Number <> 0 Then Debug.Print Err.Number, Err.Description
End Sub

Public Function SetChannelModes2(ChanID As Integer, Modes As String)
    'Believe it or not, I like throwing errors over just
    'sending out a scream :) .
    If ChanID < 0 Then Err.Raise 9, , Replace(Replies.SanityCheckInvalidIndex, "%n", "basFunctions.SetChannelModes2")
    'Indexes, for the character and parameter
    Dim iChar As Integer, iParam As Integer
    'Strings to store said character and parameter
    Dim sChar As String, sParam As String
    'Two arrays: one for holding the parsed mode string
    'and the other for holding the modes that are valid.
    Dim sMode As Variant, sValid As Variant
    'Are we setting or unsetting a mode?
    Dim bSet As Boolean
    bSet = True 'Start off in + by default.
    sMode = Split(Modes, " ") 'Parse the modes.
    sValid = Split(basMain.ChannelModes2, ",") 'And these too.
    iParam = 1 'Init the parameter index.
    For iChar = 1 To Len(sMode(0))
        sChar = Mid(sMode(0), iChar, 1) 'Get the modeflag
        If sChar = "+" Then 'Now setting modes
            bSet = True
        ElseIf sChar = "-" Then 'Now unsetting modes
            bSet = False
        ElseIf InStr(basMain.ChanModesForAccess, sChar) > 0 Then
            'Prefix mode: controls channel privs
            If iParam <= UBound(sMode) Then
                sParam = sMode(iParam)
                iParam = iParam + 1
                DispatchPrefix ChanID, bSet, sChar, ReturnUserIndex(sParam)
            Else
                'EEEEEEEEEK!
                NotifyAllUsersWithServicesAccess Replace(Replies.SanityCheckParamlessModeChange, "%c", IIf(bSet, "+", "-") & sChar)
            End If
        ElseIf InStr(sValid(0), sChar) > 0 Then
            'Type A: Mode flag controls a list.
            If iParam <= UBound(sMode) Then
                sParam = sMode(iParam)
                iParam = iParam + 1
                DispatchModeTypeA ChanID, bSet, sChar, sParam
            Else
                'EEEEEEEEEK!
                NotifyAllUsersWithServicesAccess Replace(Replies.SanityCheckParamlessModeChange, "%c", IIf(bSet, "+", "-") & sChar)
            End If
        ElseIf InStr(sValid(1), sChar) > 0 Then
            'Type B: Use param for set and unset.
            If iParam <= UBound(sMode) Then
                sParam = sMode(iParam)
                iParam = iParam + 1
                DispatchModeTypeB ChanID, bSet, sChar, sParam
            ElseIf bSet = False Then
                'Some wacky IRCd might let us get away
                'unsetting a mode w/o parameter
                '*coughunrealircdcough*
                DispatchModeTypeB ChanID, False, sChar, ""
            Else
                'EEEEEEEEEK!
                NotifyAllUsersWithServicesAccess Replace(Replies.SanityCheckParamlessModeChange, "%c", IIf(bSet, "+", "-") & sChar)
            End If
        ElseIf InStr(sValid(2), sChar) > 0 Then
            'Type C: Use param only for set
            If bSet Then
                If iParam <= UBound(sMode) Then
                    sParam = sMode(iParam)
                    iParam = iParam + 1
                    DispatchModeTypeC ChanID, bSet, sChar, sParam
                Else
                    'EEEEEEEEEK!
                    NotifyAllUsersWithServicesAccess Replace(Replies.SanityCheckParamlessModeChange, "%c", IIf(bSet, "+", "-") & sChar)
                End If
            Else
                DispatchModeTypeC ChanID, bSet, sChar
            End If
        ElseIf InStr(sValid(3), sChar) > 0 Then
            'Type D: Never use a param
            DispatchModeTypeD ChanID, bSet, sChar
        Else
            'EEEEEEEEEK!
            NotifyAllUsersWithServicesAccess Replace(Replies.SanityCheckUnknownModeChange, "%c", IIf(bSet, "+", "-") & sChar)
        End If
    Next iChar
End Function

Private Sub DispatchPrefix(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, ByVal Target As Integer)
    If ChanID < 0 Or Target < 0 Then
        'Now something really went pear-shaped. :P
        'Send out a scream.
        NotifyAllUsersWithServicesAccess Replace(Replies.SanityCheckInvalidIndex, "%n", "basFunctions.DispatchPrefix")
        'Reboot.
        RestartServices "Fatal sanity check error. Forcing restart."
    End If
    Dim s As String
    s = Channels(ChanID).UsersModes(Target)
    If bSet Then
        s = s & Char
    Else
        s = Replace(s, Char, "")
    End If
    SetItem(Channels(ChanID).UsersModes, Target) = s
    'Okay, now that we've updated their status, send it
    'out :) .
    sAdminServ.HandlePrefix ChanID, bSet, Char, Target
    sAgent.HandlePrefix ChanID, bSet, Char, Target
    sChanServ.HandlePrefix ChanID, bSet, Char, Target
    sDebugServ.HandlePrefix ChanID, bSet, Char, Target
    sMassServ.HandlePrefix ChanID, bSet, Char, Target
    sNickServ.HandlePrefix ChanID, bSet, Char, Target
    sOperServ.HandlePrefix ChanID, bSet, Char, Target
    sRootServ.HandlePrefix ChanID, bSet, Char, Target
End Sub

'Sometimes we have to modify an item in a collection.
'Unfortunately, VB6's collection does not allow us to
'simply assign a new value into the collection, so we
'are going to use a pretty ugly work around. Property
'Let|Set allows us to use the assignment syntax to
'call these, so use:
'[Let|Set] SetItem(<col>, <index>) = <newval>
'NOTE: Due to the nature of this hack, if you use an
'integer index, any string key WILL be lost! If you use
'a key value, the numeric position of the item will no
'longer be correct! - aquanight
Public Property Let SetItem(ByVal Collection As Collection, ByVal Index As Variant, ByVal NewValue As Variant)
    Collection.Remove Index
    If VarType(Index) = vbString Then
        Collection.Add NewValue, Key:=Index
    Else
        Collection.Add NewValue, before:=Index
    End If
End Property

Public Property Set SetItem(ByVal Collection As Collection, ByVal Index As Variant, ByVal NewValue As Object)
    Collection.Remove Index
    If VarType(Index) = vbString Then
        Collection.Add NewValue, Key:=Index
    Else
        Collection.Add NewValue, before:=Index
    End If
End Property

'Something to tell us if a collection item exists.
Public Function CollectionContains(ByVal Collection As Collection, ByVal Key As String) As Boolean
    On Error GoTo Nope
    Call Collection.Item(Key)
    CollectionContains = True
    Exit Function
Nope:
    CollectionContains = False
End Function

Private Sub DispatchModeTypeA(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)
    If ChanID < 0 Or Entry = "" Then
        'Now something really went pear-shaped. :P
        'Send out a scream.
        NotifyAllUsersWithServicesAccess Replace(Replies.SanityCheckInvalidIndex, "%n", "basFunctions.DispatchModeTypeA")
        'Reboot.
        RestartServices "Fatal sanity check error. Forcing restart."
    End If
    Select Case Char
        Case "b"
            If bSet Then
                If Not CollectionContains(Channels(ChanID).Bans, Entry) Then Channels(ChanID).Bans.Add Entry, Entry
            Else
                If CollectionContains(Channels(ChanID).Bans, Entry) Then Channels(ChanID).Bans.Remove Entry
            End If
        Case "e"
            If bSet Then
                If Not CollectionContains(Channels(ChanID).Bans, Entry) Then Channels(ChanID).Excepts.Add Entry, Entry
            Else
                If CollectionContains(Channels(ChanID).Bans, Entry) Then Channels(ChanID).Excepts.Remove Entry
            End If
        Case "I"
            If bSet Then
                If Not CollectionContains(Channels(ChanID).Bans, Entry) Then Channels(ChanID).Invites.Add Entry, Entry
            Else
                If CollectionContains(Channels(ChanID).Bans, Entry) Then Channels(ChanID).Invites.Remove Entry
            End If
        Case Else
            'Don't know? Don't care.
    End Select
    'Now send it out :)
    sAdminServ.HandleModeTypeA ChanID, bSet, Char, Entry
    sAgent.HandleModeTypeA ChanID, bSet, Char, Entry
    sChanServ.HandleModeTypeA ChanID, bSet, Char, Entry
    sDebugServ.HandleModeTypeA ChanID, bSet, Char, Entry
    sMassServ.HandleModeTypeA ChanID, bSet, Char, Entry
    sNickServ.HandleModeTypeA ChanID, bSet, Char, Entry
    sOperServ.HandleModeTypeA ChanID, bSet, Char, Entry
    sRootServ.HandleModeTypeA ChanID, bSet, Char, Entry
End Sub

Private Sub DispatchModeTypeB(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)
    If ChanID < 0 Or (Entry = "" And bSet = True) Then
        'Now something really went pear-shaped. :P
        'Send out a scream.
        NotifyAllUsersWithServicesAccess Replace(Replies.SanityCheckInvalidIndex, "%n", "basFunctions.DispatchModeTypeA")
        'Reboot.
        RestartServices "Fatal sanity check error. Forcing restart."
    End If
    Select Case Char
        Case "k"
            Channels(ChanID).ChannelKey = IIf(bSet, Entry, "")
        Case "L"
            Channels(ChanID).OverflowChannel = IIf(bSet, Entry, "")
        Case "f"
            If bSet Then
                Channels(ChanID).FloodProtection = Entry
            Else
                Channels(ChanID).FloodProtection = ""
            End If
        Case Else
            'Don't know? Don't care.
    End Select
    'Now send it out :)
    sAdminServ.HandleModeTypeB ChanID, bSet, Char, Entry
    sAgent.HandleModeTypeB ChanID, bSet, Char, Entry
    sChanServ.HandleModeTypeB ChanID, bSet, Char, Entry
    sDebugServ.HandleModeTypeB ChanID, bSet, Char, Entry
    sMassServ.HandleModeTypeB ChanID, bSet, Char, Entry
    sNickServ.HandleModeTypeB ChanID, bSet, Char, Entry
    sOperServ.HandleModeTypeB ChanID, bSet, Char, Entry
    sRootServ.HandleModeTypeB ChanID, bSet, Char, Entry
End Sub

Private Sub DispatchModeTypeC(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, Optional ByVal Entry As String)
    If ChanID < 0 Or (Entry = "" And bSet = True) Then
        'Now something really went pear-shaped. :P
        'Send out a scream.
        NotifyAllUsersWithServicesAccess Replace(Replies.SanityCheckInvalidIndex, "%n", "basFunctions.DispatchModeTypeA")
        'Reboot.
        RestartServices "Fatal sanity check error. Forcing restart."
    End If
    Select Case Char
        Case "l"
            Channels(ChanID).OverflowLimit = IIf(bSet, CLng(Entry), 0)
        Case Else
            'Don't know? Don't care.
    End Select
    'Now send it out :)
    sAdminServ.HandleModeTypeC ChanID, bSet, Char, Entry
    sAgent.HandleModeTypeC ChanID, bSet, Char, Entry
    sChanServ.HandleModeTypeC ChanID, bSet, Char, Entry
    sDebugServ.HandleModeTypeC ChanID, bSet, Char, Entry
    sMassServ.HandleModeTypeC ChanID, bSet, Char, Entry
    sNickServ.HandleModeTypeC ChanID, bSet, Char, Entry
    sOperServ.HandleModeTypeC ChanID, bSet, Char, Entry
    sRootServ.HandleModeTypeC ChanID, bSet, Char, Entry
End Sub

Private Sub DispatchModeTypeD(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String)
    If ChanID < 0 Then
        'Now something really went pear-shaped. :P
        'Send out a scream.
        NotifyAllUsersWithServicesAccess Replace(Replies.SanityCheckInvalidIndex, "%n", "basFunctions.DispatchModeTypeA")
        'Reboot.
        RestartServices "Fatal sanity check error. Forcing restart."
    End If
    If bSet Then
        If InStr(Channels(ChanID).Modes, Char) = 0 Then Channels(ChanID).Modes = Channels(ChanID).Modes + Char
    Else
        'Don't need to check :) replace will do that for
        'us!
        Channels(ChanID).Modes = Replace(Channels(ChanID).Modes, Char, "")
    End If
End Sub

'The reason all the Dispatch* procs force a restart is
'because they should NEVER be called with illegal
'arguments. Why?
'ChanID < 0 is alredy checked before entry, and the
'presence of arguments are checked as well. A skipped
'argument could possibly cause things to go pear-shaped,
'but I can't see that happening with a serious IRCd.
'Only if we had some form of INJECT command, and in that
'case it's the user's fault :P .

Public Sub RestartServices(Optional ByVal RestartMsg As String = "Restarting...")
    'Restart the service daemon completely. OperServ
    'RESTART? Forced restarts due to sanity checks?
    'You tell me.
    NotifyAllUsersWithServicesAccess "Restarting services... Reason: " & RestartMsg
    SquitServices RestartMsg
    Shell App.Path & "\" & App.EXEName & ".exe", vbMinimizedNoFocus
    End 'Splat.
End Sub

'More functions! :) - aquanight
Public Function FreeUserID() As Integer
    Dim i As Integer
    For i = 0 To UBound(Users)
        If Users(i).Nick = "" Then
            FreeUserID = i
            Exit Function
        End If
    Next i
End Function

Public Function FreeChanID() As Integer
    Dim i As Integer
    For i = 0 To UBound(Channels)
        If Channels(i).Name = "" Then
            FreeChanID = i
            Exit Function
        End If
    Next i
End Function

'PHEW! :> -aquanight
'Yes, I really should split this into other .bas files, but I cba. And hey,
'is it worth it? --w00t
