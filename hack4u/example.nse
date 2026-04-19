-- HEAD --

description = [[ Script qie enumera y reporta puertos por tpc ]]

-- RULE --

portrule = function(host,port)
	return port.protocol=='tcp'
	and port.state=='open'
end
-- ACTION --

action = function(host,port)
	return 'this port is open'
end
