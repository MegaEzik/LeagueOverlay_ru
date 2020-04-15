
forceSync(){
	BlockInput On
	SendInput, {Enter}{/}oos{Enter}
	BlockInput Off
}

toCharacterSelection(){
	BlockInput On
	SendInput, {Enter}{/}exit{Enter}
	BlockInput Off
}

goHideout(){
	BlockInput On
	SendInput, {Enter}{/}hideout{Enter}
	BlockInput Off
}

dndMode(){
	BlockInput On
	SendInput, {Enter}{/}dnd{Enter}
	BlockInput Off
}

chatMsg1(){
	chatReply(textMsg1)
}

chatMsg2(){
	chatReply(textMsg2)
}

chatMsg3(){
	chatReply(textMsg3)
}

chatReply(msg){
	BlockInput On
	SendInput, ^{Enter}%msg%{Enter}
	BlockInput Off
}

chatInvite(){
	BlockInput On
	SendInput, ^{Enter}{Home}{Delete}/invite {Enter}
	BlockInput Off
}

chatKick(){
	BlockInput On
	SendInput, ^{Enter}{Home}{Delete}/kick {Enter}
	BlockInput Off
}

chatTradeWith(){
	BlockInput On
	SendInput, ^{Enter}{Home}{Delete}/tradewith {Enter}
	BlockInput Off
}
