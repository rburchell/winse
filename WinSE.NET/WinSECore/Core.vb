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
Option Explicit On 
Option Strict On
Option Compare Binary
Imports Microsoft.VisualBasic
Imports System
Imports System.Collections
Imports System.Collections.Specialized
'This is the Core of WinSE. Everything that ever happens in WinSE is controlled through here...
Public NotInheritable Class Core
	'All the service clients loaded by a module go in here.
	Public ReadOnly Clients As New ServiceClients
	'The API
	Public ReadOnly API As New API(Me)
	'The configuration.
	Public Conf As Configuration
	'Our side of the IRC Map.
	Public ServicesMap As Server
	'Uplink side of the IRC Map.
	Public IRCMap As Server
	'The IRCd Protocol Class.
	Public protocol As IRCd
	'SOCKET!
	Public sck As System.Net.Sockets.Socket
	'The instance of our Event sink.
	Public ReadOnly Events As New Events
	Public Sub New()
	End Sub
	'This initializes the core. Initialization involves loading the configuration and modules and stuff.
	Public Function Init(ByVal Args() As String) As Integer
		Events.FireLogMessage("Core.Initialization", "TRACE", "Entering Init()")
		Events.FireLogMessage("Core.Initialization", "TRACE", "Leaving Init()")
	End Function
	'The start of it all.
	Public Function Main(ByVal Args() As String) As Integer
		Events.FireLogMessage("Core.Initialization", "TRACE", "Entering Main()")
		Events.FireLogMessage("Core.Initialization", "TRACE", "Leaving Main()")
	End Function
End Class

Public Structure Password
	Public PassPhrase As String
	Private mCryptMethod As System.Type
	Public Property CryptMethod() As System.Type
		Get
			Return mCryptMethod
		End Get
		Set(ByVal Value As System.Type)
			If Not Value.IsSubclassOf(GetType(System.Security.Cryptography.HashAlgorithm)) Then Throw New ArgumentException("Invalid hasher type, must derive from System.Security.Cryptography.HashAlgorithm.")
			mCryptMethod = Value
		End Set
	End Property
	Public Shared Function HashPassword(ByVal password As String, ByVal method As System.Type) As String
		Dim hasher As System.Security.Cryptography.HashAlgorithm
		If method Is Nothing Then Return password
		If Not method.IsSubclassOf(GetType(System.Security.Cryptography.HashAlgorithm)) Then Throw New InvalidCastException
		hasher = DirectCast(method.GetConstructor(System.Type.EmptyTypes).Invoke(New Object(-1) {}), System.Security.Cryptography.HashAlgorithm)
		hasher.Initialize()
		Return System.Text.Encoding.ASCII.GetString(hasher.ComputeHash(System.Text.Encoding.ASCII.GetBytes(password)))
	End Function
	Public Overloads Overrides Function Equals(ByVal obj As Object) As Boolean
		If TypeOf obj Is Password Then
			With DirectCast(obj, Password)
				Return Me.PassPhrase = .PassPhrase AndAlso Me.CryptMethod.Equals(.CryptMethod)
			End With
		ElseIf TypeOf obj Is String Then
			Return HashPassword(DirectCast(obj, String), Me.CryptMethod) = Me.PassPhrase
		End If
	End Function
	Public Sub New(ByVal Password As String)
		Me.PassPhrase = Password
		mCryptMethod = Nothing
	End Sub
	Public Sub New(ByVal Password As String, ByVal Method As System.Type)
		If Not Method.IsSubclassOf(GetType(System.Security.Cryptography.HashAlgorithm)) Then Throw New ArgumentException("Invalid hasher type, must derive from System.Security.Cryptography.HashAlgorithm.")
		mCryptMethod = Method
	End Sub
End Structure

Public Structure Configuration
	Public ServerName As String
	Public ServerDesc As String
	Public ServerNumeric As Integer
	Public UplinkName As String
	Public UplinkPort As Short
	Public SendPass As String
	Public RecvPass As Password
End Structure