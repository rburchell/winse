Attribute VB_Name = "basFunctions"
'Generic functions to make the life of a coder easier ;)

'Index of functions:
'SetChannelTopic(Sender, ChannelIndex, Topic)
'SendDataToClient(ConnectionIndex, Buffer)
'AddUserToChan(i, ConnectionIndex)
'RemoveUserFromChan(i, ConnectionIndex)
'ReturnChannelModes(Channel)
'LookupUserIndexFromAlias(Alias)
'LookupUserAliasFromIndex(ConnectionIndex)
'HasUserGotMode(ModeFlag, ConnectionIndex) As Boolean
'ReturnAccessLevel(ConnectionIndex)
'ReturnUserAccessText(ConnectionIndex)

Public Sub LogEvent(EventToLog)
    Open App.Path & "\debug.log" For Append As #1
        Print #1, EventToLog
    Close #1
End Sub
Public Function RehashServer()

End Function
Public Sub NotifyOfKill(UsernameFrom, UsernameKilled, Message)
    KillNotify = "Services: " & UsernameFrom & " killed " & UsernameKilled & " [" & Message & "]"
    For i = 1 To intMaxUsers
        If InStr(Users(i).Modes, "k") <> 0 Then
            Call basFunctionsIO.SendDataToClient(i, KillNotify)
        End If
    Next
End Sub

Public Sub GenerateServicesPassword()
    'Generates a new services password (AccessLevel=8)
    'Perform before ANY and ALL operations involving "ServicesPassword" eg SetUserModes
    Randomize
    ServicesPassword = ""
    For i = 1 To 100
        Char = Chr(Int(Rnd * 255) + 1)
        ServicesPassword = ServicesPassword & Char
    Next i
End Sub

Public Function SetUserModes(ConnectionIndex, TargetIndex, Modes)
    'This is really archaic and messy... but it works.
    'Still, I really should recode it.
                    If ConnectionIndex = ServicesPassword Then
                        AccessLevel = 8 'Services are setting something.
                    Else
                        AccessLevel = basFunctions.ReturnAccessLevel(ConnectionIndex)
                    End If
                    With Users(TargetIndex)
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
                                        Modes2 = Left(Modes2, Result - 1) & Right(Modes2, Len(Modes2) - Result)
                                    End If
                                Case False
                                    'assume addmode
                                    'If we havent got it...
                                    If InStr(Modes2, ModeChar) = 0 Then
                                        Select Case ModeChar
                                            Case "q", "U"
                                                If AccessLevel >= 5 Then
                                                    'Set it.
                                                    Modes2 = Modes2 & ModeChar
                                                Else
                                                    Call basFunctionsIO.SendDataToClient(ConnectionIndex, "Services: You may not set these modes.")
                                                End If
                                            Case "N"
                                                If AccessLevel = 8 Then
                                                    Modes2 = Modes2 & ModeChar
                                                Else
                                                Call basFunctionsIO.SendDataToClient(ConnectionIndex, "Services: You may not set these modes.")
                                                End If
                                            Case "T"
                                                If AccessLevel = 6 Then
                                                    Modes2 = Modes2 & ModeChar
                                                Else
                                                    Call basFunctionsIO.SendDataToClient(ConnectionIndex, "Services: You may not set these modes.")
                                                End If
                                            Case "C"
                                                If AccessLevel >= 6 Then
                                                    Modes2 = Modes2 & ModeChar
                                                Else
                                                    Call basFunctionsIO.SendDataToClient(ConnectionIndex, "Services: You may not set these modes.")
                                                End If
                                            Case "a"
                                                If AccessLevel >= 5 Then
                                                    Modes2 = Modes2 & ModeChar
                                                Else
                                                    Call basFunctionsIO.SendDataToClient(ConnectionIndex, "Services: You may not set these modes.")
                                                End If
                                            Case "A"
                                                If AccessLevel >= 4 Then
                                                    Modes2 = Modes2 & ModeChar
                                                Else
                                                    Call basFunctionsIO.SendDataToClient(ConnectionIndex, "Services: You may not set these modes.")
                                                End If
                                            Case "o"
                                                If AccessLevel >= 3 Then
                                                    Modes2 = Modes2 & ModeChar
                                                Else
                                                    Call basFunctionsIO.SendDataToClient(ConnectionIndex, "Services: You may not set these modes.")
                                                End If
                                            Case "O"
                                                If AccessLevel >= 2 Then
                                                    Modes2 = Modes2 & ModeChar
                                                Else
                                                    Call basFunctionsIO.SendDataToClient(ConnectionIndex, "Services: You may not set these modes.")
                                                End If
                                            Case Else
                                                'Just add it.
                                                Modes2 = Modes2 & ModeChar
                                        End Select
                                    End If
                            End Select
Skip:
                        Next j
                        .Modes = Modes2
                    End With
End Function

Public Function IsUserInvisible(ConnectionIndex)
    Temp = InStr(Users(ConnectionIndex).Modes, "I")
    Select Case Temp
        Case 0
            IsUserInvisible = False
        Case Else
            IsUserInvisible = True
    End Select
End Function

Public Function IsUserAChanOp(ConnectionIndex, ChannelIndex)
    IsUserAChanOp = False
    If UCase(Users(ConnectionIndex).Alias) = UCase(Channels(ChannelIndex).ChannelFounder) Then
        IsUserAChanOp = True
    End If
    If UCase(Users(ConnectionIndex).Alias) = UCase(Channels(ChannelIndex).ChannelCoFounder) Then
        IsUserAChanOp = True
    End If
End Function

Public Function IsUserGlobalProtected(ConnectionIndex)
    'Is user +q
    Temp = InStr(Users(ConnectionIndex).Modes, "q")
    Select Case Temp
        Case 0
            IsUserGlobalProtected = False
        Case Else
            IsUserGlobalProtected = True
    End Select
End Function

Public Function IsUserAMonitorOp(ConnectionIndex)
    'Is user +U
    Temp = InStr(Users(ConnectionIndex).Modes, "U")
    Select Case Temp
        Case 0
            IsUserAMonitorOp = False
        Case Else
            IsUserAMonitorOp = True
    End Select
End Function

Public Function AddUserToChan(i, ConnectionIndex)
    'Lets a user join a channel.
    With Channels(i)
        For a = 1 To .TotalUsers + 1
            'Are we on? If so, EXIT!
            If .ChannelUsers(a) = ConnectionIndex Then
                Exit Function
            End If
        Next a
        For a = 1 To 200
            'If we find a free indicie, then use it!
            If .ChannelUsers(a) = 0 Then
                .ChannelUsers(a) = ConnectionIndex
                .TotalUsers = .TotalUsers + 1
                Users(ConnectionIndex).TotalChannels = Users(ConnectionIndex).TotalChannels + 1
                Call SendDataToClient(ConnectionIndex, "CHANJ" & .ChannelName & Chr(3) & .ChannelTopic)
                IsInvisible = basFunctions.IsUserInvisible(ConnectionIndex)
                Select Case IsInvisible
                    Case False
                        Call basFunctionsIO.SendMessageToChannel(Channel, "Services", Users(ConnectionIndex).Alias & " joined the channel.")
                    Case True
                        Call basFunctionsIO.SendGlobalMessageToOperators("+I user " & Users(ConnectionIndex).Alias & " has joined channel " & .ChannelName, "Services")
                End Select
                Exit Function
            End If
        Next a
    End With
    'If we get here, chan is full (probably :S)
End Function

Public Function RemoveUserFromChan(ChannelIndex, ConnectionIndex, ExtraInfo)
    With Channels(ChannelIndex)
        For a = 1 To .TotalUsers + 1
            'Are they on? If so, remove em!
            If .ChannelUsers(a) = ConnectionIndex Then
                .ChannelUsers(a) = 0
                .TotalUsers = .TotalUsers - 1
                Call SendDataToClient(ConnectionIndex, "PARTC" & .ChannelName)
                IsInvisible = basFunctions.IsUserInvisible(ConnectionIndex)
                Select Case IsInvisible
                    Case False
                        Call basFunctionsIO.SendMessageToChannel(.ChannelName, "Services", ExtraInfo)
                End Select
            End If
        Next a
    End With
End Function
Public Function ReturnChannelModes(Channel)
    For i = 1 To 500
        With Channels(i)
            If UCase(.ChannelName) = UCase(Channel) Then
                ReturnChannelModes = .ChannelModes
                Exit Function
            End If
        End With
    Next i
End Function
Public Function LookupUserIndexFromAlias(Alias)
    'Returns 0 if not found.
    For i = 1 To intMaxUsers
        With Users(i)
            If UCase(.Alias) = UCase(Alias) Then
                'Found it!
                LookupUserIndexFromAlias = i
                Exit Function
            End If
        End With
    Next i
End Function

Public Function LookupUserAliasFromIndex(ConnectionIndex)
        With Users(ConnectionIndex)
            LookupUserAliasFromIndex = .Alias
        End With
End Function

'Public Function HasUserGotMode(ModeFlag, ConnectionIndex) As Boolean
'    'Not used any more. Kept for the moment in case I find a use for it... :P
'    'This checks if user on <connectionindex> has flag <modeflag>
'    'Returns true or false.
'    If Len(ModeFlag) <> 1 Then Exit Function
'    With Users(ConnectionIndex)
'        Select Case InStr(.Modes, ModeFlag)
'            Case 0
'                'Not found.
'                HasUserGotMode = False
'            Case 1
'                'found
'                HasUserGotMode = True
'        End Select
'    End With
'End Function

Public Function ReturnAccessLevel(ConnectionIndex)
    With Users(ConnectionIndex)
        Result = 0
        If InStr(.Modes, "O") <> 0 Then Result = 1 'LocOp
        If InStr(.Modes, "o") <> 0 Then Result = 2 'GlobOp
        If InStr(.Modes, "A") <> 0 Then Result = 3 'ServAdmin
        If InStr(.Modes, "a") <> 0 Then Result = 4 'ServiceAdmin
        If InStr(.Modes, "C") <> 0 Then Result = 5 'CoAdmin
        If InStr(.Modes, "T") <> 0 Then Result = 6 'TechAdmin
        If InStr(.Modes, "N") <> 0 Then Result = 7 'NAdmin
    End With
        ReturnAccessLevel = Result
End Function

Public Function ReturnUserAccessText(ConnectionIndex)
    With Users(ConnectionIndex)
        Result = "nRC User"
        If InStr(.Modes, "O") <> 0 Then Result = Result & ", LocalOp"
        If InStr(.Modes, "o") <> 0 Then Result = Result & ", GlobalOp"
        If InStr(.Modes, "A") <> 0 Then Result = Result & ", ServerAdmin"
        If InStr(.Modes, "a") <> 0 Then Result = Result & ", ServiceAdmin"
        If InStr(.Modes, "C") <> 0 Then Result = Result & ", CoAdmin"
        If InStr(.Modes, "T") <> 0 Then Result = Result & ", TechAdmin"
        If InStr(.Modes, "N") <> 0 Then Result = Result & ", NetAdmin"
    End With
        ReturnUserAccessText = Result
End Function
