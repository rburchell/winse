Attribute VB_Name = "Replies"
' Winse - WINdows SErvices. IRC services for Windows.
' Copyright (C) 2004 w00t[w00t@netronet.org]
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
'
' Contact Maintainer: w00t[w00t@netronet.org]

Option Explicit

'This file declares constants used to reply to stuff. If we change whats here,
'we change what the replies are. Makes it easy to port to other languages etc.
'------------------------------------------------------------------------------
Public Const IncorrectParam = "Incorrect parameter."
Public Const InsufficientParameters = "Insufficient parameters."
Public Const UnknownCommand = "Unknown command."
Public Const UserDoesntExist = "This user doesn't exist."
Public Const InsufficientPermissions = "Insufficient permissions."
Public Const MustBeOpered = "You must be opered to use this service. [+o]"
Public Const MustBeAServiceAdmin = "You must be opered to use this service. [+a]"
Public Const MustBeAServicesMasterOrComaster = "You must be a services master or comaster."
Public Const ServiceRestrictedToAbuseTeam = "This service is restricted to abuse team members only."
Public Const CommandRestrictedToAbuseTeam = "This command is restricted to abuse team members only."
Public Const ServiceFloodWarning = "---4WARNING--- You are flooding services. Please slow down."
Public Const ServiceFloodKill = "You were warned. Please do not flood services with requests."
Public Const ServicesConnectedToNetwork = "Services is now connected, and has been synched with the network."
Public Const AccessTooHigh = "You specified an access level too high. Use a value less than 255."

'KILL Reasons
Public Const KillReasonKilledService = "Do *NOT* /kill services!"
Public Const KillReasonPasswordLimit = "Too many bad password attempts."
'Replace() %n with GHOST user (could use n!u@h here?)
' - aquanight
Public Const KillReasonGhostKill = "GHOST Command used by %n."
Public Const KillReasonFlooding = "Please do not flood services!"
'Replace() %n with OperServ/whateverServ KILL user
'(n!u@h format?), and %r with KILL reason.
Public Const KillReasonOperServ = "Requested (%n (%r))"

'NickServ
Public Const NickServCommunicationNotice = "Services will now communicate via NOTICE"
Public Const NickServCommunicationPrivmsg = "Services will now communicate via PRIVMSG"
Public Const NickServNickAlreadyRegistered = "This nickname has already been registered. Please try another."
Public Const NickServNickRegistered = "This nickname has been registered with NickServ. If it is yours, use /msg nickserv identify <pass>, otherwise please choose another nickname."
'SVSNICK anyone? - aquanight
'Use these 3 for SET ENFORCE ON (normal)
Public Const NickServEnforceIn60 = "Your nick will be changed in 60 seconds if you do not comply."
Public Const NickServEnforceIn40 = "This nickname is registered. You have 40 seconds to identify or choose a different nick, or I will change your nick."
Public Const NickServEnforceIn20 = "Final warning - you have 20 seconds to identify or choose a different nick. If you do not, your nickname will be changed."
'Use this for SET KILL/ENFORCE QUICK - aquanight
Public Const NickServEnforceQuick = "Your nick will be changed in 20 seconds if you do not comply."
'Use this for SET KILL/ENFORCE IMMED if you implement it
' - aquanight
Public Const NickServEnforceImmed = "This nickname is registered and protected. You may not use it."
'Use this when using SVSNICK. Use Replace() to replace
'%n with the target nick (Guest???????) - aquanight
Public Const NickServEnforcingNick = "Your nick has been changed to %n."
Public Const NickServIdentificationSuccessful = "Identification sucessful, you are now identified."
Public Const NickServIdentificationBadPassword = "Your password is incorrect."
Public Const NickServIdentificationNotRegistered = "Your nickname is not registered."
'Might this be a good idea? - aquanight
Public Const NickServTooManyBadPasswords = "You have tried to incorrectly identify too many times and as such are being disconnected. Have a nice day."
'Nickserv REGISTER reply. Replace() %p with the password
'the user used.
Public Const NickServRegisterOK = "Your nickname is now registered with password %p. When connecting in the future, type /msg NickServ IDENTIFY %p to tell NickServ it's really you."

'AdminServ
Public Const AdminServCantAddMaster = "Only users with access 100 can add additional masters."
Public Const AdminServAccessModified = "User access modified sucessfully."
Public Const AdminServUserAddToAbuseTeam = "User added to the Abuse Team"
Public Const AdminServUserDelFromAbuseTeam = "User deleted from the Abuse Team"

'Agent
Public Const AgentUserUnidentified = "User un-identified successfully."

'ChanServ
'Use this when de-opping the first user, I guess?
' - aquanight
Public Const ChanServRegisteredChannel = "This channel has been registered with ChanServ."
