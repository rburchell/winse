Imports Microsoft.VisualBasic
Imports System
Imports System.Net
Imports System.Net.Sockets
Imports System.Text

<ComClass(TCPSocket.ClassId, TCPSocket.InterfaceId, TCPSocket.EventsId)> _
Public Class TCPSocket

#Region "COM GUIDs"
    ' These  GUIDs provide the COM identity for this class 
    ' and its COM interfaces. If you change them, existing 
    ' clients will no longer be able to access the class.
    Public Const ClassId As String = "B155F2D4-8359-4356-8ABE-7C2574321038"
    Public Const InterfaceId As String = "15F32941-D051-42D4-8067-C1E52A3A018C"
    Public Const EventsId As String = "0181CA94-B50D-443B-859E-B33512E5627A"
#End Region

    ' A creatable COM class must have a Public Sub New() 
    ' with no parameters, otherwise, the class will not be 
    ' registered in the COM registry and cannot be created 
    ' via CreateObject.
    Public Sub New()
        MyBase.New()
        mSck = New Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp)
        mSck.Blocking = True
    End Sub

    Private mSck As Socket

    Public Sub Bind(ByVal localhost As String, ByVal localport As Integer)
        Dim ip As IPAddress
        Try
            ip = IPAddress.Parse(localhost)
        Catch ex As Exception
            ip = Dns.Resolve(localhost).AddressList(0)
        End Try
        mSck.Bind(New IPEndPoint(ip, localport))
    End Sub

    Public Sub Connect(ByVal host As String, ByVal port As Integer)
        Dim ip As IPAddress
        Try
            ip = IPAddress.Parse(host)
        Catch ex As Exception
            ip = Dns.Resolve(host).AddressList(0)
        End Try
        mSck.Connect(New IPEndPoint(ip, port))
    End Sub

    Public Sub Listen(Optional ByVal BackLog As Integer = 50)
        mSck.Listen(BackLog)
    End Sub

    Public Function Accept() As TCPSocket
        Dim t As New TCPSocket
        t.mSck.Close()
        t.mSck = Me.mSck.Accept()
        Return t
    End Function

    Public Sub Shutdown(ByVal method As Short)
        mSck.Shutdown(method)
    End Sub

    Public Sub Close()
        mSck.Close()
    End Sub

    Public Sub Send(ByVal data As String)
        If data Is Nothing OrElse data = "" Then Return
        Dim b() As Byte = Encoding.ASCII.GetBytes(data)
        mSck.Send(b)
    End Sub

    Public Function Recv() As String
        Dim b() As Byte
        b = New Byte(mSck.Available) {}
        mSck.Receive(b)
        Return Encoding.ASCII.GetString(b)
    End Function

    Public Function PollRead(Optional ByVal Timeout As Integer = 100) As Boolean
        Return (mSck.Poll(Timeout, SelectMode.SelectRead))
    End Function

    Public Function PollWrite(Optional ByVal Timeout As Integer = 100) As Boolean
        Return (mSck.Poll(Timeout, SelectMode.SelectWrite))
    End Function

    Public Function PollError(Optional ByVal Timeout As Integer = 100) As Boolean
        Return (mSck.Poll(Timeout, SelectMode.SelectError))
    End Function

    Public Function Available() As Integer
        Return mSck.Available
    End Function

    Public Function GetError() As Integer
        If Not PollError() Then Return 0
        Return mSck.GetSocketOption(SocketOptionLevel.Socket, SocketOptionName.Error)
	End Function

	Public ReadOnly Property RemoteIP() As String
		Get
			Return DirectCast(mSck.RemoteEndPoint, IPEndPoint).Address.ToString()
		End Get
	End Property
	Public ReadOnly Property RemoteHost() As String
		Get
			Try
				Return Dns.Resolve(DirectCast(mSck.RemoteEndPoint, IPEndPoint).Address.ToString()).HostName
			Catch ex As Exception
				Return DirectCast(mSck.RemoteEndPoint, IPEndPoint).Address.ToString()
			End Try
		End Get
	End Property
	Public ReadOnly Property RemotePort() As Integer
		Get
			Return DirectCast(mSck.RemoteEndPoint, IPEndPoint).Port
		End Get
	End Property
End Class


