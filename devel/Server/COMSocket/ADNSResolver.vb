Imports System.Net

<ComClass(ADNSResolver.ClassId, ADNSResolver.InterfaceId, ADNSResolver.EventsId)> _
Public Class ADNSResolver

#Region "COM GUIDs"
	' These  GUIDs provide the COM identity for this class 
	' and its COM interfaces. If you change them, existing 
	' clients will no longer be able to access the class.
	Public Const ClassId As String = "1BE94AA3-9C57-4EA2-83A0-6FFA7B85EFB3"
	Public Const InterfaceId As String = "F9BA9813-D42C-4EC9-825E-81F551AA110E"
	Public Const EventsId As String = "3F02AAA2-C248-44ED-9AE3-3D0CEA8DB8B8"
#End Region

	' A creatable COM class must have a Public Sub New() 
	' with no parameters, otherwise, the class will not be 
	' registered in the COM registry and cannot be created 
	' via CreateObject.
	Public Sub New()
		MyBase.New()
	End Sub

	Public Event ResolveDone(ByRef IPs() As String, ByVal HostName As String, ByVal Custom As Object)
	Public Event ResolveFail(ByVal ErrorCode As Integer, ByVal ErrorMessage As String, ByVal Custom As Object)

	Private Sub CBResolve(ByVal ar As IAsyncResult)
		Dim iph As IPHostEntry
		Try
			iph = Dns.EndResolve(ar)
		Catch ex As Sockets.SocketException
			RaiseEvent ResolveFail(ex.NativeErrorCode, ex.Message, ar.AsyncState)
			Return
		End Try
		Dim ips As New ArrayList
		For Each ip As IPAddress In iph.AddressList
			ips.Add(ip.ToString())
		Next
		RaiseEvent ResolveDone(ips.ToArray(GetType(String)), iph.HostName, ar.AsyncState)
	End Sub

	Public Sub Resolve(ByVal Address As String, Optional ByVal Custom As Object = Nothing)
		Dns.BeginResolve(Address, AddressOf CBResolve, Custom)
	End Sub
End Class


