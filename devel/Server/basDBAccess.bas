Attribute VB_Name = "basDBAccess"
Option Explicit

'Okay, I'm redoing this whole data access thing... I
'hope it will make this easier to move to MySQL later
'on :) .

Public Type Field
    Name As String
    Value As Variant
End Type

Public Type Record
    Name As String
    Fields() As Field
End Type

Public Type Database
    Records() As Record
End Type

Public Sub LoadDatabase(ByVal dbName As String, ByRef dbOut As Database)
    Dim vSections As Variant, vKeys As Variant
    vSections = ScanINISections(dbName)
    ReDim dbOut.Records(UBound(vSections))
    Dim idx As Long
    For idx = 0 To UBound(vSections)
        With dbOut.Records(idx)
            .Name = vSections(idx)
            vKeys = ScanINISectionKeys(dbName, vSections(idx))
            ReDim .Fields(UBound(vKeys))
            Dim idx2 As Long
            For idx2 = 0 To UBound(vKeys)
                With .Fields(idx2)
                    .Name = vKeys(idx2)
                    .Value = GetInitEntry(dbName, vSections(idx), vKeys(idx2))
                End With
            Next idx2
        End With
    Next idx
End Sub

'Merge makes us keep any fields/records that aren't in
'the stuff to save :P .
Public Sub SaveDatabase(ByVal dbFile As String, ByRef dbIn As Database, Optional ByVal Merge As Boolean = False)
    If Not Merge Then
        DeleteInitEntry dbFile, "", ""
    End If
    Dim idx As Long, idx2 As Long
    Dim sSection As String
    With dbIn
        For idx = 0 To UBound(.Records)
            With .Records(idx)
                sSection = .Name
                For idx2 = 0 To UBound(.Fields)
                    With .Fields(idx2)
                        SetInitEntry dbFile, sSection, .Name, .Value
                    End With
                Next idx2
            End With
        Next idx
    End With
End Sub

Public Sub AddRecordToDB(ByRef dbInOut As Database, ByVal RecordName As String)
    With dbInOut
        ReDim Preserve .Records(UBound(.Records) + 1)
        .Records(UBound(.Records)).Name = RecordName
    End With
End Sub

Public Sub AddFieldToRecord(ByRef dbInOut As Database, ByVal RecordName As String, ByVal FieldName As String, Optional ByVal InitialValue As Variant = Empty)
    Dim i As Integer
    With dbInOut
        For i = 0 To UBound(.Records)
            If .Records(i).Name = RecordName Then
                With .Records(i)
                    ReDim Preserve .Fields(UBound(.Fields) + 1)
                    .Fields(UBound(.Fields)).Name = FieldName
                    .Fields(UBound(.Fields)).Value = InitialValue
                End With
            End If
        Next i
    End With
End Sub

Public Property Get RecordField(ByRef dbInOut As Database, ByVal RecordName As String, ByVal FieldName As String) As Variant
    With dbInOut
        Dim idx As Integer
        For idx = 0 To UBound(.Records)
            If .Records(idx).Name = RecordName Then
                With .Records(idx)
                    Dim idx2 As Integer
                    For idx2 = 0 To UBound(.Fields)
                        If .Fields(idx).Name = FieldName Then
                            With .Fields(idx)
                                If IsObject(.Value) Then
                                    Set RecordField = .Value
                                Else
                                    RecordField = .Value
                                End If
                                'We're ok, so get away from the Err.Raise thingies.
                                Exit Property
                            End With
                        End If
                    Next idx2
                    'No go.
                    Err.Raise 9, , "Field '" + FieldName + "' is not defined in Record '" + RecordName + "'."
                End With
            End If
        Next idx
        'No go.
        Err.Raise 9, , "No such section '" + RecordName + "'."
    End With
End Property

Public Property Let RecordField(ByRef dbInOut As Database, ByVal RecordName As String, ByVal FieldName As String, ByVal NewValue As Variant)
    With dbInOut
        Dim idx As Integer
        For idx = 0 To UBound(.Records)
            If .Records(idx).Name = RecordName Then
                With .Records(idx)
                    Dim idx2 As Integer
                    For idx2 = 0 To UBound(.Fields)
                        If .Fields(idx).Name = FieldName Then
                            'It was found!
                            With .Fields(idx)
                                .Value = NewValue
                            End With
                            Exit Property
                        End If
                    Next idx2
                    'No such field, so create it.
                    ReDim Preserve .Fields(UBound(.Fields) + 1)
                    With .Fields(UBound(.Fields))
                        .Name = FieldName
                        .Value = NewValue
                    End With
                    Exit Property
                End With
            End If
        Next idx
        'No such record, so create it.
        ReDim Preserve .Records(UBound(.Records) + 1)
        With .Records(UBound(.Records))
            .Name = RecordName
            ReDim .Fields(0)
            With .Fields(0)
                .Name = FieldName
                .Value = NewValue
            End With
        End With
    End With
End Property

Public Property Set RecordField(ByRef dbInOut As Database, ByVal RecordName As String, ByVal FieldName As String, ByVal NewValue As Variant)
    With dbInOut
        Dim idx As Integer
        For idx = 0 To UBound(.Records)
            If .Records(idx).Name = RecordName Then
                With .Records(idx)
                    Dim idx2 As Integer
                    For idx2 = 0 To UBound(.Fields)
                        If .Fields(idx).Name = FieldName Then
                            'It was found!
                            With .Fields(idx)
                                Set .Value = NewValue
                            End With
                            Exit Property
                        End If
                    Next idx2
                    'No such field, so create it.
                    ReDim Preserve .Fields(UBound(.Fields) + 1)
                    With .Fields(UBound(.Fields))
                        .Name = FieldName
                        Set .Value = NewValue
                    End With
                    Exit Property
                End With
            End If
        Next idx
        'No such record, so create it.
        ReDim Preserve .Records(UBound(.Records) + 1)
        With .Records(UBound(.Records))
            .Name = RecordName
            ReDim .Fields(0)
            With .Fields(0)
                .Name = FieldName
                Set .Value = NewValue
            End With
        End With
    End With
End Property

Public Sub DeleteField(ByRef dbInOut As Database, ByVal RecordName As String, ByVal FieldName As String)
    'Get ready for some fun...
    If RecordName = "" Then
        'Delete the entire database.
        Erase dbInOut.Records
    ElseIf FieldName = "" Then
        'Delete the entire record.
        Dim idx As Integer, idxLoc As Integer
        idxLoc = -1
        With dbInOut
            For idx = 0 To UBound(.Records)
                If .Records(idx).Name = RecordName Then
                    idxLoc = idx
                    Exit For
                End If
            Next idx
            If idxLoc = -1 Then Err.Raise 9, , "The record '" + RecordName + "' was not found."
            For idx = idxLoc + 1 To UBound(.Records)
                'Copy everything down one index to
                'overwrite the deleted entry.
                .Records(idx - 1) = .Records(idx)
            Next
            ReDim Preserve .Records(UBound(.Records) - 1)
        End With
    Else
        'Delete a single field in a record.
        Dim idxRec As Integer, idxFld As Integer
        Dim idxLoc As Integer
        idxLoc = -1
        With dbInOut
            For idxRec = 0 To UBound(.Records)
                If .Records(idxRec).Name = RecordName Then
                    With .Records(idxRec)
                        For idxFld = 0 To UBound(.Fields)
                            If .Fields(idxFld).Name = FieldName Then
                                idxLoc = idxFld
                                Exit For
                            End If
                        Next idxFld
                        If idxLoc = -1 Then Err.Raise 9, , "Field '" + FieldName + "' was not found in Record '" + RecordName + "'."
                        For idxFld = idxLoc + 1 To UBound(.Fields)
                            .Fields(idxFld - 1) = .Fields(idxFld)
                        Next idxFld
                        ReDim Preserve Fields(UBound(.Fields) - 1)
                    End With
                    Exit Sub
                End If
            Next idxRec
            'No go.
            Err.Raise 9, , "No such record '" + RecordName + "'."
        End With
    End If
    'PHEW! :>
End Sub
