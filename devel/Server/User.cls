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

Public Nick As String                   'Nickname
Public EMail As String                  'User email. NOT CHECKED FOR VALIDITY!!
Public Password As String               'User password.
Public MemoID As Integer                'ID associated with memos in the memoserv database.
Public Modes As String                  'Usermodes
Private mMemos As Memos
Public HideEmail As Boolean             'Is email visible?
Public Access As String                 'Services access.
Public Requests As Byte                 'Flood level. Goes up by 1 on each request.
                                        'When it hits 5, a warning. 10, a kill. 20, a gline (unless >= services admin)
                                        'Flood level goes down by 1 every 2 seconds??
Public MsgStyle As Long                 'True=notice false=privmsg
Public AbuseTeam As Boolean             'Abuse Team members can use services commands that otherwise, only the services master can use.
Public IdentifiedToNick As String       'Holds nick that user has identified to. Blank if not identified.
Private mChannels As Channels           'Channels this user is on.
Public AwayMessage As String
Public IsService As Boolean             'Our own Service client. If this is set many stuff are ignored...
'Some extra stuff we might get from things like
'Unreal IRCd :P .
Public ts As Long                       'Time Stamp of the user.
Public CID As String                    'Client ID. Coming from Unreal this is just the Service Stamp.
Public UserName As String               'Ident (in USER or Identd reply).
Public HostName As String               'User's real hostname.
Public RealName As String               '"Real Name" of this user
Public VirtHost As String               'Virtual Host, from stuff like GETHOST or NICKv2
Public Server As String                 'Server this user is on.
Public SWhois As String                 'Extra Whois info.
'Extra data.
Public BadIdentifies As Long            'Number of bad IDENTIFYs. When this hit configured limit, we KILL.
Public BadIdentTimer As Single          'Number of seconds until the user is obsolved of his mistakes.
Public NickKillTimer As Single          'Number of seconds until the user is smote by the mighty NickServ.
'Anything else services need to store?
Private mCustom As Collection

Private Sub Class_Initialize()
    Set mMemos = New Memos
    Set mCustom = New Collection
    Set mChannels = New Channels
End Sub

Public Property Get Memos() As Memos
    Set Memos = mMemos
End Property

Public Property Get Custom() As Collection
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
        c.IdentifedUsers.Remove Nick
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

Public Sub ForceUserModes(ByVal Modes As String, Optional ByVal Sender As String = "")
    SetUserModes Modes
    SendData FormatString(":{0} SVS{1}MODE {2} {3}", IIf(Sender <> "", Sender, basMain.Config.ServerName), IIf(basMain.Config.ServerType = "Unreal", "2", ""), Nick, Modes)
End Sub

Public Sub ForceJoin(ByVal Channel As Channel, Optional ByVal Sender As String = "", Optional ByVal Override As Boolean = False)
    'We can leave it the IRCd to send us a JOIN for this.
    If Override Then
        'I don't think servers can invite, so "borrow" Channy.
        'We could SAJOIN, but I REFUSE TO USE SA* COMMANDS IN SERVICES.
        SendData FormatString(":{0} INVITE {1} {2}", IIf(Sender <> "", Sender, Service(SVSINDEX_CHANSERV).Nick), Nick, Channel.Name)
    End If
    SendData FormatString(":{0} SVSJOIN {1} {2}", IIf(Sender <> "", Sender, basMain.Config.ServerName), Nick, Channel.Name)
End Sub

Public Sub ForcePart(ByVal Channel As Channel)
    SendData FormatString(":{0} SVSPART {1} {2}", basMain.Config.ServerName, Nick, Channel.Name)
End Sub

Public Sub ForceChangeNick(ByVal NewNick As String)
    Dim TimeStamp As Long
    TimeStamp = basUnixTime.GetTime
    Call basFunctions.SendData(FormatString("SVSNICK {0} {1} {2}", Nick, NewNick, TimeStamp))
End Sub

Public Sub SetUserModes(ByVal Modes As String)
    Dim l As Integer
    Dim ModeChar As String * 1
    Dim AddModes As Boolean
    Dim Result As String
    Result = Me.Modes
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
'                sDebugServ.HandleUserMode Me, AddModes, ModeChar
                sMassServ.HandleUserMode Me, AddModes, ModeChar
                sNickServ.HandleUserMode Me, AddModes, ModeChar
                sOperServ.HandleUserMode Me, AddModes, ModeChar
                sRootServ.HandleUserMode Me, AddModes, ModeChar
            End If
' End Validity Checked Code
        End If
    Next l
    Me.Modes = Result
End Sub

Public Function HasFlag(ByVal Flag As String) As Boolean
    HasFlag = InStr(1, Access, Flag, vbBinaryCompare) > 0 'This is case sensitive. Make sure VB knows that :P .
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
