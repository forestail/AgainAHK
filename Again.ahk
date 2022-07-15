; Again.ahk
; 
; 増井俊之先生のAgainのAutoHotKey実装。
; 参考：https://github.com/masui/Again
; 
; 2022/07/15	公開 by forestail
; 
; ※呼び出しホットキーのデフォルトは[Ctrl + l]になっているので、好みのものに変更してください。
; 

#UseHook On
#KeyHistory 50
#InstallKeybdHook
#Persistent
global seqRepeat := Object()

global againMacro := Object()
global oldHistory := Object()
global newHistory := Object()
global flgEnableLog
global strLogPath
global seqKey := Object()

; Import ini file.(Again.ini)
IniRead, strInvokeHotKey, %A_ScriptDir%\Again.ini, Main, InvokeHotKey , ^l
IniRead, strSuspendHotKey, %A_ScriptDir%\Again.ini, Main, SuspendHotKey , ^+l
IniRead, flgEnableLog, %A_ScriptDir%\Again.ini, Main, EnableLog , 1
IniRead, strLogPath, %A_ScriptDir%\Again.ini, Main, LogPath , Againlog.txt

; Set working directory to script directory.
SetWorkingDir %A_ScriptDir%

Hotkey, %strInvokeHotKey%, Execute
Hotkey, %strSuspendHotKey%, SuspendMacro

SetTimer, ClearKbdMacro, 1000
Return


ClearKbdMacro:
	newHistory := GetHistoryArray(ParseKeyHistory())

	If % ArrayCompare(oldHistory , newHistory)
	{
		againMacro = []
	}
	Else
	{
		againMacro := AppendArray(againMacro, GetPostfix(oldHistory, newHistory))
		oldHistory := newHistory
	}
Return



;;
;; "xyzabcdefg" と "abcdefghij" から "hij" を得る（AHF版では実際には配列）
;;
GetPostfix(s1, s2){
	len1 := s1.MaxIndex()
	len2 := s2.MaxIndex()
	
	i := len2

	While (i >= 0)
	{
		if % ArrayCompare(SubArray(s2, 0, i + 1) , SubArray(s1, len1 - i >= 0 ? len1 - i : 0, i + 1))
		{
			return SubArray(s2, i + 1, len2 - i + 1)
		}
		else
		{
			i -= 1
		}
	}
	return []
}



; Suspend
SuspendMacro:
	Suspend, Toggle
	; Suspendだとタイマーは動作し続けるが、Puaseにするとホットキーで解除できないためSuspendだけ
	; againMacro := []
	; oldHistory := []
	; newHistory := []
Return


; Execute
Execute:
	SetTimer, ClearKbdMacro, Off

	KeyHistory := ParseKeyHistory()

	recent := RemoveHotKey(GetHistoryArray(KeyHistory))

	if againMacro != []
	{
		oldHistory := newHistory
		againMacro := AppendArray(againMacro, GetPostfix(oldHistory, recent))
		oldHistory := recent
		Send % GetMacro(againMacro)
	}
	Else
	{
		againMacro := GetPostfix(oldHistory, recent)
	}
	newHistory := recent

	LogWrite("Again," . againMacro.MaxIndex())

	SetTimer, ClearKbdMacro, On
Return


IsDoubledHotkey(arr)
{
	if arr[arr.MaxIndex()]["Type"] == "h" || arr[arr.MaxIndex()]["Type"] == "s" || arr[arr.MaxIndex()]["Key"] == "LControl"
	{
		return IsDoubledHotkey(SubArray(arr,0,arr.MaxIndex()))
	}
	else if arr[arr.MaxIndex()]["Type"] == "i"
	{
		return 1
	}
	else
	{
		return 0
	}
}


RemoveHotKey(arr)
{
	if RegExMatch(arr[arr.MaxIndex()], "U){.+\sdown}") > 0
	{
		return RemoveHotKey(SubArray(arr,0,arr.MaxIndex()))
	}
	else
	{
		return arr
	}	
}

; Convert KeyHistory to One-dimensional array
GetHistoryArray(arr)
{
	Array := Object()
	InnerFunction := ""

	For index,element in arr
	{		
		if element["Key"] != "" && element["Type"] != "i" && element["Type"] != "h"
		{
			if element["UpDn"]
			{
				if isFunctionKey(element["Key"]) == 0
				{
					if InnerFunction != 
					{
						Array.Insert("{" . InnerFunction . " down}")
					}
					; Array.Insert("{vk" . element["VK"] . "}")
					Array.Insert("{vk" . element["VK"] . "sc" . element["SC"] . "}")

					if InnerFunction != 
					{
						Array.Insert("{" . InnerFunction . " up}")
					}
				}
				else
				{
					InnerFunction := element["Key"]
				}
			}
			else
			{
				if isFunctionKey(element["Key"]) == 1
				{
					InnerFunction := ""
				}
			}		
		}
	}
	return Array
}

isFunctionKey(key)
{
	if key in LShift,RShift,LControl,RControl,LAlt,RAlt
	{
		return 1
	}
	else
	{
		return 0
	}
}



; Make send text
GetMacro(arr)
{
	buf := ""
	For index,element in arr
	{
		buf .= element
	}
	return buf
}


SubArray(arr, start, num)
{
	res := Object()
	Loop, % num
	{
		res.Insert(arr[start + A_Index - 1])
	}
	return res
}

AppendArray(a,b)
{
	res := Object()
	Loop, % a.MaxIndex()
	{
		res.Insert(a[A_Index])
	}

	Loop, % b.MaxIndex()
	{
		res.Insert(b[A_Index])
	}

	return res
}

ArrayCompare(a,b)
{
	if a.MaxIndex() != b.MaxIndex()
	{
		return 0
	}


	for index,value in a
	{
		if a[index + 1] != b[index + 1]
		{
			return 0
		}
	}
	return 1
}

LogWrite(msg)
{
	if flgEnableLog
	{
		logText = %A_YYYY%/%A_MM%/%A_DD%,%A_Hour%:%A_Min%:%A_Sec%,%msg%
		FileAppend,  %logText%`n, %strLogPath%
	}
}

; For Debug
PrintArray( arr )
{
	buf := ""
	For index,element in arr
	{
		buf .= element
		buf .= "`n"
	}
	MsgBox % buf
	return buf
}




; ---------------------------------------------------------------
; from https://www.autohotkey.com/boards/viewtopic.php?t=9656
; ---------------------------------------------------------------
ScriptInfo(Command)
{
	static hEdit := 0, pfn, bkp
	if !hEdit {
		hEdit := DllCall("GetWindow", "ptr", A_ScriptHwnd, "uint", 5, "ptr")
		user32 := DllCall("GetModuleHandle", "str", "user32.dll", "ptr")
		pfn := [], bkp := []
		for i, fn in ["SetForegroundWindow", "ShowWindow"] {
			pfn[i] := DllCall("GetProcAddress", "ptr", user32, "astr", fn, "ptr")
			DllCall("VirtualProtect", "ptr", pfn[i], "ptr", 8, "uint", 0x40, "uint*", 0)
			bkp[i] := NumGet(pfn[i], 0, "int64")
		}
	}

	if (A_PtrSize=8) {	; Disable SetForegroundWindow and ShowWindow.
		NumPut(0x0000C300000001B8, pfn[1], 0, "int64")	; return TRUE
		NumPut(0x0000C300000001B8, pfn[2], 0, "int64")	; return TRUE
	}
	else {
		NumPut(0x0004C200000001B8, pfn[1], 0, "int64")	; return TRUE
		NumPut(0x0008C200000001B8, pfn[2], 0, "int64")	; return TRUE
	}

	static cmds := {ListLines:65406, ListVars:65407, ListHotkeys:65408, KeyHistory:65409}
	cmds[Command] ? DllCall("SendMessage", "ptr", A_ScriptHwnd, "uint", 0x111, "ptr", cmds[Command], "ptr", 0) : 0

	NumPut(bkp[1], pfn[1], 0, "int64")	; Enable SetForegroundWindow.
	NumPut(bkp[2], pfn[2], 0, "int64")	; Enable ShowWindow.

	ControlGetText, text,, ahk_id %hEdit%
	return text
}

ParseKeyHistory(KeyHistory:="",ParseStringEnumerations:=1){
	/*
	Parses the text from AutoHotkey's Key History into an associative array:
	Header:
	KeyHistory[0]	["Window"]					String
	["K-hook"]					Bool
	["M-hook"]					Bool
	["TimersEnabled"]			Int
	["TimersTotal"]				Int
	["Timers"]					String OR Array		[i] String
	["ThreadsInterrupted"]		Int
	["ThreadsPaused"]			Int
	["ThreadsTotal"]			Int
	["ThreadsLayers"]			Int
	["PrefixKey"]				Bool
	["ModifiersGetKeyState"]	|String OR Array	["LAlt"]   Bool
	["ModifiersLogical"]		|					["LCtrl"]  Bool
	["ModifiersPhysical"]		|					["LShift"] Bool
	["LWin"]   Bool
	["RAlt"]   Bool
	["RCtrl"]  Bool
	["RShift"] Bool
	["RWin"]   Bool
	Body:
	KeyHistory[i]	["VK"]		String [:xdigit:]{2}
	["SC"]		String [:xdigit:]{3}
	["Type"]	Char [ hsia#U]
	["UpDn"]	Bool (0=up 1=down)
	["Elapsed"]	Float
	["Key"]		String
	["Window"]	String
	*/


	If !(KeyHistory) && IsFunc("ScriptInfo")
	KeyHistory:=ScriptInfo("KeyHistory")

	RegExMatch(KeyHistory,"sm)(?P<Head>.*?)\s*^NOTE:.*-{109}\s*(?P<Body>.*)\s+Press \[F5] to refresh\.",KeyHistory_)
	KeyHistory:=[]

	RegExMatch(KeyHistory_Head,"Window: (.*)\s+Keybd hook: (.*)\s+Mouse hook: (.*)\s+Enabled Timers: (\d+) of (\d+) \((.*)\)\s+Interrupted threads: (.*)\s+Paused threads: (\d+) of (\d+) \((\d+) layers\)\s+Modifiers \(GetKeyState\(\) now\) = (.*)\s+Modifiers \(Hook's Logical\) = (.*)\s+Modifiers \(Hook's Physical\) = (.*)\s+Prefix key is down: (.*)",Re)

	KeyHistory[0]:={"Window": Re1, "K-hook": (Re2="yes"), "M-hook": (Re3="yes"), "TimersEnabled": Re4, "TimersTotal": Re5, "Timers": Re6, "ThreadsInterrupted": Re7, "ThreadsPaused": Re8, "ThreadsTotal": Re9, "ThreadsLayers": Re10, "ModifiersGetKeyState": Re11, "ModifiersLogical": Re12, "ModifiersPhysical": Re13, "PrefixKey": (Re14="yes")}

	If (ParseStringEnumerations){
		Loop, Parse,% "ModifiersGetKeyState,ModifiersLogical,ModifiersPhysical",CSV
		{
			i:=A_Loopfield
			k:=KeyHistory[0][i]
			KeyHistory[0][i]:={}
			Loop, Parse,% "LWin,LShift,LCtrl,LAlt,RWin,RShift,RCtrl,RAlt",CSV
			KeyHistory[0][i][A_LoopField]:=Instr(k,A_Loopfield)
		}

		k:=KeyHistory[0]["Timers"]
		KeyHistory[0]["Timers"]:=[]
		Loop, Parse,k,%A_Space%
		KeyHistory[0]["Timers"].Push(A_Loopfield)
	}

	Loop, Parse,KeyHistory_Body,`n,`r
	{
		RegExMatch(A_Loopfield,"(\w+) {2}(\w+)\t([ hsia#U])\t([du])\t(\S+)\t(\S*) *\t(.*)",Re)
		KeyHistory.Push({"VK": Re1, "SC": Re2, "Type": Re3, "UpDn": (Re4="D"), "Elapsed": Re5, "Key": Re6, "Window": Re7})
	}

	Return KeyHistory
}

hexToDecimal(str)
{
	static _0 := 0
	static _1 := 1
	static _2 := 2
	static _3 := 3
	static _4 := 4
	static _5 := 5
	static _6 := 6
	static _7 := 7
	static _8 := 8
	static _9 := 9
	static _a := 10
	static _b := 11
	static _c := 12
	static _d := 13
	static _e := 14
	static _f := 15
	;
	str := LTrim(str, "0x `t`n`r")
	len := StrLen(str)
	ret := 0
	Loop, Parse, str
	{
		ret += _%A_LoopField% * (16 ** (len - A_Index))
	}
	return ret
}
