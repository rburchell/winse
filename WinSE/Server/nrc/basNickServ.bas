Attribute VB_Name = "basNickServ"
'Corrinia Services Nickname Services Module.
'Module Version: 0.0.0.4

'Commands:
'IDENT <nickname>#<ip>
' Identify the IP address with the nickname

'**********SERVICES CODE**********
Public Sub ProcessCMD(Buffer, ConnectionIndex)
    Cmd = Left(Buffer, 5)
    Buffer = Right(Buffer, Len(Buffer) - 5)
    Select Case UCase(Cmd)
        Case "SVDAT"
            'Save database
        Case "LDDAT"
            'Load database
        Case "IDENT"
            'IsIRC not yet used...
            Call Identify(Buffer, ConnectionIndex, IsIRC)
        Case Else
            Call SendDataToClient(ConnectionIndex, "NkServ: Command " & Cmd & " not recognised.")
    End Select
End Sub


'********************Individual Commands********************
Private Sub Identify(Buffer, ConnectionIndex, IsIRC)
    'Check and make sure we dont have any duplicate usernames.
    BreakPoint = InStr(Buffer, Chr(3))
    nickname = Left(Buffer, BreakPoint - 1)
    VHost = Right(Buffer, Len(Buffer) - BreakPoint)
    With Users(ConnectionIndex)
        .Alias = nickname
        .VHost = VHost
        .IP = frmServer.tcpServer(ConnectionIndex).RemoteHostIP
        .Modes = "r"
        Call SendDataToClient(ConnectionIndex, "USMOD" & .Modes)
        #If Not ReleaseDescriptor Then
            LogAction = Date & "-" & Time & "| NOTIFICATION: User " & .Alias & " connected"
            Call basFunctions.LogEvent(LogAction)
            LogAction = ""
        #End If
    End With
End Sub
