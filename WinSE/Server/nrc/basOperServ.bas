Attribute VB_Name = "basOperServ"
'Corrinia Services Operator Services Module.
'Module Version: 0.0.0.6

'Commands:

'**********SERVICES CODE**********
Public Sub ProcessCMD(Buffer, ConnectionIndex)
    Cmd = Left(Buffer, 5)
    Buffer = Right(Buffer, Len(Buffer) - 5)
    If UCase(Cmd) = "OLINE" Then
        'ident to an oline
        Call OperActivate(Buffer, ConnectionIndex)
        With Users(ConnectionIndex)
            Buffer = "USMOD" & .Modes
            Call SendDataToClient(ConnectionIndex, Buffer)
        End With
        Exit Sub
    End If
    If basFunctions.ReturnAccessLevel(ConnectionIndex) < 2 Then
        'Insufficient permissions.
        Call SendDataToClient(ConnectionIndex, "OpServ: OperServ may only be used by Global Operators or higher.")
        Exit Sub
    End If
    Buffer = Trim(Buffer)
    Select Case UCase(Cmd)
        Case "KILLU"
            'Kill user.
            Buffer = Buffer & " (" & Users(ConnectionIndex).Alias & ")"
            Call KillU(Buffer, ConnectionIndex)
        Case "AOLIN"
            'Add O:Line
            Call AddOLine(Buffer, ConnectionIndex)
        Case "DOLIN"
            'Del O:Line
            Call DelOLine(Buffer, ConnectionIndex)
        Case "UMODE"
            'Set usermode.
            Call SetUserMode(Buffer, ConnectionIndex)
        Case "CMODE"
            'set chanmode
        Case Else
            Call SendDataToClient(ConnectionIndex, "OpServ: Command " & Cmd & " not recognised.")
    End Select
End Sub


'********************Individual Commands********************
Private Sub KillU(Buffer, ConnectionIndex)
    'Kill User. Disconnects a client from the network.
    On Error Resume Next
    BreakPoint = InStr(Buffer, " ")
    User = Left(Buffer, BreakPoint - 1)
    Buffer = Right(Buffer, Len(Buffer) - BreakPoint)
    For i = 1 To intMaxUsers
        With Users(i)
            If UCase(.Alias) = UCase(User) Then
                'First, notify them they are to be killed. then kill them.
                Call SendDataToClient(i, "Services: You have been killed by " & Users(ConnectionIndex).Alias & ": " & Buffer)
                'Call basFunctionsIO.SendGlobalMessageToOperators("User " & .Alias & " has been killed [" & Buffer & "]", "Services")
                Call basFunctions.NotifyOfKill(Users(ConnectionIndex).Alias, .Alias, Buffer)
                frmServer.tcpServer(i).Close
            End If
        End With
    Next i
End Sub
Private Sub OperActivate(Buffer, ConnectionIndex)
        On Error Resume Next
        Cmd = Trim(Buffer)
        BreakPoint = InStr(Cmd, " ")
        Username = Left(Cmd, BreakPoint - 1)
        Passwd = Right(Cmd, Len(Cmd) - BreakPoint)


        pass = basINIFunctions.GetInitEntry(Username, "PASSWORD")
        Flags = basINIFunctions.GetInitEntry(Username, "OFLAGS")
        
        Username = Users(ConnectionIndex).Alias

        If pass = Passwd Then
            'oper 'em!
            With Users(ConnectionIndex)
                FlagsToSet = Username & " " & Flags
                Call basFunctions.GenerateServicesPassword
                Call SetUserMode(FlagsToSet, ServicesPassword)
            End With
            For i = 1 To 1000
                DoEvents
            Next i
            'Call SendDataToClient(ConnectionIndex, "OpServ: You are now an operator.")
            Exit Sub
        End If
        Call SendDataToClient(ConnectionIndex, "OpServ: Incorrect password or user.")
End Sub
Private Sub DelOLine(Buffer, ConnectionIndex)
    'DOLIN <nick> <password> <flags>
    'Netadmin only
    If basFunctions.ReturnAccessLevel(ConnectionIndex) = 7 Then
        Cmd = Trim(Buffer)
        Username = Cmd
        r = basINIFunctions.SetInitEntry(Username, "PASSWORD", "")
        r = basINIFunctions.SetInitEntry(Username, "OFLAGS", "")
    End If
End Sub

Private Sub AddOLine(Buffer, ConnectionIndex)
    'AOLIN <nick> <password> <flags>
    'Netadmin only
    If basFunctions.ReturnAccessLevel(ConnectionIndex) >= 7 Then
        Cmd = Trim(Buffer)
        BreakPoint = InStr(Cmd, " ")
        Username = Left(Cmd, BreakPoint - 1)
        Cmd = Right(Cmd, Len(Cmd) - BreakPoint)
        BreakPoint = InStr(Cmd, " ")
        Password = Left(Cmd, BreakPoint - 1)
        Flags = Right(Cmd, Len(Cmd) - BreakPoint)

        r = basINIFunctions.SetInitEntry(Username, "PASSWORD", Password)
        r = basINIFunctions.SetInitEntry(Username, "OFLAGS", Flags)
    End If
End Sub

Private Sub SetUserMode(Buffer, ConnectionIndex)
            'fix: user no longer case sensetive.
            On Error Resume Next
            Cmd = Trim(Buffer)
            BreakPoint = InStr(Cmd, " ")
            User = Left(Cmd, BreakPoint - 1)
            Modes = Right(Cmd, Len(Cmd) - BreakPoint)
            For i = 1 To intMaxUsers
                With Users(i)
                    If UCase(.Alias) = UCase(User) Then
                        Call basFunctions.SetUserModes(ConnectionIndex, i, Modes)
                    End If
                    Call SendDataToClient(i, "USMOD" & Users(i).Modes)
                End With
            Next i
End Sub
