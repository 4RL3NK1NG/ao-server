Attribute VB_Name = "mLimpieza"
'Creado por shak

Option Explicit

Const MAXITEMS                  As Integer = 1500

Dim ItemsLimpieza As New Collection

'//Desde aca establecemos el ultimo slot que se uso
Public UltimoSlotLimpieza       As Integer

Public Sub AgregarObjetoLimpieza(Pos As WorldPos)
    Dim newPos As New cWorldPos
    
    newPos.X = Pos.X
    newPos.Y = Pos.Y
    
    Call ItemsLimpieza.Add(newPos)
    
    If ItemsLimpieza.Count > MAXITEMS Then
        tickLimpieza = 16
    End If

End Sub

Public Sub BorrarObjetosLimpieza()
    Dim i As Long

    For i = 1 To ItemsLimpieza.Count

        With ItemsLimpieza.Item(i)

            If (MapData(.Map, .X, .Y).trigger <> eTrigger.CASA Or _
                MapData(.Map, .X, .Y).trigger <> eTrigger.BAJOTECHO) And _
                MapData(.Map, .X, .Y).Blocked <> 1 Then
                
                Call EraseObj(MapData(.Map, .X, .Y).ObjInfo.Amount, .Map, .X, .Y)
            End If

        End With

    Next i

    Set ItemsLimpieza = Nothing
    Set ItemsLimpieza = New Collection

End Sub
