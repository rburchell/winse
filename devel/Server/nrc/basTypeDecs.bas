Attribute VB_Name = "basMain"
Global Const UplinkHost = "localhost"
Global Const UplinkPort = "8000"
Global Const UplinkPassword = "SyMmEtIc"

Global intMaxUsers As Long

Global Const ServerName = "services.symmetic.net"
Global Const ServerNumeric = "100"
Global Const ServerDescription = "Symmetic Network Services"

Global Const AppName = ""
Global Const AppVersion = "0.0.0.1"
Global Const AppCompileInfo = "crysantheum"
Global Const AppCompileDate = "30/04/2004-17:30"
Global nick(10) As String 'for 10 services... not that you'd need that many.

Sub Main()
    'On Error Resume Next
    '#If Not ReleaseDescriptor Then
        LogAction = "---------------------------------------------------"
        LogAction = LogAction & vbCrLf & "   " & ServerName & " nRC[" & AppVersion & "] "
        LogAction = LogAction & vbCrLf & "       " & AppCompileDate & " CompileInfo=" & AppCompileInfo
        LogAction = LogAction & vbCrLf & "       UserModes=" & AvailableUserModes & " ChannelModes=" & AvailableChannelModes
        LogAction = LogAction & vbCrLf & "---------------------------------------------------"
        LogAction = LogAction & vbCrLf & Date & "-" & Time & "| Begin INIT"
        'Call basFunctions.LogEvent(LogAction)
        LogAction = ""
    '#End If
    
    nick(0) = "chanserv"
    nick(1) = "nickserv"
    nick(2) = "hostserv"
    nick(3) = "botserv"
    nick(4) = "operserv"
    nick(5) = "adminserv"
    nick(6) = "rootserv"
    nick(7) = "agent"
    nick(1)=
    nick(1)=
    nick(1)=
    
    
    
    
    
    
    
    
    
    
    basNumericsAndCommands.InitiateNumerics
    frmServer.Show
End Sub

Public Sub IntroduceUsers()
    'NICK w00t 1 1085992939 w00t 127.0.0.1 irc.symmetic.net 0 +iwx * :w00t
    basFunctionsIO.SendData ("NICK OperServ 1 " & Time & "Services services.symmetic.net services.symmetic.net OperServ")
    basFunctionsIO.SendCommand(nick(operserv),"MODE " & nick(operserv) & " +dqS")
End Sub

Public Sub HandlePrivateMessage(Buffer)
    Sender = basFunctions.GetSender(Buffer)
    Target = basFunctions.GetTarget(Buffer)
End Sub
