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

'Here we go again... :|

Public Function OpenDB(ByVal ConnectString As String) As Connection
    Dim conn As Connection
    Set conn = New Connection
    conn.Open ConnectString
    Set OpenDB = conn
End Function

Public Function GetTable(ByVal conn As Connection, ByVal table As String) As Recordset
    Dim rs As Recordset
    Set rs = New Recordset
    rs.Open table, conn, adOpenDynamic, adLockPessimistic, CommandTypeEnum.adCmdTableDirect
    Set GetTable = rs
End Function

Public Function ReadTableIntoCollection(ByVal Connection As Variant, ByVal table As Variant) As Collection
    'Connection: either a connect string, or a Connection object.
    'table: either a table name or a RecordSet set object.
    'Return value: A Collection representing the records returned as keyed Collections.
    'In other words:
    'Collection
    '- Record 1 (Collection)
    '  - Field Name => Field Value
    '  - Field Name => Field Value
    '  - etc
    '- Record 2 (Collection) Same as the first
    Dim conn As Connection, rs As Recordset
    Dim bCloseConn As Boolean, bCloseTable As Boolean
    If IsObject(Connection) Then
        Set conn = Connection 'Let this do the validating :P
        If IsObject(table) Then
            Set rs = table
        ElseIf VarType(table) = vbString Then
            Set rs = GetTable(conn, table)
            bCloseTable = True
        Else
            Err.Raise 13
        End If
    ElseIf VarType(Connection) = vbString And VarType(table) = vbString Then
        Set conn = OpenDB(Connection)
        Set table = GetTable(conn, table)
        bCloseConn = True
        bCloseTable = True
    Else
        Err.Raise 13
    End If
    Dim col As Collection, col2 As Collection, idx As Long
    Set col = New Collection
    While Not rs.EOF
        Set col2 = New Collection
        For idx = 0 To rs.Fields.Count
            With rs.Fields(idx)
                col2.Add .Value, .Name
            End With
        Next idx
        col.Add col2, rs.Index
    Wend
    If bCloseTable Or bCloseConn Then rs.Close
    If bCloseConn Then conn.Close
    Set ReadTableIntoCollection = col
End Function
