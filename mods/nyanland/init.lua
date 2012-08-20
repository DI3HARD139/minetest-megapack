NYANLAND_HIGHT=30912
NYANCAT_PROP=6
NYANLAND_TREESIZE=2

local nyanland={}

--Cloudstone
minetest.register_node("nyanland:cloudstone", {
	drawtype = "allfaces_optional",
	tile_images = {"nyanland_cloudstone.png"},
	inventory_image = minetest.inventorycube("nyanland_cloudstone.png"),
	material = minetest.digprop_constanttime(0.01),
	dug_item = '',
	paramtype = "light",
	light_source = LIGHT_MAX - 2,
	visual_scale = 2,
})

-- MESE Leaves
minetest.register_node("nyanland:meseleaves", {
	drawtype = "allfaces_optional",
	visual_scale = 2,
	tile_images = {"nyanland_meseleaves.png"},
	inventory_image = minetest.inventorycube("nyanland_meseleaves.png"),
	paramtype = "light",
	material = minetest.digprop_leaveslike(1.0),
	furnace_burntime = 5,
})

-- Clonestone
minetest.register_node("nyanland:clonestone", {
	tile_images = {"nyanland_clonestone.png"},
	inventory_image = minetest.inventorycube("nyanland_clonestone.png"),
	material = minetest.digprop_leaveslike(1.0),
	furnace_burntime = 100,
})

-- Clone items
minetest.register_abm(
	{nodenames = {"nyanland:clonestone"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local pos_over ={x=pos.x, y=pos.y+1, z=pos.z}
		local pos_under={x=pos.x, y=pos.y-1, z=pos.z}
		if minetest.env:get_node(pos_under).name=="air" then
			minetest.env:add_node(pos_under, {name=minetest.env:get_node(pos_over).name})
		end
		nodeupdate(pos_under)	
	end,
})

-- Healstone
minetest.register_node("nyanland:healstone", {
	tile_images = {"nyanland_healstone.png"},
	inventory_image = minetest.inventorycube("nyanland_healstone.png"),
	material = minetest.digprop_leaveslike(1.0),
	furnace_burntime = 100,
})

-- Clone items
minetest.register_abm(
	{nodenames = {"nyanland:healstone"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local objs = minetest.env:get_objects_inside_radius(pos, 3)
		for k, obj in pairs(objs) do
			obj:set_hp(obj:get_hp()+2)
		end
	end,
})

--Creating the NyanLand
minetest.register_on_generated(function(minp, maxp)
	local addpos={}
	if minp.y==NYANLAND_HIGHT then
		for x=minp.x, minp.x+16, 1 do
			for y=minp.y, minp.y, 1 do
				for z=minp.z, minp.z+16, 1 do
					addpos={x=x, y=y, z=z}
					minetest.env:add_node(addpos, {name="nyanland:cloudstone"})
					if math.random(200)==1 then
						nyanland:grow_mesetree(addpos)
					elseif math.random(5000)==1 then
						minetest.env:add_node(addpos,{name="nyanland:clonestone"})
					end
				end
			end
		end

		if math.random(NYANCAT_PROP)==1 then
			local nyan_headpos={}
			nyan_headpos={x=minp.x+math.random(16), y=minp.y+math.random(16)+10, z=minp.z+math.random(16)}	
			nyanland:add_nyancat(nyan_headpos, minp)
		end
	end

end)

function nyanland:add_nyancat(nyan_headpos, minp)
	local nyan_tailpos={}
	minetest.env:add_node(nyan_headpos, {name="default:nyancat"})
	local length=math.random(4,15)
	for z=nyan_headpos.z+1, nyan_headpos.z+length, 1 do
		if z-minp.z > 15 then break end
		nyan_tailpos={x=nyan_headpos.x, y=nyan_headpos.y, z=z}
		minetest.env:add_node(nyan_tailpos, {name="default:nyancat_rainbow"})
	end
end

function nyanland:grow_mesetree(pos)
	--TRUNK
	pos.y=pos.y+1
	local trunkpos={x=pos.x, z=pos.z}
	for y=pos.y, pos.y+4+math.random(2) do
		trunkpos.y=y
		if math.random(200)>1 then
			minetest.env:add_node(trunkpos, {name="default:mese"})
		else
			minetest.env:add_node(trunkpos, {name="nyanland:healstone"})
		end
	end
	--LEAVES
	local leafpos={}
	for x=(trunkpos.x-NYANLAND_TREESIZE), (trunkpos.x+NYANLAND_TREESIZE), 1 do
       		for y=(trunkpos.y-NYANLAND_TREESIZE), (trunkpos.y+NYANLAND_TREESIZE), 1 do
       			for z=(trunkpos.z-NYANLAND_TREESIZE), (trunkpos.z+NYANLAND_TREESIZE), 1 do
		       		if (x-trunkpos.x)*(x-trunkpos.x)
				+(y-trunkpos.y)*(y-trunkpos.y)
				+(z-trunkpos.z)*(z-trunkpos.z)
				<= NYANLAND_TREESIZE*NYANLAND_TREESIZE + NYANLAND_TREESIZE then	
					leafpos={x=x, y=y, z=z}
					if minetest.env:get_node(leafpos).name=="air" then
						if math.random(5)==1 then
							minetest.env:add_node(leafpos, {name="default:apple"})
						else
							minetest.env:add_node(leafpos, {name="nyanland:meseleaves"})
						end				
					end				
				end
			end
		end
	end
end

--MOVING NYAN CATS
minetest.register_abm(
	{nodenames = {"default:nyancat"},
	interval = 1.0,
	chance = 10,
	action = function(pos, node, active_object_count, active_object_count_wider)
		if pos.y>NYANLAND_HIGHT then
			minetest.env:remove_node(pos)
			minetest.env:add_entity(pos, "nyanland:head_entity")

			local tailpos={x=pos.x, y=pos.y, z=pos.z+1}
			while minetest.env:get_node(tailpos).name=="default:nyancat_rainbow" do
				minetest.env:remove_node(tailpos)
				minetest.env:add_entity(tailpos, "nyanland:tail_entity")
				tailpos.z=tailpos.z+1
			end
		end
	end,
})

minetest.register_entity("nyanland:head_entity", {
	physical = false,
	visual = "sprite",
	timer=0,
	textures = {"default_nc_side.png", "default_nc_side.png", "default_nc_side.png",
		"default_nc_side.png", "default_nc_back.png", "default_nc_front.png"},
	collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
	visual = "cube",
	on_activate = function(self, staticdata)
		self.object:setvelocity({x=0, y=0, z=-2})
	end,

	on_punch = function(self, hitter)
		local mesepos=self.object:getpos()
		mesepos.y=mesepos.y-1
		minetest.env:add_entity(mesepos, "nyanland:mese")
	end,

	on_step = function(self, dtime)
		self.timer=self.timer+dtime
		if self.timer>=16 then	
			minetest.env:add_node(self.object:getpos(), {name="default:nyancat"})
			self.object:remove()
		end
	end
})

minetest.register_entity("nyanland:tail_entity", {
	physical = false,
	visual = "sprite",
	timer=0,
	textures = {"default_nc_rb.png", "default_nc_rb.png", "default_nc_rb.png", "default_nc_rb.png", "default_nc_rb.png", "default_nc_rb.png"},
	collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
	visual = "cube",
	on_activate = function(self, staticdata)
		self.object:setvelocity({x=0, y=0, z=-2})
	end,

	on_step = function(self, dtime)
		self.timer=self.timer+dtime
		if self.timer>10 then	
			minetest.env:add_node(self.object:getpos(), {name="default:nyancat_rainbow"})
			self.object:remove()
		end
	end
})

minetest.register_entity("nyanland:mese", {
	physical = true,
	collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
	visual = "cube",
	textures = {"default_mese.png","default_mese.png","default_mese.png","default_mese.png","default_mese.png","default_mese.png"},
	on_step = function(self, dtime)
		self.object:setacceleration({x=0, y=-10, z=0})
		local pos = self.object:getpos()
		local bcp = {x=pos.x, y=pos.y-0.7, z=pos.z} 
		local bcn = minetest.env:get_node(bcp)
		if bcn.name ~= "air" then
			local np = {x=bcp.x, y=bcp.y+1, z=bcp.z}
			minetest.env:add_node(np, {name="default:mese"})
			self.object:remove()
		end
	end
})
