Public Class MemoServ
	Inherits WinSECore.Module
	Dim sc As WinSECore.ServiceClient
	Public Sub New(ByVal c As WinSECore.Core)
		MyBase.New(c)
		sc = New WinSECore.ServiceClient
		sc.Nick = "MemoServ"
		sc.Ident = "memo"
		sc.Host = c.Conf.ServerName
		sc.RealName = "Memorandum Services"
		sc.Usermode = c.protocol.ServiceUMode()
		sc.mainproc = AddressOf Me.DebugServMain
		sc.CmdHash.Add("HELP", AddressOf CmdHelp)
	End Sub
	Public Overrides Function ModLoad(ByVal params() As System.Collections.Specialized.StringCollection) As Boolean
		c.Clients.Add(sc)
	End Function
	Public Overrides Sub ModUnload()
		c.Clients.Remove(sc)
	End Sub
	Public Sub DebugServMain(ByVal Source As WinSECore.IRCNode, ByVal Message As String)
		If Not TypeOf Source Is WinSECore.User Then Return
		c.API.ExecCommand(sc.CmdHash, DirectCast(Source, WinSECore.User), Message)
	End Sub
	Private Function CmdHelp(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean
		c.API.SendHelp(Source, "MemoServ", Args)
	End Function

	Public Overrides Function GetHelpDirectory() As System.IO.DirectoryInfo

	End Function
End Class
