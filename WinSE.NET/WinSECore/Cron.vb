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

Public NotInheritable Class Cron
	Private ReadOnly Jobs As ArrayList
	Private ReadOnly TheCore As Core
	Private ReadOnly CronTimer As Timer

	Public Sub New(ByVal c As Core)
		TheCore = c
		CronTimer = TheCore.API.AddTimer(New System.TimeSpan(0, 1, 0), AddressOf RunJobs, -1)
	End Sub

	Private Sub RunJobs(ByVal t As Timer)
		Dim Job As CronJob, ThePresent As Date
		ThePresent = Now
		For Each Job In Jobs
			If Job.RunNow(ThePresent) Then Job.Run()
		Next
	End Sub

	Public Function Add(ByVal Job As CronJobCallback, ByVal Minutes() As Integer, ByVal Hours() As Integer, ByVal DaysOfMonth() As Integer, ByVal Months() As Integer, ByVal DaysOfWeek() As Integer, ByVal RunCount As Integer, ByVal ParamArray Args() As Object) As CronJob
		' myCronJob = Cron.Add(CallBackFunction,Minutes(),Hours(),DaysOfMonth(),Months(),DaysOfWeek(),RunCount,ParamArray Args())
		'
		' CallBackFunction = Public Delegate Sub CronJobCallback(ByVal Job As CronJob)
		' An empty array means *
		' A RunCount of -1 is Infinite.
		' A RunCount of 0 is an Exception.

		Dim newJob As New CronJob(Job, Minutes, Hours, DaysOfMonth, Months, DaysOfWeek, RunCount, Args)
		Jobs.Add(newJob)
		Return newJob
	End Function

	Public Sub Remove(ByVal Job As CronJob)
		Jobs.Remove(Job)
	End Sub
End Class


Public Delegate Sub CronJobCallback(ByVal Job As CronJob)

Public NotInheritable Class CronJob
	Private ReadOnly Job As CronJobCallback
	Private RunsRemaining As Integer
	Public ReadOnly Minutes() As Integer
	Public ReadOnly Hours() As Integer
	Public ReadOnly DaysOfMonth() As Integer
	Public ReadOnly Months() As Integer
	Public ReadOnly DaysOfWeek() As Integer
	Public Args() As Object

	Public Sub New(ByVal Job As CronJobCallback, ByVal Minutes() As Integer, ByVal Hours() As Integer, ByVal DaysOfMonth() As Integer, ByVal Months() As Integer, ByVal DaysOfWeek() As Integer, ByVal RunCount As Integer, ByVal ParamArray Args() As Object)
		Me.Job = Job
		Me.Minutes = Minutes
		Me.Hours = Hours
		Me.DaysOfMonth = DaysOfMonth
		Me.Months = Months
		Me.DaysOfWeek = DaysOfWeek
		Me.RunsRemaining = RunCount
		Me.Args = Args
	End Sub

	Public ReadOnly Property RunsLeft() As Integer
		Get
			Return RunsRemaining
		End Get
	End Property

	Public Overloads Function RunNow() As Boolean
		Me.RunNow(Now)
		'VB.NET wouldnt let me do "RunNow(Optional ByVal RunWhen As Date = Now)" because Now isnt a constant.
	End Function

	Public Overloads Function RunNow(ByVal RunWhen As Date) As Boolean
		If Not Minutes.Length = 0 AndAlso Not Array.IndexOf(Minutes, Now.Minute) >= 0 Then Return False
		If Not Hours.Length = 0 AndAlso Not Array.IndexOf(Hours, Now.Hour) >= 0 Then Return False
		If Not DaysOfMonth.Length = 0 AndAlso Not Array.IndexOf(DaysOfMonth, Now.Day) >= 0 Then Return False
		If Not Months.Length = 0 AndAlso Not Array.IndexOf(Months, Now.Month) >= 0 Then Return False
		If Not DaysOfWeek.Length = 0 AndAlso Not Array.IndexOf(DaysOfWeek, Now.DayOfWeek) >= 0 Then Return False
		Return True
	End Function

	Public Sub Run()
		If RunsRemaining = 0 Then Throw New Exception("Attempting to run an expired timer.")
		If RunsRemaining > 0 Then RunsRemaining -= 1
		Job(Me)
	End Sub
End Class