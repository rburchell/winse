Public Class NickServ
	Inherits WinSECore.Module
	Dim sc As WinSECore.ServiceClient
	Public Sub New(ByVal c As WinSECore.Core)
		MyBase.New(c)
		sc = New WinSECore.ServiceClient
		sc.Nick = "NickServ"
		sc.Ident = "nickname"
		sc.Host = c.Conf.ServerName
		sc.RealName = "Nickname Registration Services"
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
	Public Overrides Function GetHelpDirectory() As System.IO.DirectoryInfo

	End Function

	'Callbacks go below here.
	Private Function SendMsg_PRIVMSG(ByVal Source As WinSECore.IRCNode, ByVal Dest As WinSECore.User, ByVal Message As String) As Boolean
		c.protocol.SendMessage(Source, Dest, Message, False)
	End Function
	Private Function SendMsg_NOTICE(ByVal Source As WinSECore.IRCNode, ByVal Dest As WinSECore.User, ByVal Message As String) As Boolean
		c.protocol.SendMessage(Source, Dest, Message, True)
	End Function
	Private Function SendMsg_304(ByVal Source As WinSECore.IRCNode, ByVal Dest As WinSECore.User, ByVal Message As String) As Boolean
		c.protocol.SendNumeric(Source, Dest, 304, ":{0}: {1}", Source.Name, Message)
	End Function
	Private Function SendMsg_SNOTICE(ByVal Source As WinSECore.IRCNode, ByVal Dest As WinSECore.User, ByVal Message As String) As Boolean
		c.protocol.SendMessage(c.Services, Dest, String.Format(":*** {0}: {1}", Source.Name, Message), True)
	End Function
	Private Function CmdHelp(ByVal Source As WinSECore.User, ByVal Cmd As String, ByVal Args() As String) As Boolean
		c.API.SendHelp(Source, "NickServ", Args)
	End Function
End Class
