'Copyright (c) 2005 The WinSE Team 
'All rights reserved. 
' 
'Redistribution and use in source and binary forms, with or without 
'modification, are permitted provided that the following conditions 
'are met: 
'1. Redistributions of source code must retain the above copyright 
'   notice, this list of conditions and the following disclaimer. 
'2. Redistributions in binary form must reproduce the above copyright 
'   notice, this list of conditions and the following disclaimer in the 
'   documentation and/or other materials provided with the distribution. 
'3. The name of the author may not be used to endorse or promote products 
'   derived from this software without specific prior written permission.

'THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR 
'IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
'OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
'IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, 
'INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
'NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
'DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
'THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
'(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF 
'THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
Option Explicit On 
Option Strict On
Option Compare Binary
Imports Microsoft.VisualBasic
Imports System
Imports System.Collections
Imports System.Collections.Specialized
Public NotInheritable Class API
	Private ReadOnly c As Core
	Public Const FORMAT_BOLD As Char = Chr(2)
	Public Const FORMAT_COLOR As Char = Chr(3)
	Public Const FORMAT_UNDERLINE As Char = Chr(31)
	Public Const FORMAT_RESET As Char = Chr(15)
	Friend Sub New(ByVal c As Core)
		Me.c = c
	End Sub
	'Invokes a service command routine from the given hashtable.
	'Exceptions thrown:
	'- None : No error occured - all commands executed normally.
	'- ArgumentNullException : The parameter named in the exception was passed a Null Reference.
	'- MissingMethodException : The command named in the exception description was not found in the hashtable.
	'- TargetInvocationException : A command method threw an exception, which is contained in the innerException.
	Public Sub ExecCommand(ByVal hash As CommandHash, ByVal sender As User, ByVal Command As String)
		Dim cmd As String, cl As CommandList
		Dim args() As String
		If InStr(Command, " ") > 0 Then
			cmd = Split(Command, " ", 2)(0)
			args = Split(Split(Command, " ", 2)(1), " ")
		Else
			cmd = Command
			args = New String(-1) {}
		End If
		If hash Is Nothing Then Throw New ArgumentNullException("hash")
		If sender Is Nothing Then Throw New ArgumentNullException("sender")
		If Not hash.Contains(cmd) Then
			Throw New MissingMethodException(cmd)
		Else
			cl = hash(cmd)
			For idx As Integer = 0 To cl.Count - 1
				Try
					If Not cl(idx)(sender, cmd, args) Then Exit For
				Catch ex As Exception
					Throw New System.Reflection.TargetInvocationException(ex)
				End Try
			Next
		End If
	End Sub
	Public Function GetServ() As String
		Static buffer As String
		Dim stmp As String, b() As Byte
		If c.sck.Poll(0, Net.Sockets.SelectMode.SelectRead) Then
			If c.sck.Available > 0 Then
				b = New Byte(c.sck.Available) {}
				c.sck.Receive(b)
				buffer += System.Text.Encoding.ASCII.GetString(b)
				'Easier to handle things with just LF as opposed to CRLF.
				buffer = Replace(buffer, vbCrLf, vbLf)
				buffer = Replace(buffer, vbCr, vbLf)
				buffer = Replace(buffer, Chr(0), "")
			ElseIf c.sck.Available = 0 AndAlso InStr(buffer, vbLf) <= 0 Then
				Throw New System.Net.Sockets.SocketException(10101)
			End If
		End If
		If InStr(buffer, vbLf) > 0 Then
			stmp = Split(buffer, vbLf, 2)(0)
			buffer = Split(buffer, vbLf, 2)(1)
			Return stmp
		Else
			Return Nothing
		End If
	End Function
	Public Function GetServ(ByVal timeout As TimeSpan) As String
		'If it's 0 from the outset, assume it means infinite.
		Dim str As String
		If timeout.Equals(TimeSpan.Zero) Then
			Do While str Is Nothing
				str = GetServ()
				System.Threading.Thread.CurrentThread.Sleep(100)
			Loop
			Return str
		Else
			Dim dteEnd As Date = Now.Add(timeout)
			Do While str Is Nothing AndAlso Now < dteEnd
				str = GetServ()
				System.Threading.Thread.CurrentThread.Sleep(100)
			Loop
			Return str
		End If
	End Function
	Public Overloads Sub PutServ(ByVal buffer As String)
		Dim b() As Byte = System.Text.Encoding.ASCII.GetBytes(buffer & vbCrLf)
		c.sck.Send(b)
	End Sub
	Public Overloads Sub PutServ(ByVal format As String, ByVal ParamArray args() As Object)
		PutServ(String.Format(format, args))
	End Sub
	Public Sub ExitServer(ByVal Reason As String, Optional ByVal Name As String = Nothing)
		c.protocol.SendError(String.Format("ERROR :Closing link {0}[{1}] ({2})", IIf(Name Is Nothing, c.Conf.UplinkName, Name), DirectCast(c.sck.RemoteEndPoint, System.Net.IPEndPoint).Address, Reason))
		c.sck.Shutdown(Net.Sockets.SocketShutdown.Send)
	End Sub
	Public Shared Function FMod(ByVal dividend As Double, ByVal divisor As Double) As Double
		'Floating modulus. When the Mod operator doesn't help.
		'Essentially, a % b == ((a / b) - iPart(a / b)) * b
		FMod = ((dividend / divisor) - Fix(dividend / divisor)) * divisor
	End Function
	Public Shared Function Mask(ByVal NUH As String, ByVal MaskType As Integer) As String
		Dim n As String, u As String, h As String, d As String
		If InStr(NUH, "!") = 0 Or InStr(NUH, "@") = 0 Or InStr(NUH, "!") >= InStr(NUH, "@") Then Error 5
		n = Left(NUH, InStr(NUH, "!") - 1)
		NUH = Mid(NUH, InStr(NUH, "!") + 1)
		u = Left(NUH, InStr(NUH, "@") - 1)
		h = Mid(NUH, InStr(NUH, "@") + 1)
		If Left(u, 1) = "~" Then u = Mid(u, 2)
		'Get the domain based on these rules:
		'If the hostname is an Numeric IP Address, use the first 3 octets.
		'If the hostname has 2 or less parts, use the entire hostname.
		'If the hostname has 5 or more parts, use only the top 4.
		'Otherwise, use all but the bottom domain.
		Dim hs() As String
		hs = Split(h, ".")
		If UBound(hs) <= 2 Then
			'Examples:
			'localhost (not masked)
			'mydomain.com (not masked)
			d = h
		ElseIf UBound(hs) = 3 Then
			'Examples:
			'mymachine.mydomain.com (masked as *.mydomain.com)
			d = "*." + Split(h, ".", 2)(1)
		ElseIf UBound(hs) = 4 And IsNumeric(hs(0)) And IsNumeric(hs(1)) And IsNumeric(hs(2)) And IsNumeric(hs(3)) Then
			'IPv4 ADDRESS!!!
			'Examples:
			'127.0.0.1 (masked as 127.0.0.* - maybe soon it will be masked as 127.0.0.0/24)
			d = hs(0) + "." + hs(1) + "." + hs(2) + ".*"
		ElseIf UBound(hs) = 4 Then
			'Examples:
			'localhost.127.in-addr.arpa (masked as *.in-addr.arpa)
			d = "*." + Split(h, ".", 2)(1)
		ElseIf UBound(hs) >= 5 Then
			'my.isp.gives.me.really.long.hosts.like.this (masked as *.long.hosts.like.this)
			d = "*." + hs(UBound(hs) - 3) + "." + hs(UBound(hs) - 2) + "." + hs(UBound(hs) - 1) + "." + hs(UBound(hs))
		End If
		Select Case MaskType Mod 10
			Case 0			 '*!user@host.domain
				Return "*!" + u + "@" + h
			Case 1			 '*!*user@host.domain
				Return "*!*" + u + "@" + h
			Case 2			 '*!*@host.domain
				Return "*!*@" + h
			Case 3			 '*!*user@*.domain
				Return "*!*" + u + "@" + d
			Case 4			 '*!*@*.domain
				Return "*!*@" + d
			Case 5			 'nick!user@host.domain
				Return n + "!" + u + "@" + h
			Case 6			 'nick!*user@host.domain
				Return n + "!*" + u + "@" + h
			Case 7			 'nick!*@host.domain
				Return n + "!*@" + h
			Case 8			 'nick!*user@*.domain
				Return n + "!*" + u + "@" + d
			Case 9			 'nick!*@*.domain
				Return n + "!*@" + d
		End Select
	End Function
	Public Shared Function ExtractNickFromNUH(ByVal Prefix As String) As String
		If InStr(Prefix, "!") = 0 Then
			If InStr(Prefix, "@") = 0 Then
				Return Prefix
			Else
				Return Left(Prefix, InStr(Prefix, "@") - 1)
			End If
		Else
			Return Left(Prefix, InStr(Prefix, "!") - 1)
		End If
	End Function
	Public Shared Function IsMatch(ByVal Text As String, ByVal Mask As String, Optional ByVal SplatNoEmpty As Boolean = False) As Boolean
		'A lesser version of the Like operator needed for IRC.
		Dim sMask As String
		sMask = Replace(Mask, "[", "[]]")
		sMask = Replace(sMask, "#", "[#]")
		If SplatNoEmpty Then sMask = Replace(sMask, "*", "?*")
		Return Text Like sMask
	End Function
	Public Shared Function Duration(ByVal dur As String) As Integer
		'Takes a string like this: 1d2h3m4s and returns the number of seconds.
		'The exact format could be described with a regular expression:
		'([0-9]+([dD]|[hH]|[mM]|[sS]))+
		Dim secs As Integer, stmp As String
		Dim idx As Integer, ch As Char
		For idx = 1 To Len(dur)
			ch = dur.Chars(idx - 1)
			Select Case ch
				Case "0"c To "9"c
					stmp = stmp & ch
				Case "d"c, "D"c
					If stmp = "" Then Throw New ArgumentException("Not a valid duration string (period specifier without quantity).", "dur")
					secs = secs + CInt(stmp) * 86400
					stmp = ""
				Case "h"c, "H"c
					If stmp = "" Then Throw New ArgumentException("Not a valid duration string (period specifier without quantity).", "dur")
					secs = secs + CInt(stmp) * 3600
					stmp = ""
				Case "m"c, "M"c
					If stmp = "" Then Throw New ArgumentException("Not a valid duration string (period specifier without quantity).", "dur")
					secs = secs + CInt(stmp) * 60
					stmp = ""
				Case "s"c, "S"c
					If stmp = "" Then Throw New ArgumentException("Not a valid duration string (period specifier without quantity).", "dur")
					secs = secs + CInt(stmp)
					stmp = ""
				Case Else
					Throw New ArgumentException("Not a valid duration string (invalid character '" + ch + "').", "dur")
			End Select
		Next idx
		If stmp <> "" Then secs = secs + CInt(stmp)
		Return secs
	End Function
	Public Shared Function UnDuration(ByVal dur As Integer) As String
		'Take Duration's output and converts into a string.
		Dim days As Integer, hours As Integer, mins As Integer, secs As Integer
		If dur < 0 Then Throw New ArgumentException("Invalid time specifier (negative).", "dur")
		days = (dur \ 86400)
		hours = (dur \ 3600) Mod 24
		mins = (dur \ 60) Mod 60
		secs = dur Mod 60
		UnDuration = IIf(days > 0, CStr(days) & "d", "").ToString & IIf(hours > 0, CStr(hours) & "h", "").ToString & IIf(mins > 0, CStr(mins) & "m", "").ToString & IIf(secs > 0, CStr(secs) & "s", "").ToString
	End Function
	Public Function FindNode(ByVal name As String) As IRCNode
		Dim n As IRCNode
		n = FindNode(name, c.Services)
		If n Is Nothing AndAlso Not c.IRCMap Is Nothing Then n = FindNode(name, c.IRCMap)
		Return n
	End Function
	Public Shared Function FindNode(ByVal needle As String, ByVal haystack As Server) As IRCNode
		If LCase(haystack.Name) = LCase(needle) Then Return haystack
		With haystack
			For Each n As IRCNode In haystack.SubNodes
				If TypeOf n Is Server Then
					Return FindNode(needle, DirectCast(n, Server))
				Else
					If LCase(needle) = LCase(n.Name) Then Return n
				End If
			Next
		End With
		Return Nothing
	End Function
	Public Overloads Shared Function GetTS() As Integer
		Return GetTS(Now)
	End Function
	Public Overloads Shared Function GetTS(ByVal d As Date) As Integer
		Return CInt(DateDiff(DateInterval.Second, New Date(1970, 1, 1, 0, 0, 0), d.ToUniversalTime))
	End Function
	Public Overloads Function IsService(ByVal cptr As IRCNode) As Boolean
		Return c.Services.HasClient(cptr, True)
	End Function
	Private Function GlobDirectory(ByVal root As System.IO.DirectoryInfo, ByVal path As String) As StringCollection
		Dim sc As New StringCollection
		Dim current As String, rest As String
		path = Replace(path, "/", "\")
		While Left(path, 1) = "\"
			path = Mid(path, 2)
		End While
		If InStr(path, "\") > 0 Then
			current = Split(path, "\", 2)(0)
			rest = Split(path, "\", 2)(1)
		Else
			current = path
			rest = Nothing
		End If
		For Each di As System.IO.DirectoryInfo In root.GetDirectories()
			If di.Name Like current Then
				If rest Is Nothing Then
					sc.Add(di.FullName)
				Else
					Dim a() As String, sc2 As StringCollection
					sc2 = GlobDirectory(di, rest)
					a = New String(sc2.Count) {}
					sc2.CopyTo(a, 0)
					sc.AddRange(a)
				End If
			End If
		Next
		Return sc
	End Function
	Public Sub SendHelp(ByVal Source As IRCNode, ByVal SendTo As User, ByVal Base As String, ByVal Args() As String)
		'How this works:
		'The main file is {Base}\index (NO EXTENSION)
		'Help topics with subtopics are as folders, with an optional file named 'index' (NO EXTENSION) which is displayed by default
		'Topics with no subtopics are named <topic>.txt .
		Dim dirs As New StringCollection, a() As String, sc As StringCollection
		For Each s As String In c.Conf.HelpDirs
			sc = GlobDirectory(New System.IO.DirectoryInfo(c.Conf.WinSERoot), s)
			a = New String(sc.Count) {}
			sc.CopyTo(a, 0)
			dirs.AddRange(a)
		Next
		Dim fd As System.IO.StreamReader, sFile As String
		Dim scLines As New StringCollection, sTmp As String
		For Each s As String In dirs
			sFile = s & "\" & Base & DirectCast(IIf(Args.Length > 0, "\" & Join(Args, "\"), ""), String)
			Try
				If System.IO.Directory.Exists(sFile) Then
					If Not System.IO.File.Exists(sFile & "\index") Then
						scLines.Add("The following topics were found for your query:")
						For Each f As System.IO.FileInfo In New System.IO.DirectoryInfo(sFile).GetFiles()
							scLines.Add(Join(Args, " ") & " " & f.Name)
						Next
						scLines.Add("Type " & FORMAT_BOLD & "/msg " & Source.Name & " HELP " & FORMAT_UNDERLINE & "topic" & FORMAT_UNDERLINE & FORMAT_BOLD & " for more information.")
					Else
						fd = New System.IO.StreamReader(sFile & "\index")
						sTmp = fd.ReadToEnd
						fd.Close()
						sTmp = Replace(sTmp, vbCrLf, vbLf)
						sTmp = Replace(sTmp, vbCr, vbLf)
						scLines.AddRange(Split(sTmp, vbLf))
					End If
				ElseIf System.IO.File.Exists(sFile & ".txt") Then
					fd = New System.IO.StreamReader(sFile & ".txt")
					sTmp = fd.ReadToEnd
					fd.Close()
					sTmp = Replace(sTmp, vbCrLf, vbLf)
					sTmp = Replace(sTmp, vbCr, vbLf)
					scLines.AddRange(Split(sTmp, vbLf))
				Else
				End If
			Catch ex As Exception
			End Try
		Next
		If scLines.Count = 0 Then
			scLines.Add("Sorry, no help available for " & DirectCast(IIf(Args.Length <= 0, "this service.", FORMAT_BOLD & Join(Args, " ") & FORMAT_BOLD & ". Type " & FORMAT_BOLD & "/msg " & Source.Name & " HELP" & FORMAT_BOLD & " for help."), String))
		End If
		For Each sLine As String In scLines
			SendTo.SendMessage(Source, SendTo, sLine)
		Next
	End Sub
	'I converted these from unreal's src/support.c.
	Private Const Base64 As String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	Const Pad64 As Char = "="c
	Public Overloads Shared Function B64Encode(ByVal src As String) As String
		Return B64Encode(System.Text.Encoding.ASCII.GetBytes(src))
	End Function
	Public Overloads Shared Function B64Encode(ByVal src() As Byte) As String
		Dim target As String
		Dim input(2) As Byte
		Dim output(3) As Byte
		Dim srclength As Integer = src.Length
		Dim i As Integer
		Dim srcidx As Integer = 0
		While 2 < srclength
			input(0) = src(srcidx)
			input(1) = src(srcidx + 1)
			input(2) = src(srcidx + 2)
			srclength -= 3
			srcidx += 3
			output(0) = CByte(input(0) >> 2)
			output(1) = CByte(((input(0) And &H3) << 4) + (input(1) >> 4))
			output(2) = CByte(((input(1) And &HF) << 2) + (input(2) >> 6))
			output(3) = CByte(input(2) And &H3F)
			target += Base64.Chars(output(0))
			target += Base64.Chars(output(1))
			target += Base64.Chars(output(2))
			target += Base64.Chars(output(3))
		End While
		If srclength <> 0 Then
			'Get what's left.
			input(0) = 0
			input(1) = 0
			input(2) = 0
			For i = 0 To srclength - 1
				input(i) = src(srcidx)
				srcidx += 1
			Next
			output(0) = CByte(input(0) >> 2)
			output(1) = CByte(((input(0) And &H3) << 4) + (input(1) >> 4))
			output(2) = CByte(((input(1) And &HF) << 2) + (input(2) >> 6))
			target += Base64.Chars(output(0))
			target += Base64.Chars(output(1))
			If srclength = 1 Then
				target += Pad64
			Else
				target += Base64.Chars(output(2))
			End If
			target += Pad64
		End If
		Return target
	End Function
	Public Overloads Shared Function B64Decode(ByVal src As String) As Byte()
		Dim tarindex As Integer = 0, state As Integer = 0, ch As Char
		Dim pos As Integer = 0
		Dim target(0) As Byte
		Dim srcidx As Integer = 0
		ch = src.Chars(srcidx)
		srcidx += 1
		While ch <> Chr(0) AndAlso srcidx < Len(src)
			If Char.IsWhiteSpace(ch) Then
				GoTo Continue
			End If
			If ch = Pad64 Then Exit While
			pos = InStr(Base64, ch)
			If pos <= 0 Then
				Throw New ArgumentException("Invalid base64 character '" + ch + "' at position " + srcidx.ToString())
			End If
			Select Case state
				Case 0
					If tarindex >= target.Length Then
						ReDim Preserve target(tarindex)
					End If
					target(tarindex) = CByte((pos - 1) << 2)
					state = 1
					Exit Select
				Case 1
					If tarindex + 1 >= target.Length Then
						ReDim Preserve target(tarindex + 1)
					End If
					target(tarindex) = target(tarindex) Or CByte((pos - 1) >> 4)
					target(tarindex + 1) = CByte((pos - 1) And &HF) << 4
					tarindex += 1
					state = 2
					Exit Select
				Case 2
					If tarindex + 1 >= target.Length Then
						ReDim Preserve target(tarindex + 1)
					End If
					target(tarindex) = target(tarindex) Or CByte((pos - 1) >> 2)
					target(tarindex + 1) = CByte((pos - 1) And &H3) >> 6
					tarindex += 1
					state = 3
					Exit Select
				Case 3
					If tarindex >= target.Length Then
						ReDim Preserve target(tarindex)
					End If
					target(tarindex) = target(tarindex) Or CByte(pos - 1)
					tarindex += 1
					state = 0
					Exit Select
			End Select
Continue:
			ch = src.Chars(srcidx)
			srcidx += 1
		End While
		If ch = Pad64 Then
			ch = src.Chars(srcidx)
			srcidx += 1
			Select Case state
				Case 0, 1
					Throw New ArgumentException("Invalid padding character at first or second position on byte boundary.")
				Case 2
					While ch <> Chr(0) AndAlso srcidx < src.Length
						If Not Char.IsWhiteSpace(ch) Then Exit While
						ch = src.Chars(srcidx)
						srcidx += 1
					End While
					If ch <> Pad64 Then Throw New ArgumentException("Expected two padding characters but only found one...")
					If srcidx < src.Length Then
						ch = src.Chars(srcidx)
						srcidx += 1
					Else
						ch = Chr(0)
					End If
					GoTo DropThrough					  'VB doesn't let us "implicitly" drop through :( 
				Case 3
DropThrough:
					While ch <> Chr(0) AndAlso srcidx < src.Length
						If Not Char.IsWhiteSpace(ch) Then Throw New ArgumentException("Invalid character '" + ch + "' after end of Base64 string.")
						ch = src.Chars(srcidx)
						srcidx += 1
					End While
					If (target(tarindex) <> 0) Then
						Throw New ArgumentException("Extra nonzero bits...?")
					End If
					ReDim Preserve target(tarindex - 1)
			End Select
		Else
			'Hit a 0.
			If state <> 0 Then
				Throw New ArgumentException("Base64 string was terminated mid-piece.")
			End If
		End If
		Return target
	End Function
	Public Function GetMOTD() As String()
		Dim fd As System.IO.Stream
		Dim s As String, b() As Byte		  'Stream reads a byte array :-/ .
		If c.Conf.MOTDFile Is Nothing Then
			Try
				fd = System.IO.File.Open(c.Conf.MOTDFile, IO.FileMode.Open, IO.FileAccess.Read, IO.FileShare.None)
				If fd.Length <= Integer.MaxValue Then
					b = New Byte(CInt(fd.Length)) {}
					fd.Read(b, 0, CInt(fd.Length))
				Else
					c.Events.FireLogMessage("WinSE.MOTD", "WARNING", String.Format("MOTD too long ({0} bytes), truncating to {1} bytes.", fd.Length, Integer.MaxValue))
					b = New Byte(Integer.MaxValue) {}
					fd.Read(b, 0, Integer.MaxValue)
				End If
				s = System.Text.Encoding.ASCII.GetString(b)
				fd.Close()
				fd = Nothing
				s = Replace(s, vbCrLf, vbLf)
				s = Replace(s, vbCr, vbLf)
				'Now do %VARIABLE% substitution.
				s = Replace(s, "%COREVERSION%", c.GetType().Assembly.GetName().Version.ToString())
				'Possibly do Environment variable crap?
				c.Conf.MOTD = Split(s, vbLf)
			Catch ex As System.Exception
				c.Events.FireLogMessage("WinSE.MOTD", "WARNING", String.Format("Read error on {0}: {1}", c.Conf.MOTDFile, ex.Message))
			End Try
		End If
		Return DirectCast(c.Conf.MOTD.Clone(), String())
	End Function
	Public Function SendMsg_PRIVMSG(ByVal Source As WinSECore.IRCNode, ByVal Dest As WinSECore.User, ByVal Message As String) As Boolean
		c.protocol.SendMessage(Source, Dest, Message, False)
	End Function
	Public Function SendMsg_NOTICE(ByVal Source As WinSECore.IRCNode, ByVal Dest As WinSECore.User, ByVal Message As String) As Boolean
		c.protocol.SendMessage(Source, Dest, Message, True)
	End Function
	Public Function SendMsg_304(ByVal Source As WinSECore.IRCNode, ByVal Dest As WinSECore.User, ByVal Message As String) As Boolean
		c.protocol.SendNumeric(Source, Dest, 304, ":{0}: {1}", Source.Name, Message)
	End Function
	Public Function SendMsg_SNOTICE(ByVal Source As WinSECore.IRCNode, ByVal Dest As WinSECore.User, ByVal Message As String) As Boolean
		c.protocol.SendMessage(c.Services, Dest, String.Format(":*** {0}: {1}", Source.Name, Message), True)
	End Function
End Class

Public NotInheritable Class Events
	'This should only be created within the WinSE module...
	Friend Sub New()
	End Sub
	'Fired when a message is Logged.
	'Facility is in the format: module.<operation> where operation is up to the module to decide.
	'Severity is any of the following:
	'FATAL - Used for Fatal Errors that require WinSE to shut down.
	'ERROR - Used for general errors.
	'WARNING - Used for things that could be bad.
	'NOTICE - Used for things like command usage, general alerts, etc.
	'DEBUG - Used for debugging messages. Use this type for showing variable contents, etc.
	'TRACE - Used for debugging messages. Use this type for tracing code paths.
	Public Event LogMessage(ByVal Facility As String, ByVal Severity As String, ByVal Message As String)
	Public Sub FireLogMessage(ByVal Facility As String, ByVal Severity As String, ByVal Message As String)
#If DEBUG Then
#Else
		If Severity = "DEBUG" Then Return
#End If
#If TRACE Then
#Else
		If Severity = "TRACE" Then Return
#End If
		RaiseEvent LogMessage(Facility, Severity, Message)
	End Sub
	'Fired when WinSE successfully estabilishes a connection.
	Public Event ServerInit()
	Public Sub FireServerInit()
		RaiseEvent ServerInit()
	End Sub
	Public Event ServerSynched()
	'Fired when the protocol module indicates that it has processed the end of the netsynch burst.
	Public Sub FireServerSynched()
		RaiseEvent ServerSynched()
	End Sub
	'Fired before exiting the server (after a valid connection is already present, eg after ServerInit has been raised).
	Public Event ServerTerm()
	Public Sub FireServerTerm()
		RaiseEvent ServerTerm()
	End Sub
	'Fired when a raw message from the server is received.
	Public Event RawMsg(ByVal sptr As IRCNode, ByVal cmd As String, ByVal params() As String)
	Public Sub FireRawMsg(ByVal sptr As IRCNode, ByVal cmd As String, ByVal params() As String)
		RaiseEvent RawMsg(sptr, cmd, params)
	End Sub
	'Fired when user sptr is introduced to the network (behind cptr).
	Public Event ClientConnect(ByVal cptr As Server, ByVal sptr As User)
	Public Sub FireClientConnect(ByVal cptr As Server, ByVal sptr As User)
		RaiseEvent ClientConnect(cptr, sptr)
	End Sub
	'Fired when user sptr disconnects.
	Public Event ClientQuit(ByVal sptr As User, ByVal reason As String)
	Public Sub FireClientQuit(ByVal sptr As User, ByVal reason As String)
		RaiseEvent ClientQuit(sptr, reason)
	End Sub
	'Fired when a user sets or unsets AWAY. If Reason Is Nothing Then User Is Back Else User Is Away
	Public Event ClientAway(ByVal sptr As User, ByVal Reason As String)
	Public Sub FireClientAway(ByVal sptr As User, ByVal reason As String)
		RaiseEvent ClientAway(sptr, reason)
	End Sub
	'Fired when user cptr is killed by sptr (ClientQuit fired afterwards...)
	Public Event ClientKilled(ByVal sptr As IRCNode, ByVal cptr As User, ByVal Reason As String)
	Public Sub FireClientKilled(ByVal sptr As IRCNode, ByVal cptr As User, ByVal Reason As String)
		RaiseEvent ClientKilled(sptr, cptr, Reason)
	End Sub
	'Fired when server sptr connects to the network.
	Public Event ServerConnect(ByVal sptr As Server, ByVal sptrIsBehindThisGuy As Server)
	Public Sub FireServerConnect(ByVal sptr As Server, ByVal sptrIsBehindThisGuy As Server)
		RaiseEvent ServerConnect(sptr, sptrIsBehindThisGuy)
	End Sub
	'Fired when a server quits. ClientQuit and ServerQuit will be called for each client and server under this server.
	Public Event ServerQuit(ByVal sptr As Server, ByVal reason As String)
	Public Sub FireServerQuit(ByVal sptr As Server, ByVal reason As String)
		RaiseEvent ServerQuit(sptr, reason)
	End Sub
	'Fired when a client changes his nickname.
	Public Event ClientNickChange(ByVal sptr As User, ByVal oldnick As String, ByVal nick As String)
	Public Sub FireClientNickChange(ByVal sptr As User, ByVal oldnick As String, ByVal nick As String)
		RaiseEvent ClientNickChange(sptr, oldnick, nick)
	End Sub
	'Fired when a client joins a channel.
	Public Event ClientJoin(ByVal sptr As User, ByVal chptr As Channel)
	Public Sub FireClientJoin(ByVal sptr As User, ByVal chptr As Channel)
		RaiseEvent ClientJoin(sptr, chptr)
	End Sub
	'Fired when a client leaves a channel.
	Public Event ClientPart(ByVal sptr As User, ByVal chptr As Channel, ByVal reason As String)
	Public Sub FireClientPart(ByVal sptr As User, ByVal chptr As Channel, ByVal reason As String)
		RaiseEvent ClientPart(sptr, chptr, reason)
	End Sub
	'Fired when a client is kicked from the channel. 
	Public Event ClientKicked(ByVal sptr As IRCNode, ByVal chptr As Channel, ByVal acptr As User, ByVal reason As String)
	Public Sub FireClientKicked(ByVal sptr As IRCNode, ByVal chptr As Channel, ByVal acptr As User, ByVal reason As String)
		RaiseEvent ClientKicked(sptr, chptr, acptr, reason)
	End Sub
	'Fired when a client sends a message to the channel.
	Public Event ClientChannelMessage(ByVal sptr As User, ByVal chptr As Channel, ByVal msg As String)
	Public Sub FireClientChannelMessage(ByVal sptr As User, ByVal chptr As Channel, ByVal msg As String)
		RaiseEvent ClientChannelMessage(sptr, chptr, msg)
	End Sub
	'Fired when a client sends a message to users with the given status in the channel.
	Public Event ClientChannelPrefixMessage(ByVal sptr As User, ByVal chptr As Channel, ByVal prefix As Char, ByVal msg As String)
	Public Sub FireClientChannelPrefixMessage(ByVal sptr As User, ByVal chptr As Channel, ByVal prefix As Char, ByVal msg As String)
		RaiseEvent ClientChannelPrefixMessage(sptr, chptr, prefix, msg)
	End Sub
	'Fired when a user changes his usermodes (or they are forcefully changed by SVSMODE, etc).
	Public Event UserModeChange(ByVal Source As IRCNode, ByVal Who As User, ByVal Flag As Char, ByVal Setting As Boolean)
	Public Sub FireUserModeChange(ByVal Source As IRCNode, ByVal Who As User, ByVal Flag As Char, ByVal Setting As Boolean)
		RaiseEvent UserModeChange(Source, Who, Flag, Setting)
	End Sub
	'Fired when a user's channel status is changed.
	Public Event ChannelStatusChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal Status As Char, ByVal Who As ChannelMember, ByVal Add As Boolean)
	Public Sub FireChannelStatusChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal Status As Char, ByVal Who As ChannelMember, ByVal Add As Boolean)
		RaiseEvent ChannelStatusChange(Source, Chan, Status, Who, Add)
	End Sub
	'Fired when a channel list entry (+b, +e, +I, etc) is added or removed.
	Public Event ChannelListChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal List As Char, ByVal Entry As String, ByVal Add As Boolean)
	Public Sub FireChannelListChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal List As Char, ByVal Entry As String, ByVal Add As Boolean)
		RaiseEvent ChannelListChange(Source, Chan, List, Entry, Add)
	End Sub
	'Fired when a channel mode requiring a parameter (+l, +k) is modified.
	Public Event ChannelParamModeChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal Mode As Char, ByVal Param As String)
	Public Sub FireChannelParamModeChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal Mode As Char, ByVal Param As String)
		RaiseEvent ChannelParamModeChange(Source, Chan, Mode, Param)
	End Sub
	'Fired when a channel binary mode (+i, +m) is changed.
	Public Event ChannelFlagModeChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal Mode As Char, ByVal Setting As Boolean)
	Public Sub FireChannelFlagModeChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal Mode As Char, ByVal Setting As Boolean)
		RaiseEvent ChannelFlagModeChange(Source, Chan, Mode, Setting)
	End Sub
	'Fired when a channel's topic changes.
	Public Event ChannelTopicChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal NewTopic As String)
	Public Sub FireChannelTopicChange(ByVal Source As IRCNode, ByVal Chan As Channel, ByVal NewTopic As String)
		RaiseEvent ChannelTopicChange(Source, Chan, NewTopic)
	End Sub
End Class

