Attribute VB_Name = "MD5"
Option Explicit

Private Declare Function CryptAcquireContextA Lib "advapi32" (ByRef hProv As Long, ByVal szContainer As String, ByVal szProvider As String, ByVal dwProvType As Long, ByVal dwFlags As Long) As Long
Private Const PROV_RSA_FULL As Long = 1
Private Const CRYPT_VERIFYCONTEXT As Long = &HF0000000
Private Const CRYPT_MACHINEKEYSET As Long = &H20

Private Declare Function CryptCreateHash Lib "advapi32" (ByVal hProv As Long, ByVal Algid As Long, ByVal hKey As Long, ByVal dwFlags As Long, ByRef phHash As Long) As Long
Private Const ALG_CLASS_HASH As Long = 4 * 2 ^ 13
Private Const ALG_TYPE_ANY As Long = 0
Private Const ALG_SID_MD5 As Long = 3
Private Const CALG_MD5 As Long = ALG_CLASS_HASH Or ALG_TYPE_ANY Or ALG_SID_MD5

Private Declare Function CryptHashData Lib "advapi32" (ByVal hHash As Long, ByRef pbData As Byte, ByVal dwDataLen As Long, ByVal dwFlags As Long) As Long

Private Declare Function CryptGetHashParam Lib "advapi32" (ByVal hHash As Long, ByVal dwParam As Long, ByRef pbData As Byte, ByRef pdwDataLen As Long, ByVal dwFlags As Long) As Long
Public Const HP_HASHVAL As Long = 2

Private Declare Function CryptDestroyHash Lib "advapi32" (ByVal hHash As Long) As Long
Private Declare Function CryptReleaseContext Lib "advapi32" (ByVal hProv As Long, ByVal dwFlags As Long) As Long

Private Function StrToBin(ByVal s As String) As Variant
    Dim bin() As Byte
    ReDim bin(0 To Len(s) - 1)
    Dim idx As Long
    For idx = 0 To Len(s) - 1
        bin(idx) = Asc(Mid(s, idx + 1, 1))
    Next idx
    StrToBin = bin
End Function

Public Function Digest(ByVal s As String) As String
    Dim hCryptProv As Long
    Dim hHash As Long
    Dim bHash(0 To &H7E) As Byte
    Dim dwHashLen As Long
    dwHashLen = 16
    Dim cbContent As Long
    cbContent = Len(s)
    Dim pbContent() As Byte
    pbContent = StrToBin(s)
    Dim csDigest As String
    On Error GoTo CleanUp
    If CryptAcquireContextA(hCryptProv, vbNullString, vbNullString, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT Or CRYPT_MACHINEKEYSET) Then
        If CryptCreateHash(hCryptProv, CALG_MD5, 0, 0, hHash) Then
            If CryptHashData(hHash, pbContent(0), cbContent, 0) Then
                If CryptGetHashParam(hHash, HP_HASHVAL, bHash(0), dwHashLen, 0) Then
                    Dim i As Long, sTmp As String
                    csDigest = ""
                    For i = 0 To 15
                        sTmp = IIf(Len(Hex(bHash(i))) < 2, "0" & Hex(bHash(i)), Hex(bHash(i)))
                        csDigest = csDigest & sTmp
                    Next i
                Else
                    Err.Raise 51, , "Error getting hash parameter: " + Err.LastDllError
                End If
            Else
                Err.Raise 51, , "Error hashing data: " + Err.LastDllError
            End If
        Else
            Err.Raise 51, , "Error creating hash: " + Err.LastDllError
        End If
    Else
        Err.Raise 51, , "Error acquiring context: " + Err.LastDllError
    End If
CleanUp:
    Call CryptDestroyHash(hHash)
    Call CryptReleaseContext(hCryptProv, 0)
    If Err.Number <> 0 Then
        Err.Raise Err.Number, Err.Source, Err.Description, Err.HelpFile, Err.HelpContext
    Else
        Digest = csDigest
    End If
End Function
