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
   Begin VB.Timer tmrSVSTick 
      Interval        =   250
      Left            =   3240
      Top             =   2280
   End
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
Option Explicit

' Note on this form:
'  Eventually, we will have no interface (maybe a web
'  interface on port81 or some such crap??) and therefore,
'  _dont_ go doing a lot of interface work, it wont be
'  there long ;) It's only there for testing stuff atm. --w00t

Public tcpServer As New TCPSocket

Private Sub Form_Initialize()
    On Error Resume Next
    Set tcpServer = New TCPSocket
    If Err.Number = 429 Then 'Can't create object.
        If MsgBox("Oh dear. We couldn't start up the socket engine. It could be because you  haven't installed COMSocket yet. Press OK for more information.", vbCritical + vbOKCancel, "Error!") = vbOK Then
            'I hate doing this. But Shell()'s stupidities leave me no choice.
            ShellExecuteA 0, vbNullString, "http://www.phpbbhost.biz/jason/phpbb/viewtopic.php?t=18", vbNullString, CurDir(), SW_SHOWMAXIMIZED
        End If
        'No connection, so trying to message won't work.
        LogEvent LogTypeError, "Unable to initialize socket engine. For more information, see http://www.phpbbhost.biz/jason/phpbb/viewtopic.php?t=18"
        End 'Die.
    End If
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
    
    'Buffer will be something like ":w00t PRIVMSG OperServ :help\r\n:w00t _
    'PRIVMSG OperServ :GLOBAL Services going down\r\n"
    rtbStatusWindow.Text = rtbStatusWindow.Text + Buffer
    rtbStatusWindow.SelStart = Len(rtbStatusWindow.Text)
    
    'I think it's time to retire this code... - aquanight
    While InStr(Buffer, vbCrLf) > 0
        CurrentCmd = VBA.Left(Buffer, InStr(Buffer, vbCrLf) - 1)
        Buffer = Mid(Buffer, InStr(Buffer, vbCrLf) + 2)
        Call ParseCmd(CurrentCmd)
    Wend
    'RIP The old command parser. The new one is now
    'official :P .
End Sub

Private Sub Form_Unload(Cancel As Integer)
    Dim i As Single
    'Close the connection, if it's running.
    If Not tcpServer Is Nothing Then
        Call basFunctions.LogEvent(basMain.LogTypeNotice, Replies.ServicesTerminatingNormally)
        On Error Resume Next
        Call frmServer.tcpServer.Send("SQUIT " & basMain.Config.UplinkName & " :" & Replies.ServicesTerminatingNormally)
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
    For i = 1 To basMain.Users.Count
        With basMain.Users(i)
            If .Requests > 0 Then
                .Requests = .Requests - 1
            End If
        End With
        DoEvents
    Next i
End Sub

Private Sub tmrSVSTick_Timer()
    sAdminServ.HandleTick CSng(tmrSVSTick.Interval) / 1000!
    sAgent.HandleTick CSng(tmrSVSTick.Interval) / 1000!
    sChanServ.HandleTick CSng(tmrSVSTick.Interval) / 1000!
    sDebugServ.HandleTick CSng(tmrSVSTick.Interval) / 1000!
    sMassServ.HandleTick CSng(tmrSVSTick.Interval) / 1000!
    sNickServ.HandleTick CSng(tmrSVSTick.Interval) / 1000!
    sOperServ.HandleTick CSng(tmrSVSTick.Interval) / 1000!
    sRootServ.HandleTick CSng(tmrSVSTick.Interval) / 1000!
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
    tcpServer.Connect basMain.Config.UplinkHost, basMain.Config.UplinkPort
    tcpServer_Connect
End Sub

