VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Server"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'For Server tracking.
Public ServerName As String
Public Hops As Long
Public Description As String
Public SID As String 'ServerID for some IRCds.
Public OurServer As Boolean 'This server behind us, or the uplink?
Private mCustom As Collection

Private Sub Class_Initialize()
    Set mCustom = New Collection
End Sub

Public Property Get Custom() As Collection
    Set Custom = mCustom
End Property

Public Sub Dispose()
    'Remove this server from the tracker, and remove all Users on this server.
    Call Servers.Remove(Me)
    Dim u As User
    For Each u In Users
        If u.Server = ServerName Then
            RaiseCustomEvent u, basEvents.UserQuit, u, "Lost in the netsplit"
            u.Dispose
        End If
    Next u
End Sub
