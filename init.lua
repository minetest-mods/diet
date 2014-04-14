diet = {
	players = {}
}

function diet.__init()
	local file = io.open(minetest.get_worldpath().."/diet.txt", "r")
	if file then
		local table = minetest.deserialize(file:read("*all"))
		if type(table) == "table" then
			diet.players = table.players
			return
		end
	end
end

function diet.save()
	local file = io.open(minetest.get_worldpath().."/diet.txt", "w")
	if file then
		file:write(minetest.serialize({
			players = diet.players
		}))
		file:close()
	end
end

function diet.item_eat(max)	
	return function(itemstack, user, pointed_thing)	
		-- Process player data
		local name = user:get_player_name()
		local player = diet.__player(name)
		local item = itemstack:get_name()
		
		-- Get type
		local ftype = ""
		if (minetest.registered_items[item] and minetest.registered_items[item].groups) then
			local groups = minetest.registered_items[item].groups
			if groups.food_type_meal then
				ftype = "meal"
			elseif groups.food_type_snack then
				ftype = "snack"
			elseif groups.food_type_dessert then
				ftype = "dessert"
			elseif groups.food_type_drink then
				ftype = "drink"
			end
		end
		
		-- Calculate points
		local points = max
		if (#player.eaten>0) then
			local same_food = 0
			local same_type = 0
			for _,v in pairs(player.eaten) do
				if v[1] == item then
					same_food = same_food + 1
				end
				if v[2] == ftype then
					same_type = same_type + 1
				end
			end
			local mult = same_food/10
			points = points * 1-mult
			
			if (mult > 0.9) then
				local desc = item
				if (minetest.registered_items[item] and minetest.registered_items[item].description) then
					desc = minetest.registered_items[item].description
				end
				minetest.chat_send_player(name,"Your stomach hates "..desc)
			elseif (mult > 0.4) then
				minetest.chat_send_player(name,"Your stomach could do with a change.")
			end
			if points > max then
				error("[DIET] This shouldn't happen! points > max")
				return
			end
		end
		
		-- Increase health
		if minetest.get_modpath("hud") and hud then
			local h = tonumber(hud.hunger[name])
			h = h + points
			if h>30 then h = 30 end
			hud.hunger[name] = h
			hud.save_hunger(user)
		else
			local hp = user:get_hp()		
			if (hp+points > 20) then
				hp = 20
			else
				hp = hp + points
			end		
			user:set_hp(hp)
		end
		
		-- Register
		diet.__register_eat(player,item,ftype)
		
		diet.save()
		
		-- Remove item
		itemstack:take_item()
		return itemstack
	end
end

function diet.__player(name)
	if name == "" then
		return nil
	end
	if diet.players[name] then
		return diet.players[name]
	end
	
	diet.players[name] = {
		name = name,
		eaten = {}
	}
	diet.save()
	return diet.players[name]
end

function diet.__register_eat(player,food,type)
	table.insert(player.eaten,{food,type})
	
	while (#player.eaten > 10) do
		table.remove(player.eaten,1)
	end
end

local function overwrite(name, amt)
	local tab = minetest.registered_items[name]
	if not tab then
		return
	end
	tab.on_use = diet.item_eat(amt)
end

diet.__init()

overwrite("default:apple", 2)
if minetest.get_modpath("farming") ~= nil then
	overwrite("farming:bread", 4)
end

if minetest.get_modpath("mobs") ~= nil then
	overwrite("mobs:meat", 6)
	overwrite("mobs:rat_cooked", 5)
end

if minetest.get_modpath("moretrees") ~= nil then
	overwrite("moretrees:coconut_milk", 1)
	overwrite("moretrees:raw_coconut", 2)
	overwrite("moretrees:acorn_muffin", 3)
	overwrite("moretrees:spruce_nuts", 1)
	overwrite("moretrees:pine_nuts", 1)
	overwrite("moretrees:fir_nuts", 1)
end

if minetest.get_modpath("dwarves") ~= nil then
	overwrite("dwarves:beer", 2)
	overwrite("dwarves:apple_cider", 1)
	overwrite("dwarves:midus", 2)
	overwrite("dwarves:tequila", 2)
	overwrite("dwarves:tequila_with_lime", 2)
	overwrite("dwarves:sake", 2)
end

if minetest.get_modpath("animalmaterials") ~= nil then
	overwrite("animalmaterials:milk", 2)
	overwrite("animalmaterials:meat_raw", 3)
	overwrite("animalmaterials:meat_pork", 3)
	overwrite("animalmaterials:meat_beef", 3)
	overwrite("animalmaterials:meat_chicken", 3)
	overwrite("animalmaterials:meat_lamb", 3)
	overwrite("animalmaterials:meat_venison", 3)
	overwrite("animalmaterials:meat_ostrich", 3)
	overwrite("animalmaterials:fish_bluewhite", 2)
	overwrite("animalmaterials:fish_clownfish", 2)
end

if minetest.get_modpath("fishing") ~= nil then
	overwrite("fishing:fish_raw", 2)
	overwrite("fishing:fish", 4)
	overwrite("fishing:sushi", 6)
	overwrite("fishing:shark", 4)
	overwrite("fishing:shark_cooked", 8)
	overwrite("fishing:pike", 4)
	overwrite("fishing:pike_cooked", 8)
end

if minetest.get_modpath("glooptest") ~= nil then
	overwrite("glooptest:kalite_lump", 1)
end

if minetest.get_modpath("bushes") ~= nil then
	overwrite("bushes:sugar", 1)
	overwrite("bushes:strawberry", 2)
	overwrite("bushes:berry_pie_raw", 3)
	overwrite("bushes:berry_pie_cooked", 4)
	overwrite("bushes:basket_pies", 15)
end

if minetest.get_modpath("bushes_classic") then
	-- bushes_classic mod, as found in the plantlife modpack
	local berries = {
		"strawberry",
		"blackberry",
		"blueberry",
		"raspberry",
		"gooseberry",
		"mixed_berry"
	}
	for _, berry in ipairs(berries) do
		if berry ~= "mixed_berry" then
		
		end
		overwrite("bushes:"..berry.."_pie_raw", 2)
		overwrite("bushes:"..berry.."_pie_cooked", 5)
		overwrite("bushes:basket_"..berry, 15)
	end
end

if minetest.get_modpath("mushroom") ~= nil then
	overwrite("mushroom:brown", 1)
	overwrite("mushroom:red", 1, "", 3)
end

if minetest.get_modpath("docfarming") ~= nil then
	overwrite("docfarming:carrot", 2)
	overwrite("docfarming:cucumber", 2)
	overwrite("docfarming:corn", 2)
	overwrite("docfarming:potato", 4)
	overwrite("docfarming:bakedpotato", 5)
	overwrite("docfarming:raspberry", 3)
end

if minetest.get_modpath("farming_plus") ~= nil then
	overwrite("farming_plus:carrot_item", 3)
	overwrite("farming_plus:banana", 2)
	overwrite("farming_plus:orange_item", 2)
	overwrite("farming:pumpkin_bread", 4)
	overwrite("farming_plus:strawberry_item", 2)
	overwrite("farming_plus:tomato_item", 2)
	overwrite("farming_plus:potato_item", 4)
	overwrite("farming_plus:rhubarb_item", 2)
end

if minetest.get_modpath("mtfoods") ~= nil then
	overwrite("mtfoods:dandelion_milk", 1)
	overwrite("mtfoods:sugar", 1)
	overwrite("mtfoods:short_bread", 4)
	overwrite("mtfoods:cream", 1)
	overwrite("mtfoods:chocolate", 2)
	overwrite("mtfoods:cupcake", 2)
	overwrite("mtfoods:strawberry_shortcake", 2)
	overwrite("mtfoods:cake", 3)
	overwrite("mtfoods:chocolate_cake", 3)
	overwrite("mtfoods:carrot_cake", 3)
	overwrite("mtfoods:pie_crust", 3)
	overwrite("mtfoods:apple_pie", 3)
	overwrite("mtfoods:rhubarb_pie", 2)
	overwrite("mtfoods:banana_pie", 3)
	overwrite("mtfoods:pumpkin_pie", 3)
	overwrite("mtfoods:cookies", 2)
	overwrite("mtfoods:mlt_burger", 5)
	overwrite("mtfoods:potato_slices", 2)
	overwrite("mtfoods:potato_chips", 3)
	--mtfoods:medicine
	overwrite("mtfoods:casserole", 3)
	overwrite("mtfoods:glass_flute", 2)
	overwrite("mtfoods:orange_juice", 2)
	overwrite("mtfoods:apple_juice", 2)
	overwrite("mtfoods:apple_cider", 2)
	overwrite("mtfoods:cider_rack", 2)
end

if minetest.get_modpath("fruit") ~= nil then
	overwrite("fruit:apple", 2)
	overwrite("fruit:pear", 2)
	overwrite("fruit:bananna", 3)
	overwrite("fruit:orange", 2)
end

if minetest.get_modpath("mush45") ~= nil then
	overwrite("mush45:meal", 4)
end

if minetest.get_modpath("seaplants") ~= nil then
	overwrite("seaplants:kelpgreen", 1)
	overwrite("seaplants:kelpbrown", 1)
	overwrite("seaplants:seagrassgreen", 1)
	overwrite("seaplants:seagrassred", 1)
	overwrite("seaplants:seasaladmix", 6)
	overwrite("seaplants:kelpgreensalad", 1)
	overwrite("seaplants:kelpbrownsalad", 1)
	overwrite("seaplants:seagrassgreensalad", 1)
	overwrite("seaplants:seagrassgreensalad", 1)
end

if minetest.get_modpath("mobfcooking") ~= nil then
	overwrite("mobfcooking:cooked_pork", 6)
	overwrite("mobfcooking:cooked_ostrich", 6)
	overwrite("mobfcooking:cooked_beef", 6)
	overwrite("mobfcooking:cooked_chicken", 6)
	overwrite("mobfcooking:cooked_lamb", 6)
	overwrite("mobfcooking:cooked_venison", 6)
	overwrite("mobfcooking:cooked_fish", 6)
end

if minetest.get_modpath("ethereal") ~= nil then
	overwrite("ethereal:strawberry", 1)
	overwrite("ethereal:banana", 2)
	overwrite("ethereal:pine_nuts", 1)
	overwrite("ethereal:fern_tubers", 1)
	overwrite("ethereal:banana_bread", 7)
	overwrite("ethereal:mushroom_plant", 1)
	overwrite("ethereal:coconut_slice", 2)
	overwrite("ethereal:golden_apple", 10)
	overwrite("ethereal:wild_onion_plant", 1)
	overwrite("ethereal:mushroom_soup", 2)
	overwrite("ethereal:mushroom_soup_cooked", 3)
	overwrite("ethereal:hearty_stew", 4)
	overwrite("ethereal:hearty_stew_cooked", 6)
	overwrite("ethereal:bucket_cactus", 2)
	overwrite("ethereal:fish_raw", 2)
	overwrite("ethereal:fish_cooked", 4)
end
