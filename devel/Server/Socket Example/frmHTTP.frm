VERSION 5.00
Begin VB.Form frmHTTP 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "HTTP Get Program"
   ClientHeight    =   3900
   ClientLeft      =   45
   ClientTop       =   435
   ClientWidth     =   6285
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   3900
   ScaleWidth      =   6285
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton cmdAbort 
      Caption         =   "Disconnect"
      Enabled         =   0   'False
      Height          =   255
      Left            =   3120
      TabIndex        =   7
      Top             =   840
      Width           =   3135
   End
   Begin VB.CommandButton cmdGet 
      Caption         =   "GET"
      Default         =   -1  'True
      Height          =   255
      Left            =   120
      TabIndex        =   2
      Top             =   840
      Width           =   3015
   End
   Begin VB.TextBox txtResults 
      BeginProperty Font 
         Name            =   "Courier New"
         Size            =   9.75
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   2295
      Left            =   120
      Locked          =   -1  'True
      MultiLine       =   -1  'True
      ScrollBars      =   3  'Both
      TabIndex        =   3
      Top             =   1560
      Width           =   6135
   End
   Begin VB.TextBox txtURL 
      Height          =   285
      Left            =   1440
      TabIndex        =   1
      Top             =   480
      Width           =   4815
   End
   Begin VB.TextBox txtServer 
      Height          =   285
      Left            =   1440
      TabIndex        =   0
      Top             =   120
      Width           =   4815
   End
   Begin VB.Label lblStatus 
      Caption         =   "Status: Ready"
      Height          =   255
      Left            =   120
      TabIndex        =   6
      Top             =   1200
      Width           =   6135
   End
   Begin VB.Label lblGet 
      Caption         =   "URL:"
      Height          =   255
      Left            =   120
      TabIndex        =   5
      Top             =   480
      Width           =   1215
   End
   Begin VB.Label lblServer 
      Caption         =   "Target Server:"
      Height          =   255
      Left            =   120
      TabIndex        =   4
      Top             =   120
      Width           =   1215
   End
End
Attribute VB_Name = "frmHTTP"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private mAbort As Boolean

Private Sub cmdAbort_Click()
    mAbort = True
End Sub

Private Sub cmdGet_Click()
'Basic GET example.
    Dim s As TCPSocket
    On Error GoTo FinallyNoSD
    lblStatus.Caption = "Status: Preparing to connect..."
    txtServer.Enabled = False
    txtURL.Enabled = False
    cmdGet.Enabled = False
    cmdAbort.Enabled = True
    MousePointer = vbArrowHourglass
    If txtServer.Text = "" Then
        MsgBox "Enter a servername!", vbExclamation, "Error"
        Exit Sub
    End If
    Set s = New TCPSocket 'Allocate it :)
    txtResults.Text = ""
    'Select the local interface to use. We really don't
    'care so we use the "anything" address and specify
    'no preferred port.
    lblStatus.Caption = "Status: Connecting to server..."
    s.Bind "0.0.0.0", 0
    If mAbort Then Error 18
    'Connect to the server, port 80.
    s.Connect txtServer.Text, 80
    On Error GoTo Finally 'Shutdown valid now.
    If mAbort Then Error 18
    lblStatus.Caption = "Status: Connected. Requesting document..."
    'Send the get request.
    s.Send "GET /" + txtURL.Text + " HTTP/1.1" + vbCrLf + "Host: " + txtServer.Text + vbCrLf + vbCrLf
    'That should commense the inflood of data :)
    'Wait a bit.
    If mAbort Then Error 18
    lblStatus.Caption = "Status: Request sent. Waiting for data..."
    Do Until s.PollRead Or s.PollError
        DoEvents
        If mAbort Then Error 18
    Loop
    If s.PollError Then
        Err.Raise s.GetError, , "Socket error"
        GoTo Finally
    End If
    'If Avail = 0 and PollRead = True, then server
    'closed it!
    lblStatus.Caption = "Status: Receiving document..."
    While s.Available() > 0 Or s.PollRead = 0
        If s.PollRead Then txtResults.Text = txtResults.Text & s.Recv()
        If mAbort Then Error 18
        DoEvents
    Wend
    'Got here? Then Available = 0 and Poll = True
    'which means the connection is closed.
    'so close it.
    lblStatus.Caption = "Status: Host disconnected. Cleaning up..."
Finally:
    s.Shutdown (2)
FinallyNoSD:
    s.Close
    lblStatus.Caption = "Status: Disconnected"
    Set s = Nothing
    txtServer.Enabled = True
    txtURL.Enabled = True
    cmdGet.Enabled = True
    cmdAbort.Enabled = False
    MousePointer = vbDefault
    If mAbort Then
        lblStatus.Caption = "Status: Aborted. Ready"
    ElseIf Err <> 0 Then
        MsgBox "ERROR " & Err.Number & ": " & Err.Description, vbCritical, ":("
        lblStatus.Caption = "Status: Operation Failed - Ready"
    Else
        lblStatus.Caption = "Status: Ready"
    End If
    mAbort = False
End Sub
