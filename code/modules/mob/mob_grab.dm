/obj/item/weapon/grab
	name = "grab"
	icon = 'icons/mob/screen1.dmi'
	icon_state = "grabbed"
	var/obj/screen/grab/hud1 = null
	var/mob/affecting = null
	var/atom/movable/structure = null // if the grab is not grabbing a mob
	var/mob/assailant = null
	var/state = 1.0

	var/killing = 0.0 // 1 = about to kill, 2 = killing
	var/kill_loc = null

	var/allow_upgrade = 1.0
	var/last_suffocate = 1.0

	layer = 21
	abstract = 1.0
	item_state = "nothing"
	w_class = 5.0


/obj/item/weapon/grab/proc/thrown()

	if(affecting)
		if(state >= 2)
			var/grabee = affecting
			spawn(1)
				del(src)
			return grabee
		else
			spawn(1)
				del(src)
			return null

	else if(structure)
		var/grabee = structure
		spawn(1)
			del(src)
		return grabee

	return null


/obj/item/weapon/grab/proc/synch()
	if(affecting)
		if(affecting.anchored)//This will prevent from grabbing people that are anchored.
			del(src)
		if (assailant.r_hand == src)
			if(ishuman(assailant))
				var/mob/living/carbon/human/H = assailant
				hud1.screen_loc = H.get_slot_loc("rhand")
			else
				hud1.screen_loc = ui_rhand
		else
			if(ishuman(assailant))
				var/mob/living/carbon/human/H = assailant
				hud1.screen_loc = H.get_slot_loc("lhand")
			else
				hud1.screen_loc = ui_lhand
	return


/obj/item/weapon/grab/process()
	if(!assailant || (!affecting && !structure))
		del(src)
		return

	if(affecting && !structure)
		if ((!( isturf(assailant.loc) ) || (!( isturf(affecting.loc) ) || (assailant.loc != affecting.loc && get_dist(assailant, affecting) > 1))))
			//SN src = null
			del(src)
			return
	else if(!affecting && structure)
		if (!isturf(structure.loc) || !isturf(structure.loc) || (assailant.loc != structure.loc && get_dist(assailant, structure) > 1))
			del(src)
			return

	if (assailant.client)
		assailant.client.screen -= hud1
		assailant.client.screen += hud1
	if (assailant.pulling == affecting || assailant.pulling == structure)
		assailant.stop_pulling()

	if (structure)
		structure.loc = assailant.loc
		structure.layer = assailant.layer + 1

	if (state <= 2)
		allow_upgrade = 1
		if ((assailant.l_hand && assailant.l_hand != src && istype(assailant.l_hand, /obj/item/weapon/grab)))
			var/obj/item/weapon/grab/G = assailant.l_hand
			if (G.affecting != affecting)
				allow_upgrade = 0
		if ((assailant.r_hand && assailant.r_hand != src && istype(assailant.r_hand, /obj/item/weapon/grab)))
			var/obj/item/weapon/grab/G = assailant.r_hand
			if (G.affecting != affecting)
				allow_upgrade = 0
		if (state == 2)
			var/h = affecting.hand
			affecting.hand = 0
			affecting.drop_item()
			affecting.hand = 1
			affecting.drop_item()
			affecting.hand = h
			for(var/obj/item/weapon/grab/G in affecting.grabbed_by)
				if (G.state == 2)
					allow_upgrade = 0
		if (allow_upgrade)
			hud1.icon_state = "reinforce"
		else
			hud1.icon_state = "!reinforce"
	else
		if (!( affecting.buckled ))
			affecting.loc = assailant.loc
	if ((killing == 2 && state == 3))
		if(assailant.loc != kill_loc)
			assailant.visible_message("\red [assailant] lost \his tightened grip on [affecting]'s neck!")
			killing = 0
			hud1.icon_state = "disarm/kill"
			return

		if(ishuman(affecting))
			var/mob/living/carbon/human/H = affecting
			var/datum/organ/external/head = H.get_organ("head")
			head.add_autopsy_data("Strangulation", 0)
			if(!(H.species && H.species.flags & NO_BREATHE))
				H.adjustOxyLoss(4)

		affecting.Weaken(5) // Should keep you down unless you get help.
		affecting.Stun(5) // It will hamper your voice, being choked and all.
		affecting.losebreath = min(affecting.losebreath + 2, 3)


	return


/obj/item/weapon/grab/proc/s_click(obj/screen/S as obj)
	if (!affecting)
		return
	if(killing)
		return
	if (assailant.next_move > world.time)
		return
	if ((!( assailant.canmove ) || assailant.lying))
		//SN src = null
		del(src)
		return
	switch(S.id)
		if(1.0)
			if (state >= 3)
				if (!( killing ))
					assailant.visible_message("\red [assailant] has temporarily tightened \his grip on [affecting]!")
						//Foreach goto(97)
					assailant.next_move = world.time + 10
					//affecting.stunned = max(2, affecting.stunned)
					//affecting.paralysis = max(1, affecting.paralysis)
					affecting.losebreath = min(affecting.losebreath + 1, 3)
					last_suffocate = world.time
					flick("disarm/killf", S)
		else
	return


/obj/item/weapon/grab/proc/s_dbclick(obj/screen/S as obj)
	//if ((assailant.next_move > world.time && !( last_suffocate < world.time + 2 )))
	//	return

	if (!affecting)
		return
	if ((!( assailant.canmove ) || assailant.lying))
		del(src)
		return
	if(killing)
		return

	switch(S.id)
		if(1.0)
			if (state < 2)
				if (!( allow_upgrade ))
					return
				assailant.visible_message("\red [assailant] has grabbed [affecting] aggressively (now hands)!")
				state = 2
				icon_state = "grabbed1"
				/*if (prob(75))
					for(var/mob/O in viewers(assailant, null))
						O.show_message(text("\red [] has grabbed [] aggressively (now hands)!", assailant, affecting), 1)
					state = 2
					icon_state = "grabbed1"
				else
					for(var/mob/O in viewers(assailant, null))
						O.show_message(text("\red [] has failed to grab [] aggressively!", assailant, affecting), 1)
					del(src)
					return*/
			else
				if (state < 3)
					if(istype(affecting, /mob/living/carbon/human))
						var/mob/living/carbon/human/H = affecting
						if(FAT in H.mutations)
							assailant << "\blue You can't strangle [affecting] through all that fat!"
							return

						/*Hrm might want to add this back in
						//we should be able to strangle the Captain if he is wearing a hat
						for(var/obj/item/clothing/C in list(H.head, H.wear_suit, H.wear_mask, H.w_uniform))
							if(C.body_parts_covered & HEAD)
								assailant << "\blue You have to take off [affecting]'s [C.name] first!"
								return

						if(istype(H.wear_suit, /obj/item/clothing/suit/space) || istype(H.wear_suit, /obj/item/clothing/suit/armor) || istype(H.wear_suit, /obj/item/clothing/suit/bio_suit) || istype(H.wear_suit, /obj/item/clothing/suit/swat_suit))
							assailant << "\blue You can't strangle [affecting] through their suit collar!"
							return
						*/

					if(istype(affecting, /mob/living/carbon/metroid))
						assailant << "\blue You squeeze [affecting], but nothing interesting happens."
						return

					assailant.visible_message("\red [assailant] has reinforced \his grip on [affecting] (now neck)!")
					state = 3
					icon_state = "grabbed+1"
					if (!( affecting.buckled ))
						affecting.loc = assailant.loc
					affecting.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has had their neck grabbed by [assailant.name] ([assailant.ckey])</font>")
					assailant.attack_log += text("\[[time_stamp()]\] <font color='red'>Grabbed the neck of [affecting.name] ([affecting.ckey])</font>")
					msg_admin_attack("[assailant.name] ([assailant.ckey]) grabbed the neck of [affecting.name] ([affecting.ckey]) (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[assailant.x];Y=[assailant.y];Z=[assailant.z]'>JMP</a>)",0)
					log_attack("[assailant.name] ([assailant.ckey]) grabbed the neck of [affecting.name] ([affecting.ckey])")

					hud1.icon_state = "disarm/kill"
					hud1.name = "disarm/kill"
				else
					if (state >= 3 && !killing)
						assailant.visible_message("\red [assailant] starts to tighten \his grip on [affecting]'s neck!")
						hud1.icon_state = "disarm/kill1"
						killing = 1
						if(do_after(assailant, 40))
							if(killing == 2)
								return
							if(!affecting)
								del(src)
								return
							if ((!( assailant.canmove ) || assailant.lying))
								del(src)
								return
							killing = 2
							kill_loc = assailant.loc
							assailant.visible_message("\red [assailant] has tightened \his grip on [affecting]'s neck!")
							affecting.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been strangled (kill intent) by [assailant.name] ([assailant.ckey])</font>")
							assailant.attack_log += text("\[[time_stamp()]\] <font color='red'>Strangled (kill intent) [affecting.name] ([affecting.ckey])</font>")
							msg_admin_attack("[assailant] ([assailant.ckey])(<A HREF='?_src_=holder;adminplayerobservejump=\ref[assailant]'>JMP</A>) strangled [affecting] ([affecting.ckey]) (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[assailant.x];Y=[assailant.y];Z=[assailant.z]'>JMP</a>)", 0)
							log_attack("[assailant.name] ([assailant.ckey]) strangled [affecting.name] ([affecting.ckey])")

							assailant.next_move = world.time + 10
							affecting.losebreath += 2
						else
							assailant.visible_message("\red [assailant] was unable to tighten \his grip on [affecting]'s neck!")
							killing = 0
							hud1.icon_state = "disarm/kill"
	return


/obj/item/weapon/grab/New(var/location, mob/user as mob, mob/affected as mob)
	..()
	src.loc = location
	src.assailant = user
	src.affecting = affected
	// HUD
	hud1 = new /obj/screen/grab( src )
	hud1.icon_state = "reinforce"
	hud1.name = "Reinforce Grab"
	hud1.id = 1
	hud1.master = src
	return


/obj/item/weapon/grab/attack(mob/M as mob, mob/user as mob)
	if(!affecting) return
	if (M == affecting)
		if (state < 3)
			s_dbclick(hud1)
		else
			s_click(hud1)
		return
	if(M == assailant && state >= 2)
		if( ( ishuman(user) && (FAT in user.mutations) && ismonkey(affecting) ) || ( isalien(user) && iscarbon(affecting) ) )
			var/mob/living/carbon/attacker = user
			user.visible_message("\red <B>[user] is attempting to devour [affecting]!</B>")
			if(istype(user, /mob/living/carbon/alien/humanoid/hunter))
				if(!do_mob(user, affecting)||!do_after(user, 30)) return
			else
				if(!do_mob(user, affecting)||!do_after(user, 100)) return
			user.visible_message("\red <B>[user] devours [affecting]!</B>")
			affecting.loc = user
			attacker.stomach_contents.Add(affecting)
			del(src)


/obj/item/weapon/grab/dropped()
	del(src)
	return


/obj/item/weapon/grab/Del()
	del(hud1)
	..()
	return