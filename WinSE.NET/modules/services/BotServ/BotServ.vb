Public Class BotServ
	Inherits WinSECore.Module
	Dim sc As WinSECore.ServiceClient
	Public Sub New(ByVal c As WinSECore.Core)
		MyBase.New(c)
		sc = New WinSECore.ServiceClient
		sc.Nick = "BotServ"
		sc.Ident = "bot"
		sc.Host = c.Conf.ServerName
		sc.RealName = "Bot Registration Services"
		sc.Usermode = c.protocol.ServiceUMode()
		sc.mainproc = AddressOf Me.DebugServMain
		sc.CmdHash.Add("HELP", AddressOf CmdHelp)
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
		c.API.ExecCommand(sc.CmdHash, DirectCast(Source, WinSECore.User), Message)
	End Sub
	Private Function CmdHelp(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean
		c.API.SendHelp(sc.node, Source, "BotServ", Args)
	End Function
End Class
