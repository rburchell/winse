Public Class DebugServ
	Inherits WinSECore.Module
	Dim sc As WinSECore.ServiceClient
	Public Sub New(ByVal c As WinSECore.Core)
		MyBase.New(c)
		sc = New WinSECore.ServiceClient
		sc.Nick = "DebugServ"
		sc.Ident = "debug"
		sc.Host = c.Conf.ServerName
		sc.RealName = "Debugging Services"
		sc.Usermode = c.protocol.InvisServiceUMode()
		sc.mainproc = AddressOf Me.DebugServMain
		sc.CmdHash.Add("HELP", AddressOf CmdHelp)
		sc.CmdHash.Add("DUMPCLIENT", AddressOf CmdDumpClient)
		sc.CmdHash.Add("DIE", AddressOf CmdDie)
	End Sub
	Public Overrides Function ModLoad(ByVal params() As String) As Boolean
		c.Clients.Add(sc)
		Return True
	End Function
	Public Overrides Sub ModUnload()
		c.Clients.Remove(sc)
	End Sub
	Public Sub DebugServMain(ByVal Source As WinSECore.IRCNode, ByVal Message As String)
		If Not TypeOf Source Is WinSECore.User Then Return
		If Not c.protocol.IsIRCop(DirectCast(Source, WinSECore.User)) Then
			DirectCast(Source, WinSECore.User).SendMessage(sc.node, DirectCast(Source, WinSECore.User), "Access denied")
		End If
		c.API.ExecCommand(sc.CmdHash, DirectCast(Source, WinSECore.User), Message)
	End Sub
	Private Function CmdHelp(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean
		c.API.SendHelp(sc.node, Source, "DebugServ", Args)
	End Function
	Private Function CmdDie(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean
		c.Halt = WinSECore.Core.HaltCode.HALT_SHUTDOWN
	End Function
	Private Function CmdDumpClient(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean
		If Args.Length < 1 Then
			Source.SendMessage(sc.node, Source, "Syntax: " & WinSECore.API.FORMAT_BOLD & "DUMPUSER " & WinSECore.API.FORMAT_UNDERLINE & "nick" & WinSECore.API.FORMAT_UNDERLINE & WinSECore.API.FORMAT_BOLD)
			Return False
		End If
		Dim n As WinSECore.IRCNode, a() As String
		n = c.API.FindNode(Args(0))
		If n Is Nothing Then
			Source.SendMessage(sc.node, Source, "Client " & WinSECore.API.FORMAT_BOLD & Args(0) & WinSECore.API.FORMAT_BOLD & " does not exist.")
			Return False
		End If
		If TypeOf n Is WinSECore.User Then
			With DirectCast(n, WinSECore.User)
				Source.SendMessage(sc.node, Source, "Nick: " & .Nick)
				Source.SendMessage(sc.node, Source, "Numeric: " & .Numeric)
				Source.SendMessage(sc.node, Source, "Username: " & .Username & DirectCast(IIf(.VIdent <> "" AndAlso .VIdent <> .Username, " => " & .VIdent, ""), String))
				Source.SendMessage(sc.node, Source, "Hostname: " & .Hostname & DirectCast(IIf(.VHost <> "" AndAlso .VHost <> .Hostname, " => " & .VHost, ""), String))
				Source.SendMessage(sc.node, Source, "IP Address: " & .IP.ToString())
				Source.SendMessage(sc.node, Source, "Realname: " & .RealName)
				Source.SendMessage(sc.node, Source, "Server: " & .Server.Name)
				Source.SendMessage(sc.node, Source, "Timestamp: " & .TS.ToString())
				Source.SendMessage(sc.node, Source, "Usermodes: " & .Usermodes)
				Source.SendMessage(sc.node, Source, "Flood Level: " & .Since)
				If .SWhois <> "" Then Source.SendMessage(sc.node, Source, "SWhoIs: " & .SWhois)
				Source.SendMessage(sc.node, Source, DirectCast(IIf(.AwayMessage <> "", "Away: " & .AwayMessage, "Away? No"), String))
				If .Identifies.Count > 0 Then
					a = New String(.Identifies.Count) {}
					.Identifies.CopyTo(a, 0)
					Source.SendMessage(sc.node, Source, "Identified to nicks: " & Join(a, " "))
				Else
					Source.SendMessage(sc.node, Source, "Not identified.")
				End If
				Source.SendMessage(sc.node, Source, "Abuse Team? " & DirectCast(IIf(.AbuseTeam, "Yes", "No"), String))
				Source.SendMessage(sc.node, Source, "Access Flags: " & .Flags)
				For Each chptr As WinSECore.Channel In .Channels
					Source.SendMessage(sc.node, Source, "On channel: " & chptr.Name)
				Next
				Try
					Source.SendMessage(sc.node, Source, "Send Method: " & .SendMessage.Method.DeclaringType.ToString() & "." & .SendMessage.Method.Name)
				Catch ex As Exception
				End Try
			End With
		ElseIf TypeOf n Is WinSECore.Server Then
			With DirectCast(n, WinSECore.Server)
				Source.SendMessage(sc.node, Source, "Name: " & .Name)
				Source.SendMessage(sc.node, Source, "Numeric: " & .Numeric)
				Source.SendMessage(sc.node, Source, "Description: " & .Info)
				If .Parent Is Nothing Then
					Source.SendMessage(sc.node, Source, "Uplink: Direct link")
				Else
					Source.SendMessage(sc.node, Source, "Uplink: " & .Parent.Name)
				End If
			End With
		End If
	End Function
	Private Function CmdDumpChannel(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean

	End Function

End Class
