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
; Hyperlink stuffs from: http://members.a1.net/ranmasaotome/masm32/Hyperlink.zip
;

.386
.model flat,stdcall
option casemap:none

include fuu.inc

.code

start:

	invoke GetModuleHandle,NULL
	mov    hInstance,eax
	
	invoke InitHyperLinkClass
	
	invoke GetCommandLine
	invoke InitCommonControls

	invoke CreateFontIndirect,offset Tahoma10
	mov hTahoma,eax
	
	invoke CreateSolidBrush,008080FFh
	mov hBrush,eax
	
	mov		CommandLine,eax
	invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	
	invoke DeleteObject,hTahoma
	invoke DeleteObject,hBrush
	
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
	
	invoke LoadIcon, hInstance, 500
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	
	invoke RegisterClassEx,addr wc
	invoke CreateDialogParam,hInstance,IDD_DIALOG,NULL,addr WndProc,NULL
	
	invoke DragAcceptFiles, hWnd, TRUE
	
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
	
	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		push	hWin
		pop		hWnd
		
		invoke Init, hWin, uMsg, wParam, lParam
		
	.elseif eax == WM_DROPFILES
		invoke DragQueryFile, wParam, NULL, addr GlobalBuffer, 1024
		mov IsFileSelected, 1
		invoke SetDlgItemText, hWin, FileNameEdit, addr GlobalBuffer
		
	.elseif eax == WM_COMMAND
		mov		eax,wParam
		mov		edx,eax
		shr		edx,16
		and		eax,0FFFFh
		
		.if edx == BN_CLICKED
			.if eax==IDM_FILE_EXIT
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.elseif ax == IDM_HELP_ABOUT
				;invoke ShellAbout,hWin,addr AppName,addr AboutMsg,NULL
				invoke MessageBox,hWin,offset msgText, offset msgTitle, MB_OK
			.elseif ax == IDM_TOOLS_CRYPTSIGN
				invoke DetectCryptoSignatures, hWin, addr GlobalBuffer, addr CryptoSignDllName
			.elseif ax == IDM_TOOLS_DETECTOEP
				invoke DetectOEP, hWin, addr GlobalBuffer, addr GenOEPDllName
			.elseif ax == IDM_GENUNPACK
				invoke GenericUnpacker, hWin, addr GlobalBuffer, addr GenUnpackerDllName
			.elseif ax == IDM_IDENTIFY_SIGNATURE
				invoke IdentifyPackerOrCompiler, hWin, addr GlobalBuffer, addr IdentifyPESignatureDllName
			.elseif ax == ExitBtn
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.elseif ax == AboutBtn
				invoke MessageBox,hWin,offset msgText, offset msgTitle, MB_OK
			.elseif ax == RefreshBtn
				invoke RefreshComboBox
			.elseif ax == UnpackBtn
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
				
			.elseif ax == BrowseFileBtn
				invoke GetFileDialog
				invoke SetDlgItemText, hWin, FileNameEdit, addr GlobalBuffer
			.endif
		
		.elseif edx == CBN_SELCHANGE
			.if ax == PluginComboBox
				invoke SendMessage, hCombo, CB_GETCURSEL, 0, 0
				.if eax == CB_ERR 
					jmp NoSelection
				.endif
				mov current_selection, eax
			.endif
		NoSelection:
			; no item selected
		.endif
		
	.elseif eax == WM_CTLCOLORDLG
		mov eax, hBrush
		ret
		
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

Init proc hWin:HWND, uMsg:UINT, wParam:LPARAM, lParam:LPARAM
	
	invoke GetHandlesOfControls, hWin
	
	invoke CheckDlgButton, hWin, RealignPECheckBox, BST_CHECKED
	
	invoke LoadPlugins, hWin, uMsg, wParam, lParam

	ret
Init endp 

GetHandlesOfControls proc hWin:HWND

	invoke GetDlgItem, hWin, PluginComboBox
	mov hCombo,eax
	
	invoke GetDlgItem, hWin, OutputListBox
	mov hListBox, eax

	invoke GetDlgItem, hWin, EmailLink
	mov hEmailLink, eax
	
	invoke SetWindowText,hEmailLink,offset EmailAddress
	
	invoke SendMessage,hEmailLink,HLM_SETHOTCOLOR,0,0FF0000h
	invoke SendMessage,hEmailLink,HLM_SETTEXTCOLOR,0,0
	invoke SendMessage,hEmailLink,HLM_SETUNDERLINE,0,TRUE
	
	invoke SendMessage,hEmailLink,HLM_SETSUBJECT,0,offset Subject
	invoke SendMessage,hEmailLink,HLM_SETBODY,0,offset Body

	invoke SendMessage,hEmailLink,HLM_SETTYPE,0,HLINK_EMAIL
	
	invoke GetDlgItem, hWin, BlogLinkClickable
	mov hBlogLink, eax
	
	invoke SetWindowText, hBlogLink, offset CrackinglandiaLink
	invoke SendMessage, hBlogLink,HLM_SETHOTCOLOR,0,0FF0000h
	invoke SendMessage, hBlogLink,HLM_SETTEXTCOLOR,0,0
	invoke SendMessage, hBlogLink,HLM_SETTYPE,0,HLINK_URL 
	ret

GetHandlesOfControls endp

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

IdentifyPackerOrCompiler proc hWin:HWND, szFileName:DWORD, szDllName:DWORD
	
	invoke DoJob, hWin, szFileName, szDllName
	ret

IdentifyPackerOrCompiler endp

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
	
	ret

LoadPlugins endp

_Hyperlink proc hlc_hWin:DWORD,hlc_uMsg:DWORD,hlc_wParam:DWORD,hlc_lParam:DWORD
	LOCAL hlc_tme				:TRACKMOUSEEVENT
	LOCAL hlc_ps				:PAINTSTRUCT
	LOCAL hlc_hdc				:DWORD
	LOCAL hlc_strlen			:DWORD
	LOCAL hlc_prc				:RECT
	LOCAL hlc_color				:DWORD
	LOCAL hlc_pt				:POINT
	LOCAL hlc_text[2048]		:BYTE
	LOCAL hlc_pSubject			:DWORD

	.if hlc_uMsg == WM_SETTEXT
		; Get the border size
		invoke GetWindowRect,hlc_hWin,ADDR hlc_prc
		mov eax,hlc_prc.right
		sub eax,hlc_prc.left
		push eax
		mov eax,hlc_prc.bottom
		sub eax,hlc_prc.top
		push eax
		invoke GetClientRect,hlc_hWin,ADDR hlc_prc
		pop eax
		sub eax,hlc_prc.bottom
		pop ecx
		push eax
		sub ecx,hlc_prc.right
		push ecx

		invoke GetDC,hlc_hWin
		mov hlc_hdc,eax

		invoke GetWindowLong,hlc_hWin,20
		.if !eax
			invoke GetStockObject,SYSTEM_FONT
		.endif
		invoke SelectObject,hlc_hdc,eax
		invoke lstrlen,hlc_lParam
		mov hlc_strlen,eax
		invoke DrawText,hlc_hdc,hlc_lParam,hlc_strlen,ADDR hlc_prc,DT_CALCRECT
		pop ecx
		add ecx,hlc_prc.right
		sub ecx,hlc_prc.left

		pop eax
		add eax,hlc_prc.bottom
		sub eax,hlc_prc.top
		invoke SetWindowPos,hlc_hWin,HWND_TOP,0,0,ecx,eax,SWP_NOMOVE or SWP_NOZORDER
		invoke ReleaseDC,hlc_hWin,hlc_hdc

	.elseif hlc_uMsg == WM_CREATE
		invoke GlobalAlloc,GMEM_FIXED,4192
		invoke SetWindowLong,hlc_hWin,12,eax

	.elseif hlc_uMsg == HLM_SETTYPE
		invoke SetWindowLong,hlc_hWin,0,hlc_lParam
		ret

	.elseif hlc_uMsg == HLM_SETUNDERLINE
		invoke SetWindowLong,hlc_hWin,32,hlc_lParam
		ret

	.elseif hlc_uMsg == HLM_SETHOTCOLOR
		invoke SetWindowLong,hlc_hWin,4,hlc_lParam

		; set the current color if necessary
		invoke GetCursorPos,ADDR hlc_pt
		invoke GetParent,hlc_hWin
		push eax
		mov ecx,eax
		invoke ScreenToClient,ecx,ADDR hlc_pt
		pop ecx
		invoke ChildWindowFromPoint,ecx,hlc_pt.x,hlc_pt.y
		.if eax == hlc_hWin
			invoke SetWindowLong,hlc_hWin,16,hlc_lParam
			mov hlc_tme.cbSize,SIZEOF TRACKMOUSEEVENT
			mov hlc_tme.dwFlags,TME_LEAVE
			mov eax,hlc_hWin
			mov hlc_tme.hwndTrack,eax
			mov hlc_tme.dwHoverTime,HOVER_DEFAULT
			invoke _TrackMouseEvent,ADDR hlc_tme
		.endif
		invoke InvalidateRect,hlc_hWin,NULL,TRUE
		invoke UpdateWindow,hlc_hWin
		ret

	.elseif hlc_uMsg == HLM_SETTEXTCOLOR
		invoke SetWindowLong,hlc_hWin,8,hlc_lParam

		; set the current color if necessary
		invoke GetCursorPos,ADDR hlc_pt
		invoke GetParent,hlc_hWin
		push eax
		mov ecx,eax
		invoke ScreenToClient,ecx,ADDR hlc_pt
		pop ecx
		invoke ChildWindowFromPoint,ecx,hlc_pt.x,hlc_pt.y
		.if eax != hlc_hWin
			invoke SetWindowLong,hlc_hWin,16,hlc_lParam
		.endif
		invoke InvalidateRect,hlc_hWin,NULL,TRUE
		invoke UpdateWindow,hlc_hWin
		ret

	.elseif hlc_uMsg == HLM_SETSUBJECT
		invoke lstrlen,hlc_lParam
		inc eax
		mov hlc_strlen,eax
		invoke GetWindowLong,hlc_hWin,24
		mov hlc_pSubject,eax
		.if eax
			invoke GlobalFree,eax
		.endif
		invoke GlobalAlloc,GMEM_FIXED,hlc_strlen
		mov hlc_pSubject,eax
		.if hlc_strlen >= 1024
			mov eax,hlc_lParam
			add eax,1023
			mov BYTE PTR [eax],0
		.endif
		invoke lstrcpy,hlc_pSubject,hlc_lParam
		invoke SetWindowLong,hlc_hWin,24,hlc_pSubject
		ret

	.elseif hlc_uMsg == HLM_SETBODY
		invoke lstrlen,hlc_lParam
		inc eax
		mov hlc_strlen,eax
		invoke GetWindowLong,hlc_hWin,28
		mov hlc_pSubject,eax
		.if eax
			invoke GlobalFree,eax
		.endif
		invoke GlobalAlloc,GMEM_FIXED,hlc_strlen
		mov hlc_pSubject,eax
		.if hlc_strlen >= 1024
			mov eax,hlc_lParam
			add eax,1023
			mov BYTE PTR [eax],0
		.endif
		invoke lstrcpy,hlc_pSubject,hlc_lParam
		invoke SetWindowLong,hlc_hWin,28,hlc_pSubject
		ret

	.elseif hlc_uMsg == WM_SETFONT
		; The def window proc does not do fonts so it has to be done manually
		invoke SetWindowLong,hlc_hWin,20,hlc_wParam
		invoke GetWindowText,hlc_hWin,ADDR hlc_text,256
		invoke SetWindowText,hlc_hWin,ADDR hlc_text
		.if hlc_lParam
			invoke InvalidateRect,hlc_hWin,NULL,TRUE
			invoke UpdateWindow,hlc_hWin
		.endif
		ret

	.elseif hlc_uMsg == WM_LBUTTONDOWN
		invoke GetWindowLong,hlc_hWin,12
		mov hlc_pSubject,eax

		invoke GetWindowLong,hlc_hWin,0
		.if eax == HLINK_URL
			lea eax,hlc_text
			invoke GetWindowText,hlc_hWin,hlc_pSubject,256


		.ELSEIF eax == HLINK_EMAIL
			jmp @F
				hlc_szMailTo 	db		"mailto:",0
				hlc_szSubject	db		"?subject=",0
				hlc_szBody		db		"&body=",0
				hlc_szOpen		db		"open",0
			@@:
			invoke lstrcpy,hlc_pSubject,OFFSET hlc_szMailTo
			mov eax,hlc_pSubject
			add eax,7
			invoke GetWindowText,hlc_hWin,eax,240
			invoke GetWindowLong,hlc_hWin,24
			.IF eax
				push eax
				invoke lstrcat,hlc_pSubject,OFFSET hlc_szSubject
				pop eax
				invoke lstrcat,hlc_pSubject,eax
				invoke GetWindowLong,hlc_hWin,28
				.IF eax
					push eax
					invoke lstrcat,hlc_pSubject,OFFSET hlc_szBody
					pop eax
					invoke lstrcat,hlc_pSubject,eax
				.ENDIF
			.endif
	
		.endif
		invoke ShellExecute, hlc_hWin, OFFSET hlc_szOpen,hlc_pSubject, 0, 0, SW_SHOWNORMAL

	.elseif hlc_uMsg == WM_MOUSEMOVE
		; The first mouse move message changes the color
		invoke GetWindowLong,hlc_hWin,4
		push eax
		invoke SetWindowLong,hlc_hWin,16,eax
		pop ecx
		.IF eax!=ecx
			invoke GetDlgCtrlID,hlc_hWin
			push eax
			invoke GetParent,hlc_hWin
			pop ecx
			invoke SendMessage,eax,HLM_ISHOT,ecx,hlc_hWin
			mov hlc_tme.cbSize,SIZEOF TRACKMOUSEEVENT
			mov hlc_tme.dwFlags,TME_LEAVE
			mov eax,hlc_hWin
			mov hlc_tme.hwndTrack,eax
			mov hlc_tme.dwHoverTime,HOVER_DEFAULT
			invoke _TrackMouseEvent,ADDR hlc_tme
			invoke InvalidateRect,hlc_hWin,NULL,TRUE
		.ENDIF

	.elseif hlc_uMsg == WM_MOUSELEAVE
		invoke GetWindowLong,hlc_hWin,8
		invoke SetWindowLong,hlc_hWin,16,eax
		invoke InvalidateRect,hlc_hWin,NULL,TRUE
		ret

	.elseif hlc_uMsg == WM_PAINT
		invoke GetWindowText,hlc_hWin,ADDR hlc_text,256
		mov hlc_strlen,eax
		invoke GetWindowLong,hlc_hWin,16
		mov hlc_color,eax
		invoke BeginPaint,hlc_hWin,ADDR hlc_ps
			mov hlc_hdc,eax
			invoke GetWindowLong,hlc_hWin,20
			invoke SelectObject,hlc_hdc,eax
			invoke SetTextColor,hlc_hdc,hlc_color
			invoke SetBkMode,hlc_hdc,TRANSPARENT
			invoke TextOut,hlc_hdc,0,0,ADDR hlc_text,hlc_strlen
			invoke GetWindowLong,hlc_hWin,32 ; Underline
			.IF eax
				; a line is drawn
				invoke CreatePen,PS_SOLID,1,hlc_color
				invoke SelectObject,hlc_hdc,eax
				push eax
				invoke GetClientRect,hlc_hWin,ADDR hlc_prc
				dec hlc_prc.bottom
				invoke MoveToEx,hlc_hdc,0,hlc_prc.bottom,NULL
				invoke LineTo,hlc_hdc,hlc_prc.right,hlc_prc.bottom
				pop eax
				invoke SelectObject,hlc_hdc,eax
				invoke DeleteObject,eax
			.endif
		invoke EndPaint,hlc_hWin,ADDR hlc_ps
		ret

	.elseif hlc_uMsg == WM_DESTROY
		invoke GetWindowLong,hlc_hWin,12
		.IF eax
			invoke GlobalFree,eax
		.endif
		invoke GetWindowLong,hlc_hWin,24
		.IF eax
			invoke GlobalFree,eax
		.endif
		invoke GetWindowLong,hlc_hWin,28
		.IF eax
			invoke GlobalFree,eax
		.endif

	.endif

	invoke DefWindowProc,hlc_hWin,hlc_uMsg,hlc_wParam,hlc_lParam
	ret
	
_Hyperlink endp

InitHyperLinkClass proc
	LOCAL hlc_wcx			:WNDCLASSEX

	jmp @F
		UDC_HyperClass	db		"UDC_HyperLink",0
	@@:

	mov hlc_wcx.cbSize,SIZEOF WNDCLASSEX
	mov hlc_wcx.style, CS_HREDRAW or CS_VREDRAW
	mov eax,hInstance
	mov hlc_wcx.hInstance,eax
	mov hlc_wcx.lpszClassName,OFFSET UDC_HyperClass
	mov hlc_wcx.cbClsExtra,0
	mov hlc_wcx.cbWndExtra,36
	mov hlc_wcx.lpfnWndProc,OFFSET _Hyperlink
	mov hlc_wcx.hIcon,NULL
	mov hlc_wcx.hIconSm,NULL
	invoke GetStockObject,NULL_BRUSH
	mov hlc_wcx.hbrBackground,eax
	mov hlc_wcx.lpszMenuName,NULL

	invoke LoadCursor,NULL,IDC_HAND
	mov hlc_wcx.hCursor,eax

	invoke RegisterClassEx,ADDR hlc_wcx

	ret

InitHyperLinkClass endp

end start
