Attribute VB_Name = "basMain"
' Winse - WINdows SErvices. IRC services for Windows.
' Copyright (C) 2004 The Winse Team [http://www.sourceforge.net/projects/winse]
'
' This program is free software; you can redistribute it and/or modify
' it under the terms of the GNU General Public License as published by
' the Free Software Foundation; either version 2 of the License, or
' (at your option) any later version.
'
' This program is distributed in the hope that it will be useful,
' but WITHOUT ANY WARRANTY; without even the implied warranty of
' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
' GNU General Public License for more details.
'
' You should have received a copy of the GNU General Public License
' along with this program; if not, write to the Free Software
' Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
Option Explicit

'set to "DEBUG" to enable full logging.
'"NONE" disables logging to file. (really really not recommended!)
Public Const LoggingType = "DEBUG"
'the types of logging (for headers)
Public Const LogTypeBug = "BUG"
Public Const LogTypeError = "ERROR"
Public Const LogTypeWarn = "WARN"
Public Const LogTypeNotice = "NOTICE"
Public Const LogTypeDebug = "DEBUG"

'[ACCESS FLAGS]
Public Const AccFullAccess As String = "MmgoriIak"
Public Const AccFlagMaster As String * 1 = "M"
Public Const AccFlagCoMaster As String * 1 = "m"
Public Const AccFlagGetServNotices As String * 1 = "g"
Public Const AccFlagCanOperServ As String * 1 = "o"
Public Const AccFlagCanRootServ As String * 1 = "r"
Public Const AccFlagCanRootServInject As String * 1 = "i"
Public Const AccFlagCanRootServSuperInject As String * 1 = "I"
Public Const AccFlagCanMassServ As String * 1 = "a"
Public Const AccFlagCanMassKill As String * 1 = "k"
'[/ACCESS FLAGS]

Public Type ConfigVars
    ServerType As String
    '^Added this so we can use better ways of doing
    ' things if we have the right IRCd.  - Jason
    UplinkHost As String
    UplinkName As String
    UplinkPort As String
    UplinkPassword As String
    UplinkType As String
    ServerName As String
    ServerNumeric As Byte
    ServerDescription As String
    ServicesMaster  As String
    DefaultMessageType As Boolean
    GlobalTargets As String 'What Global sends to send something to everyone.
    InjectToOperServices As Boolean
    AbuseTeamPrivacy As Byte
End Type

Public Config As ConfigVars

'WinSe: WINdows SErvices, also a "pune" or "play on words" (wince, geddit??)
'... hasn't made me wince yet ^.- - aquanight
Public Const AppName = "winse"
Public Const AppVersion = "0.0.4.0"
Public Const AppCompileInfo = "sense_datum"
Public Const AppCompileDate = "2004/06/25-1400hours"

Public Const UserModes = "iowghraAsORTVSxNCWqBzvdHtGp"
Public Const ChannelModes2 = "be,fkL,l,psmntirRcOAQKVGCuzNSMT"
Public Const ChannelModes = "psmntirRcOAQKVGCuzNSMTbekfLl"
Public Const ChanModesForAccess = "qaohv"

Public Const FounderPrivs = "+qo"
Public Const CFounderPrivs = "+ao" 'or should we +q?
Public Const SOPPrivs = "+ao"
Public Const AOPPrivs = "+o"
Public Const HOPPrivs = "+h"
Public Const VOPPrivs = "+v"

Public Const SuspendMLock = "+Osnt"
Public Const SuspendTLock = "This channel is suspended."
Public Const ForbidTLock = "This channel is forbidden."

'I really think a seperate structure for user connection
'info and user nickserv data is necessary :P .
Public Type UserStructure
    Nick As String              'Nickname
    EMail As String             'User email. NOT CHECKED FOR VALIDITY!!
    Password As String          'User password.
    MemoID As Integer           'ID associated with memos in the memoserv database.
    Modes As String             'Usermodes
    HideEMail As Boolean        'Is email visible?
    Access As String            'Services access.
    Requests As Byte            'Flood level. Goes up by 1 on each request.
                                'When it hits 5, a warning. 10, a kill. 20, a gline (unless >= services admin)
                                'Flood level goes down by 1 every 2 seconds??
    MsgStyle As Boolean         'True=notice false=privmsg
    AbuseTeam As Boolean        'Abuse Team members can use services commands that otherwise, only the services master can use.
    IdentifiedToNick As String  'Holds nick that user has identified to. Blank if not identified.
    Channels As Collection      'Channels this user is on. (Use Channel ID as the value and key :) ).
    'Some extra stuff we might get from things like
    'Unreal IRCd :P .
    SignOn As Long              'Time Stamp of the user.
    SvsStamp As Long            '"Service stamp"
    UserName As String          'Ident (in USER or Identd reply).
    HostName As String          'User's real hostname.
    RealName As String          '"Real Name" of this user
    VirtHost As String          'Virtual Host, from stuff like GETHOST or NICKv2
    Server As String            'Server this user is on.
    'Anything else services need to store?
    'BLAH. New in struct isn't going to port very well.
    'Just don't let anyone forget to init it.
    Custom As Collection
End Type

Private Type ChannelAccess
    Nick As String
    Access As Byte 'must be < 255.
End Type

Public Type ChannelStructure
    Name As String
    Topic As String
    TopicSetBy As String
    TopicSetOn As Long 'Not sure if this is really needed... --w00t
    FounderPassword As String
    MLock As String 'modes for mlock
    TotalUsersOnAccessList As Integer
    AccessList() As ChannelAccess
    Modes As String
    
    TotalChannelUsers As Integer
    Users As Collection
    'Users on this channel. (Use UserID as the value and key :) ).
    'That kind of limit is impractical, and for storing
    'only 1-5 characters max, allocating 10 is a waste
    'of space :P . -aquanight
    'Ok, I basically just totally changed this :)
    'Basically, each entry in this collection is key'd
    'by the CStr() of the user's UserID. -aquanight
    UsersModes As Collection
    'Now for the extended modes that require parameters (+flL etc)
    Bans As Collection
    Excepts As Collection
    Invites As Collection 'For hybrid :)
    ChannelKey As String
    FloodProtection As String 'chanmode +f
    OverflowChannel As String
    OverflowLimit As Long
    'Anything else services need to store?
    Custom As Collection
End Type

Public Type Service
    Nick As String
    Hostmask As String
    Name As String
End Type


Public NextFreeUserIndex As Integer
Public NextFreeChannelIndex As Integer

Public TotalUsers As Integer
Public TotalChannels As Integer
Public Const TotalServices = 12

'We should eventually move to Dynamic buffers here.
'To be honest, I think dynamic buffers would make it
'WAY*10^7 faster to loop through stuff... *sigh*
Public Channels(32766) As ChannelStructure
Public Users(32766) As UserStructure
Public Service(TotalServices - 1) As Service

Public Buffer(32767) As String
Public BufferElements As Integer

Sub Main()
    'DO NOT REORDER THE SERVICES! eg chanserv (or whatever you call it) should be #0
    'If you change the order, you will see things like Agent setting channel topics (!)
    '--w00t
    basMain.TotalChannels = -1
    basMain.TotalUsers = -1
    'Let's parse our config :|
    basMain.ParseConfigurationFile (App.Path & "\winse.conf")
    
    'Note that you CAN have custom hostmasks (a sethost is issued) but I choose not to.
    'actually for aliases to work, the
    'hostname should generally be the same as the server
    'name (at the least, to avoid confusion). -aquanight
        'Who uses aliases, really. :P Besides, people like changing stuff. --w00t
    'I think a seperate RealName field would be nice :) -aquanight
        'Perhaps, but I cba atm :P --w00t
    Service(0).Nick = "ChanServ"
    Service(0).Hostmask = Config.ServerName '"channel-services." & DomainName
    Service(0).Name = "channel"
    
    Service(1).Nick = "NickServ" 'aka "the service that unreal loves to kill for no reason"
    Service(1).Hostmask = Config.ServerName '"nick-services." & DomainName
    Service(1).Name = "nickname"
    
    Service(2).Nick = "HostServ"
    Service(2).Hostmask = Config.ServerName '"hostmask-services." & DomainName
    Service(2).Name = "hostmask"
    
    Service(3).Nick = "BotServ"
    Service(3).Hostmask = Config.ServerName '"automation-services." & DomainName
    Service(3).Name = "automation"
    
    Service(4).Nick = "OperServ"
    Service(4).Hostmask = Config.ServerName '"operator-services." & DomainName
    Service(4).Name = "dictator"
    
    Service(5).Nick = "AdminServ"
    Service(5).Hostmask = Config.ServerName '"administrator-services." & DomainName
    Service(5).Name = "overlord"
    
    Service(6).Nick = "RootServ"
    Service(6).Hostmask = Config.ServerName '"master-services." & DomainName
    Service(6).Name = "master"
    
    Service(7).Nick = "Agent"
    Service(7).Hostmask = Config.ServerName '"blackglasses." & DomainName
    Service(7).Name = "smith"
    
    Service(8).Nick = "Global"
    Service(8).Hostmask = Config.ServerName '"noticer." & DomainName
    Service(8).Name = "noticer"
    
    Service(9).Nick = "MassServ"
    Service(9).Hostmask = Config.ServerName '"mass-services." & DomainName
    Service(9).Name = "wmd"
    
    Service(10).Nick = "MemoServ"
    Service(10).Hostmask = Config.ServerName '"memo-services." & DomainName
    Service(10).Name = "mailman"
    
    Service(11).Nick = "DebugServ"
    Service(11).Hostmask = Config.ServerName '"services." & DomainName
    Service(11).Name = "INVISIBLE"
    frmServer.Show
End Sub

Public Sub IntroduceUsers()
    Dim Nick As String
    Dim Host As String
    Dim Name As String
    Dim i As Integer
    For i = 0 To basMain.TotalServices - 1
        Nick = basMain.Service(i).Nick
        Host = basMain.Service(i).Hostmask
        Name = basMain.Service(i).Name
        Call basFunctions.IntroduceClient(Nick, Host, Name)
    Next i
End Sub

'HandlePrivMsg is no longer needed. It's work is now
'done in CommandDispatcher.CmdPrivMsg.

Public Sub ParseConfigurationFile(File As String)
    'Authored by w00t 27/06/2004
    'Probably dodgy as hell, but hey. File must be fully qualified, ie "./winse.conf"
    'wont work.
    
    'The directives.
    Dim Directives As Collection 'This should make things easier :) - aquanight
    Set Directives = New Collection
    Dim fd As Integer 'hope so :|
    Dim i As Integer
    Dim ConfigLine As String
    Dim ConfigCopy As String
    Dim DirectiveVal As String
    
    'Initialise directives.
    Directives.Add "CONFIGVER"
    Directives.Add "SERVERTYPE"
    Directives.Add "UPLINKHOST"
    Directives.Add "UPLINKPORT"
    Directives.Add "UPLINKNAME"
    Directives.Add "UPLINKPASSWORD"
    Directives.Add "UPLINKTYPE"
    Directives.Add "SERVERNAME"
    Directives.Add "SERVERDESCRIPTION"
    Directives.Add "SERVERNUMERIC"
    Directives.Add "SERVICESMASTER"
    Directives.Add "DEFAULTMESSAGETYPE"
    Directives.Add "GLOBALTARGETS"
    Directives.Add "INJECTTOOPERSERVICES"
    Directives.Add "ABUSETEAMPRIVACY"
    
    Call basFunctions.LogEvent(basMain.LogTypeDebug, "Checking conf existance")
    fd = FreeFile
    Open File For Append As #fd
    If LOF(fd) = 0 Then
        'Error, given config file doesnt exist.
        Call basFunctions.LogEvent(basMain.LogTypeError, Replies.ConfigFileDoesntExist)
        'clean up, terminate.
        Close #fd
        Kill File
        End
    End If
    Close #fd
    'k, by here, the file is confirmed as existing, so now... try to parse it :|
    'Make sure fd is still valid.
    Call basFunctions.LogEvent(basMain.LogTypeDebug, "Conf exists, parsing.")
    fd = FreeFile
    Open File For Input As #fd
NextLine:
    Do While Not EOF(fd)
        Line Input #fd, ConfigLine
        ConfigLine = Trim(ConfigLine)
        If Left(ConfigLine, 1) = "#" Or ConfigLine = "" Then
            'if its a comment, ignore. (update: also ignore blank lines :P)
            GoTo NextLine
        End If
        'Ok, now we need to :|:| try get stuff. Make a copy of the line in
        'ConfigCopy so we can mutilate it. (make it ucase for searching)
        ConfigCopy = UCase(ConfigLine)
        'See what directive we have...
        For i = 1 To Directives.Count
            If Left(ConfigCopy, Len(Directives(i))) = Directives(i) Then
                'We have a match!
                DirectiveVal = Right(ConfigLine, Len(ConfigLine) - (Len(Directives(i)) + 1))
                Select Case Directives(i)
                    Case "CONFIGVER"
                        If DirectiveVal <> "1.0.0.0" Then
                            Call basFunctions.LogEvent(basMain.LogTypeError, Replies.ConfigFileUnexpectedConfVersion)
                        End If
                    Case "SERVERTYPE"
                        basMain.Config.ServerType = UCase(DirectiveVal)
                    Case "UPLINKHOST"
                        basMain.Config.UplinkHost = DirectiveVal
                    Case "UPLINKPORT"
                        basMain.Config.UplinkPort = DirectiveVal
                    Case "UPLINKNAME"
                        basMain.Config.UplinkName = DirectiveVal
                    Case "UPLINKPASSWORD"
                        basMain.Config.UplinkPassword = DirectiveVal
                    Case "UPLINKTYPE"
                        basMain.Config.UplinkType = DirectiveVal
                    Case "SERVERNAME"
                        basMain.Config.ServerName = DirectiveVal
                    Case "SERVERDESCRIPTION"
                        basMain.Config.ServerDescription = DirectiveVal
                    Case "SERVERNUMERIC"
                        basMain.Config.ServerNumeric = DirectiveVal
                    Case "SERVICESMASTER"
                        basMain.Config.ServicesMaster = DirectiveVal
                    Case "GLOBALTARGETS"
                        basMain.Config.GlobalTargets = DirectiveVal
                    Case "DEFAULTMESSAGETYPE"
                        'Defines the default for users().msgstyle True=notice false=privmsg
                        Select Case DirectiveVal
                            Case "P", "p"
                                basMain.Config.DefaultMessageType = False
                            Case "N", "n"
                                basMain.Config.DefaultMessageType = True
                            Case Else
                                Call basFunctions.LogEvent(basMain.LogTypeWarn, Replies.ConfigFileInvalidMessageType)
                                basMain.Config.DefaultMessageType = True
                        End Select
                    Case "INJETTOOPERSERVICES"
                        'Defines the default for users().msgstyle True=notice false=privmsg
                        Select Case LCase(DirectiveVal)
                            Case "yes"
                                basMain.Config.InjectToOperServices = True
                            Case "no"
                                basMain.Config.InjectToOperServices = False
                            Case Else
                                Call basFunctions.LogEvent(basMain.LogTypeWarn, Replies.ConfigFileInvalidMessageType)
                                basMain.Config.InjectToOperServices = False
                        End Select
                    Case "ABUSETEAMPRIVACY"
                        'Defines the default for users().msgstyle True=notice false=privmsg
                        Select Case LCase(DirectiveVal)
                            Case "none"
                                basMain.Config.AbuseTeamPrivacy = 0
                            Case "partial"
                                basMain.Config.AbuseTeamPrivacy = 1
                            Case "full"
                                basMain.Config.AbuseTeamPrivacy = 2
                            Case Else
                                Call basFunctions.LogEvent(basMain.LogTypeWarn, Replies.ConfigFileInvalidMessageType)
                                basMain.Config.InjectToOperServices = False
                        End Select
                End Select
                GoTo NextLine
            End If
        Next i
        'No match. Warn and continue.
        Call basFunctions.LogEvent(basMain.LogTypeWarn, Replace(Replies.ConfigFileUnknownDirective, "%n", ConfigLine))
    Loop
    Close #fd
End Sub

