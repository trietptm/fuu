include windows.inc
include user32.inc
include kernel32.inc
include shell32.inc
include comctl32.inc
include comdlg32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib shell32.lib
includelib comctl32.lib
includelib comdlg32.lib
includelib gdi32.lib

WinMain						PROTO :DWORD,:DWORD,:DWORD,:DWORD
WndProc						PROTO :DWORD,:DWORD,:DWORD,:DWORD
LoadPlugins					PROTO :DWORD,:DWORD,:DWORD,:DWORD
Init						PROTO :DWORD,:DWORD,:DWORD,:DWORD
_Hyperlink					PROTO :DWORD,:DWORD,:DWORD,:DWORD
InitializeUnpacker			PROTO :DWORD,:DWORD,:DWORD
DoJob						PROTO :DWORD,:DWORD,:DWORD
DetectCryptoSignatures 		PROTO :DWORD,:DWORD,:DWORD
DetectOEP					PROTO :DWORD,:DWORD,:DWORD
GenericUnpacker				PROTO :DWORD,:DWORD,:DWORD
IdentifyPackerOrCompiler	PROTO :DWORD,:DWORD,:DWORD
GetStructPtr				PROTO :DWORD,:DWORD
GetElementFromList			PROTO :DWORD,:DWORD
IsElementInList				PROTO :DWORD,:DWORD
AddElementToList			PROTO :DWORD,:DWORD
GetHandlesOfControls		PROTO :DWORD
FreeString 					PROTO :DWORD
PopulateList				PROTO :DWORD
GetNumberOfItems			PROTO :DWORD
GetFileDialog				PROTO
RefreshComboBox				PROTO
InitHyperLinkClass			PROTO

IDD_DIALOG			equ 1000
IDM_MENU			equ 10000
IDM_FILE_EXIT		equ 10001
IDM_HELP_ABOUT		equ 10101
IDM_TOOLS_CRYPTSIGN equ 10003
IDM_TOOLS_DETECTOEP equ 10002
IDM_GENUNPACK		equ 10004
IDM_IDENTIFY_SIGNATURE equ 10005
FileNameEdit		equ 1001
ExitBtn				equ 1007
AboutBtn			equ 1006
UnpackBtn			equ 1003
PluginComboBox		equ 1008
BrowseFileBtn		equ 1005
OutputListBox		equ 1004
RealignPECheckBox	equ 1012
RefreshBtn			equ 1010
BlogLinkEdit		equ 1011
BlogLinkClickable	equ 1013
EmailLink			equ 1011

HLM_SETTYPE			equ		WM_USER+200 ; lParam = HLINK_URL/HLINK_EMAIL wndxtra 0
HLM_SETHOTCOLOR		equ		WM_USER+201 ; lParam = Hot color wndxtra 4
HLM_SETTEXTCOLOR	equ		WM_USER+202 ; lParam = Normal text color wndxtra 8
HLM_ISHOT			equ		WM_USER+206 ; Sent to parent wParam = ID, lParam = hControl
HLM_SETSUBJECT		equ		WM_USER+203 ; lParam = Email subject line wndxtra 24
HLM_SETBODY			equ		WM_USER+204 ; lParam = Email body wndxtra 28
HLM_SETUNDERLINE	equ		WM_USER+205 ; lParam = Underline link TRUE/FALSE wndxtra 32

HLINK_URL			equ		0
HLINK_EMAIL			equ		1

chr$ MACRO any_text:VARARG
LOCAL txtname
.data
  txtname db any_text,0
.code
EXITM <OFFSET txtname>
ENDM

PluginInfo STRUCT
	Index			dd 0
	DoUnpackAddr	dd 0
	GetPlugNameAddr	dd 0
	DllName			db MAX_PATH dup(0)
	PluginName 		db MAX_PATH dup(0)
PluginInfo ENDS

.const
ClassName			db 'DLGCLASS',0
AppName				db 'FUU - Faster Universal Unpacker',0
AboutMsg			db 'FUU - Faster Uiversal Unpacker',13,10,'Copyright © NCR 2010',0
msgText				db 'FUU - Faster Universal Unpacker by +NCR/CRC! [ReVeRsEr]',13,10,13,10,
						'Thanks to: marciano, Guan De Dio and InDuLgEo.',13,10,13,10,
						'Web: http://crackinglandia.blogspot.com',13,10,
						'@: nahuelriva[at]gmail[dot]com',0
msgTitle			db 'FUU - Copyright © NCR 2010',0
fPattern			db '*.dll',0
DoUnpackName		db 'DoUnpack',0
GetPluginName		db 'GetPluginName',0
SelectPluginError	db 'You must select a plugin first',0
ErrorMsgText		db 'An error has ocurred while loading plugins',0
ErrorMsgTitle		db 'Fatal Error',0
FilterString 		db "All Files",0,"*.*",0h,0h
ErrorMsg			db 'Error',0
FUUID				db 'FUU1',0
ToolsDirName		db "Tools",0
Pluginsx86DirName	db "Plugins\x86",0
PluginsIA64DirName	db "Plugins\x64",0
CryptoSignDllName	db "kanal.dll",0
GenOEPDllName		db "GenOEP.dll",0
GenUnpackerDllName	db "ZDRx.dll",0
IdentifyPESignatureDllName db "Detect_Signatures.dll",0
DoMyJobProcName		db "DoMyJob",0
SelectionFileErrorMsg db 'You must select a file first',0
CrackinglandiaLink	db "http://crackinglandia.blogspot.com",0
EmailAddress		db "nahuelriva@gmail.com",0
Subject				db "FUU",0
Body				db "A message about FUU",0

.data
Tahoma10			LOGFONT <-13,0,0,0,900,FALSE,FALSE,0,0,0,0,0,0,"Tahoma">
DoUnpackAddrs		dd 0
GetPluginNameAddrs	dd 0
counter				dd 0
current_selection	dd CB_ERR
CurrentDir			db MAX_PATH dup(0)
ToolsDir			db MAX_PATH dup(0)
TempDllName			db MAX_PATH dup(0)
pInfo				PluginInfo 255 dup(<>)
AuxList				PluginInfo 255 dup(<>)
IsFileSelected		db 0
RealignPEFlag		dd 0

.data?
hListBox			dd ?
hCombo				dd ?
fHandle				dd ?
hModule				dd ?
hBlogLink			dd ?
hInstance			dd ?
hEmailLink			dd ?
CommandLine			dd ?
hWnd				dd ?
_lpItem				dd ?
hBrush				dd ?
hTahoma				dd ?
GlobalBuffer 		db 1024 dup(?)
ofn 				OPENFILENAME <?>