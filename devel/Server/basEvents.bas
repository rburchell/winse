Attribute VB_Name = "basEvents"
Option Explicit

'General IRC Events.
'When the channel is created.
'Parameters: Channel Joined (Channel), User Joined (User)
Public Const ChanCreate As String = "ChannelCreated"
'When a user joins the channel.
'Parameters: Channel Joined (Channel), User Joined (User)
Public Const ChanJoin As String = "ChannelJoined"
'When a user parts the channel.
'Parameters: Channel Parted (Channel), User Parted (User)
Public Const ChanPart As String = "ChannelParted"
'When the last user parts the channel.
'Parameters: Channel Parted (Channel), User Parted (User)
Public Const ChanDestroy As String = "ChannelDestroyed"
'When a user changes a member mode on a service.
'Parameters: Channel (Channel), Mode Change (+o, -a), Service Nick
Public Const ServiceChanModeChanged As String = "ServiceMemberModeChanged"

'NickServ/AuthServ Events.
'User IDENTIFY. Parameters: User (User), Nick/Account Identified (String).
Public Const NSEventIdentify = "NickAuth"
