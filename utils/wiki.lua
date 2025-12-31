--[[
Connects to the community picotron wiki (astralsparv)
]]

argv=env().argv
local search="https://raw.githubusercontent.com/Astralsparv/Picotron-Wiki/refs/heads/main/"

store("/ram/wikipopup.lua",[[
window{x=1,y=0,width=478,height=245,title=env().title}

poke(0x5f36,128) --simple wrapping
local height=0
res=""
text=env().msg
text=text:split("\n",true)

lines={}

for i=1, #text do
	local line=text[i]
	local m1,m2=line:match("^(#+)[ \t]*(.-)[ \t]*#*[ \t]*$")
	if (m1) then --header
		if (m1:len()>3) then
			add(lines,{t="\^w\^t\014"..m2,c=7})
			height+=10
		else
			add(lines,{t="\^w\^t"..m2,c=7})
			height+=12
		end
	else
		add(lines,{t=line,c=6})
		height+=6
	end
end

local camy=0

function _update()
	local mx,my,mb,wx,wy=mouse()
	camy+=wy*4
	if (btn(2)) camy-=4
	if (btn(3)) camy+=4
	camy=max(0,camy)
end

function _draw()
	cls()
	camera(0,camy)
	for i=1, #lines do
		print(lines[i].t,lines[i].c)
	end
end
]])

sections={
	functions={
		url="picotron_api/functions/",
		suffix="/main.md",
		title="function"
	}
}


keywords={
	functions="functions",
	functs="functions",
	funct="functions"
}
keywords["function"]="functions" --lua tries making a function

section="functions" --default
query=""

local settings=fetch("/appdata/astralsparv-picotron-wiki/settings.pod") or {popup=false}

if (argv[1]) then
	if (argv[1]=="enablepopup") then
		settings.popup=true
		mkdir("/appdata/astralsparv-picotron-wiki/")
		store("/appdata/astralsparv-picotron-wiki/settings.pod",settings)
		print("Enabled popup.")
		print("Settings: "..tostr(pod(settings)))
	elseif (argv[1]=="disablepopup") then
		settings.popup=false
		mkdir("/appdata/astralsparv-picotron-wiki/")
		store("/appdata/astralsparv-picotron-wiki/settings.pod",settings)
		print("Disabled popup.")
		print("Settings: "..tostr(pod(settings)))
	elseif (argv[1]=="update") then
		store("/system/util/wiki.lua",fetch("https://raw.githubusercontent.com/Astralsparv/Picotron-File-Depot/refs/heads/main/utils/wiki.lua"))
	else
		if (argv[2]) then
			if (keywords[argv[1]]) then
				section=sections[keywords[argv[1]]].url
			end
		else
			query=argv[1]
		end
		--lets you more easily just paste a function
		local f=query:find("[(]")
		if (f) then
			query=query:sub(1,f-1)
		end
		print("Searching for: \""..query.."\" in section: "..section)
		search..=sections[section].url
		search..=query..sections[section].suffix
		--terminal.lua doesn't support async
		local res=fetch(search)
		if (res=="404: Not Found") then
			print("No results found.")
			print("Try the online search engine at astralsparv.github.io/Picotron-Wiki")
		end
		if (settings.popup) then
			print("Opened in a popup.")
			create_process("/ram/wikipopup.lua",{msg=res,title=sections[section].title.." "..query})
		else
			print(res)
		end
	end
else
	print("wiki [section] <query>\n")
	
	print("Picotron Community Wiki")
	print("Web search engine: astralsparv.github.io/Picotron-Wiki")
	print("Source: github.com/Astralsparv/Picotron-Wiki\n")
	
	print("wiki enablepopup - enable a popup for markdown")
	print("wiki disablepopup - disable the popup")
	print("wiki update - update to latest version of the wiki util")
end
