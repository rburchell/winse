Attribute VB_Name = "sRootServ"
Public Const ModVersion = "0.0.0.1"

Public Sub RootservHandler(Cmd, Sender As String)
    On Error GoTo 0
    FirstSpace = InStr(Cmd, " ")
    Parameters = Right(Cmd, Len(Cmd) - FirstSpace)
    FirstSpace = InStr(Cmd, " ")
    If FirstSpace <> 0 Then Cmd = Left(Cmd, FirstSpace - 1)
    Select Case UCase(Cmd)
        Case "HELP"
            Call sRootServ.Help(Sender)
        Case "SHUTDOWN"
            'Call sRootServ.Shutdown(Sender)
        Case "VERSION"
            Call sRootServ.Version(Sender)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(6), Sender, "Unknown Command.")
    End Select
End Sub

Private Sub Help(Sender)
    Call basFunctions.SendMessage(basMain.Service(6), Sender, "RootServ Commands:")
    Call basFunctions.SendMessage(basMain.Service(6), Sender, " ")
    Call basFunctions.SendMessage(basMain.Service(6), Sender, "  CHANSNOOP  - Channel Snoop Feature")
    Call basFunctions.SendMessage(basMain.Service(6), Sender, "  FLOODRESET - Reset someone's flev")
    Call basFunctions.SendMessage(basMain.Service(6), Sender, "  REFERENCE  - Snoop symbol Reference")
    Call basFunctions.SendMessage(basMain.Service(6), Sender, "  INJECT     - Send RAW command to Services")
    Call basFunctions.SendMessage(basMain.Service(6), Sender, "  MKICK      - Mass Kick a given channel")
    Call basFunctions.SendMessage(basMain.Service(6), Sender, "  MINVITE    - Force all users from one channel to join another")
    Call basFunctions.SendMessage(basMain.Service(6), Sender, "  RAW        - Send RAW command to Server")
    Call basFunctions.SendMessage(basMain.Service(6), Sender, "  RESTART    - Saving Databases and restart Services")
    Call basFunctions.SendMessage(basMain.Service(6), Sender, "  SHUTDOWN   - Saving Databases and shutdown Services")
    Call basFunctions.SendMessage(basMain.Service(6), Sender, "  QUIT       - Terminating Services without saving Databases")
    Call basFunctions.SendMessage(basMain.Service(6), Sender, "  RAW        - Send RAW command to Server")
    Call basFunctions.SendMessage(basMain.Service(6), Sender, " ")
    Call basFunctions.SendMessage(basMain.Service(6), Sender, "  Notice: For more Information type /msg RootServ HELP command")
    Call basFunctions.SendMessage(basMain.Service(6), Sender, "  Notice: All commands sent to RootServ are logged!")

'LOG        - Search the log ex: *auspice*
'             In big networks the services may flood you
'BACKUPLOG  - To pack the services.log file with data
'             stamp in tgz format
End Sub

Private Sub Version(Sender)
    Call basFunctions.SendMessage(basMain.Service(4), Sender, AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(6) & "[" & sRootServ.ModVersion & "]")
End Sub
