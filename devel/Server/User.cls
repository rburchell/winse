VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "User"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public Nick As String                 'Nickname
Public EMail As String                'User email. NOT CHECKED FOR VALIDITY!!
Public Password As String             'User password.
Public MemoID As Integer              'ID associated with memos in the memoserv database.
Public Modes As String                'Usermodes
Public HideEMail As Boolean           'Is email visible?
Public Access As String               'Services access.
Public Requests As Byte               'Flood level. Goes up by 1 on each request.
                                      'When it hits 5, a warning. 10, a kill. 20, a gline (unless >= services admin)
                                      'Flood level goes down by 1 every 2 seconds??
Public MsgStyle As Boolean            'True=notice false=privmsg
Public AbuseTeam As Boolean           'Abuse Team members can use services commands that otherwise, only the services master can use.
Public IdentifiedToNick As String     'Holds nick that user has identified to. Blank if not identified.
Private mChannels As Channels         'Channels this user is on.
'Some extra stuff we might get from things like
'Unreal IRCd :P .
Public SignOn As Long                 'Time Stamp of the user.
Public SvsStamp As Long               '"Service stamp"
Public UserName As String             'Ident (in USER or Identd reply).
Public HostName As String             'User's real hostname.
Public RealName As String             '"Real Name" of this user
Public VirtHost As String             'Virtual Host, from stuff like GETHOST or NICKv2
Public Server As String               'Server this user is on.
'Anything else services need to store?
Private mCustom As Collection

Private Sub Class_Initialize()
    Set mCustom = New Collection
End Sub

Public Property Get Custom() As Collection
    Set mChannels = New Channels
    Set Custom = mCustom
End Property

Public Property Get Channels() As Channels
    Set Channels = mChannels
End Property

Public Function IsAbuseTeamMember() As Boolean
    IsAbuseTeamMember = AbuseTeam
End Function

Public Function IsServicesAdmin() As Boolean
    IsServicesAdmin = (InStr(Modes, "a") <> 0)
End Function

Public Function IsOper() As Boolean
    IsOper = (InStr(Modes, "o") <> 0)
End Function

Public Sub KillUser(ByVal Message As String, Optional ByVal Killer As String = "Agent")
    If Nick = "" Then
        'For now, I'm throwing a Bad Call Error
        'Yes it's old fashioned, but if it where
        'my way, it'd be Throw New... you get the
        'idea :) . - aquanight
        Error 5
    End If
    If Not Killer = "" Then
        Message = Killer & " (" & Message & ")"
    End If
    basFunctions.SendData (":" + Killer + " KILL " & Nick & " :" & Message)
    Dispose
End Sub

Public Sub SVSKillUser(ByVal Message As String, Optional ByVal Killer As String = "Agent")
    Call basFunctions.SendData(":" + Killer + " SVSKILL " + Nick + " :" + Message)
    Dispose
End Sub

'Clears this client out of the Users and Channels array. Theoretically, this would result in the object
'becoming unreferenced, and thus deleted. Useful if something we did or received resulted in a client
'being dropped, but we really shouldn't do this while a valid client exists.
Public Sub Dispose()
    basMain.Users.Remove Nick
    Dim c As Channel
    On Error Resume Next
    For Each c In basMain.Channels
        c.Members.Remove Nick
        If c.Members.Count = 0 Then
            Channels.Remove c
        End If
    Next c
    Access = ""
    Modes = ""
    Nick = ""
    Requests = 0
    MsgStyle = False
End Sub

Public Sub CheckFloodLevel()
    'Flood level. Goes up by 1 on each request.
    'When it hits 5, a warning. 10, a kill. SHUN instead?
    If Requests >= 8 Then
        'kill, dont specify killer so it will default to "Agent"
        Call KillUser(Replies.ServiceFloodKill)
    End If
    If Requests = 4 Then
        'warn
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_GLOBAL).Nick, Nick, Replies.ServiceFloodWarning)
    End If
    'Increase flood requests
    Requests = Requests + 1
End Sub

Public Sub SetUserModes(ByVal Modes As String)
    Dim l As Integer
    Dim ModeChar As String * 1
    Dim AddModes As Boolean
    Dim Result As String
    Result = Modes
    AddModes = True
    For l = 1 To Len(Modes)
        ModeChar = Mid(Modes, l, 1)
        If (Asc(ModeChar) >= 65 And Asc(ModeChar) <= 90) Or (Asc(ModeChar) >= 97 And Asc(ModeChar) <= 122) Or Asc(ModeChar) = 43 Or Asc(ModeChar) = 45 Then
' Begin Validity Checked Code
            If ModeChar = "+" Then
                AddModes = True
            ElseIf ModeChar = "-" Then
                AddModes = False
            Else
                Result = Replace(Result, ModeChar, "")
                If AddModes Then Result = Result & ModeChar
                'Now for some callback time! -aquanight
                sAdminServ.HandleUserMode Me, AddModes, ModeChar
                sAgent.HandleUserMode Me, AddModes, ModeChar
                sChanServ.HandleUserMode Me, AddModes, ModeChar
                sDebugServ.HandleUserMode Me, AddModes, ModeChar
                sMassServ.HandleUserMode Me, AddModes, ModeChar
                sNickServ.HandleUserMode Me, AddModes, ModeChar
                sOperServ.HandleUserMode Me, AddModes, ModeChar
                sRootServ.HandleUserMode Me, AddModes, ModeChar
            End If
' End Validity Checked Code
        End If
    Next l
    Modes = Result
End Sub

Public Function HasFlag(ByVal Flag As String) As Boolean
    HasFlag = IIf(InStr(1, Access, Flag), True, False)
End Function

Public Sub SetFlags(ByVal FlagMask As String)
    If Not Mid(FlagMask, 1, 1) = "+" And Not Mid(FlagMask, 1, 1) = "-" Then 'Absolute Flag String
        Access = FlagMask
        Exit Sub
    End If
    ' Copied with few editions from my SetUserModes - Jason
    Dim l As Integer ' I use l or i for loops usually
    Dim ModeChar As String * 1
    Dim AddModes As Boolean
    Dim Result As String
    Result = Access
    AddModes = True
    For l = 1 To Len(FlagMask)
        ModeChar = Mid(FlagMask, l, 1)
        If (Asc(ModeChar) >= 65 And Asc(ModeChar) <= 90) Or _
         (Asc(ModeChar) >= 97 And Asc(ModeChar) <= 122) Or _
         Asc(ModeChar) = 43 Or Asc(ModeChar) = 45 Then
' Begin Validity Checked Code
            If ModeChar = "+" Then
                AddModes = True
            ElseIf ModeChar = "-" Then
                AddModes = False
            Else
                Result = Replace(Result, ModeChar, "")
                If AddModes Then Result = Result & ModeChar
            End If
' End Validity Checked Code
        End If
    Next l
    Access = Result
End Sub


