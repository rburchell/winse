Attribute VB_Name = "basChanServ"
'Corrinia Services Channel Services Module.
'Module Version: 0.0.1.6

'Commands:
'           -=-=-=-=-=-=UNTESTED COMMANDS=-=-=-=-=-=-
'           These commands havent been tested properly yet!
'                    They may not be fully stable!
'           -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
'TOPIC #<channel> <topic> ''<setbyservices>
' Sets the channel topic
' if SetbyServices=1 and sender is an oper\chanop then make SERVICES set the topic!
'JOINC #<channel>
' Sets user with ID <ConnectionIndex> as being on channel <channel>
'PARTC #<channel> [message]
' Tells server that a user has quit a channel.
'KICKU #<channel> <username>
' Kicks a user from a given channel.

'           -=-=-=-=-=-=STABLE COMMANDS=-=-=-=-=-=-
'PRNTC #<channel>
' Prints a list of all users in a channel.
'LISTC <connectionindex>
' list all channels on the server (excepting with mode +s)
' Return the list to <connectionindex>
'CMODE #<channel> <modes>
' Sets modes on a channel.
'PRCFC #channel connectionindex
' Prints all users on a chan so a client can use it!

'**********SERVICES CODE**********
Public Sub ProcessCMD(Buffer, ConnectionIndex)
    On Error Resume Next
    Cmd = Left(Buffer, 5)
    Buffer = Right(Buffer, Len(Buffer) - 6)
    Select Case UCase(Cmd)
        Case "KICKU"
            Call KickU(Buffer, ConnectionIndex)
        Case "TOPIC"
            Call SetChannelTopic(Buffer, ConnectionIndex)
        Case "PRNTC"
            Call PrintC(Buffer, ConnectionIndex)
        Case "PRCFC"
            Call PrCFC(Buffer, ConnectionIndex)
        Case "JOINC"
            Call JoinC(Buffer, ConnectionIndex)
        Case "PARTC"
            Call PartC(Buffer, ConnectionIndex)
        Case "LISTC"
            Call ListC(ConnectionIndex)
        Case "CMODE"
            Call SetChanMode(Buffer, ConnectionIndex)
        Case Else
            Call SendDataToClient(ConnectionIndex, "ChServ: Command " & Cmd & " not recognised.")
    End Select
End Sub


'********************Individual Commands********************
Private Sub KickU(Buffer, ConnectionIndex)
    'KickU #<channel> <user> [<message>]
    'This is one messy sub due to all the usermodes involved.
    BreakPoint = InStr(Buffer, " ")
    Channel = Left(Buffer, BreakPoint - 1)
    Buffer = Right(Buffer, Len(Buffer) - BreakPoint)
    BreakPoint = InStr(Buffer, " ")
    If BreakPoint = 0 Then
        Username = Buffer
    Else
        Username = Left(Buffer, BreakPoint - 1)
        Message = Right(Buffer, Len(Buffer) - BreakPoint)
    End If
    If Left(Channel, 1) = "#" Then Channel = Right(Channel, Len(Channel) - 1) 'Remove a # if supplied
    
    
        For ChannelIndex = 1 To 500
        With Channels(ChannelIndex)
            If UCase(Channel) = UCase(.ChannelName) Then
                Exit For
            End If
        End With
        Next
    For UserIndex = 1 To intMaxUsers
        With Users(UserIndex)
            If UCase(.Alias) = UCase(Username) Then
                    If basFunctions.IsUserAChanOp(ConnectionIndex, ChannelIndex) = True Then
                        'if we are an op
                        If InStr(Users(UserIndex).Modes, "q") <> 0 And basFunctions.IsUserAMonitorOp(ConnectionIndex) = False Then
                            'target protected and we arent a monitop...
                            Call basFunctionsIO.SendDataToClient(ConnectionIndex, "Services: You do not have permission. (Not +U)")
                            Call basFunctionsIO.SendMessageToChannel(Channel, "Services", Users(ConnectionIndex).Alias & " attempted to kick +q user " & Users(UserIndex).Alias & " [" & Message & "]")
                        Else
                            'They arent? GOODIE!!!
                            GoTo KickUser
                        End If
                    ElseIf basFunctions.IsUserAMonitorOp(ConnectionIndex) = True Then
                        'are we +U?
                        Call basFunctionsIO.SendGlobalMessageToOperators("Channel kick with +U: #" & Channel & " " & Users(UserIndex).Alias & " by " & Users(ConnectionIndex).Alias & "[" & Message & "]", "Services")
                        Call basFunctionsIO.SendMessageToChannel(Channel, "Services", Users(ConnectionIndex).Alias & " used +U to kick " & Users(UserIndex).Alias & " [" & Message & "]")
                        GoTo KickUser
                    Else
                        'If user isnt a chanop and not +U...
                        Call basFunctionsIO.SendDataToClient(ConnectionIndex, "Services: You do not have permission.")
                        Call basFunctionsIO.SendMessageToChannel(Channel, "Services", Users(ConnectionIndex).Alias & " attempted to kick " & Users(UserIndex).Alias & " [" & Message & "]")
                    End If
            End If
        End With
    Next
    'Kicks user from a channel
KickUser:
    ExtraInfo = Users(UserIndex).Alias & " kicked by " & Users(ConnectionIndex).Alias & " [" & Message & "]"
    Call basFunctions.RemoveUserFromChan(ChannelIndex, UserIndex, ExtraInfo)
    Call basFunctionsIO.SendDataToClient(UserIndex, "Services: You were kicked from #" & Channels(ChannelIndex).ChannelName & " by " & Users(ConnectionIndex).Alias & " [" & Message & "]")
End Sub

Private Sub SetChannelTopic(Buffer, ConnectionIndex)
    BreakPoint = InStr(Buffer, " ")
    Channel = Left(Buffer, BreakPoint - 1)
    Buffer = Right(Buffer, Len(Buffer) - BreakPoint)
    Topic = Buffer
    SetByServices = False
    If Left(Channel, 1) = "#" Then Channel = Right(Channel, Len(Channel) - 1) 'Remove a # if supplied
    For i = 1 To 500
        With Channels(i)
            If UCase(Channel) = UCase(.ChannelName) Then
                'Found chan. Check for access then set topic!
                If InStr(.ChannelModes, "T") <> 0 Then
                    'If cmode +T then only access lists & o:block holders can change topic.
                    If basFunctions.IsUserAChanOp(ConnectionIndex, i) = True Then
                        Call basFunctionsIO.SetChannelTopic(Users(ConnectionIndex).Alias, i, Topic)
                    ElseIf basFunctions.IsUserAMonitorOp(ConnectionIndex) = True Then
                        Call basFunctionsIO.SendGlobalMessageToOperators("Channel +T Override with +U: #" & .ChannelName & " by " & Users(ConnectionIndex).Alias, "Services")
                        Call basFunctionsIO.SetChannelTopic(Users(ConnectionIndex).Alias, i, Topic)
                    Else
                        'If user isnt and mode +T...
                        Call basFunctionsIO.SendDataToClient(ConnectionIndex, "Services: You do not have permission.")
                        Call basFunctionsIO.SendMessageToChannel(Channel, "Services", Users(ConnectionIndex).Alias & " attempted to modify the channel topic!")
                    End If
                Else
                    Call basFunctionsIO.SetChannelTopic(Users(ConnectionIndex).Alias, i, Topic)
                End If
            End If
        End With
    Next i
End Sub

Private Sub PartC(Buffer, ConnectionIndex)
    'Parts user from a channel
    BreakPoint = InStr(Buffer, " ")
    If BreakPoint = 0 Then
        Channel = Buffer
    Else
        Channel = Left(Buffer, BreakPoint - 1)
        Message = Right(Buffer, Len(Buffer) - BreakPoint)
    End If
    Message = Users(ConnectionIndex).Alias & " parted [" & Message & "]"
    If Left(Channel, 1) = "#" Then Channel = Right(Channel, Len(Channel) - 1) 'Remove a # if supplied
    For i = 1 To 500
        With Channels(i)
            If UCase(Channel) = UCase(.ChannelName) Then
                'Found chan. Make user be off it!
                Call basFunctions.RemoveUserFromChan(i, ConnectionIndex, Message)
            End If
        End With
    Next i
End Sub
Private Sub JoinC(Channel, ConnectionIndex)
    'Lets a user join a channel.
    If Left(Channel, 1) = "#" Then Channel = Right(Channel, Len(Channel) - 1) 'Remove a # if supplied
    'Oooookay this is going to be messy...
    For i = 1 To 500
        With Channels(i)
            If UCase(Channel) = UCase(.ChannelName) Then
                'We have found our channel
                If InStr(.ChannelModes, "i") Then
                    'Channel invite only.
                    'CHANGE: This used to be opers. But due to abuse, is now +U only.
                    If basFunctions.IsUserAMonitorOp(ConnectionIndex) = True Then
                        'User is an oper. Don't block from +i
                        Call basFunctionsIO.SendGlobalMessageToOperators("Channel +i Override with +U: #" & .ChannelName & " by " & Users(ConnectionIndex).Alias, "Services")
                        GoTo JoinChan
                    End If
                    If basFunctions.IsUserAChanOp(ConnectionIndex, i) = True Then
                        'User is chan cofounder. Don't block them from +i
                        GoTo JoinChan
                    End If
                    Call basFunctionsIO.SendDataToClient(ConnectionIndex, "Services: Cannot join #" & Channel & ": +i (Invite Only)")
                    Exit Sub
                Else
                    'Channel not invite only OR we passed the tests.
JoinChan:
                    If InStr(.ChannelModes, "O") Then
                        'Oh dear... Operators and above only.
                        If basFunctions.ReturnAccessLevel(ConnectionIndex) <> 0 Then
                            'User is an oper. Don't block.
                            GoTo DoneCheck
                        ElseIf basFunctions.IsUserAMonitorOp(ConnectionIndex) = True Then
                            'User is +U. Don't block
                            Call basFunctionsIO.SendGlobalMessageToOperators("Channel +O Override with +U: #" & .ChannelName & " by " & Users(ConnectionIndex).Alias, "Services")
                            GoTo DoneCheck
                        Else
                            Call basFunctionsIO.SendDataToClient(ConnectionIndex, "Services: Cannot join #" & Channel & ": +O (Operators and above only)")
                            Exit Sub
                        End If
                    End If
DoneCheck:
                    Call basFunctions.AddUserToChan(i, ConnectionIndex)
                End If
                Exit Sub
            End If
            If .ChannelName = "" And FirstFree = 0 Then FirstFree = i
        End With
    Next i
    
    'We havent found it? Then we need to create it...
    With Channels(FirstFree)
        .ChannelName = Channel
        .ChannelFounder = Users(ConnectionIndex).Alias 'The index of who sent the cmd? NO! If they have to reconnect, they lose founder!
        .ChannelModes = ""
        Call basFunctions.AddUserToChan(FirstFree, ConnectionIndex)
    End With
End Sub

Private Sub PrCFC(Channel, ConnectionIndex)
    'Print all users on a chan.
    'Find the chan by name.
    If Left(Channel, 1) = "#" Then Channel = Right(Channel, Len(Channel) - 1) 'Remove a # if supplied
    For i = 1 To 500
        With Channels(i)
            If UCase(.ChannelName) = UCase(Channel) Then
                For a = 1 To .TotalUsers
                    If .ChannelUsers(a) <> 0 Then
                        'We have a user. Lookup their name.
                        IsInvisible = basFunctions.IsUserInvisible(.ChannelUsers(a))
                        Select Case IsInvisible
                            Case False
                                txt = txt & Chr(3) & Users(.ChannelUsers(a)).Alias
                        End Select
                    End If
                Next a
            End If
        End With
    Next i
    If txt = "" Then Exit Sub
    Call SendDataToClient(ConnectionIndex, "USERS" & Channel & txt)
End Sub

Private Sub PrintC(Channel, ConnectionIndex)
    'Print all users on a chan.
    'Find the chan by name.
    If Left(Channel, 1) = "#" Then Channel = Right(Channel, Len(Channel) - 1) 'Remove a # if supplied
    For i = 1 To 500
        With Channels(i)
            If UCase(.ChannelName) = UCase(Channel) Then
                For a = 1 To .TotalUsers
                    If .ChannelUsers(a) <> 0 Then
                        'We have a user. Lookup their name.
                        txt = txt & "  " & Users(.ChannelUsers(a)).Alias & vbCrLf
                    End If
                Next a
            End If
        End With
    Next i
    
    Call SendDataToClient(ConnectionIndex, "Users on " & Channel & ":" & vbCrLf & txt)
End Sub

Private Sub ListC(ConnectionIndex)
    'List all channels EXCEPT with mode "s" set (mode s=secret)
    For i = 1 To 500
        With Channels(i)
            If .ChannelName <> "" Then
                If InStr(.ChannelModes, "s") = 0 Then
                    txt = txt & "  Channel: " & .ChannelName & vbCrLf & "    Topic: " & .ChannelTopic & vbCrLf & "  Founder: " & .ChannelFounder & vbCrLf & "    Modes: +" & .ChannelModes & vbCrLf & "    Users: " & .TotalUsers & vbCrLf
                End If
            Else
            End If
        End With
    Next i
    m = m
    Call SendDataToClient(ConnectionIndex, "Channels:" & vbCrLf & txt & "End Channels" & vbCrLf)
End Sub

Private Sub SetChanMode(Buffer, ConnectionIndex)
            'CMODE #<channel> <modes>
            On Error Resume Next
            Cmd = Trim(Buffer)
            BreakPoint = InStr(Cmd, " ")
            Channel = Left(Cmd, BreakPoint - 1)
            If Left(Channel, 1) = "#" Then Channel = Right(Channel, Len(Channel) - 1) 'Remove a # if supplied
            Modes = Right(Cmd, Len(Cmd) - BreakPoint)
            For i = 1 To 500
                With Channels(i)
                    If UCase(.ChannelName) = UCase(Channel) Then
                        If basFunctions.ReturnAccessLevel(ConnectionIndex) <> 0 Then
                            'User is an oper. Don't block them.
                        ElseIf basFunctions.IsUserAChanOp(ConnectionIndex, i) = True Then
                            'User is chan cofounder. Don't block them from +i
                        Else
                            Call basFunctionsIO.SendDataToClient(ConnectionIndex, "Services: You do not have permission.")
                            Call basFunctionsIO.SendMessageToChannel(Channel, "Services", Users(ConnectionIndex).Alias & " attempted to modify the channel modes!")
                            Exit Sub
                        End If
                        If Modes2 = "" Then Modes2 = .ChannelModes
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
                                        Modes2 = Left(Modes2, Result - 1) & Right(Modes2, Len(Modes2) - Result)
                                    End If
                                Case False
                                    'assume addmode
                                    If InStr(Modes2, ModeChar) = 0 Then
                                        Modes2 = Modes2 & ModeChar
                                    End If
                            End Select
Skip:
                        Next j
                        .ChannelModes = Modes2
                    End If
                End With
            Next i
End Sub

