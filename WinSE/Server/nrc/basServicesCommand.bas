Attribute VB_Name = "basServicesCommand"
'Corrinia Services Command Module.
Global Const servicesName = "Corrinia"
Global Const servicesVersion = "0.0.0.1"

Public Sub ProcessCMD(Buffer, ConnectionIndex)
    'We have a request for services to do something. The first 5 characters of
    'Buffer tell us which service is required.
    
    Select Case UCase(Left(Buffer, 6))
        Case "SESERV"
            'Server services
            If frmServer.lblService(0).BackColor = Red Then
                GoTo SevDn
                Exit Sub
            End If
            Buffer = Right(Buffer, Len(Buffer) - 6) '6 chars for service name
            Call basSeServ.ProcessCMD(Buffer, ConnectionIndex)
        Case "OPSERV"
            'Operator services
            If frmServer.lblService(1).BackColor = Red Then
                GoTo SevDn
                Exit Sub
            End If
            Buffer = Right(Buffer, Len(Buffer) - 6)
            Call basOperServ.ProcessCMD(Buffer, ConnectionIndex)
        Case "NKSERV"
            'Nickname Services
            If frmServer.lblService(2).BackColor = Red Then
                GoTo SevDn
                Exit Sub
            End If
            Buffer = Right(Buffer, Len(Buffer) - 6)
            Call basNickServ.ProcessCMD(Buffer, ConnectionIndex)
        Case "CHSERV"
            'Channel services
            If frmServer.lblService(3).BackColor = Red Then
                GoTo SevDn
                Exit Sub
            End If
            Buffer = Right(Buffer, Len(Buffer) - 6)
            Call basChanServ.ProcessCMD(Buffer, ConnectionIndex)
        Case "USSERV"
            'User services
            If frmServer.lblService(5).BackColor = Red Then
                GoTo SevDn
                Exit Sub
            End If
            Buffer = Right(Buffer, Len(Buffer) - 6)
            Call basUserServ.ProcessCMD(Buffer, ConnectionIndex)
        Case "AGENT_"
            '_Agent_ :) bwahahaha...
            'Agent doesnt yet exist.
            If frmServer.lblService(4).BackColor = Red Then
                GoTo SevDn
                Exit Sub
            End If
    End Select
Exit Sub
SevDn:
    Call SendDataToClient(ConnectionIndex, "SEVDN")
End Sub
