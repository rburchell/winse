Attribute VB_Name = "basUserServ"
'Corrinia Services IRC User Services Module.
'Module Version: 0.0.0.5

'Commands:

'**********SERVICES CODE**********
Public Sub ProcessCMD(Buffer, ConnectionIndex)
    Cmd = Left(Buffer, 5)
    Buffer = Right(Buffer, Len(Buffer) - 5)
    Select Case UCase(Cmd)
        Case "WHOIS"
            'whois user
            Call Whois(Buffer, ConnectionIndex)
        Case Else
            Call SendDataToClient(ConnectionIndex, "UsServ: Command " & Cmd & " not recognised.")
    End Select
End Sub

Private Sub Whois(Buffer, ConnectionIndex)
    'Whois a user. Note that the IP will only be returned if the whoiser is an oper.
    '+B desc added. +I filter added.
    User = Trim(Buffer)
    'Search for the nick.
    For i = 1 To intMaxUsers
        With Users(i)
            If UCase(.Alias) = UCase(User) Then
                'we found them. Now format the whois reply.
                If InStr(.Modes, "I") <> 0 And basFunctions.ReturnAccessLevel(ConnectionIndex) = 0 Then
                    GoTo SendWhois
                Else
                    GoTo DoWhois
                End If
            End If
        End With
    Next
    Exit Sub
DoWhois:
With Users(i)
    txt = "WHOIS: " & .Alias & vbCrLf
    Access = ReturnAccessLevel(ConnectionIndex)
    If Access <> 0 Then
        txt = txt & "  IP: " & .IP & vbCrLf
    End If
    If InStr(.Modes, "W") <> 0 Then
        'Tell them someone whois'd them!
        Call SendDataToClient(i, "UsServ: " & Users(ConnectionIndex).Alias & " attempted a WHOIS on you.")
    End If
    txt = txt & "  Modes: " & .Modes & vbCrLf
    txt = txt & "  User is on " & .TotalChannels & " channels" & vbCrLf
    txt = txt & "  VHost: " & .VHost & vbCrLf
    If InStr(.Modes, "H") <> 0 Then
        'They want to hide ops status...
        txt = txt & "  User Status: nRC User" & vbCrLf
    Else
        txt = txt & "  User Status: " & basFunctions.ReturnUserAccessText(i) & vbCrLf
    End If
    If InStr(.Modes, "B") <> 0 Then txt = txt & "  " & .Alias & " is a bot on " & ServerName & "."
    If InStr(.Modes, "I") <> 0 Then txt = txt & "  " & .Alias & " is an Invisble User (+I)." & vbCrLf
End With
    GoTo SendWhois
SendWhois:
    If txt = "" Then txt = "USER NOT FOUND"
    Call SendDataToClient(ConnectionIndex, "UsServ: " & txt)
    Exit Sub
End Sub
