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
'This is the Core of WinSE. Everything that ever happens in WinSE is controlled through here...
Public NotInheritable Class Core
	'This is where we store module references. Because modules are less mutable than just about everything else here, I am willing to
	'suffer through using an array.
	Friend ReadOnly mModules As New Hashtable
	Public ReadOnly Property Modules() As WinSECore.Module()
		Get
			Dim m() As WinSECore.Module, idx As Integer = 0
			m = New WinSECore.Module(mModules.Count - 1) {}
			For Each [mod] As WinSECore.Module In mModules.Values
				m(idx) = [mod]
				idx += 1
			Next
			'mModules.CopyTo(m, 0)
			Return m
		End Get
	End Property
	'All the service clients loaded by a module go in here.
	Public ReadOnly Clients As New ServiceClients
	'The API
	Public ReadOnly API As New API(Me)
	'The configuration.
	Public Conf As Configuration
	'Our side of the IRC Map.
	Public Services As Server
	'Uplink side of the IRC Map.
	Public IRCMap As Server
	'The IRCd Protocol Class.
	Public protocol As IRCd
	'The Database driver.
	Public dbdriver As WinSECore.DataDriver
	'The DATABASE.
	Public db As WinSECore.Database
	'CHANNELS!
	Public ReadOnly Channels As New Channels
	'Active user@host bans on the network. (AKILLS/GLINES/etc)
	Public ReadOnly UserhostBans As New Bans
	'Active nickname bans on the network. (SQLINES)
	Public ReadOnly NickBans As New Bans
	'Active realname bans on the network. (SGLIENS)
	Public ReadOnly RealnameBans As New Bans
	'Active IP bans on the network. (SZLINES)
	Public ReadOnly IPBans As New Bans
	'Active squelches (if supported) on the network. (SHUN)
	Public ReadOnly Squelches As New Bans
	'Access flags, defined by modules.
	Public ReadOnly FlagDefs As New StringDictionary
	'The Core has only two builtin flags: Master and CoMaster.
	Public Const FLAG_Master As Char = "M"c
	Public Const FLAG_CoMaster As Char = "m"c
	'SOCKET!
	Public sck As System.Net.Sockets.Socket
	'The instance of our Event sink.
	Public ReadOnly Events As New Events
	'Where our configuration file should be.
	Public ReadOnly ConfFile As String
	'Halt code. This is used by services to tell the core to halt or restart. Used by OperServ SHUTDOWN, etc.
	Public Enum HaltCode
		HALT_CONTINUE = 0	   'No halt code.
		HALT_SHUTDOWN = 1	   'Exit
		HALT_RESTART = 2	   'Restart
	End Enum
	Public Halt As HaltCode
	Public Sub New()
		ConfFile = Environment.CurrentDirectory & "\winse.conf"
	End Sub
	'This initializes the core. Initialization involves loading the configuration and modules and stuff.
	Public Function Init(ByVal Args() As String) As Integer
		Events.FireLogMessage("Core.Initialization", "TRACE", "Entering Init()")
		If Not Rehash() Then
			Events.FireLogMessage("Core.Initialization", "FATAL", "Configuration failed to pass testing.")
			Return 1
		End If
		If protocol Is Nothing Then
			Events.FireLogMessage("Core.Initialization", "FATAL", "No protocol selected - bailing!")
			Return 1
		End If
		If dbdriver Is Nothing Then
			Events.FireLogMessage("Core.Initialization", "FATAL", "No database module loaded - bailing!")
			Return 1
		End If
		Events.FireLogMessage("Core.Initialization", "NOTICE", "Loading database")
		Try
			db = dbdriver.LoadDatabase()
		Catch ex As Exception
			Events.FireLogMessage("Core.Initialization", "FATAL", "Data loading failed! " & ex.Message)
			Return 1
		End Try
		For Each m As WinSECore.Module In Modules()
			If Not m.LoadDatabase() Then
				Events.FireLogMessage("Core.Initialization", "WARNING", "Database for module " & m.Name & " failed to load.")
			End If
		Next
		If Conf.ServerNumeric <> -1 AndAlso Not protocol.IsValidNumeric(Conf.ServerNumeric, True) Then
			Events.FireLogMessage("Core.Initialization", "FATAL", String.Format("[Connect],ServerNumeric not valid for protocol."))
		End If
		Events.FireLogMessage("Core.Initialization", "NOTICE", "WinSE Initialized and ready to start.")
		Events.FireLogMessage("Core.Initialization", "TRACE", "Leaving Init()")
	End Function
	'Rehash. This loads the configuration into memory.
	Public Function Rehash() As Boolean
		Dim k As Key, p As New INIParser
		Dim cnf As Configuration
		Events.FireLogMessage("Core", "TRACE", "Entering Rehash()")
		Try
			k = p.Load(ConfFile)
			If k.SubKeys.Contains("Connect") Then
				With k.SubKeys("Connect", 0)
					If .Values.Contains("ConnectTarget") Then
						With .Values("ConnectTarget", 0)
							Dim ip As System.Net.IPAddress, host As String, port As Integer
							host = Split(.value.ToString(), ":", 2)(0)
							Try
								port = Integer.Parse(Split(.value.ToString(), ":", 2)(1))
							Catch ex As IndexOutOfRangeException
								Throw New ConfigException("Invalid ConnectTarget (expected host:port).", ex, .file, .line)
							Catch ex As Exception
								Throw New ConfigException("Invalid ConnectTarget (expected numeric port).", ex, .file, .line)
							End Try
							Try
								ip = System.Net.IPAddress.Parse(host)
							Catch ex As FormatException
								Try
									ip = System.Net.Dns.Resolve(host).AddressList(0)
								Catch ex2 As Exception
									Throw New ConfigException("Unable to resolve [Connect],ConnectTarget: " + ex2.Message, ex2, .file, .line)
								End Try
							End Try
							cnf.UplinkAddress = New System.Net.IPEndPoint(ip, port)
						End With
					Else
						Throw New ConfigException("[Connect],ConnectTarget missing.", .file, 0)
					End If
					If .Values.Contains("UplinkName") Then
						With .Values("UplinkName", 0)
							cnf.UplinkName = CStr(.value)
						End With
					Else
						Throw New ConfigException("[Connect],UplinkName missing.", .file, 0)
					End If
					If .Values.Contains("ServerName") Then
						With .Values("ServerName", 0)
							cnf.ServerName = CStr(.value)
						End With
					Else
						Throw New ConfigException("[Connect],ServerName missing.", .file, 0)
					End If
					If .Values.Contains("ServerDesc") Then
						With .Values("ServerDesc", 0)
							cnf.ServerDesc = CStr(.value)
						End With
					Else
						Throw New ConfigException("[Connect],ServerDesc missing.", .file, 0)
					End If
					If .Values.Contains("ServerNumeric") Then
						With .Values("ServerNumeric", 0)
							Try
								cnf.ServerNumeric = Integer.Parse(CStr(.value))
							Catch ex As FormatException
								Throw New ConfigException("[Connect],ServerNumeric invalid: must be a number", ex, .file, .line)
							Catch ex As OverflowException
								Throw New ConfigException("[Connect],ServerNumeric invalid: Out of supported range", ex, .file, .line)
							End Try
						End With
					Else
						cnf.ServerNumeric = -1
					End If
					If .Values.Contains("SendPass") Then
						With .Values("SendPass", 0)
							cnf.SendPass = CStr(.value)
						End With
					Else
						Throw New ConfigException("[Connect],SendPass missing.", .file, 0)
					End If
					If .Values.Contains("RecvPass") Then
						With .Values("RecvPass", 0)
							If CStr(.value) = "" Then
								cnf.RecvPass = New Password(cnf.SendPass)
							Else
								cnf.RecvPass = New Password(CStr(.value))
							End If
						End With
					Else
						cnf.RecvPass = New Password("")
					End If
					If .Values.Contains("NetworkName") Then
						With .Values("NetworkName", 0)
							cnf.NetworkName = CStr(.value)
						End With
					Else
						Throw New ConfigException("[Connect],NetworkName missing.", .file, 0)
					End If
				End With
			Else
				Throw New ConfigException("[Connect] missing.", ConfFile, 0)
			End If
			If k.SubKeys.Contains("Core") Then
				With k.SubKeys("Core", 0)
					If .Values.Contains("MasterNick") Then
						cnf.MasterNick = .Values("MasterNick", 0).value.ToString()
					Else
						Throw New ConfigException("[Core],MasterNick missing.", .file, 0)
					End If
				End With
			Else
				Throw New ConfigException("[Core] missing.", ConfFile, 0)
			End If
			If k.SubKeys.Contains("Files") Then
				With k.SubKeys("Files", 0)
					If .Values.Contains("WinSERoot") Then
						cnf.WinSERoot = CStr(.Values("WinSERoot", 0).value)
					Else
						Throw New ConfigException("[Files],WinSERoot missing.", .file, 0)
					End If
					If Not System.IO.Directory.Exists(cnf.WinSERoot) Then
						Throw New ConfigException("[Files],WinSERoot: " & cnf.WinSERoot & " does not exist or is not a directory.", .file, 0)
					End If
					If .Values.Contains("MOTDFile") Then
						cnf.MOTDFile = Replace(Replace(CStr(.Values("MOTDFile", 0).value), "%WINSEROOT%", cnf.WinSERoot), "/", "\")
					Else
						cnf.MOTDFile = Nothing
					End If
					If .Values.Contains("ExtensionRoot") Then
						cnf.ExtRoot = Replace(Replace(CStr(.Values("ExtensionRoot", 0).value), "%WINSEROOT%", cnf.WinSERoot), "/", "\")
					Else
						Throw New ConfigException("[Files],ExtensionRoot missing.", .file, 0)
					End If
					If .Values.Contains("ExtConfigRoot") Then
						cnf.ExtConfRoot = Replace(Replace(CStr(.Values("ExtConfigRoot", 0).value), "%WINSEROOT%", cnf.WinSERoot), "/", "\")
					Else
						Throw New ConfigException("[Files],ExtConfigRoot missing.", .file, 0)
					End If
					cnf.HelpDirs = New StringCollection
					If .Values.Contains("HelpDir") Then
						For idx As Integer = 0 To .Values.Count("HelpDir") - 1
							cnf.HelpDirs.Add(CStr(.Values("HelpDir", idx).value))
						Next
					End If
				End With
			Else
				Throw New ConfigException("[Files] missing.")
			End If
			If k.SubKeys.Contains("Extensions") Then
				With k.SubKeys("Extensions", 0)
					If .Values.Contains("LoadModule") Then
						cnf.LoadModules = New StringCollection
						For idx As Integer = 0 To .Values.Count("LoadModule") - 1
							Dim a() As String = Split(CStr(.Values("LoadModule", idx).value), ",", 3)
							Dim fi As System.IO.FileInfo
							If a.Length < 2 Then
								Throw New ConfigException("[Extensions],LoadModule[" & idx.ToString() & "]: Invalid format (missing image path)", .file, 0)
							ElseIf a(0).IndexOf("/") < 0 Then
								Throw New ConfigException("[Extensions],LoadModule[" & idx.ToString() & "]: Invalid format (missing / in name specifier)", .file, 0)
							ElseIf Split(a(0), "/").Length > 2 Then
								Throw New ConfigException("[Extensions],LoadModule[" & idx.ToString() & "]: Invalid format (too many / in name specifier)", .file, 0)
							ElseIf a(1) = "*" Then
								a(1) = cnf.ExtRoot & "\" & a(0) & "\" & Split(a(0), "/", 2)(1) & ".dll"
							Else
								a(1) = cnf.ExtRoot & "\" & Replace(a(1), "/", "\")
							End If
							Try
								fi = New System.IO.FileInfo(a(1))
								If Not fi.Exists Then Throw New System.IO.FileNotFoundException("No such file or directory", a(1))
							Catch ex As Exception
								Throw New ConfigException("[Extensions],LoadMudle[" & idx.ToString() & "]: Failed to stat module " + a(1), ex, .file, .line)
							End Try
							cnf.LoadModules.Add(Join(a, ","))
						Next
					End If
				End With
			End If
			'Replace the old configuration with the new.
			Conf = cnf
		Catch ex As ConfigException
			Events.FireLogMessage("Core.Configuration", "ERROR", String.Format("Configuration error: {0}", ex.Message))
			Return False
		Catch ex As System.IO.IOException
			Events.FireLogMessage("Core.Configuration", "ERROR", String.Format("Read error on {0}: {1}", ConfFile, ex.Message))
			Return False
		End Try
		'From here on out, we will not bail.
		'Now for the fun part... MODULES!!!!!!!!!!!!!!!!!!!!!!!
		For Each s As String In Conf.LoadModules
			Dim sName As String, sImage As String, sArgs As String, mMod As [Module]
			sName = Split(s, ",", 3)(0)
			sImage = Split(s, ",", 3)(1)
			If Split(s, ",", 3).Length = 3 Then sArgs = Split(s, ",", 3)(2)
			If mModules.Contains(s) Then
				mMod = DirectCast(mModules(s), WinSECore.Module)
				'It's loaded, is it active?
				With mMod
					If Not .Active Then
						'Activate it.
						.Name = sName
						Try
							If .ModLoad(Split(sArgs, " ")) Then
								.Active = True
							Else
								Events.FireLogMessage("Core.Configuration", "WARNING", String.Format("Failed to initialize module {0}: ModLoad returned False!", sName))
							End If
						Catch ex As Exception
							Events.FireLogMessage("Core.Configuration", "WARNING", String.Format("Failed to initialize module {0}: Exception thrown: {1}", sName, ex.Message))
						End Try
					End If
					'TODO: Do configuration loading.
				End With
			Else
				'It's not loaded. Load time.
				Events.FireLogMessage("Core.Configuration", "TRACE", "First time load of module " & sName & " from " & sImage)
				With System.Reflection.Assembly.LoadFile(sImage)
					Dim bFound As Boolean = False
					For Each t As Type In .GetTypes()
						If t.IsSubclassOf(GetType(WinSECore.Module)) AndAlso Not t.IsAbstract Then
							'Found one! Let's try to run it.
							mMod = Nothing
							With t
								Try
									mMod = DirectCast(.GetConstructor(New Type() {GetType(Core)}).Invoke(New Object() {Me}), WinSECore.Module)
									mModules.Add(sName, mMod)
									bFound = True
								Catch ex As NullReferenceException
									'GetConstructor returned Nothing.
									Events.FireLogMessage("Core.Configuration", "WARNING", String.Format("Initializing module {0}: Class {1} does not have a suitable constructor.", sName, t.ToString()))
									bFound = False
								Catch ex As MethodAccessException
									Events.FireLogMessage("Core.Configuration", "WARNING", String.Format("Initializing module {0}: Could not invoke constructor for class {1}: {2}.", sName, t.ToString(), ex.Message))
									bFound = False
								Catch ex As System.Reflection.TargetInvocationException
									'Constructor Threw.
									Events.FireLogMessage("Core.Configuration", "WARNING", String.Format("Failed to initialize module {0}: Exception {1} thrown from constructor: {2}", sName, ex.InnerException.GetType().ToString(), ex.InnerException.Message))
									Exit For
								End Try
							End With
						End If
					Next
					'You might think we'd lose the Assembly here. Nope. There are lots of ways we can get this very Assembly object back :P .
				End With
				'Now we can run the module.
				Try
					mMod.Name = sName
					If mMod.ModLoad(Split(sArgs, " ")) Then
						mMod.Active = True
					Else
						Events.FireLogMessage("Core.Configuration", "WARNING", String.Format("Failed to initialize module {0}: ModLoad returned False!", sName))
					End If
				Catch ex As Exception
					Events.FireLogMessage("Core.Configuration", "WARNING", String.Format("Failed to initialize module {0}: Exception thrown: {1}", sName, ex.Message))
				End Try
				'TODO: Do configuration loading.
			End If
		Next
		'And done.
		Return True
	End Function
	'The start of it all.
	Public Function Main(ByVal Args() As String) As Integer
		Randomize(Timer)
		Events.FireLogMessage("Core", "TRACE", "Entering Main()")
		'The Main Loop.
		'First time connection, we'll make sure the host is connectable before we begin.
		Events.FireLogMessage("Core", "NOTICE", String.Format("Connecting to {0}:{1}", Conf.UplinkAddress.Address, Conf.UplinkAddress.Port))
		Try
			sck = New System.Net.Sockets.Socket(Net.Sockets.AddressFamily.InterNetwork, Net.Sockets.SocketType.Stream, Net.Sockets.ProtocolType.Tcp)
			sck.Blocking = True
			sck.Connect(Conf.UplinkAddress)
		Catch ex As Exception
			Events.FireLogMessage("Core", "ERROR", String.Format("Failed to connect to server: {0)", ex.Message))
			sck = Nothing
			Return 1
		End Try
		'Now send our login.
		Dim buffer As String = ""
		Services = New Server(Me)
		With Services
			.Name = Conf.ServerName
			.Numeric = Conf.ServerNumeric
			.Info = Conf.ServerDesc
		End With
		protocol.LoginToServer()
		'Send in our psuedoclients. We have to do this first or else our netsynch processing will cause things like ChanServ or BotServ to
		'send invalid messages, MODEs, or SJOINs.
		Dim numeric As Integer
		For Each s As ServiceClient In Clients
			'First construct a user object for it.
			s.node = New User(Me)
			s.node.AbuseTeam = False
			s.node.AwayMessage = ""
			s.node.Flags = ""
			s.node.Hostname = s.Host
			s.node.Info = s.RealName
			s.node.IP = System.Net.IPAddress.Loopback
			s.node.Nick = s.Nick
			Do
				numeric = CInt(Int(Rnd() * Integer.MaxValue))
			Loop Until protocol.IsValidNumeric(numeric, False)
			s.node.Numeric = numeric
			s.node.Server = Services
			Services.SubNodes.Add(s.node)
			s.node.Since = 0
			s.node.TS = API.GetTS()
			s.node.Usermodes = s.Usermode
			s.node.Username = s.Ident
			s.node.VHost = Nothing
			s.node.VIdent = s.node.Username
			protocol.IntroduceClient(s.node.Nick, s.node.Username, s.node.Hostname, s.node.RealName, s.node.Usermodes, s.node.Numeric, s.node.Server.Name, s.node.TS)
		Next
		While Not protocol.Synched
			Try
				buffer = API.GetServ(TimeSpan.Zero)
			Catch ex As System.Net.Sockets.SocketException
				If ex.ErrorCode = 10101 Then
					Events.FireLogMessage("Core", "ERROR", "Uplink closed the connection.")
					sck.Close()
					Return 1
				Else
					Events.FireLogMessage("Core", "ERROR", String.Format("Read error to uplink: {0}", ex.Message))
					sck.Close()
					Return 1
				End If
			End Try
			protocol.ParseCmd(buffer)
		End While
		protocol.EndSynch()
		Halt = HaltCode.HALT_CONTINUE
		While Halt = HaltCode.HALT_CONTINUE
			If sck Is Nothing Then
				'Connect to server.
				Try
					protocol.Synched = False
					sck = New System.Net.Sockets.Socket(Net.Sockets.AddressFamily.InterNetwork, Net.Sockets.SocketType.Stream, Net.Sockets.ProtocolType.Tcp)
					sck.Blocking = True
					sck.Connect(Conf.UplinkAddress)
					Services = New Server(Me)
					With Services
						.Name = Conf.ServerName
						.Numeric = Conf.ServerNumeric
						.Info = Conf.ServerDesc
					End With
					protocol.LoginToServer()
					'Send in our psuedoclients. We have to do this first or else our netsynch processing will cause things like ChanServ or BotServ to
					'send invalid messages, MODEs, or SJOINs.
					For Each s As ServiceClient In Clients
						'First construct a user object for it.
						s.node = New User(Me)
						s.node.AbuseTeam = False
						s.node.AwayMessage = ""
						s.node.Flags = ""
						s.node.Hostname = s.Host
						s.node.Info = s.RealName
						s.node.IP = System.Net.IPAddress.Loopback
						s.node.Nick = s.Nick
						Do
							numeric = CInt(Int(Rnd() * Integer.MaxValue))
						Loop Until protocol.IsValidNumeric(numeric, False)
						s.node.Numeric = numeric
						s.node.Server = Services
						Services.SubNodes.Add(s.node)
						s.node.Since = 0
						s.node.TS = API.GetTS()
						s.node.Usermodes = s.Usermode
						s.node.Username = s.Ident
						s.node.VHost = Nothing
						s.node.VIdent = s.node.Username
						protocol.IntroduceClient(s.node.Nick, s.node.Username, s.node.Hostname, s.node.RealName, s.node.Usermodes, s.node.Numeric, s.node.Server.Name, s.node.TS)
					Next
					While Not protocol.Synched
						Try
							buffer = API.GetServ(TimeSpan.Zero)
							protocol.ParseCmd(buffer)
						Catch ex As System.Net.Sockets.SocketException
							If ex.ErrorCode = 10101 Then
								Events.FireLogMessage("Core", "ERROR", "Uplink closed the connection.")
								sck.Close()
								sck = Nothing
							Else
								Events.FireLogMessage("Core", "ERROR", String.Format("Read error to uplink: {0}", ex.Message))
								sck.Close()
								sck = Nothing
							End If
						Catch ex As Exception
							Events.FireLogMessage("Core", "ERROR", String.Format("Command parser threw {0}: {1}", ex.GetType().ToString(), ex.Message))
						End Try
					End While
					protocol.EndSynch()
				Catch ex As Exception
					Events.FireLogMessage("Core", "ERROR", String.Format("Failed to connect to server: {0)", ex.Message))
					sck = Nothing
				End Try
			Else
				'Parse commands normally.
				Try
					buffer = API.GetServ(New TimeSpan(0, 0, 3))
					If Not buffer Is Nothing Then
						protocol.ParseCmd(buffer)
					End If
				Catch ex As System.Net.Sockets.SocketException When ex.ErrorCode = 10101
					Events.FireLogMessage("Core", "ERROR", "Uplink closed the connection.")
					sck.Close()
					sck = Nothing
				Catch ex As System.Net.Sockets.SocketException
					Events.FireLogMessage("Core", "ERROR", String.Format("Read error from uplink: {0}", ex.Message))
					sck.Close()
					sck = Nothing
				Catch ex As System.Reflection.TargetInvocationException
					Dim ex2 As Exception = ex
					While TypeOf ex2 Is System.Reflection.TargetInvocationException
						ex2 = ex2.InnerException
					End While
					Events.FireLogMessage("Core", "ERROR", String.Format("Command parser threw {0}: {1}", ex2.GetType().ToString(), ex2.Message))
				Catch ex As Exception
					Events.FireLogMessage("Core", "ERROR", String.Format("Command parser threw {0}: {1}", ex.GetType().ToString(), ex.Message))
				End Try
			End If
		End While
		For Each m As WinSECore.Module In Modules()
			If Not m.SaveDatabase() Then
				Events.FireLogMessage("Core", "WARNING", "Database for " & m.Name & " failed to save.")
			End If
		Next
		Try
			dbdriver.SaveDatabase(db)
		Catch ex As Exception
			Events.FireLogMessage("Core", "ERROR", "OH THE HUMANITY! Failed to save databases! " & ex.Message)
		End Try
		API.ExitServer("Shutting down.", IRCMap.Name)
		sck.Shutdown(Net.Sockets.SocketShutdown.Both)
		sck.Close()
		Events.FireLogMessage("Core", "TRACE", "Leaving Main()")
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
				If Me.CryptMethod Is Nothing Then
					Return Me.PassPhrase = .PassPhrase AndAlso .CryptMethod Is Nothing
				ElseIf .CryptMethod Is Nothing Then
					Return False
				Else
					Return Me.PassPhrase = .PassPhrase AndAlso Me.CryptMethod.Equals(.CryptMethod)
				End If
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
	Public UplinkAddress As System.Net.IPEndPoint
	Public SendPass As String
	Public RecvPass As Password
	Public NetworkName As String
	Public MasterNick As String	'The nick of the permanent master.
	Public MOTDFile As String	'Location (FULL PATH) of the MOTD.
	Public MOTD() As String	'Contents of the MOTD file - used to buffer the MOTD so that we don't read it all the time. Refreshed on REHASH.
	Public WinSERoot As String	'Where we are.
	Public ExtRoot As String	'Base location of modules.
	Public ExtConfRoot As String	'Base location of module configs.
	Public LoadModules As StringCollection	'Each LoadModule line.
	Public HelpDirs As StringCollection
End Structure