VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Members"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Dim mData As Collection

Private Sub Class_Initialize()
    Set mData = New Collection
End Sub

Public Sub Add(ByVal c As ChannelMember)
    mData.Add c
End Sub

Public Sub Remove(ByVal idx As Variant)
    If VarType(idx) = vbString Then
        mData.Remove KeyToIndex(idx)
    Else
        mData.Remove idx
    End If
End Sub

Public Function Item(ByVal idx As Variant) As ChannelMember
Attribute Item.VB_UserMemId = 0
    If VarType(idx) = vbString Then
        Set Item = mData(KeyToIndex(idx))
    Else
        Set Item = mData(idx)
    End If
End Function

Public Function Count() As Long
    Count = mData.Count
End Function

Public Function NewEnum() As IUnknown
Attribute NewEnum.VB_UserMemId = -4
    Set NewEnum = mData.[_NewEnum]
End Function

Public Function Exists(ByVal idx As Variant) As Boolean
    On Error Resume Next
    Exists = Not Item(idx) Is Nothing
End Function

Private Function KeyToIndex(ByVal Key As String) As Long
    Dim idx As Long
    For idx = 1 To mData.Count
        If mData(idx).Member.Nick = Key Then
            KeyToIndex = idx
            Exit Function
        End If
    Next idx
End Function

Public Function IndexOf(ByVal Item As ChannelMember) As Long
    Dim idx As Long
    For idx = 1 To mData.Count
        If mData(idx) Is Item Then
            IndexOf = idx
            Exit Function
        End If
    Next idx
End Function

