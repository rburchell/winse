Attribute VB_Name = "SockAPI"
Option Explicit

'In a module
Public Const MIN_SOCKETS_REQD As Long = 1
Public Const WS_VERSION_REQD As Long = &H101
Public Const WS_VERSION_MAJOR As Long = WS_VERSION_REQD \ &H100 And &HFF&
Public Const WS_VERSION_MINOR As Long = WS_VERSION_REQD And &HFF&
Public Const SOCKET_ERROR As Long = -1
Public Const WSADESCRIPTION_LEN = 257
Public Const WSASYS_STATUS_LEN = 129
Public Const MAX_WSADescription = 256
Public Const MAX_WSASYSStatus = 128
Public Type WSAData
    wVersion As Integer
    wHighVersion As Integer
    szDescription(0 To MAX_WSADescription) As Byte
    szSystemStatus(0 To MAX_WSASYSStatus) As Byte
    wMaxSockets As Integer
    wMaxUDPDG As Integer
    dwVendorInfo As Long
End Type
Type WSADataInfo
    wVersion As Integer
    wHighVersion As Integer
    szDescription As String * WSADESCRIPTION_LEN
    szSystemStatus As String * WSASYS_STATUS_LEN
    iMaxSockets As Integer
    iMaxUdpDg As Integer
    lpVendorInfo As String
End Type
Public Type HOSTENT
    hName As Long
    hAliases As Long
    hAddrType As Integer
    hLen As Integer
    hAddrList As Long
End Type
Public Declare Function WSAStartupInfo Lib "ws2_32.dll" Alias "WSAStartup" (ByVal wVersionRequested As Integer, lpWSADATA As WSADataInfo) As Long
Public Declare Function WSACleanup Lib "ws2_32.dll" () As Long
Public Declare Function WSAGetLastError Lib "ws2_32.dll" () As Long
Public Declare Function WSAStartup Lib "ws2_32.dll" (ByVal wVersionRequired As Long, lpWSADATA As WSAData) As Long

'How big this is hardly matters. This could be 2^32 blah
'if we really wanted to.
Public Const FD_SETSIZE = 64

Public Type sockaddr_in
    sin_familty As Integer
    sin_port As Integer
    sin_addr As Long 'The IP Address
    sin_zero(0 To 7) As Byte
End Type

Public Type FD_SET
    fd_count As Long
    fd_array(0 To 63) As Long
End Type

Public Type timeval
    tv_sec As Long
    tv_usec As Long
End Type

'Do we want IPv6 Support?

'Windows API Declarations for WinSock.
'All functions are in ws2_32.dll - I sure hope these are
'__stdcall... if not, we're screwed :O .
Public Declare Function accept_ Lib "ws2_32.dll" Alias "accept" (ByVal s As Long, addr As sockaddr_in, ByRef addrlen As Long) As Long
Public Declare Function bind_ Lib "ws2_32.dll" Alias "bind" (ByVal s As Long, name As sockaddr_in, ByVal namelen As Long) As Long
Public Declare Function closesocket Lib "ws2_32.dll" (ByVal s As Long) As Long
Public Declare Function connect_ Lib "ws2_32.dll" Alias "connect" (ByVal s As Long, name As sockaddr_in, ByVal namelen As Long) As Long
Public Declare Function gethostbyname Lib "WSOCK32" (ByVal szHost As String) As Long
Public Declare Function gethostname Lib "ws2_32.dll" (ByVal name As String, namelen As Long) As Long
Public Declare Function getnameinfo Lib "ws2_32.dll" (sa As sockaddr_in, ByVal salen As Long, ByVal Host As String, ByVal hostlen As Long, ByVal serv As String, ByVal servlen As Long, ByVal flags As Long) As Long
Public Declare Function getperrname Lib "ws2_32.dll" (ByVal s As Long, name As sockaddr_in, ByVal namelen As Long) As Long
Public Declare Function getsockname Lib "ws2_32.dll" (ByVal s As Long, name As sockaddr_in, ByVal namelen As Long) As Long
Public Declare Function getsockopt Lib "ws2_32.dll" (ByVal s As Long, ByVal level As Long, ByVal optname As Long, ByVal optval As String, ByRef optlen As Long) As Long
Public Declare Function inet_addr Lib "ws2_32.dll" (ByVal cp As String) As Long
Public Declare Function listen_ Lib "ws2_32.dll" Alias "listen" (ByVal s As Long, ByVal backlog As Long) As Long
Public Declare Function recv Lib "ws2_32.dll" (ByVal s As Long, ByVal buf As String, ByVal length As Long, ByVal flags As Long) As Long
Public Declare Function select_ Lib "ws2_32.dll" Alias "select" (ByVal nfds As Long, readfds As Any, writefds As Any, exceptfds As Any, timeout As timeval) As Long
Public Declare Function send Lib "ws2_32.dll" (ByVal s As Long, ByVal buf As String, ByVal length As Long, ByVal flags As Long) As Long
Public Declare Function setsockopt Lib "ws2_32.dll" (ByVal s As Long, ByVal level As Long, ByVal optname As Long, ByVal optval As String, ByVal optlen As Long) As Long
Public Declare Function shutdown Lib "ws2_32.dll" (ByVal s As Long, ByVal how As Long) As Long
Public Declare Function socket Lib "ws2_32.dll" (ByVal af As Long, ByVal stype As Long, ByVal protocol As Long) As Long
'Uh... what's the Win98 version of this?
'Wait, Win98 sux for stuff like IRC. So what the heck.
'Let's make this NT only :) .
Public Declare Function lstrlenA Lib "kernel32.dll" (ByVal lpString As String) As Long
Public Declare Sub CopyMemory Lib "kernel32.dll" (lpDest As Any, lpSrc As Any, ByVal cbLen As Long)

Private mRefCount As Long 'Will we have 2 billion sockets?

Public Function SocketsInitialize() As Boolean
    Dim WSAD As WSAData
    Dim sLoByte As String
    Dim sHiByte As String
    Dim lRet As Long
    lRet = WSAStartup(WS_VERSION_REQD, WSAD)
    If lRet <> 0 Then
        Err.Raise lRet, , "The 32-bit Windows Socket is not responding."
        SocketsInitialize = False
        Exit Function
    End If
    If WSAD.wMaxSockets < MIN_SOCKETS_REQD Then
        Err.Raise 5, , "This application requires a minimum of " & CStr(MIN_SOCKETS_REQD) & " supported sockets."
        SocketsInitialize = False
        Exit Function
    End If
    'must be OK, so lets do it
    SocketsInitialize = True
End Function

Public Function HiByte(ByVal wParam As Integer)
    HiByte = wParam \ &H100 And &HFF&
End Function
Public Function LoByte(ByVal wParam As Integer)
    LoByte = wParam And &HFF&
End Function
Public Sub SocketsCleanup()
    If WSACleanup() <> 0 Then
        Err.Raise 5, , "Socket error occurred in Cleanup."
    End If
End Sub

Public Function GetIPAddress(ByVal HostName As String) As String
    Dim sHostName As String * 256
    Dim lpHost As Long
    Dim Host As HOSTENT
    Dim dwIPAddr As Long
    Dim tmpIPAddr() As Byte
    Dim I As Integer
    Dim sIPAddr As String
    sHostName = Trim(HostName)
    lpHost = gethostbyname(sHostName)
    If lpHost = 0 Then
        Err.Raise WSAGetLastError(), , "Windows Sockets are not responding. " & "Unable to successfully get Host Name."
    End If
    CopyMemory Host, lpHost, Len(Host)
    CopyMemory dwIPAddr, Host.hAddrList, 4
    ReDim tmpIPAddr(1 To Host.hLen)
    CopyMemory tmpIPAddr(1), dwIPAddr, Host.hLen
    For I = 1 To Host.hLen
        sIPAddr = sIPAddr & tmpIPAddr(I) & "."
    Next
    GetIPAddress = Mid$(sIPAddr, 1, Len(sIPAddr) - 1)
End Function

Public Sub SockAdd()
    If mRefCount = 0 Then SocketsInitialize
    mRefCount = mRefCount + 1
End Sub

Public Sub SockDel()
    mRefCount = mRefCount - 1
    If mRefCount = 0 Then SocketsCleanup
End Sub
