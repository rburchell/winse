Module WinSE
	Dim nofork As Boolean, debug As Integer
	Dim c As WinSECore.Core
	Dim logfile As IO.TextWriter

	Private Function AppPath() As String
		Dim p As String
		p = System.Reflection.Assembly.GetExecutingAssembly().Location
		If InStr(p, "\") = 0 Then
			p = Left(p, InStrRev(p, "/") - 1)
		Else
			p = Left(p, InStrRev(p, "\") - 1)
		End If
		Return p
	End Function

	Private Function DumpObject(ByVal o As Object, ByVal name As String) As String
		Dim dump As New IO.StringWriter, rp As System.Security.Permissions.ReflectionPermission
		Static dumplevel As Integer
		dump.WriteLine("{0}*** Dumping object {1} of type {2}", New String(Chr(9), dumplevel), name, o.GetType().ToString())
		rp = New System.Security.Permissions.ReflectionPermission(Security.Permissions.ReflectionPermissionFlag.MemberAccess Or Security.Permissions.ReflectionPermissionFlag.TypeInformation)
		Try
			rp.Demand()
		Catch ex As System.Security.SecurityException
			dump.WriteLine("{0}Warning! Could not demand ReflectionPermission for dumping this object! Only Public fields will be available. This may make the dump less useful for debugging...", New String(Chr(9), dumplevel))
			rp = Nothing
		End Try
		With o.GetType
			For Each fi As System.Reflection.FieldInfo In .GetFields(Reflection.BindingFlags.Instance Or Reflection.BindingFlags.Public Or DirectCast(IIf(rp Is Nothing, Reflection.BindingFlags.Default, Reflection.BindingFlags.NonPublic), System.Reflection.BindingFlags) Or Reflection.BindingFlags.GetField)
				With fi
					If fi.FieldType.IsPrimitive Then
						dump.WriteLine("{0}{1} As {2} = {3}", New String(Chr(9), dumplevel + 1), fi.Name, fi.FieldHandle.ToString(), fi.GetValue(o))
					Else
						dumplevel += 1
						dump.Write(DumpObject(fi.GetValue(o), name + "." + fi.Name))
						dumplevel -= 1
					End If
				End With
			Next
			If Array.IndexOf(o.GetType().GetInterfaces(), GetType(System.Collections.IEnumerable)) >= 0 Then
				dump.WriteLine("{0}*** Obejct {1} is enumerable, dumping contents.", New String(Chr(9), dumplevel + 1), name)
				For Each o2 As Object In DirectCast(o, System.Collections.IEnumerable)
					dumplevel += 1
					dump.Write(DumpObject(o2, name + "[]"))
					dumplevel -= 1
				Next
			End If
		End With
		dump.WriteLine("{0}*** End Dump of object {1}", New String(Chr(9), dumplevel), name)
		Return dump.GetStringBuilder().ToString()
	End Function

#If Win32 Then
	Private Declare Function FreeConsole Lib "kernel32" () As Integer
#End If

	Private Sub LogHandler(ByVal Facility As String, ByVal Severity As String, ByVal Message As String)
		If nofork Then
			Console.Error.WriteLine("[{0:hh:mm:ss}] {1}:{2}:{3}", TimeOfDay, Facility, Severity, Message)
		End If
		logfile.WriteLine("[{0:hh:mm:ss}] {1}:{2}:{3}", TimeOfDay, Facility, Severity, Message)
	End Sub

	Function Main(ByVal Args() As String) As Integer
		For Each arg As String In Args
			Select Case LCase(arg)
				Case "-nofork"
					nofork = True
				Case "-debug"
					debug += 1
			End Select
		Next
		Try
			Console.Out.WriteLine("WinSE .NET Core Initialization... ")
			Try
				c = New WinSECore.Core
			Catch ex As Exception
				Console.Error.WriteLine("Core.Initialization: FATAL: Exception {0} occured during construction! {1}", ex.GetType().ToString(), ex.Message)
				Throw New Exception("Core Initialization Failed", ex)
			End Try
			Dim nRet As Integer
			Try
				nRet = c.Init(Args)
				If nRet <> 0 Then
					Console.Error.WriteLine("Core.Initialization: FATAL: Core Init() returned {0}", nRet)
					Return nRet
				End If
			Catch ex As Exception
				Console.Error.WriteLine("Core.Initialization: FATAL: Exception {0} occured during initialization! {1}", ex.GetType().ToString(), ex.Message)
				Throw New Exception("Core Initialization Failed", ex)
			End Try
			AddHandler c.Events.LogMessage, AddressOf LogHandler
			Console.Out.WriteLine("Opening Log file...")
			logfile = New IO.StreamWriter(AppPath() + "\winse.log", True)
#If Win32 Then
			If Not nofork Then
				Console.Out.WriteLine("Forking...")
				Console.SetOut(logfile)
				Console.SetError(logfile)
				FreeConsole()
			End If
#End If
			Try
				nRet = c.Main(Args)
				Return nRet
			Catch ex As Exception
				Console.Error.WriteLine("Core.Exception: FATAL: Exception {0} was thrown and not caught! {1}", ex.GetType().ToString(), ex.Message)
				Throw New Exception("Core Internal Error", ex)
			End Try
		Catch ex As Exception
			Console.Error.WriteLine("FATAL: Unhandled exception of type {0} has occured!", ex.GetType().ToString())
			Dim corefile As String
			corefile = String.Format(AppPath() + "\winse.{0}.core", System.Diagnostics.Process.GetCurrentProcess().Id)
			Console.Error.WriteLine("Debugging information has been logged to {0}.", corefile)
			Try
				Dim io As New IO.StreamWriter(corefile)
				io.WriteLine("This file was generated because a serious error occured. Please send this file to aquanight@users.sourceforge.net")
				io.WriteLine(ex.ToString())
				If Not c Is Nothing Then
					io.WriteLine("The following is a dump of the Core:")
					io.WriteLine(DumpObject(c, "WinSE.Main().c"))
				End If
				io.Close()
			Catch ex2 As System.Security.SecurityException
				Console.Error.WriteLine("#CRASH# AAAARGH! PERMISSION DENIED writing corefile! This is REALLY BAD!")
				Console.Error.WriteLine("We'll dump what we can here then. Please copy it and report it ASAP.")
				Console.Error.WriteLine(ex.ToString())
			Catch ex2 As Exception
				Console.Error.WriteLine("#CRASH# AAAARGH! We can't write the corefile! This is REALLY REALLY BAD!")
				Console.Error.WriteLine("Please send the two exceptions dumped below:")
				Console.Error.WriteLine("-- MAIN EXCEPTION --")
				Console.Error.WriteLine(ex.ToString())
				Console.Error.WriteLine("-- COREFILE EXCEPTION --")
				Console.Error.WriteLine(ex2.ToString())
			End Try
		End Try
	End Function
End Module
