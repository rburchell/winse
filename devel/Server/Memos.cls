VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Memos"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private mData As Collection

Private Sub Class_Initialize()
    Set mData = New Collection
End Sub

Public Sub Add(ByVal m As Memo)
    mData.Add m
End Sub

Public Sub Remove(ByVal idx As Variant)
    If IsObject(idx) Then
        If TypeOf idx Is Memo Then
            Dim n As Long
            For n = 1 To mData.Count
                While mData(n) Is idx: mData.Remove n: Wend
            Next n
        Else
            Error 13
        End If
    ElseIf IsNumeric(idx) Then
        On Error GoTo RemErr
        'something really gets screwed about here... esp when they dont have any memos
        ';)
        mData.Remove idx
        On Error GoTo 0
    Else
        Error 13
    End If
    Exit Sub
RemErr:
    'Just ignore for now...
End Sub

Public Function Item(ByVal idx As Variant) As Memo
Attribute Item.VB_UserMemId = 0
    On Error Resume Next
    If IsObject(idx) Then
        If TypeOf idx Is Memo Then
            LogEventWithMessage LogTypeWarn, "Deprected use of Memos(index)! Update code ASAP!"
            Set Item = idx
            Exit Function
        End If
    End If
    Set Item = mData(idx)
End Function

Public Function Count() As Long
    Count = mData.Count
End Function

Public Function Enumerate() As IUnknown
Attribute Enumerate.VB_UserMemId = -4
    Set Enumerate = mData.[_NewEnum]()
End Function

Public Function Exists(ByVal idx As Variant) As Boolean
    On Error Resume Next
    Exists = Not Item(idx) Is Nothing
End Function

Public Function IndexOf(ByVal Item As Memo) As Long
    Dim idx As Long
    For idx = 1 To mData.Count
        If mData(idx) Is Item Then
            IndexOf = idx
            Exit Function
        End If
    Next idx
End Function
