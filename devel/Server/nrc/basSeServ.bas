Attribute VB_Name = "basSeServ"
'Corrinia Services Server Services Module.
'Module Version: 0.0.0.5

'Commands:
'ENSRV <service>
' Enable the service <service>. Note that if ALLSRV is specified, all services are enabled.
'DASRV <service>
' Disable ("disallow") the service <service>. Note that if ALLSRV is specified, all services are enabled.
'GLOBM <message>
' Sends a message to ALL users on a server. Server admin and above ONLY!

'**********SERVICES CODE**********
'This is the parsing subroutine. The command is identified and sent to the appropriate subroutine.
Public Sub ProcessCMD(Buffer, ConnectionIndex)
    On Error Resume Next
    If basFunctions.ReturnAccessLevel(ConnectionIndex) < 3 Then
        'Insufficient permissions.
        Call SendDataToClient(ConnectionIndex, "SeServ: SeServ may only be used by Server Administrators or higher.")
        Exit Sub
    End If
    Cmd = UCase(Left(Buffer, 5))
    Buffer = Right(Buffer, Len(Buffer) - 6)
    Select Case Cmd
        Case "GLOBM"
            'Global message.
            Call GlobM(Buffer, ConnectionIndex)
        Case "ENSRV"
            'Enable Service
            'ENSRV <service>
            If basFunctions.ReturnAccessLevel(ConnectionIndex) < 5 Then
                'Insufficient permissions.
                Call SendDataToClient(ConnectionIndex, "SeServ: You do not have sufficient permissions to use this command.")
                Exit Sub
            End If
            Cmd = Buffer
            Call EnableService(Cmd)
        Case "DASRV"
            'disable service
            'CDSRV <service>
            If basFunctions.ReturnAccessLevel(ConnectionIndex) < 5 Then
                'Insufficient permissions.
                Call SendDataToClient(ConnectionIndex, "SeServ: You do not have sufficient permissions to use this command.")
                Exit Sub
            End If
            Cmd = Buffer
            Call DisableService(Cmd)
        Case Else
        Call SendDataToClient(ConnectionIndex, "SeServ: Command " & Cmd & " not recognised.")
    End Select
End Sub


'********************Individual Commands********************
Private Sub GlobM(Message, ConnectionIndex)
    Call basFunctionsIO.SendGlobalMessage(Message)
End Sub
Private Sub EnableService(Buffer)
            Select Case UCase(Buffer)
                Case "SESERV"
                        frmServer.lblService(0).BackColor = Green
                Case "OPSERV"
                        frmServer.lblService(1).BackColor = Green
                Case "NKSERV"
                        frmServer.lblService(2).BackColor = Green
                Case "CHSERV"
                        frmServer.lblService(3).BackColor = Green
                Case "HSSERV"
                        frmServer.lblService(4).BackColor = Green
                Case "USSERV"
                        frmServer.lblService(5).BackColor = Green
                Case "ALLSRV"
                        For i = 0 To 5
                                frmServer.lblService(i).BackColor = Green
                                frmServer.servicesState = 1
                        Next i
            End Select
End Sub

Private Sub DisableService(Buffer)
            Select Case UCase(Buffer)
                Case "SESERV"
                        frmServer.lblService(0).BackColor = Red
                Case "OPSERV"
                        frmServer.lblService(1).BackColor = Red
                Case "NKSERV"
                        frmServer.lblService(2).BackColor = Red
                Case "CHSERV"
                        frmServer.lblService(3).BackColor = Red
                Case "HSSERV"
                        frmServer.lblService(4).BackColor = Red
                Case "USSERV"
                        frmServer.lblService(5).BackColor = Red
                Case "ALLSRV"
                        For i = 0 To 5
                                frmServer.lblService(i).BackColor = Red
                                frmServer.servicesState = 0
                        Next i
            End Select
End Sub

'http://www.chat.net/cgi-bin/irc.cgi
'http://www.dentalfx.net/cgi-bin/cgiirc-0.5.2/irc.cgi
