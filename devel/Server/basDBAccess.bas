Attribute VB_Name = "basDBAccess"
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

'Change this to True if you want to require explicit
'creation of records or fields.
#Const RequireCreate = True

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

Public Function AddRecordToDB(ByRef dbInOut As Database, ByVal RecordName As String) As Long
    With dbInOut
        If CountRecords(dbInOut) = 0 Then
            ReDim .Records(0)
        Else
            ReDim Preserve .Records(UBound(.Records) + 1)
        End If
        .Records(UBound(.Records)).Name = RecordName
        AddRecordToDB = UBound(.Records)
    End With
End Function

Public Function AddFieldToRecord(ByRef dbInOut As Database, ByVal RecordName As String, ByVal FieldName As String, Optional ByVal InitialValue As Variant = Empty) As Long
    Dim i As Integer
    With dbInOut
        For i = 0 To UBound(.Records)
            If .Records(i).Name = RecordName Then
                With .Records(i)
                    If CountFields(dbInOut, i) = 0 Then
                        ReDim .Fields(0)
                    Else
                        ReDim Preserve .Fields(UBound(.Fields) + 1)
                    End If
                    .Fields(UBound(.Fields)).Name = FieldName
                    If IsObject(InitialValue) Then
                        Set .Fields(UBound(.Fields)).Value = InitialValue
                    Else
                        Let .Fields(UBound(.Fields)).Value = InitialValue
                    End If
                    AddFieldToRecord = UBound(.Fields)
                End With
                'We found the record, so don't loop out,
                'just break.
                Exit Function
            End If
        Next i
        Err.Raise 9, "Record '" + RecordName + "' couldn't be found."
    End With
End Function

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
        Err.Raise 9, , "No such record '" + RecordName + "'."
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
                    'No such field, so create it/error.
#If RequireCreate Then
                    Err.Raise 9, , "Field '" + FieldName + "' is not defined in Record '" + RecordName + "'."
#Else
                    AddFieldToRecord dbInOut, RecordName, FieldName, NewValue
#End If
                End With
            End If
        Next idx
        'No such record, so create it/error.
#If RequireCreate Then
        Err.Raise 9, , "No such record '" + RecordName + "'."
#Else
        AddRecordToDB dbInOut, RecordName
        AddFieldToRecord dbInOut, RecordName, FieldName, NewValue
#End If
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
                    'No such field, so create it/error.
#If RequireCreate Then
                    Err.Raise 9, , "Field '" + FieldName + "' is not defined in Record '" + RecordName + "'."
#Else
                    AddFieldToRecord dbInOut, RecordName, FieldName, NewValue
#End If
                End With
            End If
        Next idx
        'No such record, so create it.
#If RequireCreate Then
        Err.Raise 9, , "No such record '" + RecordName + "'."
#Else
        AddRecordToDB dbInOut, RecordName
        AddFieldToRecord dbInOut, RecordName, FieldName, NewValue
#End If
    End With
End Property

Public Sub DeleteField(ByRef dbInOut As Database, ByVal RecordName As String, ByVal FieldName As String)
    Dim idxLoc As Integer
    'Get ready for some fun...
    If RecordName = "" Then
        'Delete the entire database.
        Erase dbInOut.Records
    ElseIf FieldName = "" Then
        'Delete the entire record.
        Dim idx As Integer
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
                        ReDim Preserve .Fields(UBound(.Fields) - 1)
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

Public Function CountRecords(ByRef dbIn As Database) As Long
    On Error Resume Next
    Dim lRet As Long
    'If this errors, lRet should remain 0, and we can.
    lRet = UBound(dbIn.Records) + 1
    CountRecords = lRet
End Function

Public Function IndexOfRecord(ByRef dbIn As Database, ByVal Name As String) As Long
    Dim idx As Long
    For idx = 0 To CountRecords(dbIn) - 1
        If dbIn.Records(idx).Name = Name Then
            IndexOfRecord = idx
            Exit Function
        End If
    Next idx
    IndexOfRecord = -1
End Function

Public Function CountFields(ByRef dbIn As Database, ByVal RecordIndex As Long) As Long
    Dim lRet As Long
    If RecordIndex < 0 Then Error 5
    On Error Resume Next
    lRet = UBound(dbIn.Records(RecordIndex).Fields) + 1
    CountFields = lRet
End Function

Public Function IndexOfField(ByRef dbIn As Database, ByVal RecordIndex As Long, ByVal FieldName As String) As Long
    Dim idx As Long
    If RecordIndex < 0 Then Error 5
    For idx = 0 To CountFields(dbIn, RecordIndex) - 1
        If dbIn.Records(RecordIndex).Fields(idx).Name = FieldName Then
            IndexOfField = idx
            Exit Function
        End If
    Next idx
    IndexOfField = -1
End Function
