VERSION 5.00
Object = "{F9043C88-F6F2-101A-A3C9-08002B2F49FB}#1.2#0"; "COMDLG32.OCX"
Begin VB.Form frmMain 
   Caption         =   "Untitiled - DBEditor"
   ClientHeight    =   3090
   ClientLeft      =   60
   ClientTop       =   750
   ClientWidth     =   4680
   LinkTopic       =   "Form1"
   ScaleHeight     =   3090
   ScaleWidth      =   4680
   StartUpPosition =   3  'Windows Default
   Begin VB.ListBox lstFields 
      Height          =   2055
      IntegralHeight  =   0   'False
      Left            =   2400
      TabIndex        =   3
      Top             =   480
      Width           =   2175
   End
   Begin VB.ListBox lstRecords 
      Height          =   2055
      IntegralHeight  =   0   'False
      Left            =   120
      TabIndex        =   1
      Top             =   480
      Width           =   2055
   End
   Begin VB.CommandButton cmdSet 
      Caption         =   "&Set"
      Default         =   -1  'True
      Enabled         =   0   'False
      Height          =   255
      Left            =   3840
      TabIndex        =   5
      Top             =   2760
      Width           =   735
   End
   Begin VB.TextBox txtValue 
      Enabled         =   0   'False
      Height          =   285
      Left            =   120
      TabIndex        =   4
      Top             =   2760
      Width           =   3615
   End
   Begin MSComDlg.CommonDialog dlg 
      Left            =   4560
      Top             =   3000
      _ExtentX        =   847
      _ExtentY        =   847
      _Version        =   393216
   End
   Begin VB.Line linSplit2 
      X1              =   120
      X2              =   4560
      Y1              =   2640
      Y2              =   2640
   End
   Begin VB.Line linRFSplit 
      X1              =   2280
      X2              =   2280
      Y1              =   120
      Y2              =   2640
   End
   Begin VB.Label lblFields 
      Caption         =   "&Fields:"
      Height          =   255
      Left            =   2400
      TabIndex        =   2
      Top             =   120
      Width           =   2175
   End
   Begin VB.Label lblRecords 
      Caption         =   "&Records:"
      Height          =   255
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   2055
   End
   Begin VB.Menu mnuFile 
      Caption         =   "&File"
      Begin VB.Menu mnuFileNew 
         Caption         =   "&New"
         Shortcut        =   ^N
      End
      Begin VB.Menu mnuFileOpen 
         Caption         =   "&Open..."
         Shortcut        =   ^O
      End
      Begin VB.Menu mnuFileBar0 
         Caption         =   "-"
      End
      Begin VB.Menu mnuFileSave 
         Caption         =   "&Save"
         Shortcut        =   ^T
      End
      Begin VB.Menu mnuFileSaveAs 
         Caption         =   "Save &As..."
      End
      Begin VB.Menu mnuFileBar1 
         Caption         =   "-"
      End
      Begin VB.Menu mnuFileExit 
         Caption         =   "E&xit"
      End
   End
   Begin VB.Menu mnuRecord 
      Caption         =   "&Record"
      Begin VB.Menu mnuRecordNew 
         Caption         =   "&New"
      End
      Begin VB.Menu mnuRecordDelete 
         Caption         =   "Delete"
         Enabled         =   0   'False
      End
      Begin VB.Menu mnuRecordRename 
         Caption         =   "Rename"
         Enabled         =   0   'False
      End
   End
   Begin VB.Menu mnuField 
      Caption         =   "&Field"
      Begin VB.Menu mnuFieldNew 
         Caption         =   "&New"
      End
      Begin VB.Menu mnuFieldDelete 
         Caption         =   "Delete"
         Enabled         =   0   'False
      End
      Begin VB.Menu mnuFieldRename 
         Caption         =   "Rename"
         Enabled         =   0   'False
      End
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Dim sCurFile As String, db As Database
Dim bChanged As Boolean

Public Sub LoadFile(ByVal File As String)
    LoadDatabase File, db
End Sub

Public Sub SaveFile(ByVal File As String)
    SaveDatabase File, db
End Sub

Public Sub Open_()
    With dlg
        .CancelError = True
        .DialogTitle = "Open"
        .FileName = ""
        .Filter = "Any File (*.*)|*.*"
        .Flags = cdlOFNExplorer Or cdlOFNFileMustExist Or cdlOFNHideReadOnly
        On Error GoTo ErrH
        .ShowOpen
        sCurFile = .FileName
    End With
    LoadFile sCurFile
    Exit Sub
ErrH:
    If Err.Number = cdlCancel Then
        Exit Sub
    Else
        Err.Raise Err.Number, Err.Source, Err.Description, Err.HelpFile, Err.HelpContext
    End If
End Sub

Public Function SaveAs() As Boolean
    With dlg
        .CancelError = True
        .DialogTitle = "Save As"
        .FileName = sCurFile
        .Filter = "Any File (*.*)|*.*"
        .Flags = cdlOFNExplorer Or cdlOFNPathMustExist Or cdlOFNHideReadOnly Or cdlOFNNoReadOnlyReturn Or cdlOFNOverwritePrompt
        On Error GoTo ErrH
        .ShowSave
        sCurFile = .FileName
    End With
    SaveFile sCurFile
    SaveAs = True
    Exit Function
ErrH:
    If Err.Number = cdlCancel Then
        SaveAs = False
        Exit Function
    Else
        Err.Raise Err.Number, Err.Source, Err.Description, Err.HelpFile, Err.HelpContext
    End If
End Function

Public Sub UpdateView(Optional ByVal Records As Boolean = False, Optional ByVal Fields As Boolean = False)
    Dim idx As Long
    If Records Then
        'SQUASH stupid "Changed"/"Click" events while
        'we work.
        lstRecords.Enabled = False
        lstRecords.Clear
        For idx = 0 To CountRecords(idx) - 1
            lstRecords.AddItem db.Records(idx).Name, idx
        Next idx
        lstRecords.Enabled = True
    End If
    On Error GoTo 0
    If lstRecords.ListIndex = -1 Then
        lstFields.Enabled = False
        lstFields.Clear
        lstFields.ListIndex = -1
        mnuRecordDelete.Enabled = False
        mnuRecordRename.Enabled = False
    Else
        mnuRecordDelete.Enabled = True
        mnuRecordRename.Enabled = True
        If Fields Then
            lstFields.Enabled = False
            lstFields.Clear
            For idx = 0 To CountFields(db, IndexOfRecord(db, lstRecords.List(lstRecords.ListIndex))) - 1
                lstFields.AddItem db.Records(IndexOfRecord(db, lstRecords.List(lstRecords.ListIndex))).Fields(idx).Name
            Next idx
            lstFields.Enabled = True
        End If
    End If
    mnuField.Enabled = lstFields.Enabled
    If lstFields.ListIndex = -1 Then
        mnuFieldDelete.Enabled = False
        mnuFieldRename.Enabled = False
        txtValue.Enabled = False
        cmdSet.Enabled = False
        txtValue.Text = ""
    Else
        mnuFieldDelete.Enabled = True
        mnuFieldRename.Enabled = True
        txtValue.Enabled = True
        cmdSet.Enabled = True
        txtValue.Text = RecordField(db, lstRecords.List(lstRecords.ListIndex), lstFields.List(lstFields.ListIndex))
    End If
End Sub

Public Function PromptSave() As Boolean
    If Not bChanged Then
        PromptSave = True
        Exit Function
    End If
    Select Case MsgBox("The database you are editing as has been changed. Would you like to save your changes before proceeding?", vbYesNoCancel, Caption)
        Case vbYes
            If sCurFile = "" Then
                PromptSave = SaveAs
                Exit Function
            Else
                SaveFile sCurFile
                PromptSave = True
            End If
            Exit Function
        Case vbNo
            PromptSave = True
            Exit Function
        Case vbCancel
            Exit Function
    End Select
End Function

Private Sub mnuFieldDelete_Click()
    If lstRecords.ListIndex < 0 Then Exit Sub
    DeleteField db, lstRecords.List(lstRecords.ListIndex), lstFields.List(lstFields.ListIndex)
    UpdateView False, True
End Sub

Private Sub mnuFieldNew_Click()
    Dim s As String
    s = InputBox("Enter the name of the new record:", Caption, "")
    If s = "" Then Exit Sub
    If IndexOfRecord(s) >= 0 Then
        MsgBox "A field with that name already exists...", vbExclamation, Caption
        lstFields.ListIndex = IndexOfField(db, IndexOfRecord(db, lstRecords.List(lstRecords.ListIndex)), s)
        UpdateView
        Exit Sub
    End If
    AddFieldToRecord db, lstRecords.List(lstRecords.ListIndex)
    UpdateView False, True
    lstFields.ListIndex = IndexOfField(db, IndexOfRecord(db, lstRecords.List(lstRecords.ListIndex)), s)
    UpdateView
End Sub

Private Sub mnuFieldRename_Click()
    Dim s As String
    s = InputBox("Enter the name of the new record:", Caption, "")
    If s = "" Then Exit Sub
    If IndexOfRecord(s) >= 0 Then
        MsgBox "A field with that name already exists...", vbExclamation, Caption
        lstFields.ListIndex = IndexOfField(db, IndexOfRecord(db, lstRecords.List(lstRecords.ListIndex)), s)
        UpdateView
        Exit Sub
    End If
    db.Records(IndexOfRecord(db, lstRecords.List(lstRecords.ListIndex))).Fields(IndexOfField(db, lstRecords.List(lstRecords.ListIndex), lstFields.List(lstFields.ListIndex))).Name = s
    UpdateView False, True
    lstFields.ListIndex = IndexOfField(db, IndexOfRecord(db, lstRecords.List(lstRecords.ListIndex)), s)
    UpdateView
End Sub

Private Sub mnuFileNew_Click()
    If PromptSave() Then
        sCurFile = ""
        Erase db.Records
        Caption = "Untitled - DBEditor"
        bChanged = False
        lstRecords.Clear
        lstRecords.ListIndex = -1
        UpdateView True, True
    End If
End Sub

Private Sub mnuFileOpen_Click()
    If PromptSave() Then
        Open_
    End If
End Sub

Private Sub mnuFileSave_Click()
    If sCurFile = "" Then
        If Not SaveAs Then Exit Sub
    Else
        SaveFile sCurFile
    End If
    bChanged = False
End Sub

Private Sub mnuFileSaveAs_Click()
    If SaveAs Then bChanged = False
End Sub

Private Sub mnuRecordDelete_Click()
    If lstRecords.ListIndex < 0 Then Exit Sub
    DeleteField db, lstRecords.List(lstRecords.ListIndex), ""
    UpdateView True, True
End Sub

Private Sub mnuRecordNew_Click()
    Dim s As String
    s = InputBox("Enter the name of the new record:", Caption, "")
    If s = "" Then Exit Sub
    If IndexOfRecord(s) >= 0 Then
        MsgBox "A record with that name already exists...", vbExclamation, Caption
        lstRecords.ListIndex = IndexOfRecord(db, s)
        UpdateView False, True
        Exit Sub
    End If
    AddRecordToDB db, s
    UpdateView True, True
    lstRecords.ListIndex = IndexOfRecord(db, s)
    UpdateView
End Sub

Private Sub mnuRecordRename_Click()
    Dim s As String
    s = InputBox("Enter the name of the new record:", Caption, "")
    If s = "" Then Exit Sub
    If IndexOfRecord(s) >= 0 Then
        MsgBox "A record with that name already exists...", vbExclamation, Caption
        lstRecords.ListIndex = IndexOfRecord(s)
        UpdateView False, True
        Exit Sub
    End If
    db.Records(IndexOfRecord(db, lstRecords.List(lstRecords.ListIndex))).Name = s
    UpdateView True, True
    lstRecords.ListIndex = lstRecords_IndexOf(s)
    UpdateView
End Sub

Private Function lstRecords_IndexOf(ByVal RecordName As String)
    Dim idx As Long
    For idx = 0 To lstRecords.ListCount - 1
        If lstRecords.List(idx) = RecordName Then
            lstRecords_IndexOf = idx
            Exit Function
        End If
    Next idx
    lstRecords_IndexOf = -1
End Function

Private Function lstFields_IndexOf(ByVal RecordName As String)
    Dim idx As Long
    For idx = 0 To lstFields.ListCount - 1
        If lstFields.List(idx) = RecordName Then
            lstFields_IndexOf = idx
            Exit Function
        End If
    Next idx
    lstFields_IndexOf = -1
End Function
