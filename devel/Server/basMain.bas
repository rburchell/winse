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

'Just because these are normally untype-able.
'They probably aren't mIRC specific but I don't care.
Public Const MIRC_CTCP = "" 'CTCP Character
Public Const MIRC_BOLD = "" 'mIRC Bold Attribute
Public Const MIRC_UNDERLINE = "" 'mIRC Underline Attribute
Public Const MIRC_REVERSE = "" 'mIRC Reverse Attribute
Public Const MIRC_COLOR = "" 'mIRC Color Attribute
Public Const MIRC_PLAIN = "" 'mIRC Plain (Reset All) Attribute

'[ACCESS FLAGS]
Public Const AccFullAccess As String = "MmgoriIakNC"
Public Const AccFlagMaster As String * 1 = "M"
Public Const AccFlagCoMaster As String * 1 = "m"
Public Const AccFlagGetServNotices As String * 1 = "g"
Public Const AccFlagCanOperServ As String * 1 = "o"
Public Const AccFlagCanRootServ As String * 1 = "r"
Public Const AccFlagCanRootServInject As String * 1 = "i"
Public Const AccFlagCanRootServSuperInject As String * 1 = "I"
Public Const AccFlagCanMassServ As String * 1 = "a"
Public Const AccFlagCanMassKill As String * 1 = "k"
Public Const AccFlagNickAdmin As String * 1 = "N"
Public Const AccFlagChanAdmin As String * 1 = "C"
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
    DefaultMessageType As Long
    GlobalTargets As String 'What Global sends to send something to everyone.
    InjectToOperServices As Boolean
    AbuseTeamPrivacy As Byte
    ConnectString As String 'We need this to connect to the database. Must include provider and everything.
    BadPassLimit As Integer 'This could be anything really.
    BadPassTimeout As Integer 'Yes ridiculous limit/timeouts like 32767 each could be what an admin wants :P .
End Type

Public Config As ConfigVars

Public MOTD As String 'The cached MOTD

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

Public Type Service
    Nick As String
    Hostmask As String
    Name As String
    UserModes As String
    Info As String
End Type

Public Const TotalServices = 12

'We should eventually move to Dynamic buffers here.
'To be honest, I think dynamic buffers would make it
'WAY*10^7 faster to loop through stuff... *sigh*
Public Channels As New Channels
Public Users As New Users
'Yay, new server tracking!
Public Servers As New Servers
Public Service(TotalServices - 1) As Service
'Because I'm SO TIRED OF GUESSING THE SERVICE INDICES.
Public Const SVSINDEX_CHANSERV = 0
Public Const SVSINDEX_NICKSERV = 1
Public Const SVSINDEX_HOSTSERV = 2
Public Const SVSINDEX_BOTSERV = 3
Public Const SVSINDEX_OPERSERV = 4
Public Const SVSINDEX_ADMINSERV = 5
Public Const SVSINDEX_ROOTSERV = 6
Public Const SVSINDEX_AGENT = 7
Public Const SVSINDEX_GLOBAL = 8
Public Const SVSINDEX_MASSSERV = 9
Public Const SVSINDEX_MEMOSERV = 10
Public Const SVSINDEX_DEBUGSERV = 11

'This will be used in some places...
Public Const E_NOTIMPL = &H80004001

Public Buffer(32767) As String
Public BufferElements As Integer

Sub Main()
    'DO NOT REORDER THE SERVICES! eg chanserv (or whatever you call it) should be #0
    'If you change the order, you will see things like Agent setting channel topics (!)
    '--w00t
    'Let's parse our config :|
    basMain.ParseConfigurationFile (App.Path & "\winse.conf")
    basMain.Config.ConnectString = Replace(basMain.Config.ConnectString, "$APPPATH", App.Path)
    
    Dim c As Connection
    Set c = OpenDB(basMain.Config.ConnectString)
    sChanServ.LoadData c
    sMemoServ.LoadData c
    'That's all. Close it up.
    c.Close
    Set c = Nothing
    
    'Note that you CAN have custom hostmasks (a sethost is issued) but I choose not to.
    'actually for aliases to work, the
    'hostname should generally be the same as the server
    'name (at the least, to avoid confusion). -aquanight
        'Who uses aliases, really. :P Besides, people like changing stuff. --w00t
    'I think a seperate RealName field would be nice :) -aquanight
        'Perhaps, but I cba atm :P --w00t
    Service(SVSINDEX_CHANSERV).Nick = "ChanServ"
    Service(SVSINDEX_CHANSERV).Hostmask = Config.ServerName '"channel-services." & DomainName
    Service(SVSINDEX_CHANSERV).Name = "channel"
    Service(SVSINDEX_CHANSERV).UserModes = "+Sqrp"
    Service(SVSINDEX_CHANSERV).Info = "Channel Registration Services"
    
    Service(SVSINDEX_NICKSERV).Nick = "NickServ" 'aka "the service that unreal loves to kill for no reason"
    Service(SVSINDEX_NICKSERV).Hostmask = Config.ServerName '"nick-services." & DomainName
    Service(SVSINDEX_NICKSERV).Name = "nickname"
    Service(SVSINDEX_NICKSERV).UserModes = "+Sqrp"
    Service(SVSINDEX_NICKSERV).Info = "Nickname Registration Services"
    
    Service(SVSINDEX_HOSTSERV).Nick = "HostServ"
    Service(SVSINDEX_HOSTSERV).Hostmask = Config.ServerName '"hostmask-services." & DomainName
    Service(SVSINDEX_HOSTSERV).Name = "hostmask"
    Service(SVSINDEX_HOSTSERV).UserModes = "+Sqrp"
    Service(SVSINDEX_HOSTSERV).Info = "Virtual Host Services"
    
    Service(SVSINDEX_BOTSERV).Nick = "BotServ"
    Service(SVSINDEX_BOTSERV).Hostmask = Config.ServerName '"automation-services." & DomainName
    Service(SVSINDEX_BOTSERV).Name = "automation"
    Service(SVSINDEX_BOTSERV).UserModes = "+Sqrp"
    Service(SVSINDEX_BOTSERV).Info = "Bot Control Services"
    
    Service(SVSINDEX_OPERSERV).Nick = "OperServ"
    Service(SVSINDEX_OPERSERV).Hostmask = Config.ServerName '"operator-services." & DomainName
    Service(SVSINDEX_OPERSERV).Name = "dictator"
    Service(SVSINDEX_OPERSERV).UserModes = "+ioSqrp"
    Service(SVSINDEX_OPERSERV).Info = "Operator Services"
    
    Service(SVSINDEX_ADMINSERV).Nick = "AdminServ"
    Service(SVSINDEX_ADMINSERV).Hostmask = Config.ServerName '"administrator-services." & DomainName
    Service(SVSINDEX_ADMINSERV).Name = "overlord"
    Service(SVSINDEX_ADMINSERV).UserModes = "+ioASqrp"
    Service(SVSINDEX_ADMINSERV).Info = "Network Administration Services"
    
    Service(SVSINDEX_ROOTSERV).Nick = "RootServ"
    Service(SVSINDEX_ROOTSERV).Hostmask = Config.ServerName '"master-services." & DomainName
    Service(SVSINDEX_ROOTSERV).Name = "master"
    Service(SVSINDEX_ROOTSERV).UserModes = "+ioaSqrp"
    Service(SVSINDEX_ROOTSERV).Info = "Services Control"
    
    Service(SVSINDEX_AGENT).Nick = "Agent"
    Service(SVSINDEX_AGENT).Hostmask = Config.ServerName '"blackglasses." & DomainName
    Service(SVSINDEX_AGENT).Name = "smith"
    Service(SVSINDEX_AGENT).UserModes = "+ioaSqrp"
    Service(SVSINDEX_AGENT).Info = "Secret Agent Man"
    
    Service(SVSINDEX_GLOBAL).Nick = "Global"
    Service(SVSINDEX_GLOBAL).Hostmask = Config.ServerName '"noticer." & DomainName
    Service(SVSINDEX_GLOBAL).Name = "noticer"
    Service(SVSINDEX_GLOBAL).UserModes = "+ioSqrp"
    Service(SVSINDEX_GLOBAL).Info = "Global Noticer"
    
    Service(SVSINDEX_MASSSERV).Nick = "MassServ"
    Service(SVSINDEX_MASSSERV).Hostmask = Config.ServerName '"mass-services." & DomainName
    Service(SVSINDEX_MASSSERV).Name = "wmd"
    Service(SVSINDEX_MASSSERV).UserModes = "+ioaSqrp"
    Service(SVSINDEX_MASSSERV).Info = "Mass Operation Services"
    
    Service(SVSINDEX_MEMOSERV).Nick = "MemoServ"
    Service(SVSINDEX_MEMOSERV).Hostmask = Config.ServerName '"memo-services." & DomainName
    Service(SVSINDEX_MEMOSERV).Name = "mailman"
    Service(SVSINDEX_MEMOSERV).UserModes = "+Sqrp"
    Service(SVSINDEX_MEMOSERV).Info = "Memorandum Services"
    
    Service(SVSINDEX_DEBUGSERV).Nick = "DebugServ"
    Service(SVSINDEX_DEBUGSERV).Hostmask = Config.ServerName '"services." & DomainName
    Service(SVSINDEX_DEBUGSERV).Name = "INVISIBLE"
    Service(SVSINDEX_DEBUGSERV).UserModes = "+iSqrp"
    Service(SVSINDEX_DEBUGSERV).Info = "Debugging Services"
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
        Call basFunctions.IntroduceClient(Nick, Host, Name, False, Service(i).UserModes)
    Next i
End Sub

'HandlePrivMsg is no longer needed. It's work is now
'done in CommandDispatcher.CmdPrivMsg.

Public Sub ParseConfigurationFile(File As String)
    'Authored by w00t 27/06/2004
    'Probably dodgy as hell, but hey. File must be fully qualified, ie "./winse.conf"
    'wont work.
    
    'The directives.
    Dim fd As Integer 'hope so :|
    Dim i As Integer
    Dim ConfigLine As String
    Dim ConfigCopy As String
    Dim DirectiveName As String
    Dim DirectiveVal As String
    
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
        'Right time to unw00t this :) .
        DirectiveName = Split(ConfigLine, "=", 2)(0)
        DirectiveVal = Split(ConfigLine, "=", 2)(1)
        Select Case UCase(DirectiveName)
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
                        basMain.Config.DefaultMessageType = 0
                    Case "N", "n"
                        basMain.Config.DefaultMessageType = 1
                    Case Else
                        Call basFunctions.LogEvent(basMain.LogTypeWarn, Replies.ConfigFileInvalidMessageType)
                        basMain.Config.DefaultMessageType = 1
                End Select
            Case "INJECTTOOPERSERVICES"
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
            Case "CONNECTSTRING"
                basMain.Config.ConnectString = DirectiveVal 'Let ADO validate it ;p .
            Case "BADPASSLIMIT"
                basMain.Config.BadPassLimit = DirectiveVal
            Case "BADPASSTIMEOUT"
                basMain.Config.BadPassTimeout = DirectiveVal
            '<-- ADD NEW DIRECTIVES ABOVE THIS LINE! MUY IMPORTANTE! -->'
            Case Else
                'No match. Warn and continue.
                Call basFunctions.LogEvent(basMain.LogTypeWarn, Replace(Replies.ConfigFileUnknownDirective, "%n", ConfigLine))
        End Select
    Loop
    Close #fd
End Sub

