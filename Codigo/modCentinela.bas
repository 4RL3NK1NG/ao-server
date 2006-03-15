Attribute VB_Name = "modCentinela"
'*****************************************************************
'modCentinela.bas - ImperiumAO - v1.2
'
'Funci�nes de control para usuarios que se encuentran trabajando
'
'*****************************************************************
'Respective portions copyrighted by contributors listed below.
'
'This library is free software; you can redistribute it and/or
'modify it under the terms of the GNU Lesser General Public
'License as published by the Free Software Foundation version 2.1 of
'the License
'
'This library is distributed in the hope that it will be useful,
'but WITHOUT ANY WARRANTY; without even the implied warranty of
'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
'Lesser General Public License for more details.
'
'You should have received a copy of the GNU Lesser General Public
'License along with this library; if not, write to the Free Software
'Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

'*****************************************************************
'Augusto Rando(barrin@imperiumao.com.ar)
'   - First Relase
'*****************************************************************

Option Explicit

Public Const NPC_CENTINELA_TIERRA As Integer = 158  '�ndice del NPC en el .dat
Public Const NPC_CENTINELA_AGUA As Integer = 159    '�dem anterior, pero en mapas de agua

Public CentinelaCharIndex As Integer                '�ndice del NPC en el servidor

Private Const TIEMPO_INICIAL As Byte = 2 'Tiempo inicial en minutos. No reducir sin antes revisar el timer que maneja estos datos.

Private Type tCentinela
    RevisandoUserIndex As Integer   '�Qu� �ndice revisamos?
    TiempoRestante As Integer       '�Cu�ntos minutos le quedan al usuario?
    Clave As Integer                'Clave que debe escribir
End Type

Public Centinela As tCentinela

Public Sub GoToNextWorkingChar()
'############################################################
'Va al siguiente usuario que se encuentre trabajando
'############################################################
    Dim LoopC As Long
    
    For LoopC = 1 To LastUser
        If (UserList(LoopC).name <> "") And UserList(LoopC).Counters.Trabajando > 0 Then
            If Not UserList(LoopC).flags.CentinelaOK Then
                Call WarpCentinela(LoopC)
                Exit Sub
            End If
        End If
    Next LoopC
End Sub

Private Sub CentinelaFinalCheck()
'############################################################
'Al finalizar el tiempo, se retira y realiza la acci�n
'pertinente dependiendo del caso
'############################################################
On Error GoTo Error_Handler
    Dim name As String
    Dim numPenas As Integer
    
    If Not UserList(Centinela.RevisandoUserIndex).flags.CentinelaOK Then
        Call LogBan(UserList(Centinela.RevisandoUserIndex).name, "Centinela", "Uso de macro inasistido")
        UserList(Centinela.RevisandoUserIndex).flags.Ban = 1
        
        name = UserList(Centinela.RevisandoUserIndex).name
        
        'Avisamos a los admins
        Call SendData(SendTarget.ToAdmins, 0, 0, "||Servidor> El centinela ha baneado a " & name & FONTTYPE_SERVER)
        
        'ponemos el flag de ban a 1
        Call WriteVar(CharPath & name & ".chr", "FLAGS", "Ban", "1")
        'ponemos la pena
        numPenas = val(GetVar(CharPath & name & ".chr", "PENAS", "Cant"))
        Call WriteVar(CharPath & name & ".chr", "PENAS", "Cant", numPenas + 1)
        Call WriteVar(CharPath & name & ".chr", "PENAS", "P" & numPenas + 1, LCase$(name) & ": BAN POR MACRO INASISTIDO " & Date & " " & Time)
        
        Call CloseSocket(Centinela.RevisandoUserIndex)
    End If
    
    Centinela.Clave = 0
    Centinela.TiempoRestante = 0
    Centinela.RevisandoUserIndex = 0
    Call QuitarNPC(CentinelaCharIndex)
Exit Sub

Error_Handler:
    Centinela.Clave = 0
    Centinela.TiempoRestante = 0
    Centinela.RevisandoUserIndex = 0
    Call QuitarNPC(CentinelaCharIndex)
    Call LogError("Error en el checkeo del centinela: " & Err.Description)
End Sub

Public Sub CentinelaCheckClave(ByVal Clave As Integer)
'############################################################
'Corrobora la clave que le envia el usuario
'############################################################
    If Clave = Centinela.Clave Then
        UserList(Centinela.RevisandoUserIndex).flags.CentinelaOK = True
        Call SendData(SendTarget.ToIndex, Centinela.RevisandoUserIndex, 0, "||" & vbWhite & "�" & "�Muchas gracias " & UserList(Centinela.RevisandoUserIndex).name & "! Espero no haber sido una molestia" & "�" & CStr(Npclist(CentinelaCharIndex).Char.CharIndex))
    Else
        Call SendData(SendTarget.ToIndex, Centinela.RevisandoUserIndex, 0, "||" & vbWhite & "�" & "�La clave que te he dicho no es esa, " & "escr�be /CENTINELA " & Centinela.Clave & " r�pido!" & "�" & CStr(Npclist(CentinelaCharIndex).Char.CharIndex))
    End If
End Sub

Public Sub ResetCentinelaInfo()
'############################################################
'Cada determinada cantidad de tiempo, volvemos a revisar
'############################################################
    Dim LoopC As Long
    
    For LoopC = 1 To LastUser
        If (UserList(LoopC).name <> "" And LoopC <> Centinela.RevisandoUserIndex) Then
            UserList(LoopC).flags.CentinelaOK = False
        End If
    Next LoopC
End Sub

Public Sub CentinelaSendClave(ByVal UserIndex As Integer)
'############################################################
'Enviamos al usuario la clave v�a el personaje centinela
'############################################################
    If UserIndex = Centinela.RevisandoUserIndex Then
        If Not UserList(UserIndex).flags.CentinelaOK Then
            Call SendData(SendTarget.ToIndex, UserIndex, 0, "||" & vbWhite & "�" & "�La clave que te he dicho es " & "/CENTINELA " & Centinela.Clave & " escr�belo r�pido!" & "�" & CStr(Npclist(CentinelaCharIndex).Char.CharIndex))
        Else
            Call SendData(SendTarget.ToIndex, UserIndex, 0, "||" & vbWhite & "�" & "Te agradezco, pero ya me has respondido. Me retirar� pronto." & "�" & CStr(Npclist(CentinelaCharIndex).Char.CharIndex))
        End If
    Else
        Call SendData(SendTarget.ToIndex, UserIndex, 0, "||" & vbWhite & "�" & "No es a ti a quien estoy revisando, �no ves?" & "�" & CStr(Npclist(CentinelaCharIndex).Char.CharIndex))
    End If
End Sub

Public Sub PasarMinutoCentinela()
'############################################################
'Control del timer. Llamado cada un minuto.
'############################################################
    If Centinela.RevisandoUserIndex = 0 Then
        Call GoToNextWorkingChar
    Else
        Centinela.TiempoRestante = Centinela.TiempoRestante - 1
        
        If Centinela.TiempoRestante = 0 Then
            Call CentinelaFinalCheck
            Call GoToNextWorkingChar
        Else
            'Recordamos al user que debe escribir
            Call SendData(SendTarget.ToIndex, Centinela.RevisandoUserIndex, 0, "||" & vbRed & "��" & UserList(Centinela.RevisandoUserIndex).name & ", tienes un minuto m�s para responder! Debes escribir /CENTINELA " & Centinela.Clave & "." & "�" & CStr(Npclist(CentinelaCharIndex).Char.CharIndex))
        End If
    End If
End Sub

Private Sub WarpCentinela(ByVal UserIndex As Integer)
'############################################################
'Inciamos la revisi�n del usuario UserIndex
'############################################################
    Centinela.RevisandoUserIndex = UserIndex
    Centinela.TiempoRestante = TIEMPO_INICIAL
    Centinela.Clave = RandomNumber(1, 36000)
    
    If HayAgua(UserList(UserIndex).Pos.Map, UserList(UserIndex).Pos.X, UserList(UserIndex).Pos.Y) Then
        CentinelaCharIndex = SpawnNpc(NPC_CENTINELA_AGUA, UserList(UserIndex).Pos, True, False)
    Else
        CentinelaCharIndex = SpawnNpc(NPC_CENTINELA_TIERRA, UserList(UserIndex).Pos, True, False)
    End If
    
    Call SendData(SendTarget.ToIndex, UserIndex, 0, "||" & vbWhite & "�" & "Saludos " & UserList(UserIndex).name & ", soy el Centinela de estas tierras. Me gustar�a que escribas /CENTINELA " & Centinela.Clave & " en no m�s de dos minutos." & "�" & CStr(Npclist(CentinelaCharIndex).Char.CharIndex))
End Sub

Public Sub CentinelaUserLogout()
'############################################################
'El usuario al que revisabamos se desconect�
'############################################################
    'Reseteamos y esperamos a otro PasarMinuto para ir al siguiente user
    Centinela.Clave = 0
    Centinela.TiempoRestante = 0
    Centinela.RevisandoUserIndex = 0
    Call QuitarNPC(CentinelaCharIndex)
End Sub
