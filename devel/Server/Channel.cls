VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Channel"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public Name As String
Public Topic As String
Public TopicSetBy As String
Public TopicSetOn As Long                   'Not sure if this is really needed... --w00t
Public Modes As String
Private mMembers As Members
'Now for the extended modes that require parameters (+flL etc)
Private mBans As Collection
Private mExcepts As Collection
Private mInvites As Collection              'For hybrid :)
Public ChannelKey As String
Public FloodProtection As String            'chanmode +f
Public OverflowChannel As String
Public OverflowLimit As Long
Private mIdentifedUsers As Users            'Users who have IDENTIFYed.
'Anything else services need to store?
Private mCustom As Collection

Private Sub Class_Initialize()
    Set mMembers = New Members
    Set mBans = New Collection
    Set mExcepts = New Collection
    Set mInvites = New Collection
    Set mCustom = New Collection
End Sub

Public Property Get Custom() As Collection
    Set Custom = mCustom
End Property

Public Property Get Members() As Members
    Set Members = mMembers
End Property

Public Property Get Bans() As Collection
    Set Bans = mBans
End Property

Public Property Get Excepts() As Collection
    Set Excepts = mExcepts
End Property

Public Property Get Invites() As Collection
    Set Invites = mInvites
End Property

Public Property Get IdentifedUsers() As Users
    Set IdentifedUsers = mIdentifedUsers
End Property

Public Sub KickUser(ByVal Source As String, ByVal Victim As User, ByVal Reason As String)
    Call basFunctions.SendData(":" & Source & " KICK " & Me.Name & " " & Victim & " :" & Reason)
    Members.Remove Victim.Nick
    If Members.Count <= 0 Then Channels.Remove Me.Name
End Sub

Public Sub SendChannelModes(ByVal Source As String, ByVal Modes As String, ParamArray Parameters() As Variant)
    Call basFunctions.SendData(":" & Source & " MODE " & Me.Name & " " & Modes & " " & Join(Parameters, " "))
    SetChannelModes Source, Trim(Modes & " " & Join(Parameters, " "))
End Sub

Public Sub SetChannelModes(ByVal Source As String, ByVal Modes As String)
    'Indexes, for the character and parameter
    Dim iChar As Integer, iParam As Integer
    'Strings to store said character and parameter
    Dim sChar As String, sParam As String
    'Two arrays: one for holding the parsed mode string
    'and the other for holding the modes that are valid.
    Dim sMode As Variant, sValid As Variant
    'Are we setting or unsetting a mode?
    Dim bSet As Boolean
    bSet = True 'Start off in + by default.
    sMode = Split(Modes, " ") 'Parse the modes.
    sValid = Split(basMain.ChannelModes2, ",") 'And these too.
    iParam = 1 'Init the parameter index.
    For iChar = 1 To Len(sMode(0))
        sChar = Mid(sMode(0), iChar, 1) 'Get the modeflag
        If sChar = "+" Then 'Now setting modes
            bSet = True
        ElseIf sChar = "-" Then 'Now unsetting modes
            bSet = False
        ElseIf InStr(basMain.ChanModesForAccess, sChar) > 0 Then
            'Prefix mode: controls channel privs
            If iParam <= UBound(sMode) Then
                sParam = sMode(iParam)
                iParam = iParam + 1
                'Another extra check here - we may have
                'killed  user that was trying to be opped
                'via the IRCd. If that happens, then we
                'get a -1 out of index, even though the
                'change is supposedly valid. In this case
                'we'll just do what Unreal does and send
                'another KILL :P .
                '(If we had continued onward to
                'DispatchPrefix it would cause services
                'to die under a very normal
                'circumstance.)
                If IsServicesNick(sParam) Then
                    'It's a service spiel. We'll figure
                    'out how to deal with this later...
                    'For now, just do nothing so that
                    'we don't die :/ .
                Else
                    DispatchPrefix Source, bSet, sChar, basMain.Users(sParam)
                End If
            Else
                'EEEEEEEEEK!
                Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replace(Replies.SanityCheckParamlessModeChange, "%c", IIf(bSet, "+", "-") & sChar))
            End If
        ElseIf InStr(sValid(0), sChar) > 0 Then
            'Type A: Mode flag controls a list.
            If iParam <= UBound(sMode) Then
                sParam = sMode(iParam)
                iParam = iParam + 1
                DispatchModeTypeA Source, bSet, sChar, sParam
            Else
                'EEEEEEEEEK!
                Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replace(Replies.SanityCheckParamlessModeChange, "%c", IIf(bSet, "+", "-") & sChar))
            End If
        ElseIf InStr(sValid(1), sChar) > 0 Then
            'Type B: Use param for set and unset.
            If iParam <= UBound(sMode) Then
                sParam = sMode(iParam)
                iParam = iParam + 1
                DispatchModeTypeB Source, bSet, sChar, sParam
            ElseIf bSet = False Then
                'Some wacky IRCd might let us get away
                'unsetting a mode w/o parameter
                '*coughunrealircdcough*
                DispatchModeTypeB Source, False, sChar, ""
            Else
                'EEEEEEEEEK!
                Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replace(Replies.SanityCheckParamlessModeChange, "%c", IIf(bSet, "+", "-") & sChar))
            End If
        ElseIf InStr(sValid(2), sChar) > 0 Then
            'Type C: Use param only for set
            If bSet Then
                If iParam <= UBound(sMode) Then
                    sParam = sMode(iParam)
                    iParam = iParam + 1
                    DispatchModeTypeC bSet, sChar, sParam
                Else
                    'EEEEEEEEEK!
                    Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replace(Replies.SanityCheckParamlessModeChange, "%c", IIf(bSet, "+", "-") & sChar))
                End If
            Else
                DispatchModeTypeC Source, bSet, sChar
            End If
        ElseIf InStr(sValid(3), sChar) > 0 Then
            'Type D: Never use a param
            DispatchModeTypeD Source, bSet, sChar
        Else
            'EEEEEEEEEK!
            Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replace(Replies.SanityCheckUnknownModeChange, "%c", IIf(bSet, "+", "-") & sChar))
        End If
    Next iChar
    Exit Sub
End Sub

Private Sub DispatchPrefix(ByVal Source As String, ByVal bSet As Boolean, ByVal Char As String, ByVal Target As User)
    If Target Is Nothing Then
        'Now something really went pear-shaped. :P
        'Send out a scream.
        NotifyAllUsersWithServicesAccess Replace(Replies.SanityCheckInvalidIndex, "%n", "basFunctions.DispatchPrefix")
        'Reboot.
        RestartServices "Fatal sanity check error. Forcing restart."
    End If
    Dim m As ChannelMember
    Set m = Members(Target.Nick)
    If bSet And InStr(m.Modes, Char) = 0 Then
        m.Modes = m.Modes & Char
    Else
        m.Modes = Replace(m.Modes, Char, "")
    End If
    'Okay, now that we've updated their status, send it
    'out :) .
    sAdminServ.HandlePrefix Source, Me, bSet, Char, Target
    sAgent.HandlePrefix Source, Me, bSet, Char, Target
    sChanServ.HandlePrefix Source, Me, bSet, Char, Target
'    sDebugServ.HandlePrefix Source, Me, bSet, Char, Target
    sMassServ.HandlePrefix Source, Me, bSet, Char, Target
    sNickServ.HandlePrefix Source, Me, bSet, Char, Target
    sOperServ.HandlePrefix Source, Me, bSet, Char, Target
    sRootServ.HandlePrefix Source, Me, bSet, Char, Target
End Sub

Private Sub DispatchModeTypeA(ByVal Source As String, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)
    If Entry = "" Then
        'Now something really went pear-shaped. :P
        'Send out a scream.
        NotifyAllUsersWithServicesAccess Replace(Replies.SanityCheckInvalidIndex, "%n", "basFunctions.DispatchModeTypeA")
        'Reboot.
        RestartServices "Fatal sanity check error. Forcing restart."
    End If
    Select Case Char
        Case "b"
            If bSet Then
                If Not CollectionContains(Bans, Entry) Then Bans.Add Entry, Entry
            Else
                If CollectionContains(Bans, Entry) Then Bans.Remove Entry
            End If
        Case "e"
            If bSet Then
                If Not CollectionContains(Excepts, Entry) Then Excepts.Add Entry, Entry
            Else
                If CollectionContains(Excepts, Entry) Then Excepts.Remove Entry
            End If
        Case "I"
            If bSet Then
                If Not CollectionContains(Invites, Entry) Then Invites.Add Entry, Entry
            Else
                If CollectionContains(Invites, Entry) Then Invites.Remove Entry
            End If
        Case Else
            'Don't know? Don't care.
    End Select
    'Now send it out :)
    sAdminServ.HandleModeTypeA Source, Me, bSet, Char, Entry
    sAgent.HandleModeTypeA Source, Me, bSet, Char, Entry
    sChanServ.HandleModeTypeA Source, Me, bSet, Char, Entry
    sDebugServ.HandleModeTypeA Source, Me, bSet, Char, Entry
    sMassServ.HandleModeTypeA Source, Me, bSet, Char, Entry
    sNickServ.HandleModeTypeA Source, Me, bSet, Char, Entry
    sOperServ.HandleModeTypeA Source, Me, bSet, Char, Entry
    sRootServ.HandleModeTypeA Source, Me, bSet, Char, Entry
End Sub

Private Sub DispatchModeTypeB(ByVal Source As String, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)
    If (Entry = "" And bSet = True) Then
        'Now something really went pear-shaped. :P
        'Send out a scream.
        NotifyAllUsersWithServicesAccess Replace(Replies.SanityCheckInvalidIndex, "%n", "basFunctions.DispatchModeTypeA")
        'Reboot.
        RestartServices "Fatal sanity check error. Forcing restart."
    End If
    Select Case Char
        Case "k"
            ChannelKey = IIf(bSet, Entry, "")
        Case "L"
            OverflowChannel = IIf(bSet, Entry, "")
        Case "f"
            If bSet Then
                FloodProtection = Entry
            Else
                FloodProtection = ""
            End If
        Case Else
            'Don't know? Don't care.
    End Select
    'Now send it out :)
    sAdminServ.HandleModeTypeB Source, Me, bSet, Char, Entry
    sAgent.HandleModeTypeB Source, Me, bSet, Char, Entry
    sChanServ.HandleModeTypeB Source, Me, bSet, Char, Entry
'    sDebugServ.HandleModeTypeB Source, Me, bSet, Char, Entry
    sMassServ.HandleModeTypeB Source, Me, bSet, Char, Entry
    sNickServ.HandleModeTypeB Source, Me, bSet, Char, Entry
    sOperServ.HandleModeTypeB Source, Me, bSet, Char, Entry
    sRootServ.HandleModeTypeB Source, Me, bSet, Char, Entry
End Sub

Private Sub DispatchModeTypeC(ByVal Source As String, ByVal bSet As Boolean, ByVal Char As String, Optional ByVal Entry As String)
    If (Entry = "" And bSet = True) Then
        'Now something really went pear-shaped. :P
        'Send out a scream.
        NotifyAllUsersWithServicesAccess Replace(Replies.SanityCheckInvalidIndex, "%n", "basFunctions.DispatchModeTypeA")
        'Reboot.
        RestartServices "Fatal sanity check error. Forcing restart."
    End If
    Select Case Char
        Case "l"
            OverflowLimit = IIf(bSet, CLng(Entry), 0)
        Case Else
            'Don't know? Don't care.
    End Select
    'Now send it out :)
    sAdminServ.HandleModeTypeC Source, Me, bSet, Char, Entry
    sAgent.HandleModeTypeC Source, Me, bSet, Char, Entry
    sChanServ.HandleModeTypeC Source, Me, bSet, Char, Entry
    sDebugServ.HandleModeTypeC Source, Me, bSet, Char, Entry
    sMassServ.HandleModeTypeC Source, Me, bSet, Char, Entry
    sNickServ.HandleModeTypeC Source, Me, bSet, Char, Entry
    sOperServ.HandleModeTypeC Source, Me, bSet, Char, Entry
    sRootServ.HandleModeTypeC Source, Me, bSet, Char, Entry
End Sub

Private Sub DispatchModeTypeD(ByVal Source As String, ByVal bSet As Boolean, ByVal Char As String)
    If bSet Then
        If InStr(Modes, Char) = 0 Then Modes = Modes + Char
    Else
        'Don't need to check :) replace will do that for
        'us!
        Modes = Replace(Modes, Char, "")
    End If
    sAdminServ.HandleModeTypeD Source, Me, bSet, Char
    sAgent.HandleModeTypeD Source, Me, bSet, Char
    sChanServ.HandleModeTypeD Source, Me, bSet, Char
'    sDebugServ.HandleModeTypeD Source, Me, bSet, Char
    sMassServ.HandleModeTypeD Source, Me, bSet, Char
    sNickServ.HandleModeTypeD Source, Me, bSet, Char
    sOperServ.HandleModeTypeD Source, Me, bSet, Char
    sRootServ.HandleModeTypeD Source, Me, bSet, Char
End Sub
