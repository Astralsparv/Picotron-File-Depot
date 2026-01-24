--[[
Created by @astralsparv
Credit through the name `astralsparv` anywhere, e.g: a credits section.
v1.1
]]

local tcp={}

tcp.host=function(self,port)
	if (self.peers) then
		for i=1, #self.peers do
			self.peers[i].peer:close()
		end
	end
	if (self.sock) then
		self.sock:close()
	end
	self.peers={}
	self.sock=socket("tcp://*:"..port)
	self.peerIndex=0
	self.type="host"
	self.buffer=nil
	return (self.sock!=nil) --socket created?
end
tcp.listen=tcp.host --alias

tcp.getPeers=function(self,full)
	if (self.peers) then
		if (full) return self.peers
		--not full info
		local indexes={}
		for i,_ in pairs(self.peers) do
			add(indexes,i)
		end
		return indexes
	end
end

tcp.client=function(self,ip,port)
	if (self.sock) then
		self.sock:close()
	end
	self.peers=nil
	self.peerIndex=nil
	self.type="client"
	if (port) then
		ip..=":"..port
	end
	self.buffer=""
	self.sock=socket("tcp://"..ip)
	return (self.sock!=nil) --socket created?
end
tcp.connect=tcp.client --alias

tcp.status=function(self)
	if (self.sock) then
		return self.sock:status()
	else
		return "nosock"
	end
end

tcp.write=function(self,message,peer)
	if (self.sock) then
		--\n used for buffers
		if (self.type=="client") then
			--only sends to one place
			self.sock:write(message.."\n")
		elseif (self.type=="host") then
			if (peer) then --send directly to a peer
				self.peers[peer].peer:write(message.."\n")
			else
				for i,peer in pairs(self.peers) do
					self.peers[i].peer:write(message.."\n")
				end
			end
		else
			return false,"library error - unknown socket type"
		end
		return true --sent
	else
		return false,"no socket"
	end
end

tcp.receive=function(self,peerIndex)
	if (self.sock) then
		if (self.type=="host") then
			local msgs={}
			--[[
			{
				{
					message="hello world!",
					sender=peerIndex
				}
			}
			]]
			local newpeer
			if (not peerIndex) then
				if (self.sock:status()=="listening") then
					local peer=self.sock:accept()
					if (peer) then
						self.peers[self.peerIndex]={peer=peer,buffer=""}
						newpeer=self.peerIndex
						self.peerIndex+=1
					end
				end
				for i,peer in pairs(self.peers) do
					local p=peer.peer
					if (p:status()=="ready") then
						peer.buffer..=p:read() or ""
						local buffer=peer.buffer
						while true do
							-- newline = full message end
							local nl = buffer:find("\n", 1, true) --find without formatting, start at index 1
							if (not nl) break
							add(msgs,{message=buffer:sub(1,nl-1),sender=i})
							buffer=buffer:sub(nl+1)
						end
						peer.buffer=buffer
					else
						--byebye peer
						p:close()
						self.peers[i]=nil
					end
				end
			else
				local peer=self.peers[peerIndex]
				local p=peer.peer
				if (peer) then
					if (p:status()=="ready") then
						peer.buffer..=p:read() or ""
						local buffer=peer.buffer
						while true do
							-- newline = full message end
							local nl = buffer:find("\n", 1, true) --find without formatting, start at index 1
							add(msgs,{message=buffer:sub(1,nl-1),sender=i})
							buffer=buffer:sub(nl+1)
							if (not nl) break
						end
					else
						p:close()
						self.peers[peerIndex]=nil
						return false,"disconnected"
					end
				else
					return false,"no peer"
				end
			end
			return msgs,newpeer
		elseif (self.type=="client") then
			local msgs={}
			--[[
			{
				{
					message="hello world!"
				}
			}
			]]
			if (self.sock:status()=="ready") then
				self.buffer..=self.sock:read() or ""
				local buffer=self.buffer
				while true do
					-- newline = full message end
					local nl = buffer:find("\n", 1, true) --find without formatting, start at index 1
					if (not nl) break
					add(msgs,{message=buffer:sub(1,nl-1),sender="host"})
					buffer=buffer:sub(nl+1)
				end
				self.buffer=buffer
			end
			return msgs
		else
			return false,"library error - unknown socket type"
		end
	else
		return false, "no socket"
	end
end

--returns version as second arg
return tcp,"1.1"
