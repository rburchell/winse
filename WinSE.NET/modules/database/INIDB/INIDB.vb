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

Public NotInheritable Class INIDB
	Inherits WinSECore.Module

	Public Sub New(ByVal c As WinSECore.Core)
		MyBase.New(c)
	End Sub

	Public Overrides Function ModLoad(ByVal params() As String) As Boolean
		Dim db As New INIDBDriver
		For Each s As String In params
			If s Like "dataroot=*" Then
				db.dataroot = Replace(Split(s, "=", 2)(1), "%WINSEROOT%", c.Conf.WinSERoot)
			End If
		Next
		If db.dataroot = "" Then
			c.Events.FireLogMessage("Database.INIDB", "ERROR", "dataroot argument missing")
			Return False
		End If
		c.dbdriver = db
		Return True
	End Function

	Public Overrides Sub ModUnload()

	End Sub
End Class

Public NotInheritable Class INIDBDriver
	Inherits WinSECore.DataDriver
	Public dataroot As String

	Public Overrides Function LoadDatabase() As WinSECore.Database
		Dim db As New WinSECore.Database, sTable As String, p As New WinSECore.INIParser, di As System.IO.DirectoryInfo
		If Not System.IO.Directory.Exists(dataroot) Then
			If System.IO.File.Exists(dataroot) Then
				Throw New IO.IOException(dataroot & " is not a directory.")
			End If
			MkDir(dataroot)
		End If
		di = New System.IO.DirectoryInfo(dataroot)
		For Each fi As System.IO.FileSystemInfo In di.GetFiles("*.db")
			sTable = fi.FullName
			Dim sBase As String, t As WinSECore.Table, r As WinSECore.Record, kRoot As WinSECore.Key
			sBase = Mid(sTable, InStrRev(sTable, "\") + 1)
			sBase = Left(sBase, Len(sBase) - 3)			 'Len(.db) = 3. 
			Try
				kRoot = p.Load(sTable)
			Catch ex As Exception
				Throw New IO.IOException("Failed to load table " & sBase & " (" & sTable & "): " & ex.Message, ex)
			End Try
			t = New WinSECore.Table(sBase)
			For Each kCur As WinSECore.Key In kRoot.SubKeys
				r = New WinSECore.Record(kCur.name)
				For Each v As WinSECore.Value In kCur.Values
					r.Add(v.name, CStr(v.value))
				Next
				t.Add(r)
			Next
			db.Add(t)
		Next
		Return db
	End Function

	Public Overrides Sub SaveDatabase(ByVal db As WinSECore.Database)
		Dim p As New WinSECore.INIParser
		Dim kRoot As WinSECore.Key, kCur As WinSECore.Key
		If Not System.IO.Directory.Exists(dataroot) Then
			If System.IO.File.Exists(dataroot) Then
				Throw New IO.IOException(dataroot & " is not a directory.")
			End If
			MkDir(dataroot)
		End If
		For Each t As WinSECore.Table In db
			kRoot = New WinSECore.Key(Nothing)
			For Each r As WinSECore.Record In t
				kCur = New WinSECore.Key(r.Name, kRoot)
				For Each f As WinSECore.Field In r
					kCur.Values.Add(New WinSECore.Value(f.Name, f.Value, kCur))
				Next
				kRoot.SubKeys.Add(kCur)
			Next
			p.Save(String.Format("{0}\{1}.db", dataroot, t.Name), kRoot)
		Next
	End Sub
End Class