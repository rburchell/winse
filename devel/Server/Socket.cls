VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Socket"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'This .cls is only for the VB6 side of things. It will
'replace the WinSock control on the form.

'Handle to the socket we are using.
Dim mSck As Long

'We need to provide an interface similar to that of the
'MS WinSock Control, except that we only allow sending
'strings.

'First, some internal methods to deal with an FD Set.
Private Sub FD_CLR(ByVal fd As Long, fset As FD_SET)
    Dim I As Long
    I = 0
    Do While I < fset.fd_count
        If fset.fd_array(I) = fd Then
            While I < fset.fd_count - 1
                fset.fd_array(I) = fset.fd_array(I + 1)
                I = I + 1
            Wend
            fset.fd_count = fset.fd_count - 1
            Exit Do
        End If
        I = I + 1
    Loop
End Sub

Private Sub FD_SET(ByVal fd As Long, fset As FD_SET)
    Dim I As Long
    I = 0
    Do While I < fset.fd_count - 1
        If (fset.fd_array(I) = fd) Then Exit Do
        I = I + 1
    Loop
    If I = fset.fd_count Then
        If fset.fd_count < FD_SETSIZE Then
            fset.fd_array(I) = fd
            fset.fd_count = fset.fd_count + 1
        End If
    End If
End Sub

Private Sub FD_ZERO(fset As FD_SET)
    fset.fd_count = 0
End Sub

Private Function FD_ISSET(ByVal fd As Long, fset As FD_SET) As Boolean
    Dim I As Long
    I = 0
    While I < fset.fd_count
        If fset.fd_array(I) = fd Then
            FD_ISSET = True
        End If
        I = I + 1
    Wend
End Function

Private Sub DoSock()
    If mSck = 0 Then
        'Stream Socket using TCP/IP.
        mSck = socket(2, 1, 6)
    End If
End Sub

Private Function GetAddr(ByVal addr As String) As Long
    Dim l As Long
    l = inet_addr(addr)
    If l = &HFFFFFFFF Then
        On Error GoTo ErrH
        addr = GetIPAddress(addr)
        l = inet_addr(addr)
    End If
    GetAddr = l
    Exit Function
ErrH:
    If Err.Number = 11001 Then 'WSAHOST_NOT_FOUND
        Err.Raise 13, , "Invalid address."
    Else
        Err.Raise Err.Number, , "Socket error."
    End If
End Function

'Select the interface for the socket.
Public Sub Bind(ByVal addr As String, ByVal port As Long)
    Dim l As Long
    l = GetAddr(addr)
    DoSock
    Dim s As sockaddr_in
    With s
        .sin_familty = 2 'IP
        .sin_addr = l
        .sin_port = port
    End With
    If bind_(mSck, s, LenB(s)) = -1 Then
        Err.Raise WSAGetLastError(), , "Socket failure - cannot bind socket."
    End If
End Sub

Public Sub Connect(ByVal addr As String, ByVal port As Long)
    Dim l As Long
    l = GetAddr(addr)
    DoSock
    Dim s As sockaddr_in
    With s
        .sin_addr = l
        .sin_familty = 2 'IP
        .sin_port = port
    End With
    If connect_(mSck, s, LenB(s)) = 0 Then
        Err.Raise WSAGetLastError(), , "Socket failure - cannot connect socket."
    End If
End Sub

Public Sub Listen(Optional ByVal backlog As Long = 50)
    DoSock
    If listen_(mSck, backlog) = 0 Then
        Err.Raise WSAGetLastError(), , "Socket failure - cannot open socket for listening."
    End If
End Sub

Public Function Accept() As socket
    If mSck = 0 Then
        Err.Raise 5, , "Socket is not open or listening."
    End If
    Dim sa As sockaddr_in
    If accept_(mSck, sa, LenB(sa)) = -1 Then
        Err.Raise WSAGetLastError(), , "Socket failure - cannot accept connection."
    End If
End Function

Public Sub CloseSock()
    If mSck = 0 Then
        Err.Raise 5, , "Socket is not open."
    End If
    If shutdown(mSck, 2) = 0 Then 'Both
        Err.Raise WSAGetLastError(), , "Socket failure - cannot shutdown socket."
    End If
    closesocket mSck
End Sub

Public Sub SendData(ByVal s As String)
    If mSck = 0 Then
        Err.Raise 5, , "Socket is not open."
    End If
    If send(mSck, s, Len(s), 0) = 0 Then
        Err.Raise WSAGetLastError(), , "Socket failure - cannot send to socket."
    End If
End Sub

Public Function RecvData(ByVal max As Long) As String
    Dim sbuf As String, lRet As Long
    sbuf = String(max, Chr(0))
    lRet = recv(mSck, sbuf, max, 0)
    If lRet = -1 Then
        Err.Raise WSAGetLastError(), , "Socket failure - cannot read from socket."
    End If
    sbuf = Left(sbuf, lRet)
    RecvData = sbuf
End Function

Public Function PollRead() As Boolean
    If mSck = 0 Then
        Err.Raise 5, , "Socket is not open."
    End If
    Dim f As FD_SET, tv As timeval
    FD_ZERO f
    FD_SET mSck, f
    tv.tv_sec = 0
    tv.tv_usec = 500
    If select_(1, f, ByVal 0&, ByVal 0&, tv) = 1 Then
        PollRead = True
    End If
    'Fall off, returning false.
End Function

Public Function PollWrite() As Boolean
    If mSck = 0 Then
        Err.Raise 5, , "Socket is not open."
    End If
    Dim f As FD_SET, tv As timeval
    FD_ZERO f
    FD_SET mSck, f
    tv.tv_sec = 0
    tv.tv_usec = 100
    If select_(1, ByVal 0&, f, ByVal 0&, tv) = 1 Then
        PollWrite = True
    End If
    'Fall off, returning false.
End Function

Public Function PollError() As Boolean
    If mSck = 0 Then
        Err.Raise 5, , "Socket is not open."
    End If
    Dim f As FD_SET, tv As timeval
    FD_ZERO f
    FD_SET mSck, f
    tv.tv_sec = 0
    tv.tv_usec = 100
    If select_(1, ByVal 0&, ByVal 0&, f, tv) = 1 Then
        PollError = True
    End If
    'Fall off, returning false.
End Function

Public Function Available(ByVal max As Long) As Long
    If PollRead = False Then Exit Function 'Ret 0
    Dim s As String
    Dim l As Long
    l = recv(mSck, s, 512, 2) 'Peek
    If l = -1 Then
        Err.Raise WSAGetLastError(), , "Socket failure - cannot read from socket."
    End If
    Available = l
End Function

Private Sub Class_Initialize()
    SockAdd
End Sub

Private Sub Class_Terminate()
    SockDel
End Sub
