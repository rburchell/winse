VERSION 5.00
Object = "{3B7C8863-D78F-101B-B9B5-04021C009402}#1.2#0"; "RICHTX32.OCX"
Begin VB.Form frmServer 
   BackColor       =   &H00000000&
   Caption         =   "#"
   ClientHeight    =   2880
   ClientLeft      =   165
   ClientTop       =   855
   ClientWidth     =   6330
   LinkTopic       =   "Form1"
   ScaleHeight     =   2880
   ScaleWidth      =   6330
   StartUpPosition =   3  'Windows Default
   Visible         =   0   'False
   Begin VB.Timer tmrPollSocket 
      Interval        =   100
      Left            =   3720
      Top             =   2280
   End
   Begin VB.Timer tmrFlushBuffer 
      Interval        =   1000
      Left            =   4320
      Top             =   2280
   End
   Begin VB.Timer tmrEoS 
      Enabled         =   0   'False
      Interval        =   5000
      Left            =   4800
      Top             =   2280
   End
   Begin VB.Timer tmrResetFlood 
      Interval        =   5000
      Left            =   5280
      Top             =   2280
   End
   Begin VB.Timer tmrPingUplink 
      Enabled         =   0   'False
      Interval        =   20000
      Left            =   5760
      Top             =   2280
   End
   Begin VB.TextBox txtCmd 
      BackColor       =   &H0000C000&
      ForeColor       =   &H00000000&
      Height          =   285
      Left            =   600
      TabIndex        =   0
      Top             =   2520
      Width           =   5655
   End
   Begin RichTextLib.RichTextBox rtbStatusWindow 
      Height          =   2295
      Left            =   120
      TabIndex        =   1
      Top             =   120
      Width           =   6135
      _ExtentX        =   10821
      _ExtentY        =   4048
      _Version        =   393217
      BackColor       =   49152
      Enabled         =   -1  'True
      ScrollBars      =   2
      TextRTF         =   $"frmServer.frx":0000
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "Lucida Console"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
   End
   Begin VB.Label lblCmd 
      BackStyle       =   0  'Transparent
      Caption         =   "Cmd:"
      ForeColor       =   &H0000C000&
      Height          =   255
      Left            =   120
      TabIndex        =   2
      Top             =   2520
      Width           =   375
   End
   Begin VB.Menu mnuMain 
      Caption         =   "&Main"
      Begin VB.Menu mnuMainReconnect 
         Caption         =   "&Reconnect"
      End
      Begin VB.Menu mnuMainExit 
         Caption         =   "&Exit"
      End
   End
End
Attribute VB_Name = "frmServer"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
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
'
' Contact Maintainer: w00t[w00t@netronet.org]
Option Explicit

' Note on this form:
'  Eventually, we will have no interface (maybe a web
'  interface on port81 or some such crap??) and therefore,
'  _dont_ go doing a lot of interface work, it wont be
'  there long ;) It's only there for testing stuff atm. --w00t

Public tcpServer As New TCPSocket

Private Sub Form_Initialize()
    Set tcpServer = New TCPSocket
End Sub

Private Sub Form_Load()
    'Set stuff up :P - Should we really connect here?
    Call basFunctions.LogEvent(basMain.LogTypeNotice, "Starting " & basMain.AppName & " " & basMain.AppVersion & "[" & basMain.AppCompileInfo & "]")
    Me.Caption = basMain.AppName & "-" & basMain.AppVersion & "[" & basMain.AppCompileInfo & "]"
    frmServer.Show
On Error GoTo NoConnect
    Call basFunctions.LogEvent(basMain.LogTypeNotice, "Connecting...")
    tcpServer.Connect basMain.Config.UplinkHost, basMain.Config.UplinkPort
    tcpServer_Connect
    Exit Sub
NoConnect:
    Call basFunctions.LogEvent(basMain.LogTypeError, Replies.SanityCheckCantConnectToIRCd)
    End
End Sub

Private Sub Form_Resize()
    'Resize everything appropriately, should be foolproof.
    On Error Resume Next
    rtbStatusWindow.Width = Me.Width - 350
    rtbStatusWindow.Height = Me.Height - 1300
    txtCmd.Top = rtbStatusWindow.Height + 140
    txtCmd.Width = Me.Width - 800
    lblCmd.Top = txtCmd.Top + 50
End Sub

Private Sub tcpServer_Close()
    'Don't ping, we dont have a connection to server.
    tmrPingUplink.Enabled = False
    'The socket is dead now. We have to close it and
    'create a new one.
    'To best simulate how MSWinSock worked, we will
    'recreate the socket, but we will NOT open it. -aquanight
        'Where do we recreate it though? You set it to Nothing...?! --w00t
    On Error Resume Next 'Any exception is non-fatal.
    tcpServer.Shutdown 2
    tcpServer.Close
    tmrPollSocket.Enabled = False
    Set tcpServer = Nothing
    Me.Caption = AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - Disconnected"
End Sub

Private Sub tcpServer_Connect()
    'We have connected, inform remote server that we are a server connection. --w00t
    tmrPingUplink.Enabled = True
    tmrPollSocket.Enabled = True
    tmrEoS.Enabled = True
    Me.Caption = AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - Connected"
    rtbStatusWindow.Text = ""
    Call tcpServer.Send("PASS :" & basMain.Config.UplinkPassword & vbCrLf)
    Call tcpServer.Send("SERVER " & basMain.Config.ServerName & " 1 :" & " " & basMain.Config.ServerDescription & vbCrLf)
End Sub

Private Sub tcpServer_DataArrival()
    Dim HadAnError As Boolean   'set to true to End once the buffer is empty.
                                'Use if something like "ERROR :Closing Link: [127.0.0.1] (Server Exists)"
    Dim Buffer As String        'What we get sent.
    Dim CurrentCmd As String    'What we are currently looking at, only to be used by parser.
    Dim Parameters() As String  'An array of words from the buffer.
    Dim i As Integer            'Multipurpose counter\index variable.
    Dim j As Integer            'Multipurpose counter\index variable.
    
    Buffer = tcpServer.Recv()
    
    Buffer = VBA.Left(Buffer, InStr(Buffer, Chr(0)) - 1)
    
    'I am SO sick of dealing with ":"s! --w00t
    If Left(Buffer, 1) = ":" Then
        Buffer = Right(Buffer, Len(Buffer) - 1)
    End If
    
    'Buffer will be something like ":w00t PRIVMSG OperServ :help\r\n:w00t _
    'PRIVMSG OperServ :GLOBAL Services going down\r\n"
    
    rtbStatusWindow.Text = rtbStatusWindow.Text + Buffer
    rtbStatusWindow.SelStart = Len(rtbStatusWindow.Text)

    'We want it in an array of words, ParseBuffer does this.
    Do While InStr(Buffer, vbCrLf) <> 0
        'START PARSE CODE
        i = InStr(Buffer, vbCrLf)
        CurrentCmd = Left(Buffer, i - 1)
        If Buffer <> "" Then Buffer = Right(Buffer, Len(Buffer) - i - 1)
        If CurrentCmd = "" Then Exit Sub
        Parameters() = basFunctions.ParseBuffer(CurrentCmd)
        'END PARSE CODE
        
        'Server stuff
        Select Case Parameters(0)
            'We dont need to respond to their pings, since we ping them, right?
            Case "ERROR"
                'Oh dear.
                'Attempt to send a dying scream, and log it too!
                Call basFunctions.LogEventWithMessage(basMain.LogTypeError, CurrentCmd)
                HadAnError = True
            Case "NICK"
                'This is for a new user.
                'P[0] - NICK
                'P[1] - To
                'P[2] - Timestamp??
                For i = 0 To basMain.TotalUsers + 1
                    If basMain.Users(i).Nick = "" Then basMain.NextFreeUserIndex = i
                Next i

                'add user to our array
                With basMain.Users(NextFreeUserIndex)
                    .Nick = Parameters(1)
                    .MsgStyle = basMain.Config.DefaultMessageType
                End With
                basMain.TotalUsers = basMain.TotalUsers + 1
                i = basFunctions.ReturnUserIndex(Parameters(1))
                'If nick registered...
                If basFunctions.IsNickRegistered(Parameters(1)) Then
                    'and not identified to by this user then inform them so. Otherwise they are
                    'identified to that nick, so ignore.
                    If UCase(basMain.Users(i).IdentifiedToNick) <> UCase(Parameters(1)) Then
                        Call basFunctions.SendMessage(basMain.Service(1).Nick, Parameters(1), Replies.NickServNickRegistered)
                    End If
                End If
        End Select

        'stuff from a user.
        Select Case Parameters(1)
            Case "PRIVMSG"
                'P[0] - Sender
                'P[1] - PRIVMSG
                'P[2] - Reciever
                'P[3>] - Message
                i = basFunctions.ReturnUserIndex(Parameters(0))
                Call basMain.HandlePrivateMessage(CurrentCmd)
                For j = 0 To basMain.TotalUsers
                    With basMain.Users(j)
                        If UCase(Parameters(0)) = UCase(.Nick) Then
                            Call basFunctions.CheckFloodLevel(j)
                            Exit For
                        End If
                    End With
                    DoEvents
                Next j
            Case "SMO"
                'EoS sends "services connected" message.
                tmrEoS.Enabled = True
            Case "KILL"
                'This reintroduces any of our guys if they get killed.
                'P[0] - From
                'P[1] - KILL
                'P[2] - Target
                'P[3] - Path?
                'P[4] - Reason
                For i = 0 To basMain.TotalServices - 1
                    If UCase(Parameters(2)) = UCase(basMain.Service(i).Nick) Then
                        Call basFunctions.IntroduceClient(basMain.Service(i).Nick, basMain.Service(i).Hostmask, basMain.Service(i).Name)
                    End If
                Next
                'send out a scream...
                Call basFunctions.NotifyAllUsersWithServicesAccess(Parameters(0) & " issued a KILL for a service client!")
                'kill the killer!
                i = basFunctions.ReturnUserIndex(Right(Parameters(0), Len(Parameters(0)) - 1))
                Call basFunctions.KillUser(i, "Don't kill services clients!")
            Case "QUIT"
                'Deal with client quits.
                'P[0] - Sender
                'P[1] - QUIT
                'P[2>] - Message
                i = basFunctions.ReturnUserIndex(Parameters(0))
                If i = -1 Then
                    Call basFunctions.NotifyAllUsersWithServicesAccess(Replace(Replies.SanityCheckInvalidIndex, "%n", "frmServer.tcpServer_DataArrival"))
                    Exit Sub
                End If
                With basMain.Users(i)
                    .Nick = ""
                    .Modes = ""
                    .Requests = 0
                    .Access = 0
                End With
                If i = basMain.TotalUsers - 1 Then basMain.TotalUsers = basMain.TotalUsers - 1
            Case "NICK"
                'Nick _change_ (not a new user)
                'P[0] - Sender
                'P[1] - NICK
                'P[2] - To
                i = ReturnUserIndex(Parameters(0))
                If i = -1 Then
                    Call basFunctions.NotifyAllUsersWithServicesAccess(Replace(Replies.SanityCheckInvalidIndex, "%n", "frmServer.tcpServer_DataArrival"))
                    Exit Sub
                End If
                basMain.Users(i).Nick = Parameters(2)
                'UserId = basFunctions.ReturnUserIndex(Parameters(2))
                'If nick registered...
                If basFunctions.IsNickRegistered(Parameters(2)) Then
                    'and not identified to by this user then inform them so. Otherwise they are
                    'identified to that nick, so ignore.
                    If UCase(basMain.Users(i).IdentifiedToNick) <> UCase(Parameters(2)) Then
                        Call basFunctions.SendMessage(basMain.Service(1).Nick, Parameters(2), Replies.NickServNickRegistered)
                    End If
                End If
            Case "MODE"
                'Deal with mode changes.
                'P[0] - Sender
                'P[1] - MODE
                'P[2] - Target
                'P[3] - Modes
                'P[4>] - Affected entities (eg from a chanop)
                'P[(final)] - Timestamp? BUT: Only if sender is server...
                Dim IsChan As Boolean   'Is affected entity a chan? (only used here)
                If InStr(Parameters(2), "#") <> 0 Then IsChan = True
                If IsChan = False Then
                    For i = 0 To basMain.TotalUsers
                        With basMain.Users(i)
                        If UCase(Parameters(2)) = UCase(.Nick) Then
                            Call basFunctions.SetUserModes(i, Parameters(3))
                            Exit For
                        End If
                        End With
                        DoEvents
                    Next i
                Else
                    'Channel modes.
                    'Modes = basFunctions.SetChannelModes(basFunctions.ReturnChannelIndex(Parameters(2)), Parameters(3))
                    'Debug.Print Modes
                End If
            Case "JOIN"
                'P[0] - Sender
                'P[1] - JOIN
                'P[2] - #chan[,#chan]
                'ChanList = Parameters(2)
                Dim CurrentChan As String
                Dim MLock As String
                Dim Topic As String
                Dim Password As String
                Do While Len(Parameters(2)) > 0 <> 0
                    i = InStr(Parameters(2), ",")
                    If i <> 0 Then
                        'Multiple Channels
                        CurrentChan = Left(Parameters(2), i - 1)
                        Parameters(2) = Right(Parameters(2), Len(Parameters(2)) - i)
                    Else
                        'Single chan only.
                        CurrentChan = Parameters(2)
                        Parameters(2) = ""
                    End If
                    Password = basFileIO.GetInitEntry("channels.db", CurrentChan, "FounderPassword")
    
                    If basFunctions.ReturnChannelIndex(CurrentChan) = -1 Then
                        'new chan record required. lookup next free record in the array.
                        For i = 0 To basMain.TotalChannels + 1
                            If basMain.Channels(i).Name = "" Then basMain.NextFreeChannelIndex = i
                            DoEvents
                        Next i
                        Topic = basFileIO.GetInitEntry("channels.db", CurrentChan, "Topic")
                        MLock = basFileIO.GetInitEntry("channels.db", CurrentChan, "MLock")
                        'add channel to array.
                        With basMain.Channels(basMain.NextFreeChannelIndex)
                            .Name = CurrentChan
                            .Modes = MLock
                            .TotalChannelUsers = .TotalChannelUsers + 1
                        End With
                        basMain.TotalChannels = basMain.TotalChannels + 1
    
                        'Set modes and topic. IF WE NEED TO!
                        If Password <> "" Then
                            Call basFunctions.SendData(":" & basMain.Service(0).Nick & " TOPIC " & CurrentChan & " :" & Topic)
                            basFunctions.SendData (":" & basMain.Service(0).Nick & " MODE " & CurrentChan & " :" & MLock)
                        End If
                    End If
                    'See if its registered, and if so, set mlock and topic.
                    '(provided noone else is there)
                Loop
            Case "PART"
                'P[0] - Sender
                'P[1] - Cmd
                'P[2] - Chan
                If basFunctions.ReturnChannelIndex(Parameters(2)) = -1 Then
                    'chan doesnt exist.
                    Call basFunctions.NotifyAllUsersWithServicesAccess(Replies.SanityCheckLostChannel)
                    Exit Sub
                End If
                With basMain.Channels(basFunctions.ReturnChannelIndex(Parameters(2)))
                    .TotalChannelUsers = .TotalChannelUsers - 1
                    If .TotalChannelUsers <= 0 Then
                        .Modes = ""
                        .Name = ""
                        .TotalChannelUsers = -1
                    End If
                End With
            Case "TOPIC"
                'P[0] - Sender
                'P[1] - TOPIC
                'P[2] - Channel
                'P[3>] - Topic.
                Password = basFileIO.GetInitEntry("channels.db", Parameters(2), "FounderPassword", "")
                If Password <> "" Then
                    Topic = basFileIO.GetInitEntry("channels.db", Parameters(2), "Topic")
                    Call basFunctions.SendData(":" & basMain.Service(0).Nick & " TOPIC " & Parameters(2) & " :" & Topic)
                End If
        End Select
    Loop
    'if something went badly wrong, DIE!!!
    If HadAnError Then
        Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replies.SanityCheckCantRecover)
        End
    End If
End Sub

Private Sub Form_Unload(Cancel As Integer)
    Dim i As Single
    'Close the connection, if it's running.
    If Not tcpServer Is Nothing Then
        Call basFunctions.LogEvent(basMain.LogTypeNotice, Replies.ServicesTerminatingNormally)
        Call frmServer.tcpServer.Send("SQUIT " & basMain.UplinkName & " :" & Replies.ServicesTerminatingNormally)
        For i = 0 To 64000
            'Don't remove, else things dont get sent etc etc (ie SQUIT) >:( --w00t
        Next i
        On Error Resume Next
        tcpServer.Shutdown 2
        tcpServer.Close
    End If
End Sub

Private Sub tmrEoS_Timer()
    'EoS makes sure everything has been set up _before_ doing anything
    '(otherwise bad stuff can happen)
    'I know this is a bad hack, but what else can I do?? --w00t
    tmrEoS.Enabled = False
    Call basMain.IntroduceUsers
    Call basFunctions.GlobalMessage(Replies.ServicesConnectedToNetwork)
    Call basFunctions.LogEvent(basMain.LogTypeNotice, Replies.ServicesConnectedToNetwork)
    tmrFlushBuffer.Enabled = True
End Sub

Private Sub tmrFlushBuffer_Timer()
    'Send everything we have buffered.
    On Error GoTo Disable
    Dim i As Integer
    For i = 0 To basMain.BufferElements
        DoEvents
        DoEvents
        If basMain.Buffer(i) <> "" Then Call tcpServer.Send(basMain.Buffer(i))
        DoEvents
        DoEvents
        basMain.Buffer(i) = ""
    Next
    basMain.BufferElements = 0
    Exit Sub
Disable:
    'Services disconnected for the moment. So stop sending from the buffer :P
    tmrFlushBuffer.Enabled = False
End Sub

Private Sub tmrPingUplink_Timer()
    Call basFunctions.SendData("PING :" & basMain.Config.ServerName)
End Sub

Private Sub tmrPollSocket_Timer()
    If tcpServer.PollRead Then
        If tcpServer.Available = 0 Then
            'Readable, but no data? Host disconnected!
            tcpServer_Close
        Else
            tcpServer_DataArrival
        End If
    End If
End Sub

Private Sub tmrResetFlood_Timer()
    'Lower the "flood" level of each user connected.
    Dim i As Integer
    For i = 0 To basMain.TotalUsers
        With basMain.Users(i)
            If .Requests > 0 Then
                .Requests = .Requests - 1
            End If
        End With
        DoEvents
    Next i
End Sub

Private Sub txtCmd_KeyPress(KeyAscii As Integer)
    If KeyAscii = 13 Then
        basFunctions.SendData (txtCmd.Text)
        txtCmd.Text = ""
        KeyAscii = 0
    End If
End Sub


'*******************
'HANDLE MENUS
'*******************
Private Sub mnuMainExit_Click()
    Unload Me
    End
End Sub

Private Sub mnuMainReconnect_Click()
    tcpServer_Close
    Set tcpServer = New TCPSocket
    tcpServer.Connect basMain.UplinkHost, basMain.UplinkPort
    tcpServer_Connect
End Sub
