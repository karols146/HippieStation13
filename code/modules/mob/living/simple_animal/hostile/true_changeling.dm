#define TRUE_CHANGELING_REFORM_THRESHOLD 1800 //3 minutes by default
// #define TRUE_CHANGELING_PASSIVE_HEAL 3 //Amount of brute damage restored per tick

//Changelings in their true form.
//Massive health and damage, but move slowly.

/mob/living/simple_animal/hostile/true_changeling
	name = "true changeling"
	real_name = "true changeling"
	desc = "Holy shit, what the fuck is that thing?!"
	speak_emote = list("says with one of its faces")
	emote_hear = list("says with one of its faces")
	icon = 'icons/mob/animal.dmi'
	icon_state = "horror"
	icon_living = "horror"
	icon_dead = "horror_dead"
	speed = 2
	a_intent = "harm"
	stop_automated_movement = 1
	status_flags = CANPUSH
	ventcrawler = 2
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxHealth = 500 //Very durable
	health = 500
	healable = 0
	environment_smash = 1
	melee_damage_lower = 30
	melee_damage_upper = 30
	see_in_dark = 8
	see_invisible = SEE_INVISIBLE_MINIMUM
	wander = 0
	attacktext = "rips into"
	attack_sound = 'sound/effects/blobattack.ogg'
	next_move_modifier = 0.5 //Faster attacks
	butcher_results = list(/obj/item/weapon/reagent_containers/food/snacks/meat/slab/human = 15) //It's a pretty big dude. Actually killing one is a feat.
	gold_core_spawnable = 0 //Should stay exclusive to changelings tbh, otherwise makes it much less significant to sight one
	var/transformed_time = 0
	var/playstyle_string = "<b><font size=3 color='red'>We have entered our true form!</font> We are unbelievably powerful, and regenerate life at a steady rate. However, most of \
	our abilities are useless in this form, and we must utilise the abilities that we have gained as a result of our transformation. Currently, we are incapable of returning to a human. \
	After several minutes, we will once again be able to revert into a human. Taking too much damage will also turn us back into a human in addition to knocking us out for a long time.</b>"
	var/mob/living/carbon/human/stored_changeling = null //The changeling that transformed
	var/devouring = FALSE //If the true changeling is currently devouring a human

/mob/living/simple_animal/hostile/true_changeling/New()
	..()
	transformed_time = world.time
	emote("scream")

/mob/living/simple_animal/hostile/true_changeling/Login()
	..()
	src << playstyle_string

/mob/living/simple_animal/hostile/true_changeling/Life()
	..()
	// adjustBruteLoss(-TRUE_CHANGELING_PASSIVE_HEAL) //Uncomment for passive healing

/mob/living/simple_animal/hostile/true_changeling/emote(act, m_type=1, message = null)
	if(stat)
		return
	if(act == "scream" && !spam_flag)
		message = "<B>[src]</B> makes a loud, bone-chilling roar!"
		act = "me"
		var/frequency = get_rand_frequency() //so sound frequency is consistent
		for(var/mob/M in range(35, src)) //You can hear the scream 7 screens away
			// Double check for client
			if(M && M.client)
				var/turf/M_turf = get_turf(M)
				if(M_turf && M_turf.z == src.z)
					var/dist = get_dist(M_turf, src)
					if(dist <= 7) //source of sound very close
						M.playsound_local(src, 'sound/effects/horror_scream.ogg', 80, 1, frequency, falloff = 2)
					else
						var/vol = Clamp(100-((dist-7)*5), 10, 100) //Every tile decreases sound volume by 5
						M.playsound_local(src, 'sound/effects/horror_scream_reverb.ogg', vol, 1, frequency, falloff = 5)
				if(M.stat == DEAD && (M.client.prefs.chat_toggles & CHAT_GHOSTSIGHT) && !(M in viewers(get_turf(src),null)))
					M.show_message(message)
		audible_message(message)
		spam_flag = 1
		spawn(50)
			spam_flag = 0
		return

	..(act, m_type, message)

/mob/living/simple_animal/hostile/true_changeling/death()
	emote("scream")
	..(1)
	if(stored_changeling && mind)
		visible_message("<span class='warning'>[src] lets out a furious scream as it shrinks into its human form.</span>", \
						"<span class='userdanger'>We lack the power to maintain this form! We helplessly turn back into a human...</span>")
		stored_changeling.loc = get_turf(src)
		mind.transfer_to(stored_changeling)
		stored_changeling.Paralyse(30) //Make them helpless for 30 seconds
		stored_changeling.status_flags &= ~GODMODE
		qdel(src)
	else
		visible_message("<span class='warning'>[src] lets out a waning scream as it falls, twitching, to the floor.</span>")
		spawn(450)
			if(src)
				visible_message("<span class='warning'>[src] stumbles upright and begins to move!</span>")
				revive() //Changelings can self-revive, and true changelings are no exception

/mob/living/simple_animal/hostile/true_changeling/verb/turn_to_human()
	set name = "Re-Form Human Shell"
	set desc = "We turn back into a human. This takes considerable effort and will stun us for some time afterwards."
	set category = "True Changeling"

	if(!stored_changeling)
		usr << "<span class='warning'>We do not have a form other than this!</span>"
		return 0
	if(stored_changeling.stat == DEAD)
		usr << "<span class='warning'>Our human form is dead!</span>"
		return 0
	if(world.time - transformed_time < TRUE_CHANGELING_REFORM_THRESHOLD)
		var/timeleft = (transformed_time + TRUE_CHANGELING_REFORM_THRESHOLD) - world.time
		usr << "<span class='warning'>We are still unable to change back at will! We need to wait [Ceiling(timeleft/600)] minutes.</span>"
		return 0
	usr.visible_message("<span class='warning'>[usr] suddenly crunches and twists into a smaller form!</span>", \
						"<span class='danger'>We return to our lesser form.</span>")
	stored_changeling.loc = get_turf(src)
	mind.transfer_to(stored_changeling)
	stored_changeling.Weaken(10)
	stored_changeling.Stun(10)
	stored_changeling.status_flags &= ~GODMODE
	qdel(usr)
	return 1

/mob/living/simple_animal/hostile/true_changeling/verb/devour()
	set name = "Devour"
	set desc = "We tear into the innards of a human. After some time, they will be significantly damaged and our health partially restored."
	set category = "True Changeling"

	var/mob/living/simple_animal/hostile/true_changeling/T = usr
	if(T.devouring)
		T << "<span class='warning'>We are already feasting on a human!</span>"
		return 0
	var/list/potential_targets = list()
	for(var/mob/living/carbon/human/H in range(1, usr))
		if(H == stored_changeling || (H.mind && H.mind.changeling)) //You can't eat changelings in human form
			continue
		potential_targets.Add(H)
	if(!potential_targets.len)
		T << "<span class='warning'>There are no humans nearby!</span>"
		return 0
	var/mob/living/carbon/human/lunch
	if(potential_targets.len == 1)
		lunch = potential_targets[1]
	else
		lunch = input(T, "Choose a human to devour.", "Lunch") as null|anything in potential_targets
	if(!lunch && !ishuman(lunch))
		return 0
	T.devouring = TRUE
	T.visible_message("<span class='warning'>[T] begins ripping apart and feasting on [lunch]!</span>", \
					"<span class='danger'>We begin to feast upon [lunch]...</span>")
	if(!do_mob(usr, 50, target = lunch))
		T.devouring = FALSE
		return 0
	T.devouring = FALSE
	var/fat = lunch.disabilities & FAT
	if(lunch.getBruteLoss() >= 300)
		T.visible_message("<span class='warning'>[lunch] is completely devoured by [T]!</span>", \
						"<span class='danger'>You completely devour [lunch]!</span>")
		lunch.gib()
	else
		lunch.adjustBruteLoss(60)
		T.visible_message("<span class='warning'>[T] tears a chunk from [lunch]'s flesh!</span>", \
						"<span class='danger'>We tear a chunk of flesh from [lunch] and devour it!</span>")
		lunch << "<span class='userdanger'>[T] takes a huge bite out of you!</span>"
		var/obj/effect/decal/cleanable/blood/gibs/G = new(get_turf(lunch))
		step(G, pick(alldirs)) //Make some gibs spray out for dramatic effect
		playsound(lunch, 'sound/effects/splat.ogg', 50, 1)
		playsound(lunch, 'sound/misc/tear.ogg', 50, 1)
		lunch.emote("scream")
	if(fat)
		T.adjustBruteLoss(-100) //Tasty leetle peegy
	else
		T.adjustBruteLoss(-50)

#undef TRUE_CHANGELING_REFORM_THRESHOLD
// #undef TRUE_CHANGELING_PASSIVE_HEAL
