; Faster Universal Unpacker v1.0
;
; Copyright (C) 2010 +NCR/CRC! [ReVeRsEr] http://crackinglandia.blogspot.com
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
; FUU - Faster Universal Unpacker
; 
; Author: +NCR/CRC! [ReVeRsEr]
; Date: Wednesday, March 24 th 2010
;
; Every plugin will export these functions:
;
; GetPluginName - returns the plugin's name
; DoUnpack - this routine does the magic to unpack :P
;
; DoUnpack will receive the path and filename, the
; main dlg handle, an ID (FUU1) and lParam.
;
;
; Thanks to all the people in CracksLatinoS!
; for helping me answering my questions!
; 
; Special thanks to GUAN DE DIO and marciano
;

.386
.model flat,stdcall
option casemap:none

include fuu.inc

.code

start:

	invoke GetModuleHandle,NULL
	mov    hInstance,eax
	invoke GetCommandLine
	invoke InitCommonControls
	mov		CommandLine,eax
	invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	invoke ExitProcess,eax

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL	wc:WNDCLASSEX
	LOCAL	msg:MSG

	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset WndProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,DLGWINDOWEXTRA
	push	hInst
	pop		wc.hInstance
	mov		wc.hbrBackground,COLOR_BTNFACE+1
	mov		wc.lpszMenuName,IDM_MENU
	mov		wc.lpszClassName,offset ClassName
	
	;invoke LoadIcon,NULL,IDI_APPLICATION
	invoke LoadIcon, hInstance, 500
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	
	invoke RegisterClassEx,addr wc
	invoke CreateDialogParam,hInstance,IDD_DIALOG,NULL,addr WndProc,NULL
	invoke ShowWindow,hWnd,SW_SHOWNORMAL
	invoke UpdateWindow,hWnd
	.while TRUE
		invoke GetMessage,addr msg,NULL,0,0
	  .BREAK .if !eax
		invoke TranslateMessage,addr msg
		invoke DispatchMessage,addr msg
	.endw
	mov		eax,msg.wParam
	ret

WinMain endp

WndProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
LOCAL 	buffer[256]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		push	hWin
		pop		hWnd
		
		invoke GetDlgItem, hWin, PluginComboBox
		mov hCombo,eax
		
		invoke GetDlgItem, hWin, OutputListBox
		mov hListBox, eax
		
		invoke CheckDlgButton, hWin, RealignPECheckBox, BST_CHECKED
		
		;invoke LoadLibrary, chr$("C:\Program Files\RadASM\Masm\Projects\fuu\TitanEngine.dll")
		
		invoke LoadPlugins, hWin, uMsg, wParam, lParam
		
	.elseif eax==WM_COMMAND
		mov		eax,wParam
		mov		edx,eax
		shr		edx,16
		and		eax,0FFFFh
		
		.if edx == BN_CLICKED
			.if eax==IDM_FILE_EXIT
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.elseif eax==IDM_HELP_ABOUT
				invoke ShellAbout,hWin,addr AppName,addr AboutMsg,NULL
			.elseif eax == IDM_TOOLS_CRYPTSIGN
				invoke DetectCryptoSignatures, hWin, addr GlobalBuffer, addr CryptoSignDllName
			.elseif eax == IDM_TOOLS_DETECTOEP
				invoke DetectOEP, hWin, addr GlobalBuffer, addr GenOEPDllName
			.elseif eax == IDM_GENUNPACK
				invoke GenericUnpacker, hWin, addr GlobalBuffer, addr GenUnpackerDllName
			.elseif eax == ExitBtn
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.elseif eax == AboutBtn
				invoke MessageBox,hWin,offset msgText, offset msgTitle, MB_OK
			.elseif eax == RefreshBtn
				invoke RefreshComboBox
			.elseif eax == UnpackBtn
				invoke SendMessage, hListBox, LB_RESETCONTENT, NULL, NULL
				
				invoke IsDlgButtonChecked, hWin, RealignPECheckBox
				.if eax == TRUE
					mov RealignPEFlag, 1
				.endif 
				
				mov eax, current_selection
				invoke GetStructPtr,addr pInfo, eax
				.if current_selection != CB_ERR
					invoke InitializeUnpacker, hWin, addr GlobalBuffer, current_selection
				.else
					invoke MessageBox, hWin, offset SelectPluginError, offset ErrorMsgTitle, MB_ICONERROR
				.endif
				;invoke MessageBox, hWin, addr [esi].DllName, addr [esi].PluginName, MB_OK
			.elseif eax == BrowseFileBtn
				invoke GetFileDialog
				invoke SetDlgItemText, hWin, FileNameEdit, addr GlobalBuffer
			.endif
		.elseif edx == CBN_SELCHANGE
			.if eax == PluginComboBox
				invoke SendMessage, hCombo, CB_GETCURSEL, 0, 0
				.if eax == CB_ERR 
					jmp NoSelection
				.endif
				mov current_selection, eax
				;mov ebx, eax
				;lea esi, pInfo
				;xor edx, edx
				;mov eax, sizeof PluginInfo
				;imul ebx
				;add esi, eax
				;invoke GetStructPtr, eax
				;assume esi: ptr PluginInfo
				;	invoke MessageBox, hWin, addr [esi].DllName, addr [esi].PluginName, MB_OK
				;assume esi:nothing
				;invoke  SendMessage, hCombo, CB_GETLBTEXT, eax, addr buffer 
			.endif
		NoSelection:
			; no item selected
		.endif
;	.elseif eax==WM_SIZE
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hWin
	.elseif uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

WndProc endp

GetFileDialog proc

	pushad
	mov ofn.lStructSize,sizeof ofn
	mov ofn.lpstrFilter,offset FilterString
	mov ofn.lpstrFile,offset GlobalBuffer
	mov ofn.nMaxFile,1024
	mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
	mov ofn.lpstrTitle,offset AppName
	invoke GetOpenFileName,addr ofn
	.if eax != 0
		mov IsFileSelected, 1
	.endif
	popad
	ret

GetFileDialog endp

;GetStructPtr proc Index:DWORD
;	
;	mov ebx, Index
;	lea esi, pInfo
;	xor edx, edx
;	mov eax, sizeof PluginInfo
;	imul ebx
;	add esi, eax
;	ret
;	
;GetStructPtr endp

GetStructPtr proc lpStruct:DWORD, Index:DWORD

	mov esi, dword ptr[lpStruct]
	mov ebx, Index
	xor edx, edx
	mov eax, sizeof PluginInfo
	imul ebx
	add esi, eax
	ret

GetStructPtr endp

InitializeUnpacker proc hWin:HWND,FileName:DWORD,CurrentSelection:DWORD

	.if IsFileSelected == 1
		mov eax, CurrentSelection
		invoke GetStructPtr, addr pInfo, eax
		assume esi: ptr PluginInfo
			push offset RealignPEFlag
			push offset FUUID
			push FileName
			push hWin
			call [esi].DoUnpackAddr
		assume esi:nothing
	.else
		invoke MessageBox, hWin, offset SelectionFileErrorMsg, offset ErrorMsg, MB_ICONERROR
	.endif
	ret

InitializeUnpacker endp

RefreshComboBox proc
	LOCAL FindData:WIN32_FIND_DATA
	LOCAL Counter:DWORD

	; 
	; L1 = List();
	; L2 = List();
	; L3 = List()
	; Top = Int();
	; Counter = Int()
	; 
	; PopulateList(L1);
	; PopulateList(L2);
	;
	; Top = len(L1)
	; 
	; item = GetElementFromList(L1);
	; while Counter < Top 
	; 	InList = IsElementInList(L2, item);
	; 	if not InList
	; 		AddElementToList(L3)
	; 	GetNextElementInList(L1)
	; 	inc Counter
	; 
	
	pushad
	mov Counter, 0
	
	invoke PopulateList, addr AuxList
	; assuming AuxList is always > pInfo
	invoke GetNumberOfItems, addr AuxList
	mov ecx, eax
	
	invoke GetElementFromList, addr AuxList, Counter
	
	.while Counter < ecx
		mov _lpItem, eax
		invoke IsElementInList, addr pInfo, eax
		.if eax == 0
			invoke AddElementToList, addr pInfo, _lpItem
		.endif
		inc Counter
		invoke GetElementFromList, addr AuxList, Counter
	.endw 
	popad
	ret
	
RefreshComboBox endp

AddElementToList proc lpList:DWORD, lpItem:DWORD
	LOCAL ListLength:DWORD
	
	pushad
	mov GetPluginNameAddrs, 0
	mov DoUnpackAddrs, 0
	
	invoke GetNumberOfItems, lpList
	mov ListLength, eax
	
	invoke LoadLibrary, lpItem
	mov hModule, eax
	.if eax != NULL
		invoke GetProcAddress,eax, offset DoUnpackName
		.if eax != NULL
			mov DoUnpackAddrs, eax
			invoke GetProcAddress, hModule, offset GetPluginName
			.if eax != NULL
				mov GetPluginNameAddrs, eax
				
				invoke GetStructPtr, lpList, ListLength
				
				assume esi: ptr PluginInfo
					mov ebx, ListLength
					mov [esi].Index, ebx 
					mov ebx, DoUnpackAddrs
					mov [esi].DoUnpackAddr, ebx
					mov ebx, GetPluginNameAddrs
					mov [esi].GetPlugNameAddr, ebx
					
					invoke lstrlen, lpItem
					inc eax
					.if eax < MAX_PATH
						invoke lstrcpyn, addr [esi].DllName, lpItem, eax
					
						call GetPluginNameAddrs
						mov ebx, eax
						invoke lstrlen,eax
						inc eax
						.if eax < MAX_PATH
							invoke lstrcpyn,addr [esi].PluginName, ebx, eax
							
							invoke SendMessage, hCombo, CB_ADDSTRING, 0, ebx								
						.endif
					.endif
				assume esi: nothing
				
			.endif
		.endif
	.endif
	popad
	ret
	
AddElementToList endp

IsElementInList proc lpList:DWORD, lpItem:DWORD
	LOCAL Counter:DWORD
	LOCAL Found:DWORD
	LOCAL AuxCounter:DWORD
	
	pushad
	mov Counter, 0
	mov Found, FALSE
	mov AuxCounter, 0
	
	invoke GetNumberOfItems, lpList
	mov ecx, eax
	
	.while Counter < ecx
		mov AuxCounter, ecx
		;mov esi, dword ptr[esi]
		invoke GetStructPtr, lpList, Counter
		
		assume esi: ptr PluginInfo
			lea eax, [esi].DllName
		assume esi: nothing
		
		invoke lstrcmp, eax, lpItem
		.if eax == 0
			mov Found, TRUE
		.else
			invoke GetElementFromList, lpList, Counter
		.endif
		
		mov ecx, AuxCounter
		inc Counter
	.endw
	popad
	mov eax, Found
	ret

IsElementInList endp

GetElementFromList proc lpList:DWORD, Index:DWORD
	LOCAL lpItem:DWORD
	
	pushad
	mov esi, dword ptr[lpList]
	invoke GetStructPtr, lpList, Index
	
	assume esi: ptr PluginInfo
		lea eax, [esi].DllName
		mov lpItem, eax
	assume esi: nothing
	popad
	mov eax, lpItem
	ret

GetElementFromList endp

GetNumberOfItems proc lpList
	LOCAL Counter:DWORD
	
	pushad
	mov Counter, 0
	xor eax, eax
	inc eax
	
	.while eax > 0
		invoke GetStructPtr, lpList, Counter
		assume esi: ptr PluginInfo
			lea eax, [esi].DllName
			invoke lstrlen, eax
		assume esi: nothing
		inc Counter
	.endw
	popad
	mov eax, Counter
	; XXX: HACK! don't do this at home!
	; this is because we have an extra dll (TitanEngine.dll)
	; and TitanEngine.dll is not loaded as a plugin in the IDE
	sub eax, 1
	ret

GetNumberOfItems endp

PopulateList proc lpList:DWORD
	LOCAL findData:WIN32_FIND_DATA
	LOCAL Counter:DWORD
	LOCAL StructCounter:DWORD
	
	pushad
	invoke GetModuleFileName, hInstance, addr CurrentDir, MAX_PATH

	mov esi, offset CurrentDir
	invoke lstrlen, esi
	add esi, eax
	.while byte ptr[esi] != "\"
		mov byte ptr [esi], 0
		dec esi
		dec eax
	.endw
	
	sub esi, eax
	
	invoke lstrlen, esi
	
	mov Counter, 0
	
	.if eax < MAX_PATH
		invoke lstrcat, esi, addr Pluginsx86DirName
		invoke SetCurrentDirectory, esi  
	
		invoke FindFirstFile,addr fPattern, addr findData
		.if eax != INVALID_HANDLE_VALUE
			mov fHandle, eax
			.while eax !=0
				invoke GetStructPtr, lpList, Counter
				
				assume esi: ptr PluginInfo
					invoke lstrlen,addr findData.cFileName
					inc eax
					.if eax < MAX_PATH
						invoke lstrcmp, addr findData.cFileName, chr$("TitanEngine.dll")
						.if eax != 0
							invoke lstrcpy, addr [esi].DllName, addr findData.cFileName
							inc Counter
						.endif								
					.endif
				assume esi:nothing
				invoke FindNextFile, fHandle, addr findData
			.endw
		.endif
	.endif
	
	invoke FreeString, addr CurrentDir
	popad
	ret

PopulateList endp

DetectCryptoSignatures proc hWin:HWND, szFileName:DWORD, szDllName:DWORD
	
	invoke DoJob, hWin, szFileName, szDllName
	ret
	
DetectCryptoSignatures endp

DetectOEP proc hWin:HWND, szFileName:DWORD, szDllName:DWORD

	invoke DoJob, hWin, szFileName, szDllName
	ret
	
DetectOEP endp

GenericUnpacker proc hWin:HWND, szFileName:DWORD, szDllName:DWORD

	invoke DoJob, hWin, szFileName, szDllName
	ret

GenericUnpacker endp

DoJob proc hWin:HWND, szFileName:DWORD, szDllName:DWORD

	.if IsFileSelected == 1
		invoke GetModuleFileName, hInstance, addr CurrentDir, MAX_PATH
		
		mov esi, offset CurrentDir
		invoke lstrlen, esi
		add esi, eax
		.while byte ptr[esi] != "\"
			mov byte ptr [esi], 0
			dec esi
			dec eax
		.endw
		
		sub esi, eax
		
		invoke lstrlen, esi
		inc eax
		
		.if eax < MAX_PATH
			invoke lstrcpy, addr ToolsDir, addr CurrentDir
			invoke lstrlen, addr ToolsDir
			inc eax
			.if eax < MAX_PATH
				invoke lstrcat, addr ToolsDir, addr ToolsDirName
				invoke lstrlen, addr ToolsDir
				inc eax
				.if eax < MAX_PATH
					lea esi, ToolsDir
					add esi, eax
					dec esi
					mov byte ptr[esi], 05ch
					
					invoke lstrlen, addr ToolsDir
					inc eax 
					.if eax < MAX_PATH
						invoke lstrcat, addr ToolsDir, szDllName
					
						invoke LoadLibrary, addr ToolsDir
						.if eax != NULL
							mov hModule, eax
							
							invoke GetProcAddress, eax, addr DoMyJobProcName
							
							.if eax != NULL
								push 0
								push 50456944h ; PluginID
								push szFileName
								push hWin
								call eax
								
								invoke FreeLibrary, hModule
								
								invoke FreeString, addr CurrentDir
								invoke FreeString, addr ToolsDir
								
								.if eax == 0
									invoke MessageBox, hWin, chr$("Error: FreeLibrary Failed!"), chr$("Error freeing library"), MB_ICONERROR
								.endif
							.else
								invoke MessageBox, hWin, chr$("Error: GetProcAddress Failed!"), chr$("Error loading function"), MB_ICONERROR
							.endif
						.else
							invoke MessageBox, hWin, chr$("Error: LoadLibrary Failed!"), chr$("Error loading library"), MB_ICONERROR
						.endif
					.endif				
				.endif
			.endif
		.endif		
	.else
		invoke MessageBox, hWin, offset SelectionFileErrorMsg, offset ErrorMsg, MB_ICONERROR
	.endif
	
	ret
	
DoJob endp

FreeString proc szString:DWORD

	mov esi, szString
	.while byte ptr[esi] != 0
		mov byte ptr[esi], 0
		inc esi
	.endw
	
	ret

FreeString endp

LoadPlugins proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL findData:WIN32_FIND_DATA
	
	invoke GetModuleFileName, hInstance, addr CurrentDir, MAX_PATH

	mov esi, offset CurrentDir
	invoke lstrlen, esi
	add esi, eax
	.while byte ptr[esi] != "\"
		mov byte ptr [esi], 0
		dec esi
		dec eax
	.endw
	
	sub esi, eax
	
	invoke lstrlen, esi
	
	.if eax < MAX_PATH
		invoke lstrcat, esi, addr Pluginsx86DirName
		invoke SetCurrentDirectory, esi  
	
		invoke FindFirstFile,addr fPattern, addr findData
		.if eax != INVALID_HANDLE_VALUE
			mov fHandle, eax
			.while eax !=0
				invoke LoadLibrary,addr findData.cFileName
				.if eax != NULL
					mov hModule, eax
					invoke GetProcAddress,eax, offset DoUnpackName
					.if eax != NULL
						mov DoUnpackAddrs, eax
						invoke GetProcAddress, hModule, offset GetPluginName
						.if eax != NULL
							mov GetPluginNameAddrs, eax
							
							;lea esi, pInfo
							;xor edx, edx
							;mov eax, sizeof PluginInfo
							;imul counter
							;add esi, eax
							;invoke GetStructPtr, counter
							invoke GetStructPtr, addr pInfo, counter
							assume esi: ptr PluginInfo
								mov ebx, counter
								mov [esi].Index, ebx 
								mov ebx, DoUnpackAddrs
								mov [esi].DoUnpackAddr, ebx
								mov ebx, GetPluginNameAddrs
								mov [esi].GetPlugNameAddr, ebx
								
								invoke lstrlen,addr findData.cFileName
								inc eax
								.if eax < MAX_PATH
									invoke lstrcpyn,addr [esi].DllName, addr findData.cFileName, eax
								
									call GetPluginNameAddrs
									mov ebx, eax
									invoke lstrlen,eax
									inc eax
									.if eax < MAX_PATH
										invoke lstrcpyn,addr [esi].PluginName, ebx, eax
										
										invoke SendMessage, hCombo, CB_ADDSTRING, 0, ebx								
									.endif
								.endif
							assume esi:nothing
							inc counter
						.endif 
					.endif
				.endif
				invoke FindNextFile, fHandle, addr findData
			.endw
		.else
			invoke MessageBox, hWin, offset ErrorMsgText, offset ErrorMsgTitle, MB_ICONERROR
		.endif
	.endif
	
	invoke FreeString, addr CurrentDir
	;push hWin
	;call eax 
	 
	;invoke FreeLibrary,addr hModule
	
	;lea esi, pInfo
	;add esi, sizeof PluginInfo
	
	;assume esi:ptr PluginInfo
	;	mov [esi].Index, 45
	;	mov [esi].DoUnpackAddr, 12345678
	;assume esi:NOTHING
	ret

;   xor ecx,ecx ; inicializacion
  
;loop_otro:
;   cmp ecx, NUMERO DE ITEMS
;    je loop_fin
;          lea esi, Array
;          xor edx,edx 
;          mov eax, sizeof TIPO DE ESTRUCTURA
;          imul ecx 
;         add esi,eax ; con esto esi apunta ya al Item
; 
;         ; Manipulando la estructura
;        assume esi: ptr TIPO DE ESTRUCTURA
;              ; Tocas los item
;
;        assume esi:NOTHING
;       ; Actualizacón par el siguiente item
;        inc ecx
;       jmp loop_otro
;
;loop_fin:

LoadPlugins endp

end start
